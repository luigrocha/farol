# Plan: Financial Engine Central

**Area**: Domain · Services · Providers  
**Priority**: P1  
**Dependencies**: `categories_redesign.md` (Phase 3 complete)  
**Files impacted**: New files in `lib/core/domain/`, refactor of `DashboardScreen`, providers

---

## 🔍 Problem Context

### Current state (confirmed in code)

```dart
// PROBLEM: Each widget calculates its own version of financial truth

// Widget A: calculates totalExpenses one way
class KpiGrid extends ConsumerWidget {
  // ref.watch(expenseProvider) → sums expenses for period
}

// Widget B: calculates balance a different way
class PeriodBalanceHero extends ConsumerWidget {
  // ref.watch(incomeProvider) - ref.watch(expenseProvider)
  // uses different logic, different filtering
}

// Widget C: calculates health score with its own inputs
class HealthGaugeCard extends ConsumerWidget {
  // calls FinancialCalculatorService.calculateHealthScore(...)
  // with data that may be incomplete
}

// RESULT: 3 widgets, 3 sources of truth, possible inconsistencies
```

```dart
// FinancialCalculatorService is a set of static functions
// Has no state, doesn't produce a coherent snapshot
// No "the financial state of the period" — just isolated calculations
class FinancialCalculatorService {
  static double calculateSavingsRate(...)   // just this
  static int calculateHealthScore(...)       // just this
  // etc.
}
```

### What's needed?

A single observable that produces **the complete financial state of the period**. All widgets consume this observable — one source of truth.

```dart
// GOAL: this
final snapshot = ref.watch(financialSnapshotProvider(period));
// snapshot.totalIncome, snapshot.totalSpent, snapshot.healthScore,
// snapshot.envelopes, snapshot.burnRate, ...
```

---

## 📐 Proposed Architecture

### New file structure

```
lib/core/domain/
├── entities/
│   ├── financial_snapshot.dart      ← central object
│   ├── envelope.dart                ← budget per category
│   └── scheduled_payment.dart       ← installments + future recurring
├── value_objects/
│   ├── money.dart                   ← safe currency type
│   ├── category_ref.dart            ← (from categories_redesign plan)
│   └── burn_rate.dart               ← spending velocity
└── services/
    ├── financial_engine.dart        ← central orchestrator
    └── envelope_engine.dart         ← envelope logic
```

### The `FinancialSnapshot`

```dart
/// The single source of financial truth for the period.
/// Produced by FinancialEngine, consumed by all UI.
class FinancialSnapshot {
  final FinancialPeriod period;
  final DateTime generatedAt;

  // ── Income ────────────────────────────────────────
  final Money totalIncome;
  final Money cashIncome;      // excludes Swile
  final Money swileIncome;

  // ── Expenses ──────────────────────────────────────
  final Money totalSpent;
  final Money cashSpent;       // excludes Swile
  final Money swileSpent;

  // ── Balance ───────────────────────────────────────
  final Money currentBalance;  // cashIncome - cashSpent
  final Money swileBalance;    // swileIncome - swileSpent

  // ── Envelopes ─────────────────────────────────────
  final List<EnvelopeStatus> envelopes;
  final Money totalAllocated;
  final Money totalBudgeted;

  // ── Financial health ──────────────────────────────
  final int healthScore;           // 0-10
  final String healthColor;        // 'green' | 'amber' | 'red'
  final double savingsRate;        // %

  // ── Future obligations ────────────────────────────
  final List<ScheduledPayment> upcomingPayments;
  final Money totalFutureObligations;

  // ── Computed conveniences ─────────────────────────
  bool get isPositive => currentBalance > Money.zero;
  Money get remainingBudget => totalAllocated - cashSpent;
}
```

### Value Object: `Money`

