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
→ See `plans/multiuser_freemium.md` — complete plan with 4 phases

**Phase 1 — COMPLETE + IN PRODUCTION (2026-05-09)**:
- V26–V32 applied in production (`database/migrations/`)
  - V26: workspaces + workspace_members + workspace_invites tables + RLS
  - V27: workspace_id column added to all 14 data tables
  - V28: backfill — personal workspace created per existing user, data linked
  - V29: workspace_id NOT NULL enforced + indexes
  - V30: RLS policies migrated from user_id to workspace membership
  - V31: Fix — system categories visibility (user_id IS NULL) + auto-populate workspace_id triggers
  - V32: Fix — infinite recursion in workspace_members RLS (SECURITY DEFINER helper functions)
- Models: `Workspace`, `WorkspaceMember`, `WorkspaceInvite` → `lib/core/models/workspace.dart`
- `WorkspaceRepository` → `lib/core/repositories/workspace_repository.dart`
- Providers: `activeWorkspaceProvider`, `workspacePlanProvider`, `canWriteProvider` → `lib/core/providers/workspace_providers.dart`
- `FeatureGate` widget + `PremiumFeature` enum → `lib/core/widgets/feature_gate.dart`
- 5 repositories with `workspaceId`: Expense, Income, Category, InstallmentPlan, RecurringRules
- **RLS pattern**: All policies use `SECURITY DEFINER` helper functions (`get_my_workspace_ids()`, `get_my_workspace_ids_as_writer()`, `get_my_workspace_ids_as_admin()`) to avoid self-referential recursion
- **Phase 2 + 3 — COMPLETE (2026-05-09)**:
  - `WorkspaceSwitcherSheet` — AppBar chip (hidden when solo), lists workspaces, switches active
  - `CreateWorkspaceSheet` — creates workspace + auto-switches to it
  - `InviteMemberSheet` — email + role picker, generates invite token + copy link
  - `MembersScreen` — list members, change roles, remove (owner/admin only)
  - `WorkspaceAppBarChip` — chip in dashboard AppBar, only visible when >1 workspace
  - Desktop NavRail header shows workspace chip when >1 workspace
  - `canWriteProvider` guards: FABs hidden for viewers in all screens (Dashboard, Transactions, Installments, Recurring, Budget, Categories, Accounts); swipe-to-delete disabled; edit `onTap` disabled
- **Collaborative Workspace Foundation Polish — COMPLETE (2026-05-10)**:
  - V33 migration: `workspace_type` (personal|shared), `emoji`, `color`, `description` columns; backfill; updated `create_personal_workspace()` trigger (default emoji 🏠, type 'personal')
  - `WorkspaceType` enum + `WorkspaceTypeX` extension in `workspace.dart`
  - `Workspace` model: new `type`, `emoji`, `color`, `description` fields; `fromJson`/`toJson`/`copyWith` updated
  - `WorkspaceRepository.create()`: accepts type/emoji/color/description; `updateIdentity()` method added
  - `WorkspaceAppBarChip`: always visible (removed `workspaces.length <= 1` guard); teal tint for shared, grey for personal; shows emoji if set
  - `WorkspaceSwitcherSheet`: redesigned with "Your space" / "Shared spaces" sections; `_WorkspaceAvatar` shows emoji; type-based coloring
  - `CreateWorkspaceSheet`: type picker (personal vs shared card UI), emoji palette, color picker (6 accent colors)
  - Desktop NavRail `_NavRailHeader`: same always-visible + teal/grey tinting treatment, emoji support
- **Attribution System (Phase 2) — COMPLETE (2026-05-10)**:
  - V34 migration: `author_user_id UUID` on `expenses`, `recurring_rules`, `installment_plans`; backfill (`SET author_user_id = user_id`); profiles RLS policy for co-member visibility
  - `MemberDisplay` value object + `avatarColorForUserId()` — `lib/core/models/member_display.dart`
  - `memberDisplayMapProvider` — `FutureProvider.autoDispose<Map<String, MemberDisplay>>` — fetches profiles in one Supabase query
  - `isSharedWorkspaceProvider` — `Provider<bool>` — gates all attribution UI
  - `MemberChip` + `MemberAvatarGroup` widgets — `lib/core/widgets/member_chip.dart`
  - Attribution wired into `TransactionsScreen` (`_TxRow`), `InstallmentsScreen` (`_PlanTile`), `RecurringScreen` (`_RuleTile`) — shown only in shared workspaces
  - `ContributionBar` on Dashboard — stacked bar + legend, groups real expenses by `author_user_id`, only visible in shared workspaces
  - `MembersScreen` upgraded — real display names, initials, and avatar colors from `memberDisplayMapProvider` (was showing raw userId prefix)
  - Repository inserts updated — `author_user_id: userId` now written on all new expenses, recurring rules, and installment plans
