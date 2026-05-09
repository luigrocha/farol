-- V29__workspace_id_not_null.sql
-- Fill any remaining NULLs with fallback to default workspace, then enforce NOT NULL.
-- Prerequisite: V28 applied.

-- Helper: get fallback workspace (first one, or create system default if none exist)
DO $$
DECLARE
  default_ws UUID;
BEGIN
  SELECT id INTO default_ws FROM public.workspaces LIMIT 1;

  IF default_ws IS NULL THEN
    INSERT INTO public.workspaces (name, owner_id, plan)
    VALUES ('System Default', '00000000-0000-0000-0000-000000000000'::uuid, 'free')
    RETURNING id INTO default_ws;
  END IF;

  -- Set session variable for use in UPDATE statements
  PERFORM set_config('app.default_workspace_id', default_ws::TEXT, FALSE);
END $$;

-- ─── Fill remaining NULLs with fallback ───────────────────────

UPDATE expenses e
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = e.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE e.workspace_id IS NULL;

UPDATE incomes i
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = i.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE i.workspace_id IS NULL;

UPDATE investments inv
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = inv.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE inv.workspace_id IS NULL;

UPDATE net_worth_snapshots n
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = n.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE n.workspace_id IS NULL;

UPDATE accounts a
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = a.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE a.workspace_id IS NULL;

UPDATE account_transfers at
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = at.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE at.workspace_id IS NULL;

UPDATE budget_goals bg
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = bg.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE bg.workspace_id IS NULL;

UPDATE period_budgets pb
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = pb.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE pb.workspace_id IS NULL;

UPDATE categories c
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = c.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE c.workspace_id IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'salary_settings'
  ) THEN
    UPDATE salary_settings ss
    SET workspace_id = COALESCE(
      (SELECT w.id FROM public.workspaces w WHERE w.owner_id = ss.user_id LIMIT 1),
      (current_setting('app.default_workspace_id')::uuid)
    )
    WHERE ss.workspace_id IS NULL;
  END IF;
END $$;

UPDATE installment_plans ip
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = ip.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE ip.workspace_id IS NULL;

UPDATE installment_payments ipy
SET workspace_id = COALESCE(
  (SELECT ip.workspace_id FROM installment_plans ip WHERE ip.id = ipy.plan_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE ipy.workspace_id IS NULL;

UPDATE recurring_rules rr
SET workspace_id = COALESCE(
  (SELECT w.id FROM public.workspaces w WHERE w.owner_id = rr.user_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE rr.workspace_id IS NULL;

UPDATE recurring_occurrences ro
SET workspace_id = COALESCE(
  (SELECT rr.workspace_id FROM recurring_rules rr WHERE rr.id = ro.rule_id LIMIT 1),
  (current_setting('app.default_workspace_id')::uuid)
)
WHERE ro.workspace_id IS NULL;

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

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'salary_settings'
  ) THEN
    ALTER TABLE salary_settings ALTER COLUMN workspace_id SET NOT NULL;
  END IF;
END $$;

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

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'salary_settings'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_salary_settings_workspace ON salary_settings (workspace_id);
  END IF;
END $$;

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
