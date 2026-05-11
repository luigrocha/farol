# ADR: Farol Collaborative Workspace — Full System Design

**Status:** Complete (all 4 phases — 2026-05-10)  
**Date:** 2026-05-10  
**Scope:** UX Architecture · UI Design · Backend Schema · Frontend Providers · Incremental Rollout  
**Author:** CTO Assistant (Senior Product Designer + UX Architect + Software Architect)

---

## Table of Contents

1. [Current System Analysis](#1-current-system-analysis)
2. [Workspace Data Model](#2-workspace-data-model)
3. [UX Flow — Workspace Management](#3-ux-flow--workspace-management)
4. [UX — Collaborative Finance (Core)](#4-ux--collaborative-finance-core)
5. [Hybrid Personal + Shared Model](#5-hybrid-personal--shared-model)
6. [UI Component System](#6-ui-component-system)
7. [Forecasting & Budgets — Shared](#7-forecasting--budgets--shared)
8. [Frontend Architecture (Riverpod)](#8-frontend-architecture-riverpod)
9. [Backend Architecture (Supabase)](#9-backend-architecture-supabase)
10. [Incremental Rollout Strategy](#10-incremental-rollout-strategy)
11. [Anti-Patterns & Risks](#11-anti-patterns--risks)
12. [Competitive Differentiation](#12-competitive-differentiation)

---

## 1. Current System Analysis

### What's already built (Phase 1–3 complete)

| Layer | Status | Notes |
|---|---|---|
| `workspaces` table | ✅ Production (V26) | `owner_id`, `plan`, `settings` |
| `workspace_members` | ✅ Production (V26) | `role`: owner/admin/member/viewer |
| `workspace_invites` | ✅ Production (V26) | Token-based, expirable |
| `workspace_id` on 14 data tables | ✅ Production (V27–V29) | All financial data scoped |
| RLS via SECURITY DEFINER helpers | ✅ Production (V30–V32) | No self-referential recursion |
| `activeWorkspaceProvider` | ✅ Flutter | Persisted in Drift UserSettings |
| `canWriteProvider` | ✅ Flutter | Guards all FABs + delete actions |
| `WorkspaceSwitcherSheet` | ✅ Flutter | List + switch |
| `CreateWorkspaceSheet` | ✅ Flutter | Creates + auto-switches |
| `InviteMemberSheet` | ✅ Flutter | Email + role + copy link |
| `MembersScreen` | ✅ Flutter | List + role change + remove |
| `WorkspaceAppBarChip` | ✅ Flutter | Visible when >1 workspace |

### What's missing (the gap this ADR closes)

| Gap | Impact | Priority |
|---|---|---|
| No workspace **type** (personal vs shared) | UX confusion — users don't know what's "their space" | 🔴 Critical |
| No **context indicator** on financial data | Can't see "whose expense" in shared workspace | 🔴 Critical |
| No **activity feed** | Collaboration feels empty | 🟠 High |
| No **shared vs private toggle** on items | No granularity — everything shared or nothing | 🟠 High |
| No **onboarding flow** for new workspace members | Members land in a blank state | 🟠 High |
| Workspace chip hidden when only 1 workspace | Personal users don't discover the feature | 🟡 Medium |
| No **ownership transfer** UI | Owner locked forever | 🟡 Medium |
| No **workspace avatar / emoji** | All workspaces look the same | 🟡 Medium |
| No **invite via link** deep-link handling | Invites only work if app installed | 🟡 Medium |
| No realtime sync indication | Users don't know when data updates | 🟡 Medium |
| `WorkspacePlan` only has free/premium | No granularity for collaborative features | 🟢 Low |

### UX Risk Map

**Risk 1 — The "Blurred Lines" problem**
When a couple shares a workspace, seeing ALL of each other's transactions creates anxiety. Farol must answer: "Is this MY money or OURS?" from the very first screen. Currently unanswered.

**Risk 2 — The "Invisible Collaborator" problem**
In a shared workspace, if Ana adds a recurring rule and Bruno sees it with no attribution, Bruno doesn't know it's Ana's. This creates confusion and distrust in shared finances.

**Risk 3 — The "Budget Ownership" conflict**
If two members both have write access and both edit the same envelope budget, the last write wins silently. No conflict resolution, no awareness of simultaneous editing.

**Risk 4 — The "Personal Workspace Pollution" risk**
Users will accidentally add personal expenses to the shared workspace (or vice versa). The active workspace must always be visually unmistakable.

**Risk 5 — The "Permission Creep" problem**
Giving everyone member role is too permissive. Giving everyone viewer is too restrictive. The default role at invite time needs to be thoughtfully designed.

---

## 2. Workspace Data Model

### Recommended Schema Extensions

```sql
-- Add to workspaces table
ALTER TABLE workspaces ADD COLUMN IF NOT EXISTS
  workspace_type TEXT NOT NULL DEFAULT 'personal'  -- 'personal' | 'shared'
  CHECK (workspace_type IN ('personal', 'shared'));

ALTER TABLE workspaces ADD COLUMN IF NOT EXISTS
  emoji TEXT DEFAULT '🏠';  -- workspace avatar

ALTER TABLE workspaces ADD COLUMN IF NOT EXISTS
  color TEXT DEFAULT '#2196F3';  -- hex, for visual identity

ALTER TABLE workspaces ADD COLUMN IF NOT EXISTS
  description TEXT;  -- optional tagline: "Eu e Ana · 2024"

-- Add to workspace_members
ALTER TABLE workspace_members ADD COLUMN IF NOT EXISTS
  display_name TEXT;  -- member's chosen name within this workspace

ALTER TABLE workspace_members ADD COLUMN IF NOT EXISTS
  avatar_color TEXT;  -- assigned avatar color for UI (auto or chosen)

ALTER TABLE workspace_members ADD COLUMN IF NOT EXISTS
  notification_prefs JSONB DEFAULT '{}';

-- Financial data authorship
-- Add author_user_id to all financial tables that currently only have workspace_id
-- This enables "who added this" attribution
-- Tables: expenses, incomes, recurring_rules, installment_plans, accounts
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS
  author_user_id UUID REFERENCES auth.users(id);

ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS
  author_user_id UUID REFERENCES auth.users(id);

ALTER TABLE installment_plans ADD COLUMN IF NOT EXISTS
  author_user_id UUID REFERENCES auth.users(id);

-- Activity log
CREATE TABLE IF NOT EXISTS workspace_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL,  -- 'added_expense' | 'edited_budget' | 'added_recurring' | etc.
  entity_type TEXT NOT NULL,  -- 'expense' | 'budget' | 'recurring_rule' | 'account'
  entity_id TEXT,
  entity_label TEXT,  -- denormalized label for display ("Aluguel", "Supermercado", etc.)
  amount NUMERIC,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for workspace feed
CREATE INDEX idx_workspace_activity_ws_time
  ON workspace_activity(workspace_id, created_at DESC);
```

### Role Permission Matrix

| Permission | Owner | Admin | Member | Viewer |
|---|:---:|:---:|:---:|:---:|
| View all financial data | ✅ | ✅ | ✅ | ✅ |
| Add/edit own expenses | ✅ | ✅ | ✅ | ❌ |
| Edit others' expenses | ✅ | ✅ | ❌ | ❌ |
| Delete expenses | ✅ | ✅ | own only | ❌ |
| Manage budgets | ✅ | ✅ | ✅ | ❌ |
| Add/manage accounts | ✅ | ✅ | ✅ | ❌ |
| Manage recurring rules | ✅ | ✅ | ✅ | ❌ |
| Invite members | ✅ | ✅ | ❌ | ❌ |
| Change member roles | ✅ | ✅ | ❌ | ❌ |
| Remove members | ✅ | ✅ | ❌ | ❌ |
| Workspace settings | ✅ | ✅ | ❌ | ❌ |
| Transfer ownership | ✅ | ❌ | ❌ | ❌ |
| Delete workspace | ✅ | ❌ | ❌ | ❌ |

### Workspace Types & Semantics

```
WorkspaceType.personal
  → Always exists (auto-created on signup)
  → Single member = the owner
  → Cannot invite (or can invite family as viewer-only)
  → Label: "My Finances" / "Minhas Finanças"
  → Emoji: 👤 (default, user can change)
  → No attribution UI needed (only one author)

WorkspaceType.shared
  → Created explicitly by user
  → Multi-member
  → Full role system
  → Full attribution / activity feed
  → Label: user-defined ("Ana & Bruno", "Casa", "Viagem NYC")
  → Emoji: user-chosen from curated set
```

### Data Scoping Rules

```
Personal workspace:
  expenses        → only my own
  budgets         → only mine
  recurring_rules → only mine
  accounts        → only mine
  investments     → only mine

Shared workspace:
  expenses        → everyone's, with author_user_id
  budgets         → shared pool (everyone contributes)
  recurring_rules → shared, with author attribution
  accounts        → shared (bank accounts, joint accounts)
  investments     → shared OR personal (configurable per investment)
```

---

## 3. UX Flow — Workspace Management

### 3.1 Workspace Switcher (Primary Entry Point)

**Current state:** `WorkspaceAppBarChip` appears only when >1 workspace. Problem: personal users never discover shared workspaces.

**Recommended change:** Always show the workspace chip in the AppBar, even for personal workspaces. Style it differently based on type.

```
Personal workspace chip:
  [👤 My Finances ▾]   → subdued, grey tint, no dot

Shared workspace chip:
  [🏠 Ana & Bruno ▾]   → colored dot = online members, teal tint
  [🏠 Ana & Bruno • 2 ▾]  → "• 2" = 2 members currently active
```

**Workspace Switcher Sheet — Enhanced Design:**

```
┌─────────────────────────────────────────────┐
│  ─────  (drag handle)                        │
│                                              │
│  Your spaces                                 │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │ 👤  My Finances              ✓ Active   │ │
│  │     Personal · just you                 │ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  Shared spaces                               │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │ 🏠  Ana & Bruno                         │ │
│  │     2 members · Premium                 │ │
│  │     [A] [B]  Ana added R$45 · 2h ago    │ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │ ✈️  NYC Trip                             │ │
│  │     4 members · Free                    │ │
│  │     [A] [C] [D] [+1]  ·  R$120 today   │ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  + Create shared space                       │
│                                              │
└─────────────────────────────────────────────┘
```

**Interaction details:**
- Tap a workspace → immediate switch (optimistic, no loading spinner)
- Long-press → context menu: Settings, Leave workspace
- The last activity line ("Ana added R$45 · 2h ago") is pulled from `workspace_activity`
- Avatar group shows up to 3 member avatars, then "+N"

### 3.2 Create Workspace Flow

```
Step 1 — Choose type
┌──────────────────────────────────────────────┐
│  What kind of space?                         │
│                                              │
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │ 👤           │  │ 👥                   │  │
│  │ Just me      │  │ With others          │  │
│  │              │  │                      │  │
│  │ Private      │  │ Couple, family,      │  │
│  │ finances     │  │ roommates, trip      │  │
│  └──────────────┘  └──────────────────────┘  │
└──────────────────────────────────────────────┘

Step 2 — Name + identity (shared only)
┌──────────────────────────────────────────────┐
│  Name your space                             │
│                                              │
│  Emoji  [🏠 ▾]                               │
│  Name   [Ana & Bruno________________]        │
│  Color  ● ● ● ● ● ●  (6 preset colors)       │
│                                              │
│  Suggestions:                                │
│  "Casa"  "Casal"  "Família"  "Viagem"        │
│                                              │
│  [Create space →]                            │
└──────────────────────────────────────────────┘

Step 3 — Invite (shared only)
┌──────────────────────────────────────────────┐
│  Invite your people                          │
│                                              │
│  [ana@email.com    ] [Member ▾]  [+]         │
│                                              │
│  Or share a link:                            │
│  [farol.app/join/abc123___]  [Copy]          │
│                                              │
│  Link expires in 7 days                      │
│                                              │
│  [Skip for now]        [Send invites →]      │
└──────────────────────────────────────────────┘

Step 4 — Onboarding checklist (post-creation)
┌──────────────────────────────────────────────┐
│  🎉 Space created!                           │
│                                              │
│  Set up "Ana & Bruno" together:              │
│                                              │
│  ○ Add your accounts                         │
│  ○ Set a monthly budget                      │
│  ○ Add recurring bills                       │
│  ○ Invite Ana  ← (if not done in step 3)    │
│                                              │
│  [Go to dashboard →]                         │
└──────────────────────────────────────────────┘
```

### 3.3 Accept Invitation Flow

**Deep link:** `farol.app/join/{token}`

```
Not installed → App Store → install → re-open link → handled

Installed, not logged in → login → redirect to invite

Installed, logged in → direct to invite screen:

┌──────────────────────────────────────────────┐
│                                              │
│  🏠                                          │
│                                              │
│  Bruno invited you to                        │
│  "Ana & Bruno"                               │
│                                              │
│  Bruno Santos · 2 members · Free plan        │
│                                              │
│  Your role: Member                           │
│  (you can add and edit expenses)             │
│                                              │
│  [Accept invitation]                         │
│  [Decline]                                   │
│                                              │
└──────────────────────────────────────────────┘
```

**After accepting:** Auto-switch to the new workspace + show the onboarding checklist for new members.

### 3.4 Workspace Settings Screen

```
┌──────────────────────────────────────────────┐
│  ← Ana & Bruno · Settings                   │
│                                              │
│  SPACE                                       │
│  [🏠] Name: Ana & Bruno          [Edit]      │
│       Color: ●                               │
│       Plan: Free                  [Upgrade]  │
│                                              │
│  MEMBERS  (2)                                │
│  [B] Bruno Santos  Owner  (you)             │
│  [A] Ana Lima      Member         [▾]        │
│       ├ Promote to Admin                     │
│       ├ Change to Viewer                     │
│       └ Remove from space                    │
│                                              │
│  [+ Invite someone]                          │
│                                              │
│  DANGER ZONE                                 │
│  [Transfer ownership]                        │
│  [Leave this space]      (not owner)         │
│  [Delete this space]     (owner only)        │
│                                              │
└──────────────────────────────────────────────┘
```

### 3.5 Edge Cases

**Leaving a workspace (non-owner):**
→ Confirmation sheet: "You'll lose access to all data in this space. Your personal space won't be affected."
→ On confirm: switch to personal workspace immediately.

**Owner leaving:**
→ Blocked. Must transfer ownership first or delete the workspace.

**Transfer ownership:**
→ Select new owner from member list (admin or member only)
→ Double confirmation: "You'll become an Admin. {Name} will become the new Owner."
→ Cannot be undone without their cooperation.

**Workspace deletion:**
→ Type workspace name to confirm (Notion-style)
→ Warning: all data permanently deleted, members lose access
→ Soft delete with 30-day recovery window

**Expired invite:**
→ Show expired screen with option to request a new invite
→ Owner gets notified to re-invite

---

## 4. UX — Collaborative Finance (Core)

### 4.1 The Fundamental UX Principle

> "Farol shared is not Splitwise. It's not about splitting bills. It's about having one financial brain for two people — with zero confusion about who did what."

Every piece of financial data in a shared workspace needs to answer three questions instantly:
1. **What** — the transaction/budget/rule
2. **Who** — which member added/owns it
3. **When** — recency matters in collaboration

### 4.2 Attribution System

All financial items in shared workspaces show a **member chip** — a small colored avatar + name abbreviation.

```dart
// MemberChip widget — used everywhere in shared workspaces
class MemberChip extends StatelessWidget {
  // Shows: [A] or [A] Ana  depending on size
  // Color: member's avatar_color from workspace_members
  // Tappable: shows member profile sheet
}
```

**Usage in transaction list:**
```
┌─────────────────────────────────────────────┐
│  📅 Hoje                                    │
│                                             │
│  🍽️ iFood                      R$ 45,90    │
│  Alimentação · Débito    [A] Ana · 14h      │
│                                             │
│  🏠 Aluguel               R$ 2.200,00      │
│  Moradia · PIX            [B] Você · 09h   │
│                                             │
│  📅 Ontem                                   │
│                                             │
│  🛒 Pão de Açúcar            R$ 187,40    │
│  Supermercado             [A] Ana · 18h    │
│                                             │
└─────────────────────────────────────────────┘
```

**Rule:** In personal workspace, never show member chip. Only in shared workspaces.

### 4.3 Dashboard — Shared View

The dashboard in a shared workspace needs a **"Together" view**, not just a sum of two people's data.

```
┌─────────────────────────────────────────────┐
│  [🏠 Ana & Bruno ▾]        [Settings]       │
│                                             │
│  ── Maio 2026 ──────────────────────────── │
│                                             │
│  SALDO DO PERÍODO                           │
│  R$ 1.840                                   │
│  R$ 5.200 receitas · R$ 3.360 gastos        │
│                                             │
│  QUEM GASTOU MAIS                           │
│  [B] Bruno  R$ 2.100  ████████░░  63%       │
│  [A] Ana    R$ 1.260  █████░░░░░  37%       │
│                                             │
│  ORÇAMENTOS ──────────────────────────────  │
│  Moradia     R$ 2.200 / 2.500  ███████░░░  │
│  Alimentação R$   780 / 1.000  ████████░░  │
│  ...                                        │
│                                             │
│  ATIVIDADE RECENTE ───────────────────────  │
│  [A] Ana adicionou Uber  R$ 32 · 1h atrás  │
│  [B] Você adicionou iFood R$ 45 · 3h atrás │
│  [A] Ana ajustou orçamento Lazer · ontem   │
│  [Ver tudo]                                 │
│                                             │
└─────────────────────────────────────────────┘
```

**"Quem gastou mais" bar:** Not accusatory — framed as contribution visibility, not judgment. Shows relative contribution to shared expenses. Color-coded by member avatar color.

### 4.4 Activity Feed

The activity feed is the **heartbeat of collaborative finance** — it replaces the need to "ask your partner if they paid X."

```
┌─────────────────────────────────────────────┐
│  ← Atividade  (Ana & Bruno)                 │
│                                             │
│  Hoje                                       │
│  ─────                                      │
│  [A] Ana adicionou                 2h atrás │
│      🍽️ iFood  R$ 45,90                     │
│      Alimentação · Débito                   │
│                                             │
│  [B] Você adicionou               3h atrás  │
│      🏠 Aluguel  R$ 2.200                   │
│      Moradia · PIX                          │
│                                             │
│  Ontem                                      │
│  ──────                                     │
│  [A] Ana editou orçamento         18h atrás │
│      Lazer: R$ 400 → R$ 600                 │
│                                             │
│  [B] Você adicionou               20h atrás │
│      🔁 Netflix (recorrente)                │
│      R$ 55,90 / mês                         │
│                                             │
└─────────────────────────────────────────────┘
```

**Design principles for activity feed:**
- "Você" (you) always displayed in second person → less clinical
- Other members shown by first name
- Amount always visible inline
- Category icon for instant recognition
- No "actions" in the feed (it's read-only audit, not a task list)
- Grouped by day
- Lazy-loaded, infinite scroll

### 4.5 What's Private vs Shared

**Rule: Data follows the workspace. The workspace IS the boundary.**

```
Personal Workspace ("My Finances")
  → EVERYTHING here is private by default
  → No member can see it
  → No indicator needed ("everything here is mine")

Shared Workspace ("Ana & Bruno")
  → EVERYTHING here is visible to all members
  → Attribution shows who added it
  → This is the explicit shared space
```

**No per-item privacy within a shared workspace.** This is by design. If you want something private, use your personal workspace. Mixing private and shared within the same space creates the exact confusion we want to avoid.

**The one exception — Investments (future):**
A `visibility` field on `investments` table can be `'shared' | 'private'`. Investments are emotionally sensitive enough to warrant this exception. But Phase 4+ only.

### 4.6 Couple / Family / Roommates — Specific Flows

**Couple ("Ana & Bruno") — Primary use case:**

```
Mental model: "One financial brain, two hands"
- Both can add expenses without asking permission
- Both see the same forecasted balance
- Budget management is collaborative
- Neither is "in charge" by default (both are co-owners or owner+admin)

Recommended roles: Owner (creator) + Admin (partner)
No viewers, no read-only partner
```

**Roommates ("Casa Itaim") — Secondary use case:**

```
Mental model: "Shared bills, separate lives"
- Shared accounts for house bills
- Each adds their own contribution
- Dashboard shows house expenses + who paid what
- Personal expenses NOT in this workspace

Recommended setup:
- Owner = whoever set it up
- All others = Member
- Budgets: only for shared bills (rent, internet, gas)
```

**Trip group ("NYC 2026") — Tertiary use case:**

```
Mental model: "Temporary shared pool"
- Created for duration of trip
- All expenses added here
- Settlement calculated at the end (future feature)
- Archived after trip

Recommended setup:
- Owner = trip organizer
- All = Member
- Time-bounded: workspace has optional end_date
```

### 4.7 Budget Collaboration UX

When opening the Budget screen in a shared workspace:

```
┌─────────────────────────────────────────────┐
│  ← Orçamento  Maio 2026  (Ana & Bruno)      │
│                                             │
│  R$ 3.360 gastos de R$ 5.000 orçados  67%  │
│  ████████████████████░░░░░░░░░░░░░░░░░░     │
│                                             │
│  ENVELOPES ────────────────────────────── │
│                                             │
│  🏠 Moradia                                 │
│  R$ 2.200 / R$ 2.500  ██████████████░░  88%│
│  Último ajuste: você · 5 dias atrás        │
│                                        [▸] │
│                                             │
│  🛒 Alimentação                             │
│  R$ 780 / R$ 1.000  ████████░░░░░░░░  78% │
│  Último ajuste: Ana · ontem                │
│                                        [▸] │
│                                             │
│  🎬 Lazer                                   │
│  R$ 420 / R$ 600  ██████░░░░░░░░░░░░  70% │
│  Último ajuste: Ana · 3 dias atrás         │
│                                        [▸] │
│                                             │
└─────────────────────────────────────────────┘
```

**Key additions vs. personal budget:**
- "Último ajuste: [member] · [time]" on each envelope — instant accountability
- Budget edit shows who last changed it + the before/after
- Budget changes logged in `workspace_activity`

---

## 5. Hybrid Personal + Shared Model

### 5.1 Model Overview

```
User
├── Personal Workspace (always exists, private)
│   ├── Personal expenses
│   ├── Personal investments
│   ├── Personal goals
│   ├── Personal salary configuration
│   └── Personal recurring (Netflix, gym)
│
└── Shared Workspace(s) (optional, user-created)
    ├── Shared expenses (with attribution)
    ├── Shared accounts (joint bank account)
    ├── Shared budgets (house budget)
    ├── Shared recurring (rent, internet)
    └── Shared goals (vacation fund, car fund)
```

### 5.2 The Workspace Context Bar

In the app, the active workspace is always surfaced at the top of the AppBar. The visual design signals which "mode" the user is in:

```
Personal mode:
┌──────────────────────────────────────────┐
│ [👤 My Finances]    🔔    [avatar]       │
│ (grey chip, no member dot)               │
└──────────────────────────────────────────┘

Shared mode:
┌──────────────────────────────────────────┐
│ [🏠 Ana & Bruno •]  🔔    [avatar]       │
│ (teal chip, dot = active members)        │
└──────────────────────────────────────────┘
```

The dot in shared mode is a **live presence indicator** (Supabase Realtime Presence) — shows how many members are currently in the app. Like a Google Docs "N people editing" indicator.

### 5.3 Advantages of This Model

**For the user:**
- No cognitive overload — clear mental model: "Personal = mine, Shared = ours"
- No accidental data leaks between contexts
- Switching feels like switching tabs in a browser — instant, clear
- Can have multiple shared workspaces simultaneously (couple + family + trip)

**For the product:**
- Monetization: shared workspaces = premium feature (more than 1 shared space, or unlimited members)
- Viral growth: inviting a partner = new user acquisition
- Retention: users with shared workspaces churn far less (social lock-in)
- Differentiation: not "splitting bills" but "shared financial planning"

### 5.4 Complexity Trade-offs

| Scenario | Complexity | UX Risk | Mitigation |
|---|---|---|---|
| User in 1 workspace | Low | None | Default flow unchanged |
| User with 1 personal + 1 shared | Medium | Accidental context switch | Always-visible workspace chip |
| User with 3+ workspaces | High | Paralysis / wrong context | Clear workspace switcher with previews |
| New member in shared workspace | Medium | Empty state confusion | Guided onboarding checklist |
| Owner leaves | High | Data loss | Transfer ownership gate |

---

## 6. UI Component System

All components below extend the existing Farol design system. They use `FarolColors`, `FarolTheme`, and `GoogleFonts.manrope`. No new design language is introduced.

### 6.1 WorkspaceChip (AppBar)

```dart
class WorkspaceChip extends StatelessWidget {
  // Always visible in AppBar
  // Personal: grey background, 👤 emoji, no dot
  // Shared: color-tinted background, workspace emoji, activity dot
  // Tap → WorkspaceSwitcherSheet
  
  // Sizing: compact (AppBar height constraint)
  // Max width: 160px (truncate with ellipsis)
  // Animated: slides + fades on workspace switch
}
```

**Visual spec:**
```
Personal:  [👤 My Finances ▾]   background: colors.surfaceLow
Shared:    [🏠 Ana & Bruno ▾]  background: workspaceColor.withOpacity(0.12)
                               border: workspaceColor.withOpacity(0.3)
Dot:       10px circle, color: Color(0xFF00C48C), positioned top-right of chip
```

### 6.2 MemberAvatarGroup

```dart
class MemberAvatarGroup extends StatelessWidget {
  // Shows up to maxVisible avatars (default 3)
  // Remaining count: "+N" grey circle
  // Each avatar: colored circle with initials
  // Colors: deterministic from userId hash → consistent across sessions
  // Size variants: small (24px), medium (32px), large (40px)
  
  // Usage:
  // - WorkspaceSwitcherSheet (medium)
  // - ActivityFeed (medium)
  // - MembersScreen (large)
  // - Dashboard contribution bar (small)
}
```

### 6.3 MemberChip (Attribution)

```dart
class MemberChip extends StatelessWidget {
  // Compact: [A] 24px colored circle + optional name
  // Variants:
  //   compact: just circle + 1 letter  (in transaction lists)
  //   labeled: circle + first name     (in detail screens)
  //   full:    circle + full name      (in settings)
  // "You" variant: slightly different styling (second-person)
  
  // Only rendered when workspace.isShared
  // Never rendered in personal workspace
}
```

### 6.4 SharedBadge

```dart
class SharedBadge extends StatelessWidget {
  // Tiny pill: "Compartilhado" or just a 👥 icon
  // Used on:
  //   - accounts that are joint
  //   - recurring rules that apply to shared workspace
  //   - budget goals that are shared
  // Color: uses colors.iconTintBlue background
}
```

### 6.5 WorkspaceContextBanner

```dart
class WorkspaceContextBanner extends StatelessWidget {
  // Shown at top of screen ONLY when in a shared workspace
  // Compact 28px bar with workspace emoji + name + member count
  // Appears in: Transactions, Budget, Recurring, Installments, Analytics
  // Does NOT appear in: Dashboard (workspace chip in AppBar is enough)
  // NOT sticky — scrolls away with content
  
  // Example:
  // [🏠 Ana & Bruno  👤 2 membros]
}
```

### 6.6 ActivityFeedTile

```dart
class ActivityFeedTile extends StatelessWidget {
  // One item in the activity feed
  // Layout: [MemberChip] [action text] [time]
  //                      [entity label + amount]
  // Category icon on the right
  // Tap: navigates to the relevant entity (expense, budget, etc.)
  // "Você" vs member name logic built-in
}
```

### 6.7 ContributionBar

```dart
class ContributionBar extends StatelessWidget {
  // Shows each member's spending % in the period
  // Layout: segmented horizontal bar
  // Each segment: member's avatar_color + percentage
  // Labels below: [A] Bruno 63% · [B] Ana 37%
  // Only shown in shared workspaces with ≥2 members who have expenses
  // Not shown if one member has 0 expenses (avoids awkward 0% display)
}
```

### 6.8 Workspace Onboarding Checklist

```dart
class WorkspaceOnboardingCard extends StatelessWidget {
  // Shown on dashboard after creating a shared workspace
  // Persisted in Drift UserSettings per workspace
  // Steps: add accounts, set budget, add recurring, invite partner
  // Each step: check icon when complete, tap to navigate
  // Dismissable after all steps complete (or after 7 days)
  // Visual: card with progress indicator at top
}
```

---

## 7. Forecasting & Budgets — Shared

### 7.1 Shared Forecasting

The `ForecastingEngine` and `CashflowForecastProvider` are currently workspace-scoped — they query expenses and recurring rules filtered by `workspace_id`. This means they already work correctly in shared workspaces without changes.

**What needs enhancement:**

**Member breakdown in projections:**
```dart
class FinancialProjection {
  // Add: Map<String, Money> projectedByMember
  // Key: userId, Value: projected spending
  // Computed by ForecastingEngine when workspace has multiple members
  // Used in dashboard ContributionBar (projected vs actual)
}
```

**Shared recurring rules:**
- Currently `recurring_rules` has `author_user_id`
- In shared workspace: rules created by any member appear in the shared forecast
- The `RecurringDetector` already scans all expenses in the workspace
- **Risk:** two members adding the same recurring (e.g., both add Netflix)
  - **Mitigation:** duplicate detection in `RecurringDetector` already exists
  - **Enhancement:** show "Similar rule exists" warning when adding in shared workspace

### 7.2 Budget Ownership in Shared Workspaces

**Current model:** Budgets are per-workspace, no per-member breakdown.

**Recommendation:** Keep budgets as shared pool. Do NOT split budgets by member. Rationale:
- Couple sharing a house has ONE budget for rent, ONE for groceries
- Splitting creates friction: "whose budget was exceeded?"
- Instead, use the ContributionBar to show who spent what WITHIN a shared budget

**Budget edit audit trail:**
```sql
-- budget_changes table (lightweight audit)
CREATE TABLE budget_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL,
  category_slug TEXT NOT NULL,
  old_amount NUMERIC,
  new_amount NUMERIC,
  changed_by UUID REFERENCES auth.users(id),
  changed_at TIMESTAMPTZ DEFAULT NOW()
);
```

This powers the "Último ajuste: Ana · ontem" display in budget envelopes.

### 7.3 Shared Accounts

Accounts in a shared workspace represent joint or shared accounts:

```
Personal workspace:
  Bradesco Corrente (personal checking)
  XP Investimentos  (personal investment)

Shared workspace "Ana & Bruno":
  Nubank Corrente Conjunto  (joint)
  Fundo de Emergência       (shared savings goal)
```

**Balance attribution:**
When an account is shared, the balance belongs to the workspace (not a member). No per-member balance split needed. Transfers between accounts work the same as today.

### 7.4 Shared Installments

`InstallmentPlan` in shared workspace has `author_user_id`. In the installments screen:

```
┌─────────────────────────────────────────────┐
│  TV Samsung 55"                             │
│  R$ 280/mês · 3 de 12 pagas                 │
│  [A] Ana · adicionado 45 dias atrás         │
└─────────────────────────────────────────────┘
```

When registering/skipping a payment, the `author_user_id` of the payment action is logged to `workspace_activity`.

---

## 8. Frontend Architecture (Riverpod)

### 8.1 Provider Dependency Graph

```
Supabase.auth ──► currentUserProvider (simple Provider<User?>)
                  │
                  ▼
workspaceRepositoryProvider
                  │
                  ▼
userWorkspacesProvider (FutureProvider, autoDispose)
                  │
                  ▼
activeWorkspaceProvider (AsyncNotifierProvider — persisted in Drift)
      │
      ├──► activeWorkspaceIdProvider (Provider<String?>) — shortcut
      │
      ├──► workspacePlanProvider (Provider<WorkspacePlan>)
      │
      ├──► currentUserRoleProvider (Provider<WorkspaceRole>)
      │
      ├──► canWriteProvider (Provider<bool>)
      │
      └──► workspaceTypeProvider (Provider<WorkspaceType>)  ← NEW
                  │
                  ▼
            isSharedWorkspaceProvider (Provider<bool>)  ← NEW
                  │
           used by all attribution/activity providers
```

### 8.2 New Providers Required

```dart
// workspace_providers.dart additions

// Type of active workspace
final workspaceTypeProvider = Provider<WorkspaceType>((ref) {
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  return ws?.type ?? WorkspaceType.personal;
});

// Is the active workspace shared?
final isSharedWorkspaceProvider = Provider<bool>((ref) {
  return ref.watch(workspaceTypeProvider) == WorkspaceType.shared;
});

// Members of active workspace (for attribution UI)
final activeWorkspaceMembersProvider = Provider<List<WorkspaceMember>>((ref) {
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  return ws?.members ?? [];
});

// Member display map: userId → display info
final memberDisplayMapProvider = Provider<Map<String, MemberDisplay>>((ref) {
  final members = ref.watch(activeWorkspaceMembersProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  return {
    for (final m in members)
      m.userId: MemberDisplay(
        userId: m.userId,
        displayName: m.userId == currentUserId ? 'Você' : m.displayName,
        avatarColor: m.avatarColor,
        initials: m.initials,
      )
  };
});

// Activity feed for active workspace
final workspaceActivityProvider = AsyncNotifierProvider
    .autoDispose<WorkspaceActivityNotifier, List<WorkspaceActivity>>(
  WorkspaceActivityNotifier.new,
);

// Workspace-level presence (realtime)
final workspacePresenceProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final wsId = ref.watch(activeWorkspaceIdProvider);
  if (wsId == null) return const Stream.empty();
  // Supabase Realtime Presence channel
  return _presenceStream(wsId);
});

// Contribution breakdown (who spent what this period)
final memberContributionProvider = FutureProvider.autoDispose<
    List<MemberContribution>>((ref) async {
  final snapshot = await ref.watch(financialSnapshotProvider.future);
  final memberMap = ref.watch(memberDisplayMapProvider);
  // Groups snapshot.expenses by author_user_id
  // Returns sorted by amount desc
  return _computeContributions(snapshot, memberMap);
});
```

### 8.3 Invalidation Strategy

When workspace switches:
```dart
// WorkspaceNotifier.select() — on workspace switch, invalidate ALL data
Future<void> select(Workspace workspace) async {
  await db.setSetting(_key, workspace.id);
  state = AsyncData(workspace);
  
  // Cascade invalidation — clears all workspace-scoped data
  ref.invalidate(financialSnapshotProvider);
  ref.invalidate(insightsProvider);
  ref.invalidate(cashflowForecastProvider);
  ref.invalidate(categoriesRefProvider);
  ref.invalidate(recurringRulesStreamProvider);
  ref.invalidate(installmentPlansStreamProvider);
  ref.invalidate(workspaceActivityProvider);
  // ... all other workspace-scoped providers
}
```

### 8.4 Optimistic UI for Expense Addition

```dart
// In AddExpenseSheet — optimistic update
Future<void> _saveExpense() async {
  final optimisticExpense = Expense(
    id: -1,  // temp id
    author_user_id: currentUserId,
    workspace_id: activeWorkspaceId,
    // ... other fields
  );
  
  // 1. Immediately update local cache (optimistic)
  ref.read(expensesCacheNotifier.notifier).addOptimistic(optimisticExpense);
  
  // 2. Close sheet immediately (no waiting)
  Navigator.pop(context);
  
  // 3. Persist to Supabase in background
  try {
    final saved = await expenseRepo.create(optimisticExpense);
    ref.read(expensesCacheNotifier.notifier).confirmOptimistic(saved);
    // Log to workspace_activity
  } catch (e) {
    ref.read(expensesCacheNotifier.notifier).revertOptimistic(optimisticExpense);
    // Show error snackbar
  }
}
```

### 8.5 Realtime Collaboration

```dart
// WorkspaceRealtimeService — registers on app start
class WorkspaceRealtimeService {
  RealtimeChannel? _channel;
  
  void subscribe(String workspaceId, WidgetRef ref) {
    _channel = Supabase.instance.client
        .channel('workspace:$workspaceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'workspace_id',
            value: workspaceId,
          ),
          callback: (_) {
            ref.invalidate(financialSnapshotProvider);
            ref.invalidate(workspaceActivityProvider);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'period_budgets',
          callback: (_) => ref.invalidate(financialSnapshotProvider),
        )
        .subscribe();
  }
  
  void unsubscribe() => _channel?.unsubscribe();
}
```

---

## 9. Backend Architecture (Supabase)

### 9.1 RLS Strategy (extending current)

Current pattern: SECURITY DEFINER helper functions to avoid recursion. This pattern is correct. Extend it:

```sql
-- New helper: get my shared workspace ids only
CREATE OR REPLACE FUNCTION get_my_shared_workspace_ids()
RETURNS UUID[]
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT ARRAY_AGG(w.id)
  FROM workspaces w
  JOIN workspace_members wm ON wm.workspace_id = w.id
  WHERE wm.user_id = auth.uid()
    AND w.workspace_type = 'shared';
$$;

-- workspace_activity RLS
ALTER TABLE workspace_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members can read activity"
  ON workspace_activity FOR SELECT
  USING (workspace_id = ANY(get_my_workspace_ids()));

CREATE POLICY "members can write activity"
  ON workspace_activity FOR INSERT
  WITH CHECK (
    workspace_id = ANY(get_my_workspace_ids_as_writer())
    AND user_id = auth.uid()
  );

-- author_user_id protection: can only set your own
CREATE POLICY "author must be self"
  ON expenses FOR INSERT
  WITH CHECK (
    author_user_id = auth.uid()
    AND workspace_id = ANY(get_my_workspace_ids_as_writer())
  );
```

### 9.2 Supabase Edge Functions

```
/functions/accept-workspace-invite
  → Validates token, checks expiry, creates workspace_member row
  → Returns workspace data for immediate switch
  → Handles both logged-in and not-logged-in cases

/functions/transfer-ownership
  → Validates requester is owner
  → Atomically: set new member to owner, set old owner to admin
  → Logs to workspace_activity

/functions/log-activity  
  → Called by triggers on expenses, budgets, recurring_rules
  → Denormalizes entity_label, amount into workspace_activity
  → Avoids N+1 queries in the activity feed
```

### 9.3 Database Triggers for Activity Logging

```sql
-- Auto-log expense creation to workspace_activity
CREATE OR REPLACE FUNCTION log_expense_activity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO workspace_activity
      (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
    VALUES
      (NEW.workspace_id, NEW.author_user_id,
       'added_expense', 'expense', NEW.id::TEXT,
       COALESCE(NEW.store_description, NEW.category), NEW.amount);
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO workspace_activity
      (workspace_id, user_id, action, entity_type, entity_id, entity_label, amount)
    VALUES
      (OLD.workspace_id, auth.uid(),
       'deleted_expense', 'expense', OLD.id::TEXT,
       COALESCE(OLD.store_description, OLD.category), OLD.amount);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_expense_activity
  AFTER INSERT OR DELETE ON expenses
  FOR EACH ROW EXECUTE FUNCTION log_expense_activity();
```

### 9.4 Migration Strategy

```sql
-- V33: workspace_type + emoji + color on workspaces
-- V34: author_user_id on expenses, recurring_rules, installment_plans
-- V35: workspace_activity table + triggers
-- V36: budget_changes table
-- V37: member display_name + avatar_color on workspace_members
-- V38: backfill author_user_id = user_id on existing rows
```

**V38 backfill is safe:** existing data has `user_id` (the owner) — we set `author_user_id = user_id` for all existing rows. For personal workspaces, there's only ever one user so attribution is trivially correct.

---

## 10. Incremental Rollout Strategy

### Phase 1 — Foundation Polish (1–2 weeks) — LOW RISK

**Goal:** Make the existing multi-workspace system feel polished, not half-built.

Tasks:
- [x] Always show WorkspaceChip in AppBar (not just when >1 workspace) — 2026-05-10
- [x] Add workspace emoji + color fields (V33 migration) — 2026-05-10
- [x] Emoji picker in CreateWorkspaceSheet — 2026-05-10
- [x] Add workspace type (personal vs shared) — V33 — 2026-05-10
- [x] WorkspaceSwitcherSheet redesign: "Your space" / "Shared spaces" sections — 2026-05-10
- [x] WorkspaceChip: teal tint for shared, grey for personal — 2026-05-10
- [x] Personal workspace auto-named via trigger (V33 updates `create_personal_workspace()` with emoji 🏠) — 2026-05-10
- [ ] Workspace onboarding checklist after creation (Drift-persisted per workspace)
- [ ] Deep-link handling for invite tokens (farol.app/join/{token})

**Risk:** Very low. All UI-only changes + one simple migration.  
**ROI:** High. Transforms existing feature from "raw" to "polished".

---

### Phase 2 — Attribution System (2–3 weeks) — LOW-MEDIUM RISK

**Goal:** Every shared workspace item shows who did what.

Tasks:
- [x] V34: Add `author_user_id` to expenses, recurring_rules, installment_plans
- [x] V34: Backfill author_user_id (SET author_user_id = user_id)
- [x] Flutter: `memberDisplayMapProvider`
- [x] `MemberChip` widget (compact + labeled variants)
- [x] `MemberAvatarGroup` widget
- [x] `isSharedWorkspaceProvider`
- [x] Attribution in TransactionsScreen (only in shared workspaces)
- [x] Attribution in InstallmentsScreen
- [x] Attribution in RecurringScreen
- [x] `ContributionBar` on Dashboard (shared workspaces only)

**Risk:** Low. Additive — new columns, new widgets. Nothing changes for personal workspaces.  
**ROI:** High. This is the single most visible collaborative feature.

---

### Phase 3 — Activity Feed (2–3 weeks) — MEDIUM RISK

**Goal:** The "heartbeat" of collaborative finance.

Tasks:
- [x] V35: `workspace_activity` table + RLS + triggers (expenses, recurring_rules, installment_plans)
- [x] V36: `budget_changes` table + RLS
- [x] `WorkspaceActivityRepository` + `latestWorkspaceActivityProvider` + `workspaceActivityFirstPageProvider`
- [x] `ActivityFeedTile` widget (avatar, action line, entity label + amount, time ago)
- [x] `ActivityFeedScreen` — full page, day-grouped, infinite scroll, pull-to-refresh
- [x] `ActivityFeedPreviewCard` on Dashboard (last 3 items + "See all" → ActivityFeedScreen)
- [x] `BudgetChangesRepository` + `budgetChangesProvider`
- [x] Budget edit logging in `BudgetEditSheet.upsert()` (shared workspaces only)
- [x] `_BudgetLastEditLine` widget on each envelope tile — "Último ajuste: Ana · ontem"

**Risk:** Medium. Database triggers need testing. Activity feed query needs pagination.  
**ROI:** Very high. Core collaborative UX — this is what differentiates Farol.

---

### Phase 4 — Realtime + Presence (3–4 weeks) — HIGH RISK

**Goal:** Live collaboration — see when your partner is using the app, see their changes instantly.

Tasks:
- [x] Supabase Realtime channel per workspace (`workspace:{workspaceId}`)
- [x] `WorkspaceRealtimeService` singleton — managed by MainShell lifecycle observer
- [x] `workspacePresenceProvider` — StreamProvider<Set<String>> of online user IDs
- [x] Presence dot on WorkspaceAppBarChip (green dot when co-members online)
- [x] `workspaceActivityRealtimeProvider` — invalidates latestWorkspaceActivityProvider on INSERT
- [x] Edge Function: `accept-workspace-invite` — validates token, creates member, returns workspace
- [x] Edge Function: `transfer-ownership` — atomic owner swap with activity log
- [ ] Optimistic UI for expense creation (deferred — last-write-wins + attribution is sufficient)
- [ ] Conflict detection for budget simultaneous edits (deferred — audit trail handles this)

**Risk:** High. Realtime introduces connection management, reconnection, and race conditions.  
**ROI:** High. This is the "wow" moment in demos.

---

## 11. Anti-Patterns & Risks

### 11.1 What NOT To Do

**❌ Don't build per-item privacy within a shared workspace**  
"Mark this expense as private" sounds like a good idea. It's not. It creates a trust problem: "Is my partner hiding expenses from me?" The workspace IS the privacy boundary.

**❌ Don't show financial comparison as competition**  
"You spent 63% and your partner 37%" needs careful framing. Never frame it as "you overspent" or "Bruno is better." Frame it as "contribution visibility," not judgment.

**❌ Don't implement a Splitwise-style debt/settlement system in Phase 1**  
It's complex, emotionally loaded, and out of scope. Farol is about financial planning, not accounting for who owes whom.

**❌ Don't require real-time presence for the app to work**  
Presence is enhancement, not core. The app must be fully functional offline or with no realtime connection.

**❌ Don't over-engineer role permissions**  
Four roles (Owner, Admin, Member, Viewer) is the right number. Don't add granular per-feature permissions ("can edit budget but not delete expenses"). It's impossible to explain in the UI.

**❌ Don't auto-merge personal and shared categories**  
Categories are per-workspace. If the personal workspace has "Academia" and the shared workspace doesn't, that's fine. Don't try to sync or merge categories across workspaces.

**❌ Don't build simultaneous editing conflict resolution**  
Google Docs-style conflict resolution is engineering overkill for a finance app. Last-write-wins with attribution ("Ana updated this 2 minutes ago") is sufficient and honest.

### 11.2 Emotional / Privacy Risks in Shared Finance

**Risk: Transparency anxiety**  
Some users will be uncomfortable with a partner seeing ALL transactions. The solution is clear onboarding: "Everything you add here is visible to everyone in this space. Use your personal space for private expenses."

**Risk: Contribution imbalance awkwardness**  
The ContributionBar (63% / 37%) can cause friction. Solution: make it a neutral data point, not a verdict. "Here's how spending breaks down this month" not "Bruno spent twice as much as Ana."

**Risk: Unilateral budget changes**  
In a shared workspace, any Member can change a budget envelope. This can cause conflict. Solution: the budget change audit trail ("Ana changed Lazer: R$400 → R$600") makes changes visible and accountable, reducing silent resentment.

**Risk: Accidental workspace context**  
User adds a personal expense to the shared workspace (or vice versa). Solution: always-visible workspace chip + a persistent `WorkspaceContextBanner` inside screens (not just AppBar).

### 11.3 Technical Risks

**Risk: N+1 queries in activity feed**  
Fetching activity + member details + expense details = N+1. Solution: denormalized `entity_label` and `amount` in `workspace_activity`. Also: load members once into `memberDisplayMapProvider`.

**Risk: Realtime subscription leaks**  
Supabase channels not properly unsubscribed on widget disposal. Solution: `WorkspaceRealtimeService` managed at app lifecycle level, not widget level.

**Risk: Author attribution lost on migration**  
V38 backfill sets `author_user_id = user_id`. For single-user workspaces this is correct. For shared workspaces that existed before V34... they didn't exist (workspace sharing is new), so this is safe.

---

## 12. Competitive Differentiation

### 12.1 How Farol Will Feel

After implementing Phases 1–3:

> "It's like having a shared financial calendar that updates itself. Ana adds the groceries, Bruno adds the rent, and when either of them opens Farol, the picture is complete — with no WhatsApp messages asking 'did you pay the internet?'"

The emotional job-to-be-done is not "track shared expenses." It's **"stop having money conversations that turn into arguments."** Farol does this by making financial reality visible and unambiguous to both people simultaneously.

### 12.2 Competitive Map

| App | Approach | Farol Advantage |
|---|---|---|
| **Splitwise** | Debt tracking, who owes whom | Farol: full financial picture, not just splits. Budgets, forecasting, recurring — not just IOUs |
| **YNAB Family** | Budget-centric, envelope method | Farol: Brazilian-specific (CLT, FGTS, Swile, 13th salary), cutoff day, more intuitive mobile UX |
| **Monarch** | Beautiful US personal finance | Farol: collaborative from the ground up, not bolted on. PT-BR native |
| **Copilot** | Premium iOS, AI-powered | Farol: Android-first, multi-platform, collaborative architecture is first-class |
| **Mobills / Organizze** | Brazilian, established | Farol: modern architecture, genuine collaboration (not just shared login), forecasting engine |

### 12.3 The Real Moat

Farol's competitive advantage in the collaborative space is **not the feature list**. It's the combination of:

1. **Brazilian-specific finance** (CLT, FGTS, Swile, cutoff day, installments) — no one else does this well
2. **Genuine forecasting** — the `IntelligenceLayer` + `ForecastingEngine` is technically ahead of Mobills/Organizze
3. **Design quality** — Farol's UI is the only Brazilian personal finance app that feels modern and intentional
4. **Collaborative architecture** — workspace model is designed correctly, not as an afterthought

The collaborative workspace system transforms Farol from "a budgeting app for individuals" into **"the financial operating system for Brazilian households."** That's the repositioning. That's the moat.

---

*Document produced: 2026-05-10*  
*Next action: Review Phase 1 scope + approve for implementation*
