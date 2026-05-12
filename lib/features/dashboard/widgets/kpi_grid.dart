import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import 'shared/brl_display.dart';

class KpiGrid extends ConsumerWidget {
  /// When false, cards use larger padding and font sizes (desktop layout).
  final bool compact;
  const KpiGrid({super.key, this.compact = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final snap = ref.watch(financialSnapshotProvider);

    final net = snap.cashIncome.amount;
    final swile = snap.swileIncome.amount;
    final cash = snap.cashSpent.amount;
    final cashRemaining = snap.currentBalance.amount;
    final swileRemaining = snap.swileBalance.amount;
    final sr = snap.savingsRate;

    final items = [
      KpiCard(
        icon: Icons.account_balance_wallet,
        bg: colors.iconTintBlue,
        label: l10n.translate('net_salary'),
        value: net,
        compact: compact,
      ),
      KpiCard(
        icon: Icons.fastfood,
        bg: colors.secondaryContainer,
        label: l10n.translate('swile'),
        value: swile,
        color: tokens.FarolColors.beam,
        compact: compact,
      ),
      KpiCard(
        icon: Icons.account_balance,
        bg: cashRemaining >= 0 ? colors.secondaryContainer : colors.iconTintRed,
        label: l10n.translate('available_total'),
        value: cashRemaining,
        color: cashRemaining >= 0 ? tokens.FarolColors.beam : tokens.FarolColors.coral,
        compact: compact,
      ),
      KpiCard(
        icon: Icons.trending_down,
        bg: colors.iconTintRed,
        label: l10n.translate('cash_expenses'),
        value: cash,
        color: tokens.FarolColors.coral,
        compact: compact,
      ),
      KpiCard(
        icon: Icons.restaurant,
        bg: swileRemaining >= 0 ? colors.secondaryContainer : colors.iconTintRed,
        label: l10n.translate('swile_remaining'),
        value: swileRemaining,
        color: swileRemaining >= 0 ? tokens.FarolColors.beam : tokens.FarolColors.coral,
        compact: compact,
      ),
      KpiCard(
        icon: Icons.savings,
        bg: colors.iconTintBlue,
        label: l10n.translate('savings_rate'),
        raw: '${sr.toStringAsFixed(1)}%',
        compact: compact,
      ),
    ];

    // Build rows of 2, each row uses IntrinsicHeight so cells expand to
    // match their tallest sibling — avoids fixed-ratio overflow.
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final hasSecond = i + 1 < items.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: items[i]),
              const SizedBox(width: 8),
              Expanded(child: hasSecond ? items[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: 8));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
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
  /// When false (desktop), uses larger padding and font sizes.
  final bool compact;
  const KpiCard({
    super.key,
    required this.icon,
    required this.bg,
    required this.label,
    this.value,
    this.raw,
    this.color,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pad = compact ? 14.0 : 18.0;
    final iconSize = compact ? 28.0 : 36.0;
    final iconInner = compact ? 16.0 : 20.0;
    final labelSize = compact ? 11.0 : 12.0;
    final valueSize = compact ? 18.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(pad),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(compact ? 8 : 10),
              ),
              child: Icon(icon, size: iconInner, color: color ?? colors.onSurface),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                color: colors.onSurfaceSoft,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            raw != null
                ? Text(
                    raw!,
                    style: GoogleFonts.manrope(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      color: color ?? colors.onSurface,
                    ),
                  )
                : BrlSmall(
                    value: value ?? 0,
                    size: compact ? 15 : 18,
                    weight: FontWeight.w700,
                    color: color,
                  ),
          ],
        ),
      ),
    );
  }
}
