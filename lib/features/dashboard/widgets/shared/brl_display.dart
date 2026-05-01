import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/financial_calculator_service.dart';
import '../../../../core/theme/farol_colors.dart';

class BrlBig extends ConsumerWidget {
  final double value;
  final double size;
  final Color? color;
  final FontWeight weight;
  const BrlBig({
    super.key,
    required this.value,
    required this.size,
    this.color,
    this.weight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = color ?? context.colors.onSurface;
    final isPrivate = ref.watch(privacyModeProvider);
    if (isPrivate) {
      return Text(
        '••••••',
        style: GoogleFonts.manrope(
          fontSize: size,
          fontWeight: weight,
          color: c,
        ),
      );
    }
    final parts = FinancialCalculatorService.formatBRL(value).split(',');
    final f = parts[0];
    final cents = parts.length > 1 ? parts[1] : '00';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'R\$ ',
          style: GoogleFonts.manrope(
            fontSize: size * 0.48,
            fontWeight: FontWeight.w500,
            color: c,
          ),
        ),
        Text(
          f.replaceFirst('R\$ ', ''),
          style: GoogleFonts.manrope(
            fontSize: size,
            fontWeight: weight,
            color: c,
            letterSpacing: -size * 0.028,
          ),
        ),
        Text(
          ',$cents',
          style: GoogleFonts.manrope(
            fontSize: size * 0.56,
            fontWeight: weight,
            color: c.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class BrlSmall extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  final FontWeight weight;
  const BrlSmall({
    super.key,
    required this.value,
    required this.size,
    this.color,
    this.weight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final f = FinancialCalculatorService.formatBRL(value);
    return Text(
      f,
      style: GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.colors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 4),
            BrlBig(value: value, size: 16, color: color, weight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}
