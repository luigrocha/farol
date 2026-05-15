import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/health_gauge.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../design/ds_tokens.dart';
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class HealthGaugeCard extends ConsumerWidget {
  const HealthGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final snap = ref.watch(financialSnapshotProvider);

    ref.watch(healthAutoSaveProvider);

    final isLoading = ref.watch(netWorthSnapshotProvider).isLoading ||
        ref.watch(activeInstallmentPlansProvider).isLoading;
    if (isLoading) return const DashboardCardSkeleton(height: 200);

    final score = snap.healthScore;

    final (statusLabel, description, healthColor) = switch (score) {
      < 4 => (
          l10n.healthCritical,
          l10n.healthCriticalDesc,
          const Color(0xFFE84855),
        ),
      < 5 => (
          l10n.healthWarning,
          l10n.healthFairDesc,
          const Color(0xFFFF6B35),
        ),
      < 7 => (
          l10n.healthWarning,
          l10n.healthGoodDesc,
          const Color(0xFFF5A623),
        ),
      _ => (
          l10n.healthHealthy,
          l10n.healthExcellentDesc,
          const Color(0xFF1A7A4A),
        ),
    };

    return DSCard(
      onTap: () => Navigator.pushNamed(context, '/health'),
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                l10n.healthScore,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.12),
                  borderRadius: DSRadius.fullBR,
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: healthColor,
                  ),
                ),
              ),
              const SizedBox(width: DSSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: colors.onSurfaceFaint,
              ),
            ],
          ),

          const SizedBox(height: DSSpacing.lg),

          // ── Gauge ───────────────────────────────────────────────────────
          HealthGauge(
            score: score.toDouble() * 10,
            size: kHealthGaugeSize,
            statusLabel: statusLabel,
          ),

          const SizedBox(height: DSSpacing.lg),

          // ── Description ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.lg,
              vertical: DSSpacing.md,
            ),
            decoration: BoxDecoration(
              color: healthColor.withValues(alpha: 0.07),
              borderRadius: DSRadius.smBR,
              border: Border.all(
                color: healthColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  score >= 7
                      ? Icons.thumb_up_outlined
                      : score >= 4
                          ? Icons.info_outline_rounded
                          : Icons.error_outline_rounded,
                  size: 14,
                  color: healthColor,
                ),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: colors.onSurfaceSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
