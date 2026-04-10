-- =============================================================================
-- Bayan v1.6 — Retention & Semantic Intelligence Layer
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. pgvector — Semantic Search foundation
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding columns (1536-dim for OpenAI text-embedding-3-small)
ALTER TABLE public.diwans
  ADD COLUMN IF NOT EXISTS embedding vector(1536),
  ADD COLUMN IF NOT EXISTS required_subscription_tier TEXT
    CHECK (required_subscription_tier IN ('gold','platinum','founder'));

ALTER TABLE public.voice_clips
  ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- HNSW index for fast approximate nearest-neighbour search (cosine distance)
CREATE INDEX IF NOT EXISTS idx_diwans_embedding_hnsw
  ON public.diwans USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS idx_voice_clips_embedding_hnsw
  ON public.voice_clips USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- match_diwans RPC — called by the semantic-search Edge Function
CREATE OR REPLACE FUNCTION public.match_diwans(
  query_embedding vector(1536),
  match_threshold  FLOAT   DEFAULT 0.70,
  match_count      INTEGER DEFAULT 10
) RETURNS TABLE (
  id                UUID,
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
  similarity        FLOAT
)
LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.title, d.description, d.owner_id, d.host_name, d.cover_url,
    d.is_live, d.is_premium, d.entry_fee, d.listener_count,
    d.series_id, d.moderation_status,
    (1.0 - (d.embedding <=> query_embedding))::FLOAT AS similarity
  FROM public.diwans d
  WHERE d.embedding IS NOT NULL
    AND d.is_public = TRUE
    AND d.moderation_status = 'approved'
    AND (1.0 - (d.embedding <=> query_embedding)) >= match_threshold
  ORDER BY d.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- match_voices RPC — semantic voice search
