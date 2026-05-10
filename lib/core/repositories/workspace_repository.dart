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
    final userId = _userId!;
    final wsRow = await _supabase
        .from('workspaces')
        .insert({
          'name':           name,
          'owner_id':       userId,
          'plan':           'free',
          'workspace_type': type.name,
          if (emoji != null) 'emoji': emoji,
          if (color != null) 'color': color,
          if (description != null) 'description': description,
        })
        .select()
        .single();

    await _supabase.from('workspace_members').insert({
      'workspace_id': wsRow['id'],
      'user_id':      userId,
      'role':         'owner',
    });

    return getById(wsRow['id'] as String).then((w) => w!);
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

  /// Aceitar convite via token — adiciona o usuário como membro.
  Future<bool> acceptInvite(String token) async {
    final userId = _userId;
    if (userId == null) return false;

    // 1. Buscar o convite
    final inviteRows = await _supabase
        .from('workspace_invites')
        .select()
        .eq('token', token)
        .isFilter('accepted_at', null)
        .limit(1);

    if (inviteRows.isEmpty) return false;
    final invite = WorkspaceInvite.fromJson(inviteRows.first);
    if (invite.isExpired) return false;

    // 2. Inserir membro
    await _supabase.from('workspace_members').upsert({
      'workspace_id': invite.workspaceId,
      'user_id':      userId,
      'role':         invite.role.name,
      'invited_by':   invite.invitedBy,
    }, onConflict: 'workspace_id,user_id');

    // 3. Marcar convite como aceito
    await _supabase
        .from('workspace_invites')
        .update({'accepted_at': DateTime.now().toIso8601String()})
        .eq('token', token);

    return true;
  }
}
