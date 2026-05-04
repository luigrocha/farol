import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/farol_colors.dart';
import '../../../../design/farol_colors.dart' as tokens;
import '../../../../design/widgets/farol_card.dart';
import '../../../../design/widgets/brl_text.dart';

class PeriodFlowCard extends ConsumerWidget {
  const PeriodFlowCard({super.key});

  static const _monthNames = [
    '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final income = ref.watch(totalIncomeProvider);
    final expenses = ref.watch(cashExpensesProvider);
    final balance = ref.watch(monthlyBalanceProvider);
    final transfersAsync = ref.watch(periodTransfersProvider);
    final transferCount = transfersAsync.value?.length ?? 0;
    final isPrivate = ref.watch(privacyModeProvider);

    return FarolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(context.l10n.periodFlow,
                  style: GoogleFonts.manrope(
                      fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurfaceSoft, letterSpacing: 0.5)),
            ),
            Text('${_monthNames[month]} $year',
                style: GoogleFonts.manrope(fontSize: 12, color: colors.onSurfaceFaint)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _FlowBlock(label: context.l10n.income, value: income, color: tokens.FarolColors.tide, isPrivate: isPrivate),
            const SizedBox(width: 8),
            _FlowBlock(label: context.l10n.expenses, value: expenses, color: tokens.FarolColors.coral, isPrivate: isPrivate),
            const SizedBox(width: 8),
            _FlowBlock(
              label: context.l10n.monthlyBalance,
              value: balance,
              color: balance >= 0 ? tokens.FarolColors.tide : tokens.FarolColors.coral,
              isPrivate: isPrivate,
            ),
          ]),
          if (transferCount > 0) ...[
            const SizedBox(height: 12),
            Divider(color: colors.onSurfaceFaint.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.swap_horiz_rounded, size: 14, color: colors.onSurfaceSoft),
              const SizedBox(width: 6),
              Text(context.l10n.internalTransfers, style: GoogleFonts.manrope(fontSize: 12, color: colors.onSurfaceSoft)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$transferCount', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurface)),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _FlowBlock extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isPrivate;

  const _FlowBlock({required this.label, required this.value, required this.color, required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurfaceSoft)),
          const SizedBox(height: 4),
          isPrivate
              ? Text('•••', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: colors.onSurface))
              : BrlText(value: value.abs(), fontSize: 14, color: colors.onSurface),
        ]),
      ),
    );
  }
}
