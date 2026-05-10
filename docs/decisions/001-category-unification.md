# ADR-001: Category System Unification

**Date**: 2026-05-07
**Status**: Implemented (Phases 1-4 complete, V20 pending production execution)
**Area**: Domain · Database

---

## Context

Farol had two parallel and incompatible category systems:

1. **Enum `ExpenseCategory`** in `lib/core/models/enums.dart` — 9 values hardcoded in Dart, not extensible without recompiling. Has localization logic and Swile classification.

2. **`CategoryTable`** in Drift + `categories` table in Supabase — allows user custom categories, has `dbValue`, `name`, `emoji`, `isSwile`, `isSystem`, `orderIndex`.

The critical problem: `ExpenseCategory.fromDb(value)` throws `StateError: No element` when the `value` is a custom category created by the user. This is a time bomb in production. Expenses store `category` as a raw `String`, and different parts of the code convert or don't convert that String to the enum inconsistently.

Additionally, the planned forecasting system requires an enriched category model (`FinancialType`, `isFixed`, `typical_recurrence`) that the enum cannot provide.

## Decision

**Create a unified `CategoryRef` value object** that:
- Completely replaces the `ExpenseCategory` enum (gradual migration in 4 phases)
- Maps 1:1 with a `categories` table in Supabase (and its Drift mirror)
- Never throws an exception for unknown categories (falls back to `uncategorized`)
- Supports system categories (is_system: true) and custom ones (user_id not null)
- Includes `FinancialType` for the forecasting engine

The migration is **additive-first**: the new system is added without removing the old one, data is migrated, UI is migrated, and only then the enum is removed.

## Consequences

### Positive
- Eliminates the possibility of `StateError` for unknown category
- Enables unlimited user custom categories
- Provides `FinancialType` (need|want|investment) for forecasting
- Allows subcategories (parent_id)
- Single source of truth for categories (no two systems)

### Negative / Trade-offs
- 4-phase migration requires ~3-4 weeks of work
- During the transition, both systems coexist (temporary complexity)
- Queries that filter by category need to be updated to use UUID instead of String
- `BudgetGoals.category` and `PeriodBudget.category` are also String → need similar migration

### Accepted Risks
- **Incomplete backfill**: if an expense has a `category` String that doesn't match any slug → assigned to `uncategorized`. Requires post-backfill audit.
- **Drift migration would fail with corrupted data**: mitigated with defensive `onUpgrade` migration.

## Alternatives Considered

### Alternative 1: Extend the enum
Add more values to the `ExpenseCategory` enum to cover custom categories.

**Discarded because**: Dart enums are static — they can't be created at runtime. A user can't create an enum value. This doesn't solve the problem of custom categories.

### Alternative 2: Only use CategoryTable (remove enum immediately)
Remove the enum in the first PR and migrate everything at once.

**Discarded because**: Big bang rewrite with high risk of regressions. The enum is in ~15 files. Gradual migration significantly reduces the risk.

### Alternative 3: Keep both systems indefinitely with an adapter
Create an adapter that maps between enum and CategoryTable, keeping both.

**Discarded because**: Increases technical debt, doesn't resolve the StateError (the adapter would need the fallback anyway), and doesn't provide `FinancialType`.

## Success Criteria

- [x] `CategoryResolver.resolve('ANY_STRING')` never throws an exception in production
- [x] 0 occurrences of `ExpenseCategory.fromDb()` in the final codebase
- [x] Users can create custom categories and use them without crashing the app
- [x] Expenses with custom categories display correctly on all screens
- [x] The `FinancialType` of each category is correct (need/want/investment)

## Migrations Executed

| Migration | Status |
|---|---|
| V17 — recreates `categories` with UUID + system seed | ✅ Executed |
| V18 — `category_id UUID` nullable in `expenses` | ✅ Executed |
| V19 — backfill `category_id` in existing expenses | ✅ Executed |
| V20 — `category_id` NOT NULL | ✅ Executed |

## References

- Implementation plan: `plans/categories_redesign.md`
- Main affected code: `lib/core/models/enums.dart`, `lib/core/models/category.dart`
- Enables: `plans/financial_engine.md`, `plans/forecasting.md`
