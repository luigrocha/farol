# Plan: Installments Redesign
**Area**: Domain · Database · Repositories · UI
**Priority**: P1 — blocks the Forecasting Engine
**Dependencies**: `categories_redesign.md` Phase 1-2 (category_id available)
**Impacted files**: `card_installment.dart`, `installment_repository.dart`, `add_installment_bottom_sheet.dart`, `installments_screen.dart`, `app_database.dart`

---

## 🔍 Problem Context

### Current state (confirmed in code)

```dart
// CORE PROBLEM: CardInstallment and Expense are parallel worlds

// CardInstallment tracks the plan — but doesn't generate expenses automatically
class CardInstallment {
  final int currentInstallment;  // manual counter
  final int numInstallments;
  final double monthlyAmount;
  // Missing: due_date, link to real expenses, payment history
}

// Expense has installmentPlanId — but CardInstallments doesn't reference expenses
class Expense {
  final int? installmentPlanId;  // field exists but not used coherently
  // Missing: installment_num, bidirectional link with the plan
}

// Current flow:
// 1. User records expense of R$100 (1st installment) — manually
// 2. User creates CardInstallment with numInstallments=12 — separately
// 3. Every month: user calls advance() manually
// 4. Future months: no recorded expenses → forecasting is blind
```

```dart
// InstallmentRepository.advance() — manual advance, no automation
Future<void> advance(int id, int newCurrent, int numInstallments) async {
  final newStatus = newCurrent >= numInstallments ? 'Settled' : 'Active';
  await _supabase.from('card_installments').update({
    'current_installment': newCurrent,
    'status': newStatus,
  }).eq('id', id);
  // Does not create expense, does not update forecasting, does not generate history
}
```

### Why this blocks Forecasting

The `ForecastingEngine` needs to know: "in the next 6 months, what are the confirmed financial commitments?". With the current model:
- R$800/month in 10 active installments → the engine doesn't know about any of these future installments
- The balance projection is off by R$8,000 (10 × R$800) for the upcoming months

---

## 📐 Correct Model: InstallmentPlan + InstallmentPayments

### Conceptual diagram

```
InstallmentPlan (the original purchase)
  │ id, description, total_amount, num_installments
  │ purchase_date, first_due_date, status (active/completed/cancelled)
  │
  └─── InstallmentPayment (each installment — generated automatically)
         installment_num: 1, due_date: 2026-02-10, amount: R$800, status: pending
         installment_num: 2, due_date: 2026-03-10, amount: R$800, status: pending
         ...
         installment_num: 10, due_date: 2026-11-10, amount: R$800, status: pending
                │
                └── Expense (created when marked as paid)
                      transaction_date: 2026-02-10
                      amount: R$800
                      installment_plan_id: <uuid>
                      installment_payment_id: <uuid>
```

### Supabase Schema

```sql
-- Parent plan: the original purchase
CREATE TABLE installment_plans (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES auth.users(id) NOT NULL,
  category_id         UUID REFERENCES categories(id),

  -- Purchase description
  description         TEXT NOT NULL,
  store_name          TEXT,
  purchase_date       DATE NOT NULL,

  -- Amounts
  total_amount        NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
  num_installments    INT NOT NULL CHECK (num_installments >= 2),
  installment_amount  NUMERIC(12,2) NOT NULL,  -- base amount (without rounding difference)

  -- Payment method
  payment_method      TEXT NOT NULL,           -- 'CREDIT_ITAU', 'CREDIT_NUBANK', etc.

  -- Calendar
  first_due_date      DATE NOT NULL,           -- date of the 1st due date

  -- State
  status              TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'completed', 'cancelled', 'paused')),

  -- Retroactive link to the original purchase expense (optional)
  original_expense_id UUID REFERENCES expenses(id),

  -- Migration: reference to old card_installments
  legacy_card_installment_id INT,

  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Individual installments — generated automatically when creating the plan
CREATE TABLE installment_payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id         UUID REFERENCES installment_plans(id) ON DELETE CASCADE NOT NULL,
  user_id         UUID REFERENCES auth.users(id) NOT NULL,

  -- Installment identification
  installment_num INT NOT NULL CHECK (installment_num >= 1),
  due_date        DATE NOT NULL,
  amount          NUMERIC(12,2) NOT NULL,  -- may differ on last one (rounding)

  -- State
  status          TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'overdue', 'skipped')),
  paid_date       DATE,
  paid_amount     NUMERIC(12,2),           -- may differ from amount (partial payment)

  -- Link to the real transaction (created when paying)
  expense_id      UUID REFERENCES expenses(id),

  -- Cache of the financial period for this installment
  financial_period_start  DATE,
  financial_period_end    DATE,

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(plan_id, installment_num)
);

-- Performance indexes for ForecastingEngine
CREATE INDEX idx_installment_payments_due_date
  ON installment_payments(user_id, due_date, status)
  WHERE status = 'pending';

CREATE INDEX idx_installment_payments_period
  ON installment_payments(user_id, financial_period_start, financial_period_end);
```

