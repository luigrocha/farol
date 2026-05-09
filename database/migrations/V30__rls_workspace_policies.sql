-- V30__rls_workspace_policies.sql
-- Replace user_id-based RLS policies with workspace membership policies.
-- Read access: any workspace member.
-- Write access: roles owner, admin, member (viewers are read-only).
-- Security is still enforced by RLS — workspace_id in queries is for index usage only.
-- Prerequisite: V29 applied (workspace_id NOT NULL on all tables).

-- Policy naming:
--   workspace_select_<table>  — FOR SELECT (any member)
--   workspace_insert_<table>  — FOR INSERT (writers only)
--   workspace_update_<table>  — FOR UPDATE (writers only)
--   workspace_delete_<table>  — FOR DELETE (writers only)

-- ─── EXPENSES ─────────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses"   ON expenses;
DROP POLICY IF EXISTS "Users can update their own expenses"   ON expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses"   ON expenses;

CREATE POLICY "workspace_select_expenses" ON expenses FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_expenses" ON expenses FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_expenses" ON expenses FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_expenses" ON expenses FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── INCOMES ──────────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can insert their own incomes"   ON incomes;
DROP POLICY IF EXISTS "Users can update their own incomes"   ON incomes;
DROP POLICY IF EXISTS "Users can delete their own incomes"   ON incomes;

CREATE POLICY "workspace_select_incomes" ON incomes FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_incomes" ON incomes FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_incomes" ON incomes FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_incomes" ON incomes FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── INVESTMENTS ──────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own investments" ON investments;
DROP POLICY IF EXISTS "Users can insert their own investments"   ON investments;
DROP POLICY IF EXISTS "Users can update their own investments"   ON investments;
DROP POLICY IF EXISTS "Users can delete their own investments"   ON investments;

CREATE POLICY "workspace_select_investments" ON investments FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_investments" ON investments FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_investments" ON investments FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_investments" ON investments FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── NET WORTH SNAPSHOTS ───────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own net_worth_snapshots" ON net_worth_snapshots;
DROP POLICY IF EXISTS "Users can insert their own net_worth_snapshots"   ON net_worth_snapshots;
DROP POLICY IF EXISTS "Users can update their own net_worth_snapshots"   ON net_worth_snapshots;
DROP POLICY IF EXISTS "Users can delete their own net_worth_snapshots"   ON net_worth_snapshots;

CREATE POLICY "workspace_select_net_worth_snapshots" ON net_worth_snapshots FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_net_worth_snapshots" ON net_worth_snapshots FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_net_worth_snapshots" ON net_worth_snapshots FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_net_worth_snapshots" ON net_worth_snapshots FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── ACCOUNTS ─────────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can insert their own accounts"   ON accounts;
DROP POLICY IF EXISTS "Users can update their own accounts"   ON accounts;
DROP POLICY IF EXISTS "Users can delete their own accounts"   ON accounts;

CREATE POLICY "workspace_select_accounts" ON accounts FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_accounts" ON accounts FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_accounts" ON accounts FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_accounts" ON accounts FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── ACCOUNT TRANSFERS ────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own account_transfers" ON account_transfers;
DROP POLICY IF EXISTS "Users can insert their own account_transfers"   ON account_transfers;
DROP POLICY IF EXISTS "Users can update their own account_transfers"   ON account_transfers;
DROP POLICY IF EXISTS "Users can delete their own account_transfers"   ON account_transfers;

CREATE POLICY "workspace_select_account_transfers" ON account_transfers FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_account_transfers" ON account_transfers FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_account_transfers" ON account_transfers FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_account_transfers" ON account_transfers FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── BUDGET GOALS ─────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own budget_goals" ON budget_goals;
DROP POLICY IF EXISTS "Users can insert their own budget_goals"   ON budget_goals;
DROP POLICY IF EXISTS "Users can update their own budget_goals"   ON budget_goals;
DROP POLICY IF EXISTS "Users can delete their own budget_goals"   ON budget_goals;

CREATE POLICY "workspace_select_budget_goals" ON budget_goals FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_budget_goals" ON budget_goals FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_budget_goals" ON budget_goals FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_budget_goals" ON budget_goals FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── PERIOD BUDGETS ───────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own period_budgets" ON period_budgets;
DROP POLICY IF EXISTS "Users can insert their own period_budgets"   ON period_budgets;
DROP POLICY IF EXISTS "Users can update their own period_budgets"   ON period_budgets;
DROP POLICY IF EXISTS "Users can delete their own period_budgets"   ON period_budgets;

