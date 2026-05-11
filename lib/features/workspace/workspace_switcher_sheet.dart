import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';
import 'create_workspace_sheet.dart';
import 'members_screen.dart';

// ─────────────────────────────────────────────────────────────
// WorkspaceSwitcherSheet
// ─────────────────────────────────────────────────────────────

/// Bottom sheet that lists workspaces grouped by Personal / Shared.
/// Opens on tap of [WorkspaceAppBarChip].
class WorkspaceSwitcherSheet extends ConsumerWidget {
  const WorkspaceSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const WorkspaceSwitcherSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(userWorkspacesProvider);
    final activeWs = ref.watch(activeWorkspaceProvider).valueOrNull;
    final role = ref.watch(currentUserRoleProvider);
    final canManage = role == WorkspaceRole.owner || role == WorkspaceRole.admin;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Handle ──────────────────────────────────────────
            const _SheetHandle(),
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Workspaces',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (activeWs != null && canManage)
                    IconButton(
                      icon: const Icon(Icons.group_outlined),
                      tooltip: 'Manage members',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MembersScreen(workspace: activeWs),
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'New workspace',
                    onPressed: () {
                      Navigator.pop(context);
                      CreateWorkspaceSheet.show(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Workspace list ───────────────────────────────────
            Expanded(
              child: workspacesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (workspaces) {
                  final personal = workspaces
                      .where((w) => w.type == WorkspaceType.personal)
                      .toList();
                  final shared = workspaces
                      .where((w) => w.type == WorkspaceType.shared)
                      .toList();

                  final items = <_ListItem>[
                    if (personal.isNotEmpty) ...[
                      _SectionHeader('Your space'),
                      ...personal.map((w) => _WorkspaceItem(w)),
                    ],
                    if (shared.isNotEmpty) ...[
                      _SectionHeader('Shared spaces'),
                      ...shared.map((w) => _WorkspaceItem(w)),
                    ],
                  ];

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is _SectionHeader) {
                        return _SectionHeaderTile(label: item.label);
                      }
                      if (item is _WorkspaceItem) {
                        final ws = item.workspace;
                        final isActive = ws.id == activeWs?.id;
                        return _WorkspaceTile(
                          workspace: ws,
                          isActive: isActive,
                          onTap: () {
                            if (!isActive) {
                              ref
                                  .read(activeWorkspaceProvider.notifier)
                                  .select(ws);
                            }
                            Navigator.pop(context);
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── List item discriminated union ─────────────────────────────

abstract class _ListItem {}

class _SectionHeader extends _ListItem {
  final String label;
  _SectionHeader(this.label);
}

class _WorkspaceItem extends _ListItem {
  final Workspace workspace;
  _WorkspaceItem(this.workspace);
}

// ─────────────────────────────────────────────────────────────
// _SectionHeaderTile
// ─────────────────────────────────────────────────────────────

class _SectionHeaderTile extends StatelessWidget {
  const _SectionHeaderTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _WorkspaceTile
// ─────────────────────────────────────────────────────────────

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.workspace,
    required this.isActive,
    required this.onTap,
  });

  final Workspace workspace;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final memberCount = workspace.members.length;
    final isShared = workspace.type == WorkspaceType.shared;

    return ListTile(
      onTap: onTap,
      leading: _WorkspaceAvatar(
        workspace: workspace,
        isActive: isActive,
      ),
      title: Text(
        workspace.name,
        style: GoogleFonts.manrope(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            isShared
                ? '$memberCount ${memberCount == 1 ? 'member' : 'members'}'
                : 'Personal',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          if (workspace.isPremium) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Premium',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: isActive
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _WorkspaceAvatar
// ─────────────────────────────────────────────────────────────

/// Circular avatar. Shows emoji if set; otherwise shows initials.
class _WorkspaceAvatar extends StatelessWidget {
  const _WorkspaceAvatar({
    required this.workspace,
    required this.isActive,
  });

  final Workspace workspace;
  final bool isActive;

  String get _initials {
    final words = workspace.name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : 'W';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isShared = workspace.type == WorkspaceType.shared;
    final hasEmoji = workspace.emoji != null && workspace.emoji!.isNotEmpty;

    // Active: primary color. Shared: teal tint. Personal: surface variant.
    final bgColor = isActive
        ? colorScheme.primary
        : isShared
            ? const Color(0xFF00695C)
            : colorScheme.surfaceContainerHighest;
    final fgColor = isActive
        ? colorScheme.onPrimary
        : isShared
            ? Colors.white
            : colorScheme.onSurfaceVariant;

    return CircleAvatar(
      radius: 22,
      backgroundColor: bgColor,
      child: hasEmoji
          ? Text(workspace.emoji!, style: const TextStyle(fontSize: 18))
          : Text(
              _initials,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WorkspaceAppBarChip
// ─────────────────────────────────────────────────────────────

/// Chip shown in the AppBar. Always visible when data is loaded
/// (even with a single workspace — so users know they can switch).
/// Teal tint for shared workspaces, grey for personal.
class WorkspaceAppBarChip extends ConsumerWidget {
  const WorkspaceAppBarChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeWorkspaceProvider);
    final activeWs = activeAsync.valueOrNull;

    // Don't render until we have data
    if (activeWs == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isShared = activeWs.type == WorkspaceType.shared;
    final hasEmoji = activeWs.emoji != null && activeWs.emoji!.isNotEmpty;

    final bgColor = isShared
        ? const Color(0xFF00695C).withValues(alpha: 0.15)
        : colorScheme.secondaryContainer;
    final fgColor = isShared
        ? const Color(0xFF00695C)
        : colorScheme.onSecondaryContainer;

    return GestureDetector(
      onTap: () => WorkspaceSwitcherSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji or icon
            if (hasEmoji)
              Text(activeWs.emoji!, style: const TextStyle(fontSize: 13))
            else
              Icon(
                isShared ? Icons.group_outlined : Icons.person_outline,
                size: 14,
                color: fgColor,
              ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                activeWs.name,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: fgColor),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SheetHandle
// ─────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
