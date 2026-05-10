-- V32__fix_workspace_members_rls_recursion.sql
-- Fix infinite recursion in workspace_members RLS policies.
--
-- Root cause: policies on workspace_members query workspace_members itself,
-- causing Postgres to re-evaluate RLS on that sub-query → infinite loop.
-- PostgreSQL error: 42P17 "infinite recursion detected in policy for relation"
--
-- Fix: replace all workspace_members self-referential subqueries with a
-- SECURITY DEFINER helper function that reads workspace_members without
-- triggering RLS, breaking the cycle.
--
-- The same recursion affects workspaces (its SELECT policy also queries
-- workspace_members) and workspace_invites (same pattern).
-- All three are fixed here.

-- ─── Helper: get workspace IDs the current user belongs to ────────────────
-- SECURITY DEFINER bypasses RLS on workspace_members, breaking the cycle.

CREATE OR REPLACE FUNCTION get_my_workspace_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid();
$$;

-- Narrower helper: workspace IDs where the user has write-level role
CREATE OR REPLACE FUNCTION get_my_workspace_ids_as_writer()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT workspace_id FROM public.workspace_members
  WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member');
$$;

-- Narrower helper: workspace IDs where the user is owner or admin
CREATE OR REPLACE FUNCTION get_my_workspace_ids_as_admin()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT workspace_id FROM public.workspace_members
  WHERE user_id = auth.uid() AND role IN ('owner', 'admin');
$$;

-- ─── workspaces: replace self-referential SELECT policy ───────────────────

DROP POLICY IF EXISTS "workspace_members_can_select" ON workspaces;

CREATE POLICY "workspace_members_can_select"
  ON workspaces FOR SELECT
  USING (id IN (SELECT get_my_workspace_ids()));

-- ─── workspace_members: replace all recursive policies ────────────────────

DROP POLICY IF EXISTS "members_can_see_members"   ON workspace_members;
DROP POLICY IF EXISTS "admin_can_insert_members"  ON workspace_members;
DROP POLICY IF EXISTS "owner_can_delete_members"  ON workspace_members;

-- Any member can see other members of the same workspace
CREATE POLICY "members_can_see_members"
  ON workspace_members FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));

-- Owner / admin can add new members
CREATE POLICY "admin_can_insert_members"
  ON workspace_members FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_admin()));

-- Owner/admin can remove anyone; member can remove themselves
CREATE POLICY "owner_can_delete_members"
  ON workspace_members FOR DELETE
  USING (
    user_id = auth.uid()
    OR workspace_id IN (SELECT get_my_workspace_ids_as_admin())
  );

-- ─── workspace_invites: replace recursive policies ────────────────────────

DROP POLICY IF EXISTS "admin_can_create_invites" ON workspace_invites;
DROP POLICY IF EXISTS "admin_can_see_invites"    ON workspace_invites;

CREATE POLICY "admin_can_create_invites"
  ON workspace_invites FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_admin()));

CREATE POLICY "admin_can_see_invites"
  ON workspace_invites FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_admin()));

-- ─── Also fix V30 policies on data tables ─────────────────────────────────
-- V30 created policies like:
--   workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid())
-- These don't recurse on workspace_members itself, but they DO trigger RLS on
-- workspace_members when evaluating — which then recurses. Replace them all
-- with the helper function too.

-- EXPENSES
DROP POLICY IF EXISTS "workspace_select_expenses" ON expenses;
DROP POLICY IF EXISTS "workspace_insert_expenses" ON expenses;
DROP POLICY IF EXISTS "workspace_update_expenses" ON expenses;
DROP POLICY IF EXISTS "workspace_delete_expenses" ON expenses;

CREATE POLICY "workspace_select_expenses" ON expenses FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_expenses" ON expenses FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_expenses" ON expenses FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_expenses" ON expenses FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- INCOMES
DROP POLICY IF EXISTS "workspace_select_incomes" ON incomes;
DROP POLICY IF EXISTS "workspace_insert_incomes" ON incomes;
DROP POLICY IF EXISTS "workspace_update_incomes" ON incomes;
DROP POLICY IF EXISTS "workspace_delete_incomes" ON incomes;

