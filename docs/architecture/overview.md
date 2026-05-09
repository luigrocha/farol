# Farol Architecture — Living Vision

> This document is updated with each significant architectural change.
> Last updated: May 2026

---

## Current Architecture State

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER UI                        │
│  lib/features/*/presentation/                       │
│  Screens · Widgets · Bottom Sheets                  │
├─────────────────────────────────────────────────────┤
│              PROVIDERS (Riverpod 2)                 │
│  lib/core/providers/                                │
│  autoDispose · StreamProvider · FutureProvider      │
├─────────────────────────────────────────────────────┤
│              REPOSITORIES                           │
│  lib/core/repositories/ + lib/features/*/data/      │
│  Direct SupabaseClient (majority)                   │
│  AppDatabase/Drift (some)                           │
├─────────────────────────────────────────────────────┤
│              CORE SERVICES                          │
│  FinancialCalculatorService (static)                │
│  ExportService · CltCalculatorService               │
├─────────────────────────────────────────────────────┤
│              PERSISTENCE                           │
│  Supabase PostgreSQL (source of truth)             │
│  Drift/SQLite (partial mirror, no coherent sync)    │
└─────────────────────────────────────────────────────┘
```

## Target Architecture (post-plan implementation)

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER UI                        │
│  Screens · Widgets (consume only FinancialSnapshot) │
├─────────────────────────────────────────────────────┤
│              APPLICATION LAYER                      │
│  UseCases · Commands · Queries                      │
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
| Identity & Period | User, profile, financial periods | ✅ Implemented |
| Ledger | Record of past transactions | ⚠️ Partial |
| Budget (Envelopes) | Budget per category | ⚠️ Basic |
| Obligations | Installments & future recurring | 🔴 Minimal |
| Forecasting | Financial projection | 🔴 Non-existent |
| Intelligence | Insights & recommendations | 🔴 Non-existent |

## Active Architectural Decisions

See `docs/decisions/` for complete ADR history.

| # | Decision | State |
|---|---|---|
| 001 | Category system unification | 🔴 Pending |
| 002 | FinancialSnapshot as single source of truth | 🔴 Pending |
| 003 | Deterministic Forecasting Engine (no ML) | 🔴 Pending |
| 004 | Sync Strategy: Optimistic + Queue | 🔴 Pending |
