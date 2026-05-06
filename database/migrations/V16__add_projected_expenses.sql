-- Add support for installment plan projections
-- is_projected: marks future installment cuotas (not yet real expenses)
-- installment_plan_id: links projected expenses to their card_installments plan
--   ON DELETE CASCADE ensures projections are removed when the plan is deleted

ALTER TABLE expenses
  ADD COLUMN is_projected boolean NOT NULL DEFAULT false,
  ADD COLUMN installment_plan_id bigint
    REFERENCES card_installments(id) ON DELETE CASCADE;
