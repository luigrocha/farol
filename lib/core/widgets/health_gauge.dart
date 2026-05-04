import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../design/farol_colors.dart' as tokens;
import '../theme/farol_colors.dart';
import '../i18n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthGauge extends StatelessWidget {
  final double score;
  final double size;
  final String? statusLabel;

  const HealthGauge({super.key, required this.score, this.size = 140, this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color scoreColor;
    if (score >= 80) {
      scoreColor = tokens.FarolColors.tide;
    } else if (score >= 50) {
      scoreColor = tokens.FarolColors.beam;
    } else {
      scoreColor = tokens.FarolColors.coral;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(score: score, color: scoreColor, trackColor: colors.surfaceLow),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}',
                style: GoogleFonts.manrope(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                  height: 1.1,
                ),
              ),
              Text(
                statusLabel ?? AppLocalizations.of(context).healthHealthy,
                style: TextStyle(
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final Color trackColor;

  _GaugePainter({required this.score, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = 3 * math.pi / 4;
    const totalAngle = 3 * math.pi / 2;
    final sweepAngle = (score / 100) * totalAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, totalAngle, false,
      Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false,
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.score != score || old.color != color || old.trackColor != trackColor;
}
