-- ============================================================
-- Migration 006: Messaging & Analytics Foundation
-- ============================================================

-- -------------------------------------------------------
-- 1. messages table (in-diwan chat)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id    UUID        NOT NULL REFERENCES public.diwans(id)   ON DELETE CASCADE,
  sender_id   UUID        REFERENCES public.profiles(id)          ON DELETE SET NULL,
  content     TEXT        NOT NULL CHECK (LENGTH(TRIM(content)) > 0),
  type        TEXT        NOT NULL DEFAULT 'text'
                          CHECK (type IN ('text', 'system')),
  sender_name TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Handle case where table already existed without type / sender_name
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'text'
    CHECK (type IN ('text', 'system'));

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS sender_name TEXT;

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_messages_diwan_created
  ON public.messages (diwan_id, created_at DESC);

-- Participants can read messages in their diwan
CREATE POLICY "Participants can read messages"
  ON public.messages FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = messages.diwan_id
        AND dp.user_id  = auth.uid()
    )
  );

-- Authenticated users can insert their own text messages
CREATE POLICY "Users can send messages"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND type = 'text'
  );

-- System messages are inserted by backend / triggers (SECURITY DEFINER fns)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Enable Realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- -------------------------------------------------------
-- 2. System-message helpers
-- -------------------------------------------------------

