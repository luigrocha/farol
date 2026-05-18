import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../design/ds_tokens.dart';
import '../../core/models/expense.dart';
import '../../core/models/income.dart';
import '../../core/i18n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'cashflow_chart.dart';
import '../../design/branding/branding.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const double _desktopBreakpoint = 800;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(analyticsRangeProvider);
    final expensesAsync = ref.watch(analyticsExpensesProvider);
    final incomesAsync = ref.watch(analyticsIncomesProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(children: [
              const FarolMark(size: FarolBrand.markSizeCompact, variant: FarolLogoVariant.dark),
              const SizedBox(width: 10),
              Text('Farol', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const Spacer(),
              Icon(Icons.notifications_outlined, size: 22, color: context.colors.onSurface),
            ]),
          ),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.analytics, style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.9, height: 1.1)),
              const SizedBox(height: 6),
              Text(l10n.analyticsSubtitle, style: TextStyle(fontSize: 13, color: context.colors.onSurfaceSoft)),
            ]),
          )),
          SliverToBoxAdapter(child: _RangePicker(
            current: range,
            onSelect: (r) => ref.read(analyticsRangeProvider.notifier).state = r,
          )),
          expensesAsync.when(
            loading: () => const SliverFillRemaining(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: DSSpacing.xl, vertical: DSSpacing.xxl),
            child: Column(children: [
              DSSkeleton(width: double.infinity, height: 80, radius: DSRadius.lg),
              SizedBox(height: DSSpacing.lg),
              DSSkeleton(width: double.infinity, height: 180, radius: DSRadius.lg),
              SizedBox(height: DSSpacing.lg),
              DSSkeleton(width: double.infinity, height: 160, radius: DSRadius.lg),
            ]),
          )),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (expenses) {
              final incomes = incomesAsync.value ?? [];
              if (isDesktop) {
                return _buildDesktopGrid(context, expenses, incomes, range, l10n);
              }
              return _buildMobileList(expenses, incomes, range, l10n);
            },
          ),
        ],
      ),
    );
  }

  // ── Desktop: two-column chart grid ──────────────────────────────────────
  //
  //  ┌────────────────────────┬───────────────────────────┐
  //  │  SummaryCards          │  MonthlyTrendCard         │
  //  │  CategoryBreakdown     │  MonthlyBarsCard          │
  //  │                        │  CashflowChart            │
  //  └────────────────────────┴───────────────────────────┘

  Widget _buildDesktopGrid(
    BuildContext context,
    List<Expense> expenses,
    List<Income> incomes,
    AnalyticsRange range,
    AppLocalizations l10n,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCards(expenses: expenses, range: range),
                  const SizedBox(height: 24),
                  _CategoryBreakdown(expenses: expenses),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthlyTrendCard(expenses: expenses, incomes: incomes, l10n: l10n),
                  const SizedBox(height: 24),
                  _MonthlyBarsCard(expenses: expenses, l10n: l10n),
                  const SizedBox(height: 24),
                  const CashflowChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile: single-column list (unchanged) ───────────────────────────────

  Widget _buildMobileList(
    List<Expense> expenses,
    List<Income> incomes,
    AnalyticsRange range,
    AppLocalizations l10n,
  ) {
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
        const SizedBox(height: 24),
        const CashflowChart(),
        const SizedBox(height: 80),
      ])),
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
      margin: const EdgeInsets.fromLTRB(DSSpacing.xl, DSSpacing.xl, DSSpacing.xl, 0),
      padding: const EdgeInsets.all(DSSpacing.xs),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: DSRadius.mdBR),
      child: Row(children: items.map((item) {
        final active = current == item.$1;
        return Expanded(child: GestureDetector(
          onTap: () => onSelect(item.$1),
          child: AnimatedContainer(
            duration: DSDuration.normal,
            padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
            decoration: BoxDecoration(
              color: active ? tokens.FarolColors.navy : Colors.transparent,
              borderRadius: DSRadius.smBR,
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

class _SummaryCards extends ConsumerWidget {
  final List<Expense> expenses;
  final AnalyticsRange range;
  const _SummaryCards({required this.expenses, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = expenses.where((e) => e.payType == 'Cash').toList();
    final total = cash.fold(0.0, (s, e) => s + e.amount);
    final months = switch (range) {
      AnalyticsRange.threeMonths => 3,
      AnalyticsRange.sixMonths => 6,
      _ => 12,
    };
    final avg = months > 0 ? total / months : 0.0;
    final byCat = _byCategory(expenses);
    final topCatDbValue = byCat.isEmpty ? null : byCat.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final catsMap = ref.watch(categoriesMapProvider);

    final l10n = context.l10n;
    return Row(children: [
      Expanded(child: _MetricCard(
        label: l10n.total.toUpperCase(),
        value: FinancialCalculatorService.formatBRL(total),
        icon: Icons.receipt_long_outlined,
        color: tokens.FarolColors.navy,
      )),
      const SizedBox(width: 10),
      Expanded(child: _MetricCard(
        label: l10n.analyticsAvgPerMonth,
        value: FinancialCalculatorService.formatBRL(avg),
        icon: Icons.calendar_month_outlined,
        color: tokens.FarolColors.beam,
      )),
      if (topCatDbValue != null) ...[
        const SizedBox(width: 10),
        Builder(builder: (context) {
          final cat = catsMap[topCatDbValue];
          final emoji = cat?.emoji ?? '📦';
          final label = cat?.name ?? topCatDbValue;
          return Expanded(child: _MetricCard(
            label: l10n.analyticsTopCategory,
            value: emoji,
            subvalue: label,
            icon: Icons.star_outline,
            color: tokens.FarolColors.getCategoryColor(topCatDbValue),
          ));
        }),
      ],
    ]);
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
    return DSCard(
      enableHover: true,
      padding: const EdgeInsets.all(DSSpacing.md),
      radius: DSRadius.lg,
      color: colors.surfaceLowest,
      enableShadow: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: DSRadius.xsBR),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: DSSpacing.sm),
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
        Text(l10n.analyticsMonthlyTrend, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
        Row(children: [
          _Legend(color: tokens.FarolColors.beam, label: l10n.analyticsSpendingLegend),
          if (hasIncome) ...[const SizedBox(width: 12), _Legend(color: tokens.FarolColors.navy, label: l10n.income)],
        ]),
      ]),
      const SizedBox(height: DSSpacing.md),
      DSCard(
        enableHover: false,
        enableShadow: true,
        padding: const EdgeInsets.fromLTRB(DSSpacing.xs, DSSpacing.md, DSSpacing.md, DSSpacing.sm),
        radius: DSRadius.lg,
        color: colors.surfaceLowest,
        height: 160,
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
              spots: expSpots, isCurved: true, color: tokens.FarolColors.beam, barWidth: 2.5,
              isStrokeCapRound: true, dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tokens.FarolColors.beam.withValues(alpha: 0.2), tokens.FarolColors.beam.withValues(alpha: 0)])),
            ),
            if (hasIncome)
              LineChartBarData(
                spots: incSpots, isCurved: true, color: tokens.FarolColors.navy, barWidth: 2,
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
    Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: DSRadius.xsBR)),
    const SizedBox(width: DSSpacing.xs),
    Text(label, style: TextStyle(fontSize: 10, color: context.colors.onSurfaceSoft)),
  ]);
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends ConsumerWidget {
  final List<Expense> expenses;
  const _CategoryBreakdown({required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final byCat = _byCategory(expenses);
    final total = byCat.values.fold(0.0, (a, b) => a + b);
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final catsMap = ref.watch(categoriesMapProvider);
    if (sorted.isEmpty) return const SizedBox.shrink();

    return DSCard(
      enableHover: false,
      enableShadow: true,
      padding: const EdgeInsets.all(DSSpacing.lg),
      radius: DSRadius.lg,
      color: colors.surfaceLowest,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.analyticsCategoryDistribution, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: DSSpacing.lg),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _DonutChart(data: byCat, total: total),
          const SizedBox(width: DSSpacing.lg),
          Expanded(child: Column(children: sorted.take(5).map((e) {
            final cat = catsMap[e.key];
            final label = cat?.name ?? e.key;
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(padding: const EdgeInsets.only(bottom: DSSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurface), overflow: TextOverflow.ellipsis)),
                Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.onSurfaceSoft)),
              ]),
              const SizedBox(height: 3),
              DSProgressBar(
                value: pct,
                height: 3,
                color: tokens.FarolColors.getCategoryColor(e.key),
                backgroundColor: colors.surfaceLow,
              ),
            ]));
          }).toList())),
        ]),
      ]),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final Map<String, double> data; final double total;
  const _DonutChart({required this.data, required this.total});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(width: 130, height: 130, child: Stack(alignment: Alignment.center, children: [
      PieChart(PieChartData(sectionsSpace: 0, centerSpaceRadius: 48, sections: data.entries.map((e) => PieChartSectionData(color: tokens.FarolColors.getCategoryColor(e.key), value: e.value, radius: 16, showTitle: false)).toList())),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.l10n.total.toUpperCase(), style: TextStyle(fontSize: 8, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
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

    return DSCard(
      enableHover: false,
      enableShadow: true,
      padding: const EdgeInsets.all(DSSpacing.lg),
      radius: DSRadius.lg,
      color: colors.surfaceLowest,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.analyticsMonthlyComparison, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: DSSpacing.md),
        ...sorted.map((entry) {
          final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
          final isAboveAvg = entry.value > avgVal * 1.05;
          final barColor = isAboveAvg ? Colors.orange.shade600 : tokens.FarolColors.beam;
          return Padding(padding: const EdgeInsets.only(bottom: DSSpacing.sm + 2), child: Row(children: [
            SizedBox(width: 30, child: Text(_shortMonth(entry.key, l10n),
              style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600))),
            const SizedBox(width: DSSpacing.sm),
            Expanded(child: LayoutBuilder(builder: (ctx, constraints) => ClipRRect(
              borderRadius: DSRadius.xsBR,
              child: Stack(children: [
                Container(height: 22, width: constraints.maxWidth, color: colors.surfaceLow),
                AnimatedContainer(
                  duration: DSDuration.slow,
                  curve: DSCurve.smooth,
                  width: constraints.maxWidth * pct,
                  height: 22,
                  color: barColor.withValues(alpha: 0.85),
                ),
              ]),
            ))),
            const SizedBox(width: DSSpacing.sm),
            SizedBox(width: 80, child: Text(FinancialCalculatorService.formatBRL(entry.value),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurface),
              textAlign: TextAlign.right)),
            if (isAboveAvg)
              Padding(padding: const EdgeInsets.only(left: DSSpacing.xs), child: Icon(Icons.arrow_upward, size: 10, color: Colors.orange.shade600)),
          ]));
        }),
      ]),
    );
  }
}
