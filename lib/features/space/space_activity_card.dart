// lib/features/space/space_activity_card.dart
//
// Preview card for the space activity feed.
// Shows the last 3 activity items + a "Ver tudo" button that opens
// SpaceActivityScreen (paginated full feed).
//
// Hidden when the space has no activity yet — returns SizedBox.shrink()
// while loading so layout doesn't jump.

import 'package:farol/core/repositories/space_activity_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/domain/entities/space_activity.dart';
import '../../core/models/member_display.dart';
import '../../core/providers/space_providers.dart';

final _brlFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Visible only when the space has at least one activity item.
/// Keeps `spaceActivityRealtimeProvider` alive while mounted so the card
/// auto-refreshes when co-members add or delete transactions.
class SpaceActivityCard extends ConsumerWidget {
  const SpaceActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep realtime bridge alive
    ref.watch(spaceActivityRealtimeProvider);

    final activityAsync = ref.watch(spaceActivityProvider(3));
    final displayMap =
        ref.watch(spaceMemberDisplayMapProvider).valueOrNull ?? {};
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final cs = Theme.of(context).colorScheme;

    return activityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Atividade do espaço',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showFullFeed(context, ref),
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

              // ── Items ────────────────────────────────────────────
              for (int i = 0; i < items.length; i++) ...[
                _SpaceActivityTile(
                  activity: items[i],
                  currentUserId: currentUserId,
                  display: displayMap[items[i].userId],
                ),
                if (i < items.length - 1) const Divider(height: 1, indent: 60),
              ],
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  void _showFullFeed(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpaceActivityScreen(
          repository: ref.read(spaceActivityRepositoryProvider),
          spaceId: ref.read(activeSpaceIdProvider) ?? '',
          displayMap: ref.read(spaceMemberDisplayMapProvider).valueOrNull ?? {},
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Activity tile
// ─────────────────────────────────────────────────────────────────

class _SpaceActivityTile extends StatelessWidget {
  final SpaceActivity activity;
  final String currentUserId;
  final MemberDisplay? display;

  const _SpaceActivityTile({
    required this.activity,
    required this.currentUserId,
    required this.display,
  });

  bool get _isSelf => activity.userId == currentUserId;

  String get _authorName {
    if (_isSelf) return 'Você';
    return display?.displayName ?? '${activity.userId.substring(0, 6)}…';
  }

  IconData get _icon => switch (activity.action) {
        'added_transaction' => Icons.add_circle_outline,
        'deleted_transaction' => Icons.remove_circle_outline,
        'recorded_settlement' => Icons.handshake_outlined,
        _ => Icons.history,
      };

  Color _iconColor(ColorScheme cs) => activity.isDeletion
      ? cs.error
      : activity.isSettlement
          ? cs.tertiary
          : cs.primary;

  String _timeAgo() {
    final diff = DateTime.now().difference(activity.createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarColor =
        display?.avatarColor ?? avatarColorForUserId(activity.userId);
    final initials =
        display?.initials ?? activity.userId.substring(0, 2).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          display?.photoUrl != null
              ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(display!.photoUrl!),
                )
              : CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + action
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: _authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' ${activity.actionLabel(isSelf: _isSelf)}',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Entity label + amount
                Row(
                  children: [
                    Icon(_icon, size: 14, color: _iconColor(cs)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.entityLabel ?? activity.entityType,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activity.amount != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _brlFmt.format(activity.amount!),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activity.isDeletion ? cs.error : cs.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time
          Text(
            _timeAgo(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Full feed screen (paginated)
// ─────────────────────────────────────────────────────────────────

class SpaceActivityScreen extends StatefulWidget {
  final SpaceActivityRepository repository;
  final String spaceId;
  final Map<String, MemberDisplay> displayMap;

  const SpaceActivityScreen({
    super.key,
    required this.repository,
    required this.spaceId,
    required this.displayMap,
  });

  @override
  State<SpaceActivityScreen> createState() => _SpaceActivityScreenState();
}

class _SpaceActivityScreenState extends State<SpaceActivityScreen> {
  final List<SpaceActivity> _items = [];
  final ScrollController _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;

  static const _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) return;
    if (!_hasMore && !reset) return;
    setState(() => _loading = true);

    if (reset) {
      _items.clear();
      _hasMore = true;
    }

    try {
      final page = await widget.repository.fetchPage(
        spaceId: widget.spaceId,
        pageSize: _pageSize,
        before: _items.isNotEmpty ? _items.last.createdAt : null,
      );
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Atividade do espaço',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: ListView.separated(
          controller: _scroll,
          itemCount: _items.length + 1,
          separatorBuilder: (_, i) => i < _items.length - 1
              ? const Divider(height: 1, indent: 60)
              : const SizedBox.shrink(),
          itemBuilder: (_, i) {
            if (i == _items.length) {
              if (_loading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Nenhuma atividade ainda.',
                      style: GoogleFonts.manrope(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox(height: 40);
            }
            return _SpaceActivityTile(
              activity: _items[i],
              currentUserId: currentUserId,
              display: widget.displayMap[_items[i].userId],
            );
          },
        ),
      ),
    );
  }
}
