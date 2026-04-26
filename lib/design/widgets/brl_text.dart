import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrlText extends StatelessWidget {
  final double value;
  final double fontSize;
  final bool signed;
  final Color? color;

  const BrlText({
    super.key,
    required this.value,
    this.fontSize = 32,
    this.signed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final absValue = value.abs();

    // Format integer and decimal parts in BRL (. thousands, , decimal)
    final intPart = absValue.truncate();
    final decPart = ((absValue - intPart) * 100).round().clamp(0, 99);

    final intStr = _formatThousands(intPart);
    final decStr = decPart.toString().padLeft(2, '0');

    String prefix = 'R\$ ';
    if (signed) prefix = value >= 0 ? '+ R\$ ' : '− R\$ ';

    final prefixSize = fontSize * 0.54;
    final decSize = fontSize * 0.60;

    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: prefix,
          style: GoogleFonts.inter(
            fontSize: prefixSize,
            fontWeight: FontWeight.w500,
            color: baseColor.withValues(alpha: 0.75),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        TextSpan(
          text: intStr,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: baseColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        TextSpan(
          text: ',$decStr',
          style: GoogleFonts.inter(
            fontSize: decSize,
            fontWeight: FontWeight.w600,
            color: baseColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }

  static String _formatThousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    final offset = s.length % 3;
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (i - offset) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
