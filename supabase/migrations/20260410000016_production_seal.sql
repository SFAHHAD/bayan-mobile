-- =============================================================================
-- Bayan Mobile v2.0 — Production Seal & Final Hardening
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. ACTIVITY LOGS — final RLS hardening
-- -----------------------------------------------------------------------------

-- Users may only read their own activity; service_role reads all.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'activity_logs' AND policyname = 'activity_logs_read_own_v2'
  ) THEN
    CREATE POLICY "activity_logs_read_own_v2"
      ON activity_logs FOR SELECT
      USING (auth.uid() = user_id OR auth.role() = 'service_role');
  END IF;
END $$;

-- Block any direct UPDATE/DELETE from client roles (only service_role allowed)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'activity_logs' AND policyname = 'activity_logs_no_client_mutate'
  ) THEN
    CREATE POLICY "activity_logs_no_client_mutate"
      ON activity_logs FOR ALL
      USING (auth.role() = 'service_role')
      WITH CHECK (auth.role() = 'service_role');
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 2. SYSTEM LOGS — production-level filter
--    In production only 'warning', 'error', 'fatal' are persisted.
--    'debug' and 'info' are silently dropped to save storage.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_system_event_production(
  p_severity    TEXT,
  p_source      TEXT,
  p_message     TEXT,
  p_stack_trace TEXT    DEFAULT NULL,
  p_metadata    JSONB   DEFAULT '{}',
  p_app_version TEXT    DEFAULT NULL,
  p_platform    TEXT    DEFAULT NULL,
  p_session_id  TEXT    DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Drop debug/info in production to preserve storage
  IF p_severity IN ('debug', 'info') THEN
    RETURN;
  END IF;

  INSERT INTO public.system_logs
    (severity, source, message, stack_trace, user_id, metadata,
     app_version, platform, session_id)
  VALUES
    (p_severity, p_source, p_message, p_stack_trace,
     auth.uid(), p_metadata, p_app_version, p_platform, p_session_id);

EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;

-- Partial index — only index warning/error/fatal rows (saves space)
CREATE INDEX IF NOT EXISTS idx_syslogs_prod_severity
  ON public.system_logs (severity, created_at DESC)
  WHERE severity IN ('warning', 'error', 'fatal');

-- Retention: auto-delete debug/info logs older than 7 days (run via pg_cron)
CREATE OR REPLACE FUNCTION public.purge_verbose_logs(p_days_old INT DEFAULT 7)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted INT;
BEGIN
  DELETE FROM public.system_logs
  WHERE severity IN ('debug', 'info')
    AND created_at < now() - (p_days_old || ' days')::INTERVAL;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

SELECT cron.schedule(
  'purge-verbose-logs',
  '0 2 * * *',   -- 02:00 UTC daily
  $$SELECT public.purge_verbose_logs(7)$$
);

-- -----------------------------------------------------------------------------
-- 3. BUG REPORTS — final RLS seal
-- -----------------------------------------------------------------------------

-- Admin update (e.g. change status to resolved) — only service_role
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'bug_reports' AND policyname = 'bug_reports_service_update'
  ) THEN
    CREATE POLICY "bug_reports_service_update"
      ON bug_reports FOR UPDATE
      USING (auth.role() = 'service_role');
  END IF;
END $$;

-- Prevent clients from deleting reports
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'bug_reports' AND policyname = 'bug_reports_no_delete'
  ) THEN
    CREATE POLICY "bug_reports_no_delete"
      ON bug_reports FOR DELETE
      USING (auth.role() = 'service_role');
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 4. PRODUCTION SECRETS VERIFICATION TABLE
--    Stores last-known health check result for each required secret.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS production_health (
  key         TEXT        PRIMARY KEY,
  is_set      BOOLEAN     NOT NULL DEFAULT false,
  masked_hint TEXT,
  checked_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE production_health ENABLE ROW LEVEL SECURITY;

CREATE POLICY "production_health_service_only"
  ON production_health FOR ALL
  USING (auth.role() = 'service_role');

-- RPC: upsert health entry (called by verify-production-secrets Edge Fn)
CREATE OR REPLACE FUNCTION upsert_production_health(
  p_key        TEXT,
  p_is_set     BOOLEAN,
  p_masked_hint TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  INSERT INTO production_health (key, is_set, masked_hint, checked_at)
  VALUES (p_key, p_is_set, p_masked_hint, now())
  ON CONFLICT (key) DO UPDATE
    SET is_set       = EXCLUDED.is_set,
        masked_hint  = EXCLUDED.masked_hint,
        checked_at   = now();
$$;

-- RPC: get all health entries (readable by auth users for dashboard)
CREATE OR REPLACE FUNCTION get_production_health()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_agg(row_to_json(ph))
  FROM production_health ph;
$$;

-- -----------------------------------------------------------------------------
-- 5. RATE LIMIT BUCKETS — cleanup cron
-- -----------------------------------------------------------------------------

SELECT cron.schedule(
  'cleanup-rate-limit-buckets',
  '*/10 * * * *',   -- every 10 minutes
  $$DELETE FROM rate_limit_buckets WHERE window_start < now() - INTERVAL '5 minutes'$$
);
