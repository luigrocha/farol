import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace.dart';
import '../repositories/workspace_repository.dart';
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
