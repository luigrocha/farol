import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../design/farol_colors.dart' as tokens;
import 'widgets/asset_allocation_card.dart';
import 'widgets/net_worth_evolution_chart.dart';
import 'widgets/period_flow_card.dart';

class PatrimonioScreen extends ConsumerWidget {
  const PatrimonioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Patrimônio Neto',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PatrimonioHero(),
          SizedBox(height: 16),
          NetWorthEvolutionChart(),
          SizedBox(height: 16),
          AssetAllocationCard(),
          SizedBox(height: 16),
          PeriodFlowCard(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PatrimonioHero extends ConsumerWidget {
  const _PatrimonioHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsReady = ref.watch(accountsProvider).value?.isNotEmpty ?? false;
    final enhancedNw = ref.watch(enhancedNetWorthProvider);
    final snapAsync = ref.watch(netWorthSnapshotProvider);
    final snap = snapAsync.value;
    final banks = ref.watch(liquidAccountsTotalProvider);
    final investmentsLive = ref.watch(totalInvestmentBalanceProvider);
    final fgtsLive = ref.watch(fgtsBalanceFromAccountsProvider);

    final double? nw;
    if (accountsReady) {
      nw = enhancedNw;
    } else if (snapAsync.isLoading) {
      nw = null;
    } else if (snap == null) {
      nw = 0.0;
    } else {
      nw = FinancialCalculatorService.calculateNetWorth(
        patrimonyTotal: snap.patrimonyTotal,
        fgtsBalance: snap.fgtsBalance,
        investmentsTotal: snap.investmentsTotal,
        emergencyFund: snap.emergencyFund,
        pendingInstallments: snap.pendingInstallments,
      );
    }

    if (nw == null) return const DashboardCardSkeleton(height: 140);

    final investments = accountsReady ? investmentsLive : (snap?.investmentsTotal ?? 0.0);
    final fgts = accountsReady
        ? fgtsLive
        : ((snap?.fgtsBalance ?? 0.0) + (snap?.emergencyFund ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244A72), tokens.FarolColors.navy],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PATRIMÔNIO NETO',
            style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white60)),
        const SizedBox(height: 6),
        _BRLBig(value: nw, size: 36, color: Colors.white),
        const SizedBox(height: 16),
        Row(children: [
          if (accountsReady) ...[
            _MiniStat(label: 'Contas', value: banks, color: Colors.white),
            const SizedBox(width: 10),
          ],
          _MiniStat(label: 'Invertido', value: investments, color: Colors.white),
          const SizedBox(width: 10),
          _MiniStat(label: 'FGTS', value: fgts, color: tokens.FarolColors.beam),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.white60)),
          const SizedBox(height: 4),
          _BRLBig(value: value, size: 16, color: color, weight: FontWeight.w700),
        ]),
      ),
    );
  }
}

class _BRLBig extends ConsumerWidget {
  final double value;
  final double size;
  final Color? color;
  final FontWeight weight;
  const _BRLBig({required this.value, required this.size, this.color, this.weight = FontWeight.w800});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = color ?? context.colors.onSurface;
    final isPrivate = ref.watch(privacyModeProvider);
    if (isPrivate) {
      return Text('••••••', style: GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: c));
    }
    final parts = FinancialCalculatorService.formatBRL(value).split(',');
    final f = parts[0];
    final cents = parts.length > 1 ? parts[1] : '00';
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: c, letterSpacing: -size * 0.028)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: weight, color: c.withValues(alpha: 0.85))),
    ]);
  }
}
