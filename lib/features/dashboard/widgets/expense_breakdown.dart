import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/ds_tokens.dart';
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class ExpenseBreakdown extends ConsumerWidget {
  const ExpenseBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final goals = ref.watch(budgetGoalsMapProvider);
    final catsRef = {
      for (final c in ref.watch(categoriesRefProvider)) c.slug: c
    };
    final net = ref.watch(effectiveNetSalaryProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (byCategory.isEmpty) {
      return DSCard(
        padding:
            const EdgeInsets.symmetric(vertical: 36, horizontal: DSSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DSSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 28,
                color: colors.onSurfaceFaint,
              ),
            ),
            const SizedBox(height: DSSpacing.md),
            Text(
              l10n.translate('no_expenses'),
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: DSSpacing.xs),
            Text(
              l10n.translate('no_expenses_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
            ),
          ],
        ),
      );
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DSCard(
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.translate('expense_by_cat'),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gasto vs orçamento',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceSoft,
                      ),
                    ),
                  ],
                ),
              ),
              DSTextButton(
                label: 'Ver análise',
                onTap: () => Navigator.pushNamed(context, '/analytics'),
                icon: Icons.chevron_right_rounded,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),

          // ── Category rows ───────────────────────────────────────────────
          ...sorted.map((e) {
            final catDbValue = e.key;
            final actual = e.value;
            final goal = goals[catDbValue];
            final target =
                goal?.targetAmount ?? (net * kDefaultCategoryTargetRate);
            final ratio = actual / target;
            final pct = math.min(ratio, 1.0);

            final (barColor, statusIcon) = switch (true) {
              _ when ratio >= kAlertExceededThreshold => (
                  tokens.FarolColors.coral,
                  Icons.error_outline_rounded,
                ),
              _ when ratio >= kAlertCriticalThreshold => (
                  const Color(0xFFFF6B35),
                  Icons.warning_amber_rounded,
                ),
              _ when ratio >= kAlertWarningThreshold => (
                  tokens.FarolColors.beam,
                  Icons.info_outline_rounded,
                ),
              _ => (tokens.FarolColors.tide, null),
            };

            final catRef = catsRef[catDbValue];
            final label = catRef?.name ?? catDbValue;
            final emoji = catRef?.emoji ?? '💰';
            final isOverBudget = ratio >= kAlertWarningThreshold;

            return Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.lg),
              child: _CategoryBudgetRow(
                emoji: emoji,
                label: label,
                actual: actual,
                target: target,
                pct: pct,
                barColor: barColor,
                isOverBudget: isOverBudget,
                statusIcon: statusIcon,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryBudgetRow extends StatefulWidget {
  const _CategoryBudgetRow({
    required this.emoji,
    required this.label,
    required this.actual,
    required this.target,
    required this.pct,
    required this.barColor,
    required this.isOverBudget,
    required this.isDark,
    this.statusIcon,
  });

  final String emoji;
  final String label;
  final double actual;
  final double target;
  final double pct;
  final Color barColor;
  final bool isOverBudget;
  final bool isDark;
  final IconData? statusIcon;

  @override
  State<_CategoryBudgetRow> createState() => _CategoryBudgetRowState();
}

class _CategoryBudgetRowState extends State<_CategoryBudgetRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pctDisplay = (widget.pct * 100).round();
    final valueColor = widget.isOverBudget ? widget.barColor : colors.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: DSDuration.fast,
        padding: EdgeInsets.symmetric(
          horizontal: _hovered ? DSSpacing.md : DSSpacing.sm,
          vertical: _hovered ? DSSpacing.sm : DSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFF1B3A5C).withValues(alpha: 0.02))
              : Colors.transparent,
          borderRadius: DSRadius.smBR,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: emoji + label + amounts ──
            Row(
              children: [
                // Emoji icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.barColor.withValues(alpha: 0.10),
                    borderRadius: DSRadius.xsBR,
                  ),
                  child: Center(
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),

                // Label + status icon
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.statusIcon != null) ...[
                        Icon(widget.statusIcon!,
                            size: 12, color: widget.barColor),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: DSSpacing.sm),

                // Amounts: actual / target
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'R\$ ${widget.actual.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ' / R\$ ${widget.target.toInt()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceFaint,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                // Percentage badge
                const SizedBox(width: DSSpacing.sm),
                AnimatedContainer(
                  duration: DSDuration.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.barColor.withValues(
                      alpha: _hovered ? 0.18 : 0.10,
                    ),
                    borderRadius: DSRadius.xsBR,
                  ),
                  child: Text(
                    '$pctDisplay%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.barColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: DSSpacing.sm),

            // ── Row 2: animated progress bar ──
            DSProgressBar(
              value: widget.pct,
              color: widget.barColor,
              height: 5,
            ),
          ],
        ),
      ),
    );
  }
}
