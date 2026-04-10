-- ============================================================
-- Migration 004: Social Graph, Voice Clips, Notifications
-- ============================================================

-- -------------------------------------------------------
-- 1. Profile social counters
-- -------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS follower_count  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS following_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS voice_count     INTEGER NOT NULL DEFAULT 0;

-- -------------------------------------------------------
-- 2. follows
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.follows (
  follower_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view follows"
  ON public.follows FOR SELECT USING (TRUE);

CREATE POLICY "Authenticated users can follow others"
  ON public.follows FOR INSERT
  TO authenticated
  WITH CHECK (follower_id = auth.uid());

CREATE POLICY "Users can unfollow"
  ON public.follows FOR DELETE
  TO authenticated
  USING (follower_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_follows_follower  ON public.follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows (following_id);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;

-- -------------------------------------------------------
-- 3. Triggers: keep follower/following counters in sync
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_follow_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.profiles SET follower_count  = follower_count  + 1 WHERE id = NEW.following_id;
  UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_follow_insert ON public.follows;
CREATE TRIGGER trg_follow_insert
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE FUNCTION public.on_follow_insert();

CREATE OR REPLACE FUNCTION public.on_follow_delete()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.profiles SET follower_count  = GREATEST(follower_count  - 1, 0) WHERE id = OLD.following_id;
  UPDATE public.profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_follow_delete ON public.follows;
CREATE TRIGGER trg_follow_delete
  AFTER DELETE ON public.follows
  FOR EACH ROW EXECUTE FUNCTION public.on_follow_delete();

-- -------------------------------------------------------
-- 4. RPC: get_mutual_friends
-- Returns profiles that both user_a and user_b follow.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_mutual_friends(p_user_a UUID, p_user_b UUID)
RETURNS TABLE (
  user_id      UUID,
  display_name TEXT,
  username     TEXT,
  avatar_url   TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT p.id, p.display_name, p.username, p.avatar_url
  FROM   public.follows f1
  JOIN   public.follows f2 ON f2.following_id = f1.following_id
  JOIN   public.profiles p ON p.id = f1.following_id
  WHERE  f1.follower_id  = p_user_a
    AND  f2.follower_id  = p_user_b
    AND  f1.following_id <> p_user_a
    AND  f1.following_id <> p_user_b;
$$;

GRANT EXECUTE ON FUNCTION public.get_mutual_friends(UUID, UUID)
  TO authenticated, anon;

-- -------------------------------------------------------
-- 5. Supabase Storage bucket: voice_clips
-- (Ensure bucket exists; idempotent via DO block)
-- -------------------------------------------------------
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('voice_clips', 'voice_clips', FALSE)
  ON CONFLICT (id) DO NOTHING;
END;
$$;

-- Storage RLS: speakers may upload; authenticated users may read own clips
CREATE POLICY "Authenticated users can upload voice clips"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'voice_clips');

CREATE POLICY "Authenticated users can read voice clips"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'voice_clips');

CREATE POLICY "Owners can delete their voice clips"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'voice_clips' AND owner = auth.uid());

-- -------------------------------------------------------
-- 6. voices
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.voices (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id         UUID        NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  speaker_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title            TEXT        NOT NULL,
  storage_path     TEXT        NOT NULL,
  public_url       TEXT,
  duration_seconds INTEGER     NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.voices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view voices"
  ON public.voices FOR SELECT USING (TRUE);

CREATE POLICY "Speakers can insert their own voices"
  ON public.voices FOR INSERT
  TO authenticated
  WITH CHECK (speaker_id = auth.uid());

CREATE POLICY "Speakers can delete their own voices"
  ON public.voices FOR DELETE
  TO authenticated
  USING (speaker_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_voices_diwan   ON public.voices (diwan_id);
CREATE INDEX IF NOT EXISTS idx_voices_speaker ON public.voices (speaker_id);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.voices;

-- -------------------------------------------------------
-- 7. Trigger: keep voice_count on profiles in sync
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_voice_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.profiles SET voice_count = voice_count + 1 WHERE id = NEW.speaker_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_voice_insert ON public.voices;
CREATE TRIGGER trg_voice_insert
  AFTER INSERT ON public.voices
  FOR EACH ROW EXECUTE FUNCTION public.on_voice_insert();

CREATE OR REPLACE FUNCTION public.on_voice_delete()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.profiles SET voice_count = GREATEST(voice_count - 1, 0) WHERE id = OLD.speaker_id;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_voice_delete ON public.voices;
CREATE TRIGGER trg_voice_delete
  AFTER DELETE ON public.voices
  FOR EACH ROW EXECUTE FUNCTION public.on_voice_delete();

-- -------------------------------------------------------
-- 8. notifications
-- -------------------------------------------------------
CREATE TYPE public.notification_type AS ENUM (
  'diwan_live',
  'new_follower',
  'speak_approved',
  'speak_rejected',
  'voice_clip_shared'
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID                      NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type       public.notification_type  NOT NULL,
  title      TEXT                      NOT NULL,
  body       TEXT                      NOT NULL DEFAULT '',
  is_read    BOOLEAN                   NOT NULL DEFAULT FALSE,
  data       JSONB                     NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ               NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own notifications"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can mark their own notifications as read"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, created_at DESC)
  WHERE is_read = FALSE;

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- -------------------------------------------------------
-- 9. Trigger: notify followers when a Diwan goes live
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_followers_on_live_diwan()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.is_live = TRUE AND (OLD.is_live IS DISTINCT FROM TRUE) THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    SELECT
      f.follower_id,
      'diwan_live',
      'ديوانية جديدة مباشرة 🎙',
      COALESCE(p.display_name, 'مضيف') || ' بدأ ديوانية: ' || NEW.title,
      jsonb_build_object('diwan_id', NEW.id, 'host_id', NEW.created_by)
    FROM   public.follows f
    JOIN   public.profiles p ON p.id = NEW.created_by
    WHERE  f.following_id = NEW.created_by
      AND  f.follower_id <> NEW.created_by;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_live_diwan ON public.diwans;
CREATE TRIGGER trg_notify_live_diwan
  AFTER UPDATE ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.notify_followers_on_live_diwan();

-- -------------------------------------------------------
-- 10. Trigger: notify user when they gain a new follower
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_new_follower()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_follower_name TEXT;
BEGIN
  SELECT COALESCE(display_name, username, 'شخص ما')
    INTO v_follower_name
    FROM public.profiles WHERE id = NEW.follower_id;

  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    NEW.following_id,
    'new_follower',
    'متابع جديد',
    v_follower_name || ' بدأ يتابعك',
    jsonb_build_object('follower_id', NEW.follower_id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_new_follower ON public.follows;
CREATE TRIGGER trg_notify_new_follower
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_follower();
