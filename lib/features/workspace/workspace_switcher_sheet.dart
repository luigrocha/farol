import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';
import 'create_workspace_sheet.dart';
import 'members_screen.dart';

/// Bottom sheet that lists the user's workspaces and lets them switch.
/// Appears only when the user has >1 workspace.
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
                  // Members button — only for active workspace owner/admin
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
                  // Create workspace button
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
                data: (workspaces) => ListView.builder(
                  controller: scrollController,
                  itemCount: workspaces.length,
                  itemBuilder: (context, i) {
                    final ws = workspaces[i];
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
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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

    return ListTile(
      onTap: onTap,
      leading: _WorkspaceAvatar(name: workspace.name, isActive: isActive),
      title: Text(
        workspace.name,
        style: GoogleFonts.manrope(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '$memberCount ${memberCount == 1 ? 'member' : 'members'}'
        '${workspace.isPremium ? ' · Premium' : ''}',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: isActive
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
    );
  }
}

/// Circular avatar with workspace initials.
class _WorkspaceAvatar extends StatelessWidget {
  const _WorkspaceAvatar({required this.name, required this.isActive});

  final String name;
  final bool isActive;

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'W';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 22,
      backgroundColor:
          isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      child: Text(
        _initials,
        style: TextStyle(
          color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Small chip shown in the AppBar — tapping opens the switcher.
/// Visible only when the user has >1 workspace.
class WorkspaceAppBarChip extends ConsumerWidget {
  const WorkspaceAppBarChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(userWorkspacesProvider);
    final activeWs = ref.watch(activeWorkspaceProvider).valueOrNull;

    // Only show when data is loaded and user has >1 workspace
    final workspaces = workspacesAsync.valueOrNull ?? [];
    if (workspaces.length <= 1 || activeWs == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => WorkspaceSwitcherSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 14,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              activeWs.name,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSecondaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

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
