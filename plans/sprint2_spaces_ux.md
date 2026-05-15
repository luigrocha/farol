# Sprint 2 — Spaces v2 Core UX
## Implementation Plan

> **Status:** Complete (2026-05-15)
> **Prerequisite:** Sprint 1 (V43 + V44 migrations applied, models + repository + providers in place)
> **Next:** Sprint 3 — Space settings, full settlement flow, member management, transaction list

---

## What was built

### Dart files

| File | Description |
|---|---|
| `lib/features/space/create_space_sheet.dart` | 2-page bottom sheet: type picker + name/emoji/color → optional invite step. Calls `createSpace()` + `createDefaultCategories()` + `createInvite()`. Auto-switches active space. |
| `lib/features/space/add_space_transaction_sheet.dart` | Bottom sheet: amount, description, category, date, "paid by", split rule (equal/custom/%/solo), per-member amount inputs, ledger-link toggle. Calls `createTransaction()` + optionally `linkToLedger()`. |
| `lib/features/space/space_dashboard_screen.dart` | Full screen: member avatar row, privacy chip, settlement summary, category envelopes (spend bars), recent transaction list, FAB. |

### Modified files

| File | Change |
|---|---|
| `lib/features/workspace/workspace_switcher_sheet.dart` | Added Spaces section below workspaces: shows all user spaces with `_SpaceTile`, a "Novo espaço" create item, navigates to `SpaceDashboardScreen` on tap. Header renamed to "Suas finanças". |

---

## Key design decisions

### Decision 1: Switcher is additive — workspaces stay
The existing Personal / Shared workspace sections are preserved verbatim. The new "Espaços" section is appended below. This means zero risk of breaking the workspace flow while users migrate to the Spaces model.

### Decision 2: Privacy chip on every space dashboard
A subtle `🔒 Gastos pessoais não são visíveis aqui` line appears below the member avatars on every SpaceDashboardScreen. It is informational only — not a warning — and uses `onSurfaceVariant` color to stay unobtrusive.

### Decision 3: `shareFor()` returns `double`, not `SpaceTransactionShare?`
The model exposes `shareFor(userId)` as a convenience double. Whenever a `SpaceTransactionShare` object is needed (e.g. to get `.id` for `linkToLedger`), the code uses `tx.shares.where((s) => s.userId == uid).firstOrNull` directly.

### Decision 4: Category envelopes are relative, not budget-bounded
The bars in `_CategoryEnvelopes` are normalized against the highest-spending category, not against a budget cap. This avoids the need to define budgets per space (Sprint 3 concern).

### Decision 5: Settlement suggestions are read-only in Sprint 2
The `_SettlementRow` "Pagar" button is a no-op stub. The full settlement confirmation + persistence flow (`saveSettlements`) is Sprint 3 work.

---

## How to use in Sprint 3

### Navigate to SpaceDashboardScreen
Already wired in `WorkspaceSwitcherSheet` — tapping a space tile pushes the screen.

### Open CreateSpaceSheet standalone
```dart
CreateSpaceSheet.show(context);
```

### Open AddSpaceTransactionSheet
```dart
AddSpaceTransactionSheet.show(context, space);
```

### Access settlement suggestions
```dart
final suggestions = ref.watch(settlementSuggestionsProvider);
// List<SettlementSuggestion> — each has fromUserId, toUserId, amount
```

---

## Sprint 3 scope (next)

- **Settlement flow** — confirmation dialog + `saveSettlements()` call + success state
- **Space settings screen** — rename, change emoji/color, archive, invite link
- **Member management in spaces** — list members, change role, remove, see balances
- **Full transaction list screen** — pagination, filters by category/member, swipe to delete
- **`SpaceAppBarChip`** — show active space name in AppBar when inside a space (parallel to `WorkspaceAppBarChip`)
- **`ledger_contributions` UI** — show space contributions in the personal ledger analytics
- **Realtime for spaces** — subscribe to `space_transactions` INSERT events (same pattern as `WorkspaceRealtimeService`)
