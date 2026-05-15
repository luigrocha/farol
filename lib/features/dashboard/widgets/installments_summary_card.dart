import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/domain/entities/installment_plan.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../design/ds_tokens.dart';
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class InstallmentsSummaryCard extends ConsumerWidget {
  const InstallmentsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final instAsync = ref.watch(activeInstallmentPlansProvider);

    if (instAsync.isLoading) {
      return const DashboardCardSkeleton(height: 120);
    }

    final installments = instAsync.value ?? [];
    if (installments.isEmpty) return const SizedBox.shrink();

    final totalMonthly = installments.fold(0.0, (s, i) => s + i.installmentAmount);
    final totalRemaining = installments.fold(0.0, (s, i) => s + i.remainingAmount);

    return DSCard(
      onTap: () => Navigator.pushNamed(context, '/installments'),
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kInstallmentsCardColor.withValues(alpha: 0.12),
                  borderRadius: DSRadius.smBR,
                ),
                child: const Center(
                  child: Text('💳', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Parcelas',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
              ),
              DSTextButton(
                label: 'Ver todas',
                onTap: () => Navigator.pushNamed(context, '/installments'),
                icon: Icons.chevron_right_rounded,
                color: kInstallmentsCardColor,
              ),
            ],
          ),

          const SizedBox(height: DSSpacing.lg),

          // ── Summary metrics ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InstallmentMetric(
                  label: 'MENSAL',
                  value: FinancialCalculatorService.formatBRL(totalMonthly),
                  valueColor: kInstallmentsCardColor,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: colors.surfaceLow,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: DSSpacing.lg),
                  child: _InstallmentMetric(
                    label: 'SALDO RESTANTE',
                    value: FinancialCalculatorService.formatBRL(totalRemaining),
                    valueColor: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DSSpacing.lg),

          // ── Individual installment rows ──────────────────────────────────
          ...installments.take(3).map((inst) => Padding(
                padding: const EdgeInsets.only(bottom: DSSpacing.sm),
                child: _InstallmentRow(inst: inst),
              )),
        ],
      ),
    );
  }
}

class _InstallmentMetric extends StatelessWidget {
  const _InstallmentMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({required this.inst});

  final InstallmentPlan inst;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                inst.description,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: DSSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: kInstallmentsCardColor.withValues(alpha: 0.08),
                borderRadius: DSRadius.xsBR,
              ),
              child: Text(
                '${inst.paidCount}/${inst.numInstallments}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kInstallmentsCardColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.xs),
        DSProgressBar(
          value: inst.progressPercent,
          color: kInstallmentsCardColor,
          height: 4,
        ),
        const SizedBox(height: DSSpacing.xs),
      ],
    );
  }
}