-- Internal function to post a system message (called by triggers)
CREATE OR REPLACE FUNCTION public._post_system_message(
  p_diwan_id UUID,
  p_content  TEXT
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
AS $$
  INSERT INTO public.messages (diwan_id, sender_id, content, type, sender_name)
  VALUES (p_diwan_id, NULL, p_content, 'system', 'النظام');
$$;

-- Trigger: when a user's role becomes 'speaker', post a system message
CREATE OR REPLACE FUNCTION public.trg_fn_speaker_joined_msg()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_name TEXT;
BEGIN
  IF NEW.role = 'speaker' AND (OLD IS NULL OR OLD.role <> 'speaker') THEN
    SELECT COALESCE(display_name, username, 'مستخدم')
      INTO v_name
      FROM public.profiles
      WHERE id = NEW.user_id;
    PERFORM public._post_system_message(
      NEW.diwan_id,
      v_name || ' انضمّ كمتحدث'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_speaker_joined_msg ON public.diwan_participants;
CREATE TRIGGER trg_speaker_joined_msg
  AFTER INSERT OR UPDATE ON public.diwan_participants
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_speaker_joined_msg();

-- Trigger: when diwan.is_live flips to TRUE, post "Room is now live"
-- when is_live flips to FALSE, post "Room ended"
CREATE OR REPLACE FUNCTION public.trg_fn_diwan_live_msg()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_live = TRUE AND (OLD.is_live IS DISTINCT FROM TRUE) THEN
    PERFORM public._post_system_message(
      NEW.id,
      'بدأ البث المباشر · ' || NEW.title
    );
  ELSIF NEW.is_live = FALSE AND OLD.is_live = TRUE THEN
    PERFORM public._post_system_message(
      NEW.id,
      'انتهى البث المباشر'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_diwan_live_msg ON public.diwans;
CREATE TRIGGER trg_diwan_live_msg
  AFTER UPDATE ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_diwan_live_msg();

-- -------------------------------------------------------
-- 3. Analytics columns on diwans
-- -------------------------------------------------------
ALTER TABLE public.diwans
  ADD COLUMN IF NOT EXISTS peak_listener_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS live_started_at     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS host_minutes        INT NOT NULL DEFAULT 0;

-- Trigger: keep peak_listener_count up-to-date
CREATE OR REPLACE FUNCTION public.trg_fn_update_peak_listeners()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.listener_count > NEW.peak_listener_count THEN
    NEW.peak_listener_count := NEW.listener_count;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_peak_listeners ON public.diwans;
CREATE TRIGGER trg_update_peak_listeners
  BEFORE UPDATE OF listener_count ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_update_peak_listeners();

-- Trigger: record live_started_at when room goes live; accumulate host_minutes when it ends
CREATE OR REPLACE FUNCTION public.trg_fn_diwan_session_track()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_minutes INT;
BEGIN
  IF NEW.is_live = TRUE AND (OLD.is_live IS DISTINCT FROM TRUE) THEN
    NEW.live_started_at := NOW();

  ELSIF NEW.is_live = FALSE AND OLD.is_live = TRUE
    AND OLD.live_started_at IS NOT NULL THEN
    v_minutes := GREATEST(0,
      EXTRACT(EPOCH FROM (NOW() - OLD.live_started_at))::INT / 60
    );
    NEW.host_minutes := COALESCE(NEW.host_minutes, 0) + v_minutes;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_diwan_session_track ON public.diwans;
CREATE TRIGGER trg_diwan_session_track
  BEFORE UPDATE OF is_live ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_diwan_session_track();

-- -------------------------------------------------------
-- 4. Analytics columns on profiles
-- -------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_live_minutes   INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_diwans_hosted  INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS peak_listeners_ever  INT NOT NULL DEFAULT 0;

-- Trigger: increment total_diwans_hosted when a new diwan is created
CREATE OR REPLACE FUNCTION public.trg_fn_diwan_created_counter()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.owner_id IS NOT NULL THEN
    UPDATE public.profiles
       SET total_diwans_hosted = total_diwans_hosted + 1
     WHERE id = NEW.owner_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_diwan_created_counter ON public.diwans;
CREATE TRIGGER trg_diwan_created_counter
  AFTER INSERT ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_diwan_created_counter();

-- Trigger: when a diwan session ends, roll-up host_minutes + peak to owner's profile
CREATE OR REPLACE FUNCTION public.trg_fn_rollup_session_to_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_live = FALSE AND OLD.is_live = TRUE AND NEW.owner_id IS NOT NULL THEN
    UPDATE public.profiles
       SET total_live_minutes  = total_live_minutes + NEW.host_minutes,
           peak_listeners_ever = GREATEST(peak_listeners_ever, NEW.peak_listener_count)
     WHERE id = NEW.owner_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_rollup_session_to_profile ON public.diwans;
CREATE TRIGGER trg_rollup_session_to_profile
  AFTER UPDATE OF is_live ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_rollup_session_to_profile();

-- -------------------------------------------------------
-- 5. user_stats VIEW (security_invoker so RLS applies)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW public.user_stats
WITH (security_invoker = true)
AS
SELECT
  p.id                                                        AS user_id,
  COALESCE(p.total_live_minutes,  0)                         AS total_live_minutes,
  ROUND(COALESCE(p.total_live_minutes, 0) / 60.0, 2)        AS total_hours_hosted,
  COALESCE(p.total_diwans_hosted, 0)                         AS total_diwans_hosted,
  COALESCE(p.peak_listeners_ever, 0)                         AS peak_listeners_ever,
  COALESCE(p.follower_count,      0)                         AS follower_count,
  COALESCE(p.voice_count,         0)                         AS voice_count,
  (
    COALESCE(p.follower_count,     0) * 3
    + COALESCE(p.voice_count,      0) * 5
    + COALESCE(p.total_live_minutes, 0) / 30
  )                                                           AS influence_score
FROM public.profiles p;

-- RPC wrapper (preferred by Flutter clients — avoids direct view access)
CREATE OR REPLACE FUNCTION public.get_user_stats(p_user_id UUID)
RETURNS TABLE (
  user_id            UUID,
  total_live_minutes  INT,
  total_hours_hosted  NUMERIC,
  total_diwans_hosted INT,
  peak_listeners_ever INT,
  follower_count      INT,
  voice_count         INT,
  influence_score     INT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    user_id,
    total_live_minutes,
    total_hours_hosted,
    total_diwans_hosted,
    peak_listeners_ever,
    follower_count,
    voice_count,
    influence_score
  FROM public.user_stats
  WHERE user_id = p_user_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_stats(UUID) TO authenticated;

-- -------------------------------------------------------
-- 6. Performance indexes
-- -------------------------------------------------------

-- Diwan feed: is_public + recency (feed queries)
CREATE INDEX IF NOT EXISTS idx_diwans_public_created
  ON public.diwans (is_public, created_at DESC)
  WHERE is_public = TRUE;

-- Diwan feed: is_live first, then recency (trending queries)
CREATE INDEX IF NOT EXISTS idx_diwans_live_created
  ON public.diwans (is_live DESC, created_at DESC)
  WHERE is_public = TRUE;

-- Voices: per-diwan retrieval
CREATE INDEX IF NOT EXISTS idx_voices_diwan_created
  ON public.voices (diwan_id, created_at DESC);

-- Voices: per-speaker retrieval
CREATE INDEX IF NOT EXISTS idx_voices_speaker_created
  ON public.voices (speaker_id, created_at DESC);

-- Notifications: per-user unread
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, is_read, created_at DESC);

-- Follows: lookup speed
CREATE INDEX IF NOT EXISTS idx_follows_follower
  ON public.follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following
  ON public.follows (following_id);
