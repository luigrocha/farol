# Sprint 5 — Spaces v2: Invite Deep-link Acceptance
## Implementation Plan

> **Status:** Complete (2026-05-15)
> **Prerequisite:** Sprint 4 complete
> **Next:** Sprint 6 — Space activity log, push notifications (FCM)

---

## What was built

### New files

| File | Description |
|---|---|
| `supabase/functions/accept-space-invite/index.ts` | Edge Function: validates a `space_invites` token, creates the `space_members` row, marks `accepted_at`, and returns the joined space data. Runs with service-role credentials to bypass RLS on `space_invites` (invitee has no membership yet). Mirrors `accept-workspace-invite` exactly. |
| `lib/features/space/accept_space_invite_screen.dart` | Invite acceptance screen shown when user opens `farol.app/join/:token`. Handles not-authenticated (login CTA), loading, success (shows space emoji + name, navigates to `SpaceDashboardScreen`), and error states. Uses `SpaceRepository.acceptSpaceInviteViaEdgeFunction()`. On success: invalidates `userSpacesProvider` and auto-selects the new space via `activeSpaceProvider.notifier.select()`. |

### Modified files

| File | Change |
|---|---|
| `lib/core/repositories/space_repository.dart` | Added `acceptSpaceInviteViaEdgeFunction(String token) → Future<Space>`. Calls the `accept-space-invite` Edge Function, parses the response, returns a `Space`. Throws `SpaceInviteException(code)` on non-2xx (mirrors `WorkspaceInviteException` pattern). Added `SpaceInviteException` class at bottom of file. Added `import 'package:flutter/foundation.dart' show debugPrint`. |
| `lib/features/space/space_dashboard_screen.dart` | Added `static Future<void> push(BuildContext context, Space space)` helper for programmatic navigation (used by `AcceptSpaceInviteScreen`). |
| `lib/main.dart` | (1) Imported `AcceptSpaceInviteScreen`. (2) `_handleDeepLink` now also handles `segments[0] == 'join'` → pushes `/join/:token`. (3) `onGenerateRoute` now handles `/join/:token` path → `AcceptSpaceInviteScreen(token: token)`. |

---

## Key design decisions

### Decision 1: `/join/:token` path for space invites (not `/invite/:token`)
Workspace invites use `farol.app/invite/:token`. Space invites use `farol.app/join/:token`. This separation avoids ambiguity in the deep-link handler — the path prefix alone is sufficient to route to the right acceptance screen without inspecting the token or making a network call.

### Decision 2: Edge Function required for invite acceptance
RLS on `space_invites` uses `space_id IN (SELECT get_my_space_ids_as_admin())` — the invitee has no space membership yet, so they cannot SELECT their own invite row. The Edge Function runs with service-role credentials, bypassing RLS. Identical pattern to `accept-workspace-invite`.

### Decision 3: Auto-select space after acceptance
On success, `AcceptSpaceInviteScreen` calls `ref.read(activeSpaceProvider.notifier).select(space)` so the user is immediately dropped into the new space's context. The subsequent `SpaceDashboardScreen.push()` then makes the correct space dashboard visible without requiring another tap.

### Decision 4: `_copyInviteLink` in settings already uses `/join/` path
The stub added in Sprint 3 (`space_settings_screen.dart`) already produced `https://farol.app/join/$token`. No change was needed — Sprint 5 just wired up the receiving end.

---

## Sprint 6 scope (next)

- **Space activity log** — `space_activity` table (mirrors `workspace_activity` V35 pattern); auto-triggers on transaction INSERT/DELETE, settlement INSERT, member changes; `SpaceActivityCard` on dashboard
- **Push notifications (FCM)** — when a co-member adds a transaction, notify all other space members; requires `device_tokens` table + Cloud Messaging setup
- **Invite notification overlay** — parallel to `InviteNotificationOverlay` in workspace: surface pending space invites in a dismissable banner at the top of the dashboard
