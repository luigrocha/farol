# Farol Architecture — Living Vision

> This document is updated with each significant architectural change.
> Last updated: 2026-05-09

---

## Current Architecture State (as of 2026-05-09)

All planned domain layers are implemented. The architecture has evolved from the legacy "static services + direct Supabase" pattern to a full layered domain model:

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER UI                        │
│  lib/features/*/presentation/                       │
│  Screens · Widgets · Bottom Sheets                  │
├─────────────────────────────────────────────────────┤
│              PROVIDERS (Riverpod 2)                 │
│  lib/core/providers/                                │
│  financialSnapshotProvider · financialProjectionProvider │
│  cashflowForecastProvider · insightsProvider        │
│  categoriesRefProvider · recurringRulesStreamProvider│
│  installmentPlansStreamProvider · workspaceProviders│
├─────────────────────────────────────────────────────┤
│               DOMAIN LAYER                          │
│  lib/core/domain/                                   │
│  FinancialEngine · ForecastingEngine                │
│  EnvelopeEngine · ObligationEngine                  │
│  IntelligenceLayer · InstallmentService             │
│  RecurringService · RecurrenceResolver              │
│  RecurringDetector · CategoryResolver               │
├─────────────────────────────────────────────────────┤
│              REPOSITORIES                           │
│  lib/core/repositories/                             │
│  All repos accept workspaceId; RLS is security boundary │
│  SyncManager wraps Supabase + Drift queue           │
├─────────────────────────────────────────────────────┤
│            INFRASTRUCTURE LAYER                     │
│  SyncManager · OperationQueue · ConflictResolver    │
│  ForecastCacheRepository · DismissedInsightsRepository │
├─────────────────────────────────────────────────────┤
│              PERSISTENCE                            │
│  Supabase PostgreSQL (source of truth, V1–V32)     │
│  Drift/SQLite (UserSettings, OperationQueue, cache) │
└─────────────────────────────────────────────────────┘
```

## Target Architecture (achieved)

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER UI                        │
│  Screens · Widgets (consume FinancialSnapshot)      │
├─────────────────────────────────────────────────────┤
│              APPLICATION LAYER                      │
│  Riverpod providers orchestrate use cases           │
├─────────────────────────────────────────────────────┤
│               DOMAIN LAYER                          │
│  FinancialEngine · ForecastingEngine                │
│  EnvelopeEngine · ObligationEngine                  │
│  IntelligenceLayer                                  │
├─────────────────────────────────────────────────────┤
│            INFRASTRUCTURE LAYER                     │
│  Repositories (Drift + Supabase via SyncManager)    │
│  OperationQueue · ConflictResolver                  │
└─────────────────────────────────────────────────────┘
```

## Bounded Contexts

| Context | Responsibility | State |
|---|---|---|
| Identity & Period | User, profile, financial periods, workspaces | ✅ Implemented |
| Ledger | Record of past transactions | ✅ Implemented |
| Budget (Envelopes) | Budget per category, envelope rollover | ✅ Implemented |
| Obligations | Installments & future recurring | ✅ Implemented |
| Forecasting | Financial projection, cashflow chart | ✅ Implemented |
| Intelligence | Insights & recommendations (12 rules) | ✅ Implemented |
| Workspace | Multi-user workspaces, invites, permissions | ✅ Implemented |

## Multi-user Workspace Model

As of 2026-05-09, every piece of financial data belongs to a workspace:

```
auth.users (Supabase Auth)
    └── workspace_members (N:M)
            └── workspaces
                    └── all financial data (expenses, incomes, installments, recurring, etc.)
```

**Security pattern**: RLS uses `SECURITY DEFINER` helper functions to avoid self-referential recursion:
- `get_my_workspace_ids()` — all workspace IDs the user belongs to
- `get_my_workspace_ids_as_writer()` — workspace IDs with write role (owner/admin/member)
- `get_my_workspace_ids_as_admin()` — workspace IDs with admin/owner role

**Enforcement**: Dual-layer — Flutter UI (FABs hidden, swipe disabled for viewers) + Supabase RLS (INSERT/UPDATE/DELETE require writer role).

## Active Architectural Decisions

See `docs/decisions/` for complete ADR history.

| # | Decision | State |
|---|---|---|
| 001 | Category system unification — `CategoryRef` value object | ✅ Implemented |
| 002 | FinancialSnapshot as single source of truth | ✅ Implemented |
| 003 | Deterministic Forecasting Engine (no ML in v1) | ✅ Implemented |
| 004 | Sync Strategy: Optimistic + Queue | ✅ Implemented |
| 005 | Installments Redesign — InstallmentPlan + InstallmentPayments | ✅ Implemented |
| 006 | Recurring Rules Engine — RecurringRule + RecurringOccurrence | ✅ Implemented |
| 007 | Intelligence Layer — 12 deterministic rules, no ML | ✅ Implemented |
| Cache | Cashflow forecast cache — client-side TTL in Drift | ✅ Implemented |
