import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';
import 'invite_member_sheet.dart';

/// Screen for listing and managing workspace members.
/// Accessible to all members (read), but role/remove actions gated to owner/admin.
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  late Workspace _workspace;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _workspace = widget.workspace;
  }

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  bool get _canManage {
    final uid = _currentUserId;
    if (uid == null) return false;
    final role = _workspace.roleFor(uid);
    return role == WorkspaceRole.owner || role == WorkspaceRole.admin;
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final fresh = await repo.getById(_workspace.id);
      if (fresh != null && mounted) setState(() => _workspace = fresh);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(WorkspaceMember member, WorkspaceRole newRole) async {
    final repo = ref.read(workspaceRepositoryProvider);
    try {
      await repo.updateMemberRole(_workspace.id, member.userId, newRole);
      await _refresh();
      // Refresh active workspace provider if it's this one
      ref.invalidate(userWorkspacesProvider);
      final activeWs = ref.read(activeWorkspaceProvider).valueOrNull;
      if (activeWs?.id == _workspace.id) {
        ref.read(activeWorkspaceProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(WorkspaceMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          'This will remove the member from "${_workspace.name}". '
          'Their data will remain but they will lose access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(workspaceRepositoryProvider);
    try {
      await repo.removeMember(_workspace.id, member.userId);
      await _refresh();
      ref.invalidate(userWorkspacesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _workspace.members;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            Text(
              _workspace.name,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Invite member',
              onPressed: () async {
                await InviteMemberSheet.show(context, _workspace);
                _refresh();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final member = members[i];
                    final isSelf = member.userId == _currentUserId;
                    final isOwner = member.role == WorkspaceRole.owner;

                    return _MemberTile(
                      member: member,
                      isSelf: isSelf,
                      canManage: _canManage && !isOwner && !isSelf,
                      onChangeRole: (newRole) => _changeRole(member, newRole),
                      onRemove: () => _removeMember(member),
                    );
                  },
                ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isSelf,
    required this.canManage,
    required this.onChangeRole,
    required this.onRemove,
  });

  final WorkspaceMember member;
  final bool isSelf;
  final bool canManage;
  final ValueChanged<WorkspaceRole> onChangeRole;
  final VoidCallback onRemove;

  String _roleLabel(WorkspaceRole r) => switch (r) {
        WorkspaceRole.owner  => 'Owner',
        WorkspaceRole.admin  => 'Admin',
        WorkspaceRole.member => 'Member',
        WorkspaceRole.viewer => 'Viewer',
      };

  String get _initials {
    // We don't have display names from DB in this model — show userId prefix
    return member.userId.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = switch (member.role) {
      WorkspaceRole.owner  => colorScheme.primary,
      WorkspaceRole.admin  => colorScheme.secondary,
      WorkspaceRole.member => colorScheme.onSurfaceVariant,
      WorkspaceRole.viewer => colorScheme.outline,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Text(
          _initials,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              isSelf ? 'You' : member.userId.substring(0, 8) + '…',
              style: GoogleFonts.manrope(
                fontWeight: isSelf ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        _roleLabel(member.role),
        style: TextStyle(
          color: roleColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'admin',  child: Text('Make Admin')),
                const PopupMenuItem(value: 'member', child: Text('Make Member')),
                const PopupMenuItem(value: 'viewer', child: Text('Make Viewer')),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
              onSelected: (action) {
                if (action == 'remove') {
                  onRemove();
                } else {
                  final role = switch (action) {
                    'admin'  => WorkspaceRole.admin,
                    'member' => WorkspaceRole.member,
                    'viewer' => WorkspaceRole.viewer,
                    _        => WorkspaceRole.member,
                  };
                  onChangeRole(role);
                }
              },
            )
          : null,
    );
  }
}
