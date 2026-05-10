# Farol — Product Roadmap
> Last updated: 2026-05-09 (workspace model complete)
> Based on: `FAROL_PREDICTIVE_ENGINE.md`

---

> ## 🚨 Revised Status — 2026-05-09
>
> Audit of the code revealed that the **complete predictive engine is implemented**.
> All P0–P6 plans are complete in domain, infrastructure, and providers.
> The multi-user workspace model (Phases 1–3) is also complete and in production.
> Current focus: **Phase 4 Monetization (future, when ready)**.
>
> See `CLAUDE.md` → "Current Focus" section for detailed status.

---

## Dependency Graph (historical — all complete)

```
categories_redesign (P0)  ✅ COMPLETE
    ├──→ installments_redesign (P1)   ✅ COMPLETE
    └──→ financial_engine (P2)        ✅ COMPLETE
              ├──→ recurring_rules (P3)         ✅ COMPLETE
              │         └──→ forecasting (P4)   ✅ COMPLETE
              │                   └──→ intelligence_layer (P6)  ✅ COMPLETE
              └──→ offline_sync (P5)            ✅ COMPLETE

multiuser_freemium (Strategic)
    ├── Phase 1: DB schema + Flutter models   ✅ COMPLETE (2026-05-09)
    ├── Phase 2: Workspace switcher + Invites  ✅ COMPLETE (2026-05-09)
    ├── Phase 3: Permissions + Feature gating  ✅ COMPLETE (2026-05-09)
    └── Phase 4: Monetization                 ⏳ FUTURE
```

---

## P0 · categories_redesign · 🟢 Complete

**Plan**: `plans/categories_redesign.md`
**Completed**: Migrations V12, V17–V20 applied. `CategoryRef` + `CategoryResolver` implemented. `category_id NOT NULL` in expenses.

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | CategoryRef + Resolver | Type-safe value object, no StateError | ✅ |
| 2 | Data backfill | category_id in existing expenses | ✅ |
| 3 | Provider migration | UI uses CategoryRef | ✅ |
| 4 | Enum removal | Final cleanup | ✅ |

**ADR**: `docs/decisions/001-category-unification.md`

---

## P1 · installments_redesign · 🟢 Complete

**Plan**: `plans/installments_redesign.md`
**Completed**: Migrations V21–V23. `InstallmentPlan/Payment`, `InstallmentService` implemented. UI, forecasting integration, and legacy shim removal complete.

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | Schema + Entities | installment_plans + installment_payments | ✅ |
| 2 | InstallmentService | createPurchase() generates N installments automatically | ✅ |
| 3 | Migration | card_installments → new model (V22–V23) | ✅ |
| 4 | New UI | `installments_screen` with timeline | ✅ |
| 5 | Forecasting Integration | ObligationEngine reads pending installments | ✅ |

**ADR**: `docs/decisions/005-installments-redesign.md`

---

## P2 · financial_engine · 🟢 Complete

**Plan**: `plans/financial_engine.md`
**Completed**: `Money`, `FinancialSnapshot`, `FinancialEngine`, `EnvelopeEngine` implemented and wired in `financialSnapshotProvider`. Dashboard uses `BurnRateCard`, `HealthGaugeCard`, `PeriodBalanceHero`.

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | Money value object | Type-safe money type | ✅ |
| 2 | FinancialSnapshot entity | Central object contract | ✅ |
| 3 | FinancialEngine service | Produces the complete snapshot | ✅ |
| 4 | Dashboard refactoring | 1 provider → all widgets | ✅ |
| 5 | EnvelopeEngine | Rollover + automatic allocation | ✅ |

**ADR**: `docs/decisions/002-financial-snapshot.md`

---

## P3 · recurring_rules · 🟢 Complete

**Plan**: `plans/recurring_rules.md`
**Completed**: `RecurringRule/Occurrence`, `RecurrenceResolver`, `RecurringDetector`, migrations V24–V25, complete UI screens.

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | RecurrenceResolver | Generates occurrences from rule (pure Dart) | ✅ |
| 2 | Schema + Repositories | recurring_rules + recurring_occurrences | ✅ |
| 3 | isFixed migration | isFixed=true expenses → RecurringRule | ✅ |
| 4 | Recurring UI | `recurring_screen`, `add_recurring_bottom_sheet` | ✅ |
| 5 | Auto detection | `RecurringDetector` + `recurring_suggestions_screen` | ✅ |

**ADR**: `docs/decisions/006-recurring-rules.md`

---

## P4 · forecasting · 🟢 Complete

