import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/theme/farol_colors.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/domain/auth_state.dart';
import 'package:google_fonts/google_fonts.dart';

class SwileScreen extends ConsumerWidget {
  const SwileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final authState = ref.watch(authStateProvider).value;
    final displayName = authState is AppAuthAuthenticated
        ? (authState.user.displayName ?? authState.user.email ?? '')
        : '';
    final cardName = _initials(displayName);

    final swileTotal = ref.watch(effectiveSwileProvider);
    final swileRemaining = ref.watch(swileRemainingProvider);
    final mealBalance = ref.watch(swileMealBalanceProvider);
    final foodBalance = ref.watch(swileFoodBalanceProvider);
    final txAsync = ref.watch(swileTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: Text(l10n.corporateBenefits,
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Swile',
                style: GoogleFonts.manrope(
                    fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
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
                  BoxShadow(
                      color: const Color(0xFFE84840).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('swile',
                          style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: Colors.white)),
                      const SizedBox(height: 28),
                      const Text('SALDO DISPONÍVEL',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70)),
                      const SizedBox(height: 4),
                      _BRLBig(value: swileRemaining, size: 30, color: Colors.white),
                      const SizedBox(height: 6),
                      Text(
                        'de ${FinancialCalculatorService.formatBRL(swileTotal)} total',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('•••• •••• •••• ••••',
                              style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 2)),
                          Text(cardName.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _BreakdownCard(
                        label: l10n.translate('pay_swile_food'),
                        value: foodBalance,
                        note: l10n.translate('pay_swile_food'),
                        color: tokens.FarolColors.beam)),
                const SizedBox(width: 10),
                Expanded(
                    child: _BreakdownCard(
                        label: l10n.translate('pay_swile_meal'),
                        value: mealBalance,
                        note: l10n.translate('pay_swile_meal'),
                        color: tokens.FarolColors.beam)),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.translate('recent_transactions'),
                    style: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),

            txAsync.when(
              loading: () => Column(
                children: List.generate(
                    3,
                    (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ShimmerBox(
                              width: double.infinity, height: 68, borderRadius: 16),
                        )),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('Error al cargar transacciones',
                        style: TextStyle(color: colors.onSurfaceSoft))),
              ),
              data: (txList) {
                if (txList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 40, color: colors.onSurfaceFaint),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhuma transação Swile ainda.\nRegistre um gasto com pagamento Swile.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: colors.onSurfaceSoft),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: txList
                      .take(20)
                      .map((tx) => _TxSwile(
                            name: tx.storeDescription ??
                                tx.category,
                            paymentMethod: tx.paymentMethod,
                            date: tx.createdAt,
                            value: tx.amount,
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'USUÁRIO';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0];
    return '${parts.first} ${parts.last[0]}.';
  }
}

class _BreakdownCard extends StatelessWidget {
  final String label, note;
  final double value;
  final Color color;
  const _BreakdownCard(
      {required this.label,
      required this.value,
      required this.note,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceSoft)),
          const SizedBox(height: 6),
          _BRLSmall(value: value, size: 18, weight: FontWeight.w800),
        ],
      ),
    );
  }
}

class _TxSwile extends StatelessWidget {
  final String name, paymentMethod;
  final DateTime date;
  final double value;
  const _TxSwile(
      {required this.name,
      required this.paymentMethod,
      required this.date,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    String dateLabel;
    if (txDay == today) {
      dateLabel = 'Hoje · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (txDay == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Ontem';
    } else {
      dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF97366).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.restaurant, size: 16, color: Color(0xFFE84840)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${paymentMethod.toUpperCase()} · $dateLabel',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: colors.onSurfaceSoft,
                        fontWeight: FontWeight.w700)),
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
  final double value;
  final double size;
  final Color? color;
  const _BRLBig({required this.value, required this.size, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurface;
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('R\$ ',
              style: GoogleFonts.manrope(
                  fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
          Text(f.replaceFirst('R\$ ', ''),
              style: GoogleFonts.manrope(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: c,
                  letterSpacing: -size * 0.028)),
          Text(',$cents',
              style: GoogleFonts.manrope(
                  fontSize: size * 0.56,
                  fontWeight: FontWeight.w800,
                  color: c.withValues(alpha: 0.85))),
        ]);
  }
}

class _BRLSmall extends StatelessWidget {
  final double value;
  final double size;
  final FontWeight weight;
  const _BRLSmall(
      {required this.value, required this.size, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    final f = FinancialCalculatorService.formatBRL(value);
    return Text(f,
        style: GoogleFonts.inter(
            fontSize: size,
            fontWeight: weight,
            color: context.colors.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()]));
  }
}
