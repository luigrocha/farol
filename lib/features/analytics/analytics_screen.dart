import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/models/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Farol', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Icon(Icons.notifications_outlined, size: 22, color: context.colors.onSurface),
            ]),
          ),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Spending Analysis', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.9, height: 1.1)),
            const SizedBox(height: 6),
            Text('Your financial health projected in real time.', style: TextStyle(fontSize: 13, color: context.colors.onSurfaceSoft)),
          ]))),
          const SliverToBoxAdapter(child: _AnalyticsTabs()),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              const _AvgDailyCard(),
              const SizedBox(height: 16),
              const _ProProjectionCard(),
              const SizedBox(height: 24),
              const _CategoryDistribution(),
              const SizedBox(height: 24),
              const _TrendChartCard(),
              const SizedBox(height: 80),
            ]))),
        ],
      ),
    );
  }
}

class _AnalyticsTabs extends StatelessWidget {
  const _AnalyticsTabs();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tabs = ['Week', 'Month', 'Quarter', 'Year'];
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.surfaceLow))),
      child: Row(children: tabs.asMap().entries.map((e) {
        final active = e.key == 1;
        return Padding(padding: const EdgeInsets.only(right: 20), child: Column(children: [
          Text(e.value, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppTheme.secondaryColor : colors.onSurfaceSoft)),
          const SizedBox(height: 8),
          if (active) Container(height: 2, width: 20, decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(2))),
        ]));
      }).toList()),
    );
  }
}

class _AvgDailyCard extends ConsumerWidget {
  const _AvgDailyCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final avg = ref.watch(cashExpensesProvider) / 30;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('AVG DAILY SPENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: colors.onSurfaceSoft)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.trending_down, size: 11, color: AppTheme.secondaryColor), SizedBox(width: 3), Text('12.6%', style: TextStyle(color: AppTheme.secondaryColor, fontSize: 11, fontWeight: FontWeight.bold))])),
        ]),
        const SizedBox(height: 10),
        _BRLBig(value: avg, size: 44),
        const SizedBox(height: 16),
        SizedBox(height: 80, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(8, (i) {
          final h = [40, 55, 48, 70, 60, 82, 95, 50][i];
          return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), height: h * 0.8,
            decoration: BoxDecoration(color: i == 6 ? AppTheme.primaryContainer : colors.surfaceLow, borderRadius: BorderRadius.circular(5))));
        }))),
      ]),
    );
  }
}

class _ProProjectionCard extends StatelessWidget {
  const _ProProjectionCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryContainer, AppTheme.primaryColor])),
      child: Stack(children: [
        Positioned(right: -30, top: -30, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF71F8E4).withOpacity(0.18), Colors.transparent])))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7FCF9E)),
          const SizedBox(height: 10),
          Text('Proyección Pro', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          RichText(text: const TextSpan(style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5), children: [
            TextSpan(text: 'Según tus hábitos, podrías ahorrar un '),
            TextSpan(text: '15% adicional', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
            TextSpan(text: ' este trimestre reduciendo gastos en ocio nocturno.'),
          ])),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD37D), foregroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)), elevation: 0), child: const Text('Ver sugerencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ]),
      ]),
    );
  }
}

class _CategoryDistribution extends ConsumerWidget {
  const _CategoryDistribution();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final total = ref.watch(cashExpensesProvider);
    final cats = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Distribución por Categoría', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      Center(child: _DonutChart(data: byCategory, total: total)),
      const SizedBox(height: 16),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
        children: cats.take(4).map((e) {
          String label; try { label = ExpenseCategory.fromDb(e.key).localizedLabel(context); } catch (_) { label = e.key; }
          final pct = total > 0 ? (e.value / total * 100).toInt() : 0;
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.getCategoryColor(e.key), shape: BoxShape.circle)), const SizedBox(width: 6), Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 4),
            Text('$pct%', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
          ]));
        }).toList()),
    ]);
  }
}

class _DonutChart extends StatelessWidget {
  final Map<String, double> data; final double total;
  const _DonutChart({required this.data, required this.total});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(width: 180, height: 180, child: Stack(alignment: Alignment.center, children: [
      PieChart(PieChartData(sectionsSpace: 0, centerSpaceRadius: 72, sections: data.entries.map((e) => PieChartSectionData(color: AppTheme.getCategoryColor(e.key), value: e.value, radius: 20, showTitle: false)).toList())),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('TOTAL', style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600, letterSpacing: 1)),
        Text(FinancialCalculatorService.formatBRL(total).split(',')[0], style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: colors.onSurface)),
      ]),
    ]));
  }
}

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Tendencia de Gasto', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
        Row(children: [Container(width: 10, height: 2, decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(1))), const SizedBox(width: 6), Text('Gasto Real', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft))]),
      ]),
      const SizedBox(height: 12),
      Container(height: 150, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(18)),
        child: LineChart(LineChartData(gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [
          LineChartBarData(spots: const [FlSpot(0, 30), FlSpot(1, 45), FlSpot(2, 40), FlSpot(3, 55), FlSpot(4, 48), FlSpot(5, 62), FlSpot(6, 58)], isCurved: true, color: AppTheme.secondaryColor, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.secondaryColor.withOpacity(0.2), AppTheme.secondaryColor.withOpacity(0)]))),
        ]))),
    ]);
  }
}

class _BRLBig extends StatelessWidget {
  final double value; final double size;
  const _BRLBig({required this.value, required this.size});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: colors.onSurface)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -size * 0.028, color: colors.onSurface)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: FontWeight.w800, color: colors.onSurface.withOpacity(0.85))),
    ]);
  }
}
