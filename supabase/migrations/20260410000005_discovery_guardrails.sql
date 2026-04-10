-- ============================================================
-- Migration 005: Discovery & Guardrails
-- ============================================================

-- -------------------------------------------------------
-- 1. tags
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tags (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT        NOT NULL UNIQUE,
  slug       TEXT        NOT NULL UNIQUE,
  color      TEXT        NOT NULL DEFAULT '#B8973F',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read tags"
  ON public.tags FOR SELECT USING (TRUE);

-- Seed initial Arabic categories
INSERT INTO public.tags (name, slug, color) VALUES
  ('#تقنية',  'tech',       '#4A90D9'),
  ('#سياسة',  'politics',   '#E57373'),
  ('#أدب',    'literature', '#B8973F'),
  ('#اقتصاد', 'economy',    '#66BB6A'),
  ('#رياضة',  'sports',     '#FF7043'),
  ('#علوم',   'science',    '#7B1FA2'),
  ('#ثقافة',  'culture',    '#26A69A'),
  ('#تاريخ',  'history',    '#8D6E63')
ON CONFLICT (slug) DO NOTHING;

-- -------------------------------------------------------
-- 2. diwan_tags (many-to-many)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_tags (
  diwan_id UUID NOT NULL REFERENCES public.diwans(id)  ON DELETE CASCADE,
  tag_id   UUID NOT NULL REFERENCES public.tags(id)    ON DELETE CASCADE,
  PRIMARY KEY (diwan_id, tag_id)
);

ALTER TABLE public.diwan_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read diwan_tags"
  ON public.diwan_tags FOR SELECT USING (TRUE);

CREATE POLICY "Diwan owners can tag their own diwans"
  ON public.diwan_tags FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id AND d.owner_id = auth.uid()
    )
  );

CREATE POLICY "Diwan owners can remove tags"
  ON public.diwan_tags FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id AND d.owner_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_diwan_tags_tag ON public.diwan_tags (tag_id);
CREATE INDEX IF NOT EXISTS idx_diwan_tags_diwan ON public.diwan_tags (diwan_id);

-- -------------------------------------------------------
-- 3. Trending algorithm: get_trending_diwans
-- hotness = listener_count*2 + voice_count*5 + live_bonus - age_decay
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_trending_diwans(p_limit INT DEFAULT 20)
RETURNS SETOF public.diwans
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT d.*
  FROM   public.diwans d
  WHERE  d.is_public = TRUE
    AND  NOT EXISTS (
           SELECT 1 FROM public.blocks b
           WHERE  b.blocker_id = auth.uid() AND b.blocked_id = d.owner_id
         )
  ORDER BY (
    d.listener_count * 2
    + d.voice_count  * 5
    + CASE WHEN d.is_live THEN 50 ELSE 0 END
    - GREATEST(0,
        EXTRACT(EPOCH FROM (NOW() -
          COALESCE(d.last_activity_at, d.created_at))
        ) / 3600.0 * 0.5
      )
  ) DESC NULLS LAST
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.get_trending_diwans(INT)
  TO authenticated, anon;

-- -------------------------------------------------------
-- 4. blocks
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.blocks (
  blocker_id UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id)
);

ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own blocks"
  ON public.blocks FOR ALL TO authenticated
  USING  (blocker_id = auth.uid())
  WITH CHECK (blocker_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON public.blocks (blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON public.blocks (blocked_id);

-- -------------------------------------------------------
-- 5. RLS: hide diwans whose host is blocked by the viewer
-- (replaces/adds to existing diwan SELECT policy)
-- -------------------------------------------------------
DROP POLICY IF EXISTS "Hide diwans from blocked hosts" ON public.diwans;
CREATE POLICY "Hide diwans from blocked hosts"
  ON public.diwans FOR SELECT
  USING (
    NOT EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE b.blocker_id = auth.uid() AND b.blocked_id = diwans.owner_id
    )
  );

-- -------------------------------------------------------
-- 6. reports
-- -------------------------------------------------------
CREATE TYPE public.report_content_type AS ENUM (
  'diwan', 'voice', 'user', 'message'
);

CREATE TYPE public.report_status AS ENUM (
  'pending', 'reviewed', 'resolved', 'dismissed'
);

CREATE TABLE IF NOT EXISTS public.reports (
  id           UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id  UUID                        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_type public.report_content_type  NOT NULL,
  content_id   UUID                        NOT NULL,
  reason       TEXT                        NOT NULL,
  description  TEXT,
  status       public.report_status        NOT NULL DEFAULT 'pending',
  created_at   TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
  UNIQUE (reporter_id, content_type, content_id)
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create reports"
  ON public.reports FOR INSERT TO authenticated
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Users can read their own reports"
  ON public.reports FOR SELECT TO authenticated
  USING (reporter_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_reports_reporter ON public.reports (reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_content  ON public.reports (content_type, content_id);

-- -------------------------------------------------------
-- 7. diwan_bans (permanent kick from a diwan)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_bans (
  diwan_id   UUID        NOT NULL REFERENCES public.diwans(id)    ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES public.profiles(id)  ON DELETE CASCADE,
  banned_by  UUID        REFERENCES public.profiles(id),
  reason     TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (diwan_id, user_id)
);

ALTER TABLE public.diwan_bans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Hosts can insert bans"
  ON public.diwan_bans FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = diwan_bans.diwan_id
        AND dp.user_id  = auth.uid()
        AND dp.role     = 'host'
    )
  );

CREATE POLICY "Hosts can read bans for their diwans"
  ON public.diwan_bans FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = diwan_bans.diwan_id
        AND dp.user_id  = auth.uid()
        AND dp.role     = 'host'
    )
  );

