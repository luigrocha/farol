import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense.dart';
import '../models/income.dart';
import '../domain/entities/installment_plan.dart';
import '../domain/entities/financial_insight.dart';
import '../models/net_worth_snapshot.dart';
import '../models/budget_goal.dart';
import '../models/enums.dart';
import '../i18n/app_localizations.dart';
import '../../features/budget/domain/budget_settings.dart';
import 'financial_calculator_service.dart';

// ── PDF-only string bundle (no BuildContext required) ─────────────────────────

class _L {
  final String monthlyReport;
  final String netSalary;
  final String cashExpenses;
  final String balance;
  final String savingsRate;
  final String expensesByCategory;
  final String swileNote;
  final String monthlyIncome;
  final String activeInstallments;
  final String netWorth;
  final String financialHealth;
  final String insights;
  final String category;
  final String amount;
  final String pctSalary;
  final String status;
  final String type;
  final String net;
  final String description;
  final String monthlyPayment;
  final String totalRemaining;
  final String totalMonthly;
  final String total;
  final String yes;
  final String no;
  final String exceeded;
  final String alert;
  final String ok;
  final String noCashExpenses;
  final String noIncome;
  final String score;
  final String outOf;
  final String healthy;
  final String warning;
  final String critical;
  final String generatedBy;
  final String page;
  final String of;

  const _L({
    required this.monthlyReport,
    required this.netSalary,
    required this.cashExpenses,
    required this.balance,
    required this.savingsRate,
    required this.expensesByCategory,
    required this.swileNote,
    required this.monthlyIncome,
    required this.activeInstallments,
    required this.netWorth,
    required this.financialHealth,
    required this.insights,
    required this.category,
    required this.amount,
    required this.pctSalary,
    required this.status,
    required this.type,
    required this.net,
    required this.description,
    required this.monthlyPayment,
    required this.totalRemaining,
    required this.totalMonthly,
    required this.total,
    required this.yes,
    required this.no,
    required this.exceeded,
    required this.alert,
    required this.ok,
    required this.noCashExpenses,
    required this.noIncome,
    required this.score,
    required this.outOf,
    required this.healthy,
    required this.warning,
    required this.critical,
    required this.generatedBy,
    required this.page,
    required this.of,
  });

  static _L forLocale(String locale) {
    if (locale == 'pt') return _pt;
    return _en;
  }

  static const _pt = _L(
    monthlyReport: 'Resumo Financeiro Mensal',
    netSalary: 'Salário Líquido',
    cashExpenses: 'Gastos em Dinheiro',
    balance: 'Saldo',
    savingsRate: 'Taxa de Poupança',
    expensesByCategory: 'Gastos por Categoria (Dinheiro)',
    swileNote: 'Gastos Swile (benefício, não incluídos acima)',
    monthlyIncome: 'Rendimentos do Mês',
    activeInstallments: 'Parcelamentos Ativos',
    netWorth: 'Patrimônio Líquido',
    financialHealth: 'Saúde Financeira',
    insights: 'Alertas e Oportunidades',
    category: 'Categoria',
    amount: 'Valor',
    pctSalary: '% Salário',
    status: 'Status',
    type: 'Tipo',
    net: 'Líquido',
    description: 'Descrição',
    monthlyPayment: 'Parcela Mensal',
    totalRemaining: 'Total Restante',
    totalMonthly: 'TOTAL MENSAL',
    total: 'TOTAL',
    yes: 'Sim',
    no: 'Não',
    exceeded: 'EXCEDIDO',
    alert: 'ALERTA',
    ok: 'OK',
    noCashExpenses: 'Nenhum gasto em dinheiro registrado',
    noIncome: 'Nenhum rendimento registrado',
    score: 'Pontuação',
    outOf: 'de',
    healthy: 'SAUDÁVEL',
    warning: 'ATENÇÃO',
    critical: 'CRÍTICO',
    generatedBy: 'Gerado por Farol',
    page: 'Pág.',
    of: 'de',
  );

