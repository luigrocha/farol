# i18n Hardcoded String Cleanup — Migration Plan

**Created:** 2026-05-10
**Status:** 🔴 In Progress (audit complete, migration pending)
**Author:** CTO Assistant

---

## Executive Summary

A complete audit of the Farol codebase found **42 out of ~70 feature Dart files** with zero `l10n` usage, containing approximately **150+ hardcoded strings**. The existing i18n system (`AppLocalizations`) is solid — 371 keys per locale (EN/ES/PT) — but adoption is incomplete. Additionally, three **critical bugs** were found: `health_screen.dart`, `notifications_screen.dart`, and `investments_screen.dart` display Spanish labels instead of the expected language.

This document defines the migration strategy, priorities, and per-feature checklist. No code changes happen without this plan in place and explicit phase confirmation.

---

## Current i18n System — Quick Reference

**File:** `lib/core/i18n/app_localizations.dart` (1613 lines)

```dart
// Access in widget tree:
context.l10n.someKey

// Access outside widget tree (enums, services):
AppLocalizations.translateStatic(languageCode, 'key')

// Interpolation:
l10n.allocatedOverLimit('85%')  // uses .replaceFirst('%s', value)

// Extension:
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

**Locales supported:** `en`, `es`, `pt` (pt_BR)
**Keys per locale:** 371 (must stay in parity across all three)

---

## Overall Status

| Metric | Count |
|---|---|
| Feature files with hardcoded strings | ~42 |
| Estimated hardcoded Text() widgets | ~150+ |
| Critical bugs (wrong language) | 3 files |
| Enums with hardcoded labels | 2 (`RecurringFrequency`, `AccountType`) |
| Domain services with hardcoded strings | 1 (`IntelligenceLayer` — 12 rules) |
| Files already using l10n correctly | ~28 |

---

## Financial Localization Rules (NON-NEGOTIABLE)

These terms must NOT be translated literally. They are either proper nouns, Brazilian legal terms, or domain-specific identifiers:

| Term | Rule |
|---|---|
| `FGTS` | Keep as-is. Brazilian severance fund acronym. |
| `INSS` | Keep as-is. Social security acronym. |
| `IRRF` | Keep as-is. Withholding income tax acronym. |
| `parcelas` | Translate as "installments" in EN, "cuotas" in ES — never "parcels". |
| `cutoffDay` | Display as "closing day" (EN), "dia de fechamento" (PT) — not "cutoff". |
| `Swile` | Brand name, never translate. |
| `13º salário` | Display as "13th salary" in EN, "aguinaldo" in ES. |
| `CLT` | Keep as-is in context (Brazilian employment law). |
| `poupança` | "savings" in EN, "ahorros" in ES. |

---

## Architecture Decision: IntelligenceLayer Domain Strings

### Problem

`lib/core/domain/services/intelligence_layer.dart` generates `FinancialInsight` objects with `title`, `body`, and `actionLabel` hardcoded in Portuguese. This is a domain service — it has no access to `BuildContext`, and passing locale to pure domain logic violates clean architecture.

### Decision: Use Translation Keys, Not Strings

The `FinancialInsight` entity will carry **translation keys** instead of display strings. The UI layer (`InsightsPanel`, `InsightCard`, `InsightsScreen`) resolves them using `l10n`.

```dart
// BEFORE (domain, PT-BR hardcoded):
FinancialInsight(
  title: 'Risco de saldo negativo',
  body: 'Com o ritmo atual, você fechará...',
  actionLabel: 'Ver projeção',
)

// AFTER (domain, keys only):
FinancialInsight(
  titleKey: 'insight_negative_balance_title',
  bodyKey: 'insight_negative_balance_body',
  bodyArgs: {'projected': projected.formatted},  // interpolation args
  actionKey: 'insight_see_projection',
)

