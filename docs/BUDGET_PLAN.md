# Budget Goals – Improvement Plan

## Context

The `budget_goals` table stores categories as raw English strings (e.g., `HOUSING`, `FOOD_GROCERY`) and `target_percentage` values per user. Two critical issues must be resolved:

1. **Category display names** are not localized — they show in English regardless of app language.
2. **Percentage validation** is missing — a user's total `target_percentage` can silently exceed 100%.

Additionally, the plan introduces **AI-generated budget recommendations** and proper **Swile budget separation** so food/meal categories backed by Swile vouchers don't compete with the cash budget pool.

---

## Phase 1 — Category Localization Layer

**Goal:** Display category names in the user's selected language without changing DB values. The DB keeps the canonical English key (e.g., `HOUSING`); the UI maps it to a localized string at render time.

**Scope:**
- Add i18n keys for all `ExpenseCategory` enum values (or string constants).
- Create a `categoryLabel(BuildContext)` extension on `ExpenseCategory` (or a top-level helper).
- Replace every hardcoded category-to-string mapping in the UI with the localized version.
- Cover: period budget screen, budget goals list, budget edit sheet, analytics breakdown, transaction list category chips.

**Categories to localize (current known set):**
`HOUSING`, `TRANSPORT`, `FOOD_GROCERY`, `SUBSCRIPTIONS`, `HEALTH`, `LEISURE`, `EDUCATION`, `CARD_INSTALLMENTS`, `CLOTHING`, `PERSONAL_CARE`, `OTHER`

---

### Phase 1 Prompt

```
In the Farol Flutter app (lib/), budget categories are stored in the DB as English string keys
(HOUSING, TRANSPORT, FOOD_GROCERY, SUBSCRIPTIONS, HEALTH, LEISURE, EDUCATION,
CARD_INSTALLMENTS, CLOTHING, PERSONAL_CARE, OTHER) and must be displayed in the user's
language (EN/ES/PT).

Task:
1. Add i18n keys for each category to lib/core/i18n/app_localizations.dart (three locales: en, es, pt).
   Key format: `category_housing`, `category_transport`, etc.
   Use natural names per locale:
   - EN: Housing, Transport, Food/Grocery, Subscriptions, Health, Leisure, Education,
         Card Installments, Clothing, Personal Care, Other
   - ES: Vivienda, Transporte, Alimentación, Suscripciones, Salud, Ocio, Educación,
         Cuotas de tarjeta, Ropa, Cuidado personal, Otros
   - PT: Moradia, Transporte, Alimentação, Assinaturas, Saúde, Lazer, Educação,
         Parcelas de cartão, Roupas, Cuidados pessoais, Outros

2. Add typed getters to AppLocalizations for each key.

3. Create a utility function or extension in lib/core/models/ that maps a category string
   (or ExpenseCategory enum value) to the localized display name using context.l10n.

4. Find every place in the UI that converts a category to a display string (search for
   category.name, category.toString(), switch on category, hardcoded Maps<String,String>)
   and replace with the new localized helper.

Do not change DB values or the enum names — only the display layer.
Run flutter analyze after and fix any warnings.
```

---

## Phase 2 — Percentage Validation & Real-time Feedback

**Goal:** Prevent the sum of all `target_percentage` values from exceeding 100% of the **cash budget** (Swile categories are excluded from this pool — see Phase 3). Show live feedback while editing and block saving when over limit.

**Scope:**
- New Riverpod provider: `budgetPercentageTotalProvider` — sums non-Swile `target_percentage`.
- Budget goal edit sheet: show remaining % available; disable save when total would exceed 100%.
- Budget goals list screen: show a warning banner when current total > 100%.
- Provide a "how to fix" message pointing to each over-budget category.

---

### Phase 2 Prompt

