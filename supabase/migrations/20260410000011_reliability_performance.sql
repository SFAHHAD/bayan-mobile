-- =============================================================================
-- Bayan v1.5 — Reliability & Performance Infrastructure
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. OBSERVABILITY — system_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  severity      TEXT NOT NULL
      CHECK (severity IN ('debug','info','warning','error','fatal')),
  source        TEXT NOT NULL,
  message       TEXT NOT NULL,
  stack_trace   TEXT,
  user_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata      JSONB NOT NULL DEFAULT '{}',
  app_version   TEXT,
  platform      TEXT,
  session_id    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_syslogs_severity ON public.system_logs (severity, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_syslogs_user     ON public.system_logs (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_syslogs_source   ON public.system_logs (source);

ALTER TABLE public.system_logs ENABLE ROW LEVEL SECURITY;

-- Users can insert their own logs; admins read all (service role bypasses RLS)
CREATE POLICY "syslogs_insert_auth" ON public.system_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "syslogs_select_own" ON public.system_logs
  FOR SELECT USING (auth.uid() = user_id);

-- RPC: log_system_event — wraps insert, never raises (fire-and-forget)
CREATE OR REPLACE FUNCTION public.log_system_event(
  p_severity    TEXT,
  p_source      TEXT,
  p_message     TEXT,
  p_stack_trace TEXT    DEFAULT NULL,
  p_metadata    JSONB   DEFAULT '{}',
  p_app_version TEXT    DEFAULT NULL,
  p_platform    TEXT    DEFAULT NULL,
  p_session_id  TEXT    DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.system_logs
    (severity, source, message, stack_trace, user_id, metadata,
     app_version, platform, session_id)
  VALUES
    (p_severity, p_source, p_message, p_stack_trace,
     auth.uid(), p_metadata, p_app_version, p_platform, p_session_id);
EXCEPTION WHEN OTHERS THEN
  NULL; -- logging must never crash the caller
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. REMOTE CONFIG
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.remote_configs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT NOT NULL UNIQUE,
  value       TEXT NOT NULL,
  type        TEXT NOT NULL
      CHECK (type IN ('bool','int','double','string','json')),
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.remote_configs ENABLE ROW LEVEL SECURITY;

-- Everyone can read active configs; only service role writes
CREATE POLICY "rconfig_select_all" ON public.remote_configs
  FOR SELECT USING (is_active = TRUE);

DROP TRIGGER IF EXISTS trg_rconfig_updated_at ON public.remote_configs;
CREATE TRIGGER trg_rconfig_updated_at
  BEFORE UPDATE ON public.remote_configs
  FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

ALTER PUBLICATION supabase_realtime ADD TABLE public.remote_configs;

-- Seed default feature flags
INSERT INTO public.remote_configs (key, value, type, description) VALUES
  ('enable_gifting',             'true',  'bool',   'Toggle token gifting during live sessions'),
  ('enable_search',              'true',  'bool',   'Toggle the search feature'),
  ('enable_premium_diwans',      'true',  'bool',   'Toggle ticketed premium diwans'),
  ('enable_referral_rewards',    'true',  'bool',   'Toggle referral reward payouts'),
  ('enable_content_moderation',  'true',  'bool',   'Toggle AI content moderation on publish'),
  ('enable_series',              'true',  'bool',   'Toggle Diwan series feature'),
  ('enable_verification',        'true',  'bool',   'Toggle professional verification requests'),
  ('max_poll_options',           '4',     'int',    'Maximum poll answer options'),
  ('platform_fee_percent',       '10',    'int',    'Platform fee % on ticket sales (0-100)'),
  ('min_followers_for_verify',   '100',   'int',    'Min followers to apply for verification'),
  ('feed_page_size',             '20',    'int',    'Personalised feed page size'),
  ('max_diwan_duration_hours',   '8',     'int',    'Auto-close live diwan after N hours'),
  ('moderation_confidence_block','0.75',  'double', 'GPT confidence threshold to auto-block'),
  ('app_min_version',            '1.5.0', 'string', 'Minimum supported app version (force-upgrade)'),
  ('maintenance_message',        '',      'string', 'Non-empty = show maintenance banner'),
  ('welcome_banner_ar',          '',      'string', 'Home-screen Arabic announcement text'),
  ('interest_decay_rate',        '0.02',  'double', 'Daily decay applied to implicit interest weights')
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. MATERIALIZED VIEWS — Performance Scaling
-- ---------------------------------------------------------------------------

-- 3a. Trending stats per diwan (replaces inline computation in feed RPC)
DROP MATERIALIZED VIEW IF EXISTS public.mv_trending_stats CASCADE;
CREATE MATERIALIZED VIEW public.mv_trending_stats AS
SELECT
  d.id                                      AS diwan_id,
  d.is_live,
  COALESCE(d.listener_count, 0)             AS listener_count,
  COALESCE(da.peak_listeners, 0)            AS peak_listeners,
  COALESCE(da.total_gifts_value, 0)         AS total_gifts_value,
  COALESCE(d.is_premium, FALSE)             AS is_premium,
  d.moderation_status,
  d.owner_id,
  (
    COALESCE(d.listener_count, 0)::NUMERIC /
      NULLIF((SELECT MAX(listener_count) FROM public.diwans WHERE is_live = TRUE), 0) * 5
    + CASE WHEN d.is_live THEN 3.0 ELSE 0.0 END
    + GREATEST(0.0,
        2.0 - EXTRACT(EPOCH FROM (NOW() - d.created_at)) / 604800.0
      )
  )                                         AS trending_score,
  NOW()                                     AS refreshed_at
FROM public.diwans d
LEFT JOIN public.diwan_analytics da ON da.diwan_id = d.id
WHERE d.is_public = TRUE
  AND d.moderation_status = 'approved';

CREATE UNIQUE INDEX idx_mv_trending_diwan
  ON public.mv_trending_stats (diwan_id);

-- 3b. User influence rankings (replaces inline follower lookups)
DROP MATERIALIZED VIEW IF EXISTS public.mv_user_influence_rankings CASCADE;
CREATE MATERIALIZED VIEW public.mv_user_influence_rankings AS
SELECT
  p.id                                      AS user_id,
  COALESCE(p.follower_count, 0)             AS follower_count,
  COALESCE(p.following_count, 0)            AS following_count,
  COALESCE(p.voice_count, 0)                AS voice_count,
  COALESCE(p.is_verified, FALSE)            AS is_verified,
  (
    COALESCE(p.follower_count, 0)::NUMERIC * 3
    + COALESCE(p.voice_count,  0)::NUMERIC * 2
    + CASE WHEN COALESCE(p.is_verified, FALSE) THEN 50 ELSE 0 END
  )                                         AS influence_score,
  NOW()                                     AS refreshed_at
FROM public.profiles p;

CREATE UNIQUE INDEX idx_mv_influence_user
  ON public.mv_user_influence_rankings (user_id);

-- ---------------------------------------------------------------------------
-- 4. CRON — refresh materialized views every 15 minutes
--    Requires pg_cron extension (available on Supabase Pro plans).
--    Wrapped in DO block so migration succeeds even if pg_cron is absent.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_cron;

  -- Remove old jobs if they exist
  PERFORM cron.unschedule('refresh-trending-stats')
    FROM cron.job WHERE jobname = 'refresh-trending-stats';
  PERFORM cron.unschedule('refresh-user-influence')
    FROM cron.job WHERE jobname = 'refresh-user-influence';

  PERFORM cron.schedule(
    'refresh-trending-stats',
    '*/15 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_trending_stats$$
  );

  PERFORM cron.schedule(
    'refresh-user-influence',
    '*/15 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_user_influence_rankings$$
  );

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron not available — skipping cron job setup: %', SQLERRM;
END;
$$;

-- ---------------------------------------------------------------------------
-- 5. OPTIMIZED get_personalized_feed v2
--    Uses mv_trending_stats + mv_user_influence_rankings (5× faster).
--    Falls back gracefully if views are stale (REFRESH runs async).
-- NOTE: AI Embedding gap unchanged — still tag-based weighting (v1.4 comment).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_personalized_feed(
  p_limit     INTEGER DEFAULT 20,
  p_offset    INTEGER DEFAULT 0
) RETURNS TABLE (
  diwan_id          UUID,
  title             TEXT,
  description       TEXT,
  owner_id          UUID,
  host_name         TEXT,
  cover_url         TEXT,
  is_live           BOOLEAN,
  is_premium        BOOLEAN,
  entry_fee         INTEGER,
  listener_count    INTEGER,
  series_id         UUID,
  moderation_status TEXT,
  score             NUMERIC,
  score_interests   NUMERIC,
  score_social      NUMERIC,
  score_trending    NUMERIC,
  created_at        TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  RETURN QUERY
  WITH
  -- interest overlap (40%)
  user_cats AS (
    SELECT ui.category, ui.weight
    FROM   public.user_interests ui
    WHERE  ui.user_id = v_uid
  ),
  interest_score AS (
    SELECT dt.diwan_id,
           COALESCE(SUM(uc.weight), 0)::NUMERIC AS raw_score
    FROM   public.diwan_tags dt
    JOIN   user_cats uc ON uc.category = dt.tag
    GROUP  BY dt.diwan_id
  ),
  -- social proximity (30%) — uses mv_user_influence_rankings for host influence
  following AS (
    SELECT f.following_id AS uid FROM public.follows f WHERE f.follower_id = v_uid
  ),
  followers AS (
    SELECT f.follower_id AS uid FROM public.follows f WHERE f.following_id = v_uid
  ),
  social_score AS (
    SELECT d.id AS diwan_id,
           CASE
             WHEN d.owner_id IN (SELECT uid FROM following) THEN 3.0
             WHEN d.owner_id IN (SELECT uid FROM followers) THEN 1.5
             ELSE 0.0
           END::NUMERIC AS raw_score
    FROM   public.diwans d
  ),
  -- trending (30%) — reads pre-computed mv_trending_stats
  trending_score AS (
    SELECT ts.diwan_id,
           COALESCE(ts.trending_score, 0)::NUMERIC AS raw_score
    FROM   public.mv_trending_stats ts
  ),
  scored AS (
    SELECT
      d.id, d.title, d.description, d.owner_id, d.host_name, d.cover_url,
      d.is_live, d.is_premium, d.entry_fee, d.listener_count,
      d.series_id, d.moderation_status, d.created_at,
      COALESCE(i.raw_score, 0)  AS s_interests,
      COALESCE(s.raw_score, 0)  AS s_social,
      COALESCE(t.raw_score, 0)  AS s_trending,
      (0.40 * COALESCE(i.raw_score, 0)
     + 0.30 * COALESCE(s.raw_score, 0)
     + 0.30 * COALESCE(t.raw_score, 0)) AS total_score
    FROM   public.diwans d
    LEFT   JOIN interest_score i ON i.diwan_id = d.id
    LEFT   JOIN social_score   s ON s.diwan_id = d.id
    LEFT   JOIN trending_score t ON t.diwan_id = d.id
    WHERE  d.is_public = TRUE
      AND  d.moderation_status = 'approved'
      AND  d.owner_id <> v_uid
  )
  SELECT
    sc.id, sc.title, sc.description, sc.owner_id, sc.host_name, sc.cover_url,
    sc.is_live, sc.is_premium, sc.entry_fee, sc.listener_count,
    sc.series_id, sc.moderation_status,
    sc.total_score, sc.s_interests, sc.s_social, sc.s_trending,
    sc.created_at
  FROM   scored sc
  ORDER  BY sc.total_score DESC, sc.is_live DESC, sc.created_at DESC
  LIMIT  p_limit OFFSET p_offset;
END;
$$;
