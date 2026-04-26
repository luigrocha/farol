import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/widgets/farol_snackbar.dart';

class AddInstallmentBottomSheet extends ConsumerStatefulWidget {
  const AddInstallmentBottomSheet({super.key});
  @override
  ConsumerState<AddInstallmentBottomSheet> createState() => _AddInstallmentState();
}

class _AddInstallmentState extends ConsumerState<AddInstallmentBottomSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _numInstallments = 6;
  int _currentInstallment = 1;
  DateTime _purchaseDate = DateTime.now();
  bool _saving = false;

  static const _purple = Color(0xFF6B3FA0);

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double? _parseBRL(String text) =>
      double.tryParse(text.trim().replaceAll('.', '').replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
            color: colors.surfaceLow, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          Center(child: Text(l10n.translate('new_installment'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
          const SizedBox(height: 24),

          // Description
          TextField(
            controller: _descCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.translate('description_required'),
              prefixIcon: const Icon(Icons.label_outline),
              hintText: l10n.translate('desc_example'),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly amount
          Text(l10n.translate('monthly_installment_amount'), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: _purple),
            decoration: const InputDecoration(
              prefixText: 'R\$ ',
              hintText: '0,00',
              prefixStyle: TextStyle(fontSize: 16, color: _purple),
            ),
          ),
          const SizedBox(height: 20),

          // Number of installments
          _Label(label: '${l10n.translate('num_installments')}: $_numInstallments'),
          const SizedBox(height: 8),
          Row(children: [
            _StepButton(
              icon: Icons.remove,
              onTap: _numInstallments > 2
                  ? () => setState(() { _numInstallments--; if (_currentInstallment > _numInstallments) _currentInstallment = _numInstallments; })
                  : null,
            ),
            Expanded(child: Slider(
              value: _numInstallments.toDouble(),
              min: 2, max: 48, divisions: 46,
              activeColor: _purple,
              onChanged: (v) => setState(() { _numInstallments = v.toInt(); if (_currentInstallment > _numInstallments) _currentInstallment = _numInstallments; }),
            )),
            _StepButton(
              icon: Icons.add,
              onTap: _numInstallments < 48 ? () => setState(() => _numInstallments++) : null,
            ),
          ]),
          const SizedBox(height: 12),

          // Current installment (already paid)
          _Label(label: '${l10n.translate('current_installment')}: $_currentInstallment ${l10n.translate('of')} $_numInstallments'),
          const SizedBox(height: 8),
          Row(children: [
            _StepButton(
              icon: Icons.remove,
              onTap: _currentInstallment > 1 ? () => setState(() => _currentInstallment--) : null,
            ),
            Expanded(child: Slider(
              value: _currentInstallment.toDouble(),
              min: 1, max: _numInstallments.toDouble(), divisions: _numInstallments - 1,
              activeColor: _purple,
              onChanged: (v) => setState(() => _currentInstallment = v.toInt()),
            )),
            _StepButton(
              icon: Icons.add,
              onTap: _currentInstallment < _numInstallments ? () => setState(() => _currentInstallment++) : null,
            ),
          ]),
          const SizedBox(height: 12),

          // Purchase date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: colors.onSurfaceMuted, size: 20),
            title: Text(
              '${l10n.translate('purchased_on')} ${_purchaseDate.day.toString().padLeft(2, '0')}/${_purchaseDate.month.toString().padLeft(2, '0')}/${_purchaseDate.year}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
            onTap: () async {
              final d = await showDatePicker(
                context: context, initialDate: _purchaseDate,
                firstDate: DateTime(2020), lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _purchaseDate = d);
            },
          ),
          const SizedBox(height: 4),

          // Notes
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: l10n.translate('notes_optional'),
              prefixIcon: Icon(Icons.notes, color: colors.onSurfaceMuted),
            ),
          ),
          const SizedBox(height: 24),

          // Preview
          if (_parseBRL(_amountCtrl.text) != null) ...[
            _PreviewCard(
              monthly: _parseBRL(_amountCtrl.text)!,
              numInstallments: _numInstallments,
              currentInstallment: _currentInstallment,
              l10n: l10n,
            ),
            const SizedBox(height: 16),
          ],

          // Save
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.save.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final desc = _descCtrl.text.trim();
    final monthly = _parseBRL(_amountCtrl.text);

    if (desc.isEmpty) { _snack(l10n.translate('enter_description')); return; }
    if (monthly == null || monthly <= 0) { _snack(l10n.translate('enter_installment_amount')); return; }

    setState(() => _saving = true);
    try {
      await ref.read(installmentRepositoryProvider).insert(
        description: desc,
        purchaseDate: _purchaseDate,
        totalValue: monthly * _numInstallments,
        numInstallments: _numInstallments,
        currentInstallment: _currentInstallment,
        monthlyAmount: monthly,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(l10n.translate('installment_added'));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => context.showSuccessSnackBar(msg);
}

class _PreviewCard extends StatelessWidget {
  final double monthly;
  final int numInstallments, currentInstallment;
  final AppLocalizations l10n;
  const _PreviewCard({required this.monthly, required this.numInstallments, required this.currentInstallment, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final remaining = numInstallments - currentInstallment;
    final remainingBalance = monthly * remaining;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6B3FA0).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B3FA0).withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _PreviewStat(label: l10n.translate('total'), value: 'R\$ ${(monthly * numInstallments).toStringAsFixed(0)}', colors: colors),
        _PreviewStat(label: l10n.translate('remaining'), value: '$remaining ${l10n.translate('installments')}', colors: colors),
        _PreviewStat(label: l10n.translate('remaining_balance'), value: 'R\$ ${remainingBalance.toStringAsFixed(0)}', colors: colors),
      ]),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label, value;
  final FarolColors colors;
  const _PreviewStat({required this.label, required this.value, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 9, color: colors.onSurfaceSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B3FA0))),
    ]);
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF6B3FA0).withValues(alpha: 0.1)
              : context.colors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18,
          color: onTap != null ? const Color(0xFF6B3FA0) : context.colors.onSurfaceFaint),
      ),
    );
  }
}