  static const _en = _L(
    monthlyReport: 'Monthly Financial Summary',
    netSalary: 'Net Salary',
    cashExpenses: 'Cash Expenses',
    balance: 'Balance',
    savingsRate: 'Savings Rate',
    expensesByCategory: 'Expenses by Category (Cash)',
    swileNote: 'Swile expenses (benefit, not included above)',
    monthlyIncome: 'Monthly Income',
    activeInstallments: 'Active Installments',
    netWorth: 'Net Worth',
    financialHealth: 'Financial Health',
    insights: 'Alerts & Opportunities',
    category: 'Category',
    amount: 'Amount',
    pctSalary: '% Salary',
    status: 'Status',
    type: 'Type',
    net: 'Net',
    description: 'Description',
    monthlyPayment: 'Monthly Payment',
    totalRemaining: 'Total Remaining',
    totalMonthly: 'MONTHLY TOTAL',
    total: 'TOTAL',
    yes: 'Yes',
    no: 'No',
    exceeded: 'EXCEEDED',
    alert: 'ALERT',
    ok: 'OK',
    noCashExpenses: 'No cash expenses recorded',
    noIncome: 'No income recorded',
    score: 'Score',
    outOf: 'out of',
    healthy: 'HEALTHY',
    warning: 'WARNING',
    critical: 'CRITICAL',
    generatedBy: 'Generated by Farol',
    page: 'Page',
    of: 'of',
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class PdfReportService {
  PdfReportService._();

  // Farol brand colors
  static const _navy = PdfColor(0.1059, 0.2275, 0.3608); // #1B3A5C
  static const _amber = PdfColor(0.9608, 0.6510, 0.1373); // #F5A623
  static const _green = PdfColor(0.1020, 0.4784, 0.2902); // #1A7A4A
  static const _red = PdfColor(0.9098, 0.2824, 0.3333); // #E84855
  static const _orange = PdfColor(0.95, 0.55, 0.10);
  static const _surface = PdfColor(0.9412, 0.9333, 0.9137);
  static const _textDark = PdfColor(0.08, 0.08, 0.08);
  static const _textMuted = PdfColor(0.5, 0.5, 0.5);

  static Future<Uint8List> generate({
    required int month,
    required int year,
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<InstallmentPlan> installments,
    required BudgetSettings? budget,
    required NetWorthSnapshot? netWorth,
    required List<BudgetGoal> goals,
    List<FinancialInsight> insights = const [],
    double healthScore = 0,
    Map<String, String> categoryNames = const {},
    String locale = 'pt',
  }) async {
    final l = _L.forLocale(locale);
    final doc = pw.Document();

    final cashExpenses = expenses
        .where((e) => !e.isProjected && e.payType == 'Cash')
        .fold(0.0, (s, e) => s + e.amount);
    final swileExpenses = expenses
        .where((e) => !e.isProjected && e.payType == 'Swile')
        .fold(0.0, (s, e) => s + e.amount);
    final netSalary = (budget != null && budget.netSalary > 0)
        ? budget.netSalary
        : incomes
            .where((i) => i.incomeType == 'NET_SALARY')
            .fold(0.0, (s, i) => s + i.amount);
    final balance = netSalary - cashExpenses;
    final savingsRate = netSalary > 0 ? balance / netSalary * 100 : 0.0;

    final expByCategory = <String, double>{};
    for (final e
        in expenses.where((e) => !e.isProjected && e.payType == 'Cash')) {
      expByCategory[e.category] = (expByCategory[e.category] ?? 0) + e.amount;
    }
    final sortedCats = expByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final goalsMap = {for (final g in goals) g.category: g};
    final monthName = AppLocalizations.monthsForLocale(locale)[month - 1];
    final generatedAt = DateTime.now();

    // Page 1: KPIs, expenses, income, installments, net worth
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _header(monthName, year, l),
      footer: (ctx) => _footer(ctx, generatedAt, l),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        _kpiRow(netSalary, cashExpenses, balance, savingsRate, l),
        pw.SizedBox(height: 24),
        _sectionTitle(l.expensesByCategory),
        pw.SizedBox(height: 8),
        sortedCats.isEmpty
            ? _emptyNote(l.noCashExpenses)
            : _categoryTable(
                sortedCats, netSalary, goalsMap, locale, categoryNames, l),
        if (swileExpenses > 0) ...[
          pw.SizedBox(height: 6),
          _noteText(
              '${l.swileNote}: ${FinancialCalculatorService.formatBRL(swileExpenses)}'),
        ],
        pw.SizedBox(height: 24),
        _sectionTitle(l.monthlyIncome),
        pw.SizedBox(height: 8),
        incomes.isEmpty
            ? _emptyNote(l.noIncome)
            : _incomesTable(incomes, locale, l),
        if (installments.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _sectionTitle(l.activeInstallments),
          pw.SizedBox(height: 8),
          _installmentsTable(installments, l),
        ],
        if (netWorth != null &&
            (netWorth.fgtsBalance +
                    netWorth.investmentsTotal +
                    netWorth.emergencyFund +
                    netWorth.patrimonyTotal) >
                0) ...[
          pw.SizedBox(height: 24),
          _sectionTitle(l.netWorth),
          pw.SizedBox(height: 8),
          _netWorthBlock(netWorth),
        ],
      ],
    ));

