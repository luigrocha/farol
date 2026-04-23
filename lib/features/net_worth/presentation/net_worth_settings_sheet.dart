import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/farol_colors.dart';

class NetWorthSettingsSheet extends ConsumerStatefulWidget {
  const NetWorthSettingsSheet({super.key});

  @override
  ConsumerState<NetWorthSettingsSheet> createState() => _NetWorthSettingsSheetState();
}

class _NetWorthSettingsSheetState extends ConsumerState<NetWorthSettingsSheet> {
  final _patrimonyCtrl = TextEditingController();
  final _fgtsCtrl = TextEditingController();
  final _investmentsCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final snap = ref.read(netWorthSnapshotProvider).value;
    if (snap != null) {
      if (snap.patrimonyTotal > 0) _patrimonyCtrl.text = snap.patrimonyTotal.toStringAsFixed(2);
      if (snap.fgtsBalance > 0) _fgtsCtrl.text = snap.fgtsBalance.toStringAsFixed(2);
      if (snap.investmentsTotal > 0) _investmentsCtrl.text = snap.investmentsTotal.toStringAsFixed(2);
      if (snap.emergencyFund > 0) _emergencyCtrl.text = snap.emergencyFund.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _patrimonyCtrl.dispose();
    _fgtsCtrl.dispose();
    _investmentsCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController ctrl) =>
      double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final month = ref.read(selectedMonthProvider);
      final year = ref.read(selectedYearProvider);
      await ref.read(netWorthNotifierProvider.notifier).save(
        month: month,
        year: year,
        patrimonyTotal: _parse(_patrimonyCtrl),
        fgtsBalance: _parse(_fgtsCtrl),
        investmentsTotal: _parse(_investmentsCtrl),
        emergencyFund: _parse(_emergencyCtrl),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patrimônio guardado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final inst = ref.watch(installmentsProvider).value ?? [];
    final pending = inst.fold(0.0, (s, i) => s + i.monthlyAmount);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: colors.onSurfaceFaint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: colors.iconTintBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_balance_outlined, size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Patrimônio Neto', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${_monthName(month)} $year', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
              ])),
            ]),
            const SizedBox(height: 16),
            // Live preview total
            StatefulBuilder(builder: (_, setInner) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Text('Total estimado: ', style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
                    Text(
                      FinancialCalculatorService.formatBRL(_parse(_patrimonyCtrl) + _parse(_fgtsCtrl) + _parse(_investmentsCtrl) + _parse(_emergencyCtrl) - pending),
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(children: [
                  _Field(label: '🏠 Patrimônio (Imóveis)', ctrl: _patrimonyCtrl, onChanged: () => setState(() {})),
                  _Field(label: '🏦 FGTS', ctrl: _fgtsCtrl, onChanged: () => setState(() {})),
                  _Field(label: '📈 Inversiones', ctrl: _investmentsCtrl, onChanged: () => setState(() {})),
                  _Field(label: '💰 Fundo de Emergência', ctrl: _emergencyCtrl, onChanged: () => setState(() {})),
                  if (pending > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const Icon(Icons.credit_card_outlined, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'Dívidas (parcelas): -${FinancialCalculatorService.formatBRL(pending)}',
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ]),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return names[month - 1];
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final VoidCallback onChanged;

  const _Field({required this.label, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurface)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: '0,00',
            prefixText: 'R\$ ',
            prefixStyle: TextStyle(color: colors.onSurfaceSoft),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ]),
    );
  }
}
