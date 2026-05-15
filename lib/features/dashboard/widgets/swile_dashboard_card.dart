import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/ds_tokens.dart';

class SwileDashboardCard extends ConsumerWidget {
  const SwileDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final remaining = ref.watch(swileRemainingProvider);
    final food = ref.watch(swileFoodBalanceProvider);
    final meal = ref.watch(swileMealBalanceProvider);

    return DSCard(
      onTap: () => Navigator.pushNamed(context, '/swile'),
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97366).withValues(alpha: 0.12),
                  borderRadius: DSRadius.xsBR,
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 16,
                  color: Color(0xFFE84840),
                ),
              ),
              const SizedBox(width: DSSpacing.sm),
              Text(
                'Swile',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: colors.onSurfaceFaint,
              ),
            ],
          ),

          const SizedBox(height: DSSpacing.lg),

          // ── Available balance ───────────────────────────────────────────
          Text(
            'DISPONÍVEL',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceFaint,
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

          const SizedBox(height: DSSpacing.lg),

          // ── Breakdown rows ──────────────────────────────────────────────
          _SwileRow(
            icon: Icons.fastfood_outlined,
            label: 'Swile Food',
            value: food,
          ),
          const SizedBox(height: DSSpacing.sm),
          _SwileRow(
            icon: Icons.coffee_outlined,
            label: 'Saldo Livre',
            value: meal,
          ),
        ],
      ),
    );
  }
}

class _SwileRow extends StatelessWidget {
  const _SwileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceSoft),
        const SizedBox(width: DSSpacing.xs + 2),
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
