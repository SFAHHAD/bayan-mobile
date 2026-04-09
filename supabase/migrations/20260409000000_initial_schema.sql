-- ============================================================
-- Bayan — Initial Schema Migration
-- Run this against your Supabase project via:
--   supabase db push  OR  Supabase Dashboard → SQL Editor
-- ============================================================

-- ----------------------------------------------------------------
-- 1. lead_emails  (waitlist — already exists, kept for reference)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.lead_emails (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email      TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.lead_emails ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can join waitlist"
  ON public.lead_emails FOR INSERT
  WITH CHECK (true);

CREATE POLICY "No public read on waitlist"
  ON public.lead_emails FOR SELECT
  USING (false);

-- ----------------------------------------------------------------
-- 2. profiles  (extends auth.users 1-to-1)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  username     TEXT UNIQUE,
  display_name TEXT,
  bio          TEXT,
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create a profile row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ----------------------------------------------------------------
-- 3. diwans  (collections / rooms for Arabic content)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwans (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  owner_id    UUID REFERENCES public.profiles (id) ON DELETE CASCADE,
  is_public   BOOLEAN NOT NULL DEFAULT TRUE,
  cover_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.diwans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public diwans are viewable by everyone"
  ON public.diwans FOR SELECT
  USING (is_public = TRUE OR auth.uid() = owner_id);

CREATE POLICY "Authenticated users can create diwans"
  ON public.diwans FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their diwans"
  ON public.diwans FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their diwans"
  ON public.diwans FOR DELETE
  USING (auth.uid() = owner_id);

-- Auto-update updated_at on diwans
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS diwans_set_updated_at ON public.diwans;
CREATE TRIGGER diwans_set_updated_at
  BEFORE UPDATE ON public.diwans
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- ----------------------------------------------------------------
-- 4. messages  (messages within a diwan)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id   UUID NOT NULL REFERENCES public.diwans (id) ON DELETE CASCADE,
  sender_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Messages visible to diwan participants"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id
        AND (d.is_public = TRUE OR d.owner_id = auth.uid())
    )
  );

CREATE POLICY "Authenticated users can send messages"
  ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Senders can delete their own messages"
  ON public.messages FOR DELETE
  USING (auth.uid() = sender_id);

-- ----------------------------------------------------------------
-- 5. Indexes for common query patterns
-- ----------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_diwans_owner     ON public.diwans (owner_id);
CREATE INDEX IF NOT EXISTS idx_diwans_public    ON public.diwans (is_public);
CREATE INDEX IF NOT EXISTS idx_messages_diwan   ON public.messages (diwan_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender  ON public.messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles (username);
