import 'package:farol/design/branding/farol_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/ds_tokens.dart';
import 'shared/brl_display.dart';

class PeriodBalanceHero extends ConsumerStatefulWidget {
  const PeriodBalanceHero({super.key});

  @override
  ConsumerState<PeriodBalanceHero> createState() => _PeriodBalanceHeroState();
}

class _PeriodBalanceHeroState extends ConsumerState<PeriodBalanceHero>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: DSDuration.normal);
    _scale = Tween(begin: 1.0, end: 1.008).animate(
      CurvedAnimation(parent: _ctrl, curve: DSCurve.smooth),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snap = ref.watch(financialSnapshotProvider);
    final projAsync = ref.watch(financialProjectionProvider);

    final balance = snap.currentBalance.amount;
    final income = snap.totalIncome.amount;
    final expenses = snap.cashSpent.amount;
    final isPositive = snap.isPositive;
    final projectedClosing = projAsync.value?.projectedClosingBalance;
    final savingsRate = snap.savingsRate;

    // Premium dark gradient: deep navy-teal for positive, dark wine for negative
    final gradientColors = isPositive
        ? FarolBrand.heroGradientPositive
        : FarolBrand.heroGradientNegative;

    final accentColor = isPositive
        ? const Color(0xFF2EB06A)
        : const Color(0xFFFF6B6B);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/patrimonio'),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: Container(
            padding: const EdgeInsets.all(DSSpacing.xxl),
            decoration: BoxDecoration(
              borderRadius: DSRadius.xlBR,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPositive
                      ? FarolBrand.heroShadowPositive
                      : FarolBrand.heroShadowNegative).withValues(alpha: 0.30),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: label + nav arrow ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: DSRadius.fullBR,
                      ),
                      child: Text(
                        l10n.periodBalanceTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _HeroPrivacyBtn(),
                    const SizedBox(width: DSSpacing.xs),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.4,
                      duration: DSDuration.normal,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: DSRadius.smBR,
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DSSpacing.lg),

                // ── Main balance number ──────────────────────────────────────
                BrlBig(value: balance, size: 38, color: Colors.white),

                const SizedBox(height: DSSpacing.sm),

                // ── Projection line ──────────────────────────────────────────
                if (projectedClosing != null) ...[
                  Row(children: [
                    Icon(
                      projectedClosing.isNegative
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                      size: 13,
                      color: projectedClosing.isNegative
                          ? const Color(0xFFFF8A80)
                          : Colors.white38,
                    ),
                    const SizedBox(width: DSSpacing.xs),
                    Flexible(
                      child: Text(
                        l10n.periodProjectionClosing(
                          FinancialCalculatorService.formatBRL(
                            projectedClosing.amount,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: projectedClosing.isNegative
                              ? const Color(0xFFFF8A80)
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: DSSpacing.xl),
                ] else
                  const SizedBox(height: DSSpacing.xl),

                // ── Subtle gradient divider ──────────────────────────────────
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: DSSpacing.lg),

                // ── Bottom stats row ─────────────────────────────────────────
                Row(
                  children: [
                    _HeroStat(
                      label: l10n.periodIncomes,
                      value: income,
                      color: accentColor,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    const SizedBox(width: DSSpacing.xl),
                    _HeroStat(
                      label: l10n.periodExpenses,
                      value: expenses,
                      color: tokens.FarolColors.coral.withValues(alpha: 0.9),
                      icon: Icons.arrow_upward_rounded,
                    ),
                    const Spacer(),
                    // Savings rate pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.md,
                        vertical: DSSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: DSRadius.fullBR,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${savingsRate.toStringAsFixed(1)}%',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            'POUPADO',
                            style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        BrlSmall(
          value: value,
          size: 15,
          weight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ],
    );
  }
}

// ── Hero privacy button ───────────────────────────────────────────────────────

class _HeroPrivacyBtn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider);
    return GestureDetector(
      onTap: () => ref.read(privacyModeProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: DSDuration.fast,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isPrivate ? 0.18 : 0.10),
          borderRadius: DSRadius.smBR,
          border: Border.all(
            color: Colors.white.withValues(alpha: isPrivate ? 0.35 : 0.0),
            width: 1,
          ),
        ),
        child: Icon(
          isPrivate ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 13,
          color: Colors.white.withValues(alpha: isPrivate ? 1.0 : 0.55),
        ),
      ),
    );
  }
}

/// Compact mini-stat (legacy compat for other files that import MiniStat)
class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        BrlSmall(value: value, size: 14, weight: FontWeight.w700, color: color),
      ],
    );
  }
}
