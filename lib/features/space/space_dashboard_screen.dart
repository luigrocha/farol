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
import '../../core/domain/entities/space_activity.dart';
import 'add_space_transaction_sheet.dart';
import 'invite_accepted_overlay.dart';
import 'space_activity_card.dart';
import 'space_app_bar_chip.dart';
import 'space_settings_screen.dart';
import 'space_transactions_screen.dart';
import '../../design/branding/branding.dart';
import '../../design/layout/layout.dart';

final _brlFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt = DateFormat('dd/MM');

// ─────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────

class SpaceDashboardScreen extends ConsumerStatefulWidget {
  final Space space;

  const SpaceDashboardScreen({super.key, required this.space});

  static Future<void> push(BuildContext context, Space space) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SpaceDashboardScreen(space: space)),
      );

  @override
  ConsumerState<SpaceDashboardScreen> createState() =>
      _SpaceDashboardScreenState();
}

class _SpaceDashboardScreenState extends ConsumerState<SpaceDashboardScreen>
    with InviteAcceptedOverlayMixin<SpaceDashboardScreen> {
  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  // Track the latest activity id we have already shown an overlay for,
  // so that a rebuild doesn't re-trigger the same banner.
  String? _lastShownActivityId;

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(spaceTransactionsProvider);
    final suggestionsAsync = ref.watch(settlementSuggestionsProvider);
    final canSeeBalances = ref.watch(canSeeBalancesProvider);
    final canWrite = ref.watch(canWriteInSpaceProvider);
    final displayMap =
        ref.watch(spaceMemberDisplayMapProvider).valueOrNull ?? {};
    final theme = Theme.of(context);
    final isDesktop = FarolBreakpoints.isDesktop(context);

    // Keep the realtime subscriptions alive while dashboard is mounted.
    ref.watch(spaceTransactionsRealtimeProvider);

    // Listen for member_joined events from the activity feed.
    ref.listen<AsyncValue<List<SpaceActivity>>>(
      spaceActivityProvider(10),
      (_, next) {
        final items = next.valueOrNull;
        if (items == null || items.isEmpty) return;
        final latest = items.first;
        if (!latest.isMemberJoin) return;
        if (latest.id == _lastShownActivityId) return;
        // Don't show banner for own joins (current user accepted this invite).
        if (latest.userId == _currentUserId) return;

        _lastShownActivityId = latest.id;

        final display = displayMap[latest.userId];
        final name = display?.displayName ??
            latest.entityLabel ??
            latest.userId.substring(0, 6);
        final initials = display?.initials;
        final photoUrl = display?.photoUrl;
        final bgColor = display?.avatarColor;

        showBannerForMember(
          memberName: name,
          initials: initials,
          photoUrl: photoUrl,
          avatarColor: bgColor,
        );
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(spaceTransactionsProvider);
              ref.invalidate(settlementSuggestionsProvider);
            },
            child: CustomScrollView(
              slivers: [
                // ── AppBar ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  title: const Row(children: [
                    FarolMark(
                        size: FarolBrand.markSizeCompact,
                        variant: FarolLogoVariant.dark),
                    SizedBox(width: 8),
                    SpaceAppBarChip(),
                  ]),
                  centerTitle: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    title: _SpaceHeaderTitle(space: widget.space),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () =>
                          SpaceSettingsScreen.push(context, widget.space),
                    ),
                  ],
                ),

                // ── Member Avatars ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _MemberAvatarRow(space: widget.space),
                ),

                // ── Privacy notice ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _PrivacyChip(type: widget.space.type),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Content — mobile vs desktop ─────────────────────
                if (isDesktop)
                  _DesktopContentSliver(
                    space: widget.space,
                    txAsync: txAsync,
                    suggestionsAsync: suggestionsAsync,
                    canSeeBalances: canSeeBalances,
                    canWrite: canWrite,
                    currentUserId: _currentUserId,
                  )
                else
                  _MobileContentSliver(
                    space: widget.space,
                    txAsync: txAsync,
                    suggestionsAsync: suggestionsAsync,
                    canSeeBalances: canSeeBalances,
                    canWrite: canWrite,
                    currentUserId: _currentUserId,
                  ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(child: FarolBottomPadding()),
              ],
            ),
          ),

          // ── Invite accepted overlay ─────────────────────────────
          buildInviteOverlay(context),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () =>
                  AddSpaceTransactionSheet.show(context, widget.space),
              icon: const Icon(Icons.add),
              label: const Text('Novo gasto'),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Mobile content sliver (single column)
// ─────────────────────────────────────────────────────────────────

class _MobileContentSliver extends StatelessWidget {
  final Space space;
  final AsyncValue<List<SpaceTransaction>> txAsync;
  final AsyncValue<List<SettlementSuggestion>> suggestionsAsync;
  final bool canSeeBalances;
  final bool canWrite;
  final String currentUserId;