CREATE POLICY "Hosts can delete (lift) bans"
  ON public.diwan_bans FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwan_participants dp
      WHERE dp.diwan_id = diwan_bans.diwan_id
        AND dp.user_id  = auth.uid()
        AND dp.role     = 'host'
    )
  );

CREATE INDEX IF NOT EXISTS idx_diwan_bans_diwan ON public.diwan_bans (diwan_id);
CREATE INDEX IF NOT EXISTS idx_diwan_bans_user  ON public.diwan_bans (user_id);

-- -------------------------------------------------------
-- 8. Full-text search indexes
-- -------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_fts
  ON public.profiles USING gin(
    to_tsvector('simple',
      COALESCE(display_name,'') || ' ' || COALESCE(username,'') || ' ' || COALESCE(bio,''))
  );

CREATE INDEX IF NOT EXISTS idx_diwans_fts
  ON public.diwans USING gin(
    to_tsvector('simple',
      title || ' ' || COALESCE(description,''))
  );

CREATE INDEX IF NOT EXISTS idx_voices_fts
  ON public.voices USING gin(
    to_tsvector('simple', title)
  );

-- -------------------------------------------------------
-- 9. Global Search RPC
-- Searches profiles, diwans, and voices simultaneously.
-- Respects blocks at DB level.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.global_search(
  p_query TEXT,
  p_limit INT DEFAULT 15
)
RETURNS TABLE (
  entity_type TEXT,
  id          UUID,
  title       TEXT,
  subtitle    TEXT,
  avatar_url  TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH combined AS (
    -- Profiles
    SELECT
      'profile'::TEXT                                               AS entity_type,
      p.id,
      COALESCE(p.display_name, p.username, '')::TEXT               AS title,
      COALESCE(p.bio, '')::TEXT                                     AS subtitle,
      p.avatar_url
    FROM public.profiles p
    WHERE
      to_tsvector('simple',
        COALESCE(p.display_name,'') || ' ' || COALESCE(p.username,'') || ' ' || COALESCE(p.bio,'')
      ) @@ plainto_tsquery('simple', p_query)
      OR COALESCE(p.display_name,'') ILIKE '%' || p_query || '%'
      OR COALESCE(p.username,'')     ILIKE '%' || p_query || '%'

    UNION ALL

    -- Diwans (blocked hosts auto-excluded by RLS, but SECURITY DEFINER
    -- bypasses RLS, so we guard explicitly)
    SELECT
      'diwan'::TEXT,
      d.id,
      d.title::TEXT,
      COALESCE(d.description, '')::TEXT,
      d.cover_url
    FROM public.diwans d
    WHERE d.is_public = TRUE
      AND (
        to_tsvector('simple', d.title || ' ' || COALESCE(d.description,''))
        @@ plainto_tsquery('simple', p_query)
        OR d.title ILIKE '%' || p_query || '%'
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.blocks b
        WHERE b.blocker_id = auth.uid() AND b.blocked_id = d.owner_id
      )

    UNION ALL

    -- Voices
    SELECT
      'voice'::TEXT,
      v.id,
      v.title::TEXT,
      COALESCE(p.display_name, p.username, '')::TEXT,
      NULL::TEXT
    FROM public.voices v
    JOIN public.profiles p ON p.id = v.speaker_id
    WHERE
      to_tsvector('simple', v.title) @@ plainto_tsquery('simple', p_query)
      OR v.title ILIKE '%' || p_query || '%'
  )
  SELECT * FROM combined
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.global_search(TEXT, INT)
  TO authenticated, anon;
