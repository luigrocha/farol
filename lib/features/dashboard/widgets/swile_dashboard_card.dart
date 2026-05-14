import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;

class SwileDashboardCard extends ConsumerWidget {
  const SwileDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final remaining = ref.watch(swileRemainingProvider);
    final food = ref.watch(swileFoodBalanceProvider);
    final meal = ref.watch(swileMealBalanceProvider);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/swile'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant, size: 14, color: Color(0xFFE84840)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Swile',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 16, color: colors.onSurfaceFaint),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'DISPONIBLE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FinancialCalculatorService.formatBRL(remaining),
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.FarolColors.beam,
                ),
              ),
              const SizedBox(height: 16),
              _SwileRow(
                icon: Icons.fastfood_outlined,
                label: 'Swile Food',
                value: food,
                colors: colors,
              ),
              const SizedBox(height: 8),
              _SwileRow(
                icon: Icons.coffee_outlined,
                label: 'Saldo Livre',
                value: meal,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwileRow extends StatelessWidget {
  const _SwileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final double value;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceSoft),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
          ),
        ),
        Text(
          FinancialCalculatorService.formatBRL(value),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
