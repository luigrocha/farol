import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../domain/budget_settings.dart';

class BudgetSettingsSheet extends ConsumerStatefulWidget {
  const BudgetSettingsSheet({super.key});

  @override
  ConsumerState<BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends ConsumerState<BudgetSettingsSheet> {
  final _netSalaryController = TextEditingController();
  final _swileMealController = TextEditingController();
  final _swileFoodController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final budget = ref.read(budgetSettingsProvider).value;
    if (budget != null) {
      if (budget.netSalary > 0) _netSalaryController.text = budget.netSalary.toStringAsFixed(2);
      if (budget.swileMeal > 0) _swileMealController.text = budget.swileMeal.toStringAsFixed(2);
      if (budget.swileFood > 0) _swileFoodController.text = budget.swileFood.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _netSalaryController.dispose();
    _swileMealController.dispose();
    _swileFoodController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(budgetSettingsProvider.notifier).save(BudgetSettings(
        netSalary: _parse(_netSalaryController.text),
        swileMeal: _parse(_swileMealController.text),
        swileFood: _parse(_swileFoodController.text),
      ));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget saved successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving budget: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final budget = ref.watch(budgetSettingsProvider).value;
    final total = budget?.totalBudget ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.onSurfaceFaint, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: colors.iconTintBlue, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppTheme.primaryColor)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly Budget', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
                if (total > 0) Text('Total: ${FinancialCalculatorService.formatBRL(total)}', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
              ]),
            ]),
            const SizedBox(height: 6),
            Text('Set your planned monthly income. The dashboard will track remaining amounts as you add transactions.', style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft, height: 1.5)),
            const SizedBox(height: 20),
            _AmountField(controller: _netSalaryController, label: 'Net Salary', hint: '9651.91', icon: Icons.account_balance_wallet),
            const SizedBox(height: 12),
            _AmountField(controller: _swileMealController, label: 'Swile Meal', hint: '1400.00', icon: Icons.restaurant),
            const SizedBox(height: 12),
            _AmountField(controller: _swileFoodController, label: 'Swile Food', hint: '1031.00', icon: Icons.shopping_basket_outlined),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Budget', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  const _AmountField({required this.controller, required this.label, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        prefixText: 'R\$ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final val = double.tryParse(v.trim().replaceAll(',', '.'));
        if (val == null || val < 0) return 'Enter a valid amount';
        return null;
      },
    );
  }
}
