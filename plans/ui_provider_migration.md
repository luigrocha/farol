# Plan: UI Provider Migration — Resolving ui_audit_2026_05_08
**Area**: UI · Providers · Domain
**Priority**: P1 — UI polish, no breaking changes
**Dependencies**: None (domain already implemented)
**Origin**: `docs/architecture/ui_audit_2026_05_08.md`

---

## 🔍 Context

The predictive engine is complete. The audit identified 4 points where the UI still uses legacy providers/logic instead of the new domain. This plan resolves them incrementally, one file at a time.

### Problem map

```
quick_add_bottom_sheet.dart    → categoriesStreamProvider (AsyncValue<List<Category>>)
edit_expense_bottom_sheet.dart → categoriesStreamProvider (AsyncValue<List<Category>>)
                                  ↓ should be
                                  categoriesRefProvider (List<CategoryRef>) — synchronous, never null

expense_breakdown.dart         → categoriesMapProvider (Map<String, Category>)
                                  budgetGoalsMapProvider (legacy BudgetGoal)
                                  ↓ should be
                                  categoriesRefProvider for names/emojis

health_screen.dart             → cashExpensesProvider + cashRemainingProvider
                                  + installmentsProvider (CardInstallment!)
                                  + FinancialCalculatorService.calculateHealthScore()
                                  ↓ should be
                                  financialSnapshotProvider.healthScore (already computed)

transactions_screen.dart       → isFixed branch + deleteFixedSeriesFrom()
                                  ↓ should be
                                  link to RecurringRule if expense.recurringRuleId != null
```

### Why this order?

- **Phase 1** (category pickers) — highest impact on the most critical flow (create expense), lowest risk
- **Phase 2** (expense_breakdown) — isolated widget with no side effects
- **Phase 3** (health_screen) — requires analysis of sub-scores that depend on additional data
- **Phase 4** (isFixed cleanup) — requires verification of production data before removing

---

## ⚡ Impact Analysis

| File | Lines affected | Risk | Backward compat? |
|---|---|---|---|
| `quick_add_bottom_sheet.dart` | ~10 lines | Low | Yes — `CategoryRef` has `id`, `slug`, `name`, `emoji` |
| `edit_expense_bottom_sheet.dart` | ~10 lines | Low | Yes |
| `expense_breakdown.dart` | ~5 lines | Low | Yes — display only |
| `health_screen.dart` | ~20 lines | Medium | Yes — sub-scores partially reused |
| `transactions_screen.dart` | ~20 lines | Medium | Yes — keep fallback for legacy isFixed |

### Providers removed from files (not deleted, just stopped using)

- `categoriesStreamProvider` — no longer imported in bottom sheets
- `categoriesMapProvider` — no longer imported in expense_breakdown
- `cashExpensesProvider`, `cashRemainingProvider`, `installmentsProvider` — no longer used in health_screen

---

## 🗺️ Phases

---

### PHASE 1 — Category Pickers: quick_add + edit_expense
**Goal**: Replace `categoriesStreamProvider` with `categoriesRefProvider` in both bottom sheets.
**Reversibility**: 100% — provider swap, no schema or business logic changes.

#### What changes

`categoriesStreamProvider` returns `AsyncValue<List<Category>>` — requires `.when(loading, error, data)`.
`categoriesRefProvider` returns `List<CategoryRef>` — synchronous, no loading state.

```dart
// ❌ BEFORE — quick_add_bottom_sheet.dart
final categoriesAsync = ref.watch(categoriesStreamProvider);
// ... inside build:
categoriesAsync.when(
  loading: () => const SizedBox(height: 100, child: CircularProgressIndicator()),
  error: (_, __) => Text('Error'),
  data: (categories) => GridView(...),
)

// ✅ AFTER
final categories = ref.watch(categoriesRefProvider); // List<CategoryRef>, never null
// ... directly:
GridView(children: categories.map((c) => _catChip(c, context)).toList())
```

#### Adjustment to `_catChip`

The `_catChip` method currently receives `Category`. Change to `CategoryRef`:

```dart
// ❌ BEFORE
Widget _catChip(Category c, BuildContext context) { ... }

// ✅ AFTER
Widget _catChip(CategoryRef c, BuildContext context) { ... }
// CategoryRef has: c.slug, c.name, c.emoji — same fields used
```

#### Adjustment to `_save` (quick_add)

```dart
// ❌ BEFORE
final categories = ref.read(categoriesStreamProvider).value ?? [];
final currentCat = categories.firstWhere((c) => c.slug == _categoryDbValue,
    orElse: () => categories.isNotEmpty ? categories.first : const Category(...));

// ✅ AFTER
final categories = ref.read(categoriesRefProvider);
final currentCat = categories.firstWhere((c) => c.slug == _categoryDbValue,
    orElse: () => categories.isNotEmpty ? categories.first : CategoryRef.uncategorized(_categoryDbValue));
```

#### Adjustment in edit_expense

