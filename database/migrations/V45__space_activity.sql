-- V45: space_activity table + RLS + auto-log triggers
--
-- Mirrors the workspace_activity pattern (V35) but scoped to spaces.
-- Actions logged:
--   space_transactions  INSERT → 'added_transaction'
--   space_transactions  DELETE → 'deleted_transaction'
--   space_settlements   INSERT → 'recorded_settlement'
--
-- Denormalizes entity_label + amount to avoid N+1 in the feed query.
-- All triggers run SECURITY DEFINER so they can INSERT despite RLS.

-- ═══════════════════════════════════════════════════════════════
-- Table
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS space_activity (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id     UUID        NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL REFERENCES auth.users(id),
  action       TEXT        NOT NULL,
  -- 'added_transaction' | 'deleted_transaction' | 'recorded_settlement'
  entity_type  TEXT        NOT NULL,
  -- 'space_transaction' | 'space_settlement'
  entity_id    TEXT,
  entity_label TEXT,        -- denormalized: description or "Acerto de contas"
  amount       NUMERIC,
  metadata     JSONB        NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_space_activity_space_time
  ON space_activity(space_id, created_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE space_activity ENABLE ROW LEVEL SECURITY;

-- All space members can read the activity feed
CREATE POLICY "space_members_can_read_activity"
  ON space_activity FOR SELECT
  USING (space_id IN (SELECT get_my_space_ids()));

-- Space members with write access can insert their own rows
-- (app-side inserts for edge cases; most rows come from triggers)
CREATE POLICY "space_writers_can_log_activity"
  ON space_activity FOR INSERT
  WITH CHECK (
    space_id IN (SELECT get_my_space_ids_as_writer())
    AND user_id = auth.uid()
  );

-- ═══════════════════════════════════════════════════════════════
-- Trigger: space_transactions
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION log_space_transaction_activity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO space_activity
      (space_id, user_id, action, entity_type, entity_id, entity_label, amount)
    VALUES (
      NEW.space_id,
      NEW.paid_by,
      'added_transaction',
      'space_transaction',
      NEW.id::TEXT,
      NEW.description,
      NEW.amount
    );
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO space_activity
      (space_id, user_id, action, entity_type, entity_id, entity_label, amount)
    VALUES (
      OLD.space_id,
      COALESCE(OLD.paid_by, auth.uid()),
      'deleted_transaction',
      'space_transaction',
      OLD.id::TEXT,
      OLD.description,
      OLD.amount
    );
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_space_transaction_activity ON space_transactions;
CREATE TRIGGER trg_space_transaction_activity
  AFTER INSERT OR DELETE ON space_transactions
  FOR EACH ROW EXECUTE FUNCTION log_space_transaction_activity();

-- ═══════════════════════════════════════════════════════════════
-- Trigger: space_settlements
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION log_space_settlement_activity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO space_activity
      (space_id, user_id, action, entity_type, entity_id, entity_label, amount,
       metadata)
    VALUES (
      NEW.space_id,
      NEW.from_user_id,
      'recorded_settlement',
      'space_settlement',
      NEW.id::TEXT,
      'Acerto de contas',
      NEW.amount,
      jsonb_build_object('to_user_id', NEW.to_user_id)
    );
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_space_settlement_activity ON space_settlements;
CREATE TRIGGER trg_space_settlement_activity
  AFTER INSERT ON space_settlements
  FOR EACH ROW EXECUTE FUNCTION log_space_settlement_activity();

-- ═══════════════════════════════════════════════════════════════
-- Smoke-test queries (run manually after applying)
-- ═══════════════════════════════════════════════════════════════
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public' AND table_name = 'space_activity';
-- → 1 row
--
-- SELECT tgname FROM pg_trigger
--   WHERE tgname IN (
--     'trg_space_transaction_activity',
--     'trg_space_settlement_activity'
--   );
-- → 2 rows
