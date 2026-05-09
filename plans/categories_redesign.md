# Plan: Categories System Redesign

**Area**: Domain · Database · Repositories  
**Priority**: P0 — blocks everything else  
**Dependencies**: None (this plan is the starting point)  
**Files impacted**: `enums.dart`, `category.dart`, `app_database.dart`, `category_repository.dart`, all repositories using `ExpenseCategory`

---

## 🔍 Problem Context

### Current state (confirmed in code)

```dart
// PROBLEM 1: Two parallel, incompatible systems

// System A — hardcoded enum in Dart (enums.dart)
enum ExpenseCategory {
  housing('HOUSING', ...), transport('TRANSPORT', ...),
  // ... 9 fixed values, not extensible without recompiling
}

// System B — table in DB (app_database.dart + Supabase)
class CategoryTable extends Table {
  // dbValue, name, emoji, isSwile, isSystem, orderIndex
  // Allows user custom categories
}

// TIME BOMB:
ExpenseCategory.fromDb('CUSTOM_ROPA') // → StateError: No element
```

```dart
// PROBLEM 2: Expenses store category as raw String
class Expense {
  final String category; // 'HOUSING', 'CUSTOM_ROPA', ...
  // In some flows: ExpenseCategory.fromDb(category) → may throw
  // In other flows: used as raw string → inconsistent
}
```

### Current impact
- Any custom category can crash the app
- `BudgetGoals` uses `category` as string → same time bomb
- `PeriodBudget` uses `category` as string → inconsistent with CategoryTable
- Forecasting cannot operate on categories without a unified model

---

## 📐 Proposed Architecture

### Unified model: `CategoryRef`

```dart
// Completely replaces ExpenseCategory enum
// Is a value object in the domain — always valid, never throws
class CategoryRef {
  final String id;           // UUID (Supabase) or local slug
  final String slug;         // 'housing', 'custom_ropa'
  final String name;         // 'Moradia' (localized)
  final String emoji;
  final String? colorHex;
  final FinancialType financialType; // need | want | investment | income | transfer
  final String? parentId;
  final bool isSystem;
  final bool isSwile;
  final bool isFixed;        // typically fixed

  bool get isCustom => !isSystem;

  // Backward compatibility — never throws StateError
  static CategoryRef fromLegacyString(String dbValue, List<CategoryRef> all) {
    return all.firstWhere(
      (c) => c.slug.toUpperCase() == dbValue.toUpperCase(),
      orElse: () => CategoryRef.uncategorized(dbValue),
    );
  }
}
```

### Proposed DB schema

```sql
-- Supabase migration
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id),  -- NULL = global system
  parent_id     UUID REFERENCES categories(id),
  slug          TEXT NOT NULL,
  name          TEXT NOT NULL,
  emoji         TEXT NOT NULL DEFAULT '📋',
  color_hex     TEXT,
  financial_type TEXT NOT NULL DEFAULT 'want'
    CHECK (financial_type IN ('need','want','investment','income','transfer')),
  is_system     BOOLEAN DEFAULT FALSE,
  is_swile      BOOLEAN DEFAULT FALSE,
  is_fixed      BOOLEAN DEFAULT FALSE,
  is_archived   BOOLEAN DEFAULT FALSE,
  display_order INT DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, slug)
);

-- Additional field in expenses (backward compat: nullable first)
ALTER TABLE expenses ADD COLUMN category_id UUID REFERENCES categories(id);
```

---

## ⚡ Impact Analysis

### Files using `ExpenseCategory` enum directly
```
lib/core/models/enums.dart                    ← enum definition
lib/features/transactions/quick_add_bottom_sheet.dart
lib/features/transactions/edit_expense_bottom_sheet.dart
lib/features/analytics/analytics_screen.dart
lib/features/dashboard/widgets/expense_breakdown.dart
lib/features/budget/presentation/budget_goals_sheet.dart
lib/features/period_budget/presentation/budget_edit_sheet.dart
lib/features/period_budget/presentation/period_budget_screen.dart
lib/features/settings/categories_management_screen.dart
lib/core/repositories/category_repository.dart
```

### Files using `category` as raw String
```
lib/core/database/app_database.dart           ← DAOs with category String
lib/core/models/expense.dart                  ← category: String
lib/core/models/period_budget.dart            ← category: String
lib/core/models/budget_goal.dart              ← category: String
lib/core/repositories/period_budget_repository.dart
lib/core/repositories/budget_goals_repository.dart
```

### Identified Breaking Changes
| Change | Severity | Mitigation |
|---|---|---|
| Delete enum `ExpenseCategory` | 🔴 CRITICAL | Keep in parallel until Phase 4 |
| `Expense.category` String → `CategoryRef` | 🔴 CRITICAL | Add nullable `categoryRef` field |
| `BudgetGoal.category` String | 🟡 MEDIUM | `CategoryResolver` as adapter |
| `category_id` in expenses (Supabase) | 🟡 MEDIUM | Nullable + backfill job |
| Drift DAOs with `CategoryTable` | 🟢 LOW | Extension, not replacement |

---

## 🗺️ Incremental Strategy

```
analyze → propose → validate → phase 1 → review → phase 2 → review → ...
```

### PHASE 1 — The Safe Bridge (no breaking changes)
**Goal**: Create new infrastructure without touching existing code.
**Reversibility**: 100% — only new files added.

