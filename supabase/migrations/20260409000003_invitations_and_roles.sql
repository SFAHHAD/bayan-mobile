-- ============================================================
-- Migration 003: Invitations, Diwan Participants, Speak Requests
-- ============================================================

-- -------------------------------------------------------
-- 1. invitations
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.invitations (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT        NOT NULL UNIQUE,
  created_by  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  used_by     UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_used     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_invitations_code
  ON public.invitations (code)
  WHERE is_used = FALSE;

-- RLS
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can validate an unused code"
  ON public.invitations FOR SELECT
  USING (is_used = FALSE);

CREATE POLICY "Founders can view their own codes"
  ON public.invitations FOR SELECT
  TO authenticated
  USING (created_by = auth.uid());

CREATE POLICY "Authenticated users can redeem a code"
  ON public.invitations FOR UPDATE
  TO authenticated
  USING (is_used = FALSE)
  WITH CHECK (used_by = auth.uid());

-- -------------------------------------------------------
-- 2. Trigger: auto-delete invitation once redeemed
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_used_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_used = TRUE AND NEW.used_by IS NOT NULL THEN
    DELETE FROM public.invitations WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_delete_used_invitation ON public.invitations;

CREATE TRIGGER trg_delete_used_invitation
  AFTER UPDATE ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.delete_used_invitation();

-- -------------------------------------------------------
-- 3. Add is_founder to profiles
-- -------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_founder BOOLEAN NOT NULL DEFAULT FALSE;

-- -------------------------------------------------------
-- 4. RPC: generate_founder_codes — 3 unique codes per Founder
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_invitation_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_code TEXT;
  v_exists BOOLEAN;
BEGIN
  LOOP
    v_code := 'BAYAN-' || upper(
      regexp_replace(
        substring(encode(gen_random_bytes(4), 'base64'), 1, 6),
        '[^A-Z0-9]', '0', 'g'
      )
    );
    SELECT EXISTS(SELECT 1 FROM public.invitations WHERE code = v_code)
      INTO v_exists;
    EXIT WHEN NOT v_exists;
  END LOOP;
  RETURN v_code;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_founder_codes(p_user_id UUID)
RETURNS TEXT[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_codes TEXT[] := '{}';
  v_code  TEXT;
  i       INTEGER;
BEGIN
  -- Only founders may generate codes
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = p_user_id AND is_founder = TRUE
  ) THEN
    RAISE EXCEPTION 'User is not a founder';
  END IF;

  FOR i IN 1..3 LOOP
    v_code := public.generate_invitation_code();
    INSERT INTO public.invitations (code, created_by)
    VALUES (v_code, p_user_id);
    v_codes := array_append(v_codes, v_code);
  END LOOP;

  RETURN v_codes;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_founder_codes(UUID)
  TO authenticated;

-- -------------------------------------------------------
-- 5. Trigger: auto-generate 3 codes on first Founder login
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_founder_first_login()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_founder = TRUE AND OLD.is_founder = FALSE THEN
    -- Check they don't already have codes
    IF NOT EXISTS (
      SELECT 1 FROM public.invitations WHERE created_by = NEW.id
    ) THEN
      PERFORM public.generate_founder_codes(NEW.id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_founder_first_login ON public.profiles;

CREATE TRIGGER trg_founder_first_login
  AFTER UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.on_founder_first_login();

-- -------------------------------------------------------
-- 6. diwan_participants
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_participants (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id    UUID        NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role        TEXT        NOT NULL DEFAULT 'listener'
                          CONSTRAINT role_check CHECK (role IN ('host', 'speaker', 'listener')),
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (diwan_id, user_id)
);

ALTER TABLE public.diwan_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants visible to authenticated users"
  ON public.diwan_participants FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Users can join a diwan"
  ON public.diwan_participants FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can leave a diwan"
  ON public.diwan_participants FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Only hosts can update roles (e.g., promote speaker or mute)
CREATE POLICY "Hosts can update participant roles"
  ON public.diwan_participants FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = diwan_participants.diwan_id
        AND dp.user_id  = auth.uid()
        AND dp.role     = 'host'
    )
  );

-- Enable Realtime for participant presence
ALTER PUBLICATION supabase_realtime ADD TABLE public.diwan_participants;

-- -------------------------------------------------------
-- 7. speak_requests
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.speak_requests (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id     UUID        NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status       TEXT        NOT NULL DEFAULT 'pending'
                           CONSTRAINT status_check CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (diwan_id, user_id)
);

ALTER TABLE public.speak_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Hosts can see speak requests"
  ON public.speak_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = speak_requests.diwan_id
        AND dp.user_id  = auth.uid()
        AND dp.role     = 'host'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Authenticated users can request to speak"
  ON public.speak_requests FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Hosts can approve or reject speak requests"
  ON public.speak_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = speak_requests.diwan_id
        AND dp.user_id  = auth.uid()
        AND dp.role     = 'host'
    )
  );

-- Enable Realtime for speak requests
ALTER PUBLICATION supabase_realtime ADD TABLE public.speak_requests;

-- -------------------------------------------------------
-- 8. Performance indexes
-- -------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_participants_diwan
  ON public.diwan_participants (diwan_id);

CREATE INDEX IF NOT EXISTS idx_speak_requests_diwan_pending
  ON public.speak_requests (diwan_id)
  WHERE status = 'pending';
