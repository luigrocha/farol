# ADR-005: Installments Redesign — InstallmentPlan + InstallmentPayments

**Date**: 2026-05-07
**Status**: Implemented ✅
**Area**: Domain · Database · Repositories

---

## Context

`CardInstallment` and `Expense` were completely independent entities. `Expense.installmentPlanId` existed in the Dart model but `CardInstallments` had no bidirectional reference to expenses. Advance was manual via `advance()`. Future months had no recorded expenses until the user manually called `advance()`.

This meant the `ForecastingEngine` (planned) could not see future installment commitments — which can total R$5,000+/month for active users. The balance projection was fundamentally incorrect.

## Decision

**Replace `card_installments` with two related models**:

1. `InstallmentPlan` — represents the original purchase (the "head" of the installment plan)
2. `InstallmentPayment` — represents each individual installment, **generated automatically** when creating the plan

When creating a R$1,200 purchase in 12 installments, the system immediately generates 12 `InstallmentPayment` records with the correct `due_date` for each month. The `ForecastingEngine` reads these records with `pending` status to calculate future obligations.

When marking an installment as paid, the system automatically creates a linked `Expense` — not the other way around.

## Consequences

### Positive
- `ForecastingEngine` has complete visibility of future obligations
- No need for manual `advance()` — the system knows which installments are due when
- Complete payment history per plan (paid, skipped, overdue)
- Correct rounding: last installment absorbs cent differences
- Precise reports: "you have R$X in installments for the next 6 months"

### Negative / Trade-offs
- Migration of existing data (`card_installments` → new model) with risk of inconsistencies
- `first_due_date` in migration needs to be estimated (doesn't exist in old model)
- The installments UI needs to be rebuilt — more design work

### Accepted Risks
- **Incomplete migration**: plans migrated without correct firstDueDate → installments in wrong months. Mitigated with `legacy_card_installment_id` field for traceability and option to edit the date after migration.

## Alternatives Considered

### Keep `card_installments` with improvements
Add `due_date` and `expense_id` to the existing model.

**Discarded because**: The `card_installments` model is flat — it has no parent/child relationship. Adding individual installments would require the same new `installment_payments` table, making the old model unnecessary.

### Generate future expenses (one per month)
Automatically create a future `Expense` with `isProjected = true` for each installment.

**Discarded because**: Pollutes the transaction list with projected data. The `isProjected` field already existed but was never used coherently. `InstallmentPayment` is a distinct concept from `Expense` — mixing them creates ambiguity.

## Success Criteria

- [x] Create installment purchase → N payments generated automatically with correct due_dates
- [x] Sum of all `installment_payments.amount` == `installment_plans.total_amount`
- [x] `ForecastingEngine` reads `getPendingInRange()` and returns correct obligations
- [x] Old `advance()` redirects to `payInstallment()` without breaking UI changes

## References

- Plan: `plans/installments_redesign.md`
- Enables: `plans/forecasting.md` (ObligationEngine)
- Depends on: ADR-001 (category_id available for installment_plans)
- Migrations: V21 (schema), V22–V23 (data migration from card_installments)
