import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class InstallmentsSummaryCard extends ConsumerWidget {
  const InstallmentsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final instAsync = ref.watch(installmentsProvider);

    if (instAsync.isLoading) {
      return const DashboardCardSkeleton(height: 100);
    }

    final installments = instAsync.value ?? [];

    if (installments.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalMonthly = installments.fold(
      0.0,
      (s, i) => s + i.monthlyAmount,
    );
    final totalRemaining = installments.fold(
      0.0,
      (s, i) => s + i.remainingBalance,
    );

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/installments'),
      child: Container(
        padding: const EdgeInsets.all(kCardPadding),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kInstallmentsCardColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('💳', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: kSpacingMD),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parcelas',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          '${installments.length} ativa${installments.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'Ver todas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kInstallmentsCardColor,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: kInstallmentsCardColor,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: kSpacingXL),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MENSAL',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceFaint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        FinancialCalculatorService.formatBRL(totalMonthly),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInstallmentsCardColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: colors.surfaceLow,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: kSpacingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SALDO RESTANTE',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceFaint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          FinancialCalculatorService.formatBRL(totalRemaining),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingXL),
            ...installments.take(3).map((inst) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              inst.description,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${inst.currentInstallment}/${inst.numInstallments}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceSoft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: inst.progressPercent,
                          minHeight: 4,
                          backgroundColor:
                              kInstallmentsCardColor.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(
                            kInstallmentsCardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