  const _MobileContentSliver({
    required this.space,
    required this.txAsync,
    required this.suggestionsAsync,
    required this.canSeeBalances,
    required this.canWrite,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Balance summary
        if (canSeeBalances)
          suggestionsAsync.when(
            data: (s) => _BalanceSummary(
              suggestions: s,
              currentUserId: currentUserId,
              spaceId: space.id,
            ),
            loading: () => const _SectionSkeleton(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),

        // Category envelopes header
        Padding(
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

        txAsync.when(
          data: (txs) => _CategoryEnvelopes(transactions: txs),
          loading: () => const _SectionSkeleton(height: 120),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Recent transactions header
        Padding(
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
                  onPressed: () => SpaceTransactionsScreen.push(context, space),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
        ),

        // Transaction list / empty state
        txAsync.when(
          data: (txs) => txs.isEmpty
              ? _EmptyTransactions(
                  space: space,
                  canWrite: canWrite,
                  onAdd: () => AddSpaceTransactionSheet.show(context, space),
                )
              : Column(
                  children: txs
                      .take(10)
                      .map((tx) => _TransactionTile(
                            tx: tx,
                            currentUserId: currentUserId,
                            members: space.members,
                          ))
                      .toList(),
                ),
          loading: () => Column(
            children: List.generate(
              3,
              (_) => const _SectionSkeleton(height: 64),
            ),
          ),
          error: (e, _) => Center(child: Text('Erro: $e')),
        ),

        // Activity feed preview
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SpaceActivityCard(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Desktop content sliver (two columns)
// ─────────────────────────────────────────────────────────────────

class _DesktopContentSliver extends StatelessWidget {
  final Space space;
  final AsyncValue<List<SpaceTransaction>> txAsync;
  final AsyncValue<List<SettlementSuggestion>> suggestionsAsync;
  final bool canSeeBalances;
  final bool canWrite;
  final String currentUserId;

  const _DesktopContentSliver({
    required this.space,
    required this.txAsync,
    required this.suggestionsAsync,
    required this.canSeeBalances,
    required this.canWrite,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column — primary (transactions + balance) ──
            Expanded(
              flex: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance summary
                  if (canSeeBalances)
                    suggestionsAsync.when(
                      data: (s) => _BalanceSummary(
                        suggestions: s,
                        currentUserId: currentUserId,
                        spaceId: space.id,
                      ),
                      loading: () => const _SectionSkeleton(height: 80),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                  // Recent transactions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
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
                            onPressed: () =>
                                SpaceTransactionsScreen.push(context, space),
                            child: const Text('Ver todos'),
                          ),
                      ],
                    ),
                  ),

                  txAsync.when(
                    data: (txs) => txs.isEmpty
                        ? _EmptyTransactions(
                            space: space,
                            canWrite: canWrite,
                            onAdd: () =>
                                AddSpaceTransactionSheet.show(context, space),
                          )
                        : Column(
                            children: txs
                                .take(10)
                                .map((tx) => _TransactionTile(
                                      tx: tx,
                                      currentUserId: currentUserId,
                                      members: space.members,
                                    ))
                                .toList(),
                          ),
                    loading: () => Column(
                      children: List.generate(
                        3,
                        (_) => const _SectionSkeleton(height: 64),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('Erro: $e')),
                  ),

                  // Activity feed preview
                  const SizedBox(height: 16),
                  const SpaceActivityCard(),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // ── Right column — category envelopes ───────────────
            Expanded(
              flex: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Text(
                      'Gastos por categoria',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  txAsync.when(
                    data: (txs) => _CategoryEnvelopes(transactions: txs),
                    loading: () => const _SectionSkeleton(height: 200),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: space.members.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final m = space.members[i];
            final initials = m.userId.substring(0, 2).toUpperCase();
            final color = _avatarColor(m.userId);
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
        Icon(Icons.lock_outline,
            size: 13, color: theme.colorScheme.onSurfaceVariant),
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
  final String spaceId;

  const _BalanceSummary({
    required this.suggestions,
    required this.currentUserId,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Only show suggestions that involve the current user
    final mine = suggestions
        .where(
            (s) => s.fromUserId == currentUserId || s.toUserId == currentUserId)
        .toList();

    if (mine.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
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
                suggestion: s,
                currentUserId: currentUserId,
                spaceId: spaceId,
              )),
        ],
      ),
    );
  }
}

class _SettlementRow extends ConsumerStatefulWidget {
  final SettlementSuggestion suggestion;
  final String currentUserId;
  final String spaceId;

  const _SettlementRow({
    required this.suggestion,
    required this.currentUserId,
    required this.spaceId,
  });

  @override
  ConsumerState<_SettlementRow> createState() => _SettlementRowState();
}

class _SettlementRowState extends ConsumerState<_SettlementRow> {
  bool _settling = false;

  Future<void> _settle() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar pagamento?'),
        content: Text(
          'Registrar pagamento de '
          '${_brlFmt.format(widget.suggestion.amount)} '
          'referente a ${_brlFmt.format(widget.suggestion.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _settling = true);
    try {
      await ref.read(spaceRepositoryProvider).saveSettlements(
            widget.spaceId,
            [widget.suggestion],
            periodStart: start,
            periodEnd: end,
          );
      ref.invalidate(settlementSuggestionsProvider);
      ref.invalidate(pendingSettlementsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento registrado!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iOwePay = widget.suggestion.fromUserId == widget.currentUserId;
    final label = iOwePay
        ? 'Você deve ${_brlFmt.format(widget.suggestion.amount)}'
        : 'Te devem ${_brlFmt.format(widget.suggestion.amount)}';
    final color = iOwePay ? theme.colorScheme.error : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                onPressed: _settling ? null : _settle,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: _settling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pagar'),
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
      final catId = tx.categoryId;
      final catName = tx.categoryName;
      final catIcon = tx.categoryIcon;
      if (catId == null || catName == null) {
        uncategorized += tx.amount;
      } else {
        final existing = totals[catId];
        totals[catId] = (
          name: catName,
          icon: catIcon,
          amount: (existing?.amount ?? 0) + tx.amount,
        );
      }
    }

    if (uncategorized > 0) {
      totals['_uncategorized'] = (
        name: 'Sem categoria',
        icon: '📋',
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
            icon: e.value.icon,
            name: e.value.name,
            amount: e.value.amount,
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
              value: fillFraction,
              minHeight: 6,
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
    final theme = Theme.of(context);
    final myShareAmount =
        tx.shareFor(currentUserId); // returns 0.0 if not a participant
    final isParticipant = myShareAmount > 0;
    final isPayer = tx.paidBy == currentUserId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
          if (isPayer)
            Text(
              'Você pagou',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          else if (isParticipant)
            Text(
              'Seu: ${_brlFmt.format(myShareAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
  final Space space;
  final bool canWrite;
  final VoidCallback onAdd;

  const _EmptyTransactions({
    required this.space,
    required this.canWrite,
    required this.onAdd,
  });

  // Type-specific guidance copy
  String get _headline {
    return switch (space.type) {
      SpaceType.household => 'Registre as despesas da casa',
      SpaceType.trip => 'Registre os gastos da viagem',
      SpaceType.project => 'Registre os custos do projeto',
      SpaceType.family => 'Registre as despesas da família',
      SpaceType.business => 'Registre as despesas do negócio',
    };
  }

  String get _subheadline {
    return switch (space.type) {
      SpaceType.household =>
        'Aluguel, contas, supermercado — tudo em um só lugar, '
            'dividido automaticamente entre os moradores.',
      SpaceType.trip => 'Cada gasto da trip vai aparecer aqui. '
          'Quem pagou o quê fica claro para todos.',
      SpaceType.project => 'Mantenha o orçamento do projeto transparente '
          'para todos os envolvidos.',
      SpaceType.family => 'Organize as despesas familiares e veja '
          'o que cada um contribuiu.',
      SpaceType.business => 'Controle os gastos do negócio com visibilidade '
          'para toda a equipe.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = space.color != null
        ? Color(int.parse('FF${space.color!.replaceFirst('#', '')}', radix: 16))
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Illustration card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Space emoji or default icon
                Text(
                  space.emoji ?? space.type.defaultEmoji,
                  style: const TextStyle(fontSize: 52),
                ),
                const SizedBox(height: 16),
                Text(
                  _headline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subheadline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── How it works steps ─────────────────────────────────
          _OnboardingStep(
            number: '1',
            icon: Icons.add_circle_outline,
            title: 'Adicione um gasto',
            body:
                'Toque em "Novo gasto" e informe o valor, quem pagou e como dividir.',
            color: accentColor,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _OnboardingStep(
            number: '2',
            icon: Icons.people_outline,
            title: 'Defina a divisão',
            body:
                'Igualmente, por porcentagem ou valores personalizados por pessoa.',
            color: accentColor,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _OnboardingStep(
            number: '3',
            icon: Icons.handshake_outlined,
            title: 'Acerte as contas',
            body: 'O espaço calcula automaticamente quem deve quanto a quem.',
            color: accentColor,
            theme: theme,
          ),

          const SizedBox(height: 28),

          // ── CTA ────────────────────────────────────────────────
          if (canWrite)
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Adicionar primeiro gasto',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else
            Center(
              child: Text(
                'Aguardando o primeiro gasto ser registrado.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Onboarding step row
// ─────────────────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final ThemeData theme;

  const _OnboardingStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