    // Page 2: Health score + insights (only when there's data)
    final topInsights = insights.where((i) => !i.isExpired()).toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final visibleInsights = topInsights.take(6).toList();

    if (healthScore > 0 || visibleInsights.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(monthName, year, l),
        footer: (ctx) => _footer(ctx, generatedAt, l),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _sectionTitle(l.financialHealth),
          pw.SizedBox(height: 12),
          _healthScoreBlock(healthScore, l),
          if (visibleInsights.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _sectionTitle(l.insights),
            pw.SizedBox(height: 12),
            _insightsBlock(visibleInsights),
          ],
        ],
      ));
    }

    return doc.save();
  }

  // ── Header / Footer ──────────────────────────────────────────────────────────

  static pw.Widget _header(String monthName, int year, _L l) {
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
            pw.Text(l.monthlyReport,
                style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 9,
                    color: const PdfColor(1, 1, 1, 0.65))),
          ]),
          pw.Text('$monthName $year',
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(), fontSize: 18, color: _amber)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx, DateTime generatedAt, _L l) {
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
          pw.Text('${l.generatedBy} · $dateStr',
              style: pw.TextStyle(
                  font: pw.Font.helvetica(), fontSize: 8, color: _textMuted)),
          pw.Text('${l.page} ${ctx.pageNumber} ${l.of} ${ctx.pagesCount}',
              style: pw.TextStyle(
                  font: pw.Font.helvetica(), fontSize: 8, color: _textMuted)),
        ],
      ),
    );
  }

  // ── KPI row ──────────────────────────────────────────────────────────────────

  static pw.Widget _kpiRow(double netSalary, double cashExpenses,
      double balance, double savingsRate, _L l) {
    return pw.Row(children: [
      _kpiCard(
          l.netSalary, FinancialCalculatorService.formatBRL(netSalary), _navy),
      pw.SizedBox(width: 8),
      _kpiCard(l.cashExpenses,
          FinancialCalculatorService.formatBRL(cashExpenses), _red),
      pw.SizedBox(width: 8),
      _kpiCard(l.balance, FinancialCalculatorService.formatBRL(balance),
          balance >= 0 ? _green : _red),
      pw.SizedBox(width: 8),
      _kpiCard(
          l.savingsRate,
          '${savingsRate.toStringAsFixed(1)}%',
          savingsRate >= 20
              ? _green
              : savingsRate >= 10
                  ? _amber
                  : _red),
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
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label.toUpperCase(),
                  style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 7,
                      color: _textMuted,
                      letterSpacing: 0.6)),
              pw.SizedBox(height: 5),
              pw.Text(value,
                  style: pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 13,
                      color: accent)),
            ]),
      ),
    );
  }

  // ── Category table ───────────────────────────────────────────────────────────

  static pw.Widget _categoryTable(
      List<MapEntry<String, double>> cats,
      double netSalary,
      Map<String, BudgetGoal> goals,
      String locale,
      Map<String, String> categoryNames,
      _L l) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow([l.category, l.amount, l.pctSalary, l.status]),
        ...cats.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value.key;
          final amount = entry.value.value;
          final label = _catLabel(cat, categoryNames);
          final pctSalary = netSalary > 0 ? amount / netSalary * 100 : 0.0;
          final goal = goals[cat];
          final limit = goal?.targetAmount ?? (netSalary * 0.1);
          final over = amount > limit;
          final nearLimit = !over && limit > 0 && amount / limit >= 0.8;
          final statusText = over
              ? l.exceeded
              : nearLimit
                  ? l.alert
                  : l.ok;
          final statusColor = over
              ? _red
              : nearLimit
                  ? _amber
                  : _green;
          final rowBg = i.isEven ? PdfColors.white : _surface;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(
                  label,
                  pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 9,
                      color: _textDark)),
              _cell(
                  FinancialCalculatorService.formatBRL(amount),
                  pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 9,
                      color: _textDark),
                  align: pw.TextAlign.right),
              _cell(
                  '${pctSalary.toStringAsFixed(1)}%',
                  pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 9,
                      color: _textMuted),
                  align: pw.TextAlign.right),
              _cell(
                  statusText,
                  pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 9,
                      color: statusColor),
                  align: pw.TextAlign.center),
            ],
          );
        }),
      ],
    );
  }

  // ── Incomes table ────────────────────────────────────────────────────────────

  static pw.Widget _incomesTable(List<Income> incomes, String locale, _L l) {
    final total = incomes.fold(0.0, (s, i) => s + i.amount);
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
      },
      children: [
        _tableHeaderRow([l.type, l.amount, l.net]),
        ...incomes.asMap().entries.map((entry) {
          final i = entry.key;
          final inc = entry.value;
          return pw.TableRow(
            decoration:
                pw.BoxDecoration(color: i.isEven ? PdfColors.white : _surface),
            children: [
              _cell(
                  _incomeLabel(inc.incomeType, locale),
                  pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 9,
                      color: _textDark)),
              _cell(
                  FinancialCalculatorService.formatBRL(inc.amount),
                  pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 9,
                      color: _textDark),
                  align: pw.TextAlign.right),
              _cell(
                  inc.isNet ? l.yes : l.no,
                  pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 9,
                      color: _textMuted),
                  align: pw.TextAlign.center),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: [
            _cell(
                l.total,
                pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 9,
                    color: PdfColors.white)),
            _cell(
                FinancialCalculatorService.formatBRL(total),
                pw.TextStyle(
                    font: pw.Font.helveticaBold(), fontSize: 9, color: _amber),
                align: pw.TextAlign.right),
            _cell('', pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9)),
          ],
        ),
      ],
    );
  }

  // ── Installments table ───────────────────────────────────────────────────────

  static pw.Widget _installmentsTable(
      List<InstallmentPlan> installments, _L l) {
    final totalMonthly =
        installments.fold(0.0, (s, i) => s + i.installmentAmount);
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow([l.description, l.monthlyPayment, l.totalRemaining]),
        ...installments.asMap().entries.map((entry) {
          final i = entry.key;
          final inst = entry.value;
          return pw.TableRow(
            decoration:
                pw.BoxDecoration(color: i.isEven ? PdfColors.white : _surface),
            children: [
              _cell(
                  '${inst.description} (${inst.paidCount}/${inst.numInstallments})',
                  pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 9,
                      color: _textDark)),
              _cell(
                  FinancialCalculatorService.formatBRL(inst.installmentAmount),
                  pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 9,
                      color: _textDark),
                  align: pw.TextAlign.right),
              _cell(
                  FinancialCalculatorService.formatBRL(inst.remainingAmount),
                  pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 9,
                      color: _textMuted),
                  align: pw.TextAlign.right),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: [
            _cell(
                l.totalMonthly,
                pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 9,
                    color: PdfColors.white)),
            _cell(
                FinancialCalculatorService.formatBRL(totalMonthly),
                pw.TextStyle(
                    font: pw.Font.helveticaBold(), fontSize: 9, color: _amber),
                align: pw.TextAlign.right),
            _cell('', pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9)),
          ],
        ),
      ],
    );
  }

  // ── Net worth block ──────────────────────────────────────────────────────────

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
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          _nwStat('FGTS', snap.fgtsBalance),
          _nwStat('Investimentos', snap.investmentsTotal),
          _nwStat('F. Emergência', snap.emergencyFund),
          _nwStat('Patrimônio', snap.patrimonyTotal),
        ]),
        pw.SizedBox(height: 12),
        pw.Container(height: 0.5, color: const PdfColor(1, 1, 1, 0.25)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Patrimônio Líquido Total',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 10,
                    color: const PdfColor(1, 1, 1, 0.65))),
            pw.Text(FinancialCalculatorService.formatBRL(nw),
                style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 16,
                    color: _amber)),
          ],
        ),
      ]),
    );
  }

  static pw.Widget _nwStat(String label, double value) {
    return pw.Expanded(
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 7,
                color: const PdfColor(1, 1, 1, 0.55),
                letterSpacing: 0.5)),
        pw.SizedBox(height: 3),
        pw.Text(FinancialCalculatorService.formatBRL(value),
            style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 10,
                color: PdfColors.white)),
      ]),
    );
  }

  // ── Health score block ───────────────────────────────────────────────────────

  static pw.Widget _healthScoreBlock(double score, _L l) {
    // score is 0–10
    final clamped = score.clamp(0.0, 10.0);
    final pct = clamped / 10.0;
    final scoreColor = clamped >= 7
        ? _green
        : clamped >= 4
            ? _amber
            : _red;
    final scoreLabel = clamped >= 7
        ? l.healthy
        : clamped >= 4
            ? l.warning
            : l.critical;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: scoreColor, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // Score headline
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(scoreLabel,
                      style: pw.TextStyle(
                          font: pw.Font.helveticaBold(),
                          fontSize: 18,
                          color: scoreColor)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                      '${l.score}: ${clamped.toStringAsFixed(1)} ${l.outOf} 10',
                      style: pw.TextStyle(
                          font: pw.Font.helvetica(),
                          fontSize: 10,
                          color: _textMuted)),
                ]),
            // Score circle
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: scoreColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(28)),
              ),
              child: pw.Center(
                child: pw.Text(clamped.toStringAsFixed(1),
                    style: pw.TextStyle(
                        font: pw.Font.helveticaBold(),
                        fontSize: 18,
                        color: PdfColors.white)),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        // Progress bar — full-width track with filled portion
        pw.LayoutBuilder(builder: (ctx, constraints) {
          final trackW = constraints?.maxWidth ?? 400.0;
          final fillW = trackW * pct;
          return pw.Stack(children: [
            pw.Container(
              width: trackW,
              height: 10,
              decoration: const pw.BoxDecoration(
                color: _surface,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
            ),
            pw.Container(
              width: fillW,
              height: 10,
              decoration: pw.BoxDecoration(
                color: scoreColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
            ),
          ]);
        }),
        pw.SizedBox(height: 6),
        // Axis labels
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('0',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(), fontSize: 7, color: _textMuted)),
            pw.Text('5',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(), fontSize: 7, color: _textMuted)),
            pw.Text('10',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(), fontSize: 7, color: _textMuted)),
          ],
        ),
      ]),
    );
  }

  // ── Insights block ───────────────────────────────────────────────────────────

  static pw.Widget _insightsBlock(List<FinancialInsight> insights) {
    return pw.Column(
      children: insights.asMap().entries.map((entry) {
        final insight = entry.value;
        final accentColor = _insightColor(insight.priority);
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border:
                pw.Border(left: pw.BorderSide(color: accentColor, width: 3)),
            color: _surface,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 1, right: 6),
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(insight.title,
                          style: pw.TextStyle(
                              font: pw.Font.helveticaBold(),
                              fontSize: 10,
                              color: _textDark)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12),
                  child: pw.Text(insight.body,
                      style: pw.TextStyle(
                          font: pw.Font.helvetica(),
                          fontSize: 9,
                          color: _textMuted)),
                ),
              ]),
        );
      }).toList(),
    );
  }

  static PdfColor _insightColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return _red;
      case InsightPriority.warning:
        return _orange;
      case InsightPriority.achievement:
        return _green;
      case InsightPriority.info:
        return _navy;
    }
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  static String _catLabel(String dbValue, Map<String, String> categoryNames) {
    if (categoryNames.containsKey(dbValue)) return categoryNames[dbValue]!;
    final slug = dbValue.toLowerCase();
    if (categoryNames.containsKey(slug)) return categoryNames[slug]!;
    return dbValue;
  }

  static String _incomeLabel(String dbValue, String locale) {
    try {
      return IncomeType.fromDb(dbValue).labelForLocale(locale);
    } catch (_) {
      return dbValue;
    }
  }

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
          .map((h) => _cell(
              h,
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
