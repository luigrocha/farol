import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/expense_repository.dart';
import '../repositories/income_repository.dart';
import '../repositories/installment_repository.dart';
import '../repositories/investment_repository.dart';
import '../repositories/net_worth_repository.dart';
import '../repositories/budget_goals_repository.dart';

class ExportService {
  final ExpenseRepository expenseRepo;
  final IncomeRepository incomeRepo;
  final InstallmentRepository installmentRepo;
  final InvestmentRepository investmentRepo;
  final NetWorthRepository netWorthRepo;
  final BudgetGoalsRepository budgetGoalsRepo;

  const ExportService({
    required this.expenseRepo,
    required this.incomeRepo,
    required this.installmentRepo,
    required this.investmentRepo,
    required this.netWorthRepo,
    required this.budgetGoalsRepo,
  });

  // ═══════════════════════════════════════════
  // CSV EXPORT
  // ═══════════════════════════════════════════

  Future<void> exportExpensesToCsv(int month, int year) async {
    final expenses = await expenseRepo.getByRange(month, year, month, year);
    final rows = <List<String>>[
      ['Date', 'Month', 'Year', 'Pay Type', 'Category', 'Subcategory', 'Amount', 'Method', 'Installments', 'Fixed', 'Description'],
      ...expenses.map((e) => [
            e.transactionDate.toIso8601String().substring(0, 10),
            e.month.toString(),
            e.year.toString(),
            e.payType,
            e.category,
            e.subcategory ?? '',
            e.amount.toStringAsFixed(2),
            e.paymentMethod,
            e.installments.toString(),
            e.isFixed ? 'Yes' : 'No',
            e.storeDescription ?? '',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenses_${month}_$year.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'Expenses $month/$year');
  }

  Future<void> exportIncomesToCsv(int month, int year) async {
    final incomes = await incomeRepo.getByRange(month, year, month, year);
    final rows = <List<String>>[
      ['Month', 'Year', 'Type', 'Amount', 'Net', 'INSS', 'IRRF', 'Notes'],
      ...incomes.map((i) => [
            i.month.toString(),
            i.year.toString(),
            i.incomeType,
            i.amount.toStringAsFixed(2),
            i.isNet ? 'Yes' : 'No',
            i.inssDeducted?.toStringAsFixed(2) ?? '',
            i.irrfDeducted?.toStringAsFixed(2) ?? '',
            i.notes ?? '',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/income_${month}_$year.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'Income $month/$year');
  }

  // ═══════════════════════════════════════════
  // JSON BACKUP
  // ═══════════════════════════════════════════

  Future<void> exportBackup() async {
    final allExpenses = await expenseRepo.getAll();
    final allIncomes = await incomeRepo.getAll();

    final backup = {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'expenses': allExpenses.map((e) => {
            'transaction_date': e.transactionDate.toIso8601String().substring(0, 10),
            'month': e.month,
            'year': e.year,
            'payType': e.payType,
            'category': e.category,
            'subcategory': e.subcategory,
            'amount': e.amount,
            'paymentMethod': e.paymentMethod,
            'installments': e.installments,
            'isFixed': e.isFixed,
            'storeDescription': e.storeDescription,
          }).toList(),
      'incomes': allIncomes.map((i) => {
            'month': i.month,
            'year': i.year,
            'incomeType': i.incomeType,
            'amount': i.amount,
            'isNet': i.isNet,
            'inssDeducted': i.inssDeducted,
            'irrfDeducted': i.irrfDeducted,
            'notes': i.notes,
          }).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/farol_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], subject: 'Farol Backup');
  }
}
