// lib/core/providers/space_providers.dart
// Riverpod providers for Spaces v2.
//
// Active space selection follows the same pattern as workspace_providers.dart:
// persisted in Drift UserSettings under a separate key so it doesn't clash
// with the existing activeWorkspaceProvider.
//
// These providers are entirely additive — existing workspace_providers.dart
// is not modified.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/space.dart';
import '../models/space_transaction.dart';
import '../repositories/space_repository.dart';
import 'providers.dart' show databaseProvider;

// ─────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────

final spaceRepositoryProvider = Provider<SpaceRepository>(
  (ref) => SpaceRepository(Supabase.instance.client),
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
