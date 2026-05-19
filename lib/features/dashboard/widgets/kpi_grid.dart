import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/ds_tokens.dart';
import '../../../core/theme/farol_colors.dart';
import 'shared/brl_display.dart';

class KpiGrid extends ConsumerWidget {
  /// When false, cards use larger padding and font sizes (desktop layout).
  final bool compact;
  const KpiGrid({super.key, this.compact = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(financialSnapshotProvider);

    final net = snap.cashIncome.amount;
    final swile = snap.swileIncome.amount;
    final cash = snap.cashSpent.amount;
    final cashRemaining = snap.currentBalance.amount;
    final swileRemaining = snap.swileBalance.amount;
    final sr = snap.savingsRate;

    final items = [
      _KpiItem(
        icon: Icons.account_balance_wallet_outlined,
        iconBg: const Color(0xFFE3ECFA),
        iconBgDark: const Color(0xFF162637),
        iconColor: tokens.FarolColors.navy,
        label: l10n.translate('net_salary'),
        value: net,
        route: null,
        compact: compact,
      ),
      _KpiItem(
        icon: Icons.restaurant_outlined,
        iconBg: const Color(0xFFFDF1DB),
        iconBgDark: const Color(0xFF2C1F05),
        iconColor: tokens.FarolColors.beam,
        label: l10n.translate('swile'),
        value: swile,
        valueColor: tokens.FarolColors.beam,
        route: '/swile',
        compact: compact,
      ),
      _KpiItem(
        icon: cashRemaining >= 0
            ? Icons.savings_outlined
            : Icons.warning_amber_rounded,
        iconBg: cashRemaining >= 0
            ? const Color(0xFFE6F7EE)
            : const Color(0xFFFDE7E5),
        iconBgDark: cashRemaining >= 0
            ? const Color(0xFF0D2E1A)
            : const Color(0xFF2D1215),
        iconColor: cashRemaining >= 0
            ? tokens.FarolColors.tide
            : tokens.FarolColors.coral,
        label: l10n.translate('available_total'),
        value: cashRemaining,
        valueColor: cashRemaining >= 0
            ? tokens.FarolColors.tide
            : tokens.FarolColors.coral,
        route: null,
        compact: compact,
      ),
      _KpiItem(
        icon: Icons.trending_down_rounded,
        iconBg: const Color(0xFFFDE7E5),
        iconBgDark: const Color(0xFF2D1215),
        iconColor: tokens.FarolColors.coral,
        label: l10n.translate('cash_expenses'),
        value: cash,
        valueColor: tokens.FarolColors.coral,
        route: '/transactions',
        compact: compact,
      ),
      _KpiItem(
        icon: swileRemaining >= 0
            ? Icons.fastfood_outlined
            : Icons.money_off_rounded,
        iconBg: swileRemaining >= 0
            ? const Color(0xFFFDF1DB)
            : const Color(0xFFFDE7E5),
        iconBgDark: swileRemaining >= 0
            ? const Color(0xFF2C1F05)
            : const Color(0xFF2D1215),
        iconColor: swileRemaining >= 0
            ? tokens.FarolColors.beam
            : tokens.FarolColors.coral,
        label: l10n.translate('swile_remaining'),
        value: swileRemaining,
        valueColor: swileRemaining >= 0
            ? tokens.FarolColors.beam
            : tokens.FarolColors.coral,
        route: '/swile',
        compact: compact,
      ),
      _KpiItem(
        icon: Icons.percent_rounded,
        iconBg: const Color(0xFFE3ECFA),
        iconBgDark: const Color(0xFF162637),
        iconColor: tokens.FarolColors.navy,
        label: l10n.translate('savings_rate'),
        rawValue: '${sr.toStringAsFixed(1)}%',
        route: null,
        compact: compact,
      ),
    ];

    // Pairs of 2: IntrinsicHeight so both cells match the tallest sibling
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final hasSecond = i + 1 < items.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: items[i]),
              const SizedBox(width: DSSpacing.sm),
              Expanded(child: hasSecond ? items[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: DSSpacing.sm));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

class _KpiItem extends StatefulWidget {
  const _KpiItem({
    required this.icon,
    required this.iconBg,
    required this.iconBgDark,
    required this.iconColor,
    required this.label,
    this.value,
    this.rawValue,
    this.valueColor,
    this.route,
    this.compact = true,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconBgDark;
  final Color iconColor;
  final String label;
  final double? value;
  final String? rawValue;
  final Color? valueColor;
  final String? route;
  final bool compact;

  @override
  State<_KpiItem> createState() => _KpiItemState();
}

class _KpiItemState extends State<_KpiItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: DSDuration.normal);
    _anim = CurvedAnimation(parent: _ctrl, curve: DSCurve.smooth);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    final pad = widget.compact ? 14.0 : 18.0;
    final iconSize = widget.compact ? 30.0 : 36.0;
    final iconInner = widget.compact ? 16.0 : 19.0;
    final labelSize = widget.compact ? 10.0 : 11.0;
    final valueSize = widget.compact ? 16.0 : 20.0;
    final radius = widget.compact ? DSRadius.lg : DSRadius.xl;

    final bgColor = isDark ? colors.surfaceLowest : Colors.white;
    final iconBg = isDark ? widget.iconBgDark : widget.iconBg;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      cursor: widget.route != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.route != null
            ? () => Navigator.pushNamed(context, widget.route!)
            : null,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final shadows = isDark
                ? (_hovered ? DSShadow.cardDarkHover : DSShadow.cardDark)
                : (_hovered ? DSShadow.cardHover : DSShadow.card);
            final border = isDark
                ? Colors.white.withValues(alpha: _hovered ? 0.12 : 0.07)
                : const Color(0xFF1B3A5C)
                    .withValues(alpha: _hovered ? 0.10 : 0.06);

            return Transform.translate(
              offset: Offset(0, _anim.value * -2),
              child: Container(
                padding: EdgeInsets.all(pad),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: border, width: 1),
                  boxShadow: shadows,
                ),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(iconSize * 0.30),
                ),
                child:
                    Icon(widget.icon, size: iconInner, color: widget.iconColor),
              ),
              const SizedBox(height: DSSpacing.md),
              // Label
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: labelSize,
                  color: colors.onSurfaceSoft,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Value
              widget.rawValue != null
                  ? Text(
                      widget.rawValue!,
                      style: GoogleFonts.manrope(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w800,
                        color: widget.valueColor ?? colors.onSurface,
                      ),
                    )
                  : BrlSmall(
                      value: widget.value ?? 0,
                      size: widget.compact ? 15 : 18,
                      weight: FontWeight.w700,
                      color: widget.valueColor,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Backwards compat export
class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final String label;
  final double? value;
  final String? raw;
  final Color? color;
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

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        boxShadow: DSShadow.card,
      ),
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
            child:
                Icon(icon, size: iconInner, color: color ?? colors.onSurface),
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
                    fontSize: compact ? 18.0 : 20.0,
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
    );
  }
}
