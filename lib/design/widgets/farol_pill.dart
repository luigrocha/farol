import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FarolPill extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final Color? backgroundColor;
  final Color? labelColor;

  const FarolPill({
    super.key,
    required this.label,
    this.dotColor,
    this.backgroundColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = labelColor ?? Theme.of(context).colorScheme.onSurface;
    final bg = backgroundColor ?? fg.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
