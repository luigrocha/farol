import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/period_budget.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;

class BudgetEditSheet extends ConsumerStatefulWidget {
  /// Existing entry to edit. Null = creating a new override for a category.
  final PeriodBudgetEntry? entry;

  const BudgetEditSheet({super.key, this.entry});

  @override
  ConsumerState<BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<BudgetEditSheet> {
  late ExpenseCategory _selectedCategory;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _selectedCategory =
          _catFromDb(entry.category) ?? ExpenseCategory.values.first;
      _amountCtrl = TextEditingController(
        text: entry.amount.toStringAsFixed(2),
      );
    } else {
      _selectedCategory = ExpenseCategory.values.first;
      _amountCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  ExpenseCategory? _catFromDb(String dbValue) {
    try {
      return ExpenseCategory.fromDb(dbValue);
    } catch (_) {
      return null;
    }
  }

  double _parseAmount() =>
      double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final amount = _parseAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    // isCustom = true when the amount differs from the parent goal.
    final goalAmount = widget.entry?.goalAmount;
    final isCustom = goalAmount == null || amount != goalAmount;

    setState(() => _saving = true);
    try {
      await ref.read(periodBudgetNotifierProvider.notifier).upsert(
            category: _selectedCategory.dbValue,
            amount: amount,
            isCustom: isCustom,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final period = ref.watch(currentPeriodProvider);
    final entry = widget.entry;
    final isEdit = entry != null;
    final goalAmount = entry?.goalAmount;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  child: const Icon(Icons.pie_chart_outline,
                      size: 20, color: tokens.FarolColors.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Budget' : 'New Budget',
                        style: GoogleFonts.manrope(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        period.label,
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Category',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceSoft),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.onSurfaceFaint),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExpenseCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  // Lock category when editing an existing entry.
                  onChanged: isEdit
                      ? null
                      : (cat) {
                          if (cat != null) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                  items: ExpenseCategory.values
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(children: [
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(cat.label,
                                  style: const TextStyle(fontSize: 14)),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Amount',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft),
                ),
                if (goalAmount != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Goal: ${FinancialCalculatorService.formatBRL(goalAmount)}',
                    style: TextStyle(
                        fontSize: 11, color: colors.onSurfaceFaint),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: goalAmount != null
                    ? goalAmount.toStringAsFixed(2)
                    : '0.00',
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(color: colors.onSurfaceSoft),
                filled: true,
                fillColor: colors.surfaceLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.onSurfaceFaint),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.onSurfaceFaint),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : 'Create Budget',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
