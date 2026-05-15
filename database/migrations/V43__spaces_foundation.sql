-- V43__spaces_foundation.sql
-- Sprint 1 — Spaces v2 Foundation
--
-- Adds the new financial isolation layer described in docs/architecture/workspace_architecture_v2.md.
-- This migration is PURELY ADDITIVE — it does not drop or alter any existing table.
-- All existing workspaces/workspace_members data is preserved and remains functional.
--
-- New tables:
--   personal_ledgers          — 1:1 with auth.users, always private
--   spaces                    — bounded shared financial contexts (replaces shared workspaces UX-wise)
--   space_members             — membership + granular capability overrides
--   space_invites             — invite tokens for spaces (mirrors workspace_invites pattern)
--   space_categories          — categories scoped to a space
--   space_transactions        — expenses inside a space
--   space_transaction_shares  — per-member split of each transaction
--   space_settlements         — who owes whom (net, Splitwise-style)
--   ledger_contributions      — private bridge: space share → personal ledger entry (no duplication)
--
-- RLS pattern (same as V32):
--   All space tables use SECURITY DEFINER helper functions to avoid recursion.
--   personal_ledgers uses direct user_id = auth.uid() — never joinable by others.
--
-- Prerequisite: V26–V42 applied.

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 1 — personal_ledgers
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS personal_ledgers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency     TEXT NOT NULL DEFAULT 'BRL',
  cutoff_day   SMALLINT NOT NULL DEFAULT 5
               CHECK (cutoff_day BETWEEN 1 AND 28),
  settings     JSONB NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE personal_ledgers IS
  'Private financial ledger for a single user. RLS: user_id = auth.uid() only. Never shared.';

CREATE OR REPLACE FUNCTION update_personal_ledger_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER personal_ledger_updated_at
  BEFORE UPDATE ON personal_ledgers
  FOR EACH ROW EXECUTE FUNCTION update_personal_ledger_updated_at();

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 2 — spaces
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS spaces (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  emoji               TEXT,
  color               TEXT,
  description         TEXT,
  type                TEXT NOT NULL DEFAULT 'household'
                      CHECK (type IN ('household', 'trip', 'project', 'family', 'business')),
  owner_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  currency            TEXT NOT NULL DEFAULT 'BRL',
  settings            JSONB NOT NULL DEFAULT '{}',
  starts_at           DATE,
  ends_at             DATE,
  archived_at         TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Link to the legacy workspace this was migrated from (V44 backfill)
  legacy_workspace_id UUID REFERENCES workspaces(id) ON DELETE SET NULL
);

COMMENT ON TABLE spaces IS
  'Bounded shared financial context (house, trip, project). Members see all space data but never each other''s personal ledgers.';

CREATE INDEX ON spaces (owner_id);
CREATE INDEX ON spaces (type);
CREATE INDEX ON spaces (archived_at) WHERE archived_at IS NULL;

CREATE OR REPLACE FUNCTION update_space_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER space_updated_at
  BEFORE UPDATE ON spaces
  FOR EACH ROW EXECUTE FUNCTION update_space_updated_at();

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 3 — space_members
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_members (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id                 UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  user_id                  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role                     TEXT NOT NULL DEFAULT 'member'
                           CHECK (role IN ('owner', 'admin', 'member', 'viewer', 'guest')),
  -- Granular capability overrides (NULL = use role default)
  can_add_expenses         BOOLEAN,
  can_see_balances         BOOLEAN,
  can_see_member_balances  BOOLEAN,
  can_export               BOOLEAN,
  can_see_settlements      BOOLEAN,
  invited_by               UUID REFERENCES auth.users(id),
  joined_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (space_id, user_id)
);

COMMENT ON TABLE space_members IS
  'Membership in a Space with role + optional per-capability overrides. NULL capability = inherit from role.';

