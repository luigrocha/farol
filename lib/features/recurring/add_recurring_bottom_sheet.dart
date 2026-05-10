import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/recurring_rule.dart';
import '../../core/domain/services/recurrence_resolver.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/widgets/farol_snackbar.dart';

const _teal = Color(0xFF00897B);

class AddRecurringBottomSheet extends ConsumerStatefulWidget {
  const AddRecurringBottomSheet({super.key, this.editRule});
  final RecurringRule? editRule;

  @override
  ConsumerState<AddRecurringBottomSheet> createState() =>
      _AddRecurringState();
}

class _AddRecurringState extends ConsumerState<AddRecurringBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int _dayOfMonth = DateTime.now().day;
  DateTime _startsOn = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _categorySlug;
  String? _paymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.editRule;
    if (r != null) {
      _nameCtrl.text = r.name;
      _amountCtrl.text = r.baseAmount.toStringAsFixed(2);
      _frequency = r.frequency;
      _dayOfMonth = r.dayOfMonth ?? DateTime.now().day;
      _startsOn = r.startsOn;
      _categorySlug = r.categorySlug;
      _paymentMethod = r.paymentMethod;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double? get _amount =>
      double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty && (_amount ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isEdit = widget.editRule != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(isEdit ? l10n.recurringEditTitle : l10n.recurringAddTitle,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          // Name
          _Label(l10n.recurringFieldName),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: _inputDec(l10n.recurringFieldNameHint),
          ),
          const SizedBox(height: 16),

          // Amount
          _Label(l10n.recurringFieldAmount),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            onChanged: (_) => setState(() {}),
            decoration: _inputDec('0,00'),
          ),
          const SizedBox(height: 16),

          // Frequency
          _Label(l10n.recurringFieldFrequency),
          DropdownButtonFormField<RecurringFrequency>(
            // ignore: deprecated_member_use
            value: _frequency,
            decoration: _inputDec(null),
            items: RecurringFrequency.values
                .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.localizedLabel(l10n.locale.languageCode))))
                .toList(),
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          const SizedBox(height: 16),

          // Day of month
          if (_frequency == RecurringFrequency.monthly ||
              _frequency == RecurringFrequency.quarterly ||
              _frequency == RecurringFrequency.semiannual ||
              _frequency == RecurringFrequency.yearly) ...[
            _Label(l10n.recurringFieldDayOfMonth),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _dayOfMonth,
              decoration: _inputDec(null),
              items: List.generate(28, (i) => i + 1)
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                  .toList(),
              onChanged: (v) => setState(() => _dayOfMonth = v!),
            ),
            const SizedBox(height: 16),
          ],

          // Category
          _Label(l10n.recurringFieldCategory),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
            data: (cats) => DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _categorySlug,
              decoration: _inputDec(l10n.recurringFieldCategoryHint),
              items: cats
                  .map((c) => DropdownMenuItem(value: c.slug, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categorySlug = v),
            ),
          ),
          const SizedBox(height: 16),

          // Start date
          _Label(l10n.recurringFieldStart),
          InkWell(
            onTap: _pickStartDate,
            child: InputDecorator(
              decoration: _inputDec(null),
              child: Text(
                '${_startsOn.day.toString().padLeft(2, '0')}/${_startsOn.month.toString().padLeft(2, '0')}/${_startsOn.year}',
                style: GoogleFonts.manrope(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Preview
          if (_valid) _PreviewSection(
            amount: _amount!,
            frequency: _frequency,
            dayOfMonth: _dayOfMonth,
            startsOn: _startsOn,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _valid && !_saving ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? l10n.recurringBtnSave : l10n.recurringBtnCreate,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startsOn,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startsOn = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(recurringServiceProvider);
      final now = DateTime.now();
      final edit = widget.editRule;

      if (edit != null) {
        final updated = RecurringRule(
          id: edit.id,
          userId: edit.userId,
          categorySlug: _categorySlug,
          name: _nameCtrl.text.trim(),
          baseAmount: _amount!,
          frequency: _frequency,
          dayOfMonth: _dayOfMonth,
          startsOn: _startsOn,
          status: edit.status,
          paymentMethod: _paymentMethod,
          createdAt: edit.createdAt,
          updatedAt: now,
        );
        await service.updateRule(edit.id, updated);
      } else {
        final rule = RecurringRule(
          id: '',
          userId: '',
          categorySlug: _categorySlug,
          name: _nameCtrl.text.trim(),
          baseAmount: _amount!,
          frequency: _frequency,
          dayOfMonth: _dayOfMonth,
          startsOn: _startsOn,
          paymentMethod: _paymentMethod,
          createdAt: now,
          updatedAt: now,
        );
        await service.createRule(rule);
      }
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(
            edit != null ? context.l10n.recurringUpdatedSnack : context.l10n.recurringCreatedSnack);
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDec(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );
}

// ─── Preview section ──────────────────────────────────────────────────────────

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.amount,
    required this.frequency,
    required this.dayOfMonth,
    required this.startsOn,
  });
  final double amount;
  final RecurringFrequency frequency;
  final int dayOfMonth;
  final DateTime startsOn;

  @override
  Widget build(BuildContext context) {
    final rule = RecurringRule(
      id: 'preview',
      userId: '',
      name: '',
      baseAmount: amount,
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      startsOn: startsOn,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 4, 0);
    final occurrences = const RecurrenceResolver()
        .generateOccurrences(rule, rangeStart: now, rangeEnd: end)
        .take(3)
        .toList();

    if (occurrences.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.recurringUpcomingOccurrences,
            style: GoogleFonts.manrope(
                fontSize: 11, color: _teal, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...occurrences.map((o) {
          final d = o.scheduledDate;
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              const Icon(Icons.arrow_right, size: 14, color: _teal),
              Text(
                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  –  ${FinancialCalculatorService.formatBRL(o.expectedAmount)}',
                style: GoogleFonts.manrope(fontSize: 12),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Label ────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
