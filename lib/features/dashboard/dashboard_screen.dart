import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/theme/farol_colors.dart';
import 'dart:math' as math;
import '../transactions/quick_add_bottom_sheet.dart';
import '../../core/i18n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/health_gauge.dart';
import '../../core/models/budget_alert.dart';
import '../../core/widgets/shimmer_box.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);

    ref.listen<AsyncValue<int>>(fixedExpensePropagationProvider, (_, next) {
      next.whenData((count) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$count gasto${count == 1 ? '' : 's'} fijo${count == 1 ? '' : 's'} copiado${count == 1 ? '' : 's'} del mes anterior'),
            duration: const Duration(seconds: 3),
          ));
        }
      });
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(children: [
              IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () => _changeMonth(ref, month, year, -1)),
              Text('${AppLocalizations.of(context).months[month-1]} $year', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () => _changeMonth(ref, month, year, 1)),
            ]),
            actions: [
              Consumer(builder: (_, ref, __) {
                final isPrivate = ref.watch(privacyModeProvider);
                return IconButton(
                  icon: Icon(isPrivate ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
                );
              }),
              Consumer(builder: (_, ref, __) {
                final alerts = ref.watch(budgetAlertsProvider);
                final critical = alerts.where((a) => a.level != AlertLevel.warning).length;
                return Badge(
                  isLabelVisible: critical > 0,
                  label: Text('$critical'),
                  backgroundColor: tokens.FarolColors.coral,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 20),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                );
              }),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const _AlertBanner(),
              const _PeriodBanner(),
              const SizedBox(height: 12),
              const _NetWorthHero(),
              const SizedBox(height: 12),
              const _HealthGaugeCard(),
              const SizedBox(height: 12),
              const _KpiGrid(),
              const SizedBox(height: 16),
              const _ExpenseBreakdown(),
              const SizedBox(height: 16),
              const _MonthlyGoalCard(),
              const SizedBox(height: 16),
              const _InstallmentsSummaryCard(),
              const SizedBox(height: 80),
            ]))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const QuickAddBottomSheet()),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int m, int y, int delta) {
    int nm = m + delta; int ny = y;
    if (nm < 1) { nm = 12; ny--; } else if (nm > 12) { nm = 1; ny++; }
    ref.read(selectedMonthProvider.notifier).state = nm;
    ref.read(selectedYearProvider.notifier).state = ny;
  }
}

class _NetWorthHero extends ConsumerWidget {
  const _NetWorthHero();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapAsync = ref.watch(netWorthSnapshotProvider);
    if (snapAsync.isLoading) {
      return const DashboardCardSkeleton(height: 140);
    }
    final snap = snapAsync.value;
    final nw = snap == null ? 0.0 : FinancialCalculatorService.calculateNetWorth(
      patrimonyTotal: snap.patrimonyTotal,
      fgtsBalance: snap.fgtsBalance, investmentsTotal: snap.investmentsTotal,
      emergencyFund: snap.emergencyFund, pendingInstallments: snap.pendingInstallments);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF244A72), tokens.FarolColors.navy]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.netWorth.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white60)),
        const SizedBox(height: 6),
        _BRLBig(value: nw, size: 36, color: Colors.white),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(label: 'Invertido', value: snap?.investmentsTotal ?? 0, color: Colors.white),
          const SizedBox(width: 10),
          _MiniStat(label: 'Líquido FGTS', value: (snap?.fgtsBalance ?? 0) + (snap?.emergencyFund ?? 0), color: tokens.FarolColors.beam),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label; final double value; final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.white60)),
        const SizedBox(height: 4),
        _BRLBig(value: value, size: 16, color: color, weight: FontWeight.w700),
      ]),
    ));
  }
}

class _BRLBig extends ConsumerWidget {
  final double value; final double size; final Color? color; final FontWeight weight;
  const _BRLBig({required this.value, required this.size, this.color, this.weight = FontWeight.w800});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = color ?? context.colors.onSurface;
    final isPrivate = ref.watch(privacyModeProvider);
    if (isPrivate) {
      return Text('••••••', style: GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: c));
    }
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: c, letterSpacing: -size * 0.028)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: weight, color: c.withValues(alpha: 0.85))),
    ]);
  }
}

