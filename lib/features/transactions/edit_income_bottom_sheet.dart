import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/providers.dart';
import '../../core/models/income.dart';
import '../../core/models/enums.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/farol_snackbar.dart';

class EditIncomeBottomSheet extends ConsumerStatefulWidget {
  final Income income;
  const EditIncomeBottomSheet({super.key, required this.income});

  @override
  ConsumerState<EditIncomeBottomSheet> createState() => _EditIncomeBottomSheetState();
}

class _EditIncomeBottomSheetState extends ConsumerState<EditIncomeBottomSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late final TextEditingController _dependentsController;
  late IncomeType _type;
  late bool _isNet;
  bool _saving = false;
  NetSalaryResult? _calculatedNet;
  bool _showCalculation = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.income.amount.toStringAsFixed(2).replaceAll('.', ','));
    _notesController = TextEditingController(text: widget.income.notes ?? '');
    _dependentsController = TextEditingController(text: '0');
    _type = IncomeType.fromDb(widget.income.incomeType);
    _isNet = widget.income.isNet;
    if (widget.income.inssDeducted != null && widget.income.irrfDeducted != null) {
      _showCalculation = true;
      _calculatedNet = NetSalaryResult(
        gross: widget.income.amount + (widget.income.inssDeducted ?? 0) + (widget.income.irrfDeducted ?? 0),
        inss: widget.income.inssDeducted ?? 0,
        irrf: widget.income.irrfDeducted ?? 0,
        net: widget.income.amount,
        inssBreakdown: [],
        irrfBreakdown: [],
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _dependentsController.dispose();
    super.dispose();
  }

  void _calculateNet() {
    final amountStr = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    final gross = double.tryParse(amountStr);
    if (gross == null || gross <= 0) return;
    final dependents = int.tryParse(_dependentsController.text) ?? 0;
    setState(() {
      _calculatedNet = FinancialCalculatorService.calculateNetFromGross(gross, dependents: dependents);
      _showCalculation = true;
    });
  }

  void _useNetValue() {
    if (_calculatedNet == null) return;
    setState(() {
      _amountController.text = _calculatedNet!.net.toStringAsFixed(2).replaceAll('.', ',');
      _isNet = true;
    });
  }

  Future<void> _save() async {
    final amountStr = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      if (mounted) context.showErrorSnackBar(context.l10n.invalidAmount);
      return;
    }

    setState(() => _saving = true);
    try {
      double? inssDeducted;
      double? irrfDeducted;
      if (_showCalculation && _calculatedNet != null) {
        inssDeducted = _calculatedNet!.inss;
        irrfDeducted = _calculatedNet!.irrf;
      } else if (widget.income.inssDeducted != null) {
        inssDeducted = widget.income.inssDeducted;
        irrfDeducted = widget.income.irrfDeducted;
      }

      await ref.read(incomeNotifierProvider.notifier).save(
            id: widget.income.id,
            month: widget.income.month,
            year: widget.income.year,
            incomeType: _type.dbValue,
            amount: amount,
            isNet: _isNet,
            inssDeducted: inssDeducted,
            irrfDeducted: irrfDeducted,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(context.l10n.incomeUpdated);
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editIncome,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.translate('type'), style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: IncomeType.values.map((t) {
                      final active = _type == t;
                      return GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? tokens.FarolColors.tide : colors.surfaceLow,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${t.emoji} ${t.label}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                  decoration: InputDecoration(labelText: l10n.amount, prefixText: 'R\$ '),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.netValueHint,
                        style: TextStyle(fontSize: 13, color: colors.onSurfaceMuted),
                      ),
                    ),
                    Switch(
                      value: _isNet,
                      onChanged: (v) => setState(() => _isNet = v),
                      activeThumbColor: tokens.FarolColors.tide,
                    ),
                  ],
                ),
                if (_type == IncomeType.netSalary) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.dependentsIrrf,
                                style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _dependentsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _calculateNet,
                            icon: const Icon(Icons.calculate_outlined, size: 18),
                            label: Text(l10n.calculateNet),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: tokens.FarolColors.tide,
                              side: BorderSide(color: tokens.FarolColors.tide.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_showCalculation && _calculatedNet != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.FarolColors.tide.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.FarolColors.tide.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.salaryBreakdown,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.FarolColors.tide,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCalcRow(l10n.lblGross, _calculatedNet!.gross, colors.onSurface),
                        _buildCalcRow('INSS', -_calculatedNet!.inss, const Color(0xFFFF6B35)),
                        _buildCalcRow('IRRF', -_calculatedNet!.irrf, const Color(0xFFFF6B35)),
                        const Divider(height: 20),
                        _buildCalcRow(l10n.lblNet, _calculatedNet!.net, tokens.FarolColors.tide, bold: true),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _useNetValue,
                            icon: const Icon(Icons.download_outlined, size: 16),
                            label: Text(l10n.useNetValue),
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.FarolColors.tide,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.translate('notes_optional')),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: tokens.FarolColors.tide),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.saveChanges),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, double value, Color color, {bool bold = false}) {
    final formatted = FinancialCalculatorService.formatBRL(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            formatted,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
