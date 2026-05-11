-- V36: budget_changes audit table + RLS
-- Lightweight audit trail for budget edits in shared workspaces.
-- Written by the Flutter app (period_budget_repository.upsert) — not a trigger,
-- because period_budgets uses upsert semantics and triggers can't distinguish
-- "new budget" from "edit" without reading old values from the Flutter layer.

-- ── Table ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS budget_changes (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id   UUID        NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  category_slug  TEXT        NOT NULL,
  old_amount     NUMERIC,    -- NULL when setting a budget for the first time
  new_amount     NUMERIC     NOT NULL,
  changed_by     UUID        NOT NULL REFERENCES auth.users(id),
  changed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_budget_changes_ws_cat
  ON budget_changes(workspace_id, category_slug, changed_at DESC);

-- ── RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE budget_changes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members can read budget changes"
  ON budget_changes FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));

CREATE POLICY "workspace writers can log budget changes"
  ON budget_changes FOR INSERT
  WITH CHECK (
    workspace_id IN (SELECT get_my_workspace_ids_as_writer())
    AND changed_by = auth.uid()
  );
