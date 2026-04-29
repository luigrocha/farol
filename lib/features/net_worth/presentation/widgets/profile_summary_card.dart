import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/farol_colors.dart';
import '../../../../design/farol_colors.dart' as tokens;
import '../../../../design/widgets/farol_card.dart';
import '../../../../design/widgets/brl_text.dart';

class ProfileSummaryCard extends ConsumerWidget {
  const ProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPrivate = ref.watch(privacyModeProvider);
    final total = ref.watch(enhancedNetWorthProvider);
    final banks = ref.watch(liquidAccountsTotalProvider);
    final investments = ref.watch(totalInvestmentBalanceProvider);
    final fgts = ref.watch(fgtsBalanceFromAccountsProvider);

    return FarolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patrimônio Líquido',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          isPrivate
              ? Text('••••••',
                  style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface))
              : BrlText(value: total, fontSize: 32, color: colors.onSurface),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniPill(label: 'Contas', value: banks, isPrivate: isPrivate, color: tokens.FarolColors.navy),
              const SizedBox(width: 8),
              _MiniPill(label: 'Invest.', value: investments, isPrivate: isPrivate, color: tokens.FarolColors.tide),
              const SizedBox(width: 8),
              _MiniPill(label: 'FGTS', value: fgts, isPrivate: isPrivate, color: tokens.FarolColors.beam),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final double value;
  final bool isPrivate;
  final Color color;

  const _MiniPill({
    required this.label,
    required this.value,
    required this.isPrivate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft)),
            ]),
            const SizedBox(height: 4),
            isPrivate
                ? Text('•••', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurface))
                : BrlText(value: value, fontSize: 12, color: colors.onSurface),
          ],
        ),
      ),
    );
  }
}
