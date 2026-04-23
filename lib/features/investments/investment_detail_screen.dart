import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/farol_charts.dart';
import '../../core/services/financial_calculator_service.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final String productName;
  
  const InvestmentDetailScreen({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Asset Detail', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFEC7000), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('I', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Text('Itaú Unibanco PN', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSoft)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            _BRLBig(value: 31.84, size: 40),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.secondaryContainer, borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.trending_up, size: 12, color: AppTheme.secondaryColor),
                  SizedBox(width: 4),
                  Text('+R\$ 0.48 · +1.54% today', style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            
            // Chart Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.surfaceLowest, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  FarolCandleChart(data: [
                    CandleData(open: 30, close: 31, low: 29.5, high: 31.5),
                    CandleData(open: 31, close: 30.5, low: 30.2, high: 31.3),
                    CandleData(open: 30.5, close: 31.2, low: 30.3, high: 31.4),
                    CandleData(open: 31.2, close: 30.8, low: 30.5, high: 31.5),
                    CandleData(open: 30.8, close: 31.5, low: 30.7, high: 31.8),
                    CandleData(open: 31.5, close: 31, low: 30.8, high: 31.7),
                    CandleData(open: 31, close: 31.4, low: 30.9, high: 31.6),
                    CandleData(open: 31.4, close: 31.1, low: 30.9, high: 31.5),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['1D','5D','1M','6M','1Y','MAX'].asMap().entries.map((e) {
                      final active = e.key == 2;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.onSurfaceSoft)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Text('Statistics', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.surfaceLowest, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: const [
                  _StatLine(label: 'Open', value: 'R\$ 31.36'),
                  _StatLine(label: 'High · Low', value: 'R\$ 32.10 · R\$ 31.20'),
                  _StatLine(label: 'Volume', value: '48.3M'),
                  _StatLine(label: 'P/E', value: '8.42'),
                  _StatLine(label: 'Dividend Yield', value: '5.20%', color: AppTheme.secondaryColor),
                  _StatLine(label: 'Market Cap', value: 'R\$ 311B', last: true),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            // Position card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [AppTheme.primaryContainer, AppTheme.primaryColor]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR POSITION', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white70)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PositionStat(label: 'QUANTITY', value: '240'),
                      _PositionStat(label: 'AVG', value: 'R\$ 28.10'),
                      _PositionStat(label: 'GAIN', value: '+13.3%', color: const Color(0xFF9BF6BA)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(color: AppTheme.surface),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Buy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  foregroundColor: AppTheme.errorColor,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Sell', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool last;
  const _StatLine({required this.label, required this.value, this.color, this.last = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppTheme.surfaceLow))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceSoft)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppTheme.onSurface)),
        ],
      ),
    );
  }
}

class _PositionStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _PositionStat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.65))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: color ?? Colors.white)),
      ],
    );
  }
}

class _BRLBig extends StatelessWidget {
  final double value; final double size;
  const _BRLBig({required this.value, required this.size});
  @override
  Widget build(BuildContext context) {
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -size * 0.028)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: FontWeight.w800, color: AppTheme.onSurface.withOpacity(0.85))),
    ]);
  }
}