`edit_expense_bottom_sheet.dart` has `_subcategories` with UPPERCASE keys (`'HOUSING'`, `'TRANSPORT'`...).
When migrating to `CategoryRef`, slugs are lowercase (`'housing'`, `'transport'`).
Update `_subcategories` map keys to lowercase for consistency.

```dart
// ❌ BEFORE
static const _subcategories = {
  'HOUSING': [...],
  'TRANSPORT': [...],
};

// ✅ AFTER
static const _subcategories = {
  'housing': [...],
  'transport': [...],
};
```

**Files modified**:
- `lib/features/transactions/quick_add_bottom_sheet.dart`
- `lib/features/transactions/edit_expense_bottom_sheet.dart`

**Success test**: Open quick_add → category picker renders without loading state → select custom category → expense created with correct category.

---

### PHASE 2 — expense_breakdown: categoriesMapProvider → categoriesRefProvider
**Goal**: Dashboard widget uses `CategoryRef` for names/emojis.
**Reversibility**: 100% — display only.

#### What changes

```dart
// ❌ BEFORE
final catsMap = ref.watch(categoriesMapProvider); // Map<String, Category>
// ...
final catModel = catsMap[catDbValue];
final label = catModel?.name ?? catDbValue;
final emoji = catModel?.emoji ?? '💰';

// ✅ AFTER
final catsRef = { for (final c in ref.watch(categoriesRefProvider)) c.slug: c };
// ...
final catRef = catsRef[catDbValue];
final label = catRef?.name ?? catDbValue;
final emoji = catRef?.emoji ?? '💰';
```

**Note**: `budgetGoalsMapProvider` continues to be used for category budget targets. Migrating it to `envelopesProvider` is out of scope (requires remapping `goal.targetAmount` → `envelope.effectiveAllocated`).

**Files modified**:
- `lib/features/dashboard/widgets/expense_breakdown.dart`

**Success test**: Dashboard shows custom categories with correct name and emoji in the category expense breakdown list.

---

### PHASE 3 — health_screen: migration to financialSnapshotProvider
**Goal**: Eliminate manual healthScore recalculation and legacy providers.
**Reversibility**: High — all data is in the snapshot.

#### Sub-score analysis

The screen shows 5 sub-scores with score bars. Not all come directly from the snapshot:

| Sub-score | Current source | New source |
|---|---|---|
| Overall score (0–10) | `FinancialCalculatorService.calculateHealthScore()` | `snapshot.healthScore` ✅ |
| Savings rate | `(net - cash) / net * 100` | `snapshot.savingsRate * 100` ✅ |
| Monthly balance | `cashRemainingProvider` | `snapshot.currentBalance.amount` ✅ |
| Installments / salary | `installmentsProvider` (CardInstallment) → `monthlyAmount` | `snapshot.totalFutureObligations.amount / snapshot.cashIncome.amount * 100` ✅ |
| Housing / salary | `byCategory['HOUSING'] / net` | `cashExpensesByCategoryProvider['housing']` (keep for now) ⚠️ |
| Emergency fund | `netWorthSnapshotProvider.emergencyFund / cash` | `netWorthSnapshotProvider` (keep) + `snapshot.totalSpent` ⚠️ |

The last two (housing and emergency fund) still require data not directly exposed in the snapshot. Strategy: keep only those two providers and remove the other three.

#### What changes

```dart
// ❌ BEFORE — 5 providers + manual calculation
final net = ref.watch(effectiveNetSalaryProvider);
final cash = ref.watch(cashExpensesProvider);
final byCategory = ref.watch(cashExpensesByCategoryProvider);
final balance = ref.watch(cashRemainingProvider);
final inst = ref.watch(installmentsProvider).value ?? [];
final instTotal = inst.fold(0.0, (s, i) => s + i.monthlyAmount);
final score = FinancialCalculatorService.calculateHealthScore(...);
final savingsRate = net > 0 ? (net - cash) / net * 100 : 0.0;
final installmentsRate = net > 0 ? instTotal / net * 100 : 0.0;

// ✅ AFTER — 3 providers, score and rates from snapshot
final snap = ref.watch(financialSnapshotProvider);           // new
final byCategory = ref.watch(cashExpensesByCategoryProvider); // kept (housing)
final nwSnap = ref.watch(netWorthSnapshotProvider).value;    // kept (ef)

final score = snap.healthScore;
final savingsRate = snap.savingsRate * 100;
final balance = snap.currentBalance.amount;
final net = snap.cashIncome.amount;
final installmentsRate = net > 0
    ? snap.totalFutureObligations.amount / net * 100
    : 0.0;
// housing and efMonths: keep current calculation with byCategory and nwSnap
```

**Providers removed from this screen**:
- `cashExpensesProvider`
- `cashRemainingProvider`
- `installmentsProvider` (CardInstallment — most important to remove)

**Files modified**:
- `lib/features/health/health_screen.dart`

**Success test**: Health screen shows the same score as `HealthGaugeCard` in the dashboard (both use `snapshot.healthScore`). Sub-scores match current period values.

