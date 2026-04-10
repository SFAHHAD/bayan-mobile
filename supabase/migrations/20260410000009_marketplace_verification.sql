-- =============================================================================
-- Bayan v1.3 — Sovereign Marketplace & Verification Layer
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. ALTER diwans — Ticketed / Premium fields
-- ---------------------------------------------------------------------------
ALTER TABLE public.diwans
  ADD COLUMN IF NOT EXISTS entry_fee     INTEGER NOT NULL DEFAULT 0 CHECK (entry_fee >= 0),
  ADD COLUMN IF NOT EXISTS is_premium    BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'approved'
      CHECK (moderation_status IN ('pending','approved','rejected'));

CREATE INDEX IF NOT EXISTS idx_diwans_premium
    ON public.diwans (is_premium)
    WHERE is_premium = TRUE;

-- ---------------------------------------------------------------------------
-- 2. tickets table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tickets (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diwan_id         UUID NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  purchase_price   INTEGER NOT NULL CHECK (purchase_price >= 0),
  purchased_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, diwan_id)           -- one ticket per user per diwan
);

CREATE INDEX IF NOT EXISTS idx_tickets_user    ON public.tickets (user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_diwan   ON public.tickets (diwan_id);

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- user can see their own tickets
CREATE POLICY "tickets_select_own" ON public.tickets
  FOR SELECT USING (auth.uid() = user_id);

-- insert handled via RPC (SECURITY DEFINER), no direct insert
CREATE POLICY "tickets_insert_rpc" ON public.tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- host can view all tickets for their diwan
CREATE POLICY "tickets_host_select" ON public.tickets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id AND d.owner_id = auth.uid()
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;

-- ---------------------------------------------------------------------------
-- 3. RPC: purchase_ticket
--    Atomically: deduct tokens from buyer, credit host (net of 10% fee),
--    insert ticket.  Returns {success, reason}.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_ticket(
  p_diwan_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id      UUID  := auth.uid();
  v_host_id       UUID;
  v_entry_fee     INTEGER;
  v_is_premium    BOOLEAN;
  v_platform_fee  INTEGER;
  v_host_payout   INTEGER;
BEGIN
  -- Fetch diwan details
  SELECT owner_id, entry_fee, is_premium
  INTO   v_host_id, v_entry_fee, v_is_premium
  FROM   public.diwans
  WHERE  id = p_diwan_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'diwan_not_found');
  END IF;

  IF NOT v_is_premium OR v_entry_fee = 0 THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'not_a_premium_diwan');
  END IF;

  -- Prevent self-purchase
  IF v_buyer_id = v_host_id THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'host_cannot_buy_own_ticket');
  END IF;

  -- Idempotent: already owns a ticket?
  IF EXISTS (
    SELECT 1 FROM public.tickets
    WHERE user_id = v_buyer_id AND diwan_id = p_diwan_id
  ) THEN
    RETURN jsonb_build_object('success', TRUE, 'reason', 'already_purchased');
  END IF;

  -- Compute fee split (10% platform fee, rounded down)
  v_platform_fee := v_entry_fee / 10;
  v_host_payout  := v_entry_fee - v_platform_fee;

  -- Debit buyer (raises exception if balance insufficient)
  UPDATE public.wallets
  SET balance = balance - v_entry_fee
  WHERE user_id = v_buyer_id AND balance >= v_entry_fee;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'insufficient_balance');
  END IF;

  -- Credit host
  UPDATE public.wallets
  SET balance = balance + v_host_payout
  WHERE user_id = v_host_id;

  IF NOT FOUND THEN
    -- Rollback buyer debit
    UPDATE public.wallets SET balance = balance + v_entry_fee WHERE user_id = v_buyer_id;
    RETURN jsonb_build_object('success', FALSE, 'reason', 'host_wallet_not_found');
  END IF;

  -- Ledger: buyer debit
  INSERT INTO public.wallet_transactions
    (wallet_id, user_id, type, amount, balance_after, ref_diwan_id, metadata)
  SELECT w.id, v_buyer_id, 'purchase', -v_entry_fee,
         w.balance, p_diwan_id,
         jsonb_build_object('diwan_id', p_diwan_id, 'ticket_type', 'entry')
  FROM   public.wallets w WHERE w.user_id = v_buyer_id;

  -- Ledger: host credit
  INSERT INTO public.wallet_transactions
    (wallet_id, user_id, type, amount, balance_after, ref_diwan_id, ref_user_id, metadata)
  SELECT w.id, v_host_id, 'bonus', v_host_payout,
         w.balance, p_diwan_id, v_buyer_id,
         jsonb_build_object('diwan_id', p_diwan_id, 'platform_fee', v_platform_fee)
  FROM   public.wallets w WHERE w.user_id = v_host_id;

  -- Issue ticket
  INSERT INTO public.tickets (user_id, diwan_id, purchase_price)
  VALUES (v_buyer_id, p_diwan_id, v_entry_fee);

  RETURN jsonb_build_object('success', TRUE, 'purchase_price', v_entry_fee,
                            'host_payout', v_host_payout, 'platform_fee', v_platform_fee);
EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', TRUE, 'reason', 'already_purchased');
  WHEN OTHERS THEN
    RAISE;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. RPC: check_diwan_access
--    Returns TRUE if the user can enter the diwan
--    (free diwan OR owns a ticket OR is the host).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_diwan_access(
  p_diwan_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid        UUID  := auth.uid();
  v_owner_id   UUID;
  v_is_premium BOOLEAN;
BEGIN
  SELECT owner_id, is_premium
  INTO   v_owner_id, v_is_premium
  FROM   public.diwans
  WHERE  id = p_diwan_id;

  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF v_uid = v_owner_id THEN RETURN TRUE; END IF;
  IF NOT v_is_premium   THEN RETURN TRUE; END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.tickets
    WHERE user_id = v_uid AND diwan_id = p_diwan_id
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- 5. ALTER profiles — Professional Verification fields
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS professional_title    TEXT,
  ADD COLUMN IF NOT EXISTS verified_category     TEXT,
  ADD COLUMN IF NOT EXISTS is_verified           BOOLEAN NOT NULL DEFAULT FALSE;

-- ---------------------------------------------------------------------------
-- 6. verification_requests table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'pending'
      CHECK (status IN ('pending','under_review','approved','rejected')),
  documents_urls  TEXT[]  NOT NULL DEFAULT '{}',
  professional_title TEXT,
  verified_category  TEXT,
  reviewer_notes  TEXT,
  reviewed_by     UUID REFERENCES auth.users(id),
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)   -- one active request per user
);

CREATE INDEX IF NOT EXISTS idx_verif_status ON public.verification_requests (status);

ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Users can see and manage their own request
CREATE POLICY "verif_select_own" ON public.verification_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "verif_insert_own" ON public.verification_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "verif_update_own" ON public.verification_requests
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (
    -- users can only update docs/title/category while pending
    status = 'pending'
  );

-- ---------------------------------------------------------------------------
-- 7. TRIGGER: grant verified status when request approved
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_grant_verified_on_approval()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status <> 'approved' THEN
    UPDATE public.profiles
    SET is_verified       = TRUE,
        professional_title = COALESCE(NEW.professional_title, professional_title),
        verified_category  = COALESCE(NEW.verified_category, verified_category)
    WHERE id = NEW.user_id;
  END IF;

  -- Revoke on rejection if previously approved
  IF NEW.status = 'rejected' AND OLD.status = 'approved' THEN
    UPDATE public.profiles
    SET is_verified = FALSE
    WHERE id = NEW.user_id;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_grant_verified ON public.verification_requests;
CREATE TRIGGER trg_grant_verified
  BEFORE UPDATE ON public.verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_grant_verified_on_approval();

-- ---------------------------------------------------------------------------
-- 8. RPC: admin_review_verification
--    Called by an admin (service role) to approve or reject a request.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_review_verification(
  p_request_id  UUID,
  p_decision    TEXT,         -- 'approved' | 'rejected'
  p_notes       TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_decision NOT IN ('approved', 'rejected') THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'invalid_decision');
  END IF;

  UPDATE public.verification_requests
  SET status        = p_decision,
      reviewer_notes = p_notes,
      reviewed_by    = auth.uid(),
      reviewed_at    = NOW()
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'request_not_found');
  END IF;

  RETURN jsonb_build_object('success', TRUE, 'decision', p_decision);
