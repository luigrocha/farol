import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/investment.dart';
import '../../core/models/enums.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/farol_dialogs.dart';
import '../../core/widgets/farol_snackbar.dart';
import '../../design/farol_colors.dart' as tokens;

class InvestmentDetailScreen extends ConsumerWidget {
  final Investment investment;
  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final inv = investment;

    String typeLabel;
    String typeEmoji;
    try {
      final t = InvestmentType.fromDb(inv.type);
      typeLabel = t.label;
      typeEmoji = t.emoji;
    } catch (_) {
      typeLabel = inv.type;
      typeEmoji = '📋';
    }

    final typeColor = tokens.FarolColors.getCategoryColor(inv.type);
    final returnPct = inv.totalInvested > 0
        ? (inv.returnAmount / inv.totalInvested * 100)
        : 0.0;
    final isPositive = returnPct >= 0;
    final returnColor = isPositive ? tokens.FarolColors.tide : tokens.FarolColors.coral;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              inv.productName,
              style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: tokens.FarolColors.coral,
                onPressed: () => _confirmDelete(context, ref),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ── Hero card ──
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        typeColor.withOpacity(0.85),
                        typeColor,
                      ],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(typeEmoji, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          inv.productName,
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Text(
                          inv.institution,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    const Text('SALDO ATUAL', style: TextStyle(fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: Colors.white60)),
                    const SizedBox(height: 4),
                    _BRLBig(value: inv.currentBalance, size: 38),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
                            size: 12,
                            color: isPositive ? const Color(0xFF9BF6BA) : const Color(0xFFFF8A80),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${FinancialCalculatorService.formatBRL(inv.returnAmount)} (${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isPositive ? const Color(0xFF9BF6BA) : const Color(0xFFFF8A80),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Position breakdown ──
                Text('Posição', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surfaceLowest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(children: [
                    _StatLine(label: 'Total investido', value: FinancialCalculatorService.formatBRL(inv.totalInvested)),
                    _StatLine(label: 'Saldo atual', value: FinancialCalculatorService.formatBRL(inv.currentBalance)),
                    _StatLine(label: 'Rendimento (R\$)', value: FinancialCalculatorService.formatBRL(inv.returnAmount), valueColor: returnColor),
                    _StatLine(label: 'Rendimento (%)', value: '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%', valueColor: returnColor),
                    _StatLine(label: 'Data de entrada', value: _formatDate(inv.dateAdded), last: true),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Return bar ──
                _ReturnBar(totalInvested: inv.totalInvested, currentBalance: inv.currentBalance, typeColor: typeColor),

                const SizedBox(height: 16),

                // ── Additional info ──
                if (inv.liquidity != null || inv.notes != null) ...[
                  Text('Detalhes', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceLowest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(children: [
                      if (inv.liquidity != null)
                        _StatLine(label: 'Liquidez', value: _liquidityLabel(inv.liquidity!), last: inv.notes == null),
                      if (inv.notes != null)
                        _StatLine(label: 'Notas', value: inv.notes!, last: true),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: l10n.deleteInvestment,
      body: 'Remove "${investment.productName}"? ${l10n.cannotUndo}',
    );
    if (confirmed && context.mounted) {
      try {
        await ref.read(investmentRepositoryProvider).delete(investment.id);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar(e);
        }
      }
    }
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _liquidityLabel(String raw) => switch (raw.toUpperCase()) {
    'DAILY' => 'Diária (D+0)',
    'D1' => 'D+1',
    'D30' => 'D+30',
    'D60' => 'D+60',
    'D90' => 'D+90',
    'MATURITY' => 'No vencimento',
    _ => raw,
  };
}

// ─── Return Progress Bar ──────────────────────────────────────────────────────

class _ReturnBar extends StatelessWidget {
  final double totalInvested;
  final double currentBalance;
  final Color typeColor;

  const _ReturnBar({required this.totalInvested, required this.currentBalance, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (totalInvested <= 0) return const SizedBox.shrink();
    final ratio = (currentBalance / totalInvested).clamp(0.0, 2.0);
    final isPositive = currentBalance >= totalInvested;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Evolução do capital', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onSurface)),
          Text(
            isPositive ? '+${((ratio - 1) * 100).toStringAsFixed(1)}%' : '${((ratio - 1) * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isPositive ? tokens.FarolColors.tide : tokens.FarolColors.coral),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Investido', style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 1.0,
                minHeight: 8,
                backgroundColor: typeColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(typeColor.withOpacity(0.4)),
              ),
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Atual', style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (ratio / (ratio > 1 ? ratio : 1.0)).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: (isPositive ? tokens.FarolColors.tide : tokens.FarolColors.coral).withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(isPositive ? tokens.FarolColors.tide : tokens.FarolColors.coral),
              ),
            ),
          ])),
        ]),
      ]),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatLine extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool last;
  const _StatLine({required this.label, required this.value, this.valueColor, this.last = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: colors.surfaceLow)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft)),
        Flexible(child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? colors.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}

class _BRLBig extends StatelessWidget {
  final double value;
  final double size;
  const _BRLBig({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    final formatted = FinancialCalculatorService.formatBRL(value);
    final parts = formatted.split(',');
    final intPart = parts[0].replaceFirst('R\$ ', '');
    final centsPart = parts.length > 1 ? parts[1] : '00';
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: Colors.white70)),
      Text(intPart, style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -size * 0.028)),
      Text(',$centsPart', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.8))),
    ]);
  }
}