CREATE POLICY "workspace_select_incomes" ON incomes FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_incomes" ON incomes FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_incomes" ON incomes FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_incomes" ON incomes FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- INVESTMENTS
DROP POLICY IF EXISTS "workspace_select_investments" ON investments;
DROP POLICY IF EXISTS "workspace_insert_investments" ON investments;
DROP POLICY IF EXISTS "workspace_update_investments" ON investments;
DROP POLICY IF EXISTS "workspace_delete_investments" ON investments;

CREATE POLICY "workspace_select_investments" ON investments FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_investments" ON investments FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_investments" ON investments FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_investments" ON investments FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- NET WORTH SNAPSHOTS
DROP POLICY IF EXISTS "workspace_select_net_worth_snapshots" ON net_worth_snapshots;
DROP POLICY IF EXISTS "workspace_insert_net_worth_snapshots" ON net_worth_snapshots;
DROP POLICY IF EXISTS "workspace_update_net_worth_snapshots" ON net_worth_snapshots;
DROP POLICY IF EXISTS "workspace_delete_net_worth_snapshots" ON net_worth_snapshots;

CREATE POLICY "workspace_select_net_worth_snapshots" ON net_worth_snapshots FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_net_worth_snapshots" ON net_worth_snapshots FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_net_worth_snapshots" ON net_worth_snapshots FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_net_worth_snapshots" ON net_worth_snapshots FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- ACCOUNTS
DROP POLICY IF EXISTS "workspace_select_accounts" ON accounts;
DROP POLICY IF EXISTS "workspace_insert_accounts" ON accounts;
DROP POLICY IF EXISTS "workspace_update_accounts" ON accounts;
DROP POLICY IF EXISTS "workspace_delete_accounts" ON accounts;

CREATE POLICY "workspace_select_accounts" ON accounts FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_accounts" ON accounts FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_accounts" ON accounts FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_accounts" ON accounts FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- ACCOUNT TRANSFERS
DROP POLICY IF EXISTS "workspace_select_account_transfers" ON account_transfers;
DROP POLICY IF EXISTS "workspace_insert_account_transfers" ON account_transfers;
DROP POLICY IF EXISTS "workspace_update_account_transfers" ON account_transfers;
DROP POLICY IF EXISTS "workspace_delete_account_transfers" ON account_transfers;

CREATE POLICY "workspace_select_account_transfers" ON account_transfers FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_account_transfers" ON account_transfers FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_account_transfers" ON account_transfers FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_account_transfers" ON account_transfers FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- BUDGET GOALS
DROP POLICY IF EXISTS "workspace_select_budget_goals" ON budget_goals;
DROP POLICY IF EXISTS "workspace_insert_budget_goals" ON budget_goals;
DROP POLICY IF EXISTS "workspace_update_budget_goals" ON budget_goals;
DROP POLICY IF EXISTS "workspace_delete_budget_goals" ON budget_goals;

CREATE POLICY "workspace_select_budget_goals" ON budget_goals FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_budget_goals" ON budget_goals FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_budget_goals" ON budget_goals FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_budget_goals" ON budget_goals FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- PERIOD BUDGETS
DROP POLICY IF EXISTS "workspace_select_period_budgets" ON period_budgets;
DROP POLICY IF EXISTS "workspace_insert_period_budgets" ON period_budgets;
DROP POLICY IF EXISTS "workspace_update_period_budgets" ON period_budgets;
DROP POLICY IF EXISTS "workspace_delete_period_budgets" ON period_budgets;

CREATE POLICY "workspace_select_period_budgets" ON period_budgets FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_period_budgets" ON period_budgets FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_period_budgets" ON period_budgets FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_period_budgets" ON period_budgets FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- CATEGORIES (preserves V31 fix: user_id IS NULL = system categories always readable)
DROP POLICY IF EXISTS "workspace_select_categories" ON categories;
DROP POLICY IF EXISTS "workspace_insert_categories" ON categories;
DROP POLICY IF EXISTS "workspace_update_categories" ON categories;
DROP POLICY IF EXISTS "workspace_delete_categories" ON categories;

CREATE POLICY "workspace_select_categories" ON categories FOR SELECT
  USING (
    user_id IS NULL                                       -- system categories: always readable
    OR workspace_id IN (SELECT get_my_workspace_ids())
  );
