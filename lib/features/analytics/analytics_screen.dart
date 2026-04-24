import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/models/enums.dart';
import '../../core/models/expense.dart';
import '../../core/models/income.dart';
import '../../core/i18n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(analyticsRangeProvider);
    final expensesAsync = ref.watch(analyticsExpensesProvider);
    final incomesAsync = ref.watch(analyticsIncomesProvider);

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
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.analytics, style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.9, height: 1.1)),
              const SizedBox(height: 6),
              Text('Tu dinero, analizado en el tiempo.', style: TextStyle(fontSize: 13, color: context.colors.onSurfaceSoft)),
            ]),
          )),
          SliverToBoxAdapter(child: _RangePicker(
            current: range,
            onSelect: (r) => ref.read(analyticsRangeProvider.notifier).state = r,
          )),
          expensesAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (expenses) {
              final incomes = incomesAsync.value ?? [];
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _SummaryCards(expenses: expenses, range: range),
                  const SizedBox(height: 16),
                  _MonthlyTrendCard(expenses: expenses, incomes: incomes, l10n: l10n),
                  const SizedBox(height: 24),
                  _CategoryBreakdown(expenses: expenses),
                  const SizedBox(height: 24),
                  _MonthlyBarsCard(expenses: expenses, l10n: l10n),
                  const SizedBox(height: 80),
                ])),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Range Picker ────────────────────────────────────────────────────────────

class _RangePicker extends StatelessWidget {
  final AnalyticsRange current;
  final ValueChanged<AnalyticsRange> onSelect;
  const _RangePicker({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      (AnalyticsRange.threeMonths, '3M'),
      (AnalyticsRange.sixMonths, '6M'),
      (AnalyticsRange.twelveMonths, '12M'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(12)),
      child: Row(children: items.map((item) {
        final active = current == item.$1;
        return Expanded(child: GestureDetector(
          onTap: () => onSelect(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Text(item.$2, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? Colors.white : colors.onSurfaceSoft,
            ))),
          ),
        ));
      }).toList()),
    );
  }
}

// ─── Data Helpers ─────────────────────────────────────────────────────────────

Map<String, double> _cashByMonth(List<Expense> expenses) {
  final map = <String, double>{};
  for (final e in expenses.where((e) => e.payType == 'Cash')) {
    final key = '${e.year}-${e.month.toString().padLeft(2, '0')}';
    map[key] = (map[key] ?? 0) + e.amount;
  }
  return map;
}

Map<String, double> _salaryByMonth(List<Income> incomes) {
  final map = <String, double>{};
  for (final i in incomes.where((i) => i.incomeType == 'NET_SALARY')) {
    final key = '${i.year}-${i.month.toString().padLeft(2, '0')}';
    map[key] = (map[key] ?? 0) + i.amount;
  }
  return map;
}

Map<String, double> _byCategory(List<Expense> expenses) {
  final map = <String, double>{};
  for (final e in expenses.where((e) => e.payType == 'Cash')) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
}