```dart
/// Safe type for currency. Avoids double arithmetic errors.
/// Internally works with cents (int) for exact precision.
class Money {
  final int _cents;
  final String currencyCode; // 'BRL' by default

  static const Money zero = Money._(0);

  Money.fromDouble(double amount) : _cents = (amount * 100).round();
  Money.fromCents(int cents) : _cents = cents;

  double get amount => _cents / 100;
  int get cents => _cents;

  Money operator +(Money other) => Money.fromCents(_cents + other._cents);
  Money operator -(Money other) => Money.fromCents(_cents - other._cents);
  Money operator *(double factor) => Money.fromCents((_cents * factor).round());

  bool operator >(Money other) => _cents > other._cents;
  bool operator <(Money other) => _cents < other._cents;

  bool get isZero => _cents == 0;
  bool get isNegative => _cents < 0;

  String get formatted => FinancialCalculatorService.formatBRL(amount);

  @override
  bool operator ==(Object other) => other is Money && _cents == other._cents;
}
```

---

## ⚡ Impact Analysis

### Files to create (without touching existing code)
```
lib/core/domain/entities/financial_snapshot.dart  ← NEW
lib/core/domain/entities/envelope.dart             ← NEW
lib/core/domain/value_objects/money.dart           ← NEW
lib/core/domain/services/financial_engine.dart     ← NEW
lib/core/domain/services/envelope_engine.dart      ← NEW
lib/core/providers/financial_snapshot_provider.dart← NEW
```

### Files to modify (with backward compat)
```
lib/features/dashboard/dashboard_screen.dart       ← add snapshot watch
lib/features/dashboard/widgets/kpi_grid.dart       ← migrate to snapshot
lib/features/dashboard/widgets/period_balance_hero.dart
lib/features/dashboard/widgets/health_gauge_card.dart
```

### Breaking Changes
| Change | Severity | Mitigation |
|---|---|---|
| Dashboard providers refactored | 🟡 MEDIUM | Migrate widget by widget, not all at once |
| `FinancialCalculatorService` → internal engine methods | 🟢 LOW | Keep static methods as wrappers |

---

## 🗺️ Incremental Strategy

### PHASE 1 — Money Value Object (no UI)
**Goal**: Safe type for currency. Prerequisite for everything.
**Reversibility**: 100%.

```
Task 1.1: Create lib/core/domain/value_objects/money.dart
  - Money.fromDouble(), Money.fromCents()
  - Arithmetic operators (+, -, *)
  - Comparators (>, <, ==)
  - money.formatted → uses FinancialCalculatorService.formatBRL()
  - Money.zero as constant

Task 1.2: Money tests
  - Money(100.00) + Money(50.50) == Money(150.50)
  - Money(10.00) * 3 == Money(30.00)
  - No floating point errors: Money(0.1) + Money(0.2) == Money(0.3)
```

**Success test**: `dart test test/core/money_test.dart` → all pass.

---

### PHASE 2 — FinancialSnapshot Entity (no calculation logic)
**Goal**: Define the contract for the central object.
**Reversibility**: 100%.

```
Task 2.1: Create lib/core/domain/entities/financial_snapshot.dart
  - Define all fields with Money and correct types
  - Factory FinancialSnapshot.empty(period) for loading states
  - copyWith() for partial updates

Task 2.2: Create lib/core/domain/entities/envelope.dart
  - EnvelopeStatus (ok | warning | overspent)
  - Fields: category, allocated, spent, remaining, rolloverPolicy

Task 2.3: Create lib/core/domain/entities/scheduled_payment.dart
  - For future installments and recurring
  - daysFromNow computed property
```

---

### PHASE 3 — FinancialEngine Service
**Goal**: The service that produces FinancialSnapshot.
**Reversibility**: High — engine is new, doesn't replace anything yet.

