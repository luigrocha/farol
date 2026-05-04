import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/farol_colors.dart';
import '../../../../design/farol_colors.dart' as tokens;
import '../../../../design/widgets/farol_card.dart';
import '../../../../design/widgets/brl_text.dart';

class AssetAllocationCard extends ConsumerWidget {
  const AssetAllocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final alloc = ref.watch(assetAllocationProvider);
    final isPrivate = ref.watch(privacyModeProvider);

    final total = alloc.banks + alloc.investments + alloc.fgts + alloc.patrimony;

    final l10n = context.l10n;
    final sections = [
      _Bucket(l10n.accountsLabel, alloc.banks, tokens.FarolColors.navy),
      _Bucket(l10n.investments, alloc.investments, tokens.FarolColors.tide),
      _Bucket('FGTS', alloc.fgts, tokens.FarolColors.beam),
      _Bucket(l10n.netWorth, alloc.patrimony, const Color(0xFF8FA3B8)),
    ].where((b) => b.value > 0).toList();

    return FarolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.assetAllocation,
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurfaceSoft, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          if (sections.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(context.l10n.noAccountsRegistered,
                    style: TextStyle(color: colors.onSurfaceFaint, fontSize: 14)),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: Stack(alignment: Alignment.center, children: [
                PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  sections: sections.map((b) => PieChartSectionData(
                    color: b.color,
                    value: b.value,
                    radius: 30,
                    showTitle: false,
                  )).toList(),
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('TOTAL', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: colors.onSurfaceSoft, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  isPrivate
                      ? Text('••••••', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: colors.onSurface))
                      : BrlText(value: total, fontSize: 16, color: colors.onSurface),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            ...sections.map((b) => _LegendRow(bucket: b, total: total, isPrivate: isPrivate)),
          ],
        ],
      ),
    );
  }
}

class _Bucket {
  final String label;
  final double value;
  final Color color;
  const _Bucket(this.label, this.value, this.color);
}

class _LegendRow extends StatelessWidget {
  final _Bucket bucket;
  final double total;
  final bool isPrivate;

  const _LegendRow({required this.bucket, required this.total, required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = total > 0 ? (bucket.value / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: bucket.color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(bucket.label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: colors.onSurfaceMuted))),
        Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 12, color: colors.onSurfaceSoft)),
        const SizedBox(width: 12),
        isPrivate
            ? Text('•••', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onSurface))
            : BrlText(value: bucket.value, fontSize: 13, color: colors.onSurface),
      ]),
    );
  }
}
