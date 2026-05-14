import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace.dart';
import '../models/member_display.dart';
import '../repositories/workspace_repository.dart';
import '../repositories/workspace_activity_repository.dart';
import '../services/workspace_realtime_service.dart';
import '../repositories/budget_changes_repository.dart';
import '../domain/entities/workspace_activity.dart';
import '../models/user_notification.dart';
import '../repositories/user_notifications_repository.dart';
// Reutiliza os providers de infraestrutura já declarados em providers.dart
import 'providers.dart' show databaseProvider;

// ─────────────────────────────────────────────────────────────
// WorkspaceRepository
// ─────────────────────────────────────────────────────────────

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => WorkspaceRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────
// userWorkspacesProvider — lista todos os workspaces do usuário
// ─────────────────────────────────────────────────────────────

final userWorkspacesProvider = FutureProvider.autoDispose<List<Workspace>>(
  (ref) => ref.watch(workspaceRepositoryProvider).getUserWorkspaces(),
);

// ─────────────────────────────────────────────────────────────
// activeWorkspaceProvider — workspace selecionado no momento
// Persiste o ID em Drift UserSettings. Ao iniciar, auto-seleciona
// o primeiro workspace (personal) se houver apenas um.
// ─────────────────────────────────────────────────────────────

const _kActiveWorkspaceKey = 'active_workspace_id';

class WorkspaceNotifier extends AsyncNotifier<Workspace?> {
  static const _key = _kActiveWorkspaceKey;

  @override
  Future<Workspace?> build() async {
    final repo = ref.watch(workspaceRepositoryProvider);
    final db   = ref.watch(databaseProvider);

    final workspaces = await repo.getUserWorkspaces();
    if (workspaces.isEmpty) return null;

    // Tentar restaurar o workspace salvo
    final savedId = await db.getSetting(_key);
    if (savedId != null && savedId.isNotEmpty) {
      final saved = workspaces.where((w) => w.id == savedId).firstOrNull;
      if (saved != null) return saved;
    }

    // Fallback: primeiro workspace (pessoal)
    final first = workspaces.first;
    await db.setSetting(_key, first.id);
    return first;
  }

  Future<void> select(Workspace workspace) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(_key, workspace.id);
    state = AsyncData(workspace);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final activeWorkspaceProvider =
    AsyncNotifierProvider<WorkspaceNotifier, Workspace?>(
  WorkspaceNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// workspacePlanProvider — plano do workspace ativo
// ─────────────────────────────────────────────────────────────

final workspacePlanProvider = Provider<WorkspacePlan>((ref) {
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  return ws?.plan ?? WorkspacePlan.free;
});

// ─────────────────────────────────────────────────────────────
// currentUserRoleProvider — role do usuário autenticado no workspace ativo
// ─────────────────────────────────────────────────────────────

final currentUserRoleProvider = Provider<WorkspaceRole>((ref) {
  final ws     = ref.watch(activeWorkspaceProvider).valueOrNull;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (ws == null || userId == null) return WorkspaceRole.viewer;
  return ws.roleFor(userId);
});

// ─────────────────────────────────────────────────────────────
// canWriteProvider — true se o usuário pode criar/editar/deletar
// ─────────────────────────────────────────────────────────────

final canWriteProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role != WorkspaceRole.viewer;
});

// ─────────────────────────────────────────────────────────────
// activeWorkspaceIdProvider — atalho para o ID (string)
// Retorna null se ainda carregando ou sem workspace
// ─────────────────────────────────────────────────────────────

final activeWorkspaceIdProvider = Provider<String?>((ref) {
  return ref.watch(activeWorkspaceProvider).valueOrNull?.id;
});

// ─────────────────────────────────────────────────────────────
// workspaceTypeProvider — type of the active workspace
// ─────────────────────────────────────────────────────────────

final workspaceTypeProvider = Provider<WorkspaceType>((ref) {
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  return ws?.type ?? WorkspaceType.personal;
});

// ─────────────────────────────────────────────────────────────
// isSharedWorkspaceProvider — true when active workspace is shared
// Gates all attribution UI — nothing renders in personal workspaces
// ─────────────────────────────────────────────────────────────

final isSharedWorkspaceProvider = Provider<bool>((ref) {
  return ref.watch(workspaceTypeProvider) == WorkspaceType.shared;
});

// ─────────────────────────────────────────────────────────────
// activeWorkspaceMembersProvider — members of the active workspace
// ─────────────────────────────────────────────────────────────

final activeWorkspaceMembersProvider = Provider<List<WorkspaceMember>>((ref) {
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  return ws?.members ?? [];
});

// ─────────────────────────────────────────────────────────────
// memberDisplayMapProvider — userId → MemberDisplay (with profile info)
// Fetches display_name + photo_url from Supabase profiles for all members.
// ─────────────────────────────────────────────────────────────

