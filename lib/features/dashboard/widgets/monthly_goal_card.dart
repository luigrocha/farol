import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/i18n/app_localizations.dart';
import '../utils/dashboard_constants.dart';

class MonthlyGoalCard extends ConsumerWidget {
  const MonthlyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final net = ref.watch(effectiveNetSalaryProvider);
    final cash = ref.watch(cashExpensesProvider);
    final target = net * kSavingsGoalRate;
    final saved = net - cash;
    final pct = (saved / target).clamp(0.0, 1.0);
    final remaining = math.max(target - saved, 0.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('monthly_goal'),
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceSoft,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '${AppLocalizations.of(context).translate('missing')} ',
                  ),
                  TextSpan(
                    text: FinancialCalculatorService.formatBRL(remaining),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' ${AppLocalizations.of(context).translate('to_reach_goal')}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSpacingLG),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: colors.secondaryContainer,
                      valueColor: const AlwaysStoppedAnimation(tokens.FarolColors.beam),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingMD),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.FarolColors.beam,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
