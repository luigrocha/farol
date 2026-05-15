import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace.dart';

class WorkspaceRepository {
  final SupabaseClient _supabase;

  const WorkspaceRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ─────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────

  /// Stream de todos os workspaces do usuário autenticado (com membros).
  Stream<List<Workspace>> watchUserWorkspaces() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();
    return _supabase
        .from('workspaces')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => _fetchUserWorkspaces(userId));
  }

  Future<List<Workspace>> _fetchUserWorkspaces(String userId) async {
    final rows = await _supabase
        .from('workspaces')
        .select('*, workspace_members(*)')
        .order('created_at', ascending: true);
    return rows.map((r) => Workspace.fromJson(r)).toList();
  }

  Future<List<Workspace>> getUserWorkspaces() async {
    final userId = _userId;
    if (userId == null) return [];
    return _fetchUserWorkspaces(userId);
  }

  Future<Workspace?> getById(String workspaceId) async {
    final rows = await _supabase
        .from('workspaces')
        .select('*, workspace_members(*)')
        .eq('id', workspaceId)
        .limit(1);
    if (rows.isEmpty) return null;
    return Workspace.fromJson(rows.first);
  }

  // ─────────────────────────────────────────────────────────────
  // Create / Update
  // ─────────────────────────────────────────────────────────────

  Future<Workspace> create({
    required String name,
    WorkspaceType type = WorkspaceType.personal,
    String? emoji,
    String? color,
    String? description,
  }) async {
    final data = await _supabase.rpc('create_workspace', params: {
      'name':           name,
      'workspace_type': type.name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
      if (description != null) 'description': description,
    });
    final id = (data as Map<String, dynamic>)['id'] as String;
    return getById(id).then((w) => w!);
  }

  Future<void> updateName(String workspaceId, String name) async {
    await _supabase
        .from('workspaces')
        .update({'name': name})
        .eq('id', workspaceId);
  }

  Future<void> updateIdentity(
    String workspaceId, {
    String? name,
    String? emoji,
    String? color,
    String? description,
  }) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
      if (description != null) 'description': description,
    };
    if (updates.isEmpty) return;
    await _supabase
        .from('workspaces')
        .update(updates)
        .eq('id', workspaceId);
  }

  Future<void> updateSettings(
      String workspaceId, Map<String, dynamic> settings) async {
    await _supabase
        .from('workspaces')
        .update({'settings': settings})
        .eq('id', workspaceId);
  }

  // ─────────────────────────────────────────────────────────────
  // Members
  // ─────────────────────────────────────────────────────────────

  Future<void> updateMemberRole(
      String workspaceId, String userId, WorkspaceRole role) async {
    await _supabase
        .from('workspace_members')
        .update({'role': role.name})
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId);
  }

  Future<void> removeMember(String workspaceId, String userId) async {
    await _supabase
        .from('workspace_members')
        .delete()
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId);
  }

  // ─────────────────────────────────────────────────────────────
  // Invites
  // ─────────────────────────────────────────────────────────────

  Future<WorkspaceInvite> createInvite({
    required String workspaceId,
    required String email,
    required WorkspaceRole role,
  }) async {
    final userId = _userId!;
    final row = await _supabase
        .from('workspace_invites')
        .insert({
          'workspace_id':  workspaceId,
          'invited_email': email.toLowerCase().trim(),
          'role':          role.name,
          'invited_by':    userId,
        })
        .select()
        .single();
    return WorkspaceInvite.fromJson(row);
  }

  Future<List<WorkspaceInvite>> getPendingInvites(String workspaceId) async {
    final rows = await _supabase
        .from('workspace_invites')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('accepted_at', null);
    return rows.map((r) => WorkspaceInvite.fromJson(r)).toList();
  }

  /// Accept a workspace invite via the Edge Function.
  ///
  /// Uses the server-side Edge Function instead of querying workspace_invites
  /// directly, because RLS on workspace_invites does not allow the invitee
  /// (who only knows the token) to read the row. The Edge Function runs with
  /// service role credentials and handles all validation atomically.
  ///
  /// Returns the joined [Workspace] on success.
  /// Throws a [WorkspaceInviteException] with a machine-readable [code] on failure.
  Future<Workspace> acceptInviteViaEdgeFunction(String token) async {
    final response = await _supabase.functions.invoke(
      'accept-workspace-invite',
      body: {'token': token},
    );

    final data = response.data as Map<String, dynamic>?;

    if (response.status != 200) {
      final code = data?['error'] as String? ?? 'internal_error';
      throw WorkspaceInviteException(code);
    }

    final wsJson = data?['workspace'] as Map<String, dynamic>?;
    if (wsJson == null) throw const WorkspaceInviteException('internal_error');

    // Build a minimal Workspace from the Edge Function response.
    // Full workspace data (members, etc.) will be loaded on next getUserWorkspaces().
    return Workspace.fromEdgeFunctionResponse(wsJson);
  }

  /// Decline a workspace invite — marks declined_at so it won't appear again.
  /// Also triggers the DB trigger that notifies the workspace owner.
  Future<void> declineInvite(String token) async {
    // The invitee cannot read workspace_invites via RLS, but we use a
    // SECURITY DEFINER RPC to mark declined_at safely.
    // Fallback: call the decline edge function or use markRead on the notification.
    // For now, mark declined via direct update using the token (public lookup).
    await _supabase
        .from('workspace_invites')
        .update({'declined_at': DateTime.now().toIso8601String()})
        .eq('token', token);
  }
}

// ── Invite error ───────────────────────────────────────────────────────────────

class WorkspaceInviteException implements Exception {
  const WorkspaceInviteException(this.code);
  final String code;

  @override
  String toString() => 'WorkspaceInviteException($code)';
}
