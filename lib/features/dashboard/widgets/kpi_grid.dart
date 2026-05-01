import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import 'shared/brl_display.dart';

class KpiGrid extends ConsumerWidget {
  const KpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final net = ref.watch(effectiveNetSalaryProvider);
    final swile = ref.watch(effectiveSwileProvider);
    final cash = ref.watch(cashExpensesProvider);
    final cashRemaining = ref.watch(cashRemainingProvider);
    final swileRemaining = ref.watch(swileRemainingProvider);
    final sr = ref.watch(effectiveSavingsRateProvider);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        KpiCard(
          icon: Icons.account_balance_wallet,
          bg: colors.iconTintBlue,
          label: l10n.translate('net_salary'),
          value: net,
        ),
        KpiCard(
          icon: Icons.fastfood,
          bg: colors.secondaryContainer,
          label: l10n.translate('swile'),
          value: swile,
          color: tokens.FarolColors.beam,
        ),
        KpiCard(
          icon: Icons.account_balance,
          bg: cashRemaining >= 0 ? colors.secondaryContainer : colors.iconTintRed,
          label: l10n.translate('available_total'),
          value: cashRemaining,
          color: cashRemaining >= 0 ? tokens.FarolColors.beam : tokens.FarolColors.coral,
        ),
        KpiCard(
          icon: Icons.trending_down,
          bg: colors.iconTintRed,
          label: l10n.translate('cash_expenses'),
          value: cash,
          color: tokens.FarolColors.coral,
        ),
        KpiCard(
          icon: Icons.restaurant,
          bg: swileRemaining >= 0 ? colors.secondaryContainer : colors.iconTintRed,
          label: l10n.translate('swile_remaining'),
          value: swileRemaining,
          color: swileRemaining >= 0 ? tokens.FarolColors.beam : tokens.FarolColors.coral,
        ),
        KpiCard(
          icon: Icons.savings,
          bg: colors.iconTintBlue,
          label: l10n.translate('savings_rate'),
          raw: '${sr.toStringAsFixed(1)}%',
        ),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final String label;
  final double? value;
  final String? raw;
  final Color? color;
  const KpiCard({
    super.key,
    required this.icon,
    required this.bg,
    required this.label,
    this.value,
    this.raw,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (label.toLowerCase().contains('swile')) {
            Navigator.pushNamed(context, '/swile');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color ?? colors.onSurface),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            raw != null
                ? Text(
                    raw!,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color ?? colors.onSurface,
                    ),
                  )
                : BrlSmall(
                    value: value ?? 0,
                    size: 15,
                    weight: FontWeight.w700,
                    color: color,
                  ),
          ],
        ),
      ),
    );
  }
}