```
Task 3.1: Create lib/core/domain/services/financial_engine.dart
  - Injects: ExpenseRepository, IncomeRepository, InstallmentRepository
  - buildSnapshot(period, userId) → Future<FinancialSnapshot>
  - Internally uses FinancialCalculatorService for health score
  - Simple cache: Map<String, FinancialSnapshot> per period

Task 3.2: Create financialSnapshotProvider in Riverpod
  - @riverpod Future<FinancialSnapshot> financialSnapshot(period)
  - autoDispose
  - Invalidates when expenses or incomes of period change

Task 3.3: Engine integration test
  - Synthetic data in test
  - Verify that totalIncome + totalSpent + balance are coherent
```

---

### PHASE 4 — Dashboard Migration
**Goal**: Dashboard consumes a single observable.
**Reversibility**: Medium — visible UI changes.

```
Task 4.1: Dashboard consumes financialSnapshotProvider
  - Add ref.watch(financialSnapshotProvider(period)) in DashboardScreen
  - Pass snapshot as parameter to child widgets

Task 4.2: Migrate KpiGrid to snapshot
  - KpiGrid(snapshot: snapshot) instead of individual queries

Task 4.3: Migrate PeriodBalanceHero to snapshot
  - PeriodBalanceHero(snapshot: snapshot)

Task 4.4: Migrate HealthGaugeCard to snapshot
  - HealthGaugeCard(snapshot: snapshot)
  - healthScore comes from snapshot, not calculated in widget
```

---

### PHASE 5 — EnvelopeEngine
**Goal**: Budget per category logic with rollover.
**Reversibility**: High.
**Pre-condition**: `categories_redesign.md` Phase 3 complete.

```
Task 5.1: Create lib/core/domain/services/envelope_engine.dart
  - getEnvelopes(period, userId) → Future<List<EnvelopeStatus>>
  - calculateRollover(envelope) → Money
  - suggestAllocation(category, history) → Money

Task 5.2: Integrate envelopes in FinancialSnapshot
  - snapshot.envelopes comes from EnvelopeEngine

Task 5.3: UI: EnvelopeCard in period_budget_screen.dart
  - Display rollover if exists
  - Badge "Carried over: +R$120" on envelopes with positive balance
```

---

## 🚨 Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Double arithmetic in Money | High | Incorrect data | Use cents internally (int) |
| FinancialSnapshot inconsistent if partial queries | Medium | Incorrect UI | Factory FinancialSnapshot.empty() for loading |
| Provider rebuild cascade | Medium | Performance | autoDispose + select() for specific fields |
| Dashboard migration breaks UI temporarily | Medium | Degraded UX | Migrate widget by widget, not all at once |

---

## ✅ Completion Checklist

### Phase 1 — Money
- [ ] `Money` value object with internal cents
- [ ] Arithmetic operators correct
- [ ] Test: 0.1 + 0.2 == 0.3 (no floating point error)

### Phase 2 — Entities
- [ ] `FinancialSnapshot` with all fields
- [ ] `FinancialSnapshot.empty(period)` factory
- [ ] `EnvelopeStatus` entity
- [ ] `ScheduledPayment` entity

### Phase 3 — Engine
- [ ] `FinancialEngine.buildSnapshot()` functional
- [ ] `financialSnapshotProvider` in Riverpod
- [ ] Integration test with synthetic data

### Phase 4 — Dashboard
- [ ] Dashboard uses single `financialSnapshotProvider`
- [ ] KpiGrid, PeriodBalanceHero, HealthGaugeCard use snapshot
- [ ] 0 duplicate queries between dashboard widgets

### Phase 5 — Envelopes
- [ ] `EnvelopeEngine` with rollover
- [ ] Envelopes integrated in snapshot
- [ ] UI displays rollover in budget screen
- [ ] Document in `docs/decisions/002-financial-snapshot.md`

---

## 📎 References

- Detailed analysis: `FAROL_PREDICTIVE_ENGINE.md` → Sections 2 and 4
- Pending ADR: `docs/decisions/002-financial-snapshot.md`
- Depends on: `categories_redesign.md`
- Unblocks: `forecasting.md`