```
In the Farol Flutter app, the budget_goals table has a `target_percentage` column.
The sum of all rows for a user must not exceed 100% (excluding Swile categories:
FOOD_GROCERY and any other category flagged as Swile-backed — see Phase 3 context).

Task:
1. In lib/core/providers/providers.dart, add:
   - `budgetCashPercentageTotalProvider`: sums target_percentage for all non-Swile budget goals.
   - `budgetPercentageRemainingProvider`: 100 - total (clamped to 0).
   - `budgetPercentageOverflowProvider`: bool, true when total > 100.

2. In the budget goal add/edit sheet (find in lib/features/budget/ or lib/features/period_budget/):
   - Show a live indicator: "X% used · Y% remaining" that updates as the user types.
   - If saving would push the total over 100%, disable the save button and show an inline
     error: "Adjusting this would exceed your 100% budget limit. Free up X% first."

3. In the budget goals list screen:
   - When `budgetPercentageOverflowProvider` is true, show a warning banner at the top:
     "Your budget allocations exceed 100%. Tap a category to adjust."
   - Highlight over-contributing rows (e.g., light red background).

4. Add a provider `overBudgetCategoriesProvider` that returns the list of category names
   contributing to the overflow, sorted by target_percentage descending.

Use existing FarolColors tokens for warning/error colors. Run flutter analyze after.
```

---

## Phase 3 — Swile Budget Separation

**Goal:** Swile vouchers (meal + food) cover `FOOD_GROCERY` (and optionally `LEISURE` for Swile Flex). These should have their own budget tracked against the Swile balance — not the cash percentage pool. The 100% cash pool must exclude them.

**Scope:**
- Define which categories are "Swile-backed" (at minimum: `FOOD_GROCERY`).
- Exclude those from `budgetCashPercentageTotalProvider` (Phase 2).
- In the budget goals list UI, visually separate Swile categories in their own section.
- Show Swile remaining balance alongside the Swile budget section.
- Swile categories get a `target_amount` (absolute BRL) instead of `target_percentage`.

---

### Phase 3 Prompt

```
In the Farol Flutter app, Swile vouchers (refeição + alimentação) fund the FOOD_GROCERY
category — it must not consume the user's cash budget percentage.

Task:
1. In lib/core/models/ (or wherever ExpenseCategory / constants live), define a const Set
   called `swileCategories` containing the category keys backed by Swile (at minimum:
   {'FOOD_GROCERY'}). This is the single source of truth.

2. Update `budgetCashPercentageTotalProvider` (Phase 2) to skip categories in `swileCategories`.

3. In the budget goals list screen, split the list into two sections:
   - "Cash Budget" section: non-Swile categories, shows percentage used out of 100%.
   - "Swile Budget" section: Swile categories, shows amount used vs. Swile balance
     (pull balance from the existing Swile provider).

4. In the budget goal edit sheet, when editing a Swile category:
   - Hide the `target_percentage` field.
   - Show only `target_amount` as an absolute BRL value.
   - Show the current Swile balance as a hint below the field.

5. Update the period budget screen to reflect the same separation — Swile categories
   should show "of Swile balance" instead of "of cash budget".

Do not change the DB schema — use the existing target_amount column for Swile goals.
Run flutter analyze after.
```

---

## Phase 4 — Budget Rebalancing UI

**Goal:** When the cash budget total exceeds 100% (or the user wants to start fresh), provide an in-app tool to rebalance: either a one-tap "normalize" that scales all percentages proportionally, or a guided adjustment flow that highlights the largest contributors.

**Scope:**
- "Rebalance" action button appears on the budget goals list when overflow is detected.
- Normalization algorithm: scale each non-Swile `target_percentage` by `100 / currentTotal`.
- Guided flow: list categories sorted by %, allow inline tap-to-edit with live total.
- Preview screen before saving showing old vs. new % per category.
- Persist changes in bulk via a new repository method.

---

### Phase 4 Prompt

```
In the Farol Flutter app, when the user's cash budget percentages exceed 100%
(detected via `budgetPercentageOverflowProvider` from Phase 2), add a rebalancing tool.

Task:
1. Add a repository method `BudgetGoalsRepository.updateAllPercentages(Map<String, double>)`
   that updates target_percentage for multiple categories in a single transaction.
   Also update target_amount proportionally: newAmount = (newPct / 100) * userNetSalary
   (pull net salary from the existing income provider).

2. Add a `RebalanceBudgetSheet` bottom sheet widget in lib/features/budget/:
   - Shows all non-Swile budget goals with current % in an editable list.
   - Live running total at the top: "Total: X% / 100%". Color: green ≤100%, red >100%.
   - Each row has a - / + control (step: 0.5%) and direct text input.
   - "Normalize automatically" button: scales all percentages proportionally so they sum to 100%.
   - "Save" button: disabled while total ≠ 100% (allow ±0.5% rounding tolerance).
   - Preview before save: show a side-by-side old → new for each changed category.

3. On the budget goals list screen, when overflow is detected, show a "Rebalance" CTA
   button inside the warning banner (Phase 2) that opens `RebalanceBudgetSheet`.

4. After saving, invalidate the relevant providers so the UI refreshes immediately.

Use existing FarolButton / FarolCard design system components. Run flutter analyze after.
```

