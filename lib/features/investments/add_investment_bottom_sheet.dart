import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/models/enums.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;

class AddInvestmentBottomSheet extends ConsumerStatefulWidget {
  const AddInvestmentBottomSheet({super.key});
  @override
  ConsumerState<AddInvestmentBottomSheet> createState() => _AddInvestmentState();
}

class _AddInvestmentState extends ConsumerState<AddInvestmentBottomSheet> {
  final _amountCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  InvestmentType _type = InvestmentType.cdb;
  DateTime _dateAdded = DateTime.now();
  bool _saving = false;
  bool _balanceDiffers = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _balanceCtrl.dispose();
    _productCtrl.dispose();
    _institutionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double? _parseBRL(String text) =>
      double.tryParse(text.trim().replaceAll('.', '').replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.colors;
    final typeColor = tokens.FarolColors.getCategoryColor(_type.dbValue);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        // Header
        Center(child: Text(l10n.addInvestment, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 24),

        // Type selector — horizontal scroll
        Text('Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(height: 48, child: ListView(
          scrollDirection: Axis.horizontal,
          children: InvestmentType.values.map((t) {
            final sel = _type == t;
            final c = tokens.FarolColors.getCategoryColor(t.dbValue);
            return GestureDetector(
              onTap: () => setState(() => _type = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? c.withOpacity(0.12) : colors.surfaceLowest,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: sel ? c : colors.surfaceLowest, width: sel ? 1.5 : 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(t.label, style: TextStyle(
                    fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? c : colors.onSurfaceSoft,
                  )),
                ]),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 20),

        // Amount — big
        Text(l10n.amountInvested, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700, color: typeColor),
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            hintText: '0,00',
            prefixStyle: TextStyle(fontSize: 16, color: typeColor.withOpacity(0.6)),
          ),
        ),
        const SizedBox(height: 4),

        // Current balance toggle
        Row(children: [
          Checkbox(
            value: _balanceDiffers,
            onChanged: (v) => setState(() { _balanceDiffers = v!; if (!v) _balanceCtrl.clear(); }),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(l10n.currentBalanceDiffers, style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
        ]),
        if (_balanceDiffers) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: const InputDecoration(labelText: 'Current balance', prefixText: 'R\$ '),
          ),
        ],
        const SizedBox(height: 16),

        // Product + Institution
        TextField(
          controller: _productCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Product name',
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _institutionCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Institution / Broker',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.calendar_today, color: colors.onSurfaceMuted),
          title: Text(
            '${_dateAdded.day.toString().padLeft(2, '0')}/${_dateAdded.month.toString().padLeft(2, '0')}/${_dateAdded.year}',
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
          onTap: () async {
            final d = await showDatePicker(
              context: context, initialDate: _dateAdded,
              firstDate: DateTime(2010), lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _dateAdded = d);
          },
        ),

        // Notes
        TextField(
          controller: _notesCtrl,
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            prefixIcon: Icon(Icons.notes, color: colors.onSurfaceMuted),
          ),
        ),
        const SizedBox(height: 24),

        // Save
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          )),
      ])),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final productName = _productCtrl.text.trim();
    final institution = _institutionCtrl.text.trim();
    final totalInvested = _parseBRL(_amountCtrl.text);
    final currentBalance = _balanceDiffers
        ? _parseBRL(_balanceCtrl.text)
        : totalInvested;

    if (productName.isEmpty) {
      _snack('Enter a product name');
      return;
    }
    if (institution.isEmpty) {
      _snack('Enter the institution');
      return;
    }
    if (totalInvested == null || totalInvested <= 0) {
      _snack('Enter the invested amount');
      return;
    }
    if (_balanceDiffers && currentBalance == null) {
      _snack('Enter a valid current balance');
      return;
    }

    setState(() => _saving = true);
    try {
      final balance = currentBalance ?? totalInvested;
      await ref.read(investmentRepositoryProvider).insert(
        type: _type.dbValue,
        productName: productName,
        institution: institution,
        dateAdded: _dateAdded,
        totalInvested: totalInvested,
        currentBalance: balance,
        returnAmount: balance - totalInvested,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.investmentAdded), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
