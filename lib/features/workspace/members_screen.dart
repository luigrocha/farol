import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/member_display.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';
import 'invite_member_sheet.dart';
import '../../design/branding/branding.dart';

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

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

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

  Future<void> _changeRole(
      WorkspaceMember member, WorkspaceRole newRole) async {
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
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .errorUpdatingRole(e.toString()))),
        );
      }
    }
  }

  Future<void> _removeMember(WorkspaceMember member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10nCtx = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10nCtx.removeMemberTitle),
          content: Text(l10nCtx.removeMemberConfirm(_workspace.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10nCtx.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(l10nCtx.remove),
            ),
          ],
        );
      },
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
          SnackBar(content: Text(l10n.errorRemovingMember(e.toString()))),
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
        title: Row(children: [
          const FarolMark(
              size: FarolBrand.markSizeCompact, variant: FarolLogoVariant.dark),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).membersTitle,
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text(_workspace.name,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ]),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: AppLocalizations.of(context).inviteMember,
              onPressed: () async {
                await InviteMemberSheet.show(context, _workspace);
                _refresh();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).refresh,
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? Center(child: Text(AppLocalizations.of(context).noMembersFound))
              : ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final member = members[i];
                    final isSelf = member.userId == _currentUserId;
                    final isOwner = member.role == WorkspaceRole.owner;
                    final memberMap =
                        ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
                    final display = memberMap[member.userId];

                    return _MemberTile(
                      member: member,
                      display: display,
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
    required this.display,
    required this.isSelf,
    required this.canManage,
    required this.onChangeRole,
    required this.onRemove,
  });

  final WorkspaceMember member;
  final MemberDisplay? display;
  final bool isSelf;
  final bool canManage;
  final ValueChanged<WorkspaceRole> onChangeRole;
  final VoidCallback onRemove;

  String _roleLabel(BuildContext context, WorkspaceRole r) {
    final l10n = AppLocalizations.of(context);
    return switch (r) {
      WorkspaceRole.owner => l10n.roleOwner,
      WorkspaceRole.admin => l10n.roleAdmin,
      WorkspaceRole.member => l10n.roleMember,
      WorkspaceRole.viewer => l10n.roleViewer,
    };
  }

  String get _initials =>
      display?.initials ?? member.userId.substring(0, 2).toUpperCase();

  String _displayName(BuildContext context) {
    if (isSelf) return AppLocalizations.of(context).you;
    return display?.displayName ?? '${member.userId.substring(0, 8)}…';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = switch (member.role) {
      WorkspaceRole.owner => colorScheme.primary,
      WorkspaceRole.admin => colorScheme.secondary,
      WorkspaceRole.member => colorScheme.onSurfaceVariant,
      WorkspaceRole.viewer => colorScheme.outline,
    };

    final avatarBg =
        display?.avatarColor ?? colorScheme.surfaceContainerHighest;
    final avatarFg =
        display != null ? Colors.white : colorScheme.onSurfaceVariant;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarBg,
        child: Text(
          _initials,
          style: TextStyle(
            color: avatarFg,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              _displayName(context),
              style: GoogleFonts.manrope(
                fontWeight: isSelf ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        _roleLabel(context, member.role),
        style: TextStyle(
          color: roleColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) {
                final l10n = AppLocalizations.of(context);
                return [
                  PopupMenuItem(value: 'admin', child: Text(l10n.makeAdmin)),
                  PopupMenuItem(value: 'member', child: Text(l10n.makeMember)),
                  PopupMenuItem(value: 'viewer', child: Text(l10n.makeViewer)),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      l10n.remove,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ];
              },
              onSelected: (action) {
                if (action == 'remove') {
                  onRemove();
                } else {
                  final role = switch (action) {
                    'admin' => WorkspaceRole.admin,
                    'member' => WorkspaceRole.member,
                    'viewer' => WorkspaceRole.viewer,
                    _ => WorkspaceRole.member,
                  };
                  onChangeRole(role);
                }
              },
            )
          : null,
    );
  }
}
