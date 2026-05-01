import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/farol_colors.dart';

class PeriodBanner extends ConsumerWidget {
  const PeriodBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final period = ref.watch(selectedPeriodProvider);

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
          Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: colors.onSurfaceSoft,
          ),
          const SizedBox(width: 8),
          Text(
            period.label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
