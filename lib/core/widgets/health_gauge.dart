import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthGauge extends StatelessWidget {
  final double score; // 0 to 100
  final double size;
  final String? statusLabel;

  const HealthGauge({
    super.key,
    required this.score,
    this.size = 140,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppTheme.healthGreen;
    } else if (score >= 50) {
      scoreColor = AppTheme.healthAmber;
    } else {
      scoreColor = AppTheme.healthRed;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(score: score, color: scoreColor),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}',
                style: GoogleFonts.manrope(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  height: 1.1,
                ),
              ),
              Text(
                statusLabel ?? 'HEALTHY',
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

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.12;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    const double startAngle = 3 * math.pi / 4;
    const double totalAngle = 3 * math.pi / 2;
    final double sweepAngle = (score / 100) * totalAngle;

    final bgPaint = Paint()
      ..color = AppTheme.surfaceLow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      bgPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
    
    // Subtle glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
