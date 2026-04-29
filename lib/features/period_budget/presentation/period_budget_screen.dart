import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/period_budget.dart';
import '../../../core/models/financial_period.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import 'budget_edit_sheet.dart';

class PeriodBudgetScreen extends ConsumerWidget {
  const PeriodBudgetScreen({super.key});

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
                  'Period Budget',
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
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit period',
                onPressed: () => _showPeriodPicker(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                tooltip: 'Copy from previous period',
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
              child: Center(child: Text('Error: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context, null),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
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
              Text('No budgets for this period',
                  style:
                      TextStyle(color: colors.onSurfaceSoft, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Add budget goals in Settings to see defaults here',
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
  ) =>
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _EntryCard(
              entry: entries[i],
              isSwileBacked: _isSwileBacked(entries[i].category, ref),
              onTap: () => _openEdit(context, entries[i]),
              onAction: () => _handleAction(context, ref, entries[i]),
            ),
            childCount: entries.length,
          ),
        ),
      );

  void _openEdit(BuildContext context, PeriodBudgetEntry? entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetEditSheet(entry: entry),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    PeriodBudgetEntry entry,
  ) async {
    final hasGoal = entry.goal != null;
    final hasOverride = entry.overrideId != null;

    if (!hasOverride) return; // nothing to delete/reset

    final label = hasGoal ? 'Reset to goal amount?' : 'Delete budget?';
    final body = hasGoal
        ? 'This will remove the custom amount and revert to your goal (${FinancialCalculatorService.formatBRL(entry.goal!.targetAmount)}).'
        : 'Remove budget for ${_catLabel(entry.category, ref)}?';
    final confirm = hasGoal ? 'Reset' : 'Delete';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count > 0
            ? 'Copied $count budget(s) from previous period'
            : 'No new budgets to copy'),
        backgroundColor: count > 0 ? Colors.green : Colors.grey,
      ));
    }
  }

  Future<void> _showPeriodPicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedPeriodProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: current.start, end: current.end),
    );
    if (picked != null) {
      ref.read(selectedPeriodProvider.notifier).setPeriod(
        FinancialPeriod(start: picked.start, end: picked.end),
      );
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

class _EntryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final catsMap = ref.watch(categoriesMapProvider);
    final cat = catsMap[entry.category];
    
    final pct = entry.percentage.clamp(0.0, 1.0);

    final Color progressColor;
    switch (entry.status) {
      case BudgetStatus.overspent:
        progressColor = Colors.red;
      case BudgetStatus.warning:
        progressColor = Colors.orange;
      case BudgetStatus.ok:
        progressColor = tokens.FarolColors.navy;
    }

    final bool hasBorder = entry.status != BudgetStatus.ok;
    final borderColor = entry.status == BudgetStatus.overspent
        ? Colors.red.withValues(alpha: 0.4)
        : Colors.orange.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: hasBorder
              ? Border.all(color: borderColor, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(cat?.emoji ?? '💰',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat?.name ?? entry.category,
                        style: GoogleFonts.manrope(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (entry.isCustom && entry.goalAmount != null)
                        Text(
                          'Goal: ${FinancialCalculatorService.formatBRL(entry.goalAmount!)}',
                          style: TextStyle(
                              fontSize: 10, color: colors.onSurfaceFaint),
                        ),
                    ],
                  ),
                ),
                if (isSwileBacked)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A86B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Swile',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00A86B),
                      ),
                    ),
                  )
                else if (entry.isCustom)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.iconTintBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: tokens.FarolColors.navy,
                      ),
                    ),
                  ),
                if (entry.overrideId != null)
                  IconButton(
                    icon: Icon(
                      entry.goal != null
                          ? Icons.restart_alt_outlined
                          : Icons.delete_outline,
                      size: 18,
                    ),
                    onPressed: onAction,
                    color: colors.onSurfaceSoft,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor:
                    colors.onSurfaceFaint.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${FinancialCalculatorService.formatBRL(entry.spent)}',
                  style: TextStyle(
                      fontSize: 11, color: colors.onSurfaceSoft),
                ),
                Text(
                  entry.remaining >= 0
                      ? 'Left: ${FinancialCalculatorService.formatBRL(entry.remaining)}'
                      : 'Over: ${FinancialCalculatorService.formatBRL(entry.remaining.abs())}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: entry.remaining < 0
                        ? Colors.red
                        : colors.onSurfaceMuted,
                  ),
                ),
                Text(
                  isSwileBacked
                      ? 'of Swile balance'
                      : 'of ${FinancialCalculatorService.formatBRL(entry.amount)}',
                  style: TextStyle(
                      fontSize: 11, color: colors.onSurfaceFaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
