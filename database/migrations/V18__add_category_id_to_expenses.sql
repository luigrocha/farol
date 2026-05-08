-- V18__add_category_id_to_expenses.sql
-- Add category_id UUID to expenses as nullable FK to categories.
-- The existing text column 'category' is preserved for backward compatibility.
-- Backfill and NOT NULL constraint will be applied in a future migration (V19+).

ALTER TABLE expenses
    ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
