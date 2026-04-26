import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';

const _kTeal = Color(0xFF006D5B);
const _kTealLight = Color(0xFF007A67);
const _kMonths = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

class FgtsAniversarioScreen extends ConsumerStatefulWidget {
  const FgtsAniversarioScreen({super.key});

  @override
  ConsumerState<FgtsAniversarioScreen> createState() =>
      _FgtsAniversarioState();
}

class _FgtsAniversarioState extends ConsumerState<FgtsAniversarioScreen> {
  final _balanceCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  int _birthMonth = DateTime.now().month;
  _FgtsCalc? _result;
  bool _prefilled = false;

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  double? _parse(String t) =>
      double.tryParse(t.trim().replaceAll('.', '').replaceAll(',', '.'));

  void _calculate() {
    final balance = _parse(_balanceCtrl.text);
    final salary = _parse(_salaryCtrl.text);
    if (balance == null || balance < 0 || salary == null || salary <= 0) return;
    setState(() => _result = _FgtsCalc.compute(
          currentBalance: balance,
          grossSalary: salary,
          birthMonth: _birthMonth,
        ));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefilled) {
      final snap = ref.watch(netWorthSnapshotProvider).value;
      if (snap != null && snap.fgtsBalance > 0 && _balanceCtrl.text.isEmpty) {
        _balanceCtrl.text =
            snap.fgtsBalance.toStringAsFixed(2).replaceAll('.', ',');
      }
      _prefilled = true;
    }

    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surfaceLow,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saque Aniversário FGTS',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.surfaceLow,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InputCard(
              balanceCtrl: _balanceCtrl,
              salaryCtrl: _salaryCtrl,
              birthMonth: _birthMonth,
              onBirthMonthChanged: (v) =>
                  setState(() { _birthMonth = v; _result = null; }),
              onChanged: () => setState(() => _result = null),
              onCalculate: _calculate,
            ),
            const SizedBox(height: 16),
            if (_result != null) ...[
              _ResultCard(calc: _result!),
              const SizedBox(height: 16),
              _BracketCard(calc: _result!),
              const SizedBox(height: 16),
              _ProjectionCard(calc: _result!),
              const SizedBox(height: 16),
              _TradeoffCard(calc: _result!),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Input Card ──────────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final TextEditingController balanceCtrl, salaryCtrl;
  final int birthMonth;
  final ValueChanged<int> onBirthMonthChanged;
  final VoidCallback onChanged, onCalculate;

  const _InputCard({
    required this.balanceCtrl,
    required this.salaryCtrl,
    required this.birthMonth,
    required this.onBirthMonthChanged,
    required this.onChanged,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DADOS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: colors.onSurfaceFaint)),
        const SizedBox(height: 16),
        TextField(
          controller: balanceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
          ],
          onChanged: (_) => onChanged(),
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface),
          decoration: InputDecoration(
            labelText: 'Saldo FGTS atual (R\$)',
            labelStyle:
                TextStyle(fontSize: 13, color: colors.onSurfaceSoft),
            prefixText: 'R\$ ',
            prefixStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceMuted),
            filled: true,
            fillColor: colors.surfaceLow,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: salaryCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
          ],
          onChanged: (_) => onChanged(),
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface),
          decoration: InputDecoration(
            labelText: 'Salário bruto mensal (R\$)',
            labelStyle:
                TextStyle(fontSize: 13, color: colors.onSurfaceSoft),
            prefixText: 'R\$ ',
            prefixStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceMuted),
            filled: true,
            fillColor: colors.surfaceLow,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        Text('Mês de aniversário',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface)),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, __) => const SizedBox(width: 5),
            itemBuilder: (context, i) {
              final m = i + 1;
              final selected = m == birthMonth;
              return GestureDetector(
                onTap: () => onBirthMonthChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _kTeal : colors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _kMonths[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : colors.onSurfaceSoft,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCalculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Calcular',
                style: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ─── Result Card (gradient hero) ─────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _FgtsCalc calc;
  const _ResultCard({required this.calc});

  @override
  Widget build(BuildContext context) {
    final monthLabel = _kMonths[calc.birthMonth - 1];
    final monthsText = calc.monthsUntilBirthday == 0
        ? 'este mês!'
        : 'em ${calc.monthsUntilBirthday} '
            '${calc.monthsUntilBirthday == 1 ? 'mês' : 'meses'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kTealLight, _kTeal],
        ),
        boxShadow: [
          BoxShadow(
              color: _kTeal.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SAQUE ANIVERSÁRIO · $monthLabel',
              style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2),
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(monthsText,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('VOCÊ PODE SACAR',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: Colors.white70)),
        const SizedBox(height: 4),
        _BigBRL(value: calc.withdrawalAmount, size: 36),
        const SizedBox(height: 20),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _MiniStat(
                  label: 'SALDO PROJETADO',
                  value: calc.projectedBalance)),
          Expanded(
              child: _MiniStat(
                  label: 'SALDO APÓS SAQUE',
                  value: calc.balanceAfterWithdrawal)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _MiniStat(
                  label: 'ALÍQUOTA',
                  text:
                      '${(calc.withdrawalRate * 100).toStringAsFixed(0)}%')),
          Expanded(
              child: _MiniStat(
                  label: 'PARCELA ADICIONAL',
                  value: calc.withdrawalBonus > 0
                      ? calc.withdrawalBonus
                      : null,
                  text: calc.withdrawalBonus > 0 ? null : '—')),
        ]),
      ]),
    );
  }
}

