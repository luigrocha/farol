import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense.dart';
import '../models/income.dart';
import '../models/card_installment.dart';
import '../models/net_worth_snapshot.dart';
import '../models/budget_goal.dart';
import '../../features/budget/domain/budget_settings.dart';
import 'financial_calculator_service.dart';

class PdfReportService {
  PdfReportService._();

  // Farol brand colors
  static const _navy = PdfColor(0.1059, 0.2275, 0.3608);   // #1B3A5C
  static const _amber = PdfColor(0.9608, 0.6510, 0.1373);  // #F5A623
  static const _green = PdfColor(0.1020, 0.4784, 0.2902);  // #1A7A4A
  static const _red = PdfColor(0.9098, 0.2824, 0.3333);    // #E84855
  static const _surface = PdfColor(0.9412, 0.9333, 0.9137); // #F0EEE9
  static const _textDark = PdfColor(0.08, 0.08, 0.08);
  static const _textMuted = PdfColor(0.5, 0.5, 0.5);

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const _categoryLabels = {
    'HOUSING': 'Vivienda',
    'TRANSPORT': 'Transporte',
    'FOOD_GROCERY': 'Alimentación',
    'HEALTH': 'Salud',
    'SUBSCRIPTIONS': 'Suscripciones',
    'LEISURE': 'Ocio',
    'EDUCATION': 'Educación',
    'CARD_INSTALLMENTS': 'Cuotas',
    'OTHER': 'Otros',
  };

  static const _incomeLabels = {
    'NET_SALARY': 'Salario Neto',
    'SWILE_MEAL': 'Swile Comida',
    'SWILE_FOOD': 'Swile Alimentación',
    'BONUS': 'Bono',
    '13TH_SALARY': '13° Salario',
    'OVERTIME': 'Horas Extra',
    'OTHER': 'Otros',
  };

