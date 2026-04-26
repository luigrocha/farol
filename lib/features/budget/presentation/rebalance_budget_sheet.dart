import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import '../../../core/services/financial_calculator_service.dart';

class RebalanceBudgetSheet extends ConsumerStatefulWidget {
  /// When non-null, pre-populates each category's percentage with this map.
  final Map<String, double>? initialPercentages;

  const RebalanceBudgetSheet({super.key, this.initialPercentages});

  @override
  ConsumerState<RebalanceBudgetSheet> createState() =>
      _RebalanceBudgetSheetState();
}

class _RebalanceBudgetSheetState extends ConsumerState<RebalanceBudgetSheet> {
  final _controllers = <String, TextEditingController>{};
  final _percentages = <String, double>{};
  final _originalPercentages = <String, double>{};
  final _orderedCategories = <String>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final goals = ref.read(budgetGoalsProvider).value ?? [];
    // preserve declaration order from ExpenseCategory enum
    final goalMap = {for (final g in goals) g.category: g};
    for (final cat in ExpenseCategory.values) {
      final dbVal = cat.dbValue;
      if (swileCategories.contains(dbVal)) continue;
      final goal = goalMap[dbVal];
      if (goal == null) continue;
      _orderedCategories.add(dbVal);
      final pct = widget.initialPercentages?[dbVal] ?? goal.targetPercentage;
      _percentages[dbVal] = pct;
      _originalPercentages[dbVal] = goal.targetPercentage;
      final ctrl = TextEditingController(
        text: pct.toStringAsFixed(1),
      );
      ctrl.addListener(() => _onTextChanged(dbVal, ctrl.text));
      _controllers[dbVal] = ctrl;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total =>
      _percentages.values.fold(0.0, (s, v) => s + v);

  bool get _canSave => (_total - 100.0).abs() <= 0.5;

  void _onTextChanged(String category, String text) {
    final val = double.tryParse(text.trim()) ?? 0.0;
    if ((val - (_percentages[category] ?? 0.0)).abs() > 0.001) {
      setState(() => _percentages[category] = val);
    }
  }

  void _step(String category, double delta) {
    final newVal =
        ((_percentages[category] ?? 0.0) + delta).clamp(0.0, 100.0);
    setState(() => _percentages[category] = newVal);
    final text = newVal.toStringAsFixed(1);
    final ctrl = _controllers[category];
    if (ctrl != null && ctrl.text != text) ctrl.text = text;
  }

  void _normalize() {
    final total = _total;
    if (total <= 0) return;
    final factor = 100.0 / total;
    setState(() {
      for (final cat in _percentages.keys.toList()) {
        _percentages[cat] = (_percentages[cat]! * factor);
      }
    });
    for (final cat in _percentages.keys) {
      final text = _percentages[cat]!.toStringAsFixed(1);
      final ctrl = _controllers[cat];
      if (ctrl != null && ctrl.text != text) ctrl.text = text;
    }
  }

  Future<void> _trySave(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await _showPreview(context);
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(budgetGoalsNotifierProvider.notifier)
          .rebalance(_percentages);
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Budget rebalanced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _showPreview(BuildContext context) async {
    final changed = <String, ({double oldPct, double newPct})>{};
    for (final cat in _percentages.keys) {
      final oldPct = _originalPercentages[cat] ?? 0.0;
      final newPct = _percentages[cat] ?? 0.0;
      if ((newPct - oldPct).abs() > 0.05) {
        changed[cat] = (oldPct: oldPct, newPct: newPct);
      }
    }
    if (changed.isEmpty) return true;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Preview changes',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: changed.entries.map((e) {
              final cat = _resolveCategory(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      cat?.emoji ?? '💰',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat?.localizedLabel(ctx) ?? e.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${e.value.oldPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${e.value.newPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: tokens.FarolColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ExpenseCategory? _resolveCategory(String dbValue) {
    try {
      return ExpenseCategory.fromDb(dbValue);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = _total;
    final isOver = total > 100.5;
    final totalColor = isOver
        ? Colors.red
        : total >= 99.5
            ? Colors.green
            : Colors.orange;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    color: isOver
                        ? Colors.red.withValues(alpha: 0.1)
                        : colors.iconTintBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.balance,
                    size: 20,
                    color:
                        isOver ? Colors.red : tokens.FarolColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rebalance Budget',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Adjust percentages to reach exactly 100%',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Total bar ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: totalColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: totalColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${total.toStringAsFixed(1)}% / 100%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: totalColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _normalize,
                    icon: const Icon(Icons.auto_fix_high, size: 14),
                    label: const Text(
                      'Normalize',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.FarolColors.navy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Category rows ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _orderedCategories.map((cat) {
                    final category = _resolveCategory(cat);
                    return _RebalanceRow(
                      category: category,
                      dbValue: cat,
                      controller: _controllers[cat]!,
                      onDecrement: () => _step(cat, -0.5),
                      onIncrement: () => _step(cat, 0.5),
                      colors: colors,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || !_canSave)
                    ? null
                    : () => _trySave(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canSave ? tokens.FarolColors.navy : Colors.grey,
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _canSave
                            ? 'Save'
                            : total > 100.5
                                ? 'Over by ${(total - 100.0).toStringAsFixed(1)}% — adjust first'
                                : 'Under by ${(100.0 - total).toStringAsFixed(1)}% — adjust first',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Row widget ───────────────────────────────────────────────────────────────

class _RebalanceRow extends StatelessWidget {
  final ExpenseCategory? category;
  final String dbValue;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final FarolColors colors;

  const _RebalanceRow({
    required this.category,
    required this.dbValue,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            category?.emoji ?? '💰',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category?.localizedLabel(context) ?? dbValue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: onDecrement,
            color: tokens.FarolColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          SizedBox(
            width: 68,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 4),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
                suffixText: '%',
                suffixStyle: TextStyle(
                    fontSize: 11, color: colors.onSurfaceSoft),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onIncrement,
            color: tokens.FarolColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Formatted BRL helper (for future use / testing) ─────────────────────────

// ignore: unused_element
String _fmt(double v) => FinancialCalculatorService.formatBRL(v);
