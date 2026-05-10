import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/domain/entities/liquidity_risk.dart';
import '../../../core/domain/entities/scheduled_payment.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';

class LiquidityAlertCard extends ConsumerWidget {
  const LiquidityAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final projAsync = ref.watch(financialProjectionProvider);

    return projAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (proj) {
        if (proj == null) return const SizedBox.shrink();
        final risk = proj.liquidityRisk;
        if (!risk.isAtRisk) return const SizedBox.shrink();

        final (color, icon, title) = switch (risk.level) {
          LiquidityRiskLevel.critical => (
              Colors.red,
              Icons.warning_amber_rounded,
              l10n.liquidityCriticalTitle,
            ),
          LiquidityRiskLevel.high => (
              Colors.deepOrange,
              Icons.warning_outlined,
              l10n.liquidityHighTitle,
            ),
          LiquidityRiskLevel.medium => (
              const Color(0xFFF59E0B),
              Icons.info_outline,
              l10n.liquidityMediumTitle,
            ),
          _ => (Colors.grey, Icons.info_outline, ''),
        };

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBreakdown(context, risk),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: GoogleFonts.manrope(
                            fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(l10n, risk),
                      style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey),
                    ),
                  ]),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ]),
            ),
          ),
        );
      },
    );
  }

  String _subtitle(AppLocalizations l10n, LiquidityRisk risk) {
    final total = FinancialCalculatorService.formatBRL(
        risk.obligationsNext7Days.amount);
    final n = risk.upcomingObligations.length;
    if (risk.daysUntilEmpty >= 0 && risk.daysUntilEmpty <= 14) {
      return l10n.liquidityDaysToZero('${risk.daysUntilEmpty}');
    }
    if (n > 0) {
      return l10n.liquidityObligationsThisWeek(total, n);
    }
    return l10n.liquidityCheckUpcoming;
  }

  void _showBreakdown(BuildContext context, LiquidityRisk risk) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ObligationsSheet(risk: risk),
    );
  }
}

class _ObligationsSheet extends StatelessWidget {
  const _ObligationsSheet({required this.risk});
  final LiquidityRisk risk;

  @override
  Widget build(BuildContext context) {
    final obligations = risk.upcomingObligations;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        Text(context.l10n.liquiditySheetTitle,
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (obligations.isEmpty)
          Text(context.l10n.liquidityNoCommitments,
              style: GoogleFonts.manrope(color: Colors.grey))
        else
          ...obligations.map((p) => _ObligationRow(payment: p)),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade200),
        Row(children: [
          Text(context.l10n.liquidityTotal,
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            FinancialCalculatorService.formatBRL(risk.obligationsNext7Days.amount),
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red),
          ),
        ]),
      ]),
    );
  }
}

class _ObligationRow extends StatelessWidget {
  const _ObligationRow({required this.payment});
  final ScheduledPayment payment;

  @override
  Widget build(BuildContext context) {
    final d = payment.dueDate;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    final overdue = payment.isOverdue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(
          payment.type == ScheduledPaymentType.installment
              ? Icons.credit_card_outlined
              : Icons.repeat_rounded,
          size: 14,
          color: overdue ? Colors.red : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(payment.description,
              style: GoogleFonts.manrope(fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
        Text(dateStr,
            style: GoogleFonts.manrope(
                fontSize: 11,
                color: overdue ? Colors.red : Colors.grey)),
        const SizedBox(width: 12),
        Text(FinancialCalculatorService.formatBRL(payment.amount.amount),
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
