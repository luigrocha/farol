# ADR-002: FinancialSnapshot as the Single Source of Truth for the Dashboard

**Date**: 2026-05-08
**Status**: Implemented ✅
**Area**: Domain · Providers · UI

---

## Context

The previous dashboard had multiple widgets that independently calculated their own version of the financial state:

- `KpiGrid` calculated expense totals via its own provider
- `PeriodBalanceHero` calculated the balance with its own logic
- `HealthGaugeCard` called `FinancialCalculatorService.calculateHealthScore()` directly with potentially incomplete inputs

`FinancialCalculatorService` was a collection of static methods with no state. There was no "snapshot" of the financial state of the period — each widget built its own partial view.

This caused: potential inconsistencies between widgets, duplicate queries to the same data source, difficulty adding forecasting (which widget owns it?), and complexity in caching the financial state.

## Decision

**Create `FinancialSnapshot` as the single source of truth** of the financial state for a period. The `FinancialEngine` produces this snapshot. All dashboard widgets consume it as the single observable.

```dart
// Before: each widget has its own provider
class KpiGrid extends ConsumerWidget {
  Widget build(context, ref) {
    final expenses = ref.watch(expensesProvider(period)); // own query
    // ...
  }
}

// After: all consume the same snapshot
class KpiGrid extends ConsumerWidget {
  final FinancialSnapshot snapshot;
  Widget build(context, ref) {
    // snapshot.totalSpent, snapshot.healthScore, etc. — already calculated
  }
}
```

The `FinancialSnapshot` includes: balances (income/expenses/current), envelopes, health score, savings rate, future obligations. In future versions: burn rate, projected balance, insights.

## Consequences

### Positive
- Single source of truth → impossible for widgets to show inconsistent numbers
- Centralized cache → single TTL, coordinated invalidation
- Forecasting has a natural home (extends FinancialSnapshot)
- Simpler tests: test the engine, not each widget
- Performance: N queries → 1 well-constructed snapshot

### Negative / Trade-offs
- Dashboard refactoring requires coordinating changes across 4-5 widgets
- The snapshot may be heavier to compute than individual simple queries
- If one field of the snapshot changes, all widgets using it need updating

### Accepted Risks
- **Loading state**: while the snapshot loads, widgets show skeleton. Mitigated with `FinancialSnapshot.empty()` factory.
- **Rebuild granularity**: if one field changes, all widgets using the snapshot rebuild. Mitigated with Riverpod's `ref.select()`.

## Alternatives Considered

### Alternative 1: Multiple specialized providers (previous state)
Keep one provider per data type (incomes, expenses, health, etc.).

**Discarded because**: Doesn't scale with forecasting. The data is interdependent (health score needs income + expenses + installments + emergency fund). Keeping them separate guarantees eventual inconsistencies.

### Alternative 2: A global financial state BLoC
Use BLoC instead of Riverpod for dashboard state.

**Discarded because**: Farol uses Riverpod throughout the codebase. Introducing BLoC creates architectural inconsistency. The problem is solved with Riverpod correctly.

## Success Criteria

- [x] `DashboardScreen` makes exactly 1 `ref.watch()` to get the financial state
- [x] `KpiGrid`, `PeriodBalanceHero`, `HealthGaugeCard` receive `FinancialSnapshot` as a parameter
- [x] 0 duplicate queries between dashboard widgets for the same period
- [x] Test: `FinancialSnapshot.totalIncome - totalSpent == currentBalance` always true

## References

- Implementation plan: `plans/financial_engine.md`
- Affected code: `lib/features/dashboard/`
- Depends on: ADR-001 (unified categories)
- Enables: ADR-003 (forecasting)