  static Future<Uint8List> generate({
    required int month,
    required int year,
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<CardInstallment> installments,
    required BudgetSettings? budget,
    required NetWorthSnapshot? netWorth,
    required List<BudgetGoal> goals,
  }) async {
    final doc = pw.Document();

    final cashExpenses = expenses
        .where((e) => e.payType == 'Cash')
        .fold(0.0, (s, e) => s + e.amount);
    final swileExpenses = expenses
        .where((e) => e.payType == 'Swile')
        .fold(0.0, (s, e) => s + e.amount);
    final netSalary = (budget != null && budget.netSalary > 0)
        ? budget.netSalary
        : incomes
            .where((i) => i.incomeType == 'NET_SALARY')
            .fold(0.0, (s, i) => s + i.amount);
    final balance = netSalary - cashExpenses;
    final savingsRate = netSalary > 0 ? balance / netSalary * 100 : 0.0;

    final expByCategory = <String, double>{};
    for (final e in expenses.where((e) => e.payType == 'Cash')) {
      expByCategory[e.category] = (expByCategory[e.category] ?? 0) + e.amount;
    }
    final sortedCats = expByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final goalsMap = {for (final g in goals) g.category: g};
    final monthName = _months[month - 1];
    final generatedAt = DateTime.now();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _header(monthName, year),
      footer: (ctx) => _footer(ctx, generatedAt),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        _kpiRow(netSalary, cashExpenses, balance, savingsRate),
        pw.SizedBox(height: 24),
        _sectionTitle('Gastos por Categoría (Efectivo)'),
        pw.SizedBox(height: 8),
        sortedCats.isEmpty
            ? _emptyNote('Sin gastos en efectivo registrados')
            : _categoryTable(sortedCats, netSalary, goalsMap),
        if (swileExpenses > 0) ...[
          pw.SizedBox(height: 6),
          _noteText(
              'Gastos Swile (beneficio, no incluidos arriba): ${FinancialCalculatorService.formatBRL(swileExpenses)}'),
        ],
        pw.SizedBox(height: 24),
        _sectionTitle('Ingresos del Mes'),
        pw.SizedBox(height: 8),
        incomes.isEmpty
            ? _emptyNote('Sin ingresos registrados')
            : _incomesTable(incomes),
        if (installments.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _sectionTitle('Parcelas Activas'),
          pw.SizedBox(height: 8),
          _installmentsTable(installments),
        ],
        if (netWorth != null &&
            (netWorth.fgtsBalance +
                    netWorth.investmentsTotal +
                    netWorth.emergencyFund +
                    netWorth.patrimonyTotal) >
                0) ...[
          pw.SizedBox(height: 24),
          _sectionTitle('Patrimônio Neto'),
          pw.SizedBox(height: 8),
          _netWorthBlock(netWorth),
        ],
      ],
    ));

    return doc.save();
  }

  // ═══════════════════════════════════════════
  // HEADER / FOOTER
  // ═══════════════════════════════════════════

  static pw.Widget _header(String monthName, int year) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FAROL',
                style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 22,
                    color: PdfColors.white,
                    letterSpacing: 3)),
            pw.Text('Resumen Financiero Mensual',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 9,
                    color: PdfColor(1, 1, 1, 0.65))),
          ]),
          pw.Text('$monthName $year',
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 18,
                  color: _amber)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx, DateTime generatedAt) {
    final d = generatedAt;
    final dateStr =
        '${_pad(d.day)}/${_pad(d.month)}/${d.year}  ${_pad(d.hour)}:${_pad(d.minute)}';
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generado por Farol · $dateStr',
              style: pw.TextStyle(
                  font: pw.Font.helvetica(), fontSize: 8, color: _textMuted)),
          pw.Text('Pág. ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(
                  font: pw.Font.helvetica(), fontSize: 8, color: _textMuted)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // KPI CARDS
  // ═══════════════════════════════════════════

  static pw.Widget _kpiRow(
      double netSalary, double cashExpenses, double balance, double savingsRate) {
    return pw.Row(children: [
      _kpiCard('Salario Neto', FinancialCalculatorService.formatBRL(netSalary), _navy),
      pw.SizedBox(width: 8),
      _kpiCard('Gastos Efectivo', FinancialCalculatorService.formatBRL(cashExpenses), _red),
      pw.SizedBox(width: 8),
      _kpiCard('Saldo', FinancialCalculatorService.formatBRL(balance),
          balance >= 0 ? _green : _red),
      pw.SizedBox(width: 8),
      _kpiCard('Tasa Ahorro', '${savingsRate.toStringAsFixed(1)}%',
          savingsRate >= 20 ? _green : savingsRate >= 10 ? _amber : _red),
    ]);
  }

  static pw.Widget _kpiCard(String label, String value, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label.toUpperCase(),
              style: pw.TextStyle(
                  font: pw.Font.helvetica(),
                  fontSize: 7,
                  color: _textMuted,
                  letterSpacing: 0.6)),
          pw.SizedBox(height: 5),
          pw.Text(value,
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(), fontSize: 13, color: accent)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CATEGORY TABLE
  // ═══════════════════════════════════════════

  static pw.Widget _categoryTable(
      List<MapEntry<String, double>> cats, double netSalary, Map<String, BudgetGoal> goals) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow(['Categoría', 'Monto', '% Salario', 'Estado']),
        ...cats.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value.key;
          final amount = entry.value.value;
          final label = _categoryLabels[cat] ?? cat;
          final pctSalary = netSalary > 0 ? amount / netSalary * 100 : 0.0;
          final goal = goals[cat];
          final limit = goal?.targetAmount ?? (netSalary * 0.1);
          final over = amount > limit;
          final nearLimit = !over && limit > 0 && amount / limit >= 0.8;
          final statusText = over ? 'EXCEDIDO' : nearLimit ? 'ALERTA' : 'OK';
          final statusColor = over ? _red : nearLimit ? _amber : _green;
          final rowBg = i.isEven ? PdfColors.white : _surface;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(label, pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textDark)),
              _cell(FinancialCalculatorService.formatBRL(amount),
                  pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _textDark),
                  align: pw.TextAlign.right),
              _cell('${pctSalary.toStringAsFixed(1)}%',
                  pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textMuted),
                  align: pw.TextAlign.right),
              _cell(statusText,
                  pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: statusColor),
                  align: pw.TextAlign.center),
            ],
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // INCOMES TABLE
  // ═══════════════════════════════════════════

  static pw.Widget _incomesTable(List<Income> incomes) {
    final total = incomes.fold(0.0, (s, i) => s + i.amount);
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        _tableHeaderRow(['Tipo', 'Monto', 'Neto']),
        ...incomes.asMap().entries.map((entry) {
          final i = entry.key;
          final inc = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : _surface),
            children: [
              _cell(_incomeLabels[inc.incomeType] ?? inc.incomeType,
                  pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textDark)),
              _cell(FinancialCalculatorService.formatBRL(inc.amount),
                  pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _textDark),
                  align: pw.TextAlign.right),
              _cell(inc.isNet ? 'Sí' : 'No',
                  pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textMuted),
                  align: pw.TextAlign.center),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: [
            _cell('TOTAL',
                pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: PdfColors.white)),
            _cell(FinancialCalculatorService.formatBRL(total),
                pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _amber),
                align: pw.TextAlign.right),
            _cell('', pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.white)),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // INSTALLMENTS TABLE
  // ═══════════════════════════════════════════

  static pw.Widget _installmentsTable(List<CardInstallment> installments) {
    final totalMonthly = installments.fold(0.0, (s, i) => s + i.monthlyAmount);
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow(['Descripción', 'Cuota Mensual', 'Total Restante']),
        ...installments.asMap().entries.map((entry) {
          final i = entry.key;
          final inst = entry.value;
          final remaining =
              inst.monthlyAmount * (inst.numInstallments - inst.currentInstallment + 1);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : _surface),
            children: [
              _cell(
                  '${inst.description} (${inst.currentInstallment}/${inst.numInstallments})',
                  pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textDark)),
              _cell(FinancialCalculatorService.formatBRL(inst.monthlyAmount),
                  pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _textDark),
                  align: pw.TextAlign.right),
              _cell(FinancialCalculatorService.formatBRL(remaining),
                  pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textMuted),
                  align: pw.TextAlign.right),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: [
            _cell('TOTAL MENSUAL',
                pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: PdfColors.white)),
            _cell(FinancialCalculatorService.formatBRL(totalMonthly),
                pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _amber),
                align: pw.TextAlign.right),
            _cell('', pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.white)),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // NET WORTH BLOCK
  // ═══════════════════════════════════════════

  static pw.Widget _netWorthBlock(NetWorthSnapshot snap) {
    final nw = FinancialCalculatorService.calculateNetWorth(
      patrimonyTotal: snap.patrimonyTotal,
      fgtsBalance: snap.fgtsBalance,
      investmentsTotal: snap.investmentsTotal,
      emergencyFund: snap.emergencyFund,
      pendingInstallments: snap.pendingInstallments,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
          color: _navy,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          _nwStat('FGTS', snap.fgtsBalance),
          _nwStat('Inversiones', snap.investmentsTotal),
          _nwStat('F. Emergencia', snap.emergencyFund),
          _nwStat('Patrimônio', snap.patrimonyTotal),
        ]),
        pw.SizedBox(height: 12),
        pw.Container(height: 0.5, color: PdfColor(1, 1, 1, 0.25)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Patrimônio Neto Total',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 10,
                    color: PdfColor(1, 1, 1, 0.65))),
            pw.Text(FinancialCalculatorService.formatBRL(nw),
                style: pw.TextStyle(
                    font: pw.Font.helveticaBold(), fontSize: 16, color: _amber)),
          ],
        ),
      ]),
    );
  }

  static pw.Widget _nwStat(String label, double value) {
    return pw.Expanded(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 7,
                color: PdfColor(1, 1, 1, 0.55),
                letterSpacing: 0.5)),
        pw.SizedBox(height: 3),
        pw.Text(FinancialCalculatorService.formatBRL(value),
            style: pw.TextStyle(
                font: pw.Font.helveticaBold(), fontSize: 10, color: PdfColors.white)),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════

  static pw.Widget _sectionTitle(String title) {
    return pw.Row(children: [
      pw.Container(width: 3, height: 14, color: _amber),
      pw.SizedBox(width: 8),
      pw.Text(title,
          style: pw.TextStyle(
              font: pw.Font.helveticaBold(), fontSize: 12, color: _textDark)),
    ]);
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _navy),
      children: headers
          .map((h) => _cell(h,
              pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 9,
                  color: PdfColors.white)))
          .toList(),
    );
  }

  static pw.Widget _cell(String text, pw.TextStyle style,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  static pw.Widget _emptyNote(String msg) {
    return pw.Text(msg,
        style: pw.TextStyle(
            font: pw.Font.helveticaOblique(), fontSize: 10, color: _textMuted));
  }

  static pw.Widget _noteText(String msg) {
    return pw.Text(msg,
        style: pw.TextStyle(
            font: pw.Font.helveticaOblique(), fontSize: 8, color: _textMuted));
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
