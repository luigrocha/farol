import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/services/clt_calculator_service.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/widgets/farol_snackbar.dart';
import '../../design/farol_colors.dart' as tokens;

const _kGreen = tokens.FarolColors.beam;

class SalarySettingsSheet extends ConsumerStatefulWidget {
  const SalarySettingsSheet({super.key});

  @override
  ConsumerState<SalarySettingsSheet> createState() =>
      _SalarySettingsSheetState();
}

class _SalarySettingsSheetState extends ConsumerState<SalarySettingsSheet> {
  final _grossCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  int _dependents = 0;
  bool _useSimplified = false;
  bool _saving = false;
  bool _prefilled = false;
  CltResult? _preview;

  @override
  void dispose() {
    _grossCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  double _parse(String t) =>
      double.tryParse(t.trim().replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  void _recompute() {
    final gross = _parse(_grossCtrl.text);
    if (gross <= 0) {
      setState(() => _preview = null);
      return;
    }
    setState(() => _preview = CltCalculatorService.compute(
          grossSalary: gross,
          dependents: _dependents,
          otherDeductions: _parse(_otherCtrl.text),
          useSimplifiedDeduction: _useSimplified,
        ));
  }

  Future<void> _save() async {
    final gross = _parse(_grossCtrl.text);
    if (gross <= 0) {
      context.showSuccessSnackBar(AppLocalizations.of(context).translate('enter_gross_salary'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(salarySettingsProvider.notifier).save(
            grossSalary: gross,
            dependents: _dependents,
            otherDeductions: _parse(_otherCtrl.text),
            useSimplifiedDeduction: _useSimplified,
          );
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(AppLocalizations.of(context).translate('salary_saved'));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill once from persisted settings
    if (!_prefilled) {
      final saved = ref.read(salarySettingsProvider).value;
      if (saved != null) {
        if (saved.grossSalary > 0) {
          _grossCtrl.text =
              saved.grossSalary.toStringAsFixed(2).replaceAll('.', ',');
        }
        if (saved.otherDeductions > 0) {
          _otherCtrl.text =
              saved.otherDeductions.toStringAsFixed(2).replaceAll('.', ',');
        }
        _dependents = saved.dependents;
        _useSimplified = saved.useSimplifiedDeduction;
      }
      _prefilled = true;
      Future.microtask(_recompute);
    }

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: colors.surfaceLow,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_outlined,
                      size: 20, color: _kGreen),
                ),
                const SizedBox(width: 12),
                Text('Salário CLT 2026',
                    style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),

              // ── Gross salary ──────────────────────────────────────────────
              TextField(
                controller: _grossCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
                onChanged: (_) => _recompute(),
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Salário bruto mensal',
                  prefixText: 'R\$ ',
                  prefixStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceMuted),
                  hintText: '13.287,90',
                  filled: true,
                  fillColor: colors.surfaceLow,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // ── Dependents ────────────────────────────────────────────────
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Dependentes',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface)),
                      Text(
                          'Dedução: ${FinancialCalculatorService.formatBRL(189.59 * _dependents)} / mês',
                          style: TextStyle(
                              fontSize: 11, color: colors.onSurfaceSoft)),
                    ]),
                    _Counter(
                      value: _dependents,
                      min: 0,
                      max: 10,
                      onChanged: (v) {
                        setState(() => _dependents = v);
                        _recompute();
                      },
                    ),
                  ]),
              const SizedBox(height: 16),

              // ── Simplified deduction ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                    color: colors.surfaceLow,
                    borderRadius: BorderRadius.circular(14)),
                child: SwitchListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  title: Text('Desconto simplificado',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface)),
                  subtitle: Text('R\$ 607,20 deduzidos da base do IRRF',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceSoft)),
                  value: _useSimplified,
                  activeThumbColor: _kGreen,
                  onChanged: (v) {
                    setState(() => _useSimplified = v);
                    _recompute();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Other deductions ──────────────────────────────────────────
              TextField(
                controller: _otherCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
                onChanged: (_) => _recompute(),
                decoration: InputDecoration(
                  labelText: 'Outras deduções (plano de saúde, etc.)',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  filled: true,
                  fillColor: colors.surfaceLow,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              // ── Live preview ──────────────────────────────────────────────
              if (_preview != null) ...[
                _PreviewCard(result: _preview!),
                const SizedBox(height: 16),
              ],

              // ── Save button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.save.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
      ),
    );
  }
}

// ─── Preview card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final CltResult result;
  const _PreviewCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A7A4A), Color(0xFF145E38)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _kGreen.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Text('SALÁRIO LÍQUIDO',
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${result.effectiveRate.toStringAsFixed(1)}% alíquota efetiva',
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          FinancialCalculatorService.formatBRL(result.netSalary),
          style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 14),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _Stat(label: 'INSS', value: result.inss, color: Colors.white70),
          _Stat(label: 'IRRF', value: result.irrf, color: const Color(0xFFFFB3B3)),
          _Stat(label: 'FGTS*', value: result.fgts, color: const Color(0xFFB3E5FC)),
        ]),
        if (result.reducaoMensal > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Reducão mensal aplicada: −${FinancialCalculatorService.formatBRL(result.reducaoMensal)}',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        const Text('* FGTS é encargo do empregador, não descontado do salário.',
            style: TextStyle(fontSize: 9, color: Colors.white54)),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(
          FinancialCalculatorService.formatBRL(value),
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ]),
    );
  }
}

// ─── Counter widget ───────────────────────────────────────────────────────────

class _Counter extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const _Counter(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(children: [
      _Btn(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1)),
      Container(
        width: 36,
        alignment: Alignment.center,
        child: Text('$value',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface)),
      ),
      _Btn(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1)),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: enabled
                ? _kGreen.withValues(alpha: 0.1)
                : context.colors.surfaceLow,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon,
            size: 16,
            color: enabled ? _kGreen : context.colors.onSurfaceFaint),
      ),
    );
  }
}
