import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/workspace_providers.dart'
    show
        isSharedWorkspaceProvider,
        latestWorkspaceActivityProvider,
        memberDisplayMapProvider;
import '../../activity/activity_feed_tile.dart';
import '../../activity/activity_feed_screen.dart';

/// Dashboard card: last 3 activity items + "See all" button.
/// Invisible in personal workspaces.
class ActivityFeedPreviewCard extends ConsumerWidget {
  const ActivityFeedPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    if (!isShared) return const SizedBox.shrink();

    final activityAsync = ref.watch(latestWorkspaceActivityProvider(3));
    final memberMap =
        ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Icon(Icons.history_outlined,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Atividade recente',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityFeedScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ver tudo',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Body ──
          activityAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Nenhuma atividade ainda. Adicione despesas ou regras recorrentes para começar.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    ActivityFeedTile(
                      activity: items[i],
                      currentUserId: currentUserId,
                      display: memberMap[items[i].userId],
                    ),
                    if (i < items.length - 1)
                      const Divider(height: 1, indent: 60),
                  ],
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
