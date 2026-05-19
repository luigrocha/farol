// lib/features/space/space_members_screen.dart
// Lists all members of a Space with role management.
//
// Features:
//   • Avatar + name (initials fallback) + role badge
//   • Net balance per member (who owes / is owed) — visible to those with permission
//   • Role picker for admins/owners
//   • Remove member (owner/admin only, cannot remove self if owner)
//   • Invite button → email invite flow

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/member_display.dart';

import '../../core/models/space.dart';
import '../../core/providers/space_providers.dart';
import '../../design/branding/branding.dart';
import '../../design/layout/layout.dart';

final _brlFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class SpaceMembersScreen extends ConsumerWidget {
  final Space space;

  const SpaceMembersScreen({super.key, required this.space});

  static Future<void> push(BuildContext context, Space space) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SpaceMembersScreen(space: space),
        ),
      );

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRole = ref.watch(currentUserSpaceRoleProvider);
    final canAdmin = myRole.isAdmin;
    final canSeeBalances = ref.watch(canSeeMemberBalancesProvider);
    final suggestionsAsync = ref.watch(settlementSuggestionsProvider);
    final displayMap =
        ref.watch(spaceMemberDisplayMapProvider).valueOrNull ?? {};
    final theme = Theme.of(context);

    // Build a net-balance map from settlement suggestions
    final netMap = <String, double>{};
    suggestionsAsync.whenData((suggestions) {
      for (final s in suggestions) {
        netMap[s.fromUserId] = (netMap[s.fromUserId] ?? 0) - s.amount;
        netMap[s.toUserId] = (netMap[s.toUserId] ?? 0) + s.amount;
      }
    });

    final isDesktop = FarolBreakpoints.isDesktop(context);

    final memberList = ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: space.members.length,
      separatorBuilder: (_, __) => Divider(
          height: 1, indent: 72, color: theme.colorScheme.outlineVariant),
      itemBuilder: (_, i) {
        final member = space.members[i];
        final isSelf = member.userId == _currentUserId;
        final net = canSeeBalances ? (netMap[member.userId] ?? 0.0) : null;

        return _MemberTile(
          member: member,
          display: displayMap[member.userId],
          isSelf: isSelf,
          net: net,
          canAdmin: canAdmin && !isSelf,
          onRoleChange: (role) => _changeRole(context, ref, member, role),
          onRemove: () => _removeMember(context, ref, member),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const FarolMark(
              size: FarolBrand.markSizeCompact, variant: FarolLogoVariant.dark),
          const SizedBox(width: 10),
          Text('Membros',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        ]),
        actions: [
          if (canAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Convidar',
              onPressed: () => _showInviteDialog(context, ref),
            ),
        ],
      ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: member list, constrained
                Expanded(
                  flex: 3,
                  child: memberList,
                ),
                VerticalDivider(
                    width: 1, color: theme.colorScheme.outlineVariant),
                // Right: summary panel
                SizedBox(
                  width: 280,
                  child: _MembersSummaryPanel(
                    space: space,
                    netMap: netMap,
                    canSeeBalances: canSeeBalances,
                    displayMap: displayMap,
                    currentUserId: _currentUserId,
                  ),
                ),
              ],
            )
          : memberList,
    );
  }

  // ── Invite dialog ────────────────────────────────────────────────

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final emailCtrl = TextEditingController();
    SpaceRole selectedRole = SpaceRole.member;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Convidar pessoa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Text(
                'Papel',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<SpaceRole>(
                segments: const [
                  ButtonSegment(value: SpaceRole.member, label: Text('Membro')),
                  ButtonSegment(
                      value: SpaceRole.viewer, label: Text('Visualizador')),
                ],
                selected: {selectedRole},
                onSelectionChanged: (s) =>
                    setDlgState(() => selectedRole = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Convidar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;

    try {
      await ref.read(spaceRepositoryProvider).createInvite(
            spaceId: space.id,
            invitedEmail: email,
            role: selectedRole,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Convite enviado para $email')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  // ── Role change ─────────────────────────────────────────────────

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    SpaceMember member,
    SpaceRole newRole,
  ) async {
    try {
      await ref
          .read(spaceRepositoryProvider)
          .updateMemberRole(space.id, member.userId, newRole);
      ref.invalidate(userSpacesProvider);
      ref.invalidate(activeSpaceProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  // ── Remove member ───────────────────────────────────────────────

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    SpaceMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover membro?'),
        content: const Text(
          'O membro perderá acesso ao espaço. '
          'As transações existentes não serão alteradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(spaceRepositoryProvider)
          .removeMember(space.id, member.userId);
      ref.invalidate(userSpacesProvider);
      ref.invalidate(activeSpaceProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Member tile
// ─────────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final SpaceMember member;
  final MemberDisplay? display;
  final bool isSelf;
  final double? net; // null = hidden
  final bool canAdmin;
  final ValueChanged<SpaceRole> onRoleChange;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    required this.display,
    required this.isSelf,
    required this.net,
    required this.canAdmin,
    required this.onRoleChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials =
        display?.initials ?? member.userId.substring(0, 2).toUpperCase();
    final avatarBg = display?.avatarColor ?? _avatarColor(member.userId);
    final name =
        isSelf ? 'Você' : display?.displayName ?? member.userId.substring(0, 8);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: display?.photoUrl != null
          ? CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(display!.photoUrl!),
            )
          : CircleAvatar(
              radius: 22,
              backgroundColor: avatarBg,
              child: Text(
                initials,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
      title: Row(
        children: [
          Text(
            name,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          _RoleBadge(role: member.role),
        ],
      ),
      subtitle: net != null
          ? Text(
              net! > 0
                  ? 'Te devem ${_brlFmt.format(net!.abs())}'
                  : net! < 0
                      ? 'Você deve ${_brlFmt.format(net!.abs())}'
                      : 'Quite',
              style: theme.textTheme.bodySmall?.copyWith(
                color: net! > 0
                    ? theme.colorScheme.primary
                    : net! < 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: canAdmin
          ? PopupMenuButton<_MemberAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case _MemberAction.makeAdmin:
                    onRoleChange(SpaceRole.admin);
                  case _MemberAction.makeMember:
                    onRoleChange(SpaceRole.member);
                  case _MemberAction.makeViewer:
                    onRoleChange(SpaceRole.viewer);
                  case _MemberAction.remove:
                    onRemove();
                }
              },
              itemBuilder: (_) => [
                if (member.role != SpaceRole.admin)
                  const PopupMenuItem(
                    value: _MemberAction.makeAdmin,
                    child: Text('Tornar admin'),
                  ),
                if (member.role != SpaceRole.member)
                  const PopupMenuItem(
                    value: _MemberAction.makeMember,
                    child: Text('Tornar membro'),
                  ),
                if (member.role != SpaceRole.viewer)
                  const PopupMenuItem(
                    value: _MemberAction.makeViewer,
                    child: Text('Tornar visualizador'),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: Text(
                    'Remover',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  static Color _avatarColor(String userId) {
    const palette = [
      Color(0xFF6366F1),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ];
    return palette[userId.codeUnitAt(0) % palette.length];
  }
}

enum _MemberAction { makeAdmin, makeMember, makeViewer, remove }

// ─────────────────────────────────────────────────────────────────
// Desktop summary panel (right column)
// ─────────────────────────────────────────────────────────────────

class _MembersSummaryPanel extends StatelessWidget {
  final Space space;
  final Map<String, double> netMap;
  final bool canSeeBalances;
  final Map<String, MemberDisplay> displayMap;
  final String currentUserId;

  const _MembersSummaryPanel({
    required this.space,
    required this.netMap,
    required this.canSeeBalances,
    required this.displayMap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMembers = space.members.length;
    final admins = space.members.where((m) => m.role.isAdmin).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'RESUMO',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          icon: Icons.group_outlined,
          label: 'Membros',
          value: '$totalMembers',
          theme: theme,
        ),
        const SizedBox(height: 8),
        _SummaryCard(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admins',
          value: '$admins',
          theme: theme,
        ),
        if (canSeeBalances && netMap.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'SALDOS',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...netMap.entries.map((e) {
            final display = displayMap[e.key];
            final name = e.key == currentUserId
                ? 'Você'
                : display?.displayName ?? e.key.substring(0, 6);
            final isPositive = e.value > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name,
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(
                    _brlFmt.format(e.value.abs()),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPositive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
// Role badge
// ─────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final SpaceRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bg, fg) = switch (role) {
      SpaceRole.owner => (
          'Dono',
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer
        ),
      SpaceRole.admin => (
          'Admin',
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer
        ),
      SpaceRole.member => (
          'Membro',
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurface
        ),
      SpaceRole.viewer => (
          'Visualizador',
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant
        ),
      SpaceRole.guest => (
          'Convidado',
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
