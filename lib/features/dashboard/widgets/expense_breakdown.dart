import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class ExpenseBreakdown extends ConsumerWidget {
  const ExpenseBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final goals = ref.watch(budgetGoalsMapProvider);
    final catsMap = ref.watch(categoriesMapProvider);
    final net = ref.watch(effectiveNetSalaryProvider);
    final l10n = AppLocalizations.of(context);

    if (byCategory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: colors.onSurfaceSoft,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('no_expenses'),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('no_expenses_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.translate('expense_by_cat'),
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'ACTUAL VS PRESUPUESTO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: colors.onSurfaceSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...sorted.map((e) {
              final catDbValue = e.key;
              final actual = e.value;
              final goal = goals[catDbValue];
              final target = goal?.targetAmount ?? (net * kDefaultCategoryTargetRate);
              final ratio = actual / target;
              final pct = math.min(ratio, 1.0);
              final barColor = ratio >= kAlertExceededThreshold
                  ? tokens.FarolColors.coral
                  : ratio >= kAlertCriticalThreshold
                      ? const Color(0xFFFF6B35)
                      : ratio >= kAlertWarningThreshold
                          ? tokens.FarolColors.beam
                          : tokens.FarolColors.tide;
              final labelColor = ratio >= kAlertWarningThreshold ? barColor : colors.onSurfaceSoft;

              final catModel = catsMap[catDbValue];
              final label = catModel?.name ?? catDbValue;
              final emoji = catModel?.emoji ?? '💰';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (ratio >= kAlertWarningThreshold) ...[
                              Icon(
                                ratio >= kAlertExceededThreshold
                                    ? Icons.error_outline
                                    : Icons.warning_amber_outlined,
                                size: 13,
                                color: barColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '$emoji $label',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'R\$ ${actual.toInt()} / R\$ ${target.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: labelColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kSpacingSM),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: colors.surfaceLow,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
