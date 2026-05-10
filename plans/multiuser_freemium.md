# Plan: Multi-user (Workspace) + Freemium
**Area**: Architecture · DB · Auth · UI · Product
**Priority**: P0 strategic — defines the future business model
**Dependencies**: All migrations V1–V25 applied ✅
**Status**: 🟢 Phases 1–3 complete in production (2026-05-09)

---

## 🎯 Strategic Positioning

```
❌ BEFORE: "control your spending"
✅ NOW:    "understand the future of your money"
```

Farol is not an expense tracker. It is a **predictive financial co-pilot**.
The difference: a user who sees "at this rate you'll end the month -R$120"
changes behavior. A user who only sees "you spent R$800" has no actionable information.

---

## 📐 Workspace Model

### Hierarchy

```
auth.users (Supabase Auth)
    └── workspace_members (N:M)
            └── workspaces
                    ├── expenses
                    ├── incomes
                    ├── installment_plans
                    ├── recurring_rules
                    ├── budget_goals
                    ├── period_budgets
                    ├── categories (custom)
                    ├── accounts
                    ├── investments
                    └── ...all financial data
```

### Real use cases

| Case | Workspace | Members | Permissions |
|---|---|---|---|
| Solo | Personal (auto-created) | 1 | owner |
| Couple | "Our Home" | 2 | owner + admin |
| Roommates | "Apt 42" | 3–5 | owner + members |
| Family | "Grocha Family" | N | owner + admins + viewers |
| Freelancer | "Personal" + "LTDA" | 1–2 | owner on both |

### Core rule

> **Every new user automatically gets a personal workspace.**
> The solo UX is identical. The workspace is invisible until the user invites someone.

---

## 🗄️ DB Schema — Migrations

### V26 — `workspaces` table

```sql
CREATE TABLE workspaces (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  slug          TEXT UNIQUE,
  owner_id      UUID NOT NULL REFERENCES auth.users(id),
  plan          TEXT NOT NULL DEFAULT 'free'
                CHECK (plan IN ('free', 'premium')),
  plan_expires_at TIMESTAMPTZ,                  -- NULL = free forever
  settings      JSONB DEFAULT '{}',             -- cutoffDay, currency, etc.
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE workspace_members (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          TEXT NOT NULL DEFAULT 'member'
                CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  invited_by    UUID REFERENCES auth.users(id),
  joined_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (workspace_id, user_id)
);

CREATE TABLE workspace_invites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'member',
  token         TEXT NOT NULL UNIQUE DEFAULT gen_random_uuid()::text,
  invited_by    UUID NOT NULL REFERENCES auth.users(id),
  expires_at    TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
  accepted_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
```

### V27 — `workspace_id` on all data tables

```sql
ALTER TABLE expenses        ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;
-- repeat for all 14 data tables
```

### V28 — Backfill: personal workspace for all existing users

```sql
-- 1. Create personal workspace per existing user
-- 2. Add each user as owner of their workspace
-- 3. Backfill workspace_id on all existing data (user_id → workspace)
```

### V29 — NOT NULL + indexes

```sql
ALTER TABLE expenses ALTER COLUMN workspace_id SET NOT NULL;
-- repeat for all tables
CREATE INDEX ON expenses (workspace_id);
-- repeat for all tables
```

### V30 — Update RLS on all tables

Pattern for each table: replace `user_id = auth.uid()` with workspace membership check.

### V31 — Fix: system categories + auto-populate triggers

- System categories (`user_id IS NULL`) visible to all authenticated users
- `auto_set_workspace_id()` BEFORE INSERT trigger populates `workspace_id` from `user_id` when omitted
- Special triggers for `installment_payments` (via `plan_id`) and `recurring_occurrences` (via `rule_id`)

### V32 — Fix: infinite recursion in workspace_members RLS

Root cause: policies on `workspace_members` queried `workspace_members` itself → infinite loop.
Fix: three `SECURITY DEFINER` helper functions that bypass RLS:
- `get_my_workspace_ids()` — all workspace IDs the user belongs to
- `get_my_workspace_ids_as_writer()` — workspace IDs with write role
- `get_my_workspace_ids_as_admin()` — workspace IDs with admin/owner role

