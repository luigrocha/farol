# Sprint 6 — Space Activity Feed

**Status**: ✅ Complete (2026-05-15)

Mirrors the Workspace Activity Feed (V35/V36, `WorkspaceActivityRepository`,
`ActivityFeedPreviewCard`) but scoped to Spaces. Every INSERT/DELETE on
`space_transactions` and every INSERT on `space_settlements` is auto-logged by
SECURITY DEFINER triggers. The `SpaceActivityCard` sits at the bottom of
`SpaceDashboardScreen` and auto-refreshes via a realtime Supabase channel.

---

## Deliverables

| File | Type | Notes |
|---|---|---|
| `database/migrations/V45__space_activity.sql` | Migration | Table + RLS + 2 triggers |
| `lib/core/domain/entities/space_activity.dart` | Entity | `SpaceActivity`, `actionLabel()` |
| `lib/core/repositories/space_activity_repository.dart` | Repository | `fetchLatest()` + `fetchPage()` |
| `lib/core/providers/space_providers.dart` | Providers | `spaceActivityRepositoryProvider`, `spaceActivityProvider`, `spaceActivityRealtimeProvider` |
| `lib/features/space/space_activity_card.dart` | UI | `SpaceActivityCard`, `_SpaceActivityTile`, `SpaceActivityScreen` |
| `lib/features/space/space_dashboard_screen.dart` | Modified | Import + wired into mobile + desktop layouts |

---

## Database — V45

```sql
CREATE TABLE space_activity (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id     UUID        NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL REFERENCES auth.users(id),
  action       TEXT        NOT NULL,
  entity_type  TEXT        NOT NULL,
  entity_id    TEXT,
  entity_label TEXT,
  amount       NUMERIC,
  metadata     JSONB       NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_space_activity_space_time
  ON space_activity(space_id, created_at DESC);
```

**RLS:**
- SELECT: `space_id IN (SELECT get_my_space_ids())`
- INSERT: `space_id IN (SELECT get_my_space_ids_as_writer()) AND user_id = auth.uid()`

**Triggers (SECURITY DEFINER):**
- `trg_space_transaction_activity` — AFTER INSERT OR DELETE on `space_transactions`
  - INSERT → `action = 'added_transaction'`, `user_id = NEW.paid_by`
  - DELETE → `action = 'deleted_transaction'`, `user_id = COALESCE(OLD.paid_by, auth.uid())`
- `trg_space_settlement_activity` — AFTER INSERT on `space_settlements`
  - INSERT → `action = 'recorded_settlement'`, `metadata = {'to_user_id': NEW.to_user_id}`

---

## Entity — SpaceActivity

```dart
class SpaceActivity {
  final String  id;
  final String  spaceId;
  final String  userId;
  final String  action;       // 'added_transaction' | 'deleted_transaction' | 'recorded_settlement'
  final String  entityType;   // 'space_transaction' | 'space_settlement'
  final String? entityId;
  final String? entityLabel;
  final double? amount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  bool get isAddition   => action.startsWith('added_');
  bool get isDeletion   => action.startsWith('deleted_');
  bool get isSettlement => action == 'recorded_settlement';

  String actionLabel({required bool isSelf});  // Portuguese action verb
}
```

---

## Repository

```dart
class SpaceActivityRepository {
  // Preview card: last [limit] items
  Future<List<SpaceActivity>> fetchLatest({required String spaceId, int limit = 3});

  // Paginated full feed (cursor = DateTime before)
  Future<List<SpaceActivity>> fetchPage({
    required String spaceId,
    int pageSize = 30,
    DateTime? before,
  });
}
```

---

## Providers

```dart
// Repository
final spaceActivityRepositoryProvider = Provider<SpaceActivityRepository>(...);

// Data feed — family param is the limit (3 for preview card)
final spaceActivityProvider = FutureProvider.autoDispose
    .family<List<SpaceActivity>, int>((ref, limit) async { ... });

// Realtime bridge — channel 'space_act:$spaceId'
// On INSERT: ref.invalidate(spaceActivityProvider)
// Keep alive by watching in SpaceActivityCard
final spaceActivityRealtimeProvider = StreamProvider.autoDispose<void>(...);
```

Also extended `spaceTransactionsRealtimeProvider` callback to additionally
invalidate `spaceActivityProvider` (transaction events also produce activity rows).

---

## UI

### SpaceActivityCard (preview)

- `ConsumerWidget` — watches `spaceActivityRealtimeProvider` (keepalive),
  `spaceActivityProvider(3)`, `spaceMemberDisplayMapProvider`
- Returns `SizedBox.shrink()` while loading, on error, or when empty
- Shows last 3 activity items + "Ver tudo" → `SpaceActivityScreen`
- Header: history icon + "Atividade do espaço" + "Ver tudo" TextButton

### _SpaceActivityTile

- Left: `CircleAvatar` — photo if available, else initials on `avatarColor`
- Center: `RichText` — **author** (bold) + action verb; entity label + icon + amount
- Right: time-ago string (`agora`, `5min`, `2h`, `ontem`, `3d`)
- Icon color: `cs.error` (deletion), `cs.tertiary` (settlement), `cs.primary` (addition)

### SpaceActivityScreen (full feed)

- `StatefulWidget` — cursor pagination via `fetchPage(before: _items.last.createdAt)`
- `ScrollController` listener triggers next page at 200px from bottom
- Pull-to-refresh calls `_loadPage(reset: true)`
- Empty state: "Nenhuma atividade ainda."
- Page size: 30 items

---

## Wiring into SpaceDashboardScreen

**Mobile** (`_MobileContentSliver`):
```dart
// After transaction list / empty state:
const Padding(
  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
  child: SpaceActivityCard(),
),
```

**Desktop** (`_DesktopContentSliver` — left column, after transaction list):
```dart
const SizedBox(height: 16),
const SpaceActivityCard(),
```

---

## Design Decisions

1. **No day-grouping in the preview card** — only the full `SpaceActivityScreen`
   warrants grouping; the 3-item preview is simple enough without it.
2. **Cursor = `DateTime`** — same as workspace activity feed. Simpler than
   UUID-based cursors; safe because `created_at` has millisecond precision and
   page fetches use `<` (strictly before).
3. **Single file for card + screen** — mirrors `activity_feed_preview_card.dart`
   which co-locates `ActivityFeedPreviewCard` and `ActivityFeedScreen` to keep
   the space feature folder flat.
4. **Realtime channel name `space_act:$spaceId`** — distinct from workspace
   channel `workspace:{id}` and transaction channel `space_tx:$spaceId`.