**Plan**: `plans/forecasting.md`
**Completed**: `ForecastingEngine`, `ObligationEngine`, all providers wired. `analytics_screen` + `cashflow_chart`. Tests: `forecasting_engine_test.dart` (30 tests).

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | BurnRate | Dashboard widget (`BurnRateCard`) | ✅ |
| 2 | DaysUntilEmpty + LiquidityRisk | `LiquidityAlertCard` in dashboard | ✅ |
| 3 | ProjectedClosingBalance | `financialProjectionProvider` | ✅ |
| 4 | CashflowForecast 90 days | `cashflow_chart.dart` in analytics screen | ✅ |
| 5 | CategoryVelocity | Implemented in `ForecastingEngine` | ✅ |
| 6 | Unit tests | BurnRate, DaysUntilEmpty, ProjectedBalance | ✅ |

**ADR**: `docs/decisions/003-forecasting-deterministic.md`

---

## P5 · offline_sync · 🟢 Complete

**Plan**: `plans/offline_sync.md`
**Completed**: `SyncManager`, `OperationQueue`, `ConflictResolver`, `ConnectivityBanner`, providers wired. Tests: 29 tests (sync/).

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | Connectivity detection | `ConnectivityBanner` in dashboard | ✅ |
| 2 | OperationQueue | Persistent queue in Drift with retry | ✅ |
| 3 | SyncManager | Online/offline orchestrator | ✅ |
| 4 | Expense Repository | Wrap with SyncManager | ✅ |
| 5 | Conflict Resolution | Last-Write-Wins + semantic merge | ✅ |
| 6 | Integration tests | Offline→online, retry, conflict scenarios | ✅ |

**ADR**: `docs/decisions/004-sync-strategy.md`

---

## P6 · intelligence_layer · 🟢 Complete

**Plan**: `plans/intelligence_layer.md`
**Completed**: `IntelligenceLayer` with 12 rules, `InsightsPanel`, `insights_screen`, `insightsProvider`, `DismissedInsightsRepository`, dismiss rate tracking (2026-05-08).

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | Foundation + 4 core rules | Overdraft, Liquidity, Spike, Investment | ✅ |
| 2 | InsightsPanel in dashboard | Non-invasive UI, max 3 insights | ✅ |
| 3 | 8 advanced rules | Duplicates, Subscriptions, Achievements, etc. | ✅ |
| 4 | Insight analytics | Dismiss rate tracking via `insightStatsProvider` | ✅ |

**ADR**: `docs/decisions/007-intelligence-layer.md`

---

## Strategic · multiuser_freemium · 🟡 Phase 4 Pending

**Plan**: `plans/multiuser_freemium.md`
**Completed phases**: 1 (DB schema V26–V32 + Flutter models), 2 (workspace switcher + invites), 3 (permission guards + feature gating)

| # | Phase | Goal | Status |
|---|---|---|---|
| 1 | Invisible foundation | V26–V32 migrations + Flutter models + providers | ✅ 2026-05-09 |
| 2 | Workspace switcher + Invites | WorkspaceSwitcherSheet, InviteMemberSheet, MembersScreen | ✅ 2026-05-09 |
| 3 | Permissions + Feature gating | FeatureGate widget, canWriteProvider guards | ✅ 2026-05-09 |
| 4 | Monetization | Stripe/RevenueCat, paywall, pricing | ⏳ Future |

**Plan**: `plans/multiuser_freemium.md`

---

## Success Metrics

| Plan | Metric | Status |
|---|---|---|
| categories_redesign | 0 `StateError` in production | ✅ Resolved |
| installments_redesign | Future installments visible in ForecastingEngine | ✅ Implemented |
| financial_engine | Dashboard with 1 single `ref.watch()` for financial state | ✅ `financialSnapshotProvider` |
| recurring_rules | Recurrings projected 3 months ahead automatically | ✅ Implemented |
| forecasting | User answers "how much will I save?" by looking at the app | ✅ Functional + tested |
| offline_sync | 0 data loss in offline → online scenario | ✅ Functional + tested |
| intelligence_layer | Insight dismiss rate < 40% | ⏳ Tracking implemented, awaiting real data |
| multiuser_freemium | Couple can share a workspace in real time | ✅ Phase 1–3 complete |

---

## Version History

| Date | Change |
|---|---|
| 2026-05-07 | Initial roadmap (4 plans: P0–P3) |
| 2026-05-07 | Full revision: 7 plans, dependency graph, priorities redefined |
| 2026-05-08 | All P0–P6 complete. Focus shifted to UI polish + tests + web adaptation |
| 2026-05-09 | Multi-user workspace model (Phases 1–3) complete and in production |
