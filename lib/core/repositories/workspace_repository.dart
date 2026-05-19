import 'package:flutter/foundation.dart';
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
    return _supabase.from('workspaces').stream(
        primaryKey: ['id']).asyncMap((_) => _fetchUserWorkspaces(userId));
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
      'name': name,
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
        .update({'name': name}).eq('id', workspaceId);
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
    await _supabase.from('workspaces').update(updates).eq('id', workspaceId);
  }

  Future<void> updateSettings(
      String workspaceId, Map<String, dynamic> settings) async {
    await _supabase
        .from('workspaces')
        .update({'settings': settings}).eq('id', workspaceId);
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
          'workspace_id': workspaceId,
          'invited_email': email.toLowerCase().trim(),
          'role': role.name,
          'invited_by': userId,
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
  /// directly — RLS on workspace_invites blocks the invitee from reading the row.
  /// The Edge Function runs with service role credentials and handles validation
  /// and membership creation atomically.
  ///
  /// Returns the joined [Workspace] on success.
  /// Throws [WorkspaceInviteException] with a machine-readable [code] on failure.
  ///
  /// IMPORTANT: The Supabase Flutter SDK throws [FunctionException] (not a
  /// standard Dart Exception) for non-2xx HTTP responses. We catch it explicitly
  /// and translate it into [WorkspaceInviteException].
  Future<Workspace> acceptInviteViaEdgeFunction(String token) async {
    try {
      final response = await _supabase.functions.invoke(
        'accept-workspace-invite',
        body: {'token': token},
      );

      // On success (200), data is already JSON-decoded by the SDK.
      // Safe-cast: jsonDecode always returns Map<String, dynamic> for JSON objects.
      final data = response.data;
      debugPrint(
          '[InviteAccept] Edge Function response: status=${response.status} data=$data');

      final dataMap =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final wsRaw = dataMap['workspace'];
      if (wsRaw == null) {
        throw const WorkspaceInviteException('internal_error');
      }

      final wsJson =
          wsRaw is Map ? Map<String, dynamic>.from(wsRaw) : <String, dynamic>{};

      return Workspace.fromEdgeFunctionResponse(wsJson);
    } on FunctionException catch (e) {
      // FunctionException is thrown for non-2xx responses.
      // details contains the parsed JSON body: { "error": "<code>" }
      debugPrint(
          '[InviteAccept] FunctionException: status=${e.status} details=${e.details}');
      final details = e.details;
      final code = (details is Map ? details['error'] : null) as String? ??
          'internal_error';
      throw WorkspaceInviteException(code);
    } catch (e) {
      debugPrint('[InviteAccept] Unexpected error: $e');
      rethrow;
    }
  }

  /// Decline a workspace invite — marks declined_at via a SECURITY DEFINER RPC.
  ///
  /// A direct UPDATE on workspace_invites is blocked by RLS for the invitee
  /// (only workspace admins/owners can UPDATE the table). The V42 RPC runs
  /// as DB owner and sets declined_at atomically, which fires the V41 trigger
  /// that notifies the workspace owner.
  Future<void> declineInvite(String token) async {
    final result = await _supabase.rpc(
      'decline_workspace_invite',
      params: {'p_token': token},
    );
    final map =
        result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
    final error = map['error'] as String?;
    if (error != null && error != 'invite_already_used') {
      // invite_already_used is idempotent — treat as success for the invitee UX
      debugPrint('[InviteDecline] RPC returned error: $error');
      throw WorkspaceInviteException(error);
    }
    debugPrint('[InviteDecline] Declined successfully (token=$token)');
  }
}

// ── Invite error ───────────────────────────────────────────────────────────────

class WorkspaceInviteException implements Exception {
  const WorkspaceInviteException(this.code);
  final String code;

  @override
  String toString() => 'WorkspaceInviteException($code)';
}
