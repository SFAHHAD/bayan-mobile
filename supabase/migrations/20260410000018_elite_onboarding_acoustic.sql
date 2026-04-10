-- =============================================================================
-- Bayan Mobile v2.2 — Elite Onboarding & Acoustic Identity Infrastructure
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: onboarding_status
-- Tracks per-user onboarding state machine progress.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.onboarding_status (
  user_id             UUID        PRIMARY KEY
                                  REFERENCES auth.users ON DELETE CASCADE,
  welcome_seen        BOOLEAN     NOT NULL DEFAULT false,
  interests_selected  BOOLEAN     NOT NULL DEFAULT false,
  voice_print_created BOOLEAN     NOT NULL DEFAULT false,
  completed           BOOLEAN     NOT NULL DEFAULT false,
  completed_at        TIMESTAMPTZ,
  selected_categories TEXT[]      NOT NULL DEFAULT '{}',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.onboarding_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "onboarding_own"
  ON public.onboarding_status
  USING  (auth.uid() = user_id OR auth.role() = 'service_role')
  WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.touch_onboarding_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_onboarding_updated_at ON public.onboarding_status;
CREATE TRIGGER trg_onboarding_updated_at
  BEFORE UPDATE ON public.onboarding_status
  FOR EACH ROW EXECUTE FUNCTION public.touch_onboarding_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: voice_prints
-- Stores AES-GCM-256 encrypted 5-second intro voice clips.
-- The encryption key NEVER reaches the server — it is kept on-device.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.voice_prints (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  encrypted_audio   TEXT        NOT NULL,   -- base64(nonce||ciphertext||mac)
  duration_seconds  INTEGER     NOT NULL CHECK (duration_seconds > 0 AND duration_seconds <= 30),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id)              -- one acoustic identity per user
);

ALTER TABLE public.voice_prints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "voice_prints_own"
  ON public.voice_prints
  USING  (auth.uid() = user_id OR auth.role() = 'service_role')
  WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.touch_voice_prints_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_voice_prints_updated_at ON public.voice_prints;
CREATE TRIGGER trg_voice_prints_updated_at
  BEFORE UPDATE ON public.voice_prints
  FOR EACH ROW EXECUTE FUNCTION public.touch_voice_prints_updated_at();

-- ---------------------------------------------------------------------------
-- RPC: upsert_onboarding_status
-- Called by OnboardingRepository to atomically update state machine progress.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_onboarding_status(
  p_welcome_seen        BOOLEAN   DEFAULT NULL,
  p_interests_selected  BOOLEAN   DEFAULT NULL,
  p_voice_print_created BOOLEAN   DEFAULT NULL,
  p_completed           BOOLEAN   DEFAULT NULL,
  p_selected_categories TEXT[]    DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  INSERT INTO onboarding_status (
    user_id,
    welcome_seen,
    interests_selected,
    voice_print_created,
    completed,
    completed_at,
    selected_categories
  ) VALUES (
    v_uid,
    COALESCE(p_welcome_seen,        false),
    COALESCE(p_interests_selected,  false),
    COALESCE(p_voice_print_created, false),
    COALESCE(p_completed,           false),
    CASE WHEN COALESCE(p_completed, false) THEN now() ELSE NULL END,
    COALESCE(p_selected_categories, '{}')
  )
  ON CONFLICT (user_id) DO UPDATE SET
    welcome_seen        = COALESCE(p_welcome_seen,        onboarding_status.welcome_seen),
    interests_selected  = COALESCE(p_interests_selected,  onboarding_status.interests_selected),
    voice_print_created = COALESCE(p_voice_print_created, onboarding_status.voice_print_created),
    completed           = COALESCE(p_completed,           onboarding_status.completed),
    completed_at        = CASE
                            WHEN COALESCE(p_completed, onboarding_status.completed)
                                 AND onboarding_status.completed_at IS NULL
                            THEN now()
                            ELSE onboarding_status.completed_at
                          END,
    selected_categories = COALESCE(p_selected_categories, onboarding_status.selected_categories);
END;
$$;

COMMENT ON FUNCTION public.upsert_onboarding_status IS
  'Idempotent upsert of per-user onboarding state machine. '
  'Only non-NULL parameters are written; existing flags are never cleared.';

-- ---------------------------------------------------------------------------
-- RPC: get_onboarding_status
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_onboarding_status()
RETURNS TABLE (
  welcome_seen        BOOLEAN,
  interests_selected  BOOLEAN,
  voice_print_created BOOLEAN,
  completed           BOOLEAN,
  completed_at        TIMESTAMPTZ,
  selected_categories TEXT[]
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT welcome_seen, interests_selected, voice_print_created,
         completed, completed_at, selected_categories
  FROM   onboarding_status
  WHERE  user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- RPC: warm_feed_with_interests
-- Bulk-upserts explicit interest rows then triggers feed pre-population.
-- Called by FeedWarmupService immediately after the user picks categories.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.warm_feed_with_interests(
  p_categories TEXT[],
  p_weight     NUMERIC DEFAULT 5.0
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cat TEXT;
BEGIN
  FOREACH cat IN ARRAY p_categories LOOP
    PERFORM upsert_user_interest(
      p_category => cat,
      p_delta    => p_weight,
      p_source   => 'explicit'
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION public.warm_feed_with_interests IS
  'Bulk-inserts explicit user interest rows from onboarding category selections. '
  'Weight defaults to 5.0 (maximum boost) so the first feed is 100%% tailored.';
