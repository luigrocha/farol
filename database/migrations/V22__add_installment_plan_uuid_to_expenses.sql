-- V22__add_installment_plan_uuid_to_expenses.sql
-- Adds installment_plan_uuid_id to expenses for the new installment system.
-- The existing installment_plan_id (bigint → card_installments) is preserved.

ALTER TABLE expenses
    ADD COLUMN IF NOT EXISTS installment_plan_uuid_id UUID
        REFERENCES installment_plans(id) ON DELETE SET NULL;

ALTER TABLE expenses
    ADD COLUMN IF NOT EXISTS installment_payment_id UUID
        REFERENCES installment_payments(id) ON DELETE SET NULL;

CREATE INDEX idx_expenses_installment_plan_uuid
    ON expenses(installment_plan_uuid_id)
    WHERE installment_plan_uuid_id IS NOT NULL;