CREATE POLICY "workspace_select_period_budgets" ON period_budgets FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_period_budgets" ON period_budgets FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_period_budgets" ON period_budgets FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_period_budgets" ON period_budgets FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── CATEGORIES ───────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own categories" ON categories;
DROP POLICY IF EXISTS "Users can insert their own categories"   ON categories;
DROP POLICY IF EXISTS "Users can update their own categories"   ON categories;
DROP POLICY IF EXISTS "Users can delete their own categories"   ON categories;

CREATE POLICY "workspace_select_categories" ON categories FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_categories" ON categories FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_categories" ON categories FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_categories" ON categories FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── SALARY SETTINGS ──────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own salary_settings" ON salary_settings;
DROP POLICY IF EXISTS "Users can insert their own salary_settings"   ON salary_settings;
DROP POLICY IF EXISTS "Users can update their own salary_settings"   ON salary_settings;
DROP POLICY IF EXISTS "Users can delete their own salary_settings"   ON salary_settings;

CREATE POLICY "workspace_select_salary_settings" ON salary_settings FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_salary_settings" ON salary_settings FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_salary_settings" ON salary_settings FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_salary_settings" ON salary_settings FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── INSTALLMENT PLANS ────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own installment_plans" ON installment_plans;
DROP POLICY IF EXISTS "Users can insert their own installment_plans"   ON installment_plans;
DROP POLICY IF EXISTS "Users can update their own installment_plans"   ON installment_plans;
DROP POLICY IF EXISTS "Users can delete their own installment_plans"   ON installment_plans;

CREATE POLICY "workspace_select_installment_plans" ON installment_plans FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_installment_plans" ON installment_plans FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_installment_plans" ON installment_plans FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_installment_plans" ON installment_plans FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── INSTALLMENT PAYMENTS ─────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own installment_payments" ON installment_payments;
DROP POLICY IF EXISTS "Users can insert their own installment_payments"   ON installment_payments;
DROP POLICY IF EXISTS "Users can update their own installment_payments"   ON installment_payments;
DROP POLICY IF EXISTS "Users can delete their own installment_payments"   ON installment_payments;

CREATE POLICY "workspace_select_installment_payments" ON installment_payments FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_installment_payments" ON installment_payments FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_installment_payments" ON installment_payments FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_installment_payments" ON installment_payments FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── RECURRING RULES ──────────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own recurring_rules" ON recurring_rules;
DROP POLICY IF EXISTS "Users can insert their own recurring_rules"   ON recurring_rules;
DROP POLICY IF EXISTS "Users can update their own recurring_rules"   ON recurring_rules;
DROP POLICY IF EXISTS "Users can delete their own recurring_rules"   ON recurring_rules;

CREATE POLICY "workspace_select_recurring_rules" ON recurring_rules FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_recurring_rules" ON recurring_rules FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_recurring_rules" ON recurring_rules FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_recurring_rules" ON recurring_rules FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- ─── RECURRING OCCURRENCES ────────────────────────────────────

DROP POLICY IF EXISTS "Users can only see their own recurring_occurrences" ON recurring_occurrences;
DROP POLICY IF EXISTS "Users can insert their own recurring_occurrences"   ON recurring_occurrences;
DROP POLICY IF EXISTS "Users can update their own recurring_occurrences"   ON recurring_occurrences;
DROP POLICY IF EXISTS "Users can delete their own recurring_occurrences"   ON recurring_occurrences;

CREATE POLICY "workspace_select_recurring_occurrences" ON recurring_occurrences FOR SELECT
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "workspace_insert_recurring_occurrences" ON recurring_occurrences FOR INSERT
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_update_recurring_occurrences" ON recurring_occurrences FOR UPDATE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

CREATE POLICY "workspace_delete_recurring_occurrences" ON recurring_occurrences FOR DELETE
  USING (workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin','member')));

-- Verification (run after applying):
-- SELECT tablename, policyname FROM pg_policies
-- WHERE tablename IN (
--   'expenses','incomes','investments','net_worth_snapshots','accounts',
--   'account_transfers','budget_goals','period_budgets','categories',
--   'salary_settings','installment_plans','installment_payments',
--   'recurring_rules','recurring_occurrences'
-- )
-- ORDER BY tablename, policyname;
-- Expect 4 policies per table (select, insert, update, delete) named workspace_*.
