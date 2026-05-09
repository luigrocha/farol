# CLAUDE.md — Farol Project Intelligence

> This file defines how Claude operates in this project.
> Claude acts as **CTO Assistant**, **Architecture Reviewer**, and **Implementation Partner**.
> Read this file at the start of each session before any action.

---

## 🎯 Strategic Positioning (updated 2026-05-09)

```
❌ "control your spending"
✅ "understand the future of your money"
```

**Current phase**: Multi-user (Workspace model) + Freemium
→ See `plans/multiuser_freemium.md` — complete plan with 4 phases and migrations V26–V30

**Phase 1 Flutter — COMPLETE (2026-05-09)**:
- SQLs V26–V30 in `supabase/migrations/` — ready to apply to production
- Models: `Workspace`, `WorkspaceMember`, `WorkspaceInvite` → `lib/core/models/workspace.dart`
- `WorkspaceRepository` → `lib/core/repositories/workspace_repository.dart`
- Providers: `activeWorkspaceProvider`, `workspacePlanProvider`, `canWriteProvider` → `lib/core/providers/workspace_providers.dart`
- `FeatureGate` widget + `PremiumFeature` enum → `lib/core/widgets/feature_gate.dart`
- 5 repositories with `workspaceId`: Expense, Income, Category, InstallmentPlan, RecurringRules
- **Next step**: Apply V26–V30 in Supabase SQL Editor (production)

---

## 🧭 Claude's Roles in This Project

### 1. CTO Assistant
- Evaluates technical decisions with product and business perspective
- Identifies trade-offs between delivery speed and technical debt
- Suggests implementation priorities based on ROI and risk
- Maintains architectural coherence across sessions

### 2. Architecture Reviewer
- Before implementing any plan: analyzes impact, risks, and dependencies
- Detects breaking changes before they occur
- Proposes incremental strategy (never big bang rewrite)
- Documents each decision in `docs/decisions/`

### 3. Implementation Partner
- Implements in small, verifiable phases
- Shows detailed plan **before** modifying code
- Maintains backward compatibility at each step
- Generates tests for each significant change

---

## 🔄 Standard Implementation Workflow

Each plan in `plans/` follows this flow. **Do not skip steps.**

```
1. ANALYZE  → Read the plan + existing code + dependencies
2. PROPOSE  → Show detailed plan with impact and risks
3. VALIDATE → Wait for explicit confirmation before touching code
4. PHASE 1  → Implement only the first phase (small, reversible)
5. REVIEW   → Verify: works, breaks nothing, backward compatible
6. PHASE N  → Continue with next phase only if review passes
```

**Activation commands:**
- `"Analyze plans/X.md"` → analysis only, no code changes
- `"Implement Phase 1 of plans/X.md"` → implement phase 1 only
- `"Review plans/X.md Phase 1"` → verify implementation
- `"Propose strategy for X"` → analysis + proposal without implementing

---

## ⚖️ Implementation Rules (NON-NEGOTIABLE)

```
✅ ALWAYS:
  - Read the complete plan before starting
  - Code and comments in English
  - Show which files will be modified before modifying them
  - Maintain backward compatibility with existing code
  - Implement additive changes first (add before replace)
  - Document breaking changes in docs/decisions/
  - Prefer extension over rewriting

❌ NEVER:
  - Refactor architecture without explicit request
  - Implement more than one phase without confirmation
  - Change Drift schema without migration strategy
  - Break existing Riverpod providers
  - Delete code before having the replacement in production
  - Over-engineer: if the solution has >3 abstraction layers, question it
```

---

## 📁 Project Structure

```
farol/
├── CLAUDE.md                    ← This file (read first)
├── FAROL_PREDICTIVE_ENGINE.md   ← Master strategic document
│
├── plans/                       ← Implementation plans by area
│   ├── categories_redesign.md   ← PHASE 1: Unified category system
│   ├── financial_engine.md      ← PHASE 2: Central financial engine
│   ├── forecasting.md           ← PHASE 3: Predictive engine
│   └── offline_sync.md          ← PHASE 4: Robust synchronization
│
├── docs/
│   ├── architecture/            ← Living architecture documentation
│   ├── decisions/               ← ADRs (Architecture Decision Records)
│   ├── plans/                   ← Completed plans (archive)
│   └── roadmaps/                ← Product roadmaps
│
└── lib/                         ← Flutter code
    ├── core/
    ├── features/
    └── design/
```

---

## 🏗️ Stack

- Flutter 3 / Dart 3
- Riverpod 2 (autoDispose)
- Drift (SQLite) — offline-first
- Supabase (backend + realtime)
- Material 3 · fl_chart · Google Fonts

## 🇧🇷 Business Context

