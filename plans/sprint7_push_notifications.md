# Sprint 7 — Push Notifications + Invite Accepted Overlay

**Status**: 🔲 In progress

Adds FCM push notifications for Space events and an in-app overlay banner
when a co-member accepts a space invite.

---

## Scope

| Task | Deliverable |
|---|---|
| V46 migration | `push_tokens` table + RLS |
| PushTokenRepository | Upsert FCM token on login/startup |
| `send-space-notification` Edge Function | Sends FCM to co-members via FCM HTTP v1 API |
| SpaceNotificationService | FCM init, permission, foreground handler, tap routing |
| InviteAcceptedOverlay | In-app banner on SpaceDashboardScreen |
| pubspec additions | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |

---

## Prerequisite: Firebase project setup (manual, one-time)

Before running the app with notifications, the developer must:

1. Create a Firebase project at console.firebase.google.com
2. Add Android app (package: `com.crsoft.farol`) → download `google-services.json`
   → place at `android/app/google-services.json`
3. Add iOS app → download `GoogleService-Info.plist`
   → place at `ios/Runner/GoogleService-Info.plist`
4. In `android/build.gradle`: add `classpath 'com.google.gms:google-services:4.4.0'`
5. In `android/app/build.gradle`: add `apply plugin: 'com.google.gms.google-services'`
6. Store the Firebase service-account JSON (for server-side FCM) as a Supabase secret:
   `supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='<json>'`

---

## pubspec.yaml additions

```yaml
  firebase_core: ^3.3.0
  firebase_messaging: ^15.1.0
  flutter_local_notifications: ^17.2.0
```

---

## Database — V46

```sql
CREATE TABLE push_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT        NOT NULL,
  platform   TEXT        NOT NULL,  -- 'android' | 'ios' | 'web'
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, platform)
);

-- RLS: users manage only their own tokens
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_manage_own_tokens"
  ON push_tokens FOR ALL
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

---

## PushTokenRepository

`lib/core/repositories/push_token_repository.dart`

```dart
class PushTokenRepository {
  final SupabaseClient _supabase;
  const PushTokenRepository(this._supabase);

  Future<void> upsertToken(String token, String platform) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('push_tokens').upsert({
      'user_id':    userId,
      'token':      token,
      'platform':   platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,platform');
  }

  Future<void> deleteToken(String platform) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('push_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('platform', platform);
  }
}
```

Provider: `pushTokenRepositoryProvider = Provider<PushTokenRepository>(...)`

---

## SpaceNotificationService

`lib/core/services/space_notification_service.dart`

Singleton (mirrors `WorkspaceRealtimeService` pattern).

**Responsibilities:**
1. `init()` — `Firebase.initializeApp()`, request permission, get token, call
   `PushTokenRepository.upsertToken()`, listen for token refresh
2. `setupForegroundHandler()` — `FirebaseMessaging.onMessage` → show local
   notification via `flutter_local_notifications`
3. `setupTapHandler()` — `FirebaseMessaging.onMessageOpenedApp` +
   `getInitialMessage()` → route to the right `SpaceDashboardScreen`

**Notification routing:**
- Notification payload includes `{spaceId, spaceEmoji, spaceName, event}`
- On tap: find the space from `userSpacesProvider`, call
  `activeSpaceProvider.notifier.select(space)`, push `SpaceDashboardScreen`

**Platform detection:**
```dart
String get _platform {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  return 'android';
}
```

Called from `_MainShellState.initState()` after `addPostFrameCallback`.

---

## Edge Function — send-space-notification

`supabase/functions/send-space-notification/index.ts`

**POST** `/functions/v1/send-space-notification`

```typescript
// Body: { spaceId: string, event: string, actorUserId: string, payload: object }
// Auth: service-role key (called from pg_net trigger or app-side)

// 1. Fetch push_tokens for all space members EXCEPT actorUserId
// 2. Build FCM v1 API message per token
// 3. POST to https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
//    using service-account JWT (FIREBASE_SERVICE_ACCOUNT_JSON secret)
// 4. Return { sent: N, failed: M }
```

**Events and their notification text:**

| event | title | body |
|---|---|---|
| `added_transaction` | `{spaceName}` | `{actorName} adicionou {label} — {amount}` |
| `deleted_transaction` | `{spaceName}` | `{actorName} removeu {label}` |
| `recorded_settlement` | `{spaceName}` | `{actorName} registrou um acerto de {amount}` |
| `member_joined` | `{spaceName}` | `{actorName} entrou no espaço` |

**Trigger strategy:** Called app-side after `AddSpaceTransactionSheet` saves,
after settlement is recorded, and from `accept-space-invite` Edge Function for
`member_joined`. (Avoids pg_net complexity — keeps notification logic in TS.)

---

## InviteAcceptedOverlay

`lib/features/space/invite_accepted_overlay.dart`

Triggered when `spaceActivityRealtimeProvider` receives a `member_joined` event.

```dart
class InviteAcceptedOverlay extends StatefulWidget {
  // Shown as an OverlayEntry on SpaceDashboardScreen
  // Animates in from top, auto-dismisses after 4s
  // Shows: avatar initials + "{name} entrou no espaço 🎉"
  // Dismiss button (X)
}
```

**Integration:** `SpaceDashboardScreen` wraps its `Scaffold` body in a `Stack`
with the overlay. Watches `spaceActivityProvider` for new `member_joined` items
and shows the overlay for 4 seconds.

---

## Design Decisions

1. **App-side notification dispatch (not pg_net)** — pg_net requires the
   `pg_net` extension to be enabled in Supabase (it's not always on). Calling
   the Edge Function from the app (after a successful save) is simpler, more
   testable, and doesn't block the DB trigger. Trade-off: if the app crashes
   mid-save, the notification is not sent — acceptable for v1.

2. **FCM HTTP v1 API** — the legacy FCM API is deprecated as of June 2024.
   The v1 API requires a service-account JWT, generated from
   `FIREBASE_SERVICE_ACCOUNT_JSON` in the Edge Function.

3. **`member_joined` in space_activity** — the `accept-space-invite` Edge
   Function already inserts a row into `workspace_activity` for workspace
   invites. We extend `accept-space-invite` to also insert a `member_joined`
   row into `space_activity` so both the realtime overlay and the activity feed
   reflect the event without extra client calls.

4. **`flutter_local_notifications` for foreground** — FCM on its own only
   shows notifications when the app is in background/terminated. For foreground,
   `flutter_local_notifications` is required to display a heads-up notification.
