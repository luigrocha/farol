import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/value_objects/category_ref.dart';
import '../../core/models/category.dart';
import '../../core/providers/providers.dart';
import '../../core/models/enums.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/farol_snackbar.dart';

class QuickAddBottomSheet extends ConsumerStatefulWidget {
  const QuickAddBottomSheet({super.key});
  @override
  ConsumerState<QuickAddBottomSheet> createState() => _QuickAddState();
}

class _QuickAddState extends ConsumerState<QuickAddBottomSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController(text: '2');
  String _categoryDbValue = 'food_grocery';
  PaymentMethod _method = PaymentMethod.pix;
  bool _isFixed = false;
  DateTime _date = DateTime.now();
  String? _subcategory;
  bool _saving = false;


  @override
  void dispose() { _amountCtrl.dispose(); _descCtrl.dispose(); _installmentsCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    // Watch the raw stream AsyncValue so we can distinguish loading from empty.
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final allLoaded = categoriesAsync.value ?? [];
    final categories = allLoaded
        .where((c) => c.parentId == null)
        .map(CategoryRef.fromCategory)
        .toList();
    final isLoadingCategories = categoriesAsync.isLoading && allLoaded.isEmpty;

    final selectedCategory = categories.firstWhere(
      (c) => c.slug == _categoryDbValue,
      orElse: () => categories.isNotEmpty ? categories.first : CategoryRef.uncategorized(_categoryDbValue),
    );
    final subcategories = ref.watch(subcategoriesForProvider(selectedCategory.id));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(l10n.addExpense, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),

        // 1. Amount
        TextField(controller: _amountCtrl, autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(prefixText: 'R\$ ', hintText: '0,00'),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),

        // 2. Category grid
        Align(alignment: Alignment.centerLeft, child: Text(l10n.category, style: Theme.of(context).textTheme.labelLarge)),
        const SizedBox(height: 8),
        if (isLoadingCategories)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: categories.map((c) => _catChip(c, context)).toList(),
          ),
        const SizedBox(height: 16),

        // 3. Subcategory chips (dynamic from DB)
        if (subcategories.isNotEmpty) ...[
          Align(alignment: Alignment.centerLeft, child: Text(l10n.translate('subcategory'), style: Theme.of(context).textTheme.labelLarge)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: subcategories.map((s) =>
            ChoiceChip(
              label: Text('${s.emoji} ${s.name}', style: const TextStyle(fontSize: 12)),
              selected: _subcategory == s.slug,
              onSelected: (v) => setState(() => _subcategory = v ? s.slug : null),
            )).toList()),
          const SizedBox(height: 16),
        ],

        // 4. Payment method pills
        Align(alignment: Alignment.centerLeft, child: Text(l10n.paymentMethod, style: Theme.of(context).textTheme.labelLarge)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          PaymentMethod.debit, PaymentMethod.pix, PaymentMethod.creditFull,
          PaymentMethod.creditInstallment, PaymentMethod.swileMeal, PaymentMethod.swileFood,
        ].map((m) => ChoiceChip(label: Text(m.localizedLabel(context), style: const TextStyle(fontSize: 12)),
          selected: _method==m, onSelected: (v) => setState(() { if(v) _method=m; }))).toList()),
        const SizedBox(height: 12),

        // Installments field + total preview (conditional)
        if (_method == PaymentMethod.creditInstallment) ...[
          TextField(
            controller: _installmentsCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.translate('num_installments'), prefixIcon: const Icon(Icons.format_list_numbered))),
          const SizedBox(height: 8),
          _InstallmentTotalPreview(amountCtrl: _amountCtrl, installmentsCtrl: _installmentsCtrl),
          const SizedBox(height: 12),
        ],

        // 5. Fixed/Variable toggle
        SwitchListTile(title: Text(l10n.fixedCost), value: _isFixed,
          onChanged: (v) => setState(() => _isFixed = v),
          contentPadding: EdgeInsets.zero),

        // 6. Description
        TextField(controller: _descCtrl,
          decoration: InputDecoration(labelText: '${l10n.translate('description')} (${l10n.translate('optional')})', prefixIcon: const Icon(Icons.description))),
        const SizedBox(height: 12),

        // 7. Date
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today),
          title: Text('${_date.day.toString().padLeft(2,'0')}/${_date.month.toString().padLeft(2,'0')}/${_date.year}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date,
              firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) setState(() => _date = d);
          }),
        const SizedBox(height: 20),

        // Save button
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: tokens.FarolColors.beam, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.save.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
    );
  }

  Widget _catChip(CategoryRef c, BuildContext context) {
    final sel = _categoryDbValue == c.slug;
    final color = tokens.FarolColors.getCategoryColor(c.slug);
    return GestureDetector(
      onTap: () => setState(() { _categoryDbValue = c.slug; _subcategory = null; }),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.15) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), width: sel ? 2 : 1)),
        child: Center(child: Text('${c.emoji} ${c.name}',
          style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? color : context.colors.onSurface),
          textAlign: TextAlign.center, overflow: TextOverflow.ellipsis))),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final amountStr = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      context.showSuccessSnackBar(l10n.invalidAmount);
      return;
    }
    setState(() => _saving = true);

    final payType = _method.isSwile ? 'Swile' : 'Cash';
    final numInst = _method == PaymentMethod.creditInstallment
        ? int.tryParse(_installmentsCtrl.text) ?? 1
        : 1;

    final allCats = (ref.read(categoriesStreamProvider).value ?? [])
        .where((c) => c.parentId == null)
        .map(CategoryRef.fromCategory)
        .toList();
    final currentCat = allCats.firstWhere((c) => c.slug == _categoryDbValue,
        orElse: () => allCats.isNotEmpty ? allCats.first : CategoryRef.uncategorized(_categoryDbValue));
    
    final desc = _descCtrl.text.isEmpty ? _subcategory ?? currentCat.name : _descCtrl.text;

    try {
      if (_method == PaymentMethod.creditInstallment && numInst > 1) {
        final totalValue = amount * numInst;
        final cutoffDay = ref.read(budgetSettingsProvider).value?.cutoffDay ?? 1;

        // Create plan + all payment rows via InstallmentService
        final plan = await ref.read(installmentServiceProvider).createPurchase(
          description: desc,
          purchaseDate: _date,
          totalAmount: totalValue,
          numInstallments: numInst,
          paymentMethod: _method.dbValue,
          firstDueDate: _date,
          categorySlug: _categoryDbValue,
          cutoffDay: cutoffDay,
        );

        // Insert only the first (real) expense linked to the new plan UUID
        final baseAmount = plan.installmentAmount;
        await ref.read(expenseRepositoryProvider).insert(
          transactionDate: _date,
          month: _date.month,
          year: _date.year,
          payType: payType,
          category: _categoryDbValue,
          subcategory: _subcategory ?? currentCat.name,
          amount: baseAmount,
          paymentMethod: _method.dbValue,
          installments: numInst,
          isFixed: false,
          storeDescription: '$desc (1/$numInst)',
          installmentPlanUuidId: plan.id,
        );
      } else {
        await ref.read(expenseRepositoryProvider).insert(
          transactionDate: _date,
          month: _date.month,
          year: _date.year,
          payType: payType,
          category: _categoryDbValue,
          subcategory: _subcategory ?? currentCat.name,
          amount: amount,
          paymentMethod: _method.dbValue,
          installments: numInst,
          isFixed: _isFixed,
          storeDescription: desc,
        );
      }

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(l10n.expenseSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showErrorSnackBar(e);
      }
    }
  }
}

class _InstallmentTotalPreview extends StatelessWidget {
  final TextEditingController amountCtrl;
  final TextEditingController installmentsCtrl;

  const _InstallmentTotalPreview({
    required this.amountCtrl,
    required this.installmentsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final amountStr = amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountStr) ?? 0;
    final numInst = int.tryParse(installmentsCtrl.text) ?? 0;
    if (amount <= 0 || numInst <= 1) return const SizedBox.shrink();
    final total = amount * numInst;
    final totalStr = total.toStringAsFixed(2).replaceAll('.', ',');
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Total projetado: R\$ $totalStr ($numInst × R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')})',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
