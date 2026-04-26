import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/theme/farol_colors.dart';
import '../../core/widgets/health_gauge.dart';
import '../../core/models/health_snapshot.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final net = ref.watch(effectiveNetSalaryProvider);
    final cash = ref.watch(cashExpensesProvider);
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final balance = ref.watch(cashRemainingProvider);
    final snap = ref.watch(netWorthSnapshotProvider).value;
    final inst = ref.watch(installmentsProvider).value ?? [];
    final housing = byCategory['HOUSING'] ?? 0;
    final instTotal = inst.fold(0.0, (s, i) => s + i.monthlyAmount);
    final ef = snap?.emergencyFund ?? 0;
    final efMonths = cash > 0 ? ef / cash : 0.0;
    final savingsRate = net > 0 ? (net - cash) / net * 100 : 0.0;
    final housingRate = net > 0 ? housing / net * 100 : 0.0;
    final installmentsRate = net > 0 ? instTotal / net * 100 : 0.0;

    final score = FinancialCalculatorService.calculateHealthScore(
      netSalary: net,
      cashExpenses: cash,
      housingExpenses: housing,
      monthlyBalance: balance,
      emergencyFund: ef,
      avgMonthlyExpenses: cash,
      activeInstallmentsTotal: instTotal,
    );

    String statusLabel;
    if (score < 4) {
      statusLabel = 'CRÍTICO';
    } else if (score < 7) {
      statusLabel = 'ALERTA';
    } else {
      statusLabel = 'SALUDABLE';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Salud Financiera',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                // ── Gauge card ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF244A72), tokens.FarolColors.navy],
                    ),
                  ),
                  child: Column(children: [
                    Text(
                      '${_monthName(month)} $year',
                      style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: Colors.white60),
                    ),
                    const SizedBox(height: 20),
                    HealthGauge(score: score * 10.0, size: 180, statusLabel: statusLabel),
                    const SizedBox(height: 16),
                    Text(
                      FinancialCalculatorService.healthScoreDescription(score),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                // ── Sub-score breakdown ──
                Text('Desglose', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 10),
                _SubScoreRow(
                  icon: Icons.savings_outlined,
                  label: 'Tasa de ahorro',
                  value: '${savingsRate.toStringAsFixed(1)}%',
                  maxPoints: 2,
                  earned: savingsRate >= 20 ? 2 : savingsRate >= 10 ? 1 : 0,
                ),
                _SubScoreRow(
                  icon: Icons.home_outlined,
                  label: 'Vivienda / salario',
                  value: '${housingRate.toStringAsFixed(1)}%',
                  maxPoints: 2,
                  earned: housingRate <= 30 ? 2 : housingRate <= 40 ? 1 : 0,
                ),
                _SubScoreRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Balance mensual',
                  value: FinancialCalculatorService.formatBRL(balance),
                  maxPoints: 2,
                  earned: balance >= 0 ? 2 : 0,
                ),
                _SubScoreRow(
                  icon: Icons.shield_outlined,
                  label: 'Fondo de emergencia',
                  value: '${efMonths.toStringAsFixed(1)} meses',
                  maxPoints: 2,
                  earned: efMonths >= 3 ? 2 : 0,
                ),
                _SubScoreRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Parcelas / salario',
                  value: '${installmentsRate.toStringAsFixed(1)}%',
                  maxPoints: 1,
                  earned: installmentsRate <= 30 ? 1 : 0,
                ),
                const SizedBox(height: 24),
                // ── History ──
                Text('Historial', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 10),
                ref.watch(healthHistoryProvider).when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error: $e', style: TextStyle(color: colors.onSurfaceSoft)),
                  data: (history) {
                    if (history.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Sin historial aún', style: TextStyle(color: colors.onSurfaceSoft, fontSize: 13)),
                        ),
                      );
                    }
                    return Column(
                      children: history.map((h) => _HistoryTile(snapshot: h)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return names[month - 1];
  }
}

class _SubScoreRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxPoints;
  final int earned;

  const _SubScoreRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxPoints,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color badgeColor;
    if (earned == maxPoints && earned > 0) {
      badgeColor = tokens.FarolColors.tide;
    } else if (earned > 0) {
      badgeColor = tokens.FarolColors.beam;
    } else {
      badgeColor = colors.onSurfaceFaint;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: tokens.FarolColors.navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: tokens.FarolColors.navy),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.onSurface)),
          Text(value, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '+$earned / +$maxPoints',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
          ),
        ),
      ]),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HealthSnapshot snapshot;
  const _HistoryTile({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color scoreColor;
    if (snapshot.score >= 7) {
      scoreColor = tokens.FarolColors.tide;
    } else if (snapshot.score >= 4) {
      scoreColor = tokens.FarolColors.beam;
    } else {
      scoreColor = tokens.FarolColors.coral;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${_monthName(snapshot.month)} ${snapshot.year}',
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
          ),
          Text(
            'Ahorro ${snapshot.savingsRate.toStringAsFixed(1)}%  ·  Balance ${FinancialCalculatorService.formatBRL(snapshot.monthlyBalance)}',
            style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
          ),
        ])),
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${snapshot.score}',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: scoreColor),
          ),
        ),
      ]),
    );
  }

  String _monthName(int month) {
    const names = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return names[month - 1];
  }
}
