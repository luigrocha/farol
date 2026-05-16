// lib/core/providers/space_providers.dart
// Riverpod providers for Spaces v2.
//
// Active space selection follows the same pattern as workspace_providers.dart:
// persisted in Drift UserSettings under a separate key so it doesn't clash
// with the existing activeWorkspaceProvider.
//
// These providers are entirely additive — existing workspace_providers.dart
// is not modified.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/space_activity.dart';
import '../models/member_display.dart' show MemberDisplay, avatarColorForUserId;
import '../models/space.dart';
import '../models/space_transaction.dart';
import '../repositories/push_token_repository.dart';
import '../repositories/space_activity_repository.dart';
import '../repositories/space_repository.dart';
import 'providers.dart' show databaseProvider;

// ─────────────────────────────────────────────────────────────────
// Repositories
// ─────────────────────────────────────────────────────────────────

final spaceRepositoryProvider = Provider<SpaceRepository>(
  (ref) => SpaceRepository(Supabase.instance.client),
);

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => PushTokenRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────
// Personal Ledger
// ─────────────────────────────────────────────────────────────────

/// The current user's personal ledger (always private).
final personalLedgerProvider = FutureProvider.autoDispose<PersonalLedger>((ref) {
  return ref.watch(spaceRepositoryProvider).getOrCreatePersonalLedger();
});

// ─────────────────────────────────────────────────────────────────
// User Spaces list
// ─────────────────────────────────────────────────────────────────

/// All active spaces the current user belongs to.
final userSpacesProvider = FutureProvider.autoDispose<List<Space>>((ref) {
  return ref.watch(spaceRepositoryProvider).getUserSpaces();
});

// ─────────────────────────────────────────────────────────────────
// Active Space — persisted selection
// ─────────────────────────────────────────────────────────────────

const _kActiveSpaceKey = 'active_space_id_v2';

class ActiveSpaceNotifier extends AsyncNotifier<Space?> {
  static const _key = _kActiveSpaceKey;

  @override
  Future<Space?> build() async {
    final repo   = ref.watch(spaceRepositoryProvider);
    final db     = ref.watch(databaseProvider);
    final spaces = await repo.getUserSpaces();

    if (spaces.isEmpty) return null;

    final savedId = await db.getSetting(_key);
    if (savedId != null && savedId.isNotEmpty) {
      final saved = spaces.where((s) => s.id == savedId).firstOrNull;
      if (saved != null) return saved;
    }

    // No persisted selection — return null (user is in Personal Ledger context)
    return null;
  }