final memberDisplayMapProvider =
    FutureProvider.autoDispose<Map<String, MemberDisplay>>((ref) async {
  final members = ref.watch(activeWorkspaceMembersProvider);
  if (members.isEmpty) return {};

  final currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';
  final userIds = members.map((m) => m.userId).toList();

  // Fetch profiles for all member user IDs in one query.
  // V34 adds an RLS policy allowing workspace co-members to read each other.
  final rows = await Supabase.instance.client
      .from('profiles')
      .select('id, display_name, email, photo_url')
      .inFilter('id', userIds);

  final profileMap = {
    for (final r in rows) r['id'] as String: r,
  };

  return {
    for (final m in members)
      m.userId: MemberDisplay.fromProfile(
        profileMap[m.userId] ??
            {'id': m.userId, 'display_name': null, 'email': null, 'photo_url': null},
        avatarColor: avatarColorForUserId(m.userId),
        currentUserId: currentUserId,
      ),
  };
});

// ─────────────────────────────────────────────────────────────
// WorkspaceActivityRepository
// ─────────────────────────────────────────────────────────────

final workspaceActivityRepositoryProvider =
    Provider<WorkspaceActivityRepository>(
  (ref) => WorkspaceActivityRepository(Supabase.instance.client),
);

/// Latest [limit] activity items for the active workspace.
/// Returns empty list for personal workspaces or when workspace is loading.
final latestWorkspaceActivityProvider =
    FutureProvider.autoDispose.family<List<WorkspaceActivity>, int>(
  (ref, limit) async {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    if (!isShared) return [];
    final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
    if (ws == null) return [];
    final repo = ref.read(workspaceActivityRepositoryProvider);
    return repo.fetchLatest(workspaceId: ws.id, limit: limit);
  },
);

/// Full paginated activity feed — first page.
/// ActivityFeedScreen manages pagination itself using the repository directly.
final workspaceActivityFirstPageProvider =
    FutureProvider.autoDispose<List<WorkspaceActivity>>((ref) async {
  final isShared = ref.watch(isSharedWorkspaceProvider);
  if (!isShared) return [];
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  if (ws == null) return [];
  final repo = ref.read(workspaceActivityRepositoryProvider);
  return repo.fetchPage(workspaceId: ws.id, pageSize: 30);
});

// ─────────────────────────────────────────────────────────────
// BudgetChangesRepository + provider
// ─────────────────────────────────────────────────────────────

final budgetChangesRepositoryProvider = Provider<BudgetChangesRepository>(
  (ref) => BudgetChangesRepository(Supabase.instance.client),
);

/// Map of category_slug → most recent BudgetChange for the active workspace.
/// Empty map in personal workspaces or while loading.
final budgetChangesProvider =
    FutureProvider.autoDispose<Map<String, BudgetChange>>((ref) async {
  final isShared = ref.watch(isSharedWorkspaceProvider);
  if (!isShared) return {};
  final ws = ref.watch(activeWorkspaceProvider).valueOrNull;
  if (ws == null) return {};
  final repo = ref.read(budgetChangesRepositoryProvider);
  return repo.fetchLatestPerCategory(ws.id);
});

// ─────────────────────────────────────────────────────────────
// Realtime invalidation bridge
// ─────────────────────────────────────────────────────────────

/// Listens to WorkspaceRealtimeService.onActivityChange and invalidates
/// latestWorkspaceActivityProvider whenever a new activity row appears.
/// Must be watched by at least one widget to activate (use in MainShell or
/// ActivityFeedPreviewCard).
final workspaceActivityRealtimeProvider = StreamProvider.autoDispose<void>(
  (ref) {
    return WorkspaceRealtimeService.instance.onActivityChange.map((_) {
      // Invalidate the activity preview — it will re-fetch
      ref.invalidate(latestWorkspaceActivityProvider);
      // Also invalidate first page so feed screen refreshes on next open
      ref.invalidate(workspaceActivityFirstPageProvider);
    });
  },
);

// ─────────────────────────────────────────────────────────────
// Presence
// ─────────────────────────────────────────────────────────────

/// Set of user IDs (excluding self) currently online in the active workspace.
/// Empty in personal workspaces or when no co-members are online.
final workspacePresenceProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    if (!isShared) return const Stream.empty();
    return WorkspaceRealtimeService.instance.onPresenceChange;
  },
);

// ─────────────────────────────────────────────────────────────
// User Notifications
// ─────────────────────────────────────────────────────────────


final userNotificationsRepositoryProvider = Provider.autoDispose(
  (ref) => UserNotificationsRepository(Supabase.instance.client),
);

/// Stream of unread notifications for the current user.
/// Powered by Supabase .stream() so it refreshes on Realtime INSERT.
final pendingInviteNotificationsProvider =
    StreamProvider.autoDispose<List<UserNotification>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();

  return supabase
      .from('user_notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((rows) => rows
          .where((r) => r['read_at'] == null)
          .map(UserNotification.fromJson)
          .toList());
});