// ─── Bracket Table Card ───────────────────────────────────────────────────────

class _BracketCard extends StatelessWidget {
  final _FgtsCalc calc;
  const _BracketCard({required this.calc});

  static const _rows = [
    (label: 'Até R\$ 500', rate: '50%', bonus: '—'),
    (label: 'R\$ 500 – 1.000', rate: '40%', bonus: '+R\$50'),
    (label: 'R\$ 1.000 – 5.000', rate: '30%', bonus: '+R\$80'),
    (label: 'R\$ 5.000 – 10.000', rate: '20%', bonus: '+R\$100'),
    (label: 'R\$ 10.000 – 15.000', rate: '15%', bonus: '+R\$100'),
    (label: 'R\$ 15.000 – 20.000', rate: '10%', bonus: '+R\$100'),
    (label: 'Acima de R\$ 20.000', rate: '5%', bonus: '+R\$100'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TABELA DE ALÍQUOTAS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: colors.onSurfaceFaint)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              flex: 5,
              child: Text('Faixa de saldo',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft))),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text('Alíquota',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceSoft)))),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text('Adicional',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceSoft)))),
        ]),
        const SizedBox(height: 8),
        ..._rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isActive = i == calc.bracketIndex;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? _kTeal.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: _kTeal.withOpacity(0.3))
                  : null,
            ),
            child: Row(children: [
              Expanded(
                  flex: 5,
                  child: Row(children: [
                    if (isActive) ...[
                      const Icon(Icons.arrow_right,
                          size: 14, color: _kTeal),
                      const SizedBox(width: 2),
                    ] else
                      const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive ? _kTeal : colors.onSurface,
                        ),
                      ),
                    ),
                  ])),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(row.rate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive ? _kTeal : colors.onSurface,
                          )))),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(row.bonus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? _kTeal
                                : colors.onSurfaceSoft,
                          )))),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Projection Card ──────────────────────────────────────────────────────────

class _ProjectionCard extends StatelessWidget {
  final _FgtsCalc calc;
  const _ProjectionCard({required this.calc});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PROJEÇÃO 3 ANOS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: colors.onSurfaceFaint)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              flex: 2,
              child: Text('Ano',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Saldo',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceSoft)))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Saque',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceSoft)))),
          Expanded(
              flex: 3,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Após saque',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceSoft)))),
        ]),
        const SizedBox(height: 8),
        ...calc.projections.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isFirst = i == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isFirst
                  ? _kTeal.withOpacity(0.07)
                  : colors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: isFirst
                  ? Border.all(color: _kTeal.withOpacity(0.2))
                  : null,
            ),
            child: Row(children: [
              Expanded(
                  flex: 2,
                  child: Text('${p.year}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isFirst ? _kTeal : colors.onSurface,
                      ))),
              Expanded(
                  flex: 3,
                  child: Center(
                      child: Text(
                          FinancialCalculatorService.formatBRL(p.balance),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceSoft,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          )))),
              Expanded(
                  flex: 3,
                  child: Center(
                      child: Text(
                          FinancialCalculatorService.formatBRL(
                              p.withdrawal),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isFirst ? _kTeal : colors.onSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          )))),
              Expanded(
                  flex: 3,
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          FinancialCalculatorService.formatBRL(
                              p.afterBalance),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceSoft,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          )))),
            ]),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kTeal.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.savings_outlined, size: 14, color: _kTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Total sacado em 3 anos: ${FinancialCalculatorService.formatBRL(calc.projections.fold(0.0, (s, p) => s + p.withdrawal))}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTeal),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Tradeoff Card ────────────────────────────────────────────────────────────

