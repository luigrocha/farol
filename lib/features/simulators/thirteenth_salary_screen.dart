import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/services/financial_calculator_service.dart';

class ThirteenthSalaryScreen extends StatefulWidget {
  const ThirteenthSalaryScreen({super.key});

  @override
  State<ThirteenthSalaryScreen> createState() => _ThirteenthSalaryScreenState();
}

class _ThirteenthSalaryScreenState extends State<ThirteenthSalaryScreen> {
  final _salaryCtrl = TextEditingController();
  int _months = 12;
  int _dependents = 0;
  _Calc? _result;

  @override
  void dispose() {
    _salaryCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final gross = double.tryParse(_salaryCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    if (gross == null || gross <= 0) return;
    setState(() => _result = _Calc.compute(gross: gross, months: _months, dependents: _dependents));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surfaceLow,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Simulador 13º Salário', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
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
              months: _months,
              dependents: _dependents,
              onMonthsChanged: (v) => setState(() { _months = v; _result = null; }),
              onDependentsChanged: (v) => setState(() { _dependents = v; _result = null; }),
              onSalaryChanged: (_) => setState(() => _result = null),
              onCalculate: _calculate,
            ),
            const SizedBox(height: 16),
            if (_result != null) ...[
              _SummaryCard(calc: _result!),
              const SizedBox(height: 16),
              _InstallmentsCard(calc: _result!),
              const SizedBox(height: 16),
              _DeductionsCard(calc: _result!),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Input ─────────────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final TextEditingController salaryCtrl;
  final int months, dependents;
  final ValueChanged<int> onMonthsChanged, onDependentsChanged;
  final ValueChanged<String> onSalaryChanged;
  final VoidCallback onCalculate;

  const _InputCard({
    required this.salaryCtrl,
    required this.months,
    required this.dependents,
    required this.onMonthsChanged,
    required this.onDependentsChanged,
    required this.onSalaryChanged,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DATOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: colors.onSurfaceFaint)),
        const SizedBox(height: 16),
        TextField(
          controller: salaryCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
          onChanged: onSalaryChanged,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: colors.onSurface),
          decoration: InputDecoration(
            labelText: 'Salário Bruto Mensal (R\$)',
            labelStyle: TextStyle(fontSize: 13, color: colors.onSurfaceSoft),
            prefixText: 'R\$ ',
            prefixStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurfaceMuted),
            filled: true,
            fillColor: colors.surfaceLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Meses trabalhados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
          _Counter(
            value: months, min: 1, max: 12,
            label: '$months/${12}',
            onChanged: onMonthsChanged,
          ),
        ]),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: colors.surfaceLow,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.12),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: months.toDouble(),
            min: 1, max: 12, divisions: 11,
            onChanged: (v) => onMonthsChanged(v.round()),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dependentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
            Text('Redução IRRF: ${FinancialCalculatorService.formatBRL(_kDepDeduction * dependents)}', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
          ]),
          _Counter(value: dependents, min: 0, max: 10, label: '$dependents', onChanged: onDependentsChanged),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCalculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
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

class _Counter extends StatelessWidget {
  final int value, min, max;
  final String label;
  final ValueChanged<int> onChanged;
  const _Counter({required this.value, required this.min, required this.max, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(children: [
      _IconBtn(icon: Icons.remove, onTap: value > min ? () => onChanged(value - 1) : null),
      Container(
        width: 44,
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface)),
      ),
      _IconBtn(icon: Icons.add, onTap: value < max ? () => onChanged(value + 1) : null),
    ]);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: onTap != null ? colors.onSurface : colors.onSurfaceFaint),
      ),
    );
  }
}

// ─── Summary ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final _Calc calc;
  const _SummaryCard({required this.calc});

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
          colors: [AppTheme.primaryContainer, AppTheme.primaryColor],
        ),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('13º SALÁRIO', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2)),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('TOTAL LÍQUIDO', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 4),
        _BigBRL(value: calc.totalNet, size: 36, color: Colors.white),
        const SizedBox(height: 20),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MiniStat(label: '13º BRUTO', value: calc.proportional13th, color: Colors.white)),
          Expanded(child: _MiniStat(label: 'DESCUENTOS', value: calc.totalDeductions, color: const Color(0xFFFFB3B3))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniStat(label: '1ª PARCELA', value: calc.firstInstallment, color: Colors.white)),
          Expanded(child: _MiniStat(label: '2ª PARCELA', value: calc.secondInstallment, color: Colors.white)),
        ]),
      ]),
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
      Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: color.withOpacity(0.7))),
      const SizedBox(height: 2),
      Text(FinancialCalculatorService.formatBRL(value), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFeatures: [FontFeature.tabularFigures()])),
    ]);
  }
}