---

## ⚡ Impact Analysis

### Files to create (new)
```
lib/core/domain/entities/installment_plan.dart
lib/core/domain/entities/installment_payment.dart
lib/core/domain/services/installment_service.dart
lib/core/repositories/installment_plan_repository.dart
lib/core/repositories/installment_payment_repository.dart
```

### Files to modify
```
lib/core/database/app_database.dart            ← new Drift table (migration v3)
lib/features/installments/installments_screen.dart  ← migrate to new model
lib/features/installments/add_installment_bottom_sheet.dart  ← new flow
lib/core/models/expense.dart                   ← installment_payment_id fields
```

### Files to deprecate (gradually)
```
lib/core/models/card_installment.dart          ← replaced by InstallmentPlan
lib/core/repositories/installment_repository.dart  ← replaced by new repos
```

### Breaking Changes

| Change | Severity | Mitigation |
|---|---|---|
| `card_installments` → `installment_plans + payments` | 🔴 HIGH | Gradual migration with legacy table in parallel |
| `InstallmentRepository.advance()` → `payInstallment()` | 🟡 MEDIUM | Keep `advance()` as wrapper during transition |
| Installments UI completely redesigned | 🟡 MEDIUM | Feature flag for new UI |

---

## 🗺️ Incremental Strategy

```
analyze → propose → validate → phase 1 → review → phase 2 → review → ...
```

### PHASE 1 — Schema + Entities (no UI) ✅ COMPLETE
**Goal**: Create the new infrastructure without breaking anything existing.
**Reversibility**: 100% — only new files and tables.

```
Task 1.1: Supabase Schema (V21)
  - CREATE TABLE installment_plans (...)
  - CREATE TABLE installment_payments (...)
  - Indexes for ForecastingEngine
  - RLS policies (user_id = auth.uid())

Task 1.2: Dart Entities
  - lib/core/domain/entities/installment_plan.dart
    → InstallmentPlan with all fields + computed properties
    → remainingPayments, remainingAmount, progressPercent
    → isComplete, isActive, isOverdue
  - lib/core/domain/entities/installment_payment.dart
    → InstallmentPayment with daysUntilDue computed
    → isOverdue: due_date < today && status == 'pending'

Task 1.3: Basic Repositories
  - InstallmentPlanRepository.create(), getActive(), watchAll()
  - InstallmentPaymentRepository.getPending(), getByPlan(), getPendingInRange()
```

**Success test**: New tables exist in Supabase, repositories do basic CRUD.

---

### PHASE 2 — InstallmentService (the central logic) ✅ COMPLETE
**Goal**: The service that orchestrates plan creation + automatic installment generation.

```
Task 2.1: InstallmentService.createPurchase()
  - Receives: description, purchaseDate, totalAmount, numInstallments, categoryId, paymentMethod
  - Calculates: installmentAmount with correct rounding
    → base = (total / n * 100).floor() / 100
    → remainder = total - (base * n)
    → last installment = base + remainder
  - Calculates: firstDueDate (if not provided, next card due date)
  - Creates: 1 InstallmentPlan + N InstallmentPayments automatically
  - Event: InstallmentPlanCreated → ForecastingEngine invalidates cache

Task 2.2: InstallmentService.payInstallment()
  - Receives: paymentId, actualPaidDate?, actualAmount?
  - Creates: real Expense linked to the installment
  - Updates: InstallmentPayment → status: paid, paid_date, expense_id
  - Checks: if last installment → plan.status = completed
  - Event: InstallmentPaid → ForecastingEngine invalidates cache

Task 2.3: InstallmentService.skipInstallment()
  - Marks installment as skipped with note
  - Does not create expense

Task 2.4: InstallmentService tests
  - createPurchase(R$1200, 12x) → 12 InstallmentPayments of R$100
  - createPurchase(R$1000, 3x) → 2x R$333 + 1x R$334 (correct rounding)
  - payInstallment() → creates Expense, updates status
  - payInstallment() on last → closes the plan
```

---

### PHASE 3 — Migration of existing card_installments ✅ COMPLETE (V22–V23)
**Goal**: Convert existing data to the new model.