All policies (workspace tables + all 14 data tables) replaced to use these functions.

---

## 🏗️ Flutter Architecture

### Models (`lib/core/models/workspace.dart`)

```dart
class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final WorkspacePlan plan;            // free | premium
  final DateTime? planExpiresAt;
  final Map<String, dynamic> settings;
  final List<WorkspaceMember> members;

  bool get isPremium => ...;
  WorkspaceRole roleFor(String userId) => ...;
}

enum WorkspacePlan { free, premium }

class WorkspaceMember {
  final String userId;
  final String workspaceId;
  final WorkspaceRole role;
  final DateTime joinedAt;
}

enum WorkspaceRole { owner, admin, member, viewer }
```

### Providers (`lib/core/providers/workspace_providers.dart`)

```dart
// Active workspace (persisted in Drift UserSettings)
final activeWorkspaceProvider = AsyncNotifierProvider<WorkspaceNotifier, Workspace?>();

// All user workspaces
final userWorkspacesProvider = FutureProvider.autoDispose<List<Workspace>>();

// Plan of active workspace (for feature gating)
final workspacePlanProvider = Provider<WorkspacePlan>((ref) {
  return ref.watch(activeWorkspaceProvider).valueOrNull?.plan ?? WorkspacePlan.free;
});

// Current user's role in active workspace
final currentUserRoleProvider = Provider<WorkspaceRole>(...);

// Guard: true if user can create/edit/delete
final canWriteProvider = Provider<bool>((ref) {
  return ref.watch(currentUserRoleProvider) != WorkspaceRole.viewer;
});

// Shortcut for active workspace ID
final activeWorkspaceIdProvider = Provider<String?>(...);
```

### Repositories — signature change

```dart
// All repositories now accept workspaceId
// RLS is still the security source of truth —
// workspaceId in queries is for clarity and index usage only.

class ExpenseRepository {
  final String? workspaceId;

  Stream<List<Expense>> watchAll() {
    if (workspaceId != null) {
      return _supabase.from('expenses').stream(...).eq('workspace_id', workspaceId);
    }
    return _supabase.from('expenses').stream(...).eq('user_id', userId);
  }
}
```

### Feature Gating — `FeatureGate` widget (`lib/core/widgets/feature_gate.dart`)

```dart
class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(workspacePlanProvider);
    final allowed = feature.isAllowed(plan);
    if (allowed) return child;
    return fallback ?? _UpgradePrompt(feature: feature);
  }
}

enum PremiumFeature {
  advancedForecasting,
  aiInsights,
  multiWorkspace,
  advancedAnalytics,
  cashflowProjections,
  exportPdf,
  unlimitedInstallments,
  recurringDetection;

  bool isAllowed(WorkspacePlan plan) => switch (this) {
    // Everything free for now — uncomment when monetizing
    _ => true,
  };
}
```

### Workspace Switcher UI

```
WorkspaceAppBarChip  — chip in dashboard AppBar, only visible when >1 workspace
WorkspaceSwitcherSheet — lists workspaces, switch active, go to members, create new
CreateWorkspaceSheet   — name input, creates + auto-switches
InviteMemberSheet      — email + role picker, generates invite link
MembersScreen          — list members, change roles, remove (owner/admin only)
```

---

## 🗺️ Implementation Strategy (phases)

### PHASE 1 — Invisible foundation ✅ COMPLETE (2026-05-09)
**Goal**: Infrastructure created, UX identical for existing users.
**Risk**: Low — nothing breaks, no features removed.

