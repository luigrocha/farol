/// FarolPainter — CustomPainter that draws the Farol lighthouse mark.
///
/// Faithfully reproduces the brand SVG (viewBox 0 0 64 64):
///   - Mast: white rect 10,14 → 7×44 + base rect 7,54 → 13×6
///   - Beam 1 (bright):  pivot(17,18) → (38,18)  horizontal
///   - Beam 2 (bright):  pivot(17,18) → (33,8)   diagonal up
///   - Beam 3 (shadow):  pivot(17,18) → (52,18)  horizontal far, 55% opacity
///   - Beam 4 (shadow):  pivot(17,18) → (46,2)   diagonal up far, 55% opacity
///
/// Three color schemes via [FarolMarkScheme]:
///   - full   → mast=white, beams=amber (#F5A623) — for dark backgrounds
///   - white  → mast=white, beams=white          — for dark backgrounds, mono
///   - navy   → mast=navy,  beams=navy            — for light backgrounds, mono
library farol_painter;

import 'package:flutter/material.dart';

enum FarolMarkScheme { full, white, navy }

class FarolPainter extends CustomPainter {
  const FarolPainter({required this.scheme});

  final FarolMarkScheme scheme;

  static const Color _amber = Color(0xFFF5A623);
  static const Color _navy  = Color(0xFF1B3A5C);
  static const Color _white = Colors.white;

  // ── Color resolution ──────────────────────────────────────────
  Color get _mastColor => switch (scheme) {
    FarolMarkScheme.full  => _white,
    FarolMarkScheme.white => _white,
    FarolMarkScheme.navy  => _navy,
  };

  Color get _beamBright => switch (scheme) {
    FarolMarkScheme.full  => _amber,
    FarolMarkScheme.white => _white,
    FarolMarkScheme.navy  => _navy,
  };

  Color get _beamDim => _beamBright.withValues(alpha: 0.55);

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from the 64×64 viewBox to the actual widget size.
    final double sx = size.width  / 64.0;
    final double sy = size.height / 64.0;

    // ── Mast ─────────────────────────────────────────────────────
    final mastPaint = Paint()
      ..color = _mastColor
      ..style = PaintingStyle.fill;

    // Shaft: x=10, y=14, w=7, h=44, rx=1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10 * sx, 14 * sy, 7 * sx, 44 * sy),
        Radius.circular(1 * sx),
      ),
      mastPaint,
    );

    // Base: x=7, y=54, w=13, h=6, rx=1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(7 * sx, 54 * sy, 13 * sx, 6 * sy),
        Radius.circular(1 * sx),
      ),
      mastPaint,
    );

    // ── Beams ─────────────────────────────────────────────────────
    final beamBrightPaint = Paint()
      ..color = _beamBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * sx
      ..strokeCap = StrokeCap.round;

    final beamDimPaint = Paint()
      ..color = _beamDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * sx
      ..strokeCap = StrokeCap.round;

    final pivot = Offset(17 * sx, 18 * sy);

    // Beam 1 bright: horizontal → (38, 18)
    canvas.drawLine(pivot, Offset(38 * sx, 18 * sy), beamBrightPaint);
    // Beam 2 bright: diagonal up → (33, 8)
    canvas.drawLine(pivot, Offset(33 * sx, 8 * sy),  beamBrightPaint);
    // Beam 3 dim: horizontal far → (52, 18)
    canvas.drawLine(pivot, Offset(52 * sx, 18 * sy), beamDimPaint);
    // Beam 4 dim: diagonal up far → (46, 2)
    canvas.drawLine(pivot, Offset(46 * sx, 2 * sy),  beamDimPaint);
  }

  @override
  bool shouldRepaint(FarolPainter old) => old.scheme != scheme;
}
