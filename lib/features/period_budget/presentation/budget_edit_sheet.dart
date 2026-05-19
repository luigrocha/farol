import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/period_budget.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/farol_snackbar.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/providers/workspace_providers.dart'
    show
        activeWorkspaceProvider,
        budgetChangesProvider,
        budgetChangesRepositoryProvider,
        isSharedWorkspaceProvider;

class BudgetEditSheet extends ConsumerStatefulWidget {
  /// Existing entry to edit. Null = creating a new override for a category.
  final PeriodBudgetEntry? entry;

  const BudgetEditSheet({super.key, this.entry});

  @override
  ConsumerState<BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<BudgetEditSheet> {
  String? _selectedCategory;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _selectedCategory = entry.category;
      _amountCtrl = TextEditingController(
        text: entry.amount.toStringAsFixed(2),
      );
    } else {
      _amountCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double _parseAmount() =>
      double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final amount = _parseAmount();
    if (amount <= 0) {
      context.showSuccessSnackBar(AppLocalizations.of(context).invalidAmount);
      return;
    }

    if (_selectedCategory == null) return;

    // isCustom = true when the amount differs from the parent goal.
    final goalAmount = widget.entry?.goalAmount;
    final isCustom = goalAmount == null || amount != goalAmount;

    setState(() => _saving = true);
    try {
      await ref.read(periodBudgetNotifierProvider.notifier).upsert(
            category: _selectedCategory!,
            amount: amount,
            isCustom: isCustom,
          );

      // Log budget change for shared workspaces
      final isShared = ref.read(isSharedWorkspaceProvider);
      final ws = ref.read(activeWorkspaceProvider).valueOrNull;
      if (isShared && ws != null) {
        final changesRepo = ref.read(budgetChangesRepositoryProvider);
        await changesRepo.log(
          workspaceId: ws.id,
          categorySlug: _selectedCategory!.toLowerCase(),
          newAmount: amount,
          oldAmount: widget.entry?.amount,
        );
        ref.invalidate(budgetChangesProvider);
      }

      if (mounted) Navigator.of(context).pop();
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
    final colors = context.colors;
    final period = ref.watch(currentPeriodProvider);
    // Only root categories in the picker — no subcategories.
    // Also normalize the selected slug to lowercase for legacy UPPERCASE values.
    final categories = (ref.watch(categoriesStreamProvider).value ?? [])
        .where((c) => c.parentId == null)
        .toList();

    final entry = widget.entry;
    final isEdit = entry != null;
    final goalAmount = entry?.goalAmount;

    // Resolve the effective category slug — normalize UPPERCASE legacy values,
    // fall back to first category if unknown. Uses a local var to avoid
    // setState-during-build.
    final slugs = categories.map((c) => c.slug).toSet();
    final normalizedSelected = _selectedCategory?.toLowerCase();
    final effectiveCategory =
        (normalizedSelected != null && slugs.contains(normalizedSelected))
            ? normalizedSelected
            : (categories.isNotEmpty ? categories.first.slug : null);

    if (effectiveCategory != _selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCategory = effectiveCategory);
      });
    }

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
                        isEdit
                            ? AppLocalizations.of(context).editBudget
                            : AppLocalizations.of(context).newBudget,
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
              AppLocalizations.of(context).budgetCategoryLabel,
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
                child: DropdownButton<String>(
                  value: effectiveCategory,
                  isExpanded: true,
                  // Lock category when editing an existing entry.
                  onChanged: isEdit
                      ? null
                      : (dbVal) {
                          if (dbVal != null) {
                            setState(() => _selectedCategory = dbVal);
                          }
                        },
                  items: categories
                      .map((cat) => DropdownMenuItem(
                            value: cat.slug,
                            child: Row(children: [
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(cat.name,
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
                  AppLocalizations.of(context).budgetAmount,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft),
                ),
                if (goalAmount != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).budgetGoalLabel(
                        FinancialCalculatorService.formatBRL(goalAmount)),
                    style:
                        TextStyle(fontSize: 11, color: colors.onSurfaceFaint),
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
                hintText:
                    goalAmount != null ? goalAmount.toStringAsFixed(2) : '0.00',
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
                        isEdit
                            ? AppLocalizations.of(context).saveChanges
                            : AppLocalizations.of(context).createBudget,
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