- **Activity Feed (Phase 3) — COMPLETE (2026-05-10)**:
  - V35 migration: `workspace_activity` table + RLS + SECURITY DEFINER triggers on expenses, recurring_rules, installment_plans (INSERT/DELETE auto-log)
  - V36 migration: `budget_changes` audit table + RLS (app-side writes, not triggers)
  - `WorkspaceActivity` entity — `lib/core/domain/entities/workspace_activity.dart`
  - `WorkspaceActivityRepository` — `fetchLatest()` + `fetchPage()` (cursor-based pagination)
  - `latestWorkspaceActivityProvider` (family, limit param) + `workspaceActivityFirstPageProvider`
  - `ActivityFeedTile` widget — `lib/features/activity/activity_feed_tile.dart`
  - `ActivityFeedScreen` — full page, day-grouped, infinite scroll, pull-to-refresh — `lib/features/activity/activity_feed_screen.dart`
  - `ActivityFeedPreviewCard` — dashboard widget, last 3 items + "Ver tudo" → ActivityFeedScreen — `lib/features/dashboard/widgets/activity_feed_preview_card.dart`
  - `BudgetChangesRepository` + `budgetChangesProvider` — `lib/core/repositories/budget_changes_repository.dart`
  - `BudgetEditSheet` logs change on upsert (shared workspaces only, invalidates `budgetChangesProvider`)
  - `_BudgetLastEditLine` widget on each envelope in `PeriodBudgetScreen` — "Último ajuste: Ana · ontem"
- **Realtime + Presence (Phase 4) — COMPLETE (2026-05-10)**:
  - `WorkspaceRealtimeService` singleton — `lib/core/services/workspace_realtime_service.dart`; subscribes to `workspace_activity` INSERT + Presence on channel `workspace:{id}`; managed by `MainShell` WidgetsBindingObserver (`resume`/`pause`); re-syncs on active workspace change via `Consumer` listener
  - `workspacePresenceProvider` — `StreamProvider<Set<String>>` of co-member user IDs currently online
  - Presence dot on `WorkspaceAppBarChip` — green dot (9px) when `workspacePresenceProvider` is non-empty in shared workspaces
  - `workspaceActivityRealtimeProvider` — `StreamProvider` bridge; invalidates `latestWorkspaceActivityProvider` + `workspaceActivityFirstPageProvider` on any INSERT event
  - `ActivityFeedPreviewCard` watches `workspaceActivityRealtimeProvider` to keep bridge alive
  - Edge Function `accept-workspace-invite` — `supabase/functions/accept-workspace-invite/index.ts`; validates token, checks expiry, creates `workspace_members` row, marks invite `accepted_at`, logs to `workspace_activity`, returns workspace data
  - Edge Function `transfer-ownership` — `supabase/functions/transfer-ownership/index.ts`; atomically promotes new owner, demotes old owner to admin, updates `workspaces.owner_id`, logs to `workspace_activity`, with rollback on partial failure
- **Next step**: Monetization / Freemium gates (Phase 5, when ready)

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

- Supabase schema: 32 migrations applied (V1–V32) — source of truth in production
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

## 🚀 Spaces v2 — Implementation Status (2026-05-15)

| Sprint | Theme | Status |
|---|---|---|
| Sprint 1 | DB schema (V43/V44), Dart models, `SpaceRepository`, providers | ✅ Complete |
| Sprint 2 | `CreateSpaceSheet`, `AddSpaceTransactionSheet`, `SpaceDashboardScreen`, context switcher | ✅ Complete |
| Sprint 3 | `SpaceSettingsScreen`, `SpaceMembersScreen`, `SpaceTransactionsScreen`, realtime, `SpaceAppBarChip` | ✅ Complete |
| Sprint 4 | `spaceMemberDisplayMapProvider`, `SpaceContributionsCard`, onboarding empty state, web layout | ✅ Complete |
| Sprint 5 | `accept-space-invite` Edge Function, `AcceptSpaceInviteScreen`, `/join/:token` deep-link | ✅ Complete |
| Sprint 6 | `V45__space_activity.sql`, `SpaceActivity` entity, `SpaceActivityRepository`, `spaceActivityProvider`, `spaceActivityRealtimeProvider`, `SpaceActivityCard`, `SpaceActivityScreen` | ✅ Complete |
| Sprint 7 | `V46__push_tokens.sql`, `PushTokenRepository`, `send-space-notification` Edge Function, `SpaceNotificationService` (stub, awaits Firebase setup), `InviteAcceptedBanner` + `InviteAcceptedOverlayMixin`, `member_joined` activity event, overlay wired into `SpaceDashboardScreen` | ✅ Complete |

**Key files:**
- Schema: `database/migrations/V43__spaces_foundation.sql`, `V44__spaces_backfill.sql`, `V46__push_tokens.sql`
- Models: `lib/core/models/space.dart`, `lib/core/models/space_transaction.dart`
- Repository: `lib/core/repositories/space_repository.dart`, `lib/core/repositories/push_token_repository.dart`
- Providers: `lib/core/providers/space_providers.dart`
- Services: `lib/core/services/space_notification_service.dart`
- Screens: `lib/features/space/` (7 screens + overlay + 2 edge functions)
- Dashboard card: `lib/features/dashboard/widgets/space_contributions_card.dart`
- Edge Functions: `supabase/functions/accept-space-invite/`

---

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
