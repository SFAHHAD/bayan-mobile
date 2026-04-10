-- =============================================================================
-- Bayan Mobile v1.8 — Voice Intelligence & CI/CD Layer
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. VOICE TRANSCRIPTION — extend voices table
-- -----------------------------------------------------------------------------

ALTER TABLE voices
  ADD COLUMN IF NOT EXISTS transcript_text TEXT,
  ADD COLUMN IF NOT EXISTS transcription_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (transcription_status IN ('pending', 'processing', 'completed', 'failed'));

-- Full-text search index (Arabic + English fallback)
CREATE INDEX IF NOT EXISTS idx_voices_transcript_fts
  ON voices USING gin(to_tsvector('arabic', coalesce(transcript_text, '')));

CREATE INDEX IF NOT EXISTS idx_voices_transcription_status
  ON voices (transcription_status) WHERE transcription_status <> 'completed';

-- RPC: search voice clips by transcript text
CREATE OR REPLACE FUNCTION search_transcripts(
  p_query      TEXT,
  p_diwan_id   UUID    DEFAULT NULL,
  p_limit      INT     DEFAULT 20
)
RETURNS TABLE (
  id                    UUID,
  diwan_id              UUID,
  speaker_id            UUID,
  title                 TEXT,
  storage_path          TEXT,
  public_url            TEXT,
  duration_seconds      INT,
  transcript_text       TEXT,
  transcription_status  TEXT,
  rank                  REAL,
  created_at            TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    v.id,
    v.diwan_id,
    v.speaker_id,
    v.title,
    v.storage_path,
    v.public_url,
    v.duration_seconds,
    v.transcript_text,
    v.transcription_status,
    ts_rank(to_tsvector('arabic', coalesce(v.transcript_text, '')),
            plainto_tsquery('arabic', p_query)) AS rank,
    v.created_at
  FROM voices v
  WHERE v.transcription_status = 'completed'
    AND to_tsvector('arabic', coalesce(v.transcript_text, ''))
        @@ plainto_tsquery('arabic', p_query)
    AND (p_diwan_id IS NULL OR v.diwan_id = p_diwan_id)
  ORDER BY rank DESC, v.created_at DESC
  LIMIT p_limit;
$$;

-- -----------------------------------------------------------------------------
-- 2. POPULAR DIWANS CACHE (Redis-like warm cache via pg_net + pg_cron)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS popular_diwans_cache (
  diwan_id    UUID PRIMARY KEY REFERENCES diwans(id) ON DELETE CASCADE,
  score       INT  NOT NULL DEFAULT 0,
  rank        INT  NOT NULL DEFAULT 0,
  refreshed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE popular_diwans_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "popular_cache_read_all"
  ON popular_diwans_cache FOR SELECT USING (true);

CREATE POLICY "popular_cache_service_write"
  ON popular_diwans_cache FOR ALL USING (auth.role() = 'service_role');

-- Function: recompute and persist top-100 popular diwans
CREATE OR REPLACE FUNCTION refresh_popular_diwans_cache()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_inserted INT;
BEGIN
  DELETE FROM popular_diwans_cache;

  WITH scored AS (
    SELECT
      d.id AS diwan_id,
      (
        COALESCE(d.listener_count, 0) * 3 +
        COUNT(DISTINCT gl.id)          * 2 +
        COALESCE(d.entry_fee, 0)
      ) AS score,
      ROW_NUMBER() OVER (
        ORDER BY (
          COALESCE(d.listener_count, 0) * 3 +
          COUNT(DISTINCT gl.id)          * 2 +
          COALESCE(d.entry_fee, 0)
        ) DESC
      ) AS rank
    FROM diwans d
    LEFT JOIN gift_ledger gl
      ON gl.diwan_id = d.id
     AND gl.created_at >= now() - INTERVAL '1 hour'
    WHERE d.is_live = TRUE
       OR d.created_at >= now() - INTERVAL '24 hours'
    GROUP BY d.id
    ORDER BY score DESC
    LIMIT 100
  )
  INSERT INTO popular_diwans_cache (diwan_id, score, rank, refreshed_at)
  SELECT diwan_id, score, rank, now() FROM scored;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  RETURN v_inserted;
END;
$$;

-- RPC: get ordered popular diwan IDs (read by clients)
CREATE OR REPLACE FUNCTION get_popular_diwan_ids(p_limit INT DEFAULT 20)
RETURNS TABLE (diwan_id UUID, score INT, rank INT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT diwan_id, score, rank
  FROM popular_diwans_cache
  ORDER BY rank
  LIMIT p_limit;
$$;

-- pg_cron: warm cache every 5 minutes
SELECT cron.schedule(
  'refresh-popular-diwans-cache',
  '*/5 * * * *',
  $$ SELECT refresh_popular_diwans_cache(); $$
);

-- -----------------------------------------------------------------------------
-- 3. REPUTATION — update calculate_trust_score with Verified Professional bonus
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION calculate_trust_score(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_xp         INT := 0;
  v_streak     INT := 0;
  v_governance INT := 0;
  v_sub        INT := 0;
  v_pro        INT := 0;
  v_xp_comp    INT;
  v_str_comp   INT;
  v_gov_comp   INT;
  v_sub_comp   INT;
  v_pro_comp   INT;
  v_total      INT;
BEGIN
  -- XP component (0–40)
  SELECT COALESCE(engagement_xp, 0) INTO v_xp
  FROM user_activity_metrics WHERE user_id = p_user_id;
  v_xp_comp := LEAST(40, v_xp / 250);

  -- Streak component (0–10)
  SELECT COALESCE(daily_streak, 0) INTO v_streak
  FROM user_activity_metrics WHERE user_id = p_user_id;
  v_str_comp := LEAST(10, v_streak);

  -- Governance participation (0–20)
  SELECT COUNT(*) INTO v_governance
  FROM governance_votes WHERE user_id = p_user_id;
  v_gov_comp := LEAST(20, v_governance * 2);

  -- Subscription tier (0–20)
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM user_subscriptions us
      JOIN subscription_tiers st ON st.id = us.tier_id
      WHERE us.user_id = p_user_id AND us.status = 'active'
        AND st.type = 'founder'
    ) THEN 20
    WHEN EXISTS (
      SELECT 1 FROM user_subscriptions us
      JOIN subscription_tiers st ON st.id = us.tier_id
      WHERE us.user_id = p_user_id AND us.status = 'active'
        AND st.type = 'platinum'
    ) THEN 15
    WHEN EXISTS (
      SELECT 1 FROM user_subscriptions us
      JOIN subscription_tiers st ON st.id = us.tier_id
      WHERE us.user_id = p_user_id AND us.status = 'active'
        AND st.type = 'gold'
    ) THEN 10
    ELSE 0
  END INTO v_sub;
  v_sub_comp := v_sub;

  -- Verified Professional bonus (0–10, weight ×1.5 of normal verified)
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = p_user_id AND is_verified = TRUE
    ) THEN 10
    ELSE 0
  END INTO v_pro;
  v_pro_comp := v_pro;

  v_total := LEAST(100,
    v_xp_comp + v_str_comp + v_gov_comp + v_sub_comp + v_pro_comp);

  RETURN jsonb_build_object(
    'score',                  v_total,
    'xp_component',           v_xp_comp,
    'streak_component',       v_str_comp,
    'governance_component',   v_gov_comp,
    'subscription_component', v_sub_comp,
    'verified_pro_component', v_pro_comp
  );
END;
$$;
