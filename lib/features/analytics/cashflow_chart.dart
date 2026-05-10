import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/widgets/shimmer_box.dart';

class CashflowChart extends ConsumerWidget {
  const CashflowChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projAsync = ref.watch(cashflowForecastProvider);

    return projAsync.when(
      loading: () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.cashflowTitle,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const ShimmerBox(width: double.infinity, height: 200, borderRadius: 12),
      ]),
      error: (e, _) => Text('${context.l10n.error}: $e'),
      data: (proj) {
        if (proj == null || proj.cashflowForecast == null) {
          return const SizedBox.shrink();
        }
        final forecast = proj.cashflowForecast!;
        if (forecast.isEmpty) return const SizedBox.shrink();

        final minBalance = forecast.minBalance;
        final minBalanceFormatted = FinancialCalculatorService.formatBRL(minBalance.amount);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l10n.cashflowTitle,
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (forecast.goesNegative)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  context.l10n.cashflowNegativeWarning,
                  style: GoogleFonts.manrope(fontSize: 12, color: Colors.red),
                ),
              ]),
            ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (v, _) => Text(
                        FinancialCalculatorService.formatBRL(v),
                        style: GoogleFonts.manrope(fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 15,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= forecast.points.length) {
                          return const SizedBox.shrink();
                        }
                        final d = forecast.points[idx].date;
                        return Text(
                          '${d.day}/${d.month}',
                          style: GoogleFonts.manrope(fontSize: 9, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // Real line (solid)
                  LineChartBarData(
                    spots: forecast.points
                        .asMap()
                        .entries
                        .where((e) => e.value.isReal)
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.balance.amount,
                            ))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF00897B),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00897B).withValues(alpha: 0.08),
                    ),
                  ),
                  // Projected line (dashed)
                  LineChartBarData(
                    spots: forecast.points
                        .asMap()
                        .entries
                        .where((e) => !e.value.isReal)
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.balance.amount,
                            ))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFFF59E0B),
                    barWidth: 1.5,
                    dashArray: [5, 5],
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= forecast.points.length) return false;
                        return forecast.points[idx].hasObligation;
                      },
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.red,
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                ],
                // Zero line
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Colors.red.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              _Legend(color: const Color(0xFF00897B), label: context.l10n.cashflowLegendReal, dashed: false),
              const SizedBox(width: 16),
              _Legend(color: const Color(0xFFF59E0B), label: context.l10n.cashflowLegendProjection, dashed: true),
              const SizedBox(width: 16),
              _Legend(color: Colors.red, label: context.l10n.cashflowLegendCommitment, isDot: true),
            ]),
          ]),
          const SizedBox(height: 10),
          // Min-balance summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: minBalance.isNegative
                  ? Colors.red.withValues(alpha: 0.07)
                  : Colors.grey.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(
                minBalance.isNegative
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
                size: 14,
                color: minBalance.isNegative ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.cashflowMinBalanceLabel,
                style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                minBalanceFormatted,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: minBalance.isNegative ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.dashed = false,
    this.isDot = false,
  });
  final Color color;
  final String label;
  final bool dashed;
  final bool isDot;

  @override
  Widget build(BuildContext context) => Row(children: [
        isDot
            ? Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle))
            : Container(
                width: 20, height: 2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey)),
      ]);
}
