-- V29__workspace_id_not_null.sql
-- Enforce NOT NULL on workspace_id across all 14 tables, then add performance indexes.
-- Prerequisite: V28 applied and sanity check confirms 0 NULLs in every table.

-- ─── NOT NULL constraints ─────────────────────────────────────

ALTER TABLE expenses              ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE incomes               ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE investments           ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE net_worth_snapshots   ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE accounts              ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE account_transfers     ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE budget_goals          ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE period_budgets        ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE categories            ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE salary_settings       ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE installment_plans     ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE installment_payments  ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE recurring_rules       ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE recurring_occurrences ALTER COLUMN workspace_id SET NOT NULL;

-- ─── Indexes ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_expenses_workspace              ON expenses              (workspace_id);
CREATE INDEX IF NOT EXISTS idx_incomes_workspace               ON incomes               (workspace_id);
CREATE INDEX IF NOT EXISTS idx_investments_workspace           ON investments           (workspace_id);
CREATE INDEX IF NOT EXISTS idx_net_worth_snapshots_workspace   ON net_worth_snapshots   (workspace_id);
CREATE INDEX IF NOT EXISTS idx_accounts_workspace              ON accounts              (workspace_id);
CREATE INDEX IF NOT EXISTS idx_account_transfers_workspace     ON account_transfers     (workspace_id);
CREATE INDEX IF NOT EXISTS idx_budget_goals_workspace          ON budget_goals          (workspace_id);
CREATE INDEX IF NOT EXISTS idx_period_budgets_workspace        ON period_budgets        (workspace_id);
CREATE INDEX IF NOT EXISTS idx_categories_workspace            ON categories            (workspace_id);
CREATE INDEX IF NOT EXISTS idx_salary_settings_workspace       ON salary_settings       (workspace_id);
CREATE INDEX IF NOT EXISTS idx_installment_plans_workspace     ON installment_plans     (workspace_id);
CREATE INDEX IF NOT EXISTS idx_installment_payments_workspace  ON installment_payments  (workspace_id);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_workspace       ON recurring_rules       (workspace_id);
CREATE INDEX IF NOT EXISTS idx_recurring_occurrences_workspace ON recurring_occurrences (workspace_id);

-- Verification (run after applying):
-- SELECT table_name, column_name, is_nullable
-- FROM information_schema.columns
-- WHERE column_name = 'workspace_id'
-- ORDER BY table_name;
-- All 14 rows must show is_nullable = 'NO'.
