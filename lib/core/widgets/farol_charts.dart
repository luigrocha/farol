import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FarolDonutChart extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final String centerLabel;

  const FarolDonutChart({
    super.key,
    required this.data,
    required this.total,
    this.centerLabel = 'Diversificada',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              sections: data.entries.map((e) => PieChartSectionData(
                color: AppTheme.getCategoryColor(e.key),
                value: e.value,
                radius: 18,
                showTitle: false,
              )).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.onSurfaceSoft,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${(total / 1000).toStringAsFixed(1)}k',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FarolTrendChart extends StatelessWidget {
  final List<double> points;
  final Color color;

  const FarolTrendChart({
    super.key,
    required this.points,
    this.color = AppTheme.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FarolCandleChart extends StatelessWidget {
  final List<CandleData> data;

  const FarolCandleChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: _CandlePainter(data: data),
    );
  }
}

class CandleData {
  final double open, close, low, high;
  CandleData({required this.open, required this.close, required this.low, required this.high});
}

class _CandlePainter extends CustomPainter {
  final List<CandleData> data;
  _CandlePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double minVal = data.map((e) => e.low).reduce(math.min) * 0.98;
    final double maxVal = data.map((e) => e.high).reduce(math.max) * 1.02;
    final double range = maxVal - minVal;

    final double cw = size.width / data.length;
    final double candleWidth = cw * 0.6;

    final paintUp = Paint()..style = PaintingStyle.fill;
    final paintDown = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final bool up = d.close >= d.open;
      final Color col = up ? AppTheme.secondaryColor : AppTheme.errorColor;
      final p = up ? paintUp : paintDown;
      p.color = col;

      final double x = i * cw + cw / 2;
      final double yH = size.height - ((d.high - minVal) / range) * size.height;
      final double yL = size.height - ((d.low - minVal) / range) * size.height;
      final double yO = size.height - ((d.open - minVal) / range) * size.height;
      final double yC = size.height - ((d.close - minVal) / range) * size.height;

      // Wick
      canvas.drawLine(Offset(x, yH), Offset(x, yL), Paint()..color = col..strokeWidth = 1.2);

      // Body
      final double top = math.min(yO, yC);
      final double bottom = math.max(yO, yC);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - candleWidth / 2, top, x + candleWidth / 2, math.max(top + 2, bottom)),
          const Radius.circular(2),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
