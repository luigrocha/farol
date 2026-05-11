-- V34: Attribution system — author_user_id on financial tables
-- Also: profiles RLS update so workspace members can read each other's display info.

-- ─── 1. Add author_user_id to financial tables ────────────────

ALTER TABLE expenses ADD COLUMN IF NOT EXISTS
  author_user_id UUID REFERENCES auth.users(id);

ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS
  author_user_id UUID REFERENCES auth.users(id);

ALTER TABLE installment_plans ADD COLUMN IF NOT EXISTS
  author_user_id UUID REFERENCES auth.users(id);

-- ─── 2. Backfill: author = the user who owns the row ─────────
-- For personal workspaces this is trivially correct (only one user).
-- For shared workspaces created after V26: author_user_id = user_id (creator).

UPDATE expenses        SET author_user_id = user_id WHERE author_user_id IS NULL;
UPDATE recurring_rules SET author_user_id = user_id WHERE author_user_id IS NULL;
UPDATE installment_plans SET author_user_id = user_id WHERE author_user_id IS NULL;

-- ─── 3. Profiles RLS: allow workspace members to read each other ──
-- Without this, the attribution UI cannot show display names for other members.
-- Uses the same SECURITY DEFINER helper pattern as workspace_members RLS (V32).

DROP POLICY IF EXISTS "Workspace members can read co-member profiles" ON profiles;

CREATE POLICY "Workspace members can read co-member profiles"
  ON profiles FOR SELECT
  USING (
    -- Own profile always readable
    auth.uid() = id
    OR
    -- Co-members in any shared workspace are readable
    id IN (
      SELECT wm.user_id
      FROM workspace_members wm
      WHERE wm.workspace_id IN (SELECT get_my_workspace_ids())
    )
  );

-- ─── 4. RLS for author_user_id: only set your own ────────────
-- Enforce that author_user_id matches the authenticated user on INSERT.
-- We do this via a check constraint rather than RLS to keep policies simple.
-- The existing workspace-scoped RLS on expenses/recurring_rules/installment_plans
-- already ensures the row belongs to a workspace the user is a member of.

-- Note: We cannot add a CHECK constraint that calls auth.uid() in standard SQL,
-- so we rely on the application layer setting author_user_id = auth.uid() on insert,
-- and the existing RLS policies preventing unauthorized inserts into those tables.
-- Future: add a BEFORE INSERT trigger if stricter enforcement is needed.

COMMENT ON COLUMN expenses.author_user_id         IS 'User who created this expense. Set by app on insert.';
COMMENT ON COLUMN recurring_rules.author_user_id   IS 'User who created this recurring rule. Set by app on insert.';
COMMENT ON COLUMN installment_plans.author_user_id IS 'User who created this installment plan. Set by app on insert.';
