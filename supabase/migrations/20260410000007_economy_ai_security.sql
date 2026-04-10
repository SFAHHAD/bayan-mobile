-- ============================================================
-- Migration 007: Economy & AI Intelligence Layer
-- ============================================================

-- -------------------------------------------------------
-- 1. SCHEDULING SYSTEM
-- -------------------------------------------------------

-- Device tokens for push notifications
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    TEXT        NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own device tokens"
  ON public.device_tokens FOR ALL TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Scheduled Diwans
CREATE TABLE IF NOT EXISTS public.scheduled_diwans (
  id                         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id                   UUID        NOT NULL UNIQUE REFERENCES public.diwans(id) ON DELETE CASCADE,
  host_id                    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  start_time                 TIMESTAMPTZ NOT NULL,
  estimated_duration_minutes INT         NOT NULL DEFAULT 60 CHECK (estimated_duration_minutes > 0),
  reminder_sent              BOOLEAN     NOT NULL DEFAULT FALSE,
  is_cancelled               BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.scheduled_diwans ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_scheduled_start_time
  ON public.scheduled_diwans (start_time)
  WHERE is_cancelled = FALSE AND reminder_sent = FALSE;

-- Hosts can manage their schedules; all authenticated users can read
CREATE POLICY "Hosts manage their scheduled diwans"
  ON public.scheduled_diwans FOR ALL TO authenticated
  USING  (host_id = auth.uid())
  WITH CHECK (host_id = auth.uid());

CREATE POLICY "Authenticated users can view schedules"
  ON public.scheduled_diwans FOR SELECT TO authenticated
  USING (TRUE);

ALTER PUBLICATION supabase_realtime ADD TABLE public.scheduled_diwans;

-- -------------------------------------------------------
-- 2. PRESTIGE ECONOMY — Wallets & Transactions
-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.wallets (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance     INT         NOT NULL DEFAULT 0 CHECK (balance >= 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- Users see only their own wallet
CREATE POLICY "Users see own wallet"
  ON public.wallets FOR SELECT TO authenticated
  USING (user_id = auth.uid());

ALTER PUBLICATION supabase_realtime ADD TABLE public.wallets;

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id     UUID        NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  user_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          TEXT        NOT NULL
                            CHECK (type IN ('gift_sent','gift_received','purchase','bonus','withdrawal')),
  amount        INT         NOT NULL,            -- positive = credit, negative = debit
  balance_after INT         NOT NULL CHECK (balance_after >= 0),
  ref_diwan_id  UUID        REFERENCES public.diwans(id) ON DELETE SET NULL,
  ref_user_id   UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
  metadata      JSONB       NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_wallet_txn_wallet_created
  ON public.wallet_transactions (wallet_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_wallet_txn_user_created
  ON public.wallet_transactions (user_id, created_at DESC);

CREATE POLICY "Users see own transactions"
  ON public.wallet_transactions FOR SELECT TO authenticated
  USING (user_id = auth.uid());

ALTER PUBLICATION supabase_realtime ADD TABLE public.wallet_transactions;

-- Auto-create a wallet for every new profile
CREATE OR REPLACE FUNCTION public.trg_fn_create_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.wallets (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_create_wallet ON public.profiles;
CREATE TRIGGER trg_create_wallet
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_create_wallet();

-- Keep wallets.updated_at in sync
CREATE OR REPLACE FUNCTION public.trg_fn_wallet_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_wallet_updated_at ON public.wallets;
CREATE TRIGGER trg_wallet_updated_at
  BEFORE UPDATE ON public.wallets
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_wallet_updated_at();

-- -------------------------------------------------------
-- 3. send_gift RPC (atomic — runs in a transaction)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.send_gift(
  p_giver_id     UUID,
  p_recipient_id UUID,
  p_diwan_id     UUID,
  p_amount       INT,
  p_gift_type    TEXT DEFAULT 'token'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_giver_wallet_id     UUID;
  v_recipient_wallet_id UUID;
  v_giver_balance       INT;
  v_new_giver_bal       INT;
  v_new_recipient_bal   INT;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Gift amount must be positive';
  END IF;

  IF p_giver_id = p_recipient_id THEN
    RAISE EXCEPTION 'Cannot send gift to yourself';
  END IF;

  -- Lock giver row first (always lock lower UUID first to prevent deadlocks)
  IF p_giver_id < p_recipient_id THEN
    SELECT id, balance INTO v_giver_wallet_id, v_giver_balance
      FROM public.wallets WHERE user_id = p_giver_id FOR UPDATE;
    SELECT id INTO v_recipient_wallet_id
      FROM public.wallets WHERE user_id = p_recipient_id FOR UPDATE;
  ELSE
    SELECT id INTO v_recipient_wallet_id
      FROM public.wallets WHERE user_id = p_recipient_id FOR UPDATE;
    SELECT id, balance INTO v_giver_wallet_id, v_giver_balance
      FROM public.wallets WHERE user_id = p_giver_id FOR UPDATE;
  END IF;

  IF v_giver_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Giver wallet not found';
  END IF;
  IF v_recipient_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Recipient wallet not found';
  END IF;
  IF v_giver_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance: have %, need %', v_giver_balance, p_amount;
  END IF;

  -- Deduct from giver
  UPDATE public.wallets SET balance = balance - p_amount
    WHERE id = v_giver_wallet_id
    RETURNING balance INTO v_new_giver_bal;

  -- Credit to recipient
  UPDATE public.wallets SET balance = balance + p_amount
    WHERE id = v_recipient_wallet_id
    RETURNING balance INTO v_new_recipient_bal;

  -- Ledger entries
  INSERT INTO public.wallet_transactions
    (wallet_id, user_id, type, amount, balance_after, ref_diwan_id, ref_user_id, metadata)
  VALUES
    (v_giver_wallet_id, p_giver_id, 'gift_sent',
     -p_amount, v_new_giver_bal, p_diwan_id, p_recipient_id,
     jsonb_build_object('gift_type', p_gift_type)),
    (v_recipient_wallet_id, p_recipient_id, 'gift_received',
     p_amount, v_new_recipient_bal, p_diwan_id, p_giver_id,
     jsonb_build_object('gift_type', p_gift_type));

  RETURN jsonb_build_object(
    'success',         TRUE,
    'giver_balance',   v_new_giver_bal,
    'gift_type',       p_gift_type,
    'amount',          p_amount
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_gift(UUID, UUID, UUID, INT, TEXT)
  TO authenticated;

-- Credit daily bonus tokens to a user (idempotent per calendar day)
CREATE OR REPLACE FUNCTION public.claim_daily_bonus(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_wallet_id    UUID;
  v_today        DATE := CURRENT_DATE;
  v_already      BOOLEAN;
  v_bonus        INT := 10;
  v_new_balance  INT;
BEGIN
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Wallet not found'; END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.wallet_transactions
    WHERE user_id = p_user_id
      AND type = 'bonus'
      AND created_at::DATE = v_today
  ) INTO v_already;

  IF v_already THEN
    RETURN jsonb_build_object('success', FALSE, 'reason', 'already_claimed');
  END IF;

  UPDATE public.wallets SET balance = balance + v_bonus
    WHERE id = v_wallet_id
    RETURNING balance INTO v_new_balance;

  INSERT INTO public.wallet_transactions
    (wallet_id, user_id, type, amount, balance_after, metadata)
  VALUES
    (v_wallet_id, p_user_id, 'bonus', v_bonus, v_new_balance,
     jsonb_build_object('date', v_today::TEXT));

  RETURN jsonb_build_object('success', TRUE, 'bonus', v_bonus, 'balance', v_new_balance);
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_daily_bonus(UUID) TO authenticated;

-- -------------------------------------------------------
-- 4. AI DIWAN SUMMARIES
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diwan_summaries (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diwan_id      UUID        NOT NULL UNIQUE REFERENCES public.diwans(id) ON DELETE CASCADE,
  transcript    TEXT,
  summary       TEXT,
  key_points    JSONB       NOT NULL DEFAULT '[]',
  status        TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending','processing','done','failed')),
  generated_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.diwan_summaries ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read summaries for public diwans
CREATE POLICY "Authenticated users read summaries"
  ON public.diwan_summaries FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.diwans d
      WHERE d.id = diwan_summaries.diwan_id AND d.is_public = TRUE
    )
  );

-- Only the Edge Function (service role) can write
ALTER PUBLICATION supabase_realtime ADD TABLE public.diwan_summaries;

-- Auto-enqueue a summary job when a diwan session ends (is_live → FALSE)
CREATE OR REPLACE FUNCTION public.trg_fn_enqueue_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_live = FALSE AND OLD.is_live = TRUE THEN
    INSERT INTO public.diwan_summaries (diwan_id, status)
    VALUES (NEW.id, 'pending')
    ON CONFLICT (diwan_id) DO UPDATE SET status = 'pending';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_summary ON public.diwans;
CREATE TRIGGER trg_enqueue_summary
  AFTER UPDATE OF is_live ON public.diwans
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_enqueue_summary();

-- -------------------------------------------------------
-- 5. E2E ENCRYPTION — Public key store
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.e2e_public_keys (
  user_id              UUID        PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  public_key_x25519    TEXT        NOT NULL,   -- Base64-encoded X25519 public key
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.e2e_public_keys ENABLE ROW LEVEL SECURITY;

-- Users can upsert their own public key; all authenticated users can read
CREATE POLICY "Users manage own public key"
  ON public.e2e_public_keys FOR ALL TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Authenticated users read public keys"
  ON public.e2e_public_keys FOR SELECT TO authenticated
  USING (TRUE);

-- -------------------------------------------------------
-- 6. pg_cron reminder scheduler
--    Requires pg_cron extension enabled in Supabase Dashboard:
--    Database → Extensions → pg_cron
--    Then execute the SELECT below once manually (replace placeholders).
-- -------------------------------------------------------

-- SELECT cron.schedule(
--   'bayan-schedule-reminders',
--   '* * * * *',
--   $$
--     SELECT net.http_post(
--       url     := 'https://<PROJECT_REF>.supabase.co/functions/v1/schedule-reminder',
--       headers := '{"Content-Type":"application/json","Authorization":"Bearer <SERVICE_ROLE_KEY>"}'::jsonb,
--       body    := '{}'::jsonb
--     );
--   $$
-- );