CREATE OR REPLACE FUNCTION public.match_voices(
  query_embedding vector(1536),
  match_threshold  FLOAT   DEFAULT 0.70,
  match_count      INTEGER DEFAULT 10
) RETURNS TABLE (
  id          UUID,
  user_id     UUID,
  title       TEXT,
  duration    INTEGER,
  play_count  INTEGER,
  created_at  TIMESTAMPTZ,
  similarity  FLOAT
)
LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id, v.user_id, v.title, v.duration, v.play_count, v.created_at,
    (1.0 - (v.embedding <=> query_embedding))::FLOAT AS similarity
  FROM public.voice_clips v
  WHERE v.embedding IS NOT NULL
    AND (1.0 - (v.embedding <=> query_embedding)) >= match_threshold
  ORDER BY v.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. GAMIFICATION — user_activity_metrics
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_activity_metrics (
  user_id                UUID    PRIMARY KEY
                         REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_streak           INTEGER NOT NULL DEFAULT 0,
  longest_streak         INTEGER NOT NULL DEFAULT 0,
  total_minutes_listened INTEGER NOT NULL DEFAULT 0,
  engagement_xp          INTEGER NOT NULL DEFAULT 0,
  current_level          INTEGER NOT NULL DEFAULT 1,
  last_checkin_date      DATE,
  prestige_tokens        INTEGER NOT NULL DEFAULT 0,
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_activity_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "metrics_select_own" ON public.user_activity_metrics
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "metrics_insert_own" ON public.user_activity_metrics
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "metrics_update_own" ON public.user_activity_metrics
  FOR UPDATE USING (auth.uid() = user_id);

-- Leaderboard: public read on xp (no email/personal data)
CREATE POLICY "metrics_leaderboard" ON public.user_activity_metrics
  FOR SELECT USING (TRUE);

-- Level-up trigger: awards prestige tokens to wallet on level increase
CREATE OR REPLACE FUNCTION public.fn_award_prestige_on_levelup()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_tokens INTEGER;
BEGIN
  IF NEW.current_level <= OLD.current_level THEN
    RETURN NEW;
  END IF;
  v_tokens := NEW.current_level * 5;
  NEW.prestige_tokens := OLD.prestige_tokens + v_tokens;
  -- Credit wallet
  UPDATE public.wallets
  SET balance    = balance + v_tokens,
      updated_at = NOW()
  WHERE user_id  = NEW.user_id;
  -- Record ledger entry
  INSERT INTO public.wallet_transactions
    (user_id, amount, type, description)
  VALUES
    (NEW.user_id, v_tokens, 'bonus',
     'مكافأة الترقية إلى المستوى ' || NEW.current_level);
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW; -- never block the metrics update
END;
$$;

DROP TRIGGER IF EXISTS trg_award_prestige_on_levelup
  ON public.user_activity_metrics;
CREATE TRIGGER trg_award_prestige_on_levelup
  BEFORE UPDATE OF current_level ON public.user_activity_metrics
  FOR EACH ROW EXECUTE FUNCTION public.fn_award_prestige_on_levelup();

-- Helper: calculate level from XP  →  1 + floor(sqrt(xp / 100))
CREATE OR REPLACE FUNCTION public.xp_to_level(p_xp INTEGER)
RETURNS INTEGER LANGUAGE sql IMMUTABLE AS $$
  SELECT (1 + FLOOR(SQRT(GREATEST(p_xp, 0)::NUMERIC / 100.0)))::INTEGER;
$$;

-- daily_checkin RPC
CREATE OR REPLACE FUNCTION public.daily_checkin()
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_uid         UUID := auth.uid();
  v_today       DATE := CURRENT_DATE;
  v_yesterday   DATE := CURRENT_DATE - INTERVAL '1 day';
  v_metrics     public.user_activity_metrics%ROWTYPE;
  v_new_streak  INTEGER;
  v_xp_awarded  INTEGER;
  v_old_level   INTEGER;
  v_new_level   INTEGER;
BEGIN
  INSERT INTO public.user_activity_metrics (user_id)
  VALUES (v_uid)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_metrics
  FROM   public.user_activity_metrics
  WHERE  user_id = v_uid;

  IF v_metrics.last_checkin_date = v_today THEN
    RETURN jsonb_build_object(
      'already_checked_in', TRUE,
      'streak', v_metrics.daily_streak,
      'xp', 0,
      'leveled_up', FALSE,
      'new_level', v_metrics.current_level,
      'prestige_tokens', 0
    );
  END IF;

  v_new_streak := CASE
    WHEN v_metrics.last_checkin_date = v_yesterday THEN v_metrics.daily_streak + 1
    ELSE 1
  END;
  -- Base 10 XP + 5 per streak day, capped at 50 bonus
  v_xp_awarded := 10 + LEAST(v_new_streak * 5, 50);
  v_old_level  := v_metrics.current_level;
  v_new_level  := public.xp_to_level(v_metrics.engagement_xp + v_xp_awarded);

  UPDATE public.user_activity_metrics SET
    daily_streak        = v_new_streak,
    longest_streak      = GREATEST(longest_streak, v_new_streak),
    engagement_xp       = engagement_xp + v_xp_awarded,
    current_level       = v_new_level,
    last_checkin_date   = v_today,
    updated_at          = NOW()
  WHERE user_id = v_uid;

  RETURN jsonb_build_object(
    'already_checked_in', FALSE,
    'streak',             v_new_streak,
    'xp',                 v_xp_awarded,
    'leveled_up',         v_new_level > v_old_level,
    'new_level',          v_new_level,
    'prestige_tokens',    CASE WHEN v_new_level > v_old_level THEN v_new_level * 5 ELSE 0 END
  );
END;
$$;

-- add_minutes_listened RPC (called when user leaves a diwan)
CREATE OR REPLACE FUNCTION public.add_minutes_listened(p_minutes INTEGER)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_xp  INTEGER := GREATEST(p_minutes / 5, 1);
BEGIN
  INSERT INTO public.user_activity_metrics
    (user_id, total_minutes_listened, engagement_xp, current_level)
  VALUES
    (v_uid, p_minutes, v_xp, public.xp_to_level(v_xp))
  ON CONFLICT (user_id) DO UPDATE SET
    total_minutes_listened =
      public.user_activity_metrics.total_minutes_listened + p_minutes,
    engagement_xp =
      public.user_activity_metrics.engagement_xp + v_xp,
    current_level  =
      public.xp_to_level(public.user_activity_metrics.engagement_xp + v_xp),
    updated_at = NOW();
END;
$$;

-- add_engagement_xp RPC (general purpose XP award)
CREATE OR REPLACE FUNCTION public.add_engagement_xp(
  p_xp     INTEGER,
  p_source TEXT DEFAULT 'activity'
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_old_level INTEGER;
  v_new_xp    INTEGER;
  v_new_level INTEGER;
BEGIN
  INSERT INTO public.user_activity_metrics (user_id)
  VALUES (v_uid) ON CONFLICT (user_id) DO NOTHING;

  SELECT current_level, engagement_xp + p_xp
  INTO   v_old_level, v_new_xp
  FROM   public.user_activity_metrics
  WHERE  user_id = v_uid;

  v_new_level := public.xp_to_level(v_new_xp);

  UPDATE public.user_activity_metrics SET
    engagement_xp = v_new_xp,
    current_level = v_new_level,
    updated_at    = NOW()
  WHERE user_id = v_uid;

  RETURN jsonb_build_object(
    'xp_added',   p_xp,
    'new_xp',     v_new_xp,
    'leveled_up', v_new_level > v_old_level,
    'new_level',  v_new_level
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. PREMIUM SUBSCRIPTIONS — The Sovereign Club
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_tiers (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT    NOT NULL,
  type          TEXT    NOT NULL UNIQUE
                CHECK (type IN ('gold','platinum','founder')),
  price_tokens  INTEGER NOT NULL CHECK (price_tokens >= 0),
  duration_days INTEGER CHECK (duration_days IS NULL OR duration_days > 0),
  features      JSONB   NOT NULL DEFAULT '{}',
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscription_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sub_tiers_read_all" ON public.subscription_tiers
  FOR SELECT USING (is_active = TRUE);

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tier_id           UUID    NOT NULL REFERENCES public.subscription_tiers(id),
  status            TEXT    NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','expired','cancelled','pending')),
  starts_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at        TIMESTAMPTZ,
  payment_reference TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, tier_id)
);

ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "usersub_select_own" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "usersub_insert_own" ON public.user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "usersub_update_own" ON public.user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.user_subscriptions;

-- Seed tiers
INSERT INTO public.subscription_tiers
  (name, type, price_tokens, duration_days, features)
VALUES
  ('بيان الذهب',     'gold',     500,  30,   '{"private_rooms":true,"advanced_analytics":false,"priority_support":false,"badge_color":"#D4AF37"}'),
  ('بيان البلاتين',  'platinum', 1500, 365,  '{"private_rooms":true,"advanced_analytics":true,"priority_support":false,"badge_color":"#C0C0C0"}'),
  ('بيان المؤسس',    'founder',  5000, NULL, '{"private_rooms":true,"advanced_analytics":true,"priority_support":true,"lifetime":true,"badge_color":"#8B5CF6"}')
ON CONFLICT (type) DO NOTHING;

-- check_subscription_access(required_tier) — used as middleware guard
CREATE OR REPLACE FUNCTION public.check_subscription_access(
  p_required_tier TEXT
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public AS $$
DECLARE
  v_uid          UUID    := auth.uid();
  v_user_rank    INTEGER := 0;
  v_required_rank INTEGER;
BEGIN
  IF p_required_tier IS NULL THEN RETURN TRUE; END IF;
  v_required_rank := CASE p_required_tier
    WHEN 'gold'     THEN 1
    WHEN 'platinum' THEN 2
    WHEN 'founder'  THEN 3
    ELSE 99
  END;
  SELECT COALESCE(MAX(CASE st.type
    WHEN 'gold'     THEN 1
    WHEN 'platinum' THEN 2
    WHEN 'founder'  THEN 3
    ELSE 0 END), 0)
  INTO v_user_rank
  FROM public.user_subscriptions us
  JOIN public.subscription_tiers st ON st.id = us.tier_id
  WHERE us.user_id = v_uid
    AND us.status  = 'active'
    AND (us.expires_at IS NULL OR us.expires_at > NOW());
  RETURN v_user_rank >= v_required_rank;
END;
$$;

-- subscribe_to_tier RPC — deducts tokens and creates/renews subscription
CREATE OR REPLACE FUNCTION public.subscribe_to_tier(
  p_tier_type TEXT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_uid        UUID := auth.uid();
  v_tier       public.subscription_tiers%ROWTYPE;
  v_expires_at TIMESTAMPTZ;
  v_balance    INTEGER;
BEGIN
  SELECT * INTO v_tier
  FROM   public.subscription_tiers
  WHERE  type = p_tier_type AND is_active = TRUE;
  IF v_tier.id IS NULL THEN
    RETURN jsonb_build_object('success',FALSE,'error','tier_not_found');
  END IF;

  SELECT balance INTO v_balance
  FROM   public.wallets WHERE user_id = v_uid;
  IF COALESCE(v_balance, 0) < v_tier.price_tokens THEN
    RETURN jsonb_build_object('success',FALSE,'error','insufficient_balance');
  END IF;

  v_expires_at := CASE
    WHEN v_tier.duration_days IS NOT NULL
    THEN NOW() + (v_tier.duration_days || ' days')::INTERVAL
    ELSE NULL
  END;

  -- Debit wallet
  UPDATE public.wallets
  SET balance = balance - v_tier.price_tokens, updated_at = NOW()
  WHERE user_id = v_uid;

  INSERT INTO public.wallet_transactions (user_id, amount, type, description)
  VALUES (v_uid, -v_tier.price_tokens, 'purchase', 'اشتراك ' || v_tier.name);

  -- Upsert subscription
  INSERT INTO public.user_subscriptions
    (user_id, tier_id, status, starts_at, expires_at)
  VALUES
    (v_uid, v_tier.id, 'active', NOW(), v_expires_at)
  ON CONFLICT (user_id, tier_id) DO UPDATE SET
    status     = 'active',
    starts_at  = NOW(),
    expires_at = EXCLUDED.expires_at;

  RETURN jsonb_build_object(
    'success',    TRUE,
    'tier',       v_tier.name,
    'expires_at', v_expires_at
  );
END;
$$;

-- cancel_subscription RPC
CREATE OR REPLACE FUNCTION public.cancel_subscription(
  p_tier_type TEXT
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  UPDATE public.user_subscriptions us
  SET    status = 'cancelled'
  FROM   public.subscription_tiers st
  WHERE  us.tier_id = st.id
    AND  st.type    = p_tier_type
    AND  us.user_id = auth.uid()
    AND  us.status  = 'active';
  RETURN FOUND;
END;
$$;
