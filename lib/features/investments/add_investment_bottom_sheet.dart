import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/farol_colors.dart';

class AddInvestmentBottomSheet extends ConsumerStatefulWidget {
  const AddInvestmentBottomSheet({super.key});
  @override
  ConsumerState<AddInvestmentBottomSheet> createState() => _AddInvestmentState();
}

class _AddInvestmentState extends ConsumerState<AddInvestmentBottomSheet> {
  final _productCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _investedCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  InvestmentType _type = InvestmentType.cdb;
  DateTime _dateAdded = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _productCtrl.dispose();
    _institutionCtrl.dispose();
    _investedCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double? _parseBRL(String text) =>
      double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Add Investment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // Type grid
          Align(alignment: Alignment.centerLeft, child: Text('Type', style: Theme.of(context).textTheme.labelLarge)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4, mainAxisSpacing: 8, crossAxisSpacing: 8,
            children: InvestmentType.values.map((t) {
              final sel = _type == t;
              final color = AppTheme.getCategoryColor(t.dbValue);
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? color : Theme.of(context).colorScheme.outline.withOpacity(0.3), width: sel ? 2 : 1),
                  ),
                  child: Center(child: Text(
                    '${t.emoji} ${t.label}',
                    style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? color : colors.onSurface),
                    textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Product name
          TextField(
            controller: _productCtrl,
            decoration: const InputDecoration(labelText: 'Product name', prefixIcon: Icon(Icons.label_outline)),
          ),
          const SizedBox(height: 12),

          // Institution
          TextField(
            controller: _institutionCtrl,
            decoration: const InputDecoration(labelText: 'Institution / Broker', prefixIcon: Icon(Icons.account_balance_outlined)),
          ),
          const SizedBox(height: 12),

          // Amounts row
          Row(children: [
            Expanded(child: TextField(
              controller: _investedCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              decoration: const InputDecoration(labelText: 'Total invested', prefixText: 'R\$ '),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              decoration: const InputDecoration(labelText: 'Current balance', prefixText: 'R\$ '),
            )),
          ]),
          const SizedBox(height: 12),

          // Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text('${_dateAdded.day.toString().padLeft(2, '0')}/${_dateAdded.month.toString().padLeft(2, '0')}/${_dateAdded.year}'),
            trailing: const Icon(Icons.chevron_right),
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
            decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes)),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    final productName = _productCtrl.text.trim();
    final institution = _institutionCtrl.text.trim();
    final totalInvested = _parseBRL(_investedCtrl.text);
    final currentBalance = _parseBRL(_balanceCtrl.text.isEmpty ? _investedCtrl.text : _balanceCtrl.text);

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a product name')));
      return;
    }
    if (institution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the institution')));
      return;
    }
    if (totalInvested == null || totalInvested <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the invested amount')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(investmentRepositoryProvider).insert(
        type: _type.dbValue,
        productName: productName,
        institution: institution,
        dateAdded: _dateAdded,
        totalInvested: totalInvested,
        currentBalance: currentBalance ?? totalInvested,
        returnAmount: (currentBalance ?? totalInvested) - totalInvested,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment added'), backgroundColor: Colors.green),
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
}
