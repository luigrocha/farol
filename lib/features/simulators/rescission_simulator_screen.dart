import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;

class RescissionSimulatorScreen extends ConsumerStatefulWidget {
  const RescissionSimulatorScreen({super.key});

  @override
  ConsumerState<RescissionSimulatorScreen> createState() =>
      _RescissionSimulatorScreenState();
}

class _RescissionSimulatorScreenState extends ConsumerState<RescissionSimulatorScreen> {
  final _salaryCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '12');
  final _vacationCtrl = TextEditingController(text: '0.00');
  final _fgtsCtrl = TextEditingController(text: '0.00');
  _RescissionResult? _result;

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _monthsCtrl.dispose();
    _vacationCtrl.dispose();
    _fgtsCtrl.dispose();
    super.dispose();
  }

  double? _parse(String t) =>
      double.tryParse(t.trim().replaceAll('.', '').replaceAll(',', '.'));

  void _calculate() {
    final salary = _parse(_salaryCtrl.text);
    final months = int.tryParse(_monthsCtrl.text);
    final vacation = _parse(_vacationCtrl.text);
    final fgts = _parse(_fgtsCtrl.text);

    if (salary == null || salary <= 0 || months == null || months < 0 || vacation == null || vacation < 0 || fgts == null || fgts < 0) return;

    setState(() {
      _result = _RescissionResult.compute(
        grossSalary: salary,
        monthsWorkedInYear: months,
        unusedVacationPay: vacation,
        fgtsBalance: fgts,
      );
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surfaceLow,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Simulador de Rescisão', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: colors.surfaceLow,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InputCard(
              salaryCtrl: _salaryCtrl,
              monthsCtrl: _monthsCtrl,
              vacationCtrl: _vacationCtrl,
              fgtsCtrl: _fgtsCtrl,
              onCalculate: _calculate,
            ),
            const SizedBox(height: 16),
            if (_result != null) ...[
              _ResultCard(result: _result!),
              const SizedBox(height: 16),
              _DetailsCard(result: _result!),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController salaryCtrl, monthsCtrl, vacationCtrl, fgtsCtrl;
  final VoidCallback onCalculate;

  const _InputCard({
    required this.salaryCtrl,
    required this.monthsCtrl,
    required this.vacationCtrl,
    required this.fgtsCtrl,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DADOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: colors.onSurfaceFaint)),
        const SizedBox(height: 16),
        _TextField(
          label: 'Salário Bruto Mensal (R\$)',
          controller: salaryCtrl,
          colors: colors,
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Meses trabalhados no ano',
          controller: monthsCtrl,
          colors: colors,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Férias Vencidas/Proporcionais (R\$)',
          controller: vacationCtrl,
          colors: colors,
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Saldo FGTS atual (R\$)',
          controller: fgtsCtrl,
          colors: colors,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCalculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.FarolColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Calcular', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FarolColors colors;
  final TextInputType? keyboardType;

  const _TextField({
    required this.label,
    required this.controller,
    required this.colors,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface),
        decoration: InputDecoration(
          prefixText: 'R\$ ',
          prefixStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurfaceMuted),
          filled: true,
          fillColor: colors.surfaceLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  final _RescissionResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244A72), tokens.FarolColors.navy],
        ),
        boxShadow: [BoxShadow(color: tokens.FarolColors.navy.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TOTAL ESTIMADO', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 4),
        _BigBRL(value: result.totalNet, size: 36, color: Colors.white),
        const SizedBox(height: 20),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MiniStat(label: '13º Prop.', value: result.proportional13th, color: Colors.white)),
          Expanded(child: _MiniStat(label: 'Férias', value: result.unusedVacationPay, color: Colors.white)),
          Expanded(child: _MiniStat(label: 'Multa FGTS', value: result.fgtsFine, color: Colors.white)),
        ]),
      ]),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final _RescissionResult result;
  const _DetailsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DETALHAMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: context.colors.onSurfaceFaint)),
        const SizedBox(height: 16),
        _DetailRow(label: '13º Salário Proporcional', value: result.proportional13th),
        _DetailRow(label: 'Férias Proporcionais/Vencidas', value: result.unusedVacationPay),
        _DetailRow(label: 'Multa FGTS (40%)', value: result.fgtsFine, color: tokens.FarolColors.beam),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Líquido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.onSurface)),
            Text(FinancialCalculatorService.formatBRL(result.totalNet), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tokens.FarolColors.navy)),
          ],
        ),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _DetailRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: context.colors.onSurfaceSoft)),
          Text(FinancialCalculatorService.formatBRL(value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? context.colors.onSurface)),
        ],
      ),
    );
  }
}

class _BigBRL extends StatelessWidget {
  final double value, size;
  final Color? color;
  const _BigBRL({required this.value, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurface;
    final formatted = FinancialCalculatorService.formatBRL(value);
    final parts = formatted.split(',');
    final integer = parts[0];
    final cents = parts.length > 1 ? parts[1] : '00';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.44, fontWeight: FontWeight.w500, color: c.withValues(alpha: 0.8))),
        Text(integer.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, color: c, letterSpacing: -size * 0.025)),
        Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.52, fontWeight: FontWeight.w700, color: c.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7))),
      const SizedBox(height: 2),
      Text(FinancialCalculatorService.formatBRL(value), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _RescissionResult {
  final double proportional13th;
  final double unusedVacationPay;
  final double fgtsFine;
  final double totalNet;

  const _RescissionResult({
    required this.proportional13th,
    required this.unusedVacationPay,
    required this.fgtsFine,
    required this.totalNet,
  });

  factory _RescissionResult.compute({
    required double grossSalary,
    required int monthsWorkedInYear,
    required double unusedVacationPay,
    required double fgtsBalance,
  }) {
    final res = FinancialCalculatorService.calculateRescission(
      grossSalary: grossSalary,
      monthsWorkedInYear: monthsWorkedInYear,
      unusedVacationPay: unusedVacationPay,
      fgtsBalance: fgtsBalance,
    );
    return _RescissionResult(
      proportional13th: res.proportional13th,
      unusedVacationPay: res.unusedVacationPay,
      fgtsFine: res.fgtsFine,
      totalNet: res.totalNet,
    );
  }
}
