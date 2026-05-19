import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/services/installment_service.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/enums.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/widgets/farol_snackbar.dart';

const _purple = Color(0xFF6B3FA0);

class AddInstallmentBottomSheet extends ConsumerStatefulWidget {
  const AddInstallmentBottomSheet({super.key});
  @override
  ConsumerState<AddInstallmentBottomSheet> createState() =>
      _AddInstallmentState();
}

class _AddInstallmentState extends ConsumerState<AddInstallmentBottomSheet> {
  final _descCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  int _numInstallments = 6;
  DateTime _purchaseDate = DateTime.now();
  DateTime _firstDueDate = DateTime(
      DateTime.now().year, DateTime.now().month + 1, DateTime.now().day);
  PaymentMethod _method = PaymentMethod.creditInstallment;
  String? _categorySlug;
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _storeCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  double? get _totalAmount =>
      double.tryParse(_totalCtrl.text.trim().replaceAll(',', '.'));

  double? get _installmentAmount {
    final t = _totalAmount;
    if (t == null) return null;
    return (t / _numInstallments * 100).floor() / 100;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.colors;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: colors.surfaceLow,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Center(
                  child: Text(context.l10n.installmentsAddTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800))),
              const SizedBox(height: 24),

              // Description
              TextField(
                controller: _descCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.installmentsFieldDescription,
                  prefixIcon: const Icon(Icons.label_outline),
                  hintText: context.l10n.installmentsFieldDescriptionHint,
                ),
              ),
              const SizedBox(height: 12),

              // Store (optional)
              TextField(
                controller: _storeCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.installmentsFieldStore,
                  prefixIcon:
                      Icon(Icons.store_outlined, color: colors.onSurfaceMuted),
                ),
              ),
              const SizedBox(height: 20),

              // Total amount
              Text(context.l10n.installmentsFieldTotal,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                ],
                onChanged: (_) => setState(() {}),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: _purple),
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  prefixStyle: TextStyle(fontSize: 16, color: _purple),
                ),
              ),
              const SizedBox(height: 20),

              // Number of installments
              _Label(context.l10n.installmentsFieldNum(_numInstallments)),
              const SizedBox(height: 8),
              Row(children: [
                _StepButton(
                  icon: Icons.remove,
                  onTap: _numInstallments > 2
                      ? () => setState(() => _numInstallments--)
                      : null,
                ),
                Expanded(
                    child: Slider(
                  value: _numInstallments.toDouble(),
                  min: 2,
                  max: 48,
                  divisions: 46,
                  activeColor: _purple,
                  onChanged: (v) =>
                      setState(() => _numInstallments = v.toInt()),
                )),
                _StepButton(
                  icon: Icons.add,
                  onTap: _numInstallments < 48
                      ? () => setState(() => _numInstallments++)
                      : null,
                ),
              ]),
              const SizedBox(height: 12),

              // Payment method
              Text(context.l10n.paymentMethod,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    PaymentMethod.creditInstallment,
                    PaymentMethod.creditFull,
                    PaymentMethod.debit,
                  ]
                      .map((m) => ChoiceChip(
                            label: Text(m.label,
                                style: const TextStyle(fontSize: 12)),
                            selected: _method == m,
                            selectedColor: _purple.withValues(alpha: 0.15),
                            onSelected: (v) {
                              if (v) setState(() => _method = m);
                            },
                          ))
                      .toList()),
              const SizedBox(height: 16),

              // Category (optional)
              Text(context.l10n.installmentsFieldCategory,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const SizedBox(height: 36),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _categorySlug,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined,
                        color: colors.onSurfaceMuted),
                    hintText: 'Selecionar...',
                  ),
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text(context.l10n.installmentsNoCategory)),
                    ...cats.map((c) => DropdownMenuItem(
                        value: c.slug,
                        child: Text('${c.emoji}  ${c.name}',
                            style: const TextStyle(fontSize: 14)))),
                  ],
                  onChanged: (v) => setState(() => _categorySlug = v),
                ),
              ),
              const SizedBox(height: 16),

              // Dates row
              Row(children: [
                Expanded(
                    child: _DatePicker(
                  label: context.l10n.installmentsFieldPurchaseDate,
                  date: _purchaseDate,
                  onPicked: (d) => setState(() => _purchaseDate = d),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _DatePicker(
                  label: context.l10n.installmentsFieldFirstDue,
                  date: _firstDueDate,
                  onPicked: (d) => setState(() => _firstDueDate = d),
                )),
              ]),
              const SizedBox(height: 20),

              // Preview
              if (_totalAmount != null && _installmentAmount != null)
                _PreviewCard(
                  total: _totalAmount!,
                  installmentAmount: _installmentAmount!,
                  numInstallments: _numInstallments,
                  firstDueDate: _firstDueDate,
                ),
              const SizedBox(height: 20),

              // Save
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(context.l10n.installmentsBtnCreate,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
      ),
    );
  }

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    final total = _totalAmount;

    if (desc.isEmpty) {
      context.showSuccessSnackBar(context.l10n.installmentsValidationDesc);
      return;
    }
    if (total == null || total <= 0) {
      context.showSuccessSnackBar(context.l10n.installmentsValidationAmount);
      return;
    }

    setState(() => _saving = true);
    try {
      final cutoffDay = ref.read(budgetSettingsProvider).value?.cutoffDay ?? 1;

      // Resolve category_id from slug
      String? categoryId;
      if (_categorySlug != null) {
        final cats = ref.read(categoriesStreamProvider).value ?? [];
        final cat = cats.firstWhere((c) => c.slug == _categorySlug,
            orElse: () => cats.first);
        categoryId = cat.id.isNotEmpty ? cat.id : null;
      }

      await ref.read(installmentServiceProvider).createPurchase(
            description: desc,
            storeName:
                _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
            purchaseDate: _purchaseDate,
            totalAmount: total,
            numInstallments: _numInstallments,
            paymentMethod: _method.dbValue,
            firstDueDate: _firstDueDate,
            categoryId: categoryId,
            categorySlug: _categorySlug,
            cutoffDay: cutoffDay,
          );

      HapticFeedback.mediumImpact();
      ref.invalidate(installmentPlansStreamProvider);
      ref.invalidate(activeInstallmentPlansProvider);
      ref.invalidate(pendingInstallmentPaymentsProvider);

      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(context.l10n.installmentsCreatedSnack);
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Preview card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final double total, installmentAmount;
  final int numInstallments;
  final DateTime firstDueDate;

  const _PreviewCard({
    required this.total,
    required this.installmentAmount,
    required this.numInstallments,
    required this.firstDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lastAmount = double.parse(
        (total - installmentAmount * (numInstallments - 1)).toStringAsFixed(2));
    final lastDue =
        InstallmentService.addMonthsPublic(firstDueDate, numInstallments - 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.installmentsPreview,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceSoft,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _PreviewStat(
              label: context.l10n.installmentsPerInstallment,
              value: FinancialCalculatorService.formatBRL(installmentAmount)),
          _PreviewStat(
              label: context.l10n.installmentsPreviewLast,
              value: FinancialCalculatorService.formatBRL(lastAmount)),
          _PreviewStat(
              label: context.l10n.installmentsPreviewEnds,
              value:
                  '${lastDue.month.toString().padLeft(2, '0')}/${lastDue.year}'),
        ]),
        if ((lastAmount - installmentAmount).abs() > 0.001) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.installmentsPreviewRoundingNote,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceFaint),
          ),
        ]
      ]),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label, value;
  const _PreviewStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceSoft,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
    ]);
  }
}

// ─── Date picker widget ───────────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPicked;
  const _DatePicker(
      {required this.label, required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.surfaceLow),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today, size: 14, color: colors.onSurfaceMuted),
          const SizedBox(width: 6),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: colors.onSurfaceSoft,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ])),
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? _purple.withValues(alpha: 0.1)
              : context.colors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null ? _purple : context.colors.onSurfaceFaint),
      ),
    );
  }
}