class _HealthGaugeCard extends ConsumerWidget {
  const _HealthGaugeCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final net=ref.watch(effectiveNetSalaryProvider); final cash=ref.watch(cashExpensesProvider);
    final byCategory=ref.watch(cashExpensesByCategoryProvider); final bal=ref.watch(cashRemainingProvider);
    final snapAsync=ref.watch(netWorthSnapshotProvider);
    final instAsync=ref.watch(installmentsProvider);
    if (snapAsync.isLoading || instAsync.isLoading) {
      return const DashboardCardSkeleton(height: 200);
    }
    final snap=snapAsync.value; final inst=instAsync.value??[];
    final housing=byCategory['HOUSING']??0; final instTotal=inst.fold(0.0,(s,i)=>s+i.monthlyAmount);
    final ef=snap?.emergencyFund??0;
    final score=FinancialCalculatorService.calculateHealthScore(netSalary:net,cashExpenses:cash,housingExpenses:housing,monthlyBalance:bal,emergencyFund:ef,avgMonthlyExpenses:cash,activeInstallmentsTotal:instTotal);
    // Auto-save silencioso — el notifier persiste el snapshot en Supabase
    ref.watch(healthAutoSaveProvider);
    String statusLabel = l10n.healthHealthy;
    String description = l10n.healthExcellentDesc;
    if (score < 4) { statusLabel = l10n.healthCritical; description = l10n.healthCriticalDesc; }
    else if (score < 7) { statusLabel = l10n.healthWarning; description = score < 5 ? l10n.healthFairDesc : l10n.healthGoodDesc; }
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/health'),
      child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        Row(children: [
          Expanded(child: Text(l10n.healthScore, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700))),
          Icon(Icons.chevron_right_rounded, size: 18, color: colors.onSurfaceFaint),
        ]),
        const SizedBox(height: 16),
        HealthGauge(score: score.toDouble() * 10, size: 140, statusLabel: statusLabel),
        const SizedBox(height: 16),
        Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colors.onSurfaceSoft)),
      ]))),
    );
  }
}

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final net = ref.watch(effectiveNetSalaryProvider);
    final swile = ref.watch(effectiveSwileProvider);
    final cash = ref.watch(cashExpensesProvider);
    final cashRemaining = ref.watch(cashRemainingProvider);
    final swileRemaining = ref.watch(swileRemainingProvider);
    final sr = ref.watch(effectiveSavingsRateProvider);
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.5,
      children: [
        _KpiCard(icon: Icons.account_balance_wallet, bg: colors.iconTintBlue, label: l10n.translate('net_salary'), value: net),
        _KpiCard(icon: Icons.fastfood, bg: colors.secondaryContainer, label: l10n.translate('swile'), value: swile, color: tokens.FarolColors.beam),
        _KpiCard(icon: Icons.account_balance, bg: cashRemaining >= 0 ? colors.secondaryContainer : colors.iconTintRed, label: l10n.translate('available_total'), value: cashRemaining, color: cashRemaining >= 0 ? tokens.FarolColors.beam : tokens.FarolColors.coral),
        _KpiCard(icon: Icons.trending_down, bg: colors.iconTintRed, label: l10n.translate('cash_expenses'), value: cash, color: tokens.FarolColors.coral),
        _KpiCard(icon: Icons.restaurant, bg: swileRemaining >= 0 ? colors.secondaryContainer : colors.iconTintRed, label: l10n.translate('swile_remaining'), value: swileRemaining, color: swileRemaining >= 0 ? tokens.FarolColors.beam : tokens.FarolColors.coral),
        _KpiCard(icon: Icons.savings, bg: colors.iconTintBlue, label: l10n.translate('savings_rate'), raw: '${sr.toStringAsFixed(1)}%'),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon; final Color bg; final String label; final double? value; final String? raw; final Color? color;
  const _KpiCard({required this.icon, required this.bg, required this.label, this.value, this.raw, this.color});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () { if (label.toLowerCase().contains('swile')) Navigator.pushNamed(context, '/swile'); },
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color ?? colors.onSurface)),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          raw != null
            ? Text(raw!, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: color ?? colors.onSurface))
            : _BRLSmall(value: value ?? 0, size: 15, weight: FontWeight.w700, color: color),
        ]),
      ),
    );
  }
}

class _BRLSmall extends StatelessWidget {
  final double value; final double size; final Color? color; final FontWeight weight;
  const _BRLSmall({required this.value, required this.size, this.color, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    final f = FinancialCalculatorService.formatBRL(value);
    return Text(f, style: GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? context.colors.onSurface, fontFeatures: const [FontFeature.tabularFigures()]));
  }
}

class _ExpenseBreakdown extends ConsumerWidget {
  const _ExpenseBreakdown();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final goals = ref.watch(budgetGoalsMapProvider);
    final catsMap = ref.watch(categoriesMapProvider);
    final net = ref.watch(effectiveNetSalaryProvider);
    final l10n = AppLocalizations.of(context);
    if (byCategory.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(children: [Icon(Icons.bar_chart, size: 48, color: Theme.of(context).colorScheme.outline), const SizedBox(height: 8), Text(l10n.translate('no_expenses'))])));
    }
    final sorted = byCategory.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(l10n.translate('expense_by_cat'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('ACTUAL VS PRESUPUESTO', style: TextStyle(fontSize: 10, letterSpacing: 1, color: colors.onSurfaceSoft)),
      ]),
      const SizedBox(height: 14),
      ...sorted.map((e) {
        final catDbValue=e.key; final actual=e.value; final goal=goals[catDbValue]; final target=goal?.targetAmount??(net*0.1);
        final ratio = actual / target;
        final pct = math.min(ratio, 1.0);
        final barColor = ratio >= 1.0 ? tokens.FarolColors.coral
            : ratio >= 0.90 ? const Color(0xFFFF6B35)
            : ratio >= 0.75 ? tokens.FarolColors.beam
            : tokens.FarolColors.tide;
        final labelColor = ratio >= 0.75 ? barColor : colors.onSurfaceSoft;
        
        final catModel = catsMap[catDbValue];
        final label = catModel?.name ?? catDbValue;
        final emoji = catModel?.emoji ?? '💰';

        return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              if (ratio >= 0.75) ...[
                Icon(ratio >= 1.0 ? Icons.error_outline : Icons.warning_amber_outlined, size: 13, color: barColor),
                const SizedBox(width: 4),
              ],
              Text('$emoji $label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.onSurface)),
            ]),
            Text('R\$ ${actual.toInt()} / R\$ ${target.toInt()}', style: TextStyle(fontSize: 11, color: labelColor, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: colors.surfaceLow, valueColor: AlwaysStoppedAnimation(barColor))),
        ]));
      }),
    ])));
  }
}

