import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/period_budget.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/ds_tokens.dart';
import '../../../core/domain/value_objects/money.dart';
import 'budget_edit_sheet.dart';
import '../../../core/providers/workspace_providers.dart'
    show
        budgetChangesProvider,
        canWriteProvider,
        isSharedWorkspaceProvider,
        memberDisplayMapProvider;

class PeriodBudgetScreen extends ConsumerWidget {
  const PeriodBudgetScreen({super.key});

  static const double _desktopBreakpoint = 800;
  static const double _contentMaxWidth = 860;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final period = ref.watch(selectedPeriodProvider);
    final entriesAsync = ref.watch(periodBudgetEntriesProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).periodBudget,
                  style: GoogleFonts.manrope(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  period.label,
                  style:
                      TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                tooltip: AppLocalizations.of(context).copyFromPrevious,
                onPressed: () => _copyFromPrevious(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _openEdit(context, null),
              ),
            ],
          ),
          entriesAsync.when(
            data: (entries) => entries.isEmpty
                ? _emptySliver(context, colors)
                : _listSliver(context, ref, entries, colors),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('${AppLocalizations.of(context).error}: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          if (!ref.watch(canWriteProvider)) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: 'fab_period_budget',
            onPressed: () => _openEdit(context, null),
            backgroundColor: tokens.FarolColors.beam,
            child: const Icon(Icons.add, color: tokens.FarolColors.navy),
          );
        },
      ),
    );
  }

  Widget _emptySliver(BuildContext context, FarolColors colors) =>
      SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline,
                  size: 48, color: colors.onSurfaceFaint),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).noBudgetsPeriod,
                  style:
                      TextStyle(color: colors.onSurfaceSoft, fontSize: 14)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).budgetsHint,
                  style: TextStyle(
                      color: colors.onSurfaceFaint, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _listSliver(
    BuildContext context,
    WidgetRef ref,
    List<PeriodBudgetEntry> entries,
    FarolColors colors,
  ) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final list = SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _EntryCard(
          entry: entries[i],
          isSwileBacked: _isSwileBacked(entries[i].category, ref),
          onTap: () => _openEdit(context, entries[i]),
          onAction: () => _handleAction(context, ref, entries[i]),
        ),
        childCount: entries.length,
      ),
    );

    if (isDesktop) {
      // Center the list with a max-width constraint on large screens.
      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        sliver: SliverLayoutBuilder(
          builder: (ctx, constraints) {
            final hPad = ((constraints.crossAxisExtent - _contentMaxWidth) / 2)
                .clamp(16.0, double.infinity);
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: list,
            );
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: list,
    );
  }

  void _openEdit(BuildContext context, PeriodBudgetEntry? entry) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isDesktop) {
      // On desktop open as a centered Dialog instead of a bottom sheet.
      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: BudgetEditSheet(entry: entry),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BudgetEditSheet(entry: entry),
      );
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    PeriodBudgetEntry entry,
  ) async {
    final hasGoal = entry.goal != null;
    final hasOverride = entry.overrideId != null;

    if (!hasOverride) return; // nothing to delete/reset

    final l10n = AppLocalizations.of(context);
    final label = hasGoal ? l10n.resetToGoal : l10n.deleteBudget;
    final body = hasGoal
        ? l10n.resetToGoalWithAmount(FinancialCalculatorService.formatBRL(entry.goal!.targetAmount))
        : l10n.removeBudget(_catLabel(entry.category, ref));
    final confirm = hasGoal ? l10n.reset : l10n.delete;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(ctx).cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirm,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(periodBudgetNotifierProvider.notifier)
          .delete(entry.overrideId!);
    }
  }

  Future<void> _copyFromPrevious(
      BuildContext context, WidgetRef ref) async {
    final count = await ref
        .read(periodBudgetNotifierProvider.notifier)
        .copyFromPreviousPeriod();
    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count > 0
            ? l10n.copiedBudgets(count)
            : l10n.noBudgetsToCopy),
        backgroundColor: count > 0 ? Colors.green : Colors.grey,
      ));
    }
  }

  String _catLabel(String dbValue, WidgetRef ref) {
    final catsMap = ref.read(categoriesMapProvider);
    return catsMap[dbValue]?.name ?? dbValue;
  }

  bool _isSwileBacked(String dbValue, WidgetRef ref) {
    final catsMap = ref.read(categoriesMapProvider);
    return catsMap[dbValue]?.isSwile ?? false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EntryCard extends ConsumerStatefulWidget {
  final PeriodBudgetEntry entry;
  final bool isSwileBacked;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _EntryCard({
    required this.entry,
    required this.isSwileBacked,
    required this.onTap,
    required this.onAction,
  });

  @override
  ConsumerState<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends ConsumerState<_EntryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final catsMap = ref.watch(categoriesMapProvider);
    final cat = catsMap[widget.entry.category] ??
        catsMap[widget.entry.category.toLowerCase()];

    final slug = widget.entry.category.toLowerCase();
    final envelopes = ref.watch(envelopesProvider);
    final envelope = envelopes.where((e) => e.category.slug == slug).firstOrNull;
    final rollover = envelope?.rolloverAmount ?? Money.zero;

    final pct = widget.entry.percentage.clamp(0.0, 1.0);

    final Color progressColor;
    switch (widget.entry.status) {
      case BudgetStatus.overspent:
        progressColor = Colors.red;
      case BudgetStatus.warning:
        progressColor = Colors.orange;
      case BudgetStatus.ok:
        progressColor = tokens.FarolColors.navy;
    }

    final bool hasStatusBorder = widget.entry.status != BudgetStatus.ok;
    final statusBorderColor = widget.entry.status == BudgetStatus.overspent
        ? Colors.red.withValues(alpha: 0.4)
        : Colors.orange.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.md),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: DSCard(
          onTap: widget.onTap,
          enableHover: true,
          padding: const EdgeInsets.all(DSSpacing.lg),
          borderColor: hasStatusBorder ? statusBorderColor : null,
          borderWidth: hasStatusBorder ? 1.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(cat?.emoji ?? '💰',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: DSSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat?.name ?? widget.entry.category,
                          style: GoogleFonts.manrope(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (widget.entry.isCustom && widget.entry.goalAmount != null)
                          Text(
                            AppLocalizations.of(context).budgetGoalLabel(FinancialCalculatorService.formatBRL(widget.entry.goalAmount!)),
                            style: TextStyle(
                                fontSize: 10, color: colors.onSurfaceFaint),
                          ),
                      ],
                    ),
                  ),
                  if (rollover.isPositive)
                    _BudgetBadge(
                      label: '+${rollover.formatted}',
                      color: const Color(0xFF1A7A5A),
                    ),
                  if (widget.isSwileBacked)
                    _BudgetBadge(
                      label: AppLocalizations.of(context).swileLabel,
                      color: const Color(0xFF00A86B),
                    )
                  else if (widget.entry.isCustom)
                    _BudgetBadge(
                      label: AppLocalizations.of(context).budgetCustomLabel,
                      color: tokens.FarolColors.navy,
                    ),
                  if (widget.entry.overrideId != null)
                    IconButton(
                      icon: Icon(
                        widget.entry.goal != null
                            ? Icons.restart_alt_outlined
                            : Icons.delete_outline,
                        size: 18,
                      ),
                      onPressed: widget.onAction,
                      color: colors.onSurfaceSoft,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: DSSpacing.sm + 2),
              DSProgressBar(
                value: pct,
                height: 6,
                color: progressColor,
                backgroundColor: colors.onSurfaceFaint.withValues(alpha: 0.15),
              ),
              const SizedBox(height: DSSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gasto: ${FinancialCalculatorService.formatBRL(widget.entry.spent)}',
                    style:
                        TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
                  ),
                  Text(
                    widget.entry.remaining >= 0
                        ? 'Restam: ${FinancialCalculatorService.formatBRL(widget.entry.remaining)}'
                        : 'Excedido: ${FinancialCalculatorService.formatBRL(widget.entry.remaining.abs())}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.entry.remaining < 0
                          ? Colors.red
                          : colors.onSurfaceMuted,
                    ),
                  ),
                  Text(
                    widget.isSwileBacked
                        ? 'do saldo Swile'
                        : 'de ${FinancialCalculatorService.formatBRL(widget.entry.amount)}',
                    style:
                        TextStyle(fontSize: 11, color: colors.onSurfaceFaint),
                  ),
                ],
              ),
              _BudgetLastEditLine(categorySlug: widget.entry.category.toLowerCase()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _BudgetBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: DSSpacing.xs + 2),
        padding:
            const EdgeInsets.symmetric(horizontal: DSSpacing.xs + 2, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: DSRadius.xsBR,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

// ── Budget last-edit attribution ──────────────────────────────────────────────

class _BudgetLastEditLine extends ConsumerWidget {
  const _BudgetLastEditLine({required this.categorySlug});
  final String categorySlug;

  String _timeLabel(DateTime changedAt) {
    final diff = DateTime.now().difference(changedAt);
    if (diff.inDays == 0) return 'hoje';
    if (diff.inDays == 1) return 'ontem';
    return '${diff.inDays}d atrás';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    if (!isShared) return const SizedBox.shrink();

    final changesMap = ref.watch(budgetChangesProvider).valueOrNull ?? {};
    final change = changesMap[categorySlug];
    if (change == null) return const SizedBox.shrink();

    final memberMap = ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
    final editor = memberMap[change.changedBy];
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final isSelf = change.changedBy == currentUserId;
    final name = isSelf ? 'Você' : (editor?.displayName ?? '${change.changedBy.substring(0, 8)}…');

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Último ajuste: $name · ${_timeLabel(change.changedAt)}',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