CREATE POLICY "workspace_insert_categories" ON categories FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_categories" ON categories FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_categories" ON categories FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- SALARY SETTINGS (conditional — may not exist)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'salary_settings' AND table_schema = 'public'
  ) THEN
    DROP POLICY IF EXISTS "workspace_select_salary_settings" ON salary_settings;
    DROP POLICY IF EXISTS "workspace_insert_salary_settings" ON salary_settings;
    DROP POLICY IF EXISTS "workspace_update_salary_settings" ON salary_settings;
    DROP POLICY IF EXISTS "workspace_delete_salary_settings" ON salary_settings;

    EXECUTE $p$
      CREATE POLICY "workspace_select_salary_settings" ON salary_settings FOR SELECT
        USING (workspace_id IN (SELECT get_my_workspace_ids()));
      CREATE POLICY "workspace_insert_salary_settings" ON salary_settings FOR INSERT
        WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
      CREATE POLICY "workspace_update_salary_settings" ON salary_settings FOR UPDATE
        USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
      CREATE POLICY "workspace_delete_salary_settings" ON salary_settings FOR DELETE
        USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
    $p$;
  END IF;
END $$;

-- INSTALLMENT PLANS
DROP POLICY IF EXISTS "workspace_select_installment_plans" ON installment_plans;
DROP POLICY IF EXISTS "workspace_insert_installment_plans" ON installment_plans;
DROP POLICY IF EXISTS "workspace_update_installment_plans" ON installment_plans;
DROP POLICY IF EXISTS "workspace_delete_installment_plans" ON installment_plans;

CREATE POLICY "workspace_select_installment_plans" ON installment_plans FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_installment_plans" ON installment_plans FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_installment_plans" ON installment_plans FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_installment_plans" ON installment_plans FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- INSTALLMENT PAYMENTS
DROP POLICY IF EXISTS "workspace_select_installment_payments" ON installment_payments;
DROP POLICY IF EXISTS "workspace_insert_installment_payments" ON installment_payments;
DROP POLICY IF EXISTS "workspace_update_installment_payments" ON installment_payments;
DROP POLICY IF EXISTS "workspace_delete_installment_payments" ON installment_payments;

CREATE POLICY "workspace_select_installment_payments" ON installment_payments FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_installment_payments" ON installment_payments FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_installment_payments" ON installment_payments FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_installment_payments" ON installment_payments FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- RECURRING RULES
DROP POLICY IF EXISTS "workspace_select_recurring_rules" ON recurring_rules;
DROP POLICY IF EXISTS "workspace_insert_recurring_rules" ON recurring_rules;
DROP POLICY IF EXISTS "workspace_update_recurring_rules" ON recurring_rules;
DROP POLICY IF EXISTS "workspace_delete_recurring_rules" ON recurring_rules;

CREATE POLICY "workspace_select_recurring_rules" ON recurring_rules FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_recurring_rules" ON recurring_rules FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_recurring_rules" ON recurring_rules FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_recurring_rules" ON recurring_rules FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- RECURRING OCCURRENCES
DROP POLICY IF EXISTS "workspace_select_recurring_occurrences" ON recurring_occurrences;
DROP POLICY IF EXISTS "workspace_insert_recurring_occurrences" ON recurring_occurrences;
DROP POLICY IF EXISTS "workspace_update_recurring_occurrences" ON recurring_occurrences;
DROP POLICY IF EXISTS "workspace_delete_recurring_occurrences" ON recurring_occurrences;

CREATE POLICY "workspace_select_recurring_occurrences" ON recurring_occurrences FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));
CREATE POLICY "workspace_insert_recurring_occurrences" ON recurring_occurrences FOR INSERT
  WITH CHECK (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_update_recurring_occurrences" ON recurring_occurrences FOR UPDATE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));
CREATE POLICY "workspace_delete_recurring_occurrences" ON recurring_occurrences FOR DELETE
  USING (workspace_id IN (SELECT get_my_workspace_ids_as_writer()));

-- ─── Verification ─────────────────────────────────────────────────────────
-- After applying, test that recursion is gone:
--   SELECT * FROM workspace_members LIMIT 1;
--   → must return a row, not error 42P17
--
-- Test system categories still visible:
--   SELECT count(*) FROM categories WHERE user_id IS NULL;
--   → must be > 0
--
-- Confirm helper functions exist:
--   SELECT proname FROM pg_proc WHERE proname LIKE 'get_my_workspace%';
--   → 3 rows: get_my_workspace_ids, get_my_workspace_ids_as_writer, get_my_workspace_ids_as_admin
