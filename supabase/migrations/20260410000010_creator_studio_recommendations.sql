-- =============================================================================
-- Bayan v1.4 — Creator Studio & AI Recommendation Infrastructure
-- NOTE on AI Embeddings: Full vector-embedding personalisation (pgvector /
-- OpenAI ada-002) is declared as a future upgrade.  The current feed ranking
-- uses tag-based cosine-like weighting:
--   40% interest overlap  |  30% social graph proximity  |  30% trending score
-- Replace score_interests / score_social / score_trending with embedding
-- similarity queries once pgvector is enabled.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. diwan_series
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_series (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  cover_url   TEXT,
  category    TEXT,
  episode_count INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_series_host   ON public.diwan_series (host_id);
CREATE INDEX IF NOT EXISTS idx_series_active ON public.diwan_series (is_active)
    WHERE is_active = TRUE;

ALTER TABLE public.diwan_series ENABLE ROW LEVEL SECURITY;

CREATE POLICY "series_select_all" ON public.diwan_series
  FOR SELECT USING (TRUE);

CREATE POLICY "series_host_write" ON public.diwan_series
  FOR ALL USING (auth.uid() = host_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.diwan_series;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := NOW(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_series_updated_at ON public.diwan_series;
CREATE TRIGGER trg_series_updated_at
  BEFORE UPDATE ON public.diwan_series
  FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

-- ---------------------------------------------------------------------------
-- 2. ALTER diwans — link to series
-- ---------------------------------------------------------------------------
ALTER TABLE public.diwans
  ADD COLUMN IF NOT EXISTS series_id    UUID REFERENCES public.diwan_series(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS episode_number INTEGER;

CREATE INDEX IF NOT EXISTS idx_diwans_series ON public.diwans (series_id)
    WHERE series_id IS NOT NULL;

-- Maintain series episode_count automatically
CREATE OR REPLACE FUNCTION public.fn_sync_series_episode_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.series_id IS NOT NULL THEN
    UPDATE public.diwan_series
    SET episode_count = episode_count + 1, updated_at = NOW()
    WHERE id = NEW.series_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.series_id IS DISTINCT FROM NEW.series_id THEN
      IF OLD.series_id IS NOT NULL THEN
        UPDATE public.diwan_series
        SET episode_count = GREATEST(0, episode_count - 1), updated_at = NOW()
        WHERE id = OLD.series_id;
      END IF;
      IF NEW.series_id IS NOT NULL THEN
        UPDATE public.diwan_series
        SET episode_count = episode_count + 1, updated_at = NOW()
        WHERE id = NEW.series_id;
      END IF;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.series_id IS NOT NULL THEN
    UPDATE public.diwan_series
    SET episode_count = GREATEST(0, episode_count - 1), updated_at = NOW()
    WHERE id = OLD.series_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_series_episode_count ON public.diwans;
CREATE TRIGGER trg_series_episode_count
  AFTER INSERT OR UPDATE OR DELETE ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.fn_sync_series_episode_count();

-- ---------------------------------------------------------------------------
-- 3. series_subscriptions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.series_subscriptions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  series_id   UUID NOT NULL REFERENCES public.diwan_series(id) ON DELETE CASCADE,
  notify_new  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, series_id)
);

CREATE INDEX IF NOT EXISTS idx_series_sub_user   ON public.series_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS idx_series_sub_series ON public.series_subscriptions (series_id);

ALTER TABLE public.series_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "series_sub_own" ON public.series_subscriptions
  FOR ALL USING (auth.uid() = user_id);

-- Notify series subscribers when a new diwan episode is added
CREATE OR REPLACE FUNCTION public.fn_notify_series_subscribers()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  IF NEW.series_id IS NOT NULL AND (OLD.series_id IS NULL OR OLD.series_id <> NEW.series_id) THEN
    INSERT INTO public.notifications
      (user_id, type, title, body, action_url, metadata)
    SELECT
      ss.user_id,
      'series_new_episode',
      'حلقة جديدة في ' || ds.title,
      COALESCE(NEW.title, 'حلقة جديدة'),
      'bayan://diwan/' || NEW.id,
      jsonb_build_object('series_id', NEW.series_id, 'diwan_id', NEW.id,
                         'episode_number', NEW.episode_number)
    FROM public.series_subscriptions ss
    JOIN public.diwan_series ds ON ds.id = ss.series_id
    WHERE ss.series_id = NEW.series_id
      AND ss.notify_new = TRUE
      AND ss.user_id <> NEW.owner_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_series_subscribers ON public.diwans;
CREATE TRIGGER trg_notify_series_subscribers
  AFTER INSERT OR UPDATE ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.fn_notify_series_subscribers();

-- ---------------------------------------------------------------------------
-- 4. user_interests
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_interests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category    TEXT NOT NULL,
  weight      NUMERIC(5,3) NOT NULL DEFAULT 1.000 CHECK (weight >= 0 AND weight <= 10),
  source      TEXT NOT NULL DEFAULT 'explicit'
      CHECK (source IN ('explicit','implicit','admin')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, category)
);

CREATE INDEX IF NOT EXISTS idx_interests_user ON public.user_interests (user_id);

ALTER TABLE public.user_interests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "interests_own" ON public.user_interests
  FOR ALL USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS trg_interests_updated_at ON public.user_interests;
CREATE TRIGGER trg_interests_updated_at
  BEFORE UPDATE ON public.user_interests
  FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. activity_logs  (Privacy-first: no PII beyond user_id)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL
      CHECK (action_type IN (
        'joined_diwan','left_diwan','purchased_ticket',
        'followed_user','unfollowed_user',
        'upvoted_question','voted_poll',
        'sent_gift','viewed_profile'
      )),
  metadata    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_user       ON public.activity_logs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_type       ON public.activity_logs (action_type);

ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Users can read their own logs
CREATE POLICY "activity_select_own" ON public.activity_logs
  FOR SELECT USING (auth.uid() = user_id);

-- Service role inserts (app inserts via service role or SECURITY DEFINER)
CREATE POLICY "activity_insert_own" ON public.activity_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own logs (Clear History)
CREATE POLICY "activity_delete_own" ON public.activity_logs
  FOR DELETE USING (auth.uid() = user_id);

-- RPC: log_activity (used by Flutter so it always goes through auth)
CREATE OR REPLACE FUNCTION public.log_activity(
  p_action_type TEXT,
  p_metadata    JSONB DEFAULT '{}'
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.activity_logs (user_id, action_type, metadata)
  VALUES (auth.uid(), p_action_type, p_metadata);
EXCEPTION
  WHEN check_violation THEN
    NULL; -- silently drop unknown action types
END;
$$;

-- RPC: clear_activity_history (user wipes their own log)
CREATE OR REPLACE FUNCTION public.clear_activity_history()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  DELETE FROM public.activity_logs WHERE user_id = auth.uid();
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. UPDATE notifications table — add action_url and metadata columns
--    (Used for interactive push notification actions)
-- ---------------------------------------------------------------------------
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS action_url TEXT,
  ADD COLUMN IF NOT EXISTS action_type TEXT DEFAULT 'open'
      CHECK (action_type IN ('open','join_diwan','view_profile','view_series')),
  ADD COLUMN IF NOT EXISTS metadata   JSONB DEFAULT '{}';

-- ---------------------------------------------------------------------------
-- 7. get_personalized_feed — tag-based weighted recommendation
--
-- NOTE: AI Embedding gap declared.
--   Future upgrade path: replace score_interests with pgvector cosine
--   similarity between user embedding and diwan embedding vectors.
--   Replace score_social with graph-walk centrality.
--   Current implementation uses tag/category intersection weighting.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_personalized_feed(
  p_limit     INTEGER DEFAULT 20,
  p_offset    INTEGER DEFAULT 0
) RETURNS TABLE (
  diwan_id         UUID,
  title            TEXT,
  description      TEXT,
  owner_id         UUID,
  host_name        TEXT,
  cover_url        TEXT,
  is_live          BOOLEAN,
  is_premium       BOOLEAN,
  entry_fee        INTEGER,
  listener_count   INTEGER,
  series_id        UUID,
  moderation_status TEXT,
  score            NUMERIC,
  score_interests  NUMERIC,
  score_social     NUMERIC,
  score_trending   NUMERIC,
  created_at       TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  RETURN QUERY
  WITH
  -- user's interest categories with weights
  user_cats AS (
    SELECT ui.category, ui.weight
    FROM public.user_interests ui
    WHERE ui.user_id = v_uid
  ),
  -- people the user follows
  following AS (
    SELECT f.following_id AS uid
    FROM public.follows f
    WHERE f.follower_id = v_uid
  ),
  -- people who follow the user (mutual reach)
  followers AS (
    SELECT f.follower_id AS uid
    FROM public.follows f
    WHERE f.following_id = v_uid
  ),
  -- diwan tag intersection with user interests
  interest_score AS (
    SELECT
      dt.diwan_id,
      COALESCE(SUM(uc.weight), 0)::NUMERIC AS raw_score
    FROM public.diwan_tags dt
    JOIN user_cats uc ON uc.category = dt.tag
    GROUP BY dt.diwan_id
  ),
  -- social score: diwan owned by someone in social graph
  social_score AS (
    SELECT
      d.id AS diwan_id,
      CASE
        WHEN d.owner_id IN (SELECT uid FROM following)  THEN 3.0
        WHEN d.owner_id IN (SELECT uid FROM followers)  THEN 1.5
        ELSE 0.0
      END::NUMERIC AS raw_score
    FROM public.diwans d
  ),
  -- trending score: normalised listener_count + recency decay
  trending_score AS (
    SELECT
      d.id AS diwan_id,
      (
        COALESCE(d.listener_count, 0)::NUMERIC / NULLIF(
          (SELECT MAX(listener_count) FROM public.diwans WHERE is_live = TRUE), 0
        ) * 5
        +
        CASE WHEN d.is_live THEN 3.0 ELSE 0.0 END
        +
        -- recency: 0→2 based on how recently created (within last 7 days)
        GREATEST(0, 2.0 - EXTRACT(EPOCH FROM (NOW() - d.created_at)) / 604800.0)
      )::NUMERIC AS raw_score
    FROM public.diwans d
  ),
  scored AS (
    SELECT
      d.id                  AS diwan_id,
      d.title,
      d.description,
      d.owner_id,
      d.host_name,
      d.cover_url,
      d.is_live,
      d.is_premium,
      d.entry_fee,
      d.listener_count,
      d.series_id,
      d.moderation_status,
      d.created_at,
      COALESCE(i.raw_score, 0) AS s_interests,
      COALESCE(s.raw_score, 0) AS s_social,
      COALESCE(t.raw_score, 0) AS s_trending,
      (
        0.40 * COALESCE(i.raw_score, 0) +
        0.30 * COALESCE(s.raw_score, 0) +
        0.30 * COALESCE(t.raw_score, 0)
      ) AS total_score
    FROM public.diwans d
    LEFT JOIN interest_score i ON i.diwan_id = d.id
    LEFT JOIN social_score   s ON s.diwan_id = d.id
    LEFT JOIN trending_score t ON t.diwan_id = d.id
    WHERE d.is_public = TRUE
      AND d.moderation_status = 'approved'
      AND d.owner_id <> v_uid  -- exclude own diwans
  )
  SELECT
    sc.diwan_id,
    sc.title,
    sc.description,
    sc.owner_id,
    sc.host_name,
    sc.cover_url,
    sc.is_live,
    sc.is_premium,
    sc.entry_fee,
    sc.listener_count,
    sc.series_id,
    sc.moderation_status,
    sc.total_score        AS score,
    sc.s_interests        AS score_interests,
    sc.s_social           AS score_social,
    sc.s_trending         AS score_trending,
    sc.created_at
  FROM scored sc
  ORDER BY sc.total_score DESC, sc.is_live DESC, sc.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

-- ---------------------------------------------------------------------------
-- 8. upsert_user_interest — increment implicit weight on engagement
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_user_interest(
  p_category TEXT,
  p_delta    NUMERIC DEFAULT 0.1,
  p_source   TEXT    DEFAULT 'implicit'
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.user_interests (user_id, category, weight, source)
  VALUES (auth.uid(), p_category, LEAST(10, p_delta), p_source)
  ON CONFLICT (user_id, category) DO UPDATE
    SET weight = LEAST(10, public.user_interests.weight + p_delta),
        source = EXCLUDED.source,
        updated_at = NOW();
END;
$$;

-- ---------------------------------------------------------------------------
-- 9. diwan_tags helper table (if not exists — used by recommendation engine)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_tags (
  diwan_id UUID NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  tag      TEXT NOT NULL,
  PRIMARY KEY (diwan_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_diwan_tags_tag ON public.diwan_tags (tag);

ALTER TABLE public.diwan_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "diwan_tags_select" ON public.diwan_tags
  FOR SELECT USING (TRUE);

CREATE POLICY "diwan_tags_host_write" ON public.diwan_tags
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id AND d.owner_id = auth.uid()
    )
  );
