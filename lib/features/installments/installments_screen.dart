import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/card_installment.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/theme/farol_colors.dart';
import 'add_installment_bottom_sheet.dart';

class InstallmentsScreen extends ConsumerWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync = ref.watch(installmentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Parcelas', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const _HeroCard(),
              const SizedBox(height: 16),
              const _InstallmentsHeader(),
              installmentsAsync.when(
                data: (list) {
                  if (list.isEmpty) return const _EmptyState();
                  return Column(
                    children: list.map((inst) => _InstallmentTile(inst: inst)).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Error: $e')),
                ),
              ),
              const SizedBox(height: 80),
            ])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddInstallmentBottomSheet(),
        ),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(totalMonthlyInstallmentsProvider);
    final remaining = ref.watch(totalRemainingInstallmentsProvider);
    final count = ref.watch(installmentsProvider).value?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF6B3FA0)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('COMPROMISSO MENSAL', style: TextStyle(
          fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Colors.white60,
        )),
        const SizedBox(height: 6),
        _BRLBig(value: monthly, size: 32, color: Colors.white),
        const SizedBox(height: 18),
        Row(children: [
          _HeroPill(label: 'PARCELAS', value: '$count ativas'),
          const SizedBox(width: 8),
          _HeroPill(label: 'SALDO RESTANTE', value: FinancialCalculatorService.formatBRL(remaining)),
        ]),
      ]),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label, value;
  const _HeroPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.white60)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }
}

class _InstallmentsHeader extends StatelessWidget {
  const _InstallmentsHeader();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ativas', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Deslize para excluir · toque para ações', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
        ]),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
          child: const Center(child: Text('💳', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 16),
        Text('Sem parcelas ativas', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
        const SizedBox(height: 6),
        Text('Adicione uma compra parcelada no cartão', style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft)),
      ])),
    );
  }
}

class _InstallmentTile extends ConsumerWidget {
  final CardInstallment inst;
  const _InstallmentTile({required this.inst});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Dismissible(
      key: ValueKey(inst.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text('Excluir', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir parcela?'),
          content: Text('Remover "${inst.description}"? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ) ?? false,
      onDismissed: (_) async {
        try {
          await ref.read(installmentRepositoryProvider).delete(inst.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red.shade700),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => _showDetailSheet(context, ref),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B3FA0).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('💳', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inst.description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  _ProgressBadge(current: inst.currentInstallment, total: inst.numInstallments),
                  const SizedBox(width: 6),
                  if (inst.notes != null && inst.notes!.isNotEmpty) ...[
                    Icon(Icons.notes, size: 11, color: colors.onSurfaceFaint),
                    const SizedBox(width: 2),
                    Expanded(child: Text(inst.notes!, style: TextStyle(fontSize: 10, color: colors.onSurfaceFaint), overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _BRLSmall(value: inst.monthlyAmount, size: 14, weight: FontWeight.w700),
                const SizedBox(height: 2),
                Text('por mês', style: TextStyle(fontSize: 10, color: colors.onSurfaceFaint)),
              ]),
            ]),
            const SizedBox(height: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${inst.currentInstallment}ª parcela paga', style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft)),
                Text('Restam ${FinancialCalculatorService.formatBRL(inst.remainingBalance)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.onSurfaceSoft)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: inst.progressPercent,
                  minHeight: 5,
                  backgroundColor: const Color(0xFF6B3FA0).withOpacity(0.12),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6B3FA0)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InstallmentDetailSheet(inst: inst, ref: ref),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int current, total;
  const _ProgressBadge({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6B3FA0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$current/$total parcelas',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B3FA0), letterSpacing: 0.3),
      ),
    );
  }
}

class _InstallmentDetailSheet extends ConsumerStatefulWidget {
  final CardInstallment inst;
  final WidgetRef ref;
  const _InstallmentDetailSheet({required this.inst, required this.ref});
  @override
  ConsumerState<_InstallmentDetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends ConsumerState<_InstallmentDetailSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inst = widget.inst;
    const purple = Color(0xFF6B3FA0);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
          color: colors.surfaceLow, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Header
        Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: purple.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('💳', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inst.description, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            _ProgressBadge(current: inst.currentInstallment, total: inst.numInstallments),
          ])),
        ]),
        const SizedBox(height: 20),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: inst.progressPercent,
            minHeight: 8,
            backgroundColor: purple.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(purple),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(inst.progressPercent * 100).toInt()}% concluído', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
          Text('${inst.remainingInstallments} parcela${inst.remainingInstallments == 1 ? '' : 's'} restante${inst.remainingInstallments == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
        ]),
        const SizedBox(height: 20),

        // Stats row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            _StatBox(label: 'MENSAL', value: FinancialCalculatorService.formatBRL(inst.monthlyAmount), color: purple),
            _StatDivider(),
            _StatBox(label: 'RESTANTE', value: FinancialCalculatorService.formatBRL(inst.remainingBalance), color: colors.onSurface),
            _StatDivider(),
            _StatBox(label: 'TOTAL', value: FinancialCalculatorService.formatBRL(inst.totalValue), color: colors.onSurface),
          ]),
        ),
        const SizedBox(height: 20),

        if (inst.notes != null && inst.notes!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.notes, size: 14, color: colors.onSurfaceSoft),
              const SizedBox(width: 8),
              Expanded(child: Text(inst.notes!, style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        if (!inst.isComplete) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _registerPayment,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                inst.currentInstallment + 1 >= inst.numInstallments ? 'Concluir parcelas' : 'Registrar ${inst.currentInstallment + 1}ª parcela paga',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir parcela', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _registerPayment() async {
    final inst = widget.inst;
    final newCurrent = inst.currentInstallment + 1;
    setState(() => _loading = true);
    try {
      await ref.read(installmentRepositoryProvider).advance(inst.id, newCurrent, inst.numInstallments);
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newCurrent >= inst.numInstallments
              ? '🎉 "${inst.description}" concluída!'
              : '✅ ${newCurrent}ª parcela registrada'), // ignore: unnecessary_brace_in_string_interps
          backgroundColor: const Color(0xFF6B3FA0),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir parcela?'),
        content: Text('Remover "${widget.inst.description}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(installmentRepositoryProvider).delete(widget.inst.id);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red.shade700),
          );
        }
      }
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600, color: context.colors.onSurfaceFaint)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color,
        fontFeatures: const [FontFeature.tabularFigures()]), overflow: TextOverflow.ellipsis),
    ]));
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: context.colors.surfaceLow);
  }
}

// ─── BRL widgets ─────────────────────────────────────────────────────────────

class _BRLBig extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  const _BRLBig({required this.value, required this.size, this.color});
  @override
  Widget build(BuildContext context) {
    const w = FontWeight.w800;
    final c = color ?? context.colors.onSurface;
    final parts = FinancialCalculatorService.formatBRL(value).split(',');
    final intPart = parts[0].replaceFirst('R\$ ', '');
    final centsPart = parts.length > 1 ? parts[1] : '00';
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
      Text(intPart, style: GoogleFonts.manrope(fontSize: size, fontWeight: w, color: c, letterSpacing: -size * 0.028)),
      Text(',$centsPart', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: w, color: c.withOpacity(0.85))),
    ]);
  }
}

class _BRLSmall extends StatelessWidget {
  final double value;
  final double size;
  final FontWeight weight;
  const _BRLSmall({required this.value, required this.size, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    return Text(
      FinancialCalculatorService.formatBRL(value),
      style: GoogleFonts.inter(
        fontSize: size, fontWeight: weight,
        color: context.colors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
