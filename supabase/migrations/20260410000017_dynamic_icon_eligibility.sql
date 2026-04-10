-- =============================================================================
-- Bayan Mobile v2.1 — Dynamic Icon Eligibility
-- =============================================================================

-- Ensure profiles has is_sovereign and level columns (non-destructive)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_sovereign BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS level        INTEGER  NOT NULL DEFAULT 0
                                                 CHECK (level >= 0);

-- Index for quick eligibility look-ups
CREATE INDEX IF NOT EXISTS idx_profiles_elite
  ON public.profiles (id)
  WHERE is_sovereign = true OR level >= 50;

-- ---------------------------------------------------------------------------
-- RPC: check_icon_eligibility
--   Called by DynamicIconService to validate server-side whether a user may
--   use the Gold launcher icon.  STABLE + SECURITY DEFINER so the client
--   cannot bypass RLS to snoop other users' data.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_icon_eligibility(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (is_sovereign OR level >= 50),
    false
  )
  FROM profiles
  WHERE id = p_user_id;
$$;

COMMENT ON FUNCTION public.check_icon_eligibility IS
  'Returns TRUE if the user qualifies for the Gold launcher icon '
  '(is_sovereign = true OR level >= 50).';

-- RLS: users may only see their own profile row
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'profiles' AND policyname = 'profiles_select_own'
  ) THEN
    CREATE POLICY "profiles_select_own"
      ON profiles FOR SELECT
      USING (auth.uid() = id OR auth.role() = 'service_role');
  END IF;
END $$;