String _shortMonth(String key, AppLocalizations l10n) {
  final month = int.parse(key.split('-')[1]);
  return l10n.months[month - 1];
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final List<Expense> expenses;
  final AnalyticsRange range;
  const _SummaryCards({required this.expenses, required this.range});

  @override
  Widget build(BuildContext context) {
    final cash = expenses.where((e) => e.payType == 'Cash').toList();
    final total = cash.fold(0.0, (s, e) => s + e.amount);
    final months = switch (range) {
      AnalyticsRange.threeMonths => 3,
      AnalyticsRange.sixMonths => 6,
      _ => 12,
    };
    final avg = months > 0 ? total / months : 0.0;
    final byCat = _byCategory(expenses);
    final topCat = byCat.isEmpty ? null : byCat.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Row(children: [
      Expanded(child: _MetricCard(
        label: 'TOTAL',
        value: FinancialCalculatorService.formatBRL(total),
        icon: Icons.receipt_long_outlined,
        color: AppTheme.primaryColor,
      )),
      const SizedBox(width: 10),
      Expanded(child: _MetricCard(
        label: 'AVG / MES',
        value: FinancialCalculatorService.formatBRL(avg),
        icon: Icons.calendar_month_outlined,
        color: AppTheme.secondaryColor,
      )),
      if (topCat != null) ...[
        const SizedBox(width: 10),
        Expanded(child: _MetricCard(
          label: 'TOP CAT.',
          value: _emojiFor(topCat),
          subvalue: _labelFor(topCat, context),
          icon: Icons.star_outline,
          color: AppTheme.getCategoryColor(topCat),
        )),
      ],
    ]);
  }

  static String _emojiFor(String db) {
    try { return ExpenseCategory.fromDb(db).emoji; } catch (_) { return '📦'; }
  }

  static String _labelFor(String db, BuildContext context) {
    try { return ExpenseCategory.fromDb(db).localizedLabel(context); } catch (_) { return db; }
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final String? subvalue;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, this.subvalue, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: colors.onSurfaceSoft)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subvalue != null)
          Text(subvalue!, style: TextStyle(fontSize: 9, color: colors.onSurfaceSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── Monthly Trend Chart ──────────────────────────────────────────────────────

class _MonthlyTrendCard extends StatelessWidget {
  final List<Expense> expenses;
  final List<Income> incomes;
  final AppLocalizations l10n;
  const _MonthlyTrendCard({required this.expenses, required this.incomes, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final monthlyExp = _cashByMonth(expenses);
    final monthlyInc = _salaryByMonth(incomes);
    final allKeys = {...monthlyExp.keys, ...monthlyInc.keys}.toList()..sort();
    if (allKeys.isEmpty) return const SizedBox.shrink();

    final expSpots = allKeys.asMap().entries.map((e) => FlSpot(e.key.toDouble(), monthlyExp[e.value] ?? 0)).toList();
    final incSpots = allKeys.asMap().entries.map((e) => FlSpot(e.key.toDouble(), monthlyInc[e.value] ?? 0)).toList();
    final hasIncome = incSpots.any((s) => s.y > 0);
    final maxY = [...expSpots.map((s) => s.y), ...incSpots.map((s) => s.y)].fold(0.0, (a, b) => a > b ? a : b);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Tendencia Mensual', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
        Row(children: [
          _Legend(color: AppTheme.secondaryColor, label: 'Gasto'),
          if (hasIncome) ...[const SizedBox(width: 12), _Legend(color: AppTheme.primaryColor, label: 'Ingreso')],
        ]),
      ]),
      const SizedBox(height: 12),
      Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(4, 12, 12, 8),
        decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(18)),
        child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: colors.surfaceLow, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY * 1.15,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= allKeys.length) return const SizedBox.shrink();
                return Text(_shortMonth(allKeys[i], l10n), style: TextStyle(fontSize: 9, color: colors.onSurfaceSoft));
              },
            )),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: expSpots, isCurved: true, color: AppTheme.secondaryColor, barWidth: 2.5,
              isStrokeCapRound: true, dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.secondaryColor.withOpacity(0.2), AppTheme.secondaryColor.withOpacity(0)])),
            ),
            if (hasIncome)
              LineChartBarData(
                spots: incSpots, isCurved: true, color: AppTheme.primaryColor, barWidth: 2,
                isStrokeCapRound: true, dotData: const FlDotData(show: false), dashArray: [4, 3],
              ),
          ],
        )),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 10, color: context.colors.onSurfaceSoft)),
  ]);
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<Expense> expenses;
  const _CategoryBreakdown({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final byCat = _byCategory(expenses);
    final total = byCat.values.fold(0.0, (a, b) => a + b);
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Distribución por Categoría', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _DonutChart(data: byCat, total: total),
        const SizedBox(width: 16),
        Expanded(child: Column(children: sorted.take(5).map((e) {
          String label; try { label = ExpenseCategory.fromDb(e.key).localizedLabel(context); } catch (_) { label = e.key; }
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurface), overflow: TextOverflow.ellipsis)),
              Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.onSurfaceSoft)),
            ]),
            const SizedBox(height: 3),
            ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(
              value: pct, minHeight: 3,
              backgroundColor: colors.surfaceLow,
              valueColor: AlwaysStoppedAnimation(AppTheme.getCategoryColor(e.key)),
            )),
          ]));
        }).toList())),
      ]),
    ]);
  }
}

class _DonutChart extends StatelessWidget {
  final Map<String, double> data; final double total;
  const _DonutChart({required this.data, required this.total});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(width: 130, height: 130, child: Stack(alignment: Alignment.center, children: [
      PieChart(PieChartData(sectionsSpace: 0, centerSpaceRadius: 48, sections: data.entries.map((e) => PieChartSectionData(color: AppTheme.getCategoryColor(e.key), value: e.value, radius: 16, showTitle: false)).toList())),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('TOTAL', style: TextStyle(fontSize: 8, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        Text(FinancialCalculatorService.formatBRL(total).split(',')[0], style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: colors.onSurface)),
      ]),
    ]));
  }
}

// ─── Monthly Bars ─────────────────────────────────────────────────────────────

class _MonthlyBarsCard extends StatelessWidget {
  final List<Expense> expenses;
  final AppLocalizations l10n;
  const _MonthlyBarsCard({required this.expenses, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final monthly = _cashByMonth(expenses);
    final sorted = monthly.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (sorted.isEmpty) return const SizedBox.shrink();

    final maxVal = sorted.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final avgVal = sorted.fold(0.0, (s, e) => s + e.value) / sorted.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Comparativo Mensual', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...sorted.map((entry) {
        final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
        final isAboveAvg = entry.value > avgVal * 1.05;
        final barColor = isAboveAvg ? Colors.orange.shade600 : AppTheme.secondaryColor;
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          SizedBox(width: 30, child: Text(_shortMonth(entry.key, l10n),
            style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: LayoutBuilder(builder: (ctx, constraints) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(height: 22, width: constraints.maxWidth, color: colors.surfaceLowest),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: constraints.maxWidth * pct,
                height: 22,
                color: barColor.withOpacity(0.85),
              ),
            ]),
          ))),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(FinancialCalculatorService.formatBRL(entry.value),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurface),
            textAlign: TextAlign.right)),
          if (isAboveAvg)
            Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.arrow_upward, size: 10, color: Colors.orange.shade600)),
        ]));
      }),
    ]);
  }
}
