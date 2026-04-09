-- ============================================================
-- Migration 002: Diwan realtime fields + listener RPCs
-- + auto-archive trigger
-- ============================================================

-- -------------------------------------------------------
-- 1. Add new columns to diwans
-- -------------------------------------------------------
ALTER TABLE public.diwans
  ADD COLUMN IF NOT EXISTS host_name       TEXT,
  ADD COLUMN IF NOT EXISTS is_live         BOOLEAN      NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS listener_count  INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS voice_count     INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- -------------------------------------------------------
-- 2. Enable Realtime for the diwans table
-- -------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE public.diwans;

-- -------------------------------------------------------
-- 3. RPC: increment_listener_count
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_listener_count(p_diwan_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.diwans
  SET
    listener_count   = listener_count + 1,
    last_activity_at = NOW()
  WHERE id = p_diwan_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_listener_count(UUID)
  TO authenticated, anon;

-- -------------------------------------------------------
-- 4. RPC: decrement_listener_count (floor at 0)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decrement_listener_count(p_diwan_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.diwans
  SET listener_count = GREATEST(listener_count - 1, 0)
  WHERE id = p_diwan_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.decrement_listener_count(UUID)
  TO authenticated, anon;

-- -------------------------------------------------------
-- 5. Function: auto_archive_inactive_diwans
--    Archives diwans inactive for more than 4 hours.
--    Called by the scheduled Edge Function.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auto_archive_inactive_diwans()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.diwans
  SET
    is_live        = FALSE,
    voice_count    = 0,
    listener_count = 0
  WHERE
    is_live = TRUE
    AND last_activity_at < NOW() - INTERVAL '4 hours';

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.auto_archive_inactive_diwans()
  TO service_role;

-- -------------------------------------------------------
-- 6. Trigger: update last_activity_at on voice_count change
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.touch_diwan_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.voice_count <> OLD.voice_count THEN
    NEW.last_activity_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_diwan_activity ON public.diwans;

CREATE TRIGGER trg_touch_diwan_activity
  BEFORE UPDATE ON public.diwans
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_diwan_activity();

-- -------------------------------------------------------
-- 7. Performance indexes
-- -------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_diwans_is_live
  ON public.diwans (is_live)
  WHERE is_live = TRUE;

CREATE INDEX IF NOT EXISTS idx_diwans_last_activity
  ON public.diwans (last_activity_at)
  WHERE is_live = TRUE;