// UI layer resolves:
Text(l10n.translateWithArgs(insight.titleKey, insight.bodyArgs))
```

This approach:
- Keeps domain pure (no locale dependency)
- Lets the UI layer control rendering language
- Allows all 12 insight rules to be localized without changing domain logic
- Requires adding ~36 new keys per locale (12 rules × 3 string types)

### Consequence

`FinancialInsight` entity fields change from `String title/body/actionLabel` to `String titleKey/bodyKey/actionKey` + `Map<String, String>? bodyArgs`. This is a **breaking change** to the entity — all consumers must be updated. Fortunately consumers are only: `InsightsPanel`, `InsightCard`, `InsightsScreen`, `DismissedInsightsRepository` (stores `type` not strings), and `insightStatsProvider` (stores counts). The migration is contained.

**This is Phase 9 — do not implement until Phases 1–8 are complete.**

---

## Migration Phases — Master Checklist

### ✅ Phase 0 — Audit (COMPLETE)

- [x] Read `app_localizations.dart` — understand key structure, interpolation pattern
- [x] Scan all feature files for missing l10n usage
- [x] Identify critical bugs (Spanish labels)
- [x] Identify enum hardcoding issues
- [x] Identify domain-level issue (`IntelligenceLayer`)
- [x] Write this migration plan

---

### 🔴 Phase 1 — Critical Bug Fixes (Spanish Labels)

**Files:** `health_screen.dart`, `notifications_screen.dart`, `investments_screen.dart`, `transactions_screen.dart`

These files display Spanish text regardless of the user's locale setting. This is a regression — fix immediately.

**`health_screen.dart`** — Replace Spanish labels:
- [ ] `'Desglose'` → `l10n.breakdown` (add key if missing: `'breakdown'`)
- [ ] `'Tasa de ahorro'` → `l10n.savingsRate`
- [ ] `'Vivienda / salario'` → `l10n.housingVsSalary`
- [ ] `'Balance mensual'` → `l10n.monthlyBalance`
- [ ] `'Fondo de emergencia'` → `l10n.emergencyFund`
- [ ] `'Parcelas / salario'` → `l10n.installmentsVsSalary`
- [ ] `'Historial'` → `l10n.history`
- [ ] `'Sin historial aún'` → `l10n.noHistoryYet`
- [ ] `'Error: $e'` → `l10n.errorGeneric(e.toString())`

**`notifications_screen.dart`** — Replace Spanish strings:
- [ ] `'Ninguna categoría supera el 75% del presupuesto'` → `l10n.noCategoryOverBudget`

**`investments_screen.dart`** — Replace Spanish strings:
- [ ] `'vs. último mes'` → `l10n.vsLastMonth`
- [ ] `'Distribución estratégica...'` → `l10n.strategicDistribution`
- [ ] `'Su cartera tiene baja exposición...'` → `l10n.lowExposureWarning`

**`transactions_screen.dart`** — Fix mixed ES+PT:
- [ ] `'Valor líquido (ya descontado INSS/IRRF)'` → `l10n.netValueDescription` (keep "INSS/IRRF" as-is in the string)
- [ ] `'Nenhum ingresso neste mês'` → `l10n.noIncomeThisMonth`

**New keys to add (per locale):** ~15 keys

---

### 🟡 Phase 2 — Dashboard Widgets

**Files:** `burn_rate_card.dart`, `liquidity_alert_card.dart`, `period_balance_hero.dart`, `recurring_card.dart`

**`burn_rate_card.dart`:**
- [ ] `'Velocidade de gasto'` → `l10n.spendingVelocity`
- [ ] `'Ritmo vs orçamento'` → `l10n.paceVsBudget`
- [ ] `'Projeção ao fechamento'` → `l10n.projectionAtClose`
- [ ] `'Queima diária'` → `l10n.dailyBurn`
- [ ] `'Sem dados suficientes'` → `l10n.insufficientData`

**`liquidity_alert_card.dart`:**
- [ ] `'Compromissos desta semana'` → `l10n.commitmentsThisWeek`
- [ ] `'Nenhum compromisso nos próximos 7 dias.'` → `l10n.noCommitmentsNext7Days`

**`period_balance_hero.dart`:**
- [ ] `label: 'Receitas'` → `label: l10n.incomes`
- [ ] `label: 'Despesas'` → `label: l10n.expenses`

**`recurring_card.dart`:**
- [ ] `'Recorrentes'` → `l10n.recurring`
- [ ] `'Pendentes'` → `l10n.pending`
- [ ] `'Total previsto'` → `l10n.totalExpected`
- [ ] `'Regras ativas'` → `l10n.activeRules`

**New keys to add (per locale):** ~15 keys

---

### 🟡 Phase 3 — Recurring Feature

**Files:** `recurring_screen.dart`, `add_recurring_bottom_sheet.dart`, `recurring_suggestions_screen.dart`

**`recurring_screen.dart`:**
- [ ] `'Recorrentes'` (AppBar title) → `l10n.recurring`
- [ ] `'Próximas ocorrências'` → `l10n.upcomingOccurrences`
- [ ] `'Cancelar recorrente?'` (dialog title) → `l10n.cancelRecurringTitle`
- [ ] Dialog body text → add key `recurring_cancel_body`
- [ ] `'Cancelar recorrente'` (button) → `l10n.cancelRecurring`

**`add_recurring_bottom_sheet.dart`:**
- [ ] `'Próximas ocorrências'` → `l10n.upcomingOccurrences`
- [ ] `'Prévia'` → `l10n.preview`
- [ ] Form field labels: `'Descrição *'`, `'Valor *'`, `'Categoria'`, `'Dia do mês'` → l10n

**`recurring_suggestions_screen.dart`:**
- [ ] `'Sugestões de recorrentes'` → `l10n.recurringSuggestions`
- [ ] `'$pct% confiança'` → `l10n.confidencePct(pct)` (interpolated)
- [ ] `'Aceitar'`, `'Ignorar'` → `l10n.accept`, `l10n.ignore`

**New keys to add (per locale):** ~12 keys

---

### 🟡 Phase 4 — Installments Feature

**Files:** `installments_screen.dart`, `add_installment_bottom_sheet.dart`

**`installments_screen.dart`:**
- [ ] `'Parcelas'` (AppBar) → `l10n.installments`
- [ ] `'Concluídos'` (chip label) → `l10n.completed`
- [ ] `'${pct}% concluído'` → `l10n.pctComplete(pct)` (interpolated)
- [ ] `'Nenhuma parcela'` → `l10n.noInstallments`
- [ ] Status chips for active/completed states

**`add_installment_bottom_sheet.dart`:**
- [ ] `'Descrição *'` → `l10n.descriptionRequired`
- [ ] `'Prévia'` → `l10n.preview`
- [ ] All form field labels

**New keys to add (per locale):** ~10 keys

---

### 🟡 Phase 5 — Analytics + Cashflow Chart

**Files:** `analytics_screen.dart`, `cashflow_chart.dart`

**`analytics_screen.dart`:**
- [ ] `'Tendência Mensal'` → `l10n.monthlyTrend`
- [ ] `'Receita'` → `l10n.income` (or `l10n.incomes` — check existing key)
- [ ] `'Distribuição por Categoria'` → `l10n.categoryDistribution`
- [ ] `'Comparativo Mensal'` → `l10n.monthlyComparison`
- [ ] `'MÉDIA/MÊS'` → `l10n.avgPerMonth`

**`cashflow_chart.dart`:**
- [ ] `label: 'Projeção'` → `label: l10n.projection`
- [ ] `'Saldo mínimo projetado'` → `l10n.projectedMinBalance`
- [ ] `'Saldo ao fechamento'` → `l10n.balanceAtClose`

**New keys to add (per locale):** ~8 keys

---

### 🟡 Phase 6 — Accounts Screen

**Files:** `accounts_screen.dart`

- [ ] `'Contas'` (AppBar) → `l10n.accounts`
- [ ] `'Transferência entre contas'` → `l10n.transferBetweenAccounts`
- [ ] `'Adicione suas contas...'` (empty state) → `l10n.addYourAccounts`
- [ ] `'Transferência registrada'` (snackbar) → `l10n.transferRecorded`
- [ ] `'Conta adicionada'` (snackbar) → `l10n.accountAdded`

**New keys to add (per locale):** ~5 keys

---

### 🟡 Phase 7 — Insights Feature

**Files:** `insights_panel.dart`, `insights_screen.dart`

- [ ] `Text('Insights',` → `Text(l10n.insights,` (check if key exists)
- [ ] `Text('Erro: $e')` → `Text(l10n.errorGeneric(e.toString()))`
- [ ] `'Mais ignorados'` section title → `l10n.mostIgnored`

**New keys to add (per locale):** ~3 keys

---

### ✅ Phase 8 — Enum Localization (Complete 2026-05-10, 10 keys)

**File:** `lib/core/models/enums.dart`, `lib/core/domain/entities/recurring_rule.dart`

**`RecurringFrequency.label` (recurring_rule.dart):**

Currently returns hardcoded PT-BR. Migrate to use `translateStatic` — same pattern as `IncomeType.labelForLocale()`:

```dart
// BEFORE:
String get label => switch (this) {
  weekly => 'Semanal',
  biweekly => 'Quinzenal',
  ...
};

// AFTER:
String labelForLocale(String languageCode) => switch (this) {
  RecurringFrequency.weekly => AppLocalizations.translateStatic(languageCode, 'freq_weekly'),
  RecurringFrequency.biweekly => AppLocalizations.translateStatic(languageCode, 'freq_biweekly'),
  RecurringFrequency.monthly => AppLocalizations.translateStatic(languageCode, 'freq_monthly'),
  RecurringFrequency.quarterly => AppLocalizations.translateStatic(languageCode, 'freq_quarterly'),
  RecurringFrequency.semiannual => AppLocalizations.translateStatic(languageCode, 'freq_semiannual'),
  RecurringFrequency.yearly => AppLocalizations.translateStatic(languageCode, 'freq_yearly'),
};
```

- [ ] Add `labelForLocale(String languageCode)` method to `RecurringFrequency`
- [ ] Add 6 frequency keys per locale (`freq_weekly`, `freq_biweekly`, etc.)
- [ ] Update all callsites from `.label` → `.labelForLocale(locale.languageCode)`

**`AccountType.label` (enums.dart):**

```dart
// BEFORE:
enum AccountType {
  checking('CHECKING', 'Conta Corrente', '🏦'),
  savings('SAVINGS', 'Poupança', '🐷'),
  investment('INVESTMENT', 'Conta Investimento', '📈'),
  fgts('FGTS', 'FGTS', '🏛️');
  final String label;  // hardcoded PT-BR
}

// AFTER: Add labelForLocale(), keep `label` as a PT-BR fallback for existing callsites
String labelForLocale(String languageCode) => switch (this) {
  AccountType.checking => AppLocalizations.translateStatic(languageCode, 'account_checking'),
  AccountType.savings => AppLocalizations.translateStatic(languageCode, 'account_savings'),
  AccountType.investment => AppLocalizations.translateStatic(languageCode, 'account_investment'),
  AccountType.fgts => 'FGTS',  // proper noun, never translate
};
```

- [ ] Add `labelForLocale(String languageCode)` method to `AccountType`
- [ ] Add 3 account type keys per locale (FGTS stays as-is)
- [ ] Update callsites progressively

**New keys to add (per locale):** ~9 keys

---

### ✅ Phase 9 — IntelligenceLayer Domain Strings (Complete 2026-05-10, ~30 keys)

**Files:** `intelligence_layer.dart`, `financial_insight.dart` (entity), `insight_card.dart`, `insights_panel.dart`, `insights_screen.dart`

This is the most complex migration. See "Architecture Decision" section above.

Steps:
- [ ] Update `FinancialInsight` entity: `title`, `body`, `actionLabel` → `titleKey`, `bodyKey`, `actionKey`, `bodyArgs`
- [ ] Add `translateWithArgs(String key, Map<String, String>? args)` to `AppLocalizations`
- [ ] Add 36 new keys per locale (12 rules × 3 strings: title, body, action)
- [ ] Update `IntelligenceLayer` — all 12 rules emit keys instead of strings
- [ ] Update `InsightCard` — resolve keys via `l10n`
- [ ] Update `InsightsPanel` — resolve keys via `l10n`
- [ ] Update `InsightsScreen` — resolve keys via `l10n`
- [ ] Verify `DismissedInsightsRepository` still stores `type` (not strings) — no change needed
- [ ] Run all 22 `intelligence_layer_test.dart` tests — update assertions to check keys

**New keys to add (per locale):** ~36 keys

---

### ⚪ Phase 10 — Simulators (Low Priority)

**Files:** `simulators/thirteenth_salary_screen.dart`, `simulators/fgts_screen.dart`, `simulators/rescission_screen.dart`

These are Brazil-specific calculators. The content is inherently pt_BR (legal terms, Brazilian formulas). Low priority — internationalize only if the app expands to other markets.

- [ ] Audit actual string usage — separate what's translatable vs. what's a legal/cultural term
- [ ] Add l10n for generic UI elements (labels, buttons)
- [ ] Leave BR-specific legal terms as-is or with a `// i18n: Brazil-specific` comment

---

## Key Addition Strategy

When adding new keys, always add to **all three locales simultaneously** to maintain parity. Existing system asserts on missing keys:

```dart
assert(value != null, '[l10n] Missing key "$key" in all locales');
```

Template for new key blocks in `app_localizations.dart`:

```dart
// --- [Feature Name] ---
'key_name': 'English text',           // in 'en' block
'key_name': 'Texto español',          // in 'es' block  
'key_name': 'Texto português',        // in 'pt' block
```

---

## Execution Rules

```
✅ ALWAYS:
  - Add keys to all 3 locales before using them in code
  - Check existing keys before adding new ones (371 already exist)
  - Test with locale switcher after each phase
  - Keep financial terms as per the Financial Localization Rules table
  - One phase at a time — wait for confirmation before proceeding

❌ NEVER:
  - Add a key to only one locale
  - Translate FGTS, INSS, IRRF, Swile, CLT
  - Mix display strings into domain/service layer
  - Rename existing keys (breaks existing usage)
  - Do Phase 9 before Phases 1–8 are complete
```

---

## Progress Tracker

| Phase | Scope | Files | Keys to Add | Status |
|---|---|---|---|---|
| 0 | Audit | — | — | ✅ Complete |
| 1 | Critical bug fixes (Spanish) | 4 | ~15 | ✅ Complete (2026-05-10) |
| 2 | Dashboard widgets | 4 | ~15 | ✅ Complete (2026-05-10) |
| 3 | Recurring feature | 3 | ~12 | ✅ Complete (2026-05-10) |
| 4 | Installments feature | 2 | 43 | ✅ Complete (2026-05-10) |
| 5 | Analytics + Cashflow | 2 | 13 | ✅ Complete (2026-05-10) |
| 6 | Accounts screen | 1 | 23 | ✅ Complete (2026-05-10) |
| 7 | Insights feature UI | 2 | 9 | ✅ Complete (2026-05-10) |
| 8 | Enum localization | 2 | 10 | ✅ Complete (2026-05-10) |
| 9 | IntelligenceLayer domain | 3 | ~30 | ✅ Complete (2026-05-10) |
| 10 | Simulators | 3 | ~TBD | ⚪ Low priority |
| **Total** | | **~28 files** | **~113+ keys** | |

---

## References

- i18n system: `lib/core/i18n/app_localizations.dart`
- Enum patterns (good reference): `IncomeType.labelForLocale()`, `PaymentMethod.localizedLabel()`
- Domain entity to update: `lib/core/domain/entities/financial_insight.dart`
- Intelligence rules: `lib/core/domain/services/intelligence_layer.dart`
- Tests: `test/unit/intelligence_layer_test.dart` (22 tests — must pass after Phase 9)
