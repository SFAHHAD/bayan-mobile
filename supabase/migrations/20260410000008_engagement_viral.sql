-- ============================================================
-- Migration 008: Engagement & Viral Engine
-- ============================================================

-- -------------------------------------------------------
-- 0. E2E Chat — extend messages + diwan session keys
-- -------------------------------------------------------

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.e2e_diwan_keys (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id      UUID        NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  user_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  encrypted_key TEXT        NOT NULL,   -- AES-256 diwan key encrypted with X25519 shared secret
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (diwan_id, user_id)
);

ALTER TABLE public.e2e_diwan_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own diwan key"
  ON public.e2e_diwan_keys FOR ALL TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Participants read their diwan key"
  ON public.e2e_diwan_keys FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- -------------------------------------------------------
-- 1. LIVE POLLS
-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.polls (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id     UUID        NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  host_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question     TEXT        NOT NULL CHECK (char_length(question) BETWEEN 3 AND 300),
  status       TEXT        NOT NULL DEFAULT 'draft'
                           CHECK (status IN ('draft','active','ended')),
  total_votes  INT         NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at     TIMESTAMPTZ
);

ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_polls_diwan_status
  ON public.polls (diwan_id, status);

CREATE POLICY "Host manages polls"
  ON public.polls FOR ALL TO authenticated
  USING  (host_id = auth.uid())
  WITH CHECK (host_id = auth.uid());

CREATE POLICY "Authenticated users read polls"
  ON public.polls FOR SELECT TO authenticated
  USING (TRUE);

ALTER PUBLICATION supabase_realtime ADD TABLE public.polls;