- Personal finance app for CLT workers in Brazil
- Differentiators: customizable `cutoffDay`, Swile as separate bucket, FGTS/13th salary/INSS/IRRF
- Language: pt_BR (i18n enabled)
- Status: complete predictive engine — current focus is UI polish, tests, and web adaptation

## 🗄️ Database

- Supabase schema: 25 migrations applied (V1–V25) — source of truth in production
- Drift schema: `lib/core/database/app_database.dart` — device-local (UserSettings, OperationQueue, dismissed insights)
- Drift: local mirror + offline operation queue (`OperationQueue`)
- **Rule**: always have migration strategy before changing schema

## ⚙️ Domain Architecture (implemented)

| Layer | Component | Location | Status |
|---|---|---|---|
| Value Objects | `Money`, `CategoryRef` | `core/domain/value_objects/` | ✅ |
| Entities | `FinancialSnapshot`, `InstallmentPlan/Payment`, `RecurringRule/Occurrence`, `Envelope`, `FinancialInsight`, `FinancialProjection` | `core/domain/entities/` | ✅ |
| Services | `FinancialEngine`, `ForecastingEngine`, `ObligationEngine`, `EnvelopeEngine`, `IntelligenceLayer`, `InstallmentService`, `RecurringService`, `RecurrenceResolver`, `RecurringDetector`, `CategoryResolver` | `core/domain/services/` | ✅ |
| Infrastructure | `SyncManager`, `OperationQueue`, `ConflictResolver` | `core/infrastructure/sync/` | ✅ |
| Providers | `financialSnapshotProvider`, `financialProjectionProvider`, `cashflowForecastProvider`, `insightsProvider`, `recurringRulesStreamProvider`, `installmentPlansStreamProvider`, `isOfflineProvider`, `categoriesRefProvider` | `core/providers/providers.dart` | ✅ |

## 🚨 Current Focus — What's Really Left

1. ~~**UI audit + migration**~~ ✅ **Completed 2026-05-08** — see `plans/ui_provider_migration.md` and `docs/architecture/ui_audit_2026_05_08.md`
   - `categoriesStreamProvider` removed from quick_add and edit_expense → `categoriesRefProvider`
   - `categoriesMapProvider` removed from expense_breakdown → `categoriesRefProvider`
   - `cashExpensesProvider`, `cashRemainingProvider`, `installmentsProvider` (CardInstallment) removed from health_screen → `financialSnapshotProvider`
   - `deleteFixedSeriesFrom` **removed** from `expense_repository.dart` on 2026-05-08
2. ~~**Tests**~~ ✅ **Completed 2026-05-08** — `test/unit/forecasting_engine_test.dart` (30 tests), `test/unit/intelligence_layer_test.dart` (22 tests)
3. ~~**Web layout**~~ ✅ **Completed 2026-05-08** — NavigationRail in MainShell + adaptive layout in all main screens (Dashboard, Transactions, Analytics, Budget, Installments, Recurring)
4. ~~**Migrations to production**~~ ✅ **Confirmed 2026-05-08** — V21–V25 applied. Tables `installment_plans`, `installment_payments`, `recurring_rules`, `recurring_occurrences` present in production.
5. ~~**`fixedExpensePropagationProvider`**~~ ✅ Confirmed removed — no longer exists in codebase
6. ~~**Empty/loading states in dashboard widgets**~~ ✅ **Completed 2026-05-08**
   - `BurnRateCard`: loading → `DashboardCardSkeleton(height: 130)` (before: `SizedBox.shrink`)
   - `InsightsPanel`: loading → 2 shimmer boxes with label (before: `SizedBox.shrink`)
   - `HealthGaugeCard`, `InstallmentsSummaryCard`: already had `DashboardCardSkeleton` ✅

## ✅ card_installments Migration — Completed (2026-05-08)

The migration is **fully complete**. All consumers use `activeInstallmentPlansProvider` / `InstallmentPlan`:
- `InstallmentsSummaryCard`, `HealthGaugeCard`, `NetWorthSettingsSheet`, `PdfReportService` → ✅ `activeInstallmentPlansProvider`
- `totalMonthlyInstallmentsProvider`, `totalRemainingInstallmentsProvider` → ✅ derived from `activeInstallmentPlansProvider`

The shim was **removed** after confirming production data migration:
- `InstallmentRepository` — class removed
- `installmentRepositoryProvider` — removed from `providers.dart`
- `transactions_screen.dart` — fallback `legacyPlanId` removed; delete now uses only `planUuid`
- The `Expense.installmentPlanId` (int?) field remains in the model/DB for compatibility but is no longer used in business logic

