-- V35: workspace_activity table + RLS + auto-log triggers
-- Only fires for shared workspaces (workspace_id != NULL).
-- Denormalizes entity_label + amount to avoid N+1 in the feed query.

-- ── Table ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS workspace_activity (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id   UUID        NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id        UUID        NOT NULL REFERENCES auth.users(id),
  action         TEXT        NOT NULL,
  -- 'added_expense' | 'deleted_expense'
  -- 'added_recurring' | 'deleted_recurring'
  -- 'added_installment' | 'deleted_installment'
  entity_type    TEXT        NOT NULL,
  -- 'expense' | 'recurring_rule' | 'installment_plan'
  entity_id      TEXT,
  entity_label   TEXT,       -- denormalized: store_description or category name
  amount         NUMERIC,
  metadata       JSONB       NOT NULL DEFAULT '{}',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workspace_activity_ws_time
  ON workspace_activity(workspace_id, created_at DESC);

-- ── RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE workspace_activity ENABLE ROW LEVEL SECURITY;

-- All workspace members can read the activity feed
CREATE POLICY "workspace members can read activity"
  ON workspace_activity FOR SELECT
  USING (workspace_id IN (SELECT get_my_workspace_ids()));

-- Members with write access can insert (only their own user_id)
CREATE POLICY "workspace writers can log activity"
  ON workspace_activity FOR INSERT
  WITH CHECK (
    workspace_id IN (SELECT get_my_workspace_ids_as_writer())
    AND user_id = auth.uid()
  );

-- ── Trigger: expenses ──────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_expense_activity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Only log for shared workspaces (workspace_id is set)
  IF TG_OP = 'INSERT' THEN
    IF NEW.workspace_id IS NOT NULL AND NEW.author_user_id IS NOT NULL THEN
      INSERT INTO workspace_activity
        (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
      VALUES (
        NEW.workspace_id,
        NEW.author_user_id,
        'added_expense',
        'expense',
        NEW.id::TEXT,
        COALESCE(NEW.store_description, NEW.category),
        NEW.amount
      );
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.workspace_id IS NOT NULL THEN
      INSERT INTO workspace_activity
        (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
      VALUES (
        OLD.workspace_id,
        COALESCE(OLD.author_user_id, auth.uid()),
        'deleted_expense',
        'expense',
        OLD.id::TEXT,
        COALESCE(OLD.store_description, OLD.category),
        OLD.amount
      );
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_expense_activity ON expenses;
CREATE TRIGGER trg_expense_activity
  AFTER INSERT OR DELETE ON expenses
  FOR EACH ROW EXECUTE FUNCTION log_expense_activity();

-- ── Trigger: recurring_rules ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_recurring_activity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.workspace_id IS NOT NULL AND NEW.author_user_id IS NOT NULL THEN
      INSERT INTO workspace_activity
        (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
      VALUES (
        NEW.workspace_id,
        NEW.author_user_id,
        'added_recurring',
        'recurring_rule',
        NEW.id::TEXT,
        NEW.name,
        NEW.base_amount
      );
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.workspace_id IS NOT NULL THEN
      INSERT INTO workspace_activity
        (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
      VALUES (
        OLD.workspace_id,
        COALESCE(OLD.author_user_id, auth.uid()),
        'deleted_recurring',
        'recurring_rule',
        OLD.id::TEXT,
        OLD.name,
        OLD.base_amount
      );
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_recurring_activity ON recurring_rules;
CREATE TRIGGER trg_recurring_activity
  AFTER INSERT OR DELETE ON recurring_rules
  FOR EACH ROW EXECUTE FUNCTION log_recurring_activity();

-- ── Trigger: installment_plans ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_installment_activity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.workspace_id IS NOT NULL AND NEW.author_user_id IS NOT NULL THEN
      INSERT INTO workspace_activity
        (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
      VALUES (
        NEW.workspace_id,
        NEW.author_user_id,
        'added_installment',
        'installment_plan',
        NEW.id::TEXT,
        COALESCE(NEW.store_name, NEW.description),
        NEW.total_amount
      );
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.workspace_id IS NOT NULL THEN
      INSERT INTO workspace_activity
        (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
      VALUES (
        OLD.workspace_id,
        COALESCE(OLD.author_user_id, auth.uid()),
        'deleted_installment',
        'installment_plan',
        OLD.id::TEXT,
        COALESCE(OLD.store_name, OLD.description),
        OLD.total_amount
      );
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_installment_activity ON installment_plans;
CREATE TRIGGER trg_installment_activity
  AFTER INSERT OR DELETE ON installment_plans
  FOR EACH ROW EXECUTE FUNCTION log_installment_activity();
