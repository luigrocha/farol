import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/net_worth_snapshot.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/farol_colors.dart';
import '../../../../design/farol_colors.dart' as tokens;

class NetWorthEvolutionChart extends ConsumerWidget {
  const NetWorthEvolutionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(netWorthFilterProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(context.l10n.evolution, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
          _FilterChips(selected: filter, onChanged: (f) => ref.read(netWorthFilterProvider.notifier).state = f),
        ]),
        const SizedBox(height: 16),
        historyAsync.when(
          loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
          data: (snapshots) => snapshots.length < 2
              ? SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      context.l10n.noHistoryData,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 12, color: colors.onSurfaceSoft, height: 1.5),
                    ),
                  ),
                )
              : SizedBox(height: 160, child: _LineChart(snapshots: snapshots, colors: colors)),
        ),
      ]),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final NetWorthFilter selected;
  final ValueChanged<NetWorthFilter> onChanged;
  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (NetWorthFilter.sixMonths, '6M'),
      (NetWorthFilter.oneYear, '1A'),
      (NetWorthFilter.allTime, context.l10n.filterAllTime),
    ];
    return Row(children: options.map((opt) {
      final isSelected = selected == opt.$1;
      return GestureDetector(
        onTap: () => onChanged(opt.$1),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? tokens.FarolColors.beam : context.colors.surfaceLow,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            opt.$2,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? tokens.FarolColors.navy : context.colors.onSurfaceSoft,
            ),
          ),
        ),
      );
    }).toList());
  }
}

class _LineChart extends StatelessWidget {
  final List<NetWorthSnapshot> snapshots;
  final FarolColors colors;
  const _LineChart({required this.snapshots, required this.colors});

  static const _monthNames = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  String _abbr(double value) {
    if (value >= 1000000) return 'R\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'R\$${(value / 1000).toStringAsFixed(0)}k';
    return 'R\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final spots = snapshots.asMap().entries.map((e) {
      final total = e.value.patrimonyTotal + e.value.investmentsTotal + e.value.fgtsBalance;
      return FlSpot(e.key.toDouble(), total);
    }).toList();

    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: colors.surfaceLow, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxY * 1.15,
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (v, _) => Text(_abbr(v), style: TextStyle(fontSize: 9, color: colors.onSurfaceFaint)),
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 20,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= snapshots.length) return const SizedBox.shrink();
            return Text(_monthNames[snapshots[i].month], style: TextStyle(fontSize: 9, color: colors.onSurfaceSoft));
          },
        )),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: tokens.FarolColors.beam,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [tokens.FarolColors.beam.withValues(alpha: 0.2), tokens.FarolColors.beam.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    ));
  }
}