// ─── Installments ──────────────────────────────────────────────────────────

class _InstallmentsCard extends StatelessWidget {
  final _Calc calc;
  const _InstallmentsCard({required this.calc});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PARCELAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: colors.onSurfaceFaint)),
        const SizedBox(height: 16),
        _InstallmentRow(
          number: '1ª',
          label: 'Adiantamento',
          sublabel: 'Fev–Nov • sem descontos',
          value: calc.firstInstallment,
          color: AppTheme.tertiaryColor,
          isGross: true,
        ),
        const SizedBox(height: 12),
        _InstallmentRow(
          number: '2ª',
          label: 'Saldo final',
          sublabel: 'Até 20/Dez • INSS + IRRF',
          value: calc.secondInstallment,
          color: AppTheme.primaryColor,
          isGross: false,
        ),
      ]),
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  final String number, label, sublabel;
  final double value;
  final Color color;
  final bool isGross;
  const _InstallmentRow({required this.number, required this.label, required this.sublabel, required this.value, required this.color, required this.isGross});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(number, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
          Text(sublabel, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(FinancialCalculatorService.formatBRL(value), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface, fontFeatures: [FontFeature.tabularFigures()])),
          if (isGross)
            Text('sem IR/INSS', style: TextStyle(fontSize: 10, color: AppTheme.tertiaryColor, fontWeight: FontWeight.w600))
          else
            Text('líquido', style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─── Deductions ────────────────────────────────────────────────────────────

class _DeductionsCard extends StatelessWidget {
  final _Calc calc;
  const _DeductionsCard({required this.calc});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DESCONTOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: colors.onSurfaceFaint)),
        const SizedBox(height: 16),

        // INSS
        _DeductionGroup(
          icon: Icons.security_outlined,
          title: 'INSS',
          total: calc.inss,
          color: AppTheme.secondaryColor,
          rows: calc.inssRows,
        ),
        const SizedBox(height: 12),

        // IRRF
        _DeductionGroup(
          icon: Icons.receipt_outlined,
          title: 'IRRF',
          total: calc.irrf,
          color: AppTheme.errorColor,
          rows: calc.irrfRows,
        ),

        if (calc.dependentDeduction > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.family_restroom_outlined, size: 18, color: colors.onSurfaceSoft),
              const SizedBox(width: 10),
              Expanded(child: Text('Dedução dependentes', style: TextStyle(fontSize: 13, color: colors.onSurface))),
              Text('−${FinancialCalculatorService.formatBRL(calc.dependentDeduction)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurfaceSoft, fontFeatures: [FontFeature.tabularFigures()])),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        Container(height: 1, color: colors.surfaceLow),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total descontado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface)),
          Text('−${FinancialCalculatorService.formatBRL(calc.totalDeductions)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.errorColor, fontFeatures: [FontFeature.tabularFigures()])),
        ]),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: Text('${calc.effectiveRate.toStringAsFixed(1)}% alíquota efetiva', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft))),
      ]),
    );
  }
}

class _DeductionGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final double total;
  final Color color;
  final List<_Row> rows;
  const _DeductionGroup({required this.icon, required this.title, required this.total, required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface))),
            Text(FinancialCalculatorService.formatBRL(total), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFeatures: [FontFeature.tabularFigures()])),
          ]),
        ),
        if (rows.isNotEmpty) ...[
          Divider(height: 1, color: colors.surfaceLowest),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: color.withOpacity(0.4), shape: BoxShape.circle),
              ),
              Expanded(child: Text(r.label, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft))),
              Text(r.value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurfaceMuted, fontFeatures: [FontFeature.tabularFigures()])),
            ]),
          )),
          const SizedBox(height: 4),
        ],
      ]),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

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
        Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.44, fontWeight: FontWeight.w500, color: c.withOpacity(0.8))),
        Text(integer.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, color: c, letterSpacing: -size * 0.025)),
        Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.52, fontWeight: FontWeight.w700, color: c.withOpacity(0.8))),
      ],
    );
  }
}