-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.poll_options (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id     UUID  NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  text        TEXT  NOT NULL CHECK (char_length(text) BETWEEN 1 AND 200),
  votes_count INT   NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Host manages poll options"
  ON public.poll_options FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_options.poll_id AND p.host_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_options.poll_id AND p.host_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users read poll options"
  ON public.poll_options FOR SELECT TO authenticated
  USING (TRUE);

ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_options;

-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.poll_votes (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id        UUID        NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  poll_option_id UUID        NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
  user_id        UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (poll_id, user_id)   -- one vote per user per poll
);

ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users cast own votes"
  ON public.poll_votes FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users see own votes"
  ON public.poll_votes FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- -------------------------------------------------------
-- 1a. vote_poll RPC
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.vote_poll(
  p_poll_id        UUID,
  p_option_id      UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id   UUID := auth.uid();
  v_status    TEXT;
  v_poll_id_check UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify poll is active
  SELECT status INTO v_status FROM public.polls WHERE id = p_poll_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Poll not found'; END IF;
  IF v_status <> 'active' THEN RAISE EXCEPTION 'Poll is not active'; END IF;

  -- Verify option belongs to poll
  SELECT poll_id INTO v_poll_id_check FROM public.poll_options WHERE id = p_option_id;
  IF v_poll_id_check <> p_poll_id THEN RAISE EXCEPTION 'Option does not belong to poll'; END IF;

  -- Insert vote (UNIQUE constraint prevents double-voting at DB level)
  INSERT INTO public.poll_votes (poll_id, poll_option_id, user_id)
  VALUES (p_poll_id, p_option_id, v_user_id);

  -- Increment option votes
  UPDATE public.poll_options SET votes_count = votes_count + 1
  WHERE id = p_option_id;

  -- Increment poll total
  UPDATE public.polls SET total_votes = total_votes + 1
  WHERE id = p_poll_id;

  RETURN jsonb_build_object('success', TRUE, 'option_id', p_option_id);

EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'already_voted');
END;
$$;

GRANT EXECUTE ON FUNCTION public.vote_poll(UUID, UUID) TO authenticated;

-- -------------------------------------------------------
-- 1b. start_poll / end_poll (host-only, via RPC for atomicity)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_poll(p_poll_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.polls
  SET status = 'active'
  WHERE id = p_poll_id AND host_id = auth.uid() AND status = 'draft';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Poll not found, already active/ended, or not your poll';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.end_poll(p_poll_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.polls
  SET status = 'ended', ended_at = NOW()
  WHERE id = p_poll_id AND host_id = auth.uid() AND status = 'active';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Poll not found, not active, or not your poll';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.start_poll(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.end_poll(UUID) TO authenticated;

-- -------------------------------------------------------
-- 2. Q&A / QUESTIONS
-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.questions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id      UUID        NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  user_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  text          TEXT        NOT NULL CHECK (char_length(text) BETWEEN 5 AND 500),
  upvotes_count INT         NOT NULL DEFAULT 0,
  is_answered   BOOLEAN     NOT NULL DEFAULT FALSE,
  is_hidden     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_questions_diwan_votes
  ON public.questions (diwan_id, upvotes_count DESC, created_at)
  WHERE is_hidden = FALSE;

CREATE POLICY "Users submit own questions"
  ON public.questions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Authenticated users read visible questions"
  ON public.questions FOR SELECT TO authenticated
  USING (is_hidden = FALSE);

CREATE POLICY "Hosts moderate questions"
  ON public.questions FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = questions.diwan_id AND d.host_id = auth.uid()
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE public.questions;

-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.question_upvotes (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID        NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (question_id, user_id)    -- no double-voting
);

ALTER TABLE public.question_upvotes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own upvotes"
  ON public.question_upvotes FOR ALL TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- -------------------------------------------------------
-- 2a. upvote_question RPC (idempotent)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upvote_question(p_question_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id  UUID := auth.uid();
  v_new_count INT;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  INSERT INTO public.question_upvotes (question_id, user_id)
  VALUES (p_question_id, v_user_id);

  UPDATE public.questions SET upvotes_count = upvotes_count + 1
  WHERE id = p_question_id AND is_hidden = FALSE
  RETURNING upvotes_count INTO v_new_count;

  IF v_new_count IS NULL THEN RAISE EXCEPTION 'Question not found or is hidden'; END IF;

  RETURN jsonb_build_object('success', TRUE, 'upvotes_count', v_new_count);

EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'already_upvoted');
END;
$$;

GRANT EXECUTE ON FUNCTION public.upvote_question(UUID) TO authenticated;

-- -------------------------------------------------------
-- 2b. get_speaker_queue RPC (ordered by prestige score)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_speaker_queue(p_diwan_id UUID)
RETURNS TABLE (
  user_id        UUID,
  display_name   TEXT,
  avatar_url     TEXT,
  prestige_score NUMERIC,
  requested_at   TIMESTAMPTZ
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT
    sr.user_id,
    p.display_name,
    p.avatar_url,
    (
      (SELECT COUNT(*) FROM public.follows WHERE following_id = sr.user_id) * 3
      + COALESCE(p.total_live_minutes, 0) / 60.0
      + COALESCE(p.total_diwans_hosted, 0) * 2
    )::NUMERIC AS prestige_score,
    sr.created_at AS requested_at
  FROM public.speak_requests sr
  JOIN public.profiles p ON p.id = sr.user_id
  WHERE sr.diwan_id = p_diwan_id
    AND sr.status = 'pending'
  ORDER BY prestige_score DESC, sr.created_at ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_speaker_queue(UUID) TO authenticated;

-- -------------------------------------------------------
-- 3. VIRAL REFERRAL ENGINE
-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.referral_codes (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  code       TEXT        NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own referral code"
  ON public.referral_codes FOR ALL TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Authenticated users read referral codes"
  ON public.referral_codes FOR SELECT TO authenticated
  USING (TRUE);

-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.referrals (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referred_id  UUID        NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  rewarded     BOOLEAN     NOT NULL DEFAULT FALSE,
  reward_amount INT        NOT NULL DEFAULT 50,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own referral records"
  ON public.referrals FOR SELECT TO authenticated
  USING (referrer_id = auth.uid() OR referred_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_referrals_referrer
  ON public.referrals (referrer_id);

-- -------------------------------------------------------
-- 3a. get_or_create_referral_code RPC
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_or_create_referral_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_code    TEXT;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  SELECT code INTO v_code FROM public.referral_codes WHERE user_id = v_user_id;
  IF FOUND THEN RETURN v_code; END IF;

  LOOP
    v_code := upper(substring(md5(random()::TEXT || v_user_id::TEXT) FROM 1 FOR 8));
    BEGIN
      INSERT INTO public.referral_codes (user_id, code) VALUES (v_user_id, v_code);
      RETURN v_code;
    EXCEPTION WHEN unique_violation THEN
      -- collision: regenerate
    END;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_referral_code() TO authenticated;

-- -------------------------------------------------------
-- 3b. process_referral RPC (atomic — called once after signup)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_referral(p_referrer_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_user_id   UUID := auth.uid();
  v_referrer_id   UUID;
  v_wallet_id     UUID;
  v_new_balance   INT;
  v_reward        INT := 50;
BEGIN
  IF v_new_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  -- Resolve referrer
  SELECT user_id INTO v_referrer_id
    FROM public.referral_codes WHERE code = upper(p_referrer_code);
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'invalid_code');
  END IF;

  IF v_referrer_id = v_new_user_id THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'self_referral');
  END IF;

  -- Record referral (UNIQUE on referred_id prevents double)
  INSERT INTO public.referrals (referrer_id, referred_id, rewarded, reward_amount)
  VALUES (v_referrer_id, v_new_user_id, TRUE, v_reward);

  -- Credit referrer's wallet
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_referrer_id;
  IF FOUND THEN
    UPDATE public.wallets SET balance = balance + v_reward
    WHERE id = v_wallet_id
    RETURNING balance INTO v_new_balance;

    INSERT INTO public.wallet_transactions
      (wallet_id, user_id, type, amount, balance_after, ref_user_id,
       metadata)
    VALUES
      (v_wallet_id, v_referrer_id, 'bonus', v_reward, v_new_balance,
       v_new_user_id,
       jsonb_build_object('source', 'referral', 'referred_user', v_new_user_id));
  END IF;

  RETURN jsonb_build_object(
    'success',      TRUE,
    'referrer_id',  v_referrer_id,
    'reward',       v_reward
  );

EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'already_referred');
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_referral(TEXT) TO authenticated;
