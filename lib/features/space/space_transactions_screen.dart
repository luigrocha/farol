// lib/features/space/space_transactions_screen.dart
// Full paginated transaction list for a Space.
//
// Features:
//   • Infinite scroll (loads 20 at a time via cursor pagination)
//   • Filter chip row — All | by category | by member
//   • Swipe-to-delete (canWrite only)
//   • Each row shows: emoji, description, date, total, "your share" subtitle
//   • Pull-to-refresh

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/member_display.dart';
import '../../core/models/space.dart';

import '../../core/models/space_transaction.dart';
import '../../core/providers/space_providers.dart';
import 'add_space_transaction_sheet.dart';
import '../../design/branding/branding.dart';

final _brlFmt  = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt = DateFormat('dd/MM/yy');

// ─────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────

class SpaceTransactionsScreen extends ConsumerStatefulWidget {
  final Space space;

  const SpaceTransactionsScreen({super.key, required this.space});

  static Future<void> push(BuildContext context, Space space) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SpaceTransactionsScreen(space: space),
        ),
      );

  @override
  ConsumerState<SpaceTransactionsScreen> createState() =>
      _SpaceTransactionsScreenState();
}

class _SpaceTransactionsScreenState
    extends ConsumerState<SpaceTransactionsScreen> {
  final List<SpaceTransaction> _items = [];
  final ScrollController _scroll = ScrollController();

  bool   _loading     = false;
  bool   _hasMore     = true;
  String? _filterCatId;    // null = all categories
  String? _filterUserId;   // null = all members

  static const _pageSize = 20;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

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
      final repo = ref.read(spaceRepositoryProvider);
      final last = _items.isNotEmpty ? _items.last : null;

      final page = await repo.getTransactions(
        widget.space.id,
        limit:      _pageSize,
        beforeDate: last?.date,
        beforeId:   last?.id,
      );

      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(SpaceTransaction tx) async {
    try {
      await ref.read(spaceRepositoryProvider).deleteTransaction(tx.id);
      setState(() => _items.remove(tx));
      ref.invalidate(spaceTransactionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  // ── Filtered view ────────────────────────────────────────────────

  List<SpaceTransaction> get _filtered {
    return _items.where((tx) {
      if (_filterCatId != null && tx.categoryId != _filterCatId) return false;
      if (_filterUserId != null &&
          !tx.shares.any((s) => s.userId == _filterUserId)) return false;
      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final canWrite   = ref.watch(canWriteInSpaceProvider);
    final cats       = ref.watch(spaceCategoriesProvider).valueOrNull ?? [];
    final displayMap = ref.watch(spaceMemberDisplayMapProvider).valueOrNull ?? {};
    final filtered   = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transações',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              onPressed: () async {
                await AddSpaceTransactionSheet.show(context, widget.space);
                _loadPage(reset: true);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // ── Filter chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterBar(
                categories:      cats,
                members:         widget.space.members,
                displayMap:      displayMap,
                selectedCatId:   _filterCatId,
                selectedUserId:  _filterUserId,
                onCatChanged:    (id) => setState(() => _filterCatId = id),
                onUserChanged:   (id) => setState(() => _filterUserId = id),
              ),
            ),

            // ── Summary strip ────────────────────────────────────
            if (_items.isNotEmpty)
              SliverToBoxAdapter(
                child: _SummaryStrip(items: filtered),
              ),

            // ── Transaction list ─────────────────────────────────
            if (filtered.isEmpty && !_loading)
              const SliverFarolEmptyState(type: FarolEmptyStateType.spaceTransactions)
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == filtered.length) {
                      return _loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox(height: 80);
                    }
                    final tx = filtered[i];
                    return _TxRow(
                      tx:            tx,
                      currentUserId: _currentUserId,
                      displayMap:    displayMap,
                      canDelete:     canWrite && tx.paidBy == _currentUserId,
                      onDelete:      () => _delete(tx),
                    );
                  },
                  childCount: filtered.length + 1, // +1 for loader/padding
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<SpaceCategory>       categories;
  final List<SpaceMember>         members;
  final Map<String, MemberDisplay> displayMap;
  final String?                   selectedCatId;
  final String?                   selectedUserId;
  final ValueChanged<String?>     onCatChanged;
  final ValueChanged<String?>     onUserChanged;

  const _FilterBar({
    required this.categories,
    required this.members,
    required this.displayMap,
    required this.selectedCatId,
    required this.selectedUserId,
    required this.onCatChanged,
    required this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // All
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label:    const Text('Todos'),
              selected: selectedCatId == null && selectedUserId == null,
              onSelected: (_) {
                onCatChanged(null);
                onUserChanged(null);
              },
            ),
          ),
          // Categories
          ...categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: c.icon != null
                  ? Text(c.icon!, style: const TextStyle(fontSize: 12))
                  : null,
              label:    Text(c.name),
              selected: selectedCatId == c.id,
              onSelected: (_) =>
                  onCatChanged(selectedCatId == c.id ? null : c.id),
            ),
          )),
          // Members
          ...members.map((m) {
            final display = displayMap[m.userId];
            final initials = display?.initials ?? m.userId.substring(0, 1).toUpperCase();
            final avatarBg = display?.avatarColor ?? _avatarColor(m.userId);
            final name     = display?.displayName ?? m.userId.substring(0, 6);
            final photo    = display?.photoUrl;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: photo != null
                    ? CircleAvatar(
                        radius: 10,
                        backgroundImage: NetworkImage(photo),
                      )
                    : CircleAvatar(
                        radius: 10,
                        backgroundColor: avatarBg,
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontSize: 8),
                        ),
                      ),
                label:    Text(name),
                selected: selectedUserId == m.userId,
                onSelected: (_) =>
                    onUserChanged(selectedUserId == m.userId ? null : m.userId),
              ),
            );
          }),
        ],
      ),
    );
  }

  static Color _avatarColor(String userId) {
    const palette = [
      Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
      Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
    ];
    return palette[userId.codeUnitAt(0) % palette.length];
  }
}

// ─────────────────────────────────────────────────────────────────
// Summary strip
// ─────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final List<SpaceTransaction> items;

  const _SummaryStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = items.fold(0.0, (s, tx) => s + tx.amount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            '${items.length} transações',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            _brlFmt.format(total),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Transaction row
// ─────────────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final SpaceTransaction           tx;
  final String                     currentUserId;
  final Map<String, MemberDisplay> displayMap;
  final bool                       canDelete;
  final VoidCallback               onDelete;

  const _TxRow({
    required this.tx,
    required this.currentUserId,
    required this.displayMap,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme          = Theme.of(context);
    final myShareAmount  = tx.shareFor(currentUserId);
    final isPayer        = tx.paidBy == currentUserId;
    final isParticipant  = myShareAmount > 0;
    final payerDisplay   = displayMap[tx.paidBy];
    final payerName      = isPayer
        ? 'Você pagou'
        : payerDisplay?.displayName != null
            ? '${payerDisplay!.displayName} pagou'
            : 'Pago por outro';

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          tx.categoryIcon ?? '💳',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(
        tx.description,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            _dateFmt.format(tx.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (tx.categoryName != null) ...[
            Text(
              '  ·  ${tx.categoryName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _brlFmt.format(tx.amount),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (isPayer)
            Text(
              payerName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          else if (isParticipant)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  payerName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Seu: ${_brlFmt.format(myShareAmount)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    if (!canDelete) return tile;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excluir transação?'),
          content: Text('Excluir "${tx.description}"?'),
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
              child: const Text('Excluir'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: tile,
    );
  }
}