// ─── Calculation logic ─────────────────────────────────────────────────────

const double _kDepDeduction = 189.59;

class _Row {
  final String label, value;
  const _Row(this.label, this.value);
}

class _Calc {
  final double proportional13th;
  final double inss;
  final double irrf;
  final double dependentDeduction;
  final double firstInstallment;
  final double secondInstallment;
  final double totalNet;
  final double totalDeductions;
  final double effectiveRate;
  final List<_Row> inssRows;
  final List<_Row> irrfRows;

  const _Calc({
    required this.proportional13th,
    required this.inss,
    required this.irrf,
    required this.dependentDeduction,
    required this.firstInstallment,
    required this.secondInstallment,
    required this.totalNet,
    required this.totalDeductions,
    required this.effectiveRate,
    required this.inssRows,
    required this.irrfRows,
  });

  factory _Calc.compute({required double gross, required int months, required int dependents}) {
    final base = gross * months / 12;

    // ── INSS 2025 (progressive table) ──
    // Brackets: [limit, rate]
    const inssTable = <(double, double)>[
      (1518.00, 0.075),
      (2793.88, 0.09),
      (4190.83, 0.12),
      (8157.41, 0.14),
    ];
    const inssMax = 951.62;

    double inss = 0;
    double prev = 0;
    final inssRows = <_Row>[];
    for (final (limit, rate) in inssTable) {
      if (base > prev) {
        final taxable = (base < limit ? base : limit) - prev;
        final contrib = taxable * rate;
        inss += contrib;
        if (contrib > 0) {
          inssRows.add(_Row(
            'Até ${FinancialCalculatorService.formatBRL(limit)} (${(rate * 100).toStringAsFixed(1)}%)',
            FinancialCalculatorService.formatBRL(contrib),
          ));
        }
        prev = limit;
      }
    }
    if (inss > inssMax) {
      inssRows.clear();
      inssRows.add(_Row('Teto máximo INSS', FinancialCalculatorService.formatBRL(inssMax)));
      inss = inssMax;
    }

    // ── IRRF 2025 (base = 13th - INSS - dependents) ──
    final depDeduction = dependents * _kDepDeduction;
    final irrfBase = (base - inss - depDeduction).clamp(0.0, double.infinity);

    // Brackets: [limit, rate, deduction]
    const irrfTable = <(double, double, double)>[
      (2259.20, 0.0,   0.0),
      (2826.65, 0.075, 169.44),
      (3751.05, 0.15,  381.44),
      (4664.68, 0.225, 662.77),
      (double.infinity, 0.275, 896.00),
    ];

    double irrf = 0;
    final irrfRows = <_Row>[];
    for (final (limit, rate, ded) in irrfTable) {
      if (irrfBase <= limit) {
        irrf = (irrfBase * rate - ded).clamp(0.0, double.infinity);
        if (irrf > 0) {
          irrfRows.add(_Row(
            'Base ${FinancialCalculatorService.formatBRL(irrfBase)} × ${(rate * 100).toStringAsFixed(1)}%',
            FinancialCalculatorService.formatBRL(irrf),
          ));
        } else {
          irrfRows.add(_Row('Base ${FinancialCalculatorService.formatBRL(irrfBase)}', 'Isento'));
        }
        break;
      }
    }

    final firstInstallment = base / 2;
    final secondInstallment = base / 2 - inss - irrf;
    final totalNet = firstInstallment + secondInstallment;
    final totalDeductions = inss + irrf;
    final effectiveRate = base > 0 ? (totalDeductions / base) * 100 : 0.0;

    return _Calc(
      proportional13th: base,
      inss: inss,
      irrf: irrf,
      dependentDeduction: depDeduction,
      firstInstallment: firstInstallment,
      secondInstallment: secondInstallment,
      totalNet: totalNet,
      totalDeductions: totalDeductions,
      effectiveRate: effectiveRate,
      inssRows: inssRows,
      irrfRows: irrfRows,
    );
  }
}
