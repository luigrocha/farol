-- V25__add_recurring_ids_to_expenses.sql
-- Links expenses back to the recurring rule and occurrence that generated them.

ALTER TABLE expenses
    ADD COLUMN IF NOT EXISTS recurring_rule_id       UUID REFERENCES recurring_rules(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS recurring_occurrence_id UUID REFERENCES recurring_occurrences(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_expenses_recurring_rule
    ON expenses (user_id, recurring_rule_id)
    WHERE recurring_rule_id IS NOT NULL;
