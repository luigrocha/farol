# Sprint 4 — Spaces v2: Display Names, Contributions, Onboarding, Web Layout
## Implementation Plan

> **Status:** Complete (2026-05-15)
> **Prerequisite:** Sprint 3 complete
> **Next:** Sprint 5 — Invite acceptance deep-link, push notifications (FCM), invite flow polish

---

## What was built

### New files

| File | Description |
|---|---|
| `lib/features/dashboard/widgets/space_contributions_card.dart` | Personal dashboard card showing the current user's ledger-linked space contributions for the active month. Groups by space, shows emoji + name + amount + proportional progress bar. Hidden when no contributions. Auto-renders in all three layout variants (mobile, 2-col desktop, 3-col wide desktop). |

### Modified files

| File | Change |
|---|---|
| `lib/core/providers/space_providers.dart` | Added `spaceMemberDisplayMapProvider` — `FutureProvider.autoDispose<Map<String, MemberDisplay>>` watching `activeSpaceProvider`; fetches `profiles` rows for all space member userIds in one Supabase query; builds `MemberDisplay` value objects with `avatarColorForUserId()`. |
| `lib/features/space/space_members_screen.dart` | `_MemberTile` now receives `MemberDisplay?` from `spaceMemberDisplayMapProvider`; shows real `display.displayName`, profile photo (if available), and initials derived from `MemberDisplay.initials` instead of raw `userId.substring(0,2)`. |
| `lib/features/space/space_transactions_screen.dart` | `_FilterBar` and `_TxRow` now accept `Map<String, MemberDisplay> displayMap`. Member filter chips show real names + photos. `_TxRow` trailing shows `"{Name} pagou"` for non-self payers, and when current user is a participant-but-not-payer shows both lines (payer name + "Seu: R$X"). |
| `lib/features/space/space_dashboard_screen.dart` | (1) Upgraded `_EmptyTransactions` → rich onboarding empty state with type-specific headline/subheadline, three illustrated "How it works" steps, accent-colored CTA button. Now accepts `space` param. (2) Adaptive layout: `isDesktop` flag (≥800px) switches between `_MobileContentSliver` (single column) and `_DesktopContentSliver` (two columns: left=balance+transactions, right=category envelopes). |
| `lib/features/dashboard/dashboard_screen.dart` | Wired `SpaceContributionsCard` into all three layout variants (mobile `_MobileDashboardSliver`, 2-col `_DesktopSliver`, 3-col `_WideDesktopSliver`), placed after `ContributionBar` and before `ActivityFeedPreviewCard`. |

---

## Key design decisions

### Decision 1: spaceMemberDisplayMapProvider scoped to active space
Follows the exact same pattern as `memberDisplayMapProvider` in `workspace_providers.dart` — single Supabase `.inFilter()` query for all member userIds. No N+1. Falls back gracefully if profile is missing (empty `Map<String, dynamic>` synthetic row).

### Decision 2: Onboarding empty state is type-aware
Each `SpaceType` (household/trip/project/family/business) has its own headline, subheadline, and uses the space's accent color for the illustration card border and CTA button. Viewers who can't write see "Aguardando o primeiro gasto ser registrado." instead of the CTA.

### Decision 3: SpaceContributionsCard is always hidden when empty
`contribAsync.when(data: (c) => c.isEmpty ? ShrinkBox : Content)` — no "no contributions" placeholder. The card silently disappears for users who haven't linked any space expenses to their personal ledger.

### Decision 4: Desktop layout splits balance+transactions left, envelopes right
On ≥800px screens, settlement suggestions and the recent transaction feed go in the wider (55%) left column — that's the primary action area. Category envelopes (more of a summary) go in the narrower (45%) right column. This mirrors the main dashboard's primary/secondary pattern.

---

## Sprint 5 scope (next)

- **Invite acceptance** — deep-link handler for `farol.app/join/:token` → `accept-space-invite` Edge Function (parallel to `accept-workspace-invite`; insert `space_members` row, log to `workspace_activity`-equivalent)
- **Push notifications** — FCM integration: when a co-member adds a transaction to a space you belong to, send a push notification with the expense description and amount
- **Space activity log** — similar to `workspace_activity`: auto-log space transaction INSERTs/DELETEs, settlements, member changes; surface in a `SpaceActivityCard` on the dashboard
- **Invite link copy** — `space_settings_screen.dart` already has an invite link copy stub; wire it to generate a real invite token via `repo.createInvite()` and copy to clipboard
