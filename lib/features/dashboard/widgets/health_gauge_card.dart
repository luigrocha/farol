import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/health_gauge.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class HealthGaugeCard extends ConsumerWidget {
  const HealthGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final snap = ref.watch(financialSnapshotProvider);

    // Keep triggering the health auto-save side-effect
    ref.watch(healthAutoSaveProvider);

    // Show skeleton while net worth or installments are loading
    final isLoading = ref.watch(netWorthSnapshotProvider).isLoading ||
        ref.watch(installmentsProvider).isLoading;
    if (isLoading) return const DashboardCardSkeleton(height: 200);

    final score = snap.healthScore;

    String statusLabel = l10n.healthHealthy;
    String description = l10n.healthExcellentDesc;
    if (score < 4) {
      statusLabel = l10n.healthCritical;
      description = l10n.healthCriticalDesc;
    } else if (score < 7) {
      statusLabel = l10n.healthWarning;
      description = score < 5 ? l10n.healthFairDesc : l10n.healthGoodDesc;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/health'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(kCardPadding),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.healthScore,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.onSurfaceFaint,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HealthGauge(
                score: score.toDouble() * 10,
                size: kHealthGaugeSize,
                statusLabel: statusLabel,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