  Future<void> select(Space? space) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(_key, space?.id ?? '');
    state = AsyncData(space);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final activeSpaceProvider =
    AsyncNotifierProvider<ActiveSpaceNotifier, Space?>(
  ActiveSpaceNotifier.new,
);

/// Shortcut — id of the active space (null when in Personal Ledger context).
final activeSpaceIdProvider = Provider<String?>((ref) {
  return ref.watch(activeSpaceProvider).valueOrNull?.id;
});

/// True when the user is viewing a shared Space (not the Personal Ledger).
final isInSpaceContextProvider = Provider<bool>((ref) {
  return ref.watch(activeSpaceProvider).valueOrNull != null;
});

// ─────────────────────────────────────────────────────────────────
// Current user's role + capabilities in the active space
// ─────────────────────────────────────────────────────────────────

final currentUserSpaceRoleProvider = Provider<SpaceRole>((ref) {
  final space  = ref.watch(activeSpaceProvider).valueOrNull;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (space == null || userId == null) return SpaceRole.viewer;
  return space.roleFor(userId);
});

final currentUserSpaceMemberProvider = Provider<SpaceMember?>((ref) {
  final space  = ref.watch(activeSpaceProvider).valueOrNull;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (space == null || userId == null) return null;
  return space.members.where((m) => m.userId == userId).firstOrNull;
});

/// True when the current user can add/edit expenses in the active space.
final canWriteInSpaceProvider = Provider<bool>((ref) {
  final member = ref.watch(currentUserSpaceMemberProvider);
  if (member == null) return false;
  return member.effectiveCanAddExpenses;
});

/// True when the current user can see balances in the active space.
final canSeeBalancesProvider = Provider<bool>((ref) {
  final member = ref.watch(currentUserSpaceMemberProvider);
  if (member == null) return false;
  return member.effectiveCanSeeBalances;
});

/// True when the current user can see individual member balances (who owes what).
final canSeeMemberBalancesProvider = Provider<bool>((ref) {
  final member = ref.watch(currentUserSpaceMemberProvider);
  if (member == null) return false;
  return member.effectiveCanSeeMemberBalances;
});

/// True when the current user can see and interact with settlements.
final canSeeSettlementsProvider = Provider<bool>((ref) {
  final member = ref.watch(currentUserSpaceMemberProvider);
  if (member == null) return false;
  return member.effectiveCanSeeSettlements;
});

// ─────────────────────────────────────────────────────────────────
// Space categories
// ─────────────────────────────────────────────────────────────────

/// Categories for the active space.
final spaceCategoriesProvider = FutureProvider.autoDispose<List<SpaceCategory>>((ref) async {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return [];
  return ref.read(spaceRepositoryProvider).getCategories(spaceId);
});

// ─────────────────────────────────────────────────────────────────
// Space transactions
// ─────────────────────────────────────────────────────────────────

/// Most recent transactions in the active space (first page).
final spaceTransactionsProvider =
    FutureProvider.autoDispose<List<SpaceTransaction>>((ref) async {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return [];
  return ref.read(spaceRepositoryProvider).getTransactions(spaceId, limit: 30);
});

// ─────────────────────────────────────────────────────────────────
// Settlements
// ─────────────────────────────────────────────────────────────────

/// Pending settlements for the active space.
final pendingSettlementsProvider =
    FutureProvider.autoDispose<List<SpaceSettlement>>((ref) async {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return [];
  return ref.read(spaceRepositoryProvider).getPendingSettlements(spaceId);
});

/// Settlement suggestions (computed, not persisted yet).
final settlementSuggestionsProvider =
    FutureProvider.autoDispose<List<SettlementSuggestion>>((ref) async {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return [];
  return ref.read(spaceRepositoryProvider).computeSettlements(spaceId);
});

// ─────────────────────────────────────────────────────────────────
// Ledger contributions (current user, in date range)
// ─────────────────────────────────────────────────────────────────

/// Ledger contributions from all spaces for the given month.
/// Family: ({year, month}) → List<LedgerContribution>
final ledgerContributionsProvider = FutureProvider.autoDispose
    .family<List<LedgerContribution>, ({int year, int month})>((ref, period) async {
  final from = DateTime(period.year, period.month, 1);
  final to   = DateTime(period.year, period.month + 1, 0); // last day of month
  return ref.read(spaceRepositoryProvider).getLedgerContributions(from: from, to: to);
});

/// Total amount contributed to spaces in a given month (for personal ledger analysis).
final totalLedgerContributionsProvider = Provider.autoDispose
    .family<AsyncValue<double>, ({int year, int month})>((ref, period) {
  return ref.watch(ledgerContributionsProvider(period)).whenData(
        (contributions) => contributions.fold(0.0, (sum, c) => sum + c.amount),
      );
});

// ─────────────────────────────────────────────────────────────────
// Member display names for the active space
// ─────────────────────────────────────────────────────────────────

/// Fetches `profiles` rows for all members of the active space.
/// Returns a map of userId → MemberDisplay (display name, initials, avatar color).
///
/// Follows the exact same pattern as `memberDisplayMapProvider` in
/// workspace_providers.dart but scoped to space membership.
final spaceMemberDisplayMapProvider =
    FutureProvider.autoDispose<Map<String, MemberDisplay>>((ref) async {
  final space = ref.watch(activeSpaceProvider).valueOrNull;
  if (space == null || space.members.isEmpty) return {};

  final currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';
  final userIds = space.members.map((m) => m.userId).toList();

  final rows = await Supabase.instance.client
      .from('profiles')
      .select('id, display_name, email, photo_url')
      .inFilter('id', userIds);

  final profileMap = <String, Map<String, dynamic>>{
    for (final r in rows as List)
      (r as Map<String, dynamic>)['id'] as String: r,
  };

  return {
    for (final m in space.members)
      m.userId: MemberDisplay.fromProfile(
        profileMap[m.userId] ??
            {
              'id':           m.userId,
              'display_name': null,
              'email':        null,
              'photo_url':    null,
            },
        avatarColor:   avatarColorForUserId(m.userId),
        currentUserId: currentUserId,
      ),
  };
});

// ─────────────────────────────────────────────────────────────────
// Realtime — space_transactions INSERT events
// ─────────────────────────────────────────────────────────────────

/// Listens to INSERT events on `space_transactions` for the active space.
/// On each event: invalidates `spaceTransactionsProvider` so the dashboard
/// and transaction list auto-refresh.
///
/// Keep this alive by watching it in SpaceDashboardScreen.
final spaceTransactionsRealtimeProvider = StreamProvider.autoDispose<void>((ref) {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return const Stream.empty();

  final client = Supabase.instance.client;
  final controller = StreamController<void>.broadcast();

  final channel = client.channel('space_tx:$spaceId');

  channel.onPostgresChanges(
    event:  PostgresChangeEvent.insert,
    schema: 'public',
    table:  'space_transactions',
    filter: PostgresChangeFilter(
      type:   PostgresChangeFilterType.eq,
      column: 'space_id',
      value:  spaceId,
    ),
    callback: (_) {
      // Invalidate caches so consumers auto-rebuild
      ref.invalidate(spaceTransactionsProvider);
      ref.invalidate(settlementSuggestionsProvider);
      ref.invalidate(spaceActivityProvider);
      if (!controller.isClosed) controller.add(null);
    },
  );

  channel.subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});

// ─────────────────────────────────────────────────────────────────
// Space activity repository
// ─────────────────────────────────────────────────────────────────

final spaceActivityRepositoryProvider = Provider<SpaceActivityRepository>(
  (ref) => SpaceActivityRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────
// Space activity feed
// ─────────────────────────────────────────────────────────────────

/// Most recent [limit] activity items for the active space.
/// Family param is the limit (typically 3 for the preview card).
final spaceActivityProvider = FutureProvider.autoDispose
    .family<List<SpaceActivity>, int>((ref, limit) async {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return [];
  return ref
      .read(spaceActivityRepositoryProvider)
      .fetchLatest(spaceId: spaceId, limit: limit);
});

// ─────────────────────────────────────────────────────────────────
// Realtime — space_activity INSERT events
// ─────────────────────────────────────────────────────────────────

/// Listens to INSERT events on `space_activity` for the active space.
/// On each event: invalidates `spaceActivityProvider` so the card auto-refreshes.
///
/// Keep this alive by watching it in SpaceActivityCard.
final spaceActivityRealtimeProvider = StreamProvider.autoDispose<void>((ref) {
  final spaceId = ref.watch(activeSpaceIdProvider);
  if (spaceId == null) return const Stream.empty();

  final client     = Supabase.instance.client;
  final controller = StreamController<void>.broadcast();

  final channel = client.channel('space_act:$spaceId');

  channel.onPostgresChanges(
    event:  PostgresChangeEvent.insert,
    schema: 'public',
    table:  'space_activity',
    filter: PostgresChangeFilter(
      type:   PostgresChangeFilterType.eq,
      column: 'space_id',
      value:  spaceId,
    ),
    callback: (_) {
      ref.invalidate(spaceActivityProvider);
      if (!controller.isClosed) controller.add(null);
    },
  );

  channel.subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
