# Farol — Workspace Architecture v2
## Product Architect + Fintech System Design

> **Document status:** Design Proposal — not yet implemented  
> **Author:** Claude (CTO Assistant mode)  
> **Date:** 2026-05-15  
> **Scope:** Full workspace model redesign — conceptual, data, permissions, privacy, UX, roadmap

---

## Table of Contents

1. [Diagnosis of Current System](#1-diagnosis-of-current-system)
2. [Problems Found](#2-problems-found)
3. [Recommended Conceptual Model](#3-recommended-conceptual-model)
4. [Recommended Data Architecture](#4-recommended-data-architecture)
5. [Privacy System](#5-privacy-system)
6. [Roles and Permissions](#6-roles-and-permissions)
7. [Spaces (Sub-workspaces)](#7-spaces-sub-workspaces)
8. [Financial Consistency](#8-financial-consistency)
9. [Financial Analysis System](#9-financial-analysis-system)
10. [UX Design](#10-ux-design)
11. [Risks and Edge Cases](#11-risks-and-edge-cases)
12. [Migration Plan](#12-migration-plan)
13. [Roadmap](#13-roadmap)
14. [Priorities](#14-priorities)
15. [What NOT to Do](#15-what-not-to-do)
16. [Real Usage Examples](#16-real-usage-examples)
17. [Final Recommendation](#17-final-recommendation)

---

## 1. Diagnosis of Current System

### What exists today (V26–V39)

**Positive — what was built correctly:**

- Every user gets a personal workspace auto-created on signup (trigger `create_personal_workspace`)
- `workspace_id` foreign key on all 14 data tables — clean multi-tenant isolation
- RLS via `SECURITY DEFINER` helper functions — avoids self-referential recursion (good engineering)
- Four roles: `owner`, `admin`, `member`, `viewer`
- Realtime presence via Supabase channels
- Attribution system — `author_user_id` on expenses, recurring rules, installment plans
- Activity feed with cursor pagination
- `WorkspaceType` enum: `personal` | `shared`
- Emoji, color, description identity for workspaces
- `canWriteProvider` guards all write actions for viewers

**Architecture summary of current model:**

```
User (auth.users)
  └─ owns N Workspaces
       └─ has N WorkspaceMembers (role-based)
            └─ all data rows (expenses, incomes, investments, etc.)
                 carry workspace_id → strict tenant isolation
```

### The core limitation

The current model gives you **all-or-nothing sharing**. When you invite someone to a Workspace, they see **everything** in that workspace — every expense, income, investment, account, budget. There is no concept of selective sharing.

This is the right model for a fully isolated personal workspace, but it breaks down the moment you want:
- A "house expenses" space shared with a partner
- A "trip" budget shared with friends
- Freelance finances separate from personal ones

---

## 2. Problems Found

### P1 — No intra-workspace privacy
**Severity: Critical**

Every member sees every row in the workspace. `canWriteProvider` only controls writes, not reads. A partner invited to your workspace sees your salary, investments, and all private transactions.

**Root cause:** RLS policies use workspace membership as the sole access predicate. There are no column-level, category-level, or row-level privacy controls within a workspace.

### P2 — Shared workspaces require exposing all data
**Severity: Critical**

To share "casa" expenses with a partner, you must put those expenses in a shared workspace. But the shared workspace holds all your data because everything is scoped to `workspace_id`. There is no mechanism to say "share only these categories" or "share only this account."

### P3 — No financial isolation between contexts
**Severity: High**

You cannot have:
- A "freelance" context that aggregates to your personal total
- A "viaje Japón" envelope that comes out of your personal budget
- A house pool where contributions are tracked separately from personal spend

### P4 — Roles are too coarse
**Severity: Medium**

`owner / admin / member / viewer` maps to "can write everything" or "can write nothing." There is no way to say "can add expenses but cannot see balances" or "can see the budget envelope but not income."

### P5 — No split-bill / contribution tracking
**Severity: Medium**

When a shared expense is paid by one person, there is no mechanism to track who owes whom, or what portion was yours vs. the other person's. `author_user_id` shows who created the row, not who it belongs to financially.

### P6 — Mathematical duplication risk
**Severity: High**

If you want a "shared house" expense to also appear in your personal financial analysis (because it affects your actual budget), you must either:
- Enter it twice (causing duplication in totals), or
- Not enter it in your personal workspace at all (causing your personal analysis to be incomplete)

There is no consolidation layer.

### P7 — No concept of financial scopes or envelopes
**Severity: Medium**

A "viaje" has a budget, participants, a start/end date, and settlements. None of this is modeled. The current workspace is a generic container without financial semantics beyond what the existing `EnvelopeEngine` provides.

---

## 3. Recommended Conceptual Model

### Core Mental Model: The Financial Ledger Hierarchy

Think of Farol like a professional accounting system for humans. The key insight from double-entry bookkeeping: **every financial fact has a home, and can have a view from another perspective without duplication.**

```
IDENTITY LAYER
  └─ User Profile (private, immutable identity)

LEDGER LAYER  ← the new concept
  └─ Personal Ledger (your complete financial truth)
       ├─ All income streams
       ├─ All assets and accounts
       ├─ All investments
       ├─ All private expenses
       └─ Contributions to Spaces (see below)

SPACE LAYER  ← replaces "shared workspace"
  └─ Space = a scoped financial context
       ├─ Casa 🏠 (with partner)
       ├─ Japón ✈️ (with friends)
       └─ Freelance 💼 (solo but separate context)
```

### Definitions

**Personal Ledger (was: personal workspace)**  
The complete financial truth of one person. Never shared. Always private. Holds: income, all accounts, investments, net worth, salary settings, all private categories and transactions. This is your source of truth.

**Space (was: shared workspace, but redesigned)**  
A bounded financial context with its own: budget, categories, members, transactions, and settlements. A Space is NOT a copy of data — it is a projection. When you add a "casa" expense, it lives in the Casa Space AND creates a linked entry in your Personal Ledger as a contribution. One source of truth, two views.

**Contribution**  
An expense in a Space that is funded by a member. The Space records the total. The member's Ledger records their portion. No duplication.

**Settlement**  
When balances are unequal in a Space (you paid more than your share), a Settlement tracks the debt/credit. Inspired by Splitwise's algorithm but simpler.

### Space types

| Type | Members | Privacy | Best for |
|---|---|---|---|
| `personal` | 1 (solo) | fully private | personal tracking |
| `household` | 2–10 | shared, all see all | casa, roommates |
| `trip` | 2–20 | shared, time-bounded | viajes, eventos |
| `project` | 2–20 | shared, scoped | freelance projects |
| `family` | 2–20 | configurable per member | parejas, familia |
| `business` | 2–100 | role-gated | pequeñas empresas |

### The Crucial Privacy Insight

The privacy problem is solved by **not sharing the Personal Ledger at all.**

- Your **Personal Ledger** is always 100% private. Nobody can be invited to it.
- **Spaces** are shared — but a Space only contains what is explicitly added to it.
- When you add an expense to a Space, you choose: does this also appear in my Personal Ledger?

This is how Revolut's Groups and YNAB's Together work. It is also how corporate accounting works (subsidiary → consolidated).

---

## 4. Recommended Data Architecture

### Entity Relationship (simplified)

```
auth.users
  └─┬─ profiles (display_name, photo_url, email)
    └─ personal_ledger (1:1 with user — NEVER shared)
         ├─ income_streams
         ├─ accounts (bank, cash, investment)
         ├─ investments
         ├─ net_worth_snapshots
         ├─ private_expenses (user sees these only)
         └─ ledger_contributions (link to space transactions)

spaces (replaces shared workspaces)
  ├─ space_members (userId, spaceId, role, permissions_override JSONB)
  ├─ space_categories (categories scoped to the space)
  ├─ space_budgets (envelopes scoped to the space)
  ├─ space_transactions (expenses in this space)
  │     ├─ paid_by_user_id
  │     ├─ split_rule (equal | custom | percentage)
  │     └─ split_shares[] (userId, amount)
  ├─ space_settlements (who owes whom)
  └─ space_activity (audit trail)
```

### Ownership Matrix

| Entity | Owner | Shared | Notes |
|---|---|---|---|
| Personal Ledger | User | ❌ Never | Private, always |
| Income streams | User | ❌ Never | Salary is private |
| Bank accounts | User | ❌ Never | Unless explicitly contributed |
| Investments | User | ❌ Never | Private |
| Salary settings | User | ❌ Never | Private |
| Private categories | User | ❌ Never | Labeled as "personal" |
| Spaces | User (creator) | ✅ With invited members | Scoped context |
| Space categories | Space | ✅ All space members | Scoped to space |
| Space budgets | Space | ✅ All space members | Scoped to space |
| Space transactions | Space | ✅ All space members | Amount, category, author |
| Settlements | Space | ✅ All space members | Who owes whom |
| Activity feed | Space | ✅ All space members | Audit |

### Database Schema (target)

```sql
-- Personal Ledger: 1:1 with user, replaces personal workspace
CREATE TABLE personal_ledgers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency    TEXT NOT NULL DEFAULT 'BRL',
  cutoff_day  SMALLINT NOT NULL DEFAULT 5,
  settings    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: user_id = auth.uid() ONLY. No sharing possible.

-- Spaces: bounded financial contexts
CREATE TABLE spaces (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  emoji        TEXT,
  color        TEXT,
  type         TEXT NOT NULL DEFAULT 'household'
               CHECK (type IN ('household','trip','project','family','business')),
  owner_id     UUID NOT NULL REFERENCES auth.users(id),
  currency     TEXT NOT NULL DEFAULT 'BRL',
  settings     JSONB NOT NULL DEFAULT '{}',
  -- for trip/project: time-bounded
  starts_at    DATE,
  ends_at      DATE,
  archived_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Space members with granular permissions
CREATE TABLE space_members (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id            UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role                TEXT NOT NULL DEFAULT 'member'
                      CHECK (role IN ('owner','admin','member','viewer')),
  -- Capability overrides (null = use role default)
  can_add_expenses    BOOLEAN,
  can_see_balances    BOOLEAN,
  can_see_member_balances BOOLEAN,
  can_export          BOOLEAN,
  can_see_settlements BOOLEAN,
  invited_by          UUID REFERENCES auth.users(id),
  joined_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (space_id, user_id)
);

-- Space transactions (expenses in a space)
CREATE TABLE space_transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id        UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  category_id     UUID NOT NULL REFERENCES space_categories(id),
  paid_by         UUID NOT NULL REFERENCES auth.users(id),
  amount          NUMERIC(14,2) NOT NULL,
  description     TEXT NOT NULL DEFAULT '',
  date            DATE NOT NULL,
  split_rule      TEXT NOT NULL DEFAULT 'equal'
                  CHECK (split_rule IN ('equal','custom','percentage','solo')),
  notes           TEXT,
  receipt_url     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Split shares — one row per participant
CREATE TABLE space_transaction_shares (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id  UUID NOT NULL REFERENCES space_transactions(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  amount          NUMERIC(14,2) NOT NULL,  -- their share
  ledger_linked   BOOLEAN NOT NULL DEFAULT FALSE,  -- was this linked to personal ledger?
  settled         BOOLEAN NOT NULL DEFAULT FALSE
);

-- Settlements (Splitwise-style)
CREATE TABLE space_settlements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id        UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  from_user_id    UUID NOT NULL REFERENCES auth.users(id),
  to_user_id      UUID NOT NULL REFERENCES auth.users(id),
  amount          NUMERIC(14,2) NOT NULL,
  settled_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ledger contributions: link from personal ledger to a space transaction share
-- This is how "casa expense" appears in both your personal analysis AND the space
CREATE TABLE ledger_contributions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  space_id        UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  share_id        UUID NOT NULL REFERENCES space_transaction_shares(id) ON DELETE CASCADE,
  ledger_category_id UUID REFERENCES categories(id),  -- user's personal category to map to
  amount          NUMERIC(14,2) NOT NULL,
  date            DATE NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### RLS Philosophy

```
personal_ledgers   → user_id = auth.uid()              (always private)
expenses (private) → personal_ledger_id IN (mine)      (always private)
spaces             → id IN (my space memberships)       (shared)
space_transactions → space_id IN (my space memberships) (shared)
ledger_contributions → user_id = auth.uid()             (always private)
```

---

## 5. Privacy System

### The Privacy Guarantee

> "Joining a Space never reveals your Personal Ledger. Ever."

This is enforced at the database level, not in application code. The `personal_ledgers` table has a single RLS policy: `user_id = auth.uid()`. There is no API surface that can expose it to another user, regardless of their role.

### What members of a Space see

| Data point | What a space member sees |
|---|---|
| Transaction amount | ✅ Full amount |
| Transaction description | ✅ Full description |
| Transaction category | ✅ Space category |
| Who paid | ✅ Member name + avatar |
| Split breakdown | ✅ Who owes what |
| Payer's personal income | ❌ Never visible |
| Payer's other workspaces | ❌ Never visible |
| Payer's bank balances | ❌ Never visible |
| Payer's investments | ❌ Never visible |
| Payer's private expenses | ❌ Never visible |
| Balance within the Space | ✅ Who has paid more/less |

### Granular capability toggles (per member, per space)

```
can_add_expenses         default: true  for member+
can_see_balances         default: true  for member+
can_see_member_balances  default: true  for admin+   (who owes what)
can_export               default: false for member   (true for admin+)
can_see_settlements      default: true  for member+
can_manage_categories    default: false for member   (true for admin+)
can_manage_budgets       default: false for member   (true for admin+)
can_invite_members       default: false for member   (true for admin+)
```

### Default privacy rules

Things that are **private by default** and can never be changed:
- Personal Ledger (salary, investments, total net worth, private expenses)
- Other Spaces the user belongs to
- Bank account balances and transactions not contributed to the space
- AI insights and financial health score (personal)

Things that are **shared by default** in a Space:
- All space transactions (who paid, amount, category, description)
- Space budget envelopes
- Activity feed
- Settlement balances (who owes whom within the space)

---

## 6. Roles and Permissions

### Role hierarchy

```
Owner   ── created the space, can delete it, transfer ownership
  └─ Admin  ── can invite/remove members, manage categories and budgets
       └─ Member  ── can add expenses, see everything in the space
            └─ Viewer  ── read-only, cannot add expenses
                 └─ Guest  ── can see limited view (e.g. trip total only)
```

### Capability matrix

| Capability | Owner | Admin | Member | Viewer | Guest |
|---|:---:|:---:|:---:|:---:|:---:|
| Add expenses | ✅ | ✅ | ✅ | ❌ | ❌ |
| Edit own expenses | ✅ | ✅ | ✅ | ❌ | ❌ |
| Edit others' expenses | ✅ | ✅ | ❌ | ❌ | ❌ |
| Delete expenses | ✅ | ✅ | own only | ❌ | ❌ |
| See transaction list | ✅ | ✅ | ✅ | ✅ | limited |
| See balances | ✅ | ✅ | ✅ | ✅ | ❌ |
| See member balances | ✅ | ✅ | ✅ | ❌ | ❌ |
| See settlements | ✅ | ✅ | ✅ | ❌ | ❌ |
| Mark settled | ✅ | ✅ | ✅ | ❌ | ❌ |
| Manage categories | ✅ | ✅ | ❌ | ❌ | ❌ |
| Manage budgets | ✅ | ✅ | ❌ | ❌ | ❌ |
| Invite members | ✅ | ✅ | ❌ | ❌ | ❌ |
| Remove members | ✅ | own only | own only | own only | ❌ |
| Export data | ✅ | ✅ | configurable | ❌ | ❌ |
| Delete space | ✅ | ❌ | ❌ | ❌ | ❌ |
| Transfer ownership | ✅ | ❌ | ❌ | ❌ | ❌ |

### Custom capability overrides

The `space_members.can_*` JSONB columns allow per-member exceptions:

```dart
// Example: partner who can add expenses but not see individual balances
SpaceMember(
  role: SpaceRole.member,
  canAddExpenses: true,
  canSeeBalances: false,       // override: hide totals
  canSeeMemberBalances: false, // override: hide who owes what
  canExport: false,
)
```

This solves the "shared casa but no complete financial transparency" case without a full role.

### UX principle for permissions

Never show a list of 10 checkboxes to users. Instead, offer three preset modes and an "advanced" option:

- **Colaborador** — can add and see everything (default for household)
- **Solo gastos** — can add expenses, see transaction list, cannot see balances
- **Solo ver** — read-only (viewer)
- **Personalizado** — shows capability toggles (advanced users only)

---

## 7. Spaces (Sub-workspaces)

### The answer to "should I use sub-workspaces?"

**Yes, but rename them "Spaces" and make them independent contexts, not children.**

Sub-workspaces (hierarchical) create complexity: do you consolidate up? Does a parent see children? Do permission cascade? This gets ERP-level complicated fast.

The simpler model: every Space is a peer. Your Personal Ledger is the consolidation point, not a parent workspace. A Space is a bounded context you choose to contribute to.

```
Personal Ledger (YOUR financial truth)
  ├─ private expenses
  ├─ salary, investments, accounts
  └─ contributions FROM Spaces (optional auto-sync)
        ├─ Casa 🏠 → your share of rent, electricity, internet
        ├─ Japón ✈️ → your share of hotel, food, transport
        └─ Freelance 💼 → your project expenses (manual sync)
```

### Space lifecycle

```
Draft → Active → Archived → Closed

Trip spaces: have start_date + end_date, auto-archive after end
Household spaces: permanent until manually archived
Project spaces: manual lifecycle
```

### Financial behavior per Space type

**Household (casa):**
- Recurring expenses (rent, utilities) — modeled as recurring rules in the Space
- Equal or custom splits
- Monthly settlement cycle
- Budget envelopes visible to all members
- Your share auto-links to Personal Ledger under "Moradia" category

**Trip:**
- Time-bounded (start/end date)
- Per-trip budget
- Any currency (with conversion)
- Final settlement at end of trip
- Summary PDF exportable

**Project (freelance):**
- Income can be recorded (who gets paid)
- Expenses are project costs
- Can be solo (one person, separate context from personal)
- Budget by project phase

**Family:**
- Like Household but with configurable privacy per member (children vs. adults)
- Can hide certain categories from younger members

---

## 8. Financial Consistency

### The Fundamental Rule

> **One transaction, one source of truth. Views are derived, never duplicated.**

### Scenario walkthrough

**Scenario A: You pay R$2,000 rent for a 2-person household**

```
Space Transaction (source of truth):
  amount: R$2,000
  paid_by: You
  split: equal (R$1,000 each)
  
Space Transaction Shares:
  You:      R$1,000 (your actual cost)
  Partner:  R$1,000 (they owe you)

Your Personal Ledger (via ledger_contribution):
  amount: R$1,000   ← only your share appears
  category: Moradia (your personal category)
  
Settlement:
  Partner owes you: R$1,000
```

**Scenario B: Partner pays R$500 for groceries**

```
Space Transaction:
  amount: R$500
  paid_by: Partner
  split: equal (R$250 each)
  
Space Transaction Shares:
  Partner: R$250 (their actual cost)
  You:     R$250 (you owe partner)

Your Personal Ledger:
  amount: R$250 ← your share
  
Running settlement:
  Partner owes you:  R$1,000 (rent)
  You owe partner:   R$250 (groceries)
  Net: Partner owes you R$750
```

**Scenario C: Trip with 3 people, custom splits**

```
Space Transaction: Tokyo dinner, R$300
  paid_by: Friend A
  split: custom
    You:      R$150 (50%)
    Friend A: R$100 (33%)
    Friend B: R$50  (17%)
    
Your Personal Ledger:
  amount: R$150 under "Viagem"
  
Settlements:
  You owe Friend A: R$150
  Friend B owes Friend A: R$50
```

### Aggregation rules for Personal Analysis

```
Total monthly spend = private_expenses + SUM(my shares in space_transactions)

Personal budget envelope "Moradia" = 
  private moradia expenses + my share of Casa space transactions

Net worth = accounts + investments  (NEVER includes space balances)

Monthly income = salary + other incomes  (NEVER diluted by space costs)
```

### Rules to prevent inconsistencies

1. **No double entry:** A personal ledger contribution is always derived from a space transaction share, never entered independently.
2. **Deletions cascade:** Deleting a space transaction removes the linked ledger contribution.
3. **Split sum validation:** `SUM(split_shares.amount) = space_transaction.amount` enforced at DB level.
4. **Currency consistency:** Spaces have a base currency; conversions are stored at transaction time, not recalculated.
5. **Settlement idempotency:** Settlements use net balances (Splitwise algorithm), never double-count.

### The Splitwise Simplification Algorithm

When settling debts, minimize the number of transactions:

```
Members: Ana, Bruno, Carlos
Ana paid: R$300 total in shares owed by others
Bruno paid: R$0 but owes R$150 to Ana, R$100 to Carlos
Carlos paid: R$200, Ana owes Carlos R$50

Net balances:
  Ana:     +R$250 (paid more than owed)
  Bruno:   -R$250 (owes more than paid)
  Carlos:  +R$0 (even)

Simplified settlement:
  Bruno pays Ana R$250  ← 1 transaction instead of 3
```

---

## 9. Financial Analysis System

### Analysis scope hierarchy

```
Global Dashboard (Personal Ledger view)
  ├─ Total income (from all income streams)
  ├─ Total spend = private + contributions to all spaces
  ├─ Net worth (accounts + investments)
  ├─ Health score (personal)
  └─ Savings rate

Space Dashboard (per Space)
  ├─ Space total spend this period
  ├─ Budget vs. actual per category
  ├─ Member contributions (who paid what)
  ├─ Settlement status
  └─ Space-specific trends

Consolidated View (optional, premium)
  ├─ Personal spend + all space contributions
  ├─ Total obligaciones (rent share, subscriptions)
  └─ Combined cashflow forecast
```

### What belongs where

| Metric | Personal Ledger | Space | Consolidated |
|---|:---:|:---:|:---:|
| Net worth | ✅ | ❌ | ✅ |
| Total income | ✅ | ❌ | ✅ |
| Savings rate | ✅ | ❌ | ✅ |
| Health score | ✅ | ❌ | — |
| Budget envelopes | ✅ personal | ✅ space-specific | optional |
| Cashflow forecast | ✅ | ✅ | ✅ premium |
| Category breakdown | ✅ | ✅ | ✅ |
| Member attribution | ❌ | ✅ | ❌ |
| Settlement status | ❌ | ✅ | ❌ |

### Privacy in analysis

The Consolidated view **never reveals absolute income to Space members.** Each member's consolidated view is computed client-side from their own personal ledger + their own shares. Nobody else can see your consolidated numbers.

---

## 10. UX Design

### Core principle: invisible complexity

Users should never feel like they're configuring a database. The complexity lives in the data model; the surface is simple.

### Main navigation mental model

```
[🏠 Personal]  ←→  [🏠 Casa]  ←→  [✈️ Japón]
     ^                  ^
  Your private      Shared space
  financial truth   (bounded context)
```

### Switching contexts

The context switcher is a bottom sheet (mobile) or left rail picker (desktop):

```
─────────────────────────────
  Your spaces
  ──────────
  🏠 Personal          (private)
  
  Shared with others
  ──────────────────
  🏠 Casa              2 members  · R$3,200/mo
  ✈️ Japón 2025        3 members  · Trip ends in 14d
  💼 Freelance Bolt    solo context
  
  + Create space
─────────────────────────────
```

### Onboarding flow for a new space

```
Step 1: "What is this space for?"
  [🏠 Household]  [✈️ Trip]  [💼 Project]  [👨‍👩‍👧 Family]

Step 2 (Household): "Who lives with you?"
  Enter email or phone → auto-suggests from contacts
  Preset role: "Can add and see everything"
  
Step 3: "What are your shared expenses?"
  Checklist: ✅ Rent  ✅ Electricity  ✅ Internet  □ Food  □ Cleaning
  → Auto-creates space categories from selection

Step 4: "Who pays what?" 
  [Split equally]  [Custom percentages]
  
Step 5: Done. "Share invite link" → deep link to accept
```

### Invitation flow

```
Sender: copies invite link → shares via WhatsApp
Recipient: opens link → sees space name + "Ana invited you to Casa 🏠"
           → login/signup → one tap "Join"
           → land directly in space dashboard
```

### Privacy indicators in UI

Use subtle visual signals, never alarmist:

- 🔒 Private badge on Personal Ledger (always visible in switcher)
- Space members shown as avatars in space header
- Expenses in a space show a small "shared with X" indicator
- When adding an expense: "This will be visible to all 2 members of Casa"
- When linking to Personal Ledger: "Your share (R$500) will appear in your personal Moradia budget"

### Expense entry in a Space

```
Amount: R$1,800
Category: [Aluguel]
Paid by: [You ▼]
Split: [Equal — R$900 each ▼]
   > Custom split
   > Just me (not split)
   
[Add to my Moradia budget: YES / NO]  ← ledger contribution toggle

Add receipt photo  |  Add note
─────────────────────────────
[Add expense]
```

### Settlement screen

Simple, WhatsApp-inspired:

```
─────────────────────────────
  Saldos — Casa
  ──────────────
  Bruno te deve  R$750
  
  [Pedir pagamento]
  
  Histórico
  ─────────
  May 2026: Bruno pagou R$1,200 ✓
  Apr 2026: You pagou R$800 ✓
─────────────────────────────
```

---

## 11. Risks and Edge Cases

### R1 — User leaves a Space with pending debt
**Risk:** A member leaves before settling their balance.
**Solution:** Prevent leaving if `net_balance != 0`. Show "Settle first or mark as forgiven" dialog.

### R2 — Space transaction edited after settlement
**Risk:** Retroactive edits throw off balances.
**Solution:** Lock transactions that are part of a completed settlement. Allow "correction" entry only.

### R3 — Currency mismatch in trip spaces
**Risk:** Multi-currency trips cause confusion.
**Solution:** Store original currency + BRL equivalent at transaction time. Never recalculate historical FX.

### R4 — Personal Ledger sync drift
**Risk:** If `ledger_contributions` get out of sync with `space_transaction_shares`, personal analysis is wrong.
**Solution:** Cascade deletes + periodic reconciliation job. Add DB constraint: `contribution.amount = share.amount`.

### R5 — Space deleted by owner while members have balances
**Risk:** Data loss, disputed balances.
**Solution:** Soft delete only. Archive space. Export settlement PDF before archiving. Retain read-only access for 90 days.

### R6 — User opens a Space invite link from another logged-in account
**Risk:** Wrong account joins the space.
**Solution:** Show "This invite was sent to ana@example.com. You are logged in as bruno@example.com. Switch accounts?"

### R7 — Member can infer personal income from settlement totals
**Risk:** If partner sees you always pay large amounts, they can infer your income.
**Solution:** This is inherent to shared finances and acceptable. Personal Ledger (actual income number) is still private. Space shows contributions, not income.

### R8 — Solo "Freelance" space — why not just use personal ledger?
**Benefit:** Separation of concerns. Freelance has its own budget, its own P&L, and can eventually be shared with an accountant (viewer role). Personal Ledger remains personal.

---

## 12. Migration Plan

### Phase 0 — Preparation (no user-visible changes)
1. Add `spaces` table as alias for current `workspaces` where `type = 'shared'`
2. Rename `personal` workspaces to `personal_ledger` in the data layer (keep old table for compat)
3. Add `space_transaction_shares` table (nullable initially)
4. Add `ledger_contributions` table (empty initially)
5. Add `space_settlements` table

### Phase 1 — Data migration
1. Migrate all `type = 'personal'` workspaces → `personal_ledgers`
2. Migrate all `type = 'shared'` workspaces → `spaces`
3. All existing shared expenses → `space_transactions` with a single `split_rule = 'solo'` share (no split, no settlement, backward compatible)
4. Existing `expenses` table remains for personal ledger expenses

### Phase 2 — New capabilities (additive)
1. Add split UI to expense entry in Spaces
2. Add Settlements screen
3. Add `ledger_contribution` toggle to space expense entry
4. Add Consolidated view to dashboard

### Phase 3 — UX polish
1. Redesign context switcher with new Space types
2. Onboarding flow for Space creation
3. Privacy indicators
4. Settlement notifications

### Phase 4 — Advanced features
1. Trip lifecycle (start/end, auto-archive, PDF export)
2. Multi-currency support
3. Guest role (limited view via link, no signup required)
4. Accountant viewer role

---

## 13. Roadmap

### Sprint 1 (2 weeks) — Foundation
- [ ] `spaces`, `space_members`, `space_transactions`, `space_transaction_shares` tables
- [ ] `personal_ledgers` table (1:1 with user)
- [ ] `ledger_contributions` table
- [ ] `space_settlements` table
- [ ] RLS policies for all new tables
- [ ] Data migration V40

### Sprint 2 (2 weeks) — Core Space UX
- [ ] Rename "shared workspaces" → "Spaces" in UI
- [ ] Space creation flow with type picker
- [ ] Space transaction entry with split rule
- [ ] Equal-split default (covers 80% of use cases)

### Sprint 3 (2 weeks) — Settlements
- [ ] Net balance calculation per member
- [ ] Settlement screen
- [ ] "Request payment" deep link (WhatsApp share)
- [ ] Mark as settled

### Sprint 4 (2 weeks) — Personal Ledger integration
- [ ] Ledger contribution toggle on space expense entry
- [ ] Contributions appear in Personal Ledger analysis
- [ ] Personal Ledger budget envelopes include contributions

### Sprint 5 (2 weeks) — Advanced Space types
- [ ] Trip lifecycle (dates, auto-archive)
- [ ] PDF settlement export
- [ ] Freelance/Project space type
- [ ] Consolidated dashboard view

---

## 14. Priorities

### P0 — Must have (blocks everything else)
1. Personal Ledger as truly private, non-shareable container
2. Spaces as bounded shared contexts
3. Basic split (equal) on space transactions
4. Settlement tracking (who owes whom)

### P1 — High value, implement in Sprint 2–3
5. Ledger contribution link (space expense → personal ledger)
6. Privacy indicators in UI
7. Space type picker
8. Invitation flow (current one works, keep it)

### P2 — Medium value, Sprint 4–5
9. Custom split percentages
10. Consolidated dashboard
11. Trip lifecycle
12. PDF export

### P3 — Nice to have, plan later
13. Multi-currency
14. Guest role (no signup)
15. Accountant viewer
16. Business/team spaces

---

## 15. What NOT to Do

### ❌ Don't build hierarchical workspaces (parent/child)
Complexity explodes. Permission inheritance is a minefield. The flat model (Personal Ledger + peer Spaces) is simpler and covers all use cases.

### ❌ Don't allow Personal Ledger to be shared
Not even with a "trusted" role. The whole privacy model depends on this guarantee. The moment you add "share with partner" to Personal Ledger, you've rebuilt the original problem.

### ❌ Don't build row-level privacy inside a Space
"Some transactions are private within the space" — this contradicts the purpose of a Space. If something is private, it belongs in Personal Ledger. The Space is for shared context.

### ❌ Don't build a permissions UI with checkboxes
Users will panic. Use role presets with an "advanced" escape hatch. Most users will never touch advanced settings.

### ❌ Don't copy transactions between workspaces
No duplicating rows. Use `ledger_contributions` as a reference/link. One source of truth always.

### ❌ Don't recalculate historical FX rates
Store the exchange rate at transaction time. Recalculating creates inconsistencies and disputes.

### ❌ Don't let a Space owner see members' Personal Ledgers
Not even indirectly (e.g., inferring income from payment capacity). The database RLS must make this impossible, not just discouraged in code.

### ❌ Don't implement settlements with direct fund transfers
Farol is not a payments app. Settlements are tracking only — the actual money moves outside the app (PIX, cash). This avoids regulatory complexity.

---

## 16. Real Usage Examples

### Example A: Couple sharing rent

**Setup:**
- Ana creates Casa 🏠 (household), invites Bruno
- Bruno joins with "Colaborador" role
- Categories auto-created: Aluguel, Luz, Água, Internet, Alimentação

**Monthly flow:**
1. Ana pays R$2,400 rent → adds to Casa → split equal → R$1,200 each
2. Bruno pays R$180 internet → adds to Casa → split equal → R$90 each
3. Ana adds R$340 electricity → split equal → R$170 each
4. End of month: Bruno owes Ana R$(1,200 - 90 + 170) = R$1,280
5. Bruno pays Ana via PIX → marks settled in app

**What Ana sees in her Personal Dashboard:**
- Moradia: R$1,200 (her share — NOT R$2,400)
- Utilities: R$260 (her shares)
- All her private expenses (Bruno sees none of this)

**What Bruno sees:**
- The Casa space with all shared transactions
- His balance: owes Ana R$1,280
- Nothing about Ana's salary, investments, or private expenses

### Example B: Group trip to Japan (4 friends)

**Setup:**
- Marcos creates Japón ✈️, type: Trip, dates: Oct 1–15
- Invites Ana, Sofia, Diego

**During trip:**
- Expenses added in JPY with BRL equivalent stored at entry time
- Custom splits for activities (Diego skipped one dinner)
- Running balance always visible

**End of trip:**
- Simplified settlements: 2 transactions instead of 6
- PDF summary exported
- Space auto-archives Oct 16

### Example C: Solo freelancer

**Setup:**
- Luis creates Freelance 💼, type: Project, solo (no other members)
- Separate categories: Software, Coworking, Marketing, Hardware

**Benefits:**
- Project expenses tracked separately from personal
- Can add client as Viewer (sees project costs, not personal finances)
- P&L view per project (revenue - project expenses)
- Expenses can optionally link to Personal Ledger for tax purposes

---

## 17. Final Recommendation

### The headline recommendation

**Evolve from "shared workspace = visible everything" to "Space = bounded shared context, Personal Ledger = inviolable private truth."**

This single architectural decision solves every problem you described:

| Problem | Current | v2 |
|---|---|---|
| Partner sees my salary | ✅ (broken) | ❌ (fixed) |
| Can't share only house expenses | ✅ (broken) | ❌ (fixed) |
| No split-bill tracking | ✅ (missing) | ✅ (built-in) |
| Duplication when expense is "personal + shared" | ✅ (broken) | ❌ (ledger_contributions) |
| Permissions too coarse | ✅ (broken) | ❌ (capability overrides) |
| No financial isolation for freelance | ✅ (missing) | ✅ (solo space) |

### The two-sentence pitch to a user

> "Your Personal space is always private — your salary, investments, and private expenses are yours alone. When you create a shared space like 'Casa', you only put what you want to share, and we track exactly who owes what."

### Effort vs. Impact

The migration from the current model to v2 does NOT require throwing away V26–V39. It is additive:
- Add new tables (`spaces`, `space_transaction_shares`, `personal_ledgers`, `ledger_contributions`, `space_settlements`)
- Keep all existing tables (expenses, incomes, etc.) for Personal Ledger use
- Migrate shared workspaces → spaces (type column is already there)
- Migrate personal workspaces → personal_ledgers (1:1 mapping)

**Estimated total implementation: 8–10 weeks of focused development.**

The most important sprint is Sprint 1 (foundation) — getting the data model right makes everything else straightforward. Do not start on the UX until the data model is clean.

### The philosophical foundation

Farol should work like a professional accountant who manages your books, and also helps you split bills with friends. The accountant knows everything about your finances (Personal Ledger), and separately manages the shared accounts you participate in (Spaces). These two worlds never cross-contaminate. That is the correct mental model for a fintech that respects its users.

---

*Document version: 1.0 — May 15, 2026*  
*Next review: After Sprint 1 implementation*