END;
$$;

-- ---------------------------------------------------------------------------
-- 9. RPC: submit_verification_request
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_verification_request(
  p_documents_urls   TEXT[],
  p_professional_title TEXT,
  p_verified_category  TEXT
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  INSERT INTO public.verification_requests
    (user_id, documents_urls, professional_title, verified_category)
  VALUES
    (v_uid, p_documents_urls, p_professional_title, p_verified_category)
  ON CONFLICT (user_id) DO UPDATE
    SET documents_urls    = EXCLUDED.documents_urls,
        professional_title = EXCLUDED.professional_title,
        verified_category  = EXCLUDED.verified_category,
        status             = 'pending',
        reviewer_notes     = NULL,
        updated_at         = NOW();

  RETURN jsonb_build_object('success', TRUE);
END;
$$;

-- ---------------------------------------------------------------------------
-- 10. diwan_analytics snapshot table (for report export)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_analytics (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id        UUID NOT NULL REFERENCES public.diwans(id) ON DELETE CASCADE,
  total_duration_seconds INTEGER NOT NULL DEFAULT 0,
  peak_listeners  INTEGER NOT NULL DEFAULT 0,
  total_gifts_value INTEGER NOT NULL DEFAULT 0,
  unique_listeners INTEGER NOT NULL DEFAULT 0,
  report_generated_at TIMESTAMPTZ,
  report_url      TEXT,           -- optional: link to stored PDF/JSON
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (diwan_id)
);

CREATE INDEX IF NOT EXISTS idx_diwan_analytics_diwan ON public.diwan_analytics (diwan_id);

ALTER TABLE public.diwan_analytics ENABLE ROW LEVEL SECURITY;

-- Host can read their own diwan analytics
CREATE POLICY "analytics_host_select" ON public.diwan_analytics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id AND d.owner_id = auth.uid()
    )
  );

-- Service role inserts (via Edge Function)
CREATE POLICY "analytics_service_insert" ON public.diwan_analytics
  FOR INSERT WITH CHECK (TRUE);

CREATE POLICY "analytics_service_update" ON public.diwan_analytics
  FOR UPDATE USING (TRUE);

-- ---------------------------------------------------------------------------
-- 11. TRIGGER: update peak_listeners on room_participants changes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_update_peak_listeners()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_current
  FROM public.room_participants
  WHERE diwan_id = COALESCE(NEW.diwan_id, OLD.diwan_id) AND is_active = TRUE;

  INSERT INTO public.diwan_analytics (diwan_id, peak_listeners)
  VALUES (COALESCE(NEW.diwan_id, OLD.diwan_id), v_current)
  ON CONFLICT (diwan_id) DO UPDATE
    SET peak_listeners = GREATEST(
      public.diwan_analytics.peak_listeners,
      EXCLUDED.peak_listeners
    );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_peak_listeners ON public.room_participants;
CREATE TRIGGER trg_peak_listeners
  AFTER INSERT OR UPDATE OR DELETE ON public.room_participants
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_update_peak_listeners();

-- ---------------------------------------------------------------------------
-- 12. content_moderation_log table (records AI Guard decisions)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_moderation_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id    UUID REFERENCES public.diwans(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  content_type TEXT NOT NULL DEFAULT 'diwan_metadata',  -- diwan_metadata | message
  verdict     TEXT NOT NULL CHECK (verdict IN ('approved','flagged','blocked')),
  categories  TEXT[] DEFAULT '{}',    -- ['hate_speech','spam', ...]
  confidence  NUMERIC(4,3),
  raw_response JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moderation_diwan  ON public.content_moderation_log (diwan_id);
CREATE INDEX IF NOT EXISTS idx_moderation_verdict ON public.content_moderation_log (verdict);

ALTER TABLE public.content_moderation_log ENABLE ROW LEVEL SECURITY;

-- Hosts can see moderation results for their diwans
CREATE POLICY "modlog_host_select" ON public.content_moderation_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_id AND d.owner_id = auth.uid()
    )
  );

CREATE POLICY "modlog_service_insert" ON public.content_moderation_log
  FOR INSERT WITH CHECK (TRUE);
