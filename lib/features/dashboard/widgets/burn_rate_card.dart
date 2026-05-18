import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/domain/entities/burn_rate.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../design/ds_tokens.dart';

class BurnRateCard extends ConsumerWidget {
  const BurnRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final projAsync = ref.watch(financialProjectionProvider);

    return projAsync.when(
      loading: () => const DashboardCardSkeleton(height: 140),
      error: (_, __) => const SizedBox.shrink(),
      data: (proj) {
        if (proj == null) return const SizedBox.shrink();
        final br = proj.burnRate;
        if (br.daysElapsed == 0) return const SizedBox.shrink();

        final (accentColor, paceLabel, paceIcon) = switch (br.pace) {
          BurnPace.comfortable => (
              const Color(0xFF1A7A4A),
              l10n.burnPaceComfortable,
              Icons.check_circle_outline_rounded,
            ),
          BurnPace.onTrack => (
              const Color(0xFFF5A623),
              l10n.burnPaceOnTrack,
              Icons.remove_circle_outline_rounded,
            ),
          BurnPace.overspending => (
              const Color(0xFFE84855),
              l10n.burnPaceOverspending,
              Icons.warning_amber_rounded,
            ),
        };

        return DSCard(
          borderColor: accentColor.withValues(alpha: 0.20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: DSRadius.smBR,
                    ),
                    child: Icon(
                      Icons.speed_rounded,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.burnRateTitle,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Pace badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: DSRadius.fullBR,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(paceIcon, size: 11, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          paceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DSSpacing.lg),

              // ── Metrics row ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _BurnMetric(
                      label: l10n.burnDailyRateLabel,
                      value: FinancialCalculatorService.formatBRL(
                        br.dailyRate.amount,
                      ),
                      color: accentColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: DSSpacing.lg),
                      child: _BurnMetric(
                        label: l10n.burnProjectionLabel,
                        value: FinancialCalculatorService.formatBRL(
                          br.projectedTotalSpend.amount,
                        ),
                        color: br.pace == BurnPace.overspending
                            ? const Color(0xFFE84855)
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: DSSpacing.lg),
                    child: _BurnMetric(
                      label: l10n.burnDaysRemaining,
                      value: '${br.daysRemaining}d',
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DSSpacing.lg),

              // ── Pace bar ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.burnPaceVsBudget,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  Text(
                    '${(br.paceVsBudget * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.xs),
              DSProgressBar(
                value: br.paceVsBudget.clamp(0.0, 1.0),
                color: accentColor,
                height: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BurnMetric extends StatelessWidget {
  const _BurnMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: onSurface.withValues(alpha: 0.45),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? onSurface,
          ),
        ),
      ],
    );
  }
}