CREATE INDEX ON space_members (user_id);
CREATE INDEX ON space_members (space_id);

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 4 — space_invites
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_invites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id      UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'member'
                CHECK (role IN ('admin', 'member', 'viewer', 'guest')),
  preset        TEXT CHECK (preset IN ('colaborador', 'solo_gastos', 'solo_ver', 'personalizado')),
  token         TEXT NOT NULL UNIQUE DEFAULT gen_random_uuid()::text,
  invited_by    UUID NOT NULL REFERENCES auth.users(id),
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days',
  accepted_at   TIMESTAMPTZ,
  declined_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON space_invites (token);
CREATE INDEX ON space_invites (invited_email);
CREATE INDEX ON space_invites (space_id);

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 5 — space_categories
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_categories (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id       UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  name           TEXT NOT NULL,
  icon           TEXT,
  color          TEXT,
  financial_type TEXT NOT NULL DEFAULT 'expense'
                 CHECK (financial_type IN ('expense', 'income', 'transfer')),
  sort_order     SMALLINT NOT NULL DEFAULT 0,
  created_by     UUID REFERENCES auth.users(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (space_id, name)
);

COMMENT ON TABLE space_categories IS
  'Categories scoped to a specific Space. Not shared with personal ledger.';

CREATE INDEX ON space_categories (space_id);

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 6 — space_transactions
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id    UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  category_id UUID REFERENCES space_categories(id) ON DELETE SET NULL,
  paid_by     UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  amount      NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
  description TEXT NOT NULL DEFAULT '',
  date        DATE NOT NULL,
  split_rule  TEXT NOT NULL DEFAULT 'equal'
              CHECK (split_rule IN ('equal', 'custom', 'percentage', 'solo')),
  notes       TEXT,
  receipt_url TEXT,
  locked_at   TIMESTAMPTZ,  -- set when covered by a settlement; blocks edits
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE space_transactions IS
  'An expense recorded inside a Space. Amount is the full bill; splits are in space_transaction_shares.';
COMMENT ON COLUMN space_transactions.locked_at IS
  'Set when a settlement covers this transaction. Locked rows cannot be edited or deleted.';

CREATE INDEX ON space_transactions (space_id, date DESC);
CREATE INDEX ON space_transactions (paid_by);

CREATE OR REPLACE FUNCTION update_space_transaction_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER space_transaction_updated_at
  BEFORE UPDATE ON space_transactions
  FOR EACH ROW EXECUTE FUNCTION update_space_transaction_updated_at();

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 7 — space_transaction_shares
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_transaction_shares (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES space_transactions(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  amount         NUMERIC(14, 2) NOT NULL CHECK (amount >= 0),
  ledger_linked  BOOLEAN NOT NULL DEFAULT FALSE,
  settled        BOOLEAN NOT NULL DEFAULT FALSE,
  settled_at     TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (transaction_id, user_id)
);

COMMENT ON TABLE space_transaction_shares IS
  'One row per participant per transaction. SUM(amount) must equal space_transactions.amount — validated in SpaceRepository.createTransaction().';
COMMENT ON COLUMN space_transaction_shares.ledger_linked IS
  'TRUE once a ledger_contribution row exists for this share. Prevents double-linking.';

CREATE INDEX ON space_transaction_shares (transaction_id);
CREATE INDEX ON space_transaction_shares (user_id);

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 8 — space_settlements
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_settlements (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id     UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  to_user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  amount       NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
  period_start DATE,
  period_end   DATE,
  settled_at   TIMESTAMPTZ,
  settled_by   UUID REFERENCES auth.users(id),
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (from_user_id <> to_user_id)
);

COMMENT ON TABLE space_settlements IS
  'Net settlement between two members. Computed by Splitwise simplification in SpaceRepository.computeSettlements().';

CREATE INDEX ON space_settlements (space_id);
CREATE INDEX ON space_settlements (from_user_id);
CREATE INDEX ON space_settlements (to_user_id);
CREATE INDEX ON space_settlements (settled_at) WHERE settled_at IS NULL;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 9 — ledger_contributions
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ledger_contributions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  space_id           UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  share_id           UUID NOT NULL REFERENCES space_transaction_shares(id) ON DELETE CASCADE,
  ledger_category_id UUID,  -- soft FK to categories(id) — avoids cross-schema coupling
  amount             NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
  date               DATE NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (share_id)  -- one contribution per share, prevents double-linking
);

COMMENT ON TABLE ledger_contributions IS
  'Private bridge: space_transaction_share → personal ledger analysis. RLS: user_id = auth.uid() only. Cascade-deleted when share is deleted.';
COMMENT ON COLUMN ledger_contributions.amount IS
  'Mirrors space_transaction_shares.amount. Denormalized for fast personal ledger queries.';

CREATE INDEX ON ledger_contributions (user_id, date DESC);
CREATE INDEX ON ledger_contributions (space_id);
CREATE INDEX ON ledger_contributions (share_id);

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 10 — RLS HELPER FUNCTIONS
-- Mirrors the V32 pattern (SECURITY DEFINER avoids self-referential recursion).
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_my_space_ids()
RETURNS SETOF UUID
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT space_id FROM public.space_members WHERE user_id = auth.uid();
$$;

-- Write access: owner|admin|member AND can_add_expenses not explicitly FALSE
CREATE OR REPLACE FUNCTION get_my_space_ids_as_writer()
RETURNS SETOF UUID
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT space_id FROM public.space_members
  WHERE user_id = auth.uid()
    AND role IN ('owner', 'admin', 'member')
    AND COALESCE(can_add_expenses, TRUE) = TRUE;
$$;

CREATE OR REPLACE FUNCTION get_my_space_ids_as_admin()
RETURNS SETOF UUID
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT space_id FROM public.space_members
  WHERE user_id = auth.uid()
    AND role IN ('owner', 'admin');
$$;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 11 — RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE personal_ledgers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE spaces                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_members            ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_invites            ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_categories         ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_transaction_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_settlements        ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_contributions     ENABLE ROW LEVEL SECURITY;

-- ── personal_ledgers — user only, absolutely no sharing ──────────

CREATE POLICY "personal_ledger_select" ON personal_ledgers FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "personal_ledger_insert" ON personal_ledgers FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "personal_ledger_update" ON personal_ledgers FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "personal_ledger_delete" ON personal_ledgers FOR DELETE USING (user_id = auth.uid());

-- ── spaces — members read; owner/admin write ──────────────────────

CREATE POLICY "spaces_select" ON spaces FOR SELECT
  USING (id IN (SELECT get_my_space_ids()));

CREATE POLICY "spaces_insert" ON spaces FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "spaces_update" ON spaces FOR UPDATE
  USING (id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "spaces_delete" ON spaces FOR DELETE
  USING (owner_id = auth.uid());

-- ── space_members — members see members; admin+ manages ──────────

CREATE POLICY "space_members_select" ON space_members FOR SELECT
  USING (space_id IN (SELECT get_my_space_ids()));

CREATE POLICY "space_members_insert" ON space_members FOR INSERT
  WITH CHECK (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_members_update" ON space_members FOR UPDATE
  USING (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_members_delete" ON space_members FOR DELETE
  USING (user_id = auth.uid() OR space_id IN (SELECT get_my_space_ids_as_admin()));

-- ── space_invites — admin+ only ───────────────────────────────────

CREATE POLICY "space_invites_select" ON space_invites FOR SELECT
  USING (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_invites_insert" ON space_invites FOR INSERT
  WITH CHECK (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_invites_delete" ON space_invites FOR DELETE
  USING (space_id IN (SELECT get_my_space_ids_as_admin()));

-- ── space_categories — members read; admin+ writes ───────────────

CREATE POLICY "space_categories_select" ON space_categories FOR SELECT
  USING (space_id IN (SELECT get_my_space_ids()));

CREATE POLICY "space_categories_insert" ON space_categories FOR INSERT
  WITH CHECK (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_categories_update" ON space_categories FOR UPDATE
  USING (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_categories_delete" ON space_categories FOR DELETE
  USING (space_id IN (SELECT get_my_space_ids_as_admin()));

-- ── space_transactions — members read; writers insert; locked protected ──

CREATE POLICY "space_transactions_select" ON space_transactions FOR SELECT
  USING (space_id IN (SELECT get_my_space_ids()));

CREATE POLICY "space_transactions_insert" ON space_transactions FOR INSERT
  WITH CHECK (space_id IN (SELECT get_my_space_ids_as_writer()));

CREATE POLICY "space_transactions_update" ON space_transactions FOR UPDATE
  USING (
    locked_at IS NULL
    AND (paid_by = auth.uid() OR space_id IN (SELECT get_my_space_ids_as_admin()))
  );

CREATE POLICY "space_transactions_delete" ON space_transactions FOR DELETE
  USING (locked_at IS NULL AND space_id IN (SELECT get_my_space_ids_as_admin()));

-- ── space_transaction_shares — inherit from parent transaction ────

CREATE POLICY "space_tx_shares_select" ON space_transaction_shares FOR SELECT
  USING (
    transaction_id IN (
      SELECT id FROM space_transactions WHERE space_id IN (SELECT get_my_space_ids())
    )
  );

CREATE POLICY "space_tx_shares_insert" ON space_transaction_shares FOR INSERT
  WITH CHECK (
    transaction_id IN (
      SELECT id FROM space_transactions WHERE space_id IN (SELECT get_my_space_ids_as_writer())
    )
  );

CREATE POLICY "space_tx_shares_update" ON space_transaction_shares FOR UPDATE
  USING (
    transaction_id IN (
      SELECT id FROM space_transactions
      WHERE space_id IN (SELECT get_my_space_ids_as_admin()) AND locked_at IS NULL
    )
  );

CREATE POLICY "space_tx_shares_delete" ON space_transaction_shares FOR DELETE
  USING (
    transaction_id IN (
      SELECT id FROM space_transactions
      WHERE space_id IN (SELECT get_my_space_ids_as_admin()) AND locked_at IS NULL
    )
  );

-- ── space_settlements — members see; either party marks settled ───

CREATE POLICY "space_settlements_select" ON space_settlements FOR SELECT
  USING (space_id IN (SELECT get_my_space_ids()));

CREATE POLICY "space_settlements_insert" ON space_settlements FOR INSERT
  WITH CHECK (space_id IN (SELECT get_my_space_ids_as_admin()));

CREATE POLICY "space_settlements_update" ON space_settlements FOR UPDATE
  USING (
    space_id IN (SELECT get_my_space_ids())
    AND (from_user_id = auth.uid() OR to_user_id = auth.uid())
  );

-- ── ledger_contributions — strictly private ───────────────────────

CREATE POLICY "ledger_contributions_select" ON ledger_contributions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "ledger_contributions_insert" ON ledger_contributions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "ledger_contributions_update" ON ledger_contributions FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "ledger_contributions_delete" ON ledger_contributions FOR DELETE USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES (run after applying)
-- ═══════════════════════════════════════════════════════════════════

-- 1. All 9 new tables exist:
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
--   AND table_name IN (
--     'personal_ledgers','spaces','space_members','space_invites',
--     'space_categories','space_transactions','space_transaction_shares',
--     'space_settlements','ledger_contributions')
-- ORDER BY table_name;
-- → 9 rows

-- 2. Helper functions exist:
-- SELECT proname FROM pg_proc
-- WHERE proname IN ('get_my_space_ids','get_my_space_ids_as_writer','get_my_space_ids_as_admin');
-- → 3 rows

-- 3. RLS enabled on all new tables:
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE tablename IN ('personal_ledgers','spaces','space_members','space_invites',
--   'space_categories','space_transactions','space_transaction_shares',
--   'space_settlements','ledger_contributions');
-- → rowsecurity = true for all 9

-- 4. Existing data untouched:
-- SELECT COUNT(*) FROM workspaces;        -- unchanged
-- SELECT COUNT(*) FROM workspace_members; -- unchanged
-- SELECT COUNT(*) FROM expenses;          -- unchanged
