import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/models/enums.dart';
import '../../core/widgets/farol_charts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/investment.dart';
import 'add_investment_bottom_sheet.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(AppLocalizations.of(context).translate('portfolio'), style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            actions: [
              IconButton(icon: const Icon(Icons.language, size: 22), onPressed: () {}),
              IconButton(icon: const Icon(Icons.settings_outlined, size: 22), onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const _ConsolidatedHero(),
              const SizedBox(height: 12),
              const _AllocationCard(),
              const SizedBox(height: 12),
              const _IASuggestionCard(),
              const SizedBox(height: 16),
              const _InversionesHeader(),
              const _InvestmentsList(),
              const SizedBox(height: 80),
            ])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddInvestmentBottomSheet(),
        ),
        backgroundColor: AppTheme.secondaryColor,
        child: const Icon(Icons.add, color: AppTheme.primaryColor),
      ),
    );
  }
}

class _ConsolidatedHero extends ConsumerWidget {
  const _ConsolidatedHero();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalInvestmentBalanceProvider);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryContainer, AppTheme.primaryColor]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(AppLocalizations.of(context).translate('total_consolidated'), style: const TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Colors.white60)),
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.white60),
        ]),
        const SizedBox(height: 6),
        _BRLBig(value: balance, size: 36, color: Colors.white),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.trending_up, size: 13, color: Color(0xFFFCD37D)),
          const SizedBox(width: 4),
          const Text('+12.4%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFCD37D))),
          const SizedBox(width: 4),
          Text('vs. último mes', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
        ]),
        const SizedBox(height: 18),
        const Row(children: [
          _StatPill(label: 'CDI Bruto', value: '112%'),
          SizedBox(width: 8),
          _StatPill(label: 'Fee', value: '0.2%'),
          SizedBox(width: 8),
          _StatPill(label: 'Riesgo', value: 'Medio'),
        ]),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  const _StatPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(99)),
      child: Column(children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.white60)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    ));
  }
}

class _AllocationCard extends ConsumerWidget {
  const _AllocationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final investments = ref.watch(investmentsProvider).value ?? [];
    if (investments.isEmpty) return const SizedBox();
    final byType = <String, double>{};
    for (final inv in investments) { byType[inv.type] = (byType[inv.type] ?? 0) + inv.currentBalance; }
    final total = byType.values.fold(0.0, (s, v) => s + v);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context).translate('asset_allocation'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Distribución estratégica de la cartera', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
          ]),
          Icon(Icons.more_horiz, color: colors.onSurfaceSoft, size: 18),
        ]),
        const SizedBox(height: 16),
        Center(child: FarolDonutChart(data: byType, total: total, centerLabel: 'Diversificada')),
        const SizedBox(height: 14),
        ...byType.entries.map((e) {
          String label; try { label = InvestmentType.fromDb(e.key).label; } catch (_) { label = e.key; }
          final pct = total > 0 ? (e.value / total * 100).toInt() : 0;
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.getCategoryColor(e.key), shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 13, color: colors.onSurface))]),
            Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onSurface)),
          ]));
        }),
      ]),
    );
  }
}

class _IASuggestionCard extends StatelessWidget {
  const _IASuggestionCard();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 18),
        const SizedBox(height: 10),
        Text(AppLocalizations.of(context).translate('ia_suggestion'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Su cartera tiene baja exposición en activos inmobiliarios. Considere FIIs de tijolo.', style: TextStyle(fontSize: 12, color: colors.onSurfaceMuted, height: 1.5)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          child: const Text('Explorar FIIs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
    );
  }
}

class _InversionesHeader extends StatelessWidget {
  const _InversionesHeader();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Inversiones', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
        Text('Detalle por activo', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
      ]),
      const Row(children: [
        Text('Ver Historial', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor)),
        Icon(Icons.chevron_right, size: 14, color: AppTheme.secondaryColor),
      ]),
    ]));
  }
}

class _InvestmentsList extends ConsumerWidget {
  const _InvestmentsList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final investments = ref.watch(investmentsProvider).value ?? [];
    if (investments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text(l10n.noInvestmentsYet,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceSoft, height: 1.6))),
      );
    }
    return Column(children: investments.map((inv) => _InvRow(inv: inv)).toList());
  }
}

class _InvRow extends ConsumerWidget {
  final Investment inv;
  const _InvRow({required this.inv});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typeColor = AppTheme.getCategoryColor(inv.type);
    String typeLabel;
    try { typeLabel = InvestmentType.fromDb(inv.type).label; } catch (_) { typeLabel = inv.type; }
    final returnPct = inv.totalInvested > 0 ? (inv.returnAmount / inv.totalInvested * 100) : 0.0;
    final isPositive = returnPct >= 0;

    return Dismissible(
      key: ValueKey(inv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final contextL10n = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(contextL10n.deleteInvestment),
            content: Text('Remove "${inv.productName}"? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ?? false,
      onDismissed: (_) async {
        try {
          await ref.read(investmentRepositoryProvider).delete(inv.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/investment_detail', arguments: inv),
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(
                  () { try { return InvestmentType.fromDb(inv.type).emoji; } catch (_) { return '📋'; } }(),
                  style: const TextStyle(fontSize: 18),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv.productName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.onSurface)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(typeLabel, style: TextStyle(fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: typeColor)),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: colors.onSurfaceFaint, fontSize: 10)),
                  const SizedBox(width: 6),
                  Text(inv.institution, style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft)),
                ]),
              ])),
              const Icon(Icons.chevron_right, size: 16),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).translate('current_balance'),
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceFaint, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                _BRLSmall(value: inv.currentBalance, size: 13, weight: FontWeight.w700),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('RETURN', style: TextStyle(fontSize: 9, color: colors.onSurfaceFaint, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                Text(
                  '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isPositive ? AppTheme.tertiaryColor : AppTheme.errorColor),
                ),
              ]),
            ]),
          ])),
        ),
      ),
    );
  }
}

class _BRLBig extends StatelessWidget {
  final double value; final double size; final Color? color; final FontWeight weight;
  const _BRLBig({required this.value, required this.size, this.color, this.weight = FontWeight.w800});
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurface;
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: c, letterSpacing: -size * 0.028)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: weight, color: c.withOpacity(0.85))),
    ]);
  }
}

class _BRLSmall extends StatelessWidget {
  final double value; final double size; final Color? color; final FontWeight weight;
  const _BRLSmall({required this.value, required this.size, this.color, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    return Text(FinancialCalculatorService.formatBRL(value), style: GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? context.colors.onSurface, fontFeatures: [FontFeature.tabularFigures()]));
  }
}
