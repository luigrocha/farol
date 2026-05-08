import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/domain/entities/burn_rate.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/widgets/shimmer_box.dart';

class BurnRateCard extends ConsumerWidget {
  const BurnRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projAsync = ref.watch(financialProjectionProvider);

    return projAsync.when(
      loading: () => const DashboardCardSkeleton(height: 130),
      error: (_, __) => const SizedBox.shrink(),
      data: (proj) {
        if (proj == null) return const SizedBox.shrink();
        final br = proj.burnRate;
        if (br.daysElapsed == 0) return const SizedBox.shrink();

        final (color, label) = switch (br.pace) {
          BurnPace.comfortable => (const Color(0xFF00897B), 'No ritmo certo'),
          BurnPace.onTrack => (const Color(0xFFF59E0B), 'Atenção ao ritmo'),
          BurnPace.overspending => (Colors.red, 'Ritmo acima do orçamento'),
        };

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.speed_outlined, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Velocidade de gasto',
                      style: GoogleFonts.manrope(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: GoogleFonts.manrope(
                          fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _Metric(
                  label: 'R\$/dia',
                  value: FinancialCalculatorService.formatBRL(br.dailyRate.amount),
                  color: color,
                ),
                const SizedBox(width: 24),
                _Metric(
                  label: 'Projeção ao fechamento',
                  value: FinancialCalculatorService.formatBRL(
                      br.projectedTotalSpend.amount),
                  color: br.pace == BurnPace.overspending ? Colors.red : null,
                ),
                const Spacer(),
                _Metric(
                  label: 'Dias restantes',
                  value: '${br.daysRemaining}',
                  color: Colors.grey,
                ),
              ]),
              const SizedBox(height: 10),
              _PaceBar(pace: br.paceVsBudget, color: color),
            ]),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey)),
        ],
      );
}

class _PaceBar extends StatelessWidget {
  const _PaceBar({required this.pace, required this.color});
  final double pace;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (pace * 100).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Ritmo vs orçamento',
            style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey)),
        const Spacer(),
        Text('$pct%',
            style: GoogleFonts.manrope(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pace.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}
