# Farol

[![CI](https://github.com/luigrocha/farol/actions/workflows/test.yml/badge.svg)](https://github.com/luigrocha/farol/actions/workflows/test.yml)

**Predictive personal finance for Brazilian CLT workers.** Offline-first, realtime-collaborative, with a deterministic forecasting engine that understands Swile, FGTS, 13th salary, and your cutoff day.

---

## Features

- **Predictive Engine** — Burn rate, days until empty, projected closing balance, and cashflow forecast. Not a chart — an answer to *"how will my money behave this period?"*
- **CLT-native** — Customizable `cutoffDay`, Swile as a separate bucket, FGTS auto-projection (8% of gross), 13th salary simulator with INSS + IRRF 2025 progressive tables
- **Offline-first + Sync** — Drift SQLite local-first, optimistic updates, persistent operation queue, idempotent retry. Works 100% offline, syncs when connected
- **Multi-user Workspaces** — Shared spending tracking with role-based access (admin/writer/viewer), attribution (who spent what), activity feed, and realtime presence
- **Budget with Envelopes** — Per-category targets with 4-level alerts (green/yellow/orange/red), rollover between periods, automatic envelope for installments
- **Recurring Rules** — RRULE-based engine for fixed and recurring items. Auto-generates occurrences 3 months ahead. Detects recurring patterns in your history
- **Intelligence Layer** — 12 rule-based insights (unusual spending, velocity changes, budget risk) with dismiss tracking and stats. No ML — deterministic rules that work from day one
- **Installment Plans** — Full lifecycle: create, track payments, integrate with cashflow forecast. Each installment appears as a projected expense drop on the chart
- **31 test files, 0 lint warnings** — Unit, widget, sync, and integration tests enforced by CI

---

## Screens

| Screen | What it does |
|---|---|
| **Dashboard** | Net worth KPIs, health score (0–10), burn rate, contribution bar (shared workspaces), expense breakdown, activity feed preview, top alerts |
| **Transactions** | Full expense/income/installment history with filters, date range, and search. Member attribution in shared workspaces |
| **Analytics** | Cashflow forecast chart (actual + projected), revenue/expense trends, category distribution, monthly comparison, category velocity |
| **Budget** | Period envelopes with progress bars, rollover badge, last-edit attribution, 4-level alerts |
| **Recurring** | Recurring rules with occurrence calendar, auto-detection suggestions |
| **Installments** | Active installment plans with payment schedule and cashflow impact |
| **Activity** | Day-grouped feed with infinite scroll, pull-to-refresh, realtime updates |
| **Workspace** | Switcher, create/invite members, manage roles, transfer ownership |
| **Settings** | Profile, salary config (gross/net/Swile), budget goals, 13th simulator, export, theme |
| **Investments** | Portfolio positions (Treasury, CDB, REIT), allocation insights |

---

## Architecture

```
lib/
├── core/
│   ├── domain/                    # DDD — entities, services, value objects
│   │   ├── entities/              FinancialSnapshot, Envelope, BurnRate,
│   │   │                          InstallmentPlan, RecurringRule, FinancialInsight
│   │   ├── services/              FinancialEngine, ForecastingEngine, EnvelopeEngine,
│   │   │                          ObligationEngine, IntelligenceLayer, InstallmentService,
│   │   │                          RecurringService, RecurrenceResolver, RecurringDetector
│   │   └── value_objects/         Money, CategoryRef, MemberDisplay
│   ├── repositories/              WorkspaceRepository, BudgetChangesRepository,
│   │                              WorkspaceActivityRepository, (5 repos with workspaceId)
│   ├── providers/                 providers.dart — 30+ Riverpod autoDispose providers
│   ├── database/                  Drift schema (SQLite), DAOs, seed data
│   ├── models/                    Enums (ExpenseCategory, PaymentMethod, etc.),
│   │                              constants, budget_alert, member_display
│   ├── services/                  WorkspaceRealtimeService, FinancialCalculatorService,
│   │                              ExportService
│   ├── infrastructure/sync/       SyncManager, OperationQueue, ConflictResolver
│   └── widgets/                   FeatureGate, MemberChip, MemberAvatarGroup,
│                                  ActivityFeedTile, WorkspaceAppBarChip
├── features/
│   ├── dashboard/                 KPIs, health gauge, burn rate, contribution bar,
│   │                              insights panel, activity preview, connectivity banner
│   ├── transactions/              List, filters, quick-add, edit/delete
│   ├── analytics/                 Cashflow chart, trends, distribution, velocity
│   ├── budget/                    Period envelopes, budget edit sheet, progress
│   ├── recurring/                 Rules list, occurrence view, add/edit sheet
│   ├── installments/              Plans list, payment schedule
│   ├── activity/                  Activity feed screen, infinite scroll
│   ├── workspace/                 Switcher sheet, create, invite, members screen
│   ├── auth/                      Login, signup, session management
│   └── settings/                  Profile, salary, goals, 13th simulator, export
└── main.dart                      Entry point, MainShell with responsive nav
```

- **State**: Riverpod 2 (`autoDispose` — zero side effects, automatic cleanup)
- **Database**: Drift (SQLite) — offline-first, type-safe DAOs, auto migrations
- **Backend**: Supabase — auth, REST, realtime, Edge Functions
- **Charts**: fl_chart — line, pie, bar (animated, responsive)

---

## Stack

| Layer | Technology |
|---|---|
| **Language** | Dart 3 |
| **Framework** | Flutter 3 (Material 3) |
| **State** | Riverpod 2 (autoDispose) |
| **Database** | Drift (SQLite) |
| **Backend** | Supabase (auth + REST + realtime + Edge Functions) |
| **Charts** | fl_chart |
| **Fonts** | Google Fonts (Manrope) |
| **Code Gen** | build_runner (Drift, Riverpod) |

---

## Database Schema

| Table | Purpose |
|---|---|
| `incomes` | Gross/net salary, Swile, bonus, 13th salary |
| `expenses` | Cash, card, and Swile expenses with category + workspace |
| `installment_plans` | Credit card installment plans (parent) |
| `installment_payments` | Individual payments per plan (child) |
| `recurring_rules` | RRULE-based recurring expense rules |
| `recurring_occurrences` | Generated occurrences from rules |
| `envelopes` | Period budgets with rollover policy |
| `budget_goals` | Per-category target percentages |
| `investments` | Portfolio positions (Treasury, CDB, REIT) |
| `net_worth_snapshots` | Monthly net worth tracking |
| `workspace_activity` | Audit log for shared workspaces |
| `budget_changes` | Budget edit history (shared workspaces) |
| `workspaces` | Personal and shared workspaces |
| `workspace_members` | Membership with roles (admin/writer/viewer) |
| `workspace_invites` | Pending invitations |

---

## Business Logic

### Predictive Financial Engine

The engine is **deterministic**, not ML. Works from day one with zero user history:

- **Burn Rate** — Average daily spending over configurable window, projected forward
- **Days Until Empty** — Cash balance ÷ burn rate, with red/yellow/green thresholds
- **Projected Closing Balance** — Current balance + projected income − projected expenses − installment drops
- **Cashflow Forecast** — 90-day chart (solid = actual, dashed = projected) with installment event markers
- **Category Velocity** — Spending rate per category, compared to historical average
- **Budget Risk Score** — Dynamic score that changes in real-time when expenses are recorded

### Intelligence Layer (12 rules)

No ML, no training data needed. Pure heuristic rules that trigger insights:

- Unusual spending spike (2σ from mean)
- Budget depletion rate warning
- Installment concentration alert
- Savings rate drop
- Recurring charge change detection
- Low-balance before known obligations
- And 7 more — all with dismiss tracking and stats

### Budget & Envelopes

- 4 alert levels: 🟢 Green (<75%) → 🟡 Yellow (75–89%) → 🟠 Orange (90–99%) → 🔴 Red (≥100%)
- Rollover: unused envelope balance carries to next period
- Swile expenses are **excluded** from cash budget tracking

### CLT-specific

- **FGTS**: Auto-projected at 8% of gross salary, updated reactively when salary changes
- **13th Salary**: Full INSS + IRRF 2025 progressive table simulation with dependent deductions
- **Swile**: Separate Meal/Food buckets that don't touch cash burn rate
- **Cutoff Day**: Customizable period start (most Brazilians receive salary day 5–15, not day 1)

### Workspace Roles

| Role | Create/Edit | Manage Members | Transfer Ownership |
|---|---|---|---|
| Owner | ✅ | ✅ | — |
| Admin | ✅ | ✅ | ❌ |
| Writer | ✅ | ❌ | ❌ |
| Viewer | ❌ | ❌ | ❌ |

---

## Setup

### Prerequisites

- Flutter 3.27+ ([install](https://flutter.dev))
- Dart SDK ≥ 3.0 (included with Flutter)
- Git

### Install

```bash
git clone https://github.com/luigrocha/farol.git
cd farol
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Web

```bash
flutter run -d chrome --dart-define-from-file=env.json
```

### Dev

```bash
flutter analyze          # 0 issues expected
flutter test             # 31 files, 100+ tests
```

---

## Demo Data

On first launch, the app seeds demo data for April 2025:

| Category | Amount | Notes |
|---|---|---|
| Gross Salary | R$ 9,000.00 | CLT monthly |
| Net Salary | R$ 6,783.21 | After INSS + IRRF |
| Swile Meal | R$ 700.00 | Monthly benefit |
| Swile Food | R$ 500.00 | Monthly benefit |
| Rent | R$ 2,500.00 | Fixed housing |
| FGTS Balance | R$ 15,000.00 | Auto-projected at 8%/mo |
| Installments | 1 plan (12x R$ 500) | Generic example |

To reset: delete app data → restart.

### 13th Salary Example (R$ 9,000 gross, 1 dependent)

```
INSS (progressive 2025):
  1º faixa:  R$ 0 ~ 1.518,00 @ 7,5%   = R$   113,85
  2º faixa:  R$ 1.518,01 ~ 2.793,88 @ 9%   = R$   114,83
  3º faixa:  R$ 2.793,89 ~ 4.190,83 @ 12%  = R$   167,63
  4º faixa:  R$ 4.190,84 ~ 9.000,00 @ 14%  = R$   673,28
                                         ———————————
  Total: R$ 1.069,59 → capped at R$ 951,62

IRRF (progressive 2025):
  Base = R$ 9.000 - R$ 951,62 (INSS) - R$ 189,59 (dependent)
       = R$ 7.858,79
  Bracket 5 (> R$ 4.664,68): R$ 7.858,79 × 27,5% - R$ 896,00
       = R$ 1.265,17

Net 13th: R$ 9.000 - R$ 951,62 - R$ 1.265,17 = R$ 6.783,21
→ 1ª parcela (junho):  R$ 4.500,00
→ 2ª parcela (dezembro): R$ 2.283,21
```

---

## Design

- **Theme**: Material 3 (light / dark / system)
- **Colors**: Navy primary, green secondary, teal tertiary, red error
- **Typography**: Manrope (400/700/800, 12–30px)
- **Platform**: Mobile-first, responsive web via NavigationRail

---

## Testing & Quality

| Metric | Status |
|---|---|
| **Lint warnings** | 0 (`flutter analyze` clean) |
| **Test files** | 31 (unit + widget + sync + integration) |
| **CI** | GitHub Actions — Flutter 3.27, Ubuntu, 3 jobs |
| **Coverage areas** | Forecasting engine, intelligence layer, sync (queue, conflict resolver, manager), financial engine, envelope engine, recurring engine, installment service, repositories, auth UI |

---

## License

© 2026 Luis Rocha. MIT.
