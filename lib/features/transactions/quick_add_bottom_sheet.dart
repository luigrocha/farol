import 'package:farol/core/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String _categoryDbValue = 'FOOD_GROCERY';
  PaymentMethod _method = PaymentMethod.pix;
  bool _isFixed = false;
  DateTime _date = DateTime.now();
  String? _subcategory;

  static const _subcategories = {
    'HOUSING': ['Rent', 'Condo Fee', 'Electricity', 'Water', 'Gas', 'Internet', 'Property Tax', 'Maintenance'],
    'TRANSPORT': ['Uber', 'Subway/Bus', 'Fuel', 'Parking', 'Maintenance'],
    'FOOD_GROCERY': ['Supermarket', 'Restaurant', 'Delivery', 'Bakery', 'Farmers Market'],
    'HEALTH': ['Pharmacy', 'Doctor', 'Health Plan', 'Lab Tests', 'Gym'],
    'SUBSCRIPTIONS': ['Streaming', 'Apps', 'Mobile Phone', 'Gym', 'Other'],
    'LEISURE': ['Cinema', 'Travel', 'Bars', 'Games', 'Hobbies'],
    'EDUCATION': ['Course', 'Books', 'Certification', 'Materials'],
    'CARD_INSTALLMENTS': ['Installment Purchase'],
    'OTHER': ['Gift', 'Donation', 'Unexpected', 'Other'],
  };

  @override
  void dispose() { _amountCtrl.dispose(); _descCtrl.dispose(); _installmentsCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]),
        const SizedBox(height: 16),

        // 2. Category grid
        Align(alignment: Alignment.centerLeft, child: Text(l10n.category, style: Theme.of(context).textTheme.labelLarge)),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => Text(l10n.translate('error_loading')),
          data: (categories) {
            return GridView.count(
              crossAxisCount: 3, 
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5, 
              mainAxisSpacing: 8, 
              crossAxisSpacing: 8,
              children: categories.map((c) => _catChip(c, context)).toList(),
            );
          },
        ),
        const SizedBox(height: 16),

        // 3. Subcategory chips
        if (_subcategories[_categoryDbValue] != null) ...[
          Align(alignment: Alignment.centerLeft, child: Text(l10n.translate('subcategory'), style: Theme.of(context).textTheme.labelLarge)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: _subcategories[_categoryDbValue]!.map((s) =>
            ChoiceChip(label: Text(s, style: const TextStyle(fontSize: 12)), selected: _subcategory==s,
              onSelected: (v) => setState(() => _subcategory = v ? s : null))).toList()),
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

        // Installments field (conditional)
        if (_method == PaymentMethod.creditInstallment) ...[
          TextField(controller: _installmentsCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of installments', prefixIcon: Icon(Icons.format_list_numbered))),
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
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: tokens.FarolColors.beam, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: Text(l10n.save.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
    );
  }

  Widget _catChip(Category c, BuildContext context) {
    final sel = _categoryDbValue == c.dbValue;
    final color = tokens.FarolColors.getCategoryColor(c.dbValue);
    return GestureDetector(
      onTap: () => setState(() { _categoryDbValue = c.dbValue; _subcategory = null; }),
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
    final l10n = AppLocalizations.of(context);
    final amountStr = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      context.showSuccessSnackBar(l10n.invalidAmount);
      return;
    }

    final payType = _method.isSwile ? 'Swile' : 'Cash';
    final numInst = _method == PaymentMethod.creditInstallment
        ? int.tryParse(_installmentsCtrl.text) ?? 1
        : 1;

    final categories = ref.read(categoriesStreamProvider).value ?? [];
    final currentCat = categories.firstWhere((c) => c.dbValue == _categoryDbValue, 
        orElse: () => categories.isNotEmpty ? categories.first : const Category(dbValue: 'OTHER', name: 'Other', emoji: '📋'));
    
    final desc = _descCtrl.text.isEmpty ? _subcategory ?? currentCat.name : _descCtrl.text;

    try {
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

      if (_method == PaymentMethod.creditInstallment) {
        await ref.read(installmentRepositoryProvider).insert(
          description: desc,
          purchaseDate: _date,
          totalValue: amount * numInst,
          numInstallments: numInst,
          monthlyAmount: amount,
        );
      }

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(l10n.expenseSaved);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }
}