---

### PHASE 4 — transactions_screen: retire deleteFixedSeriesFrom
**Goal**: Remove the `isFixed + deleteFixedSeriesFrom` pattern from the transactions UI.
**Reversibility**: Medium — requires production data verification before proceeding.
**Pre-condition**: Verify how many expenses still have `is_fixed=true` and `recurring_rule_id IS NULL` in production.

#### Data verification (run in Supabase SQL editor before implementing)

```sql
-- How many legacy isFixed expenses still exist without an associated RecurringRule?
SELECT COUNT(*) as legacy_fixed_count
FROM expenses
WHERE is_fixed = true
  AND recurring_rule_id IS NULL
  AND user_id = auth.uid();
```

#### Scenario A: `legacy_fixed_count = 0` (migration complete)

Remove the `isFixed` branch entirely:

```dart
// REMOVE this entire block:
if (isFixed) {
  final choice = await showDeleteExpenseChoiceDialog(...)
  ...
  await ref.read(expenseRepositoryProvider).deleteFixedSeriesFrom(expense);
}
```

And deprecate `deleteFixedSeriesFrom` in the repository (keep for 1 release, then remove).

#### Scenario B: `legacy_fixed_count > 0` (legacy expenses remain)

Replace the behavior: instead of "Delete entire series", show the user a warning to convert to RecurringRule:

```dart
// ✅ AFTER — Scenario B
if (isFixed && expense.recurringRuleId == null) {
  // Legacy expense — offer conversion
  await showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Legacy fixed expense'),
    content: const Text('This expense was created as fixed in the old format. '
        'To manage the complete series, convert it to Recurring.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('This month only')),
    ],
  ));
  return true; // deletes this one only
}
```

**Files modified**:
- `lib/features/transactions/transactions_screen.dart`
- `lib/core/repositories/expense_repository.dart` (deprecate `deleteFixedSeriesFrom`)

**Success test**: Swipe delete on `isFixed` expense without `recurringRuleId` → shows legacy warning. Normal expense → standard confirm dialog.

---

## ✅ Completion Checklist

### Phase 1 — Category Pickers ✅ 2026-05-08
- [x] `quick_add_bottom_sheet.dart`: `categoriesStreamProvider` → `categoriesRefProvider`
- [x] `quick_add_bottom_sheet.dart`: `_catChip` receives `CategoryRef`
- [x] `quick_add_bottom_sheet.dart`: `_save` uses `CategoryRef.uncategorized()` as fallback
- [x] `edit_expense_bottom_sheet.dart`: `categoriesStreamProvider` → `categoriesRefProvider`
- [x] `edit_expense_bottom_sheet.dart`: `_subcategories` keys converted to lowercase (bug fix: lookup never matched with UPPERCASE)
- [ ] Manual test: create expense with custom category → displays correctly

### Phase 2 — expense_breakdown ✅ 2026-05-08
- [x] `expense_breakdown.dart`: `categoriesMapProvider` → `categoriesRefProvider` (inline map)
- [ ] Verify in production: custom categories display correct name and emoji
- [ ] No regression: system categories (housing, transport...) still display

### Phase 3 — health_screen ✅ 2026-05-08
- [x] `health_screen.dart`: `financialSnap.healthScore` instead of `calculateHealthScore()`
- [x] `financialSnap.savingsRate * 100` and `financialSnap.currentBalance.amount` for sub-scores
- [x] `installmentsProvider` (legacy CardInstallment) removed from screen
- [x] `cashExpensesProvider` and `cashRemainingProvider` removed
- [x] `byCategory['HOUSING']` corrected to `byCategory['housing']`
- [ ] Verify in production: score identical to dashboard `HealthGaugeCard`

### Phase 4 — isFixed cleanup ✅ 2026-05-08 (Scenario B)
- [ ] SQL query in Supabase still pending (to decide if migrating to Scenario A)
- [x] `isFixed` branch: Scenario B applied — legacy warning dialog, single delete only
- [x] `deleteFixedSeriesFrom` marked as `@Deprecated` in repository
- [ ] Manual test: swipe on legacy isFixed expense → warning dialog shown

---

## 🚨 Risks

| Risk | Probability | Mitigation |
|---|---|---|
| `categoriesRefProvider` returns empty list momentarily | Low | Already has `CategoryRef.uncategorized()` fallback |
| `installmentsRate` via `totalFutureObligations` includes recurring (not just installments) | Medium | Document the difference; consider exposing `activeInstallmentsTotal` separately in snapshot |
| expenses with `is_fixed=true` in production without RecurringRule → silent delete | High if Scenario B | Verify SQL before implementing Phase 4 |

---

## 📎 References

- Audit: `docs/architecture/ui_audit_2026_05_08.md`
- Bug already fixed: `intelligence_layer.dart` (..take cascade)
- Target providers: `lib/core/providers/providers.dart` → `categoriesRefProvider`, `financialSnapshotProvider`
- Categories ADR: `docs/decisions/001-category-unification.md`
