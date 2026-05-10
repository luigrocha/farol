-- V31__fix_workspace_rls_and_inserts.sql
-- Patch for issues introduced by V26–V30:
--   1. System categories (user_id IS NULL) were assigned to a fake workspace → invisible.
--      Fix: add a SELECT policy that makes them readable by all authenticated users.
--   2. Repositories that were not updated in the Flutter app still INSERT without
--      workspace_id. Fix: trigger that auto-populates workspace_id from user_id.
--   3. installment_payments and recurring_occurrences have no user_id column —
--      their trigger derives workspace_id from the parent table.

-- ─── Fix 1: system categories visible to all authenticated users ──

-- Remove the workspace-only SELECT policy and replace with one that also allows
-- system categories (user_id IS NULL, formerly visible to everyone).
DROP POLICY IF EXISTS "workspace_select_categories" ON categories;

CREATE POLICY "workspace_select_categories" ON categories FOR SELECT
  USING (
    user_id IS NULL                        -- system categories: always readable
    OR workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

-- ─── Fix 2: auto-populate workspace_id on INSERT ──────────────
-- Trigger fires BEFORE INSERT on any table that has user_id + workspace_id.
-- If workspace_id is omitted (NULL), it looks up the user's personal workspace.
-- The trigger is SECURITY DEFINER so it can read workspaces without RLS interference.

CREATE OR REPLACE FUNCTION auto_set_workspace_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.workspace_id IS NULL AND NEW.user_id IS NOT NULL THEN
    SELECT id INTO NEW.workspace_id
    FROM public.workspaces
    WHERE owner_id = NEW.user_id
    LIMIT 1;
  END IF;

  -- If workspace_id is still NULL here, the NOT NULL constraint will catch it.
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply trigger to all tables with user_id that may receive INSERTs without workspace_id.
-- Tables already reliably providing workspace_id (expense, income, category, installment_plans,
-- recurring_rules) still benefit from this as a safety net.

CREATE OR REPLACE TRIGGER trg_auto_workspace_expenses
  BEFORE INSERT ON expenses
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_incomes
  BEFORE INSERT ON incomes
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_investments
  BEFORE INSERT ON investments
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_net_worth
  BEFORE INSERT ON net_worth_snapshots
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_accounts
  BEFORE INSERT ON accounts
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_account_transfers
  BEFORE INSERT ON account_transfers
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_budget_goals
  BEFORE INSERT ON budget_goals
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_period_budgets
  BEFORE INSERT ON period_budgets
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_categories
  BEFORE INSERT ON categories
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'salary_settings' AND table_schema = 'public') THEN
    CREATE OR REPLACE TRIGGER trg_auto_workspace_salary_settings
      BEFORE INSERT ON salary_settings
      FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();
  END IF;
END $$;

CREATE OR REPLACE TRIGGER trg_auto_workspace_installment_plans
  BEFORE INSERT ON installment_plans
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

CREATE OR REPLACE TRIGGER trg_auto_workspace_recurring_rules
  BEFORE INSERT ON recurring_rules
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id();

-- ─── Fix 3: installment_payments and recurring_occurrences ────
-- These tables have no user_id — derive workspace_id from parent table.

CREATE OR REPLACE FUNCTION auto_set_workspace_id_from_plan()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.workspace_id IS NULL THEN
    SELECT workspace_id INTO NEW.workspace_id
    FROM public.installment_plans
    WHERE id = NEW.plan_id
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_auto_workspace_installment_payments
  BEFORE INSERT ON installment_payments
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id_from_plan();

CREATE OR REPLACE FUNCTION auto_set_workspace_id_from_rule()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.workspace_id IS NULL THEN
    SELECT workspace_id INTO NEW.workspace_id
    FROM public.recurring_rules
    WHERE id = NEW.rule_id
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_auto_workspace_recurring_occurrences
  BEFORE INSERT ON recurring_occurrences
  FOR EACH ROW EXECUTE FUNCTION auto_set_workspace_id_from_rule();

-- ─── Verification ─────────────────────────────────────────────
-- After applying, test:
-- 1. SELECT * FROM categories WHERE user_id IS NULL LIMIT 5;
--    → should return system categories (not empty)
-- 2. Try inserting an expense without workspace_id from the app.
--    → should succeed (trigger fills it in)
-- 3. Check pg_policies for categories:
--    SELECT policyname, qual FROM pg_policies WHERE tablename = 'categories';
--    → should see two SELECT policies (workspace + system)