class _MonthlyGoalCard extends ConsumerWidget {
  const _MonthlyGoalCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final net = ref.watch(effectiveNetSalaryProvider);
    final cash = ref.watch(cashExpensesProvider);
    final target = net * 0.2;
    final saved = net - cash;
    final pct = (saved / target).clamp(0.0, 1.0);
    final remaining = math.max(target - saved, 0.0);
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context).translate('monthly_goal'), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      RichText(text: TextSpan(style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft, height: 1.5), children: [
        TextSpan(text: '${AppLocalizations.of(context).translate('missing')} '),
        TextSpan(text: FinancialCalculatorService.formatBRL(remaining), style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700)),
        TextSpan(text: ' ${AppLocalizations.of(context).translate('to_reach_goal')}'),
      ])),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: colors.secondaryContainer, valueColor: const AlwaysStoppedAnimation(tokens.FarolColors.beam)))),
        const SizedBox(width: 10),
        const Text('', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.FarolColors.beam)),
        Text('${(pct*100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.FarolColors.beam)),
      ]),
    ])));
  }
}

class _AlertBanner extends ConsumerWidget {
  const _AlertBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(budgetAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();
    final top = alerts.first;
    final catsMap = ref.watch(categoriesMapProvider);

    final color = switch (top.level) {
      AlertLevel.exceeded => tokens.FarolColors.coral,
      AlertLevel.critical => const Color(0xFFFF6B35),
      AlertLevel.warning  => tokens.FarolColors.beam,
    };
    final icon = switch (top.level) {
      AlertLevel.exceeded => Icons.error_outline,
      AlertLevel.critical => Icons.warning_amber_outlined,
      AlertLevel.warning  => Icons.info_outline,
    };

    final catModel = catsMap[top.category];
    final label = catModel?.name ?? top.category;
    final emoji = catModel?.emoji ?? '📊';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '$emoji $label: ${top.percentageLabel} del presupuesto',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          )),
          if (alerts.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
              child: Text('+${alerts.length - 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
          Icon(Icons.chevron_right, size: 16, color: color),
        ]),
      ),
    );
  }
}

class _PeriodBanner extends ConsumerWidget {
  const _PeriodBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final period = ref.watch(currentPeriodProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.onSurfaceFaint.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 15, color: colors.onSurfaceSoft),
          const SizedBox(width: 8),
          Text(
            'Período actual',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceSoft),
          ),
          const SizedBox(width: 6),
          Text(
            period.label,
            style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}


class _InstallmentsSummaryCard extends ConsumerWidget {
  const _InstallmentsSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final instAsync = ref.watch(installmentsProvider);
    if (instAsync.isLoading) return const DashboardCardSkeleton(height: 100);
    final installments = instAsync.value ?? [];
    const purple = Color(0xFF6B3FA0);

    if (installments.isEmpty) return const SizedBox.shrink();

    final totalMonthly = installments.fold(0.0, (s, i) => s + i.monthlyAmount);
    final totalRemaining = installments.fold(0.0, (s, i) => s + i.remainingBalance);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/installments'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('💳', style: TextStyle(fontSize: 15))),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Parcelas', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface)),
                Text('${installments.length} ativa${installments.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
              ]),
            ]),
            const Row(children: [
              Text('Ver todas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B3FA0))),
              Icon(Icons.chevron_right, size: 14, color: Color(0xFF6B3FA0)),
            ]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MENSAL', style: TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: colors.onSurfaceFaint)),
              const SizedBox(height: 3),
              Text(FinancialCalculatorService.formatBRL(totalMonthly),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: purple,
                  fontFeatures: const [FontFeature.tabularFigures()])),
            ])),
            Container(width: 1, height: 32, color: colors.surfaceLow),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SALDO RESTANTE', style: TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: colors.onSurfaceFaint)),
                const SizedBox(height: 3),
                Text(FinancialCalculatorService.formatBRL(totalRemaining),
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            )),
          ]),
          const SizedBox(height: 14),
          ...installments.take(3).map((inst) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(inst.description, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurface), overflow: TextOverflow.ellipsis)),
                Text('${inst.currentInstallment}/${inst.numInstallments}', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: inst.progressPercent,
                  minHeight: 4,
                  backgroundColor: purple.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(purple),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}
