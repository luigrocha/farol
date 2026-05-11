import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/domain/entities/workspace_activity.dart';
import '../../core/providers/workspace_providers.dart'
    show
        activeWorkspaceProvider,
        isSharedWorkspaceProvider,
        memberDisplayMapProvider,
        workspaceActivityRepositoryProvider;
import 'activity_feed_tile.dart';

class ActivityFeedScreen extends ConsumerStatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  ConsumerState<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> {
  final _scrollController = ScrollController();
  final _items = <WorkspaceActivity>[];
  bool _loading = false;
  bool _hasMore = true;
  DateTime? _cursor; // oldest createdAt fetched so far

  static const _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    try {
      final ws = ref.read(activeWorkspaceProvider).valueOrNull;
      if (ws == null) return;
      final repo = ref.read(workspaceActivityRepositoryProvider);
      final page = await repo.fetchPage(
        workspaceId: ws.id,
        pageSize: _pageSize,
        before: _cursor,
      );

      if (mounted) {
        setState(() {
          _items.addAll(page);
          if (page.isNotEmpty) {
            _cursor = page.last.createdAt;
          }
          _hasMore = page.length == _pageSize;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    if (!isShared) {
      return Scaffold(
        appBar: AppBar(title: const Text('Atividade')),
        body: const Center(
          child: Text('Disponível em workspaces compartilhados'),
        ),
      );
    }

    final memberMap =
        ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final ws = ref.watch(activeWorkspaceProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atividade',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            if (ws != null)
              Text(
                ws.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma atividade ainda',
                        style: GoogleFonts.manrope(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = _items[index];
                      final display =
                          memberMap[item.userId];

                      // Day separator
                      final showDate = index == 0 ||
                          !_isSameDay(
                              _items[index - 1].createdAt, item.createdAt);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            _DateHeader(date: item.createdAt),
                          ActivityFeedTile(
                            activity: item,
                            currentUserId: currentUserId,
                            display: display,
                          ),
                          const Divider(height: 1, indent: 60),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        _label(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