```
Task 1.1: Create CategoryRef value object
  - lib/core/domain/value_objects/category_ref.dart
  - FinancialType enum
  - CategoryRef.uncategorized() factory (safe fallback)
  - CategoryRef.fromLegacyString() (adapter with no exceptions)

Task 1.2: Create CategoryResolver service
  - lib/core/domain/services/category_resolver.dart
  - Load categories from DB (Supabase + Drift)
  - Map legacy String → CategoryRef (never throws)
  - In-memory cache (invalidate on category change)

Task 1.3: Create categories table in Supabase
  - Migration SQL with all system slugs
  - Seed: 1:1 mapping with current enum (HOUSING → housing, etc.)
  - RLS policies

Task 1.4: Add category_id to expenses (nullable)
  - Supabase: ALTER TABLE expenses ADD COLUMN category_id UUID
  - Drift: add nullable field to schema (migration)
  - Do NOT update any existing queries yet
```

**Success test**: `CategoryResolver.resolve('CUSTOM_XYZ')` returns `CategoryRef.uncategorized()` — never StateError.

---

### PHASE 2 — The Backfill (existing data)
**Goal**: Populate `category_id` in existing expenses.
**Reversibility**: High — old `category` String field remains intact.

```
Task 2.1: Supabase backfill job
  - SQL script: UPDATE expenses SET category_id = (
      SELECT id FROM categories WHERE slug = LOWER(expenses.category)
    )
  - Execute in Supabase SQL editor (not in app code)
  - Verify: COUNT(*) WHERE category_id IS NULL after backfill

Task 2.2: Ensure new expenses always have category_id
  - Modify ExpenseRepository.insert() to resolve and save category_id
  - Use CategoryResolver to map string to UUID
  - String 'category' field still saved (backward compat)
```

**Success test**: All new expenses have `category_id` NOT NULL. Old ones have field populated post-backfill.

---

### PHASE 3 — Provider Migration
**Goal**: Riverpod providers use `CategoryRef` instead of enum.
**Reversibility**: Medium — requires coordinated UI changes.

```
Task 3.1: Refactored CategoryRepository
  - watchCategories() → Stream<List<CategoryRef>>
  - Internally: combines CategoryTable (Drift) + Supabase categories
  - Provides CategoryRef for system + user custom

Task 3.2: categoryProvider in Riverpod
  - Global provider for cached categories
  - Used by all screens needing the list
  - Invalidates when user adds/edits category

Task 3.3: Migrate screens one by one (coordinated)
  - categories_management_screen.dart → uses CategoryRef
  - quick_add_bottom_sheet.dart → dropdown uses CategoryRef
  - expense_breakdown.dart → uses CategoryRef for display
  - Keep adapter for code still using String
```

**Success test**: Open app, create custom category, create expense with it, close and reopen → expense shows correct category. No StateError.

---

### PHASE 4 — Enum Removal (cleanup)
**Goal**: Remove `ExpenseCategory` enum from code.
**Reversibility**: Low — irreversible change, do last.
**Pre-condition**: Phases 1-3 complete and stable in production ≥2 weeks.

```
Task 4.1: Final enum usage audit
  - grep -r "ExpenseCategory" lib/ → must return 0 uses

Task 4.2: Delete enum from enums.dart
  - Keep swileCategories as Set<String> (or migrate to CategoryRef.isSwile)

Task 4.3: Make category_id NOT NULL in expenses
  - Supabase migration: ALTER TABLE expenses ALTER COLUMN category_id SET NOT NULL
  - Verify first that NO nulls exist in production

Task 4.4: Deprecate String 'category' field
  - Keep in DB for 1 more period (backward compat with exports)
  - Eventually: DROP COLUMN category (out of scope for this plan)
```

---

## 🚨 Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| StateError in production (unknown category) | High (already occurs) | Crash | Phase 1: CategoryRef.uncategorized() as fallback |
| Incomplete backfill (non-matching slugs) | Medium | Orphaned data | Verify COUNT IS NULL post-backfill, manual fix if outliers |
| Provider rebuild cascade on CategoryRef change | Medium | Performance | autoDispose + family providers per category |
| Drift migration error (nullable field) | Low | Crash on upgrade | Test migration in emulator before release |
| Custom category with slug clashing system | Low | DB conflict | UNIQUE constraint `(user_id, slug)` — user_id NULL = system |

---

## ✅ Completion Checklist

### Phase 1
- [ ] `CategoryRef` value object created and tested
- [ ] `FinancialType` enum created
- [ ] `CategoryResolver` created with `fromLegacyString()` with no exceptions
- [ ] `categories` table created in Supabase with system category seed
- [ ] `category_id UUID` field added to `expenses` in Supabase (nullable)
- [ ] Drift schema updated with migration
- [ ] Test: `CategoryResolver.resolve('ANYTHING')` never throws

### Phase 2
- [ ] Backfill SQL executed in Supabase
- [ ] Verification: 0 nulls in `category_id` post-backfill
- [ ] `ExpenseRepository.insert()` saves `category_id`
- [ ] Test: new expense has `category_id` NOT NULL

### Phase 3
- [ ] `CategoryRepository.watchCategories()` returns `List<CategoryRef>`
- [ ] `categoryProvider` in Riverpod works
- [ ] At least 3 screens migrated to `CategoryRef`
- [ ] Test: create custom category → appears in dropdown → create expense → displays correctly

### Phase 4
- [ ] 0 uses of `ExpenseCategory` enum in code
- [ ] `category_id` NOT NULL in production
- [ ] Document decision in `docs/decisions/001-category-unification.md`

---

## 📎 References

- Detailed analysis: `FAROL_PREDICTIVE_ENGINE.md` → Section 3
- Pending ADR: `docs/decisions/001-category-unification.md`
- Depends on: no other plans
- Unblocks: `financial_engine.md`, `forecasting.md`