class _TradeoffCard extends StatelessWidget {
  final _FgtsCalc calc;
  const _TradeoffCard({required this.calc});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300.withOpacity(0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text('ATENÇÃO: TROCA-OFF',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Colors.orange.shade700)),
        ]),
        const SizedBox(height: 14),
        const _TradeoffRow(
          icon: Icons.check_circle_outline,
          iconColor: _kTeal,
          title: 'Saque Aniversário (modalidade)',
          subtitle:
              'Saca anualmente no mês do aniversário. Mantém vínculo com FGTS ao longo do emprego.',
          detail:
              'Limitação: se demitido sem justa causa, você NÃO pode sacar o saldo do FGTS — apenas recebe a multa de 40% paga pelo empregador.',
        ),
        const SizedBox(height: 12),
        _TradeoffRow(
          icon: Icons.account_balance_outlined,
          iconColor: Colors.blue.shade700,
          title: 'Saque por Rescisão (padrão)',
          subtitle:
              'Sem saques anuais. Ao ser demitido sem justa causa, saca o saldo completo + multa de 40%.',
          detail:
              'Saldo em risco se optar pelo Aniversário: ${FinancialCalculatorService.formatBRL(calc.projectedBalance)}',
        ),
        const SizedBox(height: 14),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'A modalidade Saque Aniversário vale mais se você tem estabilidade no emprego. '
                'Opte pelo padrão se há risco de demissão.',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceSoft,
                    height: 1.5),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TradeoffRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, detail;
  const _TradeoffRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceSoft, height: 1.4)),
          const SizedBox(height: 4),
          Text(detail,
              style: TextStyle(
                  fontSize: 11,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
        ]),
      ),
    ]);
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _BigBRL extends StatelessWidget {
  final double value;
  final double size;
  const _BigBRL({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    final formatted = FinancialCalculatorService.formatBRL(value);
    return Text(
      formatted,
      style: GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double? value;
  final String? text;
  const _MiniStat({required this.label, this.value, this.text});

  @override
  Widget build(BuildContext context) {
    final display = text ?? FinancialCalculatorService.formatBRL(value ?? 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white70)),
      const SizedBox(height: 2),
      Text(display,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

// ─── Calculation Logic ────────────────────────────────────────────────────────

class _YearProjection {
  final int year;
  final double balance;
  final double withdrawal;
  final double afterBalance;
  const _YearProjection({
    required this.year,
    required this.balance,
    required this.withdrawal,
    required this.afterBalance,
  });
}

class _FgtsCalc {
  final double currentBalance;
  final double grossSalary;
  final int birthMonth;
  final int monthsUntilBirthday;
  final double projectedBalance;
  final double withdrawalAmount;
  final double withdrawalRate;
  final double withdrawalBonus;
  final double balanceAfterWithdrawal;
  final int bracketIndex;
  final List<_YearProjection> projections;

  const _FgtsCalc({
    required this.currentBalance,
    required this.grossSalary,
    required this.birthMonth,
    required this.monthsUntilBirthday,
    required this.projectedBalance,
    required this.withdrawalAmount,
    required this.withdrawalRate,
    required this.withdrawalBonus,
    required this.balanceAfterWithdrawal,
    required this.bracketIndex,
    required this.projections,
  });

  factory _FgtsCalc.compute({
    required double currentBalance,
    required double grossSalary,
    required int birthMonth,
  }) {
    final now = DateTime.now();
    final months0 = (birthMonth - now.month + 12) % 12;
    final monthly = grossSalary * 0.08;

    double grow(double bal, int mo) => bal + monthly * mo;

    final bal1 = grow(currentBalance, months0);
    final br1 = _bracketOf(bal1);
    final w1 = bal1 * br1.rate + br1.bonus;
    final after1 = bal1 - w1;

    final bal2 = grow(after1, 12);
    final br2 = _bracketOf(bal2);
    final w2 = bal2 * br2.rate + br2.bonus;
    final after2 = bal2 - w2;

    final bal3 = grow(after2, 12);
    final br3 = _bracketOf(bal3);
    final w3 = bal3 * br3.rate + br3.bonus;

    return _FgtsCalc(
      currentBalance: currentBalance,
      grossSalary: grossSalary,
      birthMonth: birthMonth,
      monthsUntilBirthday: months0,
      projectedBalance: bal1,
      withdrawalAmount: w1,
      withdrawalRate: br1.rate,
      withdrawalBonus: br1.bonus,
      balanceAfterWithdrawal: after1,
      bracketIndex: br1.idx,
      projections: [
        _YearProjection(
            year: now.year, balance: bal1, withdrawal: w1, afterBalance: after1),
        _YearProjection(
            year: now.year + 1,
            balance: bal2,
            withdrawal: w2,
            afterBalance: after2),
        _YearProjection(
            year: now.year + 2,
            balance: bal3,
            withdrawal: w3,
            afterBalance: bal3 - w3),
      ],
    );
  }

  static ({double rate, double bonus, int idx}) _bracketOf(double balance) {
    if (balance <= 500) return (rate: 0.50, bonus: 0.0, idx: 0);
    if (balance <= 1000) return (rate: 0.40, bonus: 50.0, idx: 1);
    if (balance <= 5000) return (rate: 0.30, bonus: 80.0, idx: 2);
    if (balance <= 10000) return (rate: 0.20, bonus: 100.0, idx: 3);
    if (balance <= 15000) return (rate: 0.15, bonus: 100.0, idx: 4);
    if (balance <= 20000) return (rate: 0.10, bonus: 100.0, idx: 5);
    return (rate: 0.05, bonus: 100.0, idx: 6);
  }
}
