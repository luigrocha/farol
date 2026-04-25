import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/budget_goal.dart';
import '../../../core/providers/providers.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import '../../../core/services/financial_calculator_service.dart';

class BudgetGoalsSheet extends ConsumerStatefulWidget {
  const BudgetGoalsSheet({super.key});

  @override
  ConsumerState<BudgetGoalsSheet> createState() => _BudgetGoalsSheetState();
}

class _BudgetGoalsSheetState extends ConsumerState<BudgetGoalsSheet> {
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final goalsMap = ref.read(budgetGoalsMapProvider);
    for (final cat in ExpenseCategory.values) {
      final dbValue = cat.dbValue;
      final goal = goalsMap[dbValue];
      _controllers[dbValue] = TextEditingController(
        text: goal?.targetAmount.toStringAsFixed(2) ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final effectiveSalary = ref.read(effectiveNetSalaryProvider);

      for (final cat in ExpenseCategory.values) {
        final dbValue = cat.dbValue;
        final amountText = _controllers[dbValue]?.text ?? '';
        if (amountText.isEmpty) continue;

        final amount = _parse(amountText);
        if (amount <= 0) continue;

        final percentage = effectiveSalary > 0 ? (amount / effectiveSalary) * 100 : 0;

        final goal = BudgetGoal(
          id: 0,
          userId: '',
          category: dbValue,
          targetPercentage: percentage.toDouble(),
          targetAmount: amount,
          type: 'Need',
          createdAt: DateTime.now(),
        );

        await ref.read(budgetGoalsNotifierProvider.notifier).save(goal);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.budgetGoalsSaved), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorSaving}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final monthExpensesByCategory = ref.watch(expensesByCategoryProvider);
    final effectiveSalary = ref.watch(effectiveNetSalaryProvider);

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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.iconTintBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    size: 20,
                    color: tokens.FarolColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('category_budgets'),
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.translate('set_monthly_spending_limits'),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final cat in ExpenseCategory.values)
                      _BudgetCategoryRow(
                        category: cat,
                        controller: _controllers[cat.dbValue]!,
                        currentSpending:
                            monthExpensesByCategory[cat.dbValue] ?? 0,
                        effectiveSalary: effectiveSalary,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.FarolColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.saveBudget,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final TextEditingController controller;
  final double currentSpending;
  final double effectiveSalary;

  const _BudgetCategoryRow({
    required this.category,
    required this.controller,
    required this.currentSpending,
    required this.effectiveSalary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final budgetAmount = double.tryParse(controller.text) ?? 0;
    final percentage = effectiveSalary > 0 ? (budgetAmount / effectiveSalary) * 100 : 0;
    final isOver = currentSpending > budgetAmount && budgetAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOver ? Colors.orange : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${l10n.translate('current_spending')}: ${FinancialCalculatorService.formatBRL(currentSpending)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (budgetAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.surfaceLowest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: l10n.translate('budget_amount'),
              prefixText: 'R\$ ',
              prefixStyle: TextStyle(color: colors.onSurfaceSoft),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
