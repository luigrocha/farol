# Sprint 3 — Spaces v2 Polish
## Implementation Plan

> **Status:** Complete (2026-05-15)
> **Prerequisite:** Sprint 2 complete
> **Next:** Sprint 4 — Ledger contribution analytics, Space onboarding, web layout adaptation

---

## What was built

### New files

| File | Description |
|---|---|
| `lib/features/space/space_settings_screen.dart` | Identity editing (name, emoji, color, description), members shortcut, invite link copy, archive (owner only). Inline emoji popover picker. Saves via `updateSpaceIdentity()`. |
| `lib/features/space/space_members_screen.dart` | Member list with net-balance per person (from settlement suggestions), role badge, `PopupMenuButton` for role change / remove. Inline invite dialog with role picker. |
| `lib/features/space/space_transactions_screen.dart` | Paginated full transaction list. Horizontal filter chips (all / by category / by member). Summary strip (count + total). Swipe-to-delete with `Dismissible` (payer only). Infinite scroll via cursor pagination (`beforeDate` + `beforeId`). |
| `lib/features/space/space_app_bar_chip.dart` | AppBar chip for active space — accent-colored, shows emoji + name, taps into `WorkspaceSwitcherSheet`. Hidden when no space is active. |

### Modified files

| File | Change |
|---|---|
| `lib/features/space/space_dashboard_screen.dart` | Wired settings button → `SpaceSettingsScreen`, "Ver todos" → `SpaceTransactionsScreen`, "Pagar" → live settlement flow, `SpaceAppBarChip` in SliverAppBar, realtime keepalive via `spaceTransactionsRealtimeProvider`. |
| `lib/core/providers/space_providers.dart` | Added `spaceTransactionsRealtimeProvider` — `StreamProvider.autoDispose` that subscribes to `space_transactions` INSERT events for the active space, invalidates `spaceTransactionsProvider` + `settlementSuggestionsProvider` on each event. |

---

## Key design decisions

### Decision 1: Settlement "Pagar" triggers `saveSettlements`, not `markSettled`
`saveSettlements` persists a new `SpaceSettlement` row and then `settlementSuggestionsProvider` is invalidated so the algorithm re-runs. This is correct: the Splitwise algorithm reads raw transaction shares, not past settlements — so a saved settlement acts as a net-zero pair that cancels the debt on the next run. `markSettled` is reserved for marking existing saved settlements as paid (a different flow).

### Decision 2: Member names shown as initials from userId
The `SpaceMember` model doesn't carry a display name — profiles are in `auth.users` which requires a separate `profiles` table query (established in V34 for workspaces via `memberDisplayMapProvider`). Rather than adding a new cross-join for spaces now, initials are derived from `userId.substring(0, 2)`. Sprint 4 should wire `memberDisplayMapProvider` into spaces too.

### Decision 3: Realtime as `StreamProvider.autoDispose`, not a singleton service
Unlike `WorkspaceRealtimeService` (which is a singleton managed by `MainShell`), the space realtime subscription lives only as long as `SpaceDashboardScreen` is mounted. This is simpler and correct for now: there's no push-notification requirement for spaces yet. The `autoDispose` ensures the channel is removed on unmount.

### Decision 4: Filter chips in transaction list filter client-side, not server-side
The paginated list loads 20 items per page and filters the already-loaded set. This is fine for spaces (typical transaction counts are low). If a space accumulates thousands of transactions, the filter should be pushed to the `getTransactions` query parameters.

---

## How to use in Sprint 4

### Member display names in spaces
```dart
// Reuse existing memberDisplayMapProvider from workspace_providers.dart.
// It fetches profiles for all members of the active workspace.
// For spaces, create a parallel provider or extend the existing one to
// accept a list of userIds.
final memberNames = ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
final displayName = memberNames[userId]?.displayName ?? userId.substring(0, 6);
```

### Ledger contributions in personal analytics
```dart
// Already available — ledgerContributionsProvider is family by {year, month}
final contributions = ref.watch(
  ledgerContributionsProvider((year: 2026, month: 5)),
);
// Each LedgerContribution has spaceName, spaceEmoji, amount, date
```

### Extend realtime to cover more events
```dart
// In space_providers.dart spaceTransactionsRealtimeProvider:
// Add .onPostgresChanges for 'space_settlements' and 'space_members'
// to also invalidate pendingSettlementsProvider and activeSpaceProvider.
```

---

## Sprint 4 scope (next)

- **Member display names** — wire `memberDisplayMapProvider` (or equivalent) into `SpaceMembersScreen` and `_TransactionTile`
- **Ledger contributions UI** — show space contributions inside personal analytics (month breakdown card, FinancialSnapshot integration)
- **Space onboarding flow** — first-time empty state with guided "Add your first expense" prompt
- **Web layout** — `SpaceDashboardScreen` adaptive layout (NavigationRail context, wider envelopes)
- **Invite acceptance** — deep-link handler for `farol.app/join/:token` → `accept-workspace-invite` Edge Function equivalent for spaces
- **Push notifications** — when a co-member adds a transaction, notify via FCM (optional, post-MVP)