```
Task 3.1: Supabase migration script (V22)
  -- For each active card_installment:
  -- 1. Create installment_plan
  INSERT INTO installment_plans (user_id, description, total_amount, num_installments,
    installment_amount, purchase_date, first_due_date, status, legacy_card_installment_id)
  SELECT user_id, description, total_value, num_installments,
    monthly_amount, purchase_date,
    -- estimate first_due_date from purchase_date
    purchase_date + interval '1 month',
    CASE WHEN status = 'Active' THEN 'active' ELSE 'completed' END,
    id
  FROM card_installments;

  -- 2. Create installment_payments for remaining months
  -- (already paid installments: status = paid; future: status = pending)

Task 3.2: Post-migration verification (V23)
  - COUNT: card_installments = COUNT installment_plans with legacy_id
  - Verify: remainingPayments correct in all migrated plans
  - Verify: total_amount = installment_amount * num_installments

Task 3.3: Compatibility mode
  - InstallmentRepository (old) works in read-only mode
  - New creates go through InstallmentService
  - advance() redirects to payInstallment()
```

---

### PHASE 4 — New Installments UI ✅ COMPLETE
**Goal**: UI that reflects the new model and improves the experience.

```
Task 4.1: Redesigned InstallmentsScreen
  - List of active plans with progress (e.g. "iPhone 15 — 4/12 paid")
  - Highlighted installments for the current month
  - Filters: Active / Completed / All
  - Total active commitments highlighted

Task 4.2: Plan detail
  - Timeline of all installments (paid / pending / future)
  - "Record payment" button for current period installments
  - "Skip installment" button for exceptions
  - Projection: "Ends in March/2027"

Task 4.3: New installment purchase flow
  - add_installment_bottom_sheet.dart redesigned
  - Fields: description, total amount, number of installments, purchase date, 1st due date
  - Preview of installments before confirming
  - Automatic calculation of installment amount (with visible rounding)

Task 4.4: Dashboard — InstallmentsSummaryCard
  - Show current period installments (not just total active count)
  - Differentiate: paid in period vs. pending in period
  - Link to view details
```

---

### PHASE 5 — Forecasting Integration ✅ COMPLETE
**Goal**: ForecastingEngine reads pending installment_payments.
**Pre-condition**: `forecasting.md` Phase 1-2 started.

```
Task 5.1: ObligationEngine.getScheduledPayments()
  - Source 1: installment_payments WHERE status = 'pending' AND due_date IN range
  - Returns: List<ScheduledPayment> with due_date and amount
  - Used by ForecastingEngine for balance projection

Task 5.2: EnvelopeEngine — automatic envelopes for installments
  - For each active InstallmentPlan → create read-only envelope in the period
  - Envelope type 'obligation' — not editable by user
  - Amount = sum of installments in the period

Task 5.3: Dashboard — future installment projection
  - Chart: visible drops on installment due dates
  - Badge "R$X in installments this week"
```

---

## 🚨 Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Migration of card_installments with inconsistent data | Medium | Wrong data | Post-migration verification script before deprecating |
| Incorrect rounding in installments | High | Lost cents | Explicit test: sum of installments == total_amount |
| New UI confuses users accustomed to old flow | Medium | Feature abandonment | Feature flag: new UI only for new plans initially |
| due_date calculated incorrectly in migration | High | Installments in wrong months | Leave firstDueDate as editable field in plan onboarding |
| Duplicate expense (via legacy advance() + new payInstallment()) | Low | Duplicate data | Disable advance() when plan has payments in new model |

---

## ✅ Completion Checklist

### Phase 1 — Schema + Entities ✅ 2026-05-08
- [x] `installment_plans` and `installment_payments` tables created in Supabase (V21)
- [x] RLS policies configured
- [x] Performance indexes created
- [x] `InstallmentPlan` and `InstallmentPayment` entities in Dart
- [x] Basic repositories working

### Phase 2 — InstallmentService ✅ 2026-05-08
- [x] `createPurchase()` generates N installments automatically
- [x] Correct rounding: sum of installments == total
- [x] `payInstallment()` creates linked Expense
- [x] Last installment closes the plan
- [x] Tests: rounding, closing, edge cases

### Phase 3 — Migration ✅ 2026-05-08
- [x] Migration script executed in Supabase (V22–V23)
- [x] Verification: 0 plans with inconsistent data
- [x] `advance()` redirects to `payInstallment()`

### Phase 4 — New UI ✅ 2026-05-08
- [x] InstallmentsScreen with plan list + progress
- [x] Installment timeline in plan detail
- [x] New purchase flow with installment preview
- [x] Dashboard shows current period installments

### Phase 5 — Forecasting ✅ 2026-05-08
- [x] `ObligationEngine` reads pending installment_payments
- [x] Automatic envelopes for active plans
- [x] Documented in `docs/decisions/005-installments-redesign.md`

---

## 📎 References

- Detailed analysis: `FAROL_PREDICTIVE_ENGINE.md` → Section 6
- ADR: `docs/decisions/005-installments-redesign.md`
- Depends on: `categories_redesign.md` (Phase 1-2)
- Enables: `forecasting.md` (ObligationEngine), `financial_engine.md` (Phase 5)