## 🛠️ Dev Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define-from-file=env.json
flutter analyze
flutter test
```

---

## 📋 Actual Plans Status (audited on 2026-05-08)

> ⚠️ The status below reflects actual code — not originally planned.
> The complete predictive engine was implemented. Current focus is UI + tests + web.

| Plan | Domain | DB (Migrations) | Providers | UI Screens | Tests | Real Status |
|---|---|---|---|---|---|---|
| `categories_redesign.md` | ✅ `CategoryRef`, `CategoryResolver` | ✅ V12, V17–V20 | ✅ `categoriesRefProvider` | ✅ `categories_management_screen` | ⚠️ partial | 🟢 **Complete** |
| `installments_redesign.md` | ✅ `InstallmentPlan/Payment`, `InstallmentService` | ✅ V21–V23 | ✅ `installmentPlansStreamProvider`, `activeInstallmentPlansProvider` | ✅ `installments_screen`, `InstallmentsSummaryCard`, `HealthGaugeCard` | ✅ `installment_service_test` | 🟢 **Complete** |
| `financial_engine.md` | ✅ `Money`, `FinancialSnapshot`, `FinancialEngine`, `EnvelopeEngine` | ✅ (no own schema) | ✅ `financialSnapshotProvider`, `envelopesProvider` | ✅ dashboard widgets: `BurnRateCard`, `PeriodBalanceHero`, `HealthGaugeCard` | ⚠️ partial | 🟢 **Complete** |
| `recurring_rules.md` | ✅ `RecurringRule/Occurrence`, `RecurrenceResolver`, `RecurringDetector` | ✅ V24–V25 | ✅ `recurringRulesStreamProvider`, `generateRecurringOccurrencesProvider` | ✅ `recurring_screen`, `add_recurring_bottom_sheet`, `recurring_suggestions_screen` | ✅ `recurrence_resolver_test` | 🟢 **Complete** |
| `forecasting.md` | ✅ `ForecastingEngine`, `ObligationEngine`, `BurnRate`, `LiquidityRisk`, `CashflowForecast` | ✅ (reads existing tables) | ✅ `financialProjectionProvider`, `cashflowForecastProvider` | ✅ `analytics_screen` + `cashflow_chart` | ⚠️ partial | 🟢 **Complete** |
| `offline_sync.md` | ✅ `SyncManager`, `OperationQueue`, `ConflictResolver` | ✅ (Drift `sync_queue`) | ✅ `syncStatusProvider`, `isOfflineProvider` | ✅ `ConnectivityBanner` in dashboard | ✅ 29 tests (sync/) | 🟢 **Complete** |
| `intelligence_layer.md` | ✅ `IntelligenceLayer` (12 rules), `DismissedInsightsRepository` | ✅ (Drift UserSettings) | ✅ `insightsProvider`, `dismissedInsightsProvider` | ✅ `InsightsPanel`, `insight_card`, `insights_screen` | ✅ 22 tests | 🟢 **Complete** |

### Recent Implementations (2026-05-08)

- **Dismiss rate tracking** ✅ **Completed 2026-05-08**
  - `InsightStats` entity in `core/domain/entities/insight_stats.dart`
  - `DismissedInsightsRepository.trackDismiss()` + `getStats()` — key `'insight_dismissal_stats'` in UserSettings (Drift)
  - `insightStatsProvider` in `providers.dart`
  - `InsightCard` calls `trackDismiss` + invalidates `insightStatsProvider` on dismiss
  - `InsightsScreen` displays "Most ignored types" section for types with ≥2 dismissals

- **Cashflow forecast cache** ✅ **Completed 2026-05-08** — see ADR in `docs/decisions/adr_cashflow_forecast_cache.md`
  - Edge Function discarded (see ADR); implemented client-side cache in Drift UserSettings
  - `CashflowDataPoint`/`CashflowForecast` now have `toJson`/`fromJson`
  - `ForecastCacheRepository` — TTL 2h, key includes financial period
  - `forecastCacheRepositoryProvider` + `cashflowForecastProvider` updated: cache hit avoids fetching all expenses
- **UI polish** ✅ **Completed 2026-05-08** — closing 🟡 `categories_redesign`, `financial_engine`, `forecasting` plans
  - `CategoriesManagementScreen`: `_CategoryTile` shows `financialType` chip + "System" badge; `_CategoryDialog` has financial type selector
  - `AnalyticsScreen`: Spanish text fixed → pt_BR ("Tendência Mensal", "Receita", "Distribuição por Categoria", "Comparativo Mensal", "MÉDIA/MÊS", screen subtitle)
  - `CashflowChart`: loading state → `ShimmerBox` (before: `CircularProgressIndicator`); projected minimum balance card added below chart

No outstanding UI or infrastructure technical debt. The `InstallmentRepository` shim was removed on 2026-05-08 after confirming production data migration.
