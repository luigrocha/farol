import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/i18n/app_localizations.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/theme/farol_colors.dart';
import '../../core/services/financial_calculator_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SwileScreen extends StatelessWidget {
  const SwileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.corporateBenefits, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Swile', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            const SizedBox(height: 18),

            // Virtual Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF97366), Color(0xFFE84840)],
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE84840).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20, right: -20,
                    child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('swile', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)),
                      const SizedBox(height: 36),
                      const Text('AVAILABLE BALANCE', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white70)),
                      const SizedBox(height: 4),
                      const _BRLBig(value: 1450.30, size: 30, color: Colors.white),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('5320 ●●●● ●●●● 7891', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withOpacity(0.9), letterSpacing: 2)),
                          Text('RICARDO A.', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: _BreakdownCard(label: 'Food Voucher', value: 920.50, note: 'Renews on 01/10', color: tokens.FarolColors.beam)),
                SizedBox(width: 10),
                Expanded(child: _BreakdownCard(label: 'Meal Voucher', value: 529.80, note: 'Daily · R\$ 33', color: tokens.FarolColors.beam)),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.monthlySpending, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800)),
                          Text(l10n.last7Days, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _BRLSmall(value: 348.40, size: 15, weight: FontWeight.w800),
                          Text('+12% vs prev. week', style: TextStyle(fontSize: 10, color: tokens.FarolColors.beam, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [45, 68, 35, 82, 55, 28, 72].asMap().entries.map((e) {
                        final active = e.key == 3;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: e.value.toDouble() * 0.8,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    gradient: active ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tokens.FarolColors.beam, tokens.FarolColors.tide]) : null,
                                    color: active ? null : colors.surfaceLow,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(['M','T','W','T','F','S','S'][e.key], style: TextStyle(fontSize: 9, color: colors.onSurfaceFaint, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800)),
                const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.FarolColors.beam)),
              ],
            ),
            const SizedBox(height: 12),
            const _TxSwile(name: 'Restaurante Fasano', cat: 'MEAL · TODAY, 13:45', value: 89.90),
            const _TxSwile(name: 'Supermercado Pão de Açúcar', cat: 'FOOD · YESTERDAY', value: 217.40),
            const _TxSwile(name: 'Cafeteria Santo Grão', cat: 'MEAL · 12 SEP', value: 41.10),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String label, note;
  final double value;
  final Color color;
  const _BreakdownCard({required this.label, required this.value, required this.note, required this.color});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: colors.onSurfaceSoft)),
          const SizedBox(height: 6),
          _BRLSmall(value: value, size: 18, weight: FontWeight.w800),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TxSwile extends StatelessWidget {
  final String name, cat;
  final double value;
  const _TxSwile({required this.name, required this.cat, required this.value});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF97366).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.restaurant, size: 16, color: Color(0xFFE84840)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface)),
                Text(cat, style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: colors.onSurfaceSoft, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _BRLSmall(value: -value, size: 14, weight: FontWeight.w700),
        ],
      ),
    );
  }
}

class _BRLBig extends StatelessWidget {
  final double value; final double size; final Color? color;
  const _BRLBig({required this.value, required this.size, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurface;
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, color: c, letterSpacing: -size * 0.028)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: FontWeight.w800, color: c.withOpacity(0.85))),
    ]);
  }
}

class _BRLSmall extends StatelessWidget {
  final double value; final double size; final FontWeight weight;
  const _BRLSmall({required this.value, required this.size, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    final f = FinancialCalculatorService.formatBRL(value);
    return Text(f, style: GoogleFonts.inter(fontSize: size, fontWeight: weight, color: context.colors.onSurface, fontFeatures: const [FontFeature.tabularFigures()]));
  }
}