---

## Phase 5 — AI-Powered Budget Recommendations

**Goal:** Generate personalized budget percentage recommendations using Claude AI, based on the user's net salary, expense history, financial health score, and Brazilian-adapted 50/30/20 guidelines. Swile vouchers must offset food budget needs.

**Scope:**
- New service `BudgetRecommendationService` that calls the Claude API.
- Builds a context payload: net salary, last 3 months of expenses by category, current budget goals, Swile balance, health score.
- Returns a `Map<String, double>` of recommended percentages with reasoning per category.
- UI: dismissible recommendation card on the budget goals screen; shows diff vs. current allocation.
- "Apply recommendations" routes to the rebalance sheet (Phase 4) pre-populated with AI values.

**Business rules for the AI prompt:**
- Brazilian CLT baseline: housing ≤ 30–35%, transport ≤ 10%, food ≤ 15% (offset by Swile).
- CARD_INSTALLMENTS should not exceed 30% of net.
- Emergency fund target: 3× monthly expenses (hint from health score).
- Swile covers food so food % can be lower or zero if Swile balance is sufficient.

---

### Phase 5 Prompt

```
In the Farol Flutter app, add an AI-powered budget recommendation feature using the Claude API.

Task:
1. Create lib/core/services/budget_recommendation_service.dart:
   - Method: `Future<BudgetRecommendation> generateRecommendations(BudgetContext ctx)`
   - `BudgetContext` holds: netSalary (double), expensesByCategory (Map<String,double> — last 3-month avg),
     currentGoals (Map<String,double> — category→percentage), swileBalance (double), healthScore (double).
   - Call the Claude API (claude-sonnet-4-6) using the Anthropic SDK (or http package if SDK not present).
     Read the API key from dart-define env (add CLAUDE_API_KEY to env.json and CLAUDE.md).
   - System prompt: "You are a personal finance advisor for Brazilian CLT workers. Recommend
     monthly budget percentages that sum to exactly 100% for the cash budget. Exclude food/grocery
     if Swile balance covers it. Follow 50/30/20 adapted for Brazil: needs ≤50%, wants ≤30%,
     savings ≥20%. Return JSON only: {recommendations: [{category, percentage, reasoning}], summary: string}."
   - User message: include all BudgetContext values as structured text.
   - Parse the JSON response into a `BudgetRecommendation` model.

2. Create a `budgetRecommendationProvider` (FutureProvider.autoDispose) that builds BudgetContext
   from existing providers and calls the service.

3. In the budget goals list screen, add a "Get AI recommendation" button (only if
   `budgetPercentageOverflowProvider` is true OR no goals exist yet).
   - Shows a loading state while the AI call is in flight.
   - On success: display a dismissible `RecommendationCard` widget showing the AI summary
     and a diff table (current % → recommended %) per category.
   - "Apply" button on the card pre-populates the RebalanceBudgetSheet (Phase 4) with AI values.
   - "Dismiss" stores the dismissal in user_settings so it doesn't re-appear for 7 days.

4. Add CLAUDE_API_KEY to env.json (gitignored), env.json.example (with placeholder), and CLAUDE.md
   under "Key Dev Notes".

Handle API errors gracefully: show a snackbar "Could not generate recommendations. Try again later."
Run flutter analyze after.
```

---

## Execution Order

| Phase | Depends on | Estimated complexity |
|-------|-----------|----------------------|
| 1 – Category Localization | — | Low |
| 2 – Percentage Validation | Phase 1 (categories) | Medium |
| 3 – Swile Separation | Phase 2 (validation) | Medium |
| 4 – Rebalancing UI | Phases 2 + 3 | Medium-High |
| 5 – AI Recommendations | Phases 3 + 4 | High |

Run each prompt in order. After each phase, run `flutter analyze` and verify no regressions in the
budget, period_budget, and analytics screens before proceeding to the next.
