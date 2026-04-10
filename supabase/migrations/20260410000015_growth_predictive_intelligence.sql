-- =============================================================================
-- Bayan Mobile v1.9 — Growth & Predictive Intelligence Layer
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. BUG REPORTS (Shake to Report)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS bug_reports (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  title         TEXT        NOT NULL,
  description   TEXT,
  severity      TEXT        NOT NULL DEFAULT 'medium'
                            CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  screen_name   TEXT,
  screen_state  JSONB       NOT NULL DEFAULT '{}',
  app_version   TEXT,
  platform      TEXT,
  session_id    TEXT,
  device_info   JSONB       NOT NULL DEFAULT '{}',
  recent_logs   JSONB       NOT NULL DEFAULT '[]',
  status        TEXT        NOT NULL DEFAULT 'open'
                            CHECK (status IN ('open', 'in_progress', 'resolved', 'closed', 'duplicate')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bug_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bug_reports_insert_own"
  ON bug_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "bug_reports_read_own"
  ON bug_reports FOR SELECT
  USING (auth.uid() = reporter_id OR auth.role() = 'service_role');

CREATE INDEX IF NOT EXISTS idx_bug_reports_reporter
  ON bug_reports (reporter_id);

CREATE INDEX IF NOT EXISTS idx_bug_reports_open
  ON bug_reports (status, created_at DESC)
  WHERE status = 'open';

CREATE TRIGGER trg_bug_reports_updated_at
  BEFORE UPDATE ON bug_reports
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- RPC: submit a bug report (bypasses RLS, attaches caller as reporter)
CREATE OR REPLACE FUNCTION submit_bug_report(
  p_title       TEXT,
  p_description TEXT        DEFAULT NULL,
  p_severity    TEXT        DEFAULT 'medium',
  p_screen_name TEXT        DEFAULT NULL,
  p_screen_state JSONB      DEFAULT '{}',
  p_app_version TEXT        DEFAULT NULL,
  p_platform    TEXT        DEFAULT NULL,
  p_session_id  TEXT        DEFAULT NULL,
  p_device_info JSONB       DEFAULT '{}',
  p_recent_logs JSONB       DEFAULT '[]'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO bug_reports (
    reporter_id, title, description, severity,
    screen_name, screen_state, app_version, platform,
    session_id, device_info, recent_logs
  ) VALUES (
    auth.uid(), p_title, p_description, p_severity,
    p_screen_name, p_screen_state, p_app_version, p_platform,
    p_session_id, p_device_info, p_recent_logs
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. RATE LIMITING & BURST TRAFFIC SHARDING
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS rate_limit_buckets (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket_key   TEXT        NOT NULL,
  action       TEXT        NOT NULL,
  hit_count    INT         NOT NULL DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(bucket_key, action)
);

ALTER TABLE rate_limit_buckets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rate_limit_service_only"
  ON rate_limit_buckets FOR ALL
  USING (auth.role() = 'service_role');

-- RPC: check + increment rate limit bucket (token-bucket style)
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_bucket_key  TEXT,
  p_action      TEXT,
  p_limit       INT  DEFAULT 10,
  p_window_secs INT  DEFAULT 60
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count    INT;
  v_reset_at TIMESTAMPTZ;
  v_allowed  BOOLEAN;
BEGIN
  -- Expire old window
  DELETE FROM rate_limit_buckets
  WHERE bucket_key = p_bucket_key
    AND action     = p_action
    AND window_start < now() - (p_window_secs || ' seconds')::INTERVAL;

  -- Upsert and increment
  INSERT INTO rate_limit_buckets (bucket_key, action, hit_count, window_start)
  VALUES (p_bucket_key, p_action, 1, now())
  ON CONFLICT (bucket_key, action)
  DO UPDATE SET hit_count = rate_limit_buckets.hit_count + 1
  RETURNING hit_count,
            window_start + (p_window_secs || ' seconds')::INTERVAL
  INTO v_count, v_reset_at;

  v_allowed := v_count <= p_limit;

  RETURN jsonb_build_object(
    'allowed',   v_allowed,
    'count',     v_count,
    'limit',     p_limit,
    'remaining', GREATEST(0, p_limit - v_count),
    'reset_at',  v_reset_at
  );
END;
$$;

-- RPC: celebrity burst mode — temporarily raises limit for a given diwan
CREATE OR REPLACE FUNCTION enable_burst_mode(
  p_diwan_id    UUID,
  p_multiplier  INT DEFAULT 5
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete existing bucket so the next check_rate_limit call gets a fresh window
  -- with the caller's chosen multiplier baked in.
  DELETE FROM rate_limit_buckets
  WHERE bucket_key = 'diwan:' || p_diwan_id::TEXT
    AND action = 'join';

  -- Insert a sentinel row that starts life with a head-start negative count,
  -- effectively raising the effective limit by p_multiplier * base_limit.
  INSERT INTO rate_limit_buckets (bucket_key, action, hit_count, window_start)
  VALUES (
    'diwan:' || p_diwan_id::TEXT,
    'burst_mode',
    -1 * (p_multiplier * 10),  -- negative = pre-credits
    now()
  )
  ON CONFLICT (bucket_key, action) DO UPDATE
    SET hit_count    = -1 * (p_multiplier * 10),
        window_start = now();
END;
$$;

-- Mock read-replica routing table
CREATE TABLE IF NOT EXISTS read_replicas (
  id         SERIAL PRIMARY KEY,
  replica_id TEXT   NOT NULL UNIQUE,
  region     TEXT   NOT NULL DEFAULT 'us-east-1',
  weight     INT    NOT NULL DEFAULT 1,
  is_healthy BOOLEAN NOT NULL DEFAULT true,
  last_check TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO read_replicas (replica_id, region, weight, is_healthy)
VALUES
  ('replica-primary',   'us-east-1',    3, true),
  ('replica-us-west',   'us-west-1',    2, true),
  ('replica-eu-west',   'eu-west-1',    2, true),
  ('replica-ap-south',  'ap-southeast-1', 1, true)
ON CONFLICT (replica_id) DO NOTHING;

-- RPC: get best replica for routing (weighted random)
CREATE OR REPLACE FUNCTION get_best_replica()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT replica_id
  FROM read_replicas
  WHERE is_healthy = true
  ORDER BY weight DESC, random()
  LIMIT 1;
$$;

-- -----------------------------------------------------------------------------
-- 3. PREDICTIVE NOTIFICATIONS — best notification hour per user
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION predict_best_notification_hour(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_best_hour  INT   := 18;
  v_confidence FLOAT := 0.0;
  v_total      INT   := 0;
  v_dist       JSONB := '{}'::jsonb;
  v_max_count  INT   := 0;
BEGIN
  -- Aggregate activity by hour in Kuwait timezone (UTC+3)
  SELECT
    COUNT(*)::INT,
    jsonb_object_agg(hour_of_day::TEXT, cnt)
  INTO v_total, v_dist
  FROM (
    SELECT
      EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Kuwait')::INT AS hour_of_day,
      COUNT(*)::INT AS cnt
    FROM activity_logs
    WHERE user_id    = p_user_id
      AND created_at >= now() - INTERVAL '30 days'
    GROUP BY 1
  ) sub;

  IF v_total >= 5 THEN
    -- Pick the hour with the highest event count
    SELECT
      key::INT,
      value::INT
    INTO v_best_hour, v_max_count
    FROM jsonb_each_text(v_dist)
    ORDER BY value::INT DESC
    LIMIT 1;

    v_confidence := ROUND((v_max_count::FLOAT / v_total)::NUMERIC, 2);
  END IF;

  RETURN jsonb_build_object(
    'best_hour',         v_best_hour,
    'confidence',        v_confidence,
    'total_events',      v_total,
    'hour_distribution', v_dist,
    'is_predicted',      v_total >= 5
  );
END;
$$;

-- Index to accelerate hourly aggregation
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_hour
  ON activity_logs (user_id, created_at DESC);
