-- V28__backfill_workspace_id.sql
-- 1. Create a personal workspace for every existing user that doesn't have one yet.
-- 2. Backfill workspace_id on all data tables using user_id → personal workspace lookup.
-- Idempotent: safe to re-run.
-- Prerequisite: V26 and V27 applied.

-- ─── Step 1: personal workspaces for existing users ──────────

DO $$
DECLARE
  u            RECORD;
  new_ws_id    UUID;
  display_name TEXT;
BEGIN
  FOR u IN
    SELECT id, email, raw_user_meta_data
    FROM auth.users
    WHERE id NOT IN (SELECT DISTINCT owner_id FROM public.workspaces)
  LOOP
    display_name := COALESCE(
      u.raw_user_meta_data->>'full_name',
      split_part(u.email, '@', 1),
      'My Workspace'
    );

    INSERT INTO public.workspaces (name, owner_id, plan)
    VALUES (display_name, u.id, 'free')
    RETURNING id INTO new_ws_id;

    INSERT INTO public.workspace_members (workspace_id, user_id, role)
    VALUES (new_ws_id, u.id, 'owner');

    RAISE NOTICE 'Created workspace % for user %', new_ws_id, u.id;
  END LOOP;
END;
$$;

-- ─── Step 2: backfill workspace_id (user_id → personal workspace) ──

UPDATE expenses e
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = e.user_id AND e.workspace_id IS NULL;

UPDATE incomes i
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = i.user_id AND i.workspace_id IS NULL;

UPDATE investments inv
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = inv.user_id AND inv.workspace_id IS NULL;

UPDATE net_worth_snapshots n
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = n.user_id AND n.workspace_id IS NULL;

UPDATE accounts a
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = a.user_id AND a.workspace_id IS NULL;

UPDATE account_transfers at
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = at.user_id AND at.workspace_id IS NULL;

UPDATE budget_goals bg
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = bg.user_id AND bg.workspace_id IS NULL;

UPDATE period_budgets pb
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = pb.user_id AND pb.workspace_id IS NULL;

UPDATE categories c
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = c.user_id AND c.workspace_id IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'salary_settings'
  ) THEN
    UPDATE salary_settings ss
    SET workspace_id = w.id
    FROM public.workspaces w
    WHERE w.owner_id = ss.user_id AND ss.workspace_id IS NULL;
  END IF;
END $$;

UPDATE installment_plans ip
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = ip.user_id AND ip.workspace_id IS NULL;

-- installment_payments has user_id; join through installment_plans for workspace lookup
UPDATE installment_payments ipy
SET workspace_id = w.id
FROM installment_plans ip
JOIN public.workspaces w ON w.owner_id = ip.user_id
WHERE ipy.plan_id = ip.id AND ipy.workspace_id IS NULL;

UPDATE recurring_rules rr
SET workspace_id = w.id
FROM public.workspaces w
WHERE w.owner_id = rr.user_id AND rr.workspace_id IS NULL;

-- recurring_occurrences join through recurring_rules for workspace lookup
UPDATE recurring_occurrences ro
SET workspace_id = w.id
FROM recurring_rules rr
JOIN public.workspaces w ON w.owner_id = rr.user_id
WHERE ro.rule_id = rr.id AND ro.workspace_id IS NULL;

-- Sanity check (run after applying — all rows must be 0):
-- SELECT 'expenses'              AS tbl, COUNT(*) AS nulls FROM expenses              WHERE workspace_id IS NULL
-- UNION ALL SELECT 'incomes',               COUNT(*) FROM incomes               WHERE workspace_id IS NULL
-- UNION ALL SELECT 'investments',           COUNT(*) FROM investments            WHERE workspace_id IS NULL
-- UNION ALL SELECT 'net_worth_snapshots',   COUNT(*) FROM net_worth_snapshots    WHERE workspace_id IS NULL
-- UNION ALL SELECT 'accounts',             COUNT(*) FROM accounts               WHERE workspace_id IS NULL
-- UNION ALL SELECT 'account_transfers',    COUNT(*) FROM account_transfers      WHERE workspace_id IS NULL
-- UNION ALL SELECT 'budget_goals',         COUNT(*) FROM budget_goals           WHERE workspace_id IS NULL
-- UNION ALL SELECT 'period_budgets',       COUNT(*) FROM period_budgets         WHERE workspace_id IS NULL
-- UNION ALL SELECT 'categories',           COUNT(*) FROM categories             WHERE workspace_id IS NULL
-- (salary_settings omitted if it doesn't exist in schema)
-- UNION ALL SELECT 'installment_plans',    COUNT(*) FROM installment_plans      WHERE workspace_id IS NULL
-- UNION ALL SELECT 'installment_payments', COUNT(*) FROM installment_payments   WHERE workspace_id IS NULL
-- UNION ALL SELECT 'recurring_rules',      COUNT(*) FROM recurring_rules        WHERE workspace_id IS NULL
-- UNION ALL SELECT 'recurring_occurrences',COUNT(*) FROM recurring_occurrences  WHERE workspace_id IS NULL;
