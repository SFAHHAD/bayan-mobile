-- =============================================================================
-- Bayan v1.7 — Governance & Production Readiness Layer
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. COMMUNITY GOVERNANCE — نظام الشورى
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.proposals (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id      UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title           TEXT    NOT NULL,
  body            TEXT    NOT NULL DEFAULT '',
  type            TEXT    NOT NULL DEFAULT 'feature'
                  CHECK (type IN ('feature','rule','moderation','other')),
  status          TEXT    NOT NULL DEFAULT 'proposed'
                  CHECK (status IN ('proposed','voting','approved','rejected','withdrawn')),
  yes_votes       INTEGER NOT NULL DEFAULT 0,
  no_votes        INTEGER NOT NULL DEFAULT 0,
  abstain_votes   INTEGER NOT NULL DEFAULT 0,
  voting_starts_at TIMESTAMPTZ,
  voting_ends_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.proposals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "proposals_read_all" ON public.proposals
  FOR SELECT USING (TRUE);

CREATE POLICY "proposals_insert_sovereign" ON public.proposals
  FOR INSERT WITH CHECK (
    public.check_subscription_access('gold') = TRUE
  );

CREATE POLICY "proposals_update_own" ON public.proposals
  FOR UPDATE USING (auth.uid() = creator_id)
  WITH CHECK (auth.uid() = creator_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.proposals;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.fn_proposals_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_proposals_updated_at ON public.proposals;
CREATE TRIGGER trg_proposals_updated_at
  BEFORE UPDATE ON public.proposals
  FOR EACH ROW EXECUTE FUNCTION public.fn_proposals_updated_at();

-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.governance_votes (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id UUID    NOT NULL REFERENCES public.proposals(id) ON DELETE CASCADE,
  user_id     UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vote        TEXT    NOT NULL CHECK (vote IN ('yes','no','abstain')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (proposal_id, user_id)
);

ALTER TABLE public.governance_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "votes_select_all" ON public.governance_votes
  FOR SELECT USING (TRUE);

CREATE POLICY "votes_insert_sovereign" ON public.governance_votes
  FOR INSERT WITH CHECK (
    public.check_subscription_access('gold') = TRUE
    AND NOT EXISTS (
      SELECT 1 FROM public.governance_votes v2
      WHERE v2.proposal_id = proposal_id AND v2.user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_governance_votes_proposal
  ON public.governance_votes (proposal_id);

-- Trigger: update vote tallies on proposals table after insert
CREATE OR REPLACE FUNCTION public.fn_update_vote_tallies()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  UPDATE public.proposals SET
    yes_votes     = (SELECT COUNT(*) FROM public.governance_votes
                     WHERE proposal_id = NEW.proposal_id AND vote = 'yes'),
    no_votes      = (SELECT COUNT(*) FROM public.governance_votes
                     WHERE proposal_id = NEW.proposal_id AND vote = 'no'),
    abstain_votes = (SELECT COUNT(*) FROM public.governance_votes
                     WHERE proposal_id = NEW.proposal_id AND vote = 'abstain'),
    updated_at    = NOW()
  WHERE id = NEW.proposal_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_vote_tallies ON public.governance_votes;
CREATE TRIGGER trg_update_vote_tallies
  AFTER INSERT ON public.governance_votes
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_vote_tallies();

-- cast_vote RPC — atomic, idempotency-safe
CREATE OR REPLACE FUNCTION public.cast_vote(
  p_proposal_id UUID,
  p_vote        TEXT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_uid    UUID := auth.uid();
  v_status TEXT;
BEGIN
  IF NOT public.check_subscription_access('gold') THEN
    RETURN jsonb_build_object('success',FALSE,'error','sovereign_required');
  END IF;

  SELECT status INTO v_status FROM public.proposals WHERE id = p_proposal_id;
  IF v_status IS NULL THEN
    RETURN jsonb_build_object('success',FALSE,'error','proposal_not_found');
  END IF;
  IF v_status != 'voting' THEN
    RETURN jsonb_build_object('success',FALSE,'error','voting_not_open');
  END IF;
  IF EXISTS (SELECT 1 FROM public.governance_votes
             WHERE proposal_id = p_proposal_id AND user_id = v_uid) THEN
    RETURN jsonb_build_object('success',FALSE,'error','already_voted');
  END IF;

  INSERT INTO public.governance_votes (proposal_id, user_id, vote)
  VALUES (p_proposal_id, v_uid, p_vote);

  RETURN jsonb_build_object('success',TRUE,'vote',p_vote);
END;
$$;

-- finalize_proposal RPC — called by admin / cron when voting_ends_at passes
CREATE OR REPLACE FUNCTION public.finalize_proposal(p_proposal_id UUID)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_prop  public.proposals%ROWTYPE;
  v_result TEXT;
BEGIN
  SELECT * INTO v_prop FROM public.proposals WHERE id = p_proposal_id;
  IF v_prop.id IS NULL THEN RETURN 'not_found'; END IF;
  IF v_prop.status NOT IN ('voting','proposed') THEN RETURN v_prop.status; END IF;

  v_result := CASE
    WHEN v_prop.yes_votes > v_prop.no_votes THEN 'approved'
    ELSE 'rejected'
  END;

  UPDATE public.proposals
  SET status = v_result, updated_at = NOW()
  WHERE id = p_proposal_id;

  RETURN v_result;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. TRUST SCORE
-- ---------------------------------------------------------------------------

-- calculate_trust_score — weighted formula
CREATE OR REPLACE FUNCTION public.calculate_trust_score(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public AS $$
DECLARE
  v_xp            INTEGER := 0;
  v_streak        INTEGER := 0;
  v_moderation    INTEGER := 0;
  v_proposals     INTEGER := 0;
  v_votes         INTEGER := 0;
  v_subscription  INTEGER := 0;
  v_score         NUMERIC := 0;
BEGIN
  -- Engagement XP component (max 40 pts)
  SELECT COALESCE(engagement_xp, 0), COALESCE(daily_streak, 0)
  INTO v_xp, v_streak
  FROM public.user_activity_metrics WHERE user_id = p_user_id;

  -- Moderation: deduct for violations (reports accepted)
  -- (stubbed to 0 for now — expand with moderation_events table)

  -- Governance participation
  SELECT COUNT(*) INTO v_proposals
  FROM public.proposals WHERE creator_id = p_user_id;

  SELECT COUNT(*) INTO v_votes
  FROM public.governance_votes WHERE user_id = p_user_id;

  -- Subscription bonus
  IF public.check_subscription_access('founder') THEN
    v_subscription := 30;
  ELSIF public.check_subscription_access('platinum') THEN
    v_subscription := 20;
  ELSIF public.check_subscription_access('gold') THEN
    v_subscription := 10;
  END IF;

  -- Formula: XP_component(40) + streak_component(10) + governance(20) + subscription(30)
  v_score :=
    LEAST(v_xp::NUMERIC / 250.0, 40.0)          -- XP → max 40
    + LEAST(v_streak::NUMERIC * 0.5, 10.0)       -- streak → max 10
    + LEAST(v_proposals * 3.0 + v_votes * 1.0, 20.0) -- governance → max 20
    + v_subscription;                             -- subscription → max 30

  RETURN jsonb_build_object(
    'score',        ROUND(v_score)::INTEGER,
    'xp_component', ROUND(LEAST(v_xp::NUMERIC / 250.0, 40.0))::INTEGER,
    'streak_component', ROUND(LEAST(v_streak::NUMERIC * 0.5, 10.0))::INTEGER,
    'governance_component', ROUND(LEAST(v_proposals * 3.0 + v_votes * 1.0, 20.0))::INTEGER,
    'subscription_component', v_subscription
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. IAP — purchase_receipts
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.purchase_receipts (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform        TEXT    NOT NULL CHECK (platform IN ('apple','google','stripe')),
  product_id      TEXT    NOT NULL,
  transaction_id  TEXT    UNIQUE,
  receipt_data    TEXT    NOT NULL,
  status          TEXT    NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','valid','invalid','expired','refunded')),
  validated_at    TIMESTAMPTZ,
  tier_type       TEXT    CHECK (tier_type IN ('gold','platinum','founder')),
  raw_response    JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.purchase_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipts_own" ON public.purchase_receipts
  FOR ALL USING (auth.uid() = user_id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.fn_receipts_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_receipts_updated_at ON public.purchase_receipts;
CREATE TRIGGER trg_receipts_updated_at
  BEFORE UPDATE ON public.purchase_receipts
  FOR EACH ROW EXECUTE FUNCTION public.fn_receipts_updated_at();

-- activate_subscription_from_receipt RPC
-- Called by PaymentService after server-side validation succeeds
CREATE OR REPLACE FUNCTION public.activate_subscription_from_receipt(
  p_receipt_id   UUID,
  p_tier_type    TEXT,
  p_expires_at   TIMESTAMPTZ DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_uid    UUID;
  v_tier   public.subscription_tiers%ROWTYPE;
BEGIN
  -- Verify receipt belongs to caller and is valid
  SELECT user_id INTO v_uid
  FROM   public.purchase_receipts
  WHERE  id = p_receipt_id AND status = 'valid' AND user_id = auth.uid();

  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success',FALSE,'error','invalid_or_unauthorized_receipt');
  END IF;

  SELECT * INTO v_tier
  FROM   public.subscription_tiers
  WHERE  type = p_tier_type AND is_active = TRUE;

  IF v_tier.id IS NULL THEN
    RETURN jsonb_build_object('success',FALSE,'error','tier_not_found');
  END IF;

  INSERT INTO public.user_subscriptions
    (user_id, tier_id, status, starts_at, expires_at, payment_reference)
  VALUES
    (v_uid, v_tier.id, 'active', NOW(), p_expires_at, p_receipt_id::TEXT)
  ON CONFLICT (user_id, tier_id) DO UPDATE SET
    status     = 'active',
    starts_at  = NOW(),
    expires_at = EXCLUDED.expires_at,
    payment_reference = EXCLUDED.payment_reference;

  RETURN jsonb_build_object('success',TRUE,'tier',v_tier.name,'expires_at',p_expires_at);
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. FCM — user_fcm_tokens
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT    NOT NULL UNIQUE,
  platform   TEXT    NOT NULL CHECK (platform IN ('android','ios','web')),
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fcm_tokens_own" ON public.user_fcm_tokens
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_active
  ON public.user_fcm_tokens (user_id) WHERE is_active = TRUE;

-- upsert_fcm_token RPC
CREATE OR REPLACE FUNCTION public.upsert_fcm_token(
  p_token    TEXT,
  p_platform TEXT
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.user_fcm_tokens (user_id, token, platform)
  VALUES (auth.uid(), p_token, p_platform)
  ON CONFLICT (token) DO UPDATE SET
    user_id    = auth.uid(),
    platform   = p_platform,
    is_active  = TRUE,
    updated_at = NOW();
END;
$$;

-- revoke_fcm_token RPC
CREATE OR REPLACE FUNCTION public.revoke_fcm_token(p_token TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  UPDATE public.user_fcm_tokens
  SET is_active = FALSE, updated_at = NOW()
  WHERE token = p_token AND user_id = auth.uid();
END;
$$;

-- ---------------------------------------------------------------------------
-- 5. DATABASE OPTIMISATION — archive + HNSW tune
-- ---------------------------------------------------------------------------

-- Cold storage table for old activity logs
CREATE TABLE IF NOT EXISTS public.activity_logs_archive (
  LIKE public.activity_logs INCLUDING ALL
);

ALTER TABLE public.activity_logs_archive ENABLE ROW LEVEL SECURITY;
CREATE POLICY "archive_service_role" ON public.activity_logs_archive
  FOR ALL USING (auth.role() = 'service_role');

-- archive_old_activity_logs RPC — safe to run as cron or on-demand
CREATE OR REPLACE FUNCTION public.archive_old_activity_logs(
  p_days_old INTEGER DEFAULT 90
) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH moved AS (
    DELETE FROM public.activity_logs
    WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL
    RETURNING *
  )
  INSERT INTO public.activity_logs_archive SELECT * FROM moved;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Schedule nightly archival at 03:00 UTC
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'archive-activity-logs',
      '0 3 * * *',
      $$SELECT public.archive_old_activity_logs(90)$$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END;
$$;

-- Schedule nightly proposal finalization
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'finalize-expired-proposals',
      '*/30 * * * *',
      $$
        SELECT public.finalize_proposal(id)
        FROM   public.proposals
        WHERE  status = 'voting'
          AND  voting_ends_at < NOW()
      $$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END;
$$;

-- HNSW index tuning: increase ef_search at query time for sub-10ms p99
-- (set connection-level; Supabase Edge Functions can SET this per request)
ALTER INDEX IF EXISTS idx_diwans_embedding_hnsw
  SET (ef_search = 40);

ALTER INDEX IF EXISTS idx_voice_clips_embedding_hnsw
  SET (ef_search = 40);
