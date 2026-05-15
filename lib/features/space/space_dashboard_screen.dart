// lib/features/space/space_dashboard_screen.dart
// Dashboard for a shared Space.
//
// Sections:
//   1. Space header — emoji, name, member avatars, privacy chip
//   2. Balance summary — who owes what (if user can see balances)
//   3. Settlement suggestions — with "Settle up" CTA
//   4. Category envelopes — per-category spend (expense transactions)
//   5. Recent transactions — last 10, with "Ver todos" link
//   6. FAB — opens AddSpaceTransactionSheet

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/space.dart';
import '../../core/models/space_transaction.dart';
import '../../core/providers/space_providers.dart';
import 'add_space_transaction_sheet.dart';

final _brlFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt = DateFormat('dd/MM');

// ─────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────

class SpaceDashboardScreen extends ConsumerWidget {
  final Space space;

  const SpaceDashboardScreen({super.key, required this.space});

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync          = ref.watch(spaceTransactionsProvider);
    final suggestionsAsync = ref.watch(settlementSuggestionsProvider);
    final canSeeBalances   = ref.watch(canSeeBalancesProvider);
    final canWrite         = ref.watch(canWriteInSpaceProvider);
    final theme            = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(spaceTransactionsProvider);
          ref.invalidate(settlementSuggestionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned:         true,
              backgroundColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                title: _SpaceHeaderTitle(space: space),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {}, // TODO: space settings screen
                ),
              ],
            ),

            // ── Member Avatars ──────────────────────────────────
            SliverToBoxAdapter(
              child: _MemberAvatarRow(space: space),
            ),

            // ── Privacy notice ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _PrivacyChip(type: space.type),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Balance summary ──────────────────────────────────
            if (canSeeBalances)
              SliverToBoxAdapter(
                child: suggestionsAsync.when(
                  data:    (s) => _BalanceSummary(
                    suggestions: s,
                    currentUserId: _currentUserId,
                  ),
                  loading: () => const _SectionSkeleton(height: 80),
                  error:   (_, __) => const SizedBox.shrink(),
                ),
              ),

            // ── Category envelopes ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  'Gastos por categoria',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: txAsync.when(
                data:    (txs) => _CategoryEnvelopes(transactions: txs),
                loading: () => const _SectionSkeleton(height: 120),
                error:   (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Recent transactions ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Transações recentes',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (txAsync.valueOrNull != null &&
                        txAsync.valueOrNull!.length > 5)
                      TextButton(
                        onPressed: () {}, // TODO: full transaction list
                        child: const Text('Ver todos'),
                      ),
                  ],
                ),
              ),
            ),

            txAsync.when(
              data: (txs) => txs.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptyTransactions(
                        canWrite: canWrite,
                        onAdd: () => AddSpaceTransactionSheet.show(context, space),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _TransactionTile(
                          tx:            txs[i],
                          currentUserId: _currentUserId,
                          members:       space.members,
                        ),
                        childCount: txs.take(10).length,
                      ),
                    ),
              loading: () => SliverToBoxAdapter(
                child: Column(
                  children: List.generate(
                    3,
                    (_) => const _SectionSkeleton(height: 64),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Erro: $e')),
              ),
            ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => AddSpaceTransactionSheet.show(context, space),
              icon:  const Icon(Icons.add),
              label: const Text('Novo gasto'),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Space header title (inside FlexibleSpaceBar)
// ─────────────────────────────────────────────────────────────────

class _SpaceHeaderTitle extends StatelessWidget {
  final Space space;

  const _SpaceHeaderTitle({required this.space});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (space.emoji != null)
          Text(space.emoji!, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            space.name,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Member Avatar Row
// ─────────────────────────────────────────────────────────────────

class _MemberAvatarRow extends StatelessWidget {
  final Space space;

  const _MemberAvatarRow({required this.space});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: space.members.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final m       = space.members[i];
            final initials = m.userId.substring(0, 2).toUpperCase();
            final color    = _avatarColor(m.userId);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color,
                  child: Text(
                    initials,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
// Privacy chip
// ─────────────────────────────────────────────────────────────────

class _PrivacyChip extends StatelessWidget {
  final SpaceType type;

  const _PrivacyChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          'Gastos pessoais não são visíveis aqui',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Balance Summary
// ─────────────────────────────────────────────────────────────────

class _BalanceSummary extends StatelessWidget {
  final List<SettlementSuggestion> suggestions;
  final String currentUserId;

  const _BalanceSummary({
    required this.suggestions,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Only show suggestions that involve the current user
    final mine = suggestions
        .where((s) => s.from == currentUserId || s.to == currentUserId)
        .toList();

    if (mine.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Todos os gastos estão quites!',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acertos pendentes',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...mine.map((s) => _SettlementRow(
                suggestion:    s,
                currentUserId: currentUserId,
              )),
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  final SettlementSuggestion suggestion;
  final String currentUserId;

  const _SettlementRow({
    required this.suggestion,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final iOwePay = suggestion.from == currentUserId;
    final label = iOwePay
        ? 'Você deve ${_brlFmt.format(suggestion.amount)}'
        : 'Te devem ${_brlFmt.format(suggestion.amount)}';
    final color = iOwePay
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              iOwePay ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (iOwePay)
              FilledButton.tonal(
                onPressed: () {}, // TODO: settle flow
                style: FilledButton.styleFrom(
                  minimumSize:    const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Pagar'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Category Envelopes
// ─────────────────────────────────────────────────────────────────

class _CategoryEnvelopes extends StatelessWidget {
  final List<SpaceTransaction> transactions;

  const _CategoryEnvelopes({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group by category
    final totals = <String, ({String name, String? icon, double amount})>{};
    double uncategorized = 0;

    for (final tx in transactions) {
      final cat = tx.category;
      if (cat == null) {
        uncategorized += tx.amount;
      } else {
        final existing = totals[cat.id];
        totals[cat.id] = (
          name:   cat.name,
          icon:   cat.icon,
          amount: (existing?.amount ?? 0) + tx.amount,
        );
      }
    }

    if (uncategorized > 0) {
      totals['_uncategorized'] = (
        name:   'Sem categoria',
        icon:   '📋',
        amount: uncategorized,
      );
    }

    if (totals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text('Nenhum gasto ainda.'),
      );
    }

    final maxAmount = totals.values.map((e) => e.amount).reduce(
          (a, b) => a > b ? a : b,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: totals.entries.map((e) {
          final pct = maxAmount > 0 ? e.value.amount / maxAmount : 0.0;
          return _EnvelopeRow(
            icon:       e.value.icon,
            name:       e.value.name,
            amount:     e.value.amount,
            fillFraction: pct,
          );
        }).toList(),
      ),
    );
  }
}

class _EnvelopeRow extends StatelessWidget {
  final String? icon;
  final String name;
  final double amount;
  final double fillFraction;

  const _EnvelopeRow({
    required this.icon,
    required this.name,
    required this.amount,
    required this.fillFraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(icon!, style: const TextStyle(fontSize: 16)),
                ),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _brlFmt.format(amount),
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           fillFraction,
              minHeight:       6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Transaction Tile
// ─────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final SpaceTransaction tx;
  final String currentUserId;
  final List<SpaceMember> members;

  const _TransactionTile({
    required this.tx,
    required this.currentUserId,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final myShare = tx.shareFor(currentUserId);
    final isPayer = tx.paidBy == currentUserId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          tx.category?.icon ?? '💳',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(
        tx.description,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _dateFmt.format(tx.date),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (myShare != null)
            Text(
              isPayer
                  ? 'Você pagou'
                  : 'Seu: ${_brlFmt.format(myShare.amount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPayer
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  final bool canWrite;
  final VoidCallback onAdd;

  const _EmptyTransactions({required this.canWrite, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💸', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Nenhum gasto registrado ainda.',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (canWrite) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAdd,
                child: const Text('Adicionar primeiro gasto'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Skeleton loader
// ─────────────────────────────────────────────────────────────────

class _SectionSkeleton extends StatelessWidget {
  final double height;

  const _SectionSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height:       height,
        decoration: BoxDecoration(
          color:        theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