```
1.1 — V26: create workspaces + workspace_members + workspace_invites
1.2 — V27: add workspace_id (nullable) to all tables
1.3 — V28: backfill (personal workspace per user, link data)
1.4 — Verify: COUNT(*) WHERE workspace_id IS NULL = 0 on all tables
1.5 — V29: NOT NULL + indexes
1.6 — V30: update RLS (most critical — tested in staging)
1.7 — V31: fix system categories + auto-populate triggers
1.8 — V32: fix RLS infinite recursion (SECURITY DEFINER helpers)
1.9 — Flutter: Workspace model + WorkspaceMember + WorkspaceRole
1.10 — Flutter: workspaceRepositoryProvider
1.11 — Flutter: activeWorkspaceProvider (auto-selects sole workspace)
1.12 — Flutter: pass workspaceId in all repository calls
```

✅ **Acceptance criterion**: App works exactly the same for solo user.

---

### PHASE 2 — Workspace switcher + invites ✅ COMPLETE (2026-05-09)
**Goal**: User can create and share workspaces.
**Risk**: Medium — new UX, but additive (removes nothing).

```
2.1 — Flutter: WorkspaceSwitcherSheet (AppBar chip tap)
2.2 — Flutter: CreateWorkspaceSheet (name input)
2.3 — Flutter: InviteMemberSheet (email + role selector)
2.4 — Flutter: MembersScreen (list members, change role, remove)
2.5 — Flutter: WorkspaceAppBarChip — workspace badge in AppBar when >1 workspace
2.6 — Flutter: desktop NavRail header shows workspace chip when >1 workspace
```

✅ **Acceptance criterion**: A couple can create a shared workspace, see each other's expenses in real time, and invite via link.

---

### PHASE 3 — Permissions + Feature gating ✅ COMPLETE (2026-05-09)
**Goal**: Fine-grained control of who can do what + freemium infrastructure.
**Risk**: Low — additive.

```
3.1 — Flutter: FeatureGate widget (everything free by default)
3.2 — Flutter: canWriteProvider — guard for viewers
3.3 — Flutter: FABs hidden for viewers (Dashboard, Transactions, Installments, Recurring, Budget, Categories, Accounts)
3.4 — Flutter: swipe-to-delete disabled for viewers
3.5 — Flutter: edit onTap disabled for viewers
3.6 — Flutter: _UpgradePrompt placeholder (for when monetizing)
3.7 — Flutter: PremiumFeature enum with all gates defined
```

✅ **Acceptance criterion**: Viewer can see but not edit. Feature gates exist in code but everything remains unlocked.

---

### PHASE 4 — Monetization (future, when ready)
**Goal**: Activate paywall for premium features.
**Risk**: High for retention — do gradually.

```
4.1 — Integrate Stripe (RevenueCat recommended for Flutter)
4.2 — Stripe webhook → UPDATE workspaces SET plan = 'premium'
4.3 — Enable PremiumFeature.isAllowed() for chosen features
4.4 — PaywallScreen with free vs premium feature table
4.5 — Pricing: R$X/month or R$Y/year per workspace
4.6 — Trial period: 14 days premium for new workspaces
```

---

## 💸 Detailed Freemium Model

### Free (forever)
| Feature | Notes |
|---|---|
| Expense/income tracking | Unlimited |
| Budget by category | Unlimited |
| Main dashboard | Full |
| Custom categories | Unlimited |
| Recurring expenses | Unlimited |
| Installments | Unlimited |
| Offline sync | Full |
| 1 workspace | Personal |

### Premium (when activated)
| Feature | Justification |
|---|---|
| Multiple workspaces | Core sharing feature |
| Workspace members | Collaboration |
| Advanced forecasting | Full cashflow projections |
| AI insights | Intelligence layer |
| PDF/Excel export | Power user feature |
| Priority support | Retention |

---

## 🔒 Security Notes

- **RLS is the security boundary** — workspace_id in queries is for performance only
- **SECURITY DEFINER helpers** — `get_my_workspace_ids*()` bypass RLS safely to prevent self-referential recursion
- **Viewer enforcement** — implemented in Flutter UI (FABs, swipe, onTap) AND enforced at DB level via RLS INSERT/UPDATE/DELETE policies that require writer role
- **Invite tokens** — expire in 7 days, one-use (marked as accepted)
- **Owner cannot be removed** — `workspace_members` DELETE policy allows owner to remove anyone except themselves (handled in UI)
