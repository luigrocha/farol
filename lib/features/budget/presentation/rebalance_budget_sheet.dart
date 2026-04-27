import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import '../../../core/i18n/app_localizations.dart';
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
  final _orderedCategoryIds = <String>[];
  bool _saving = false;
  bool _initialized = false;

  void _initializeOnce() {
    if (_initialized) return;
    final goals = ref.read(budgetGoalsProvider).value ?? [];
    final catsMap = ref.read(categoriesMapProvider);
    
    // Sort goals by category orderIndex if available, or keep as is
    final goalMap = {for (final g in goals) g.category: g};
    
    // We only rebalance non-swile categories for now (as per original logic)
    for (final goal in goals) {
      final dbVal = goal.category;
      final cat = catsMap[dbVal];
      if (cat == null || cat.isSwile) continue;
      
      _orderedCategoryIds.add(dbVal);
      final pct = widget.initialPercentages?[dbVal] ?? goal.targetPercentage;
      _percentages[dbVal] = pct;
      _originalPercentages[dbVal] = goal.targetPercentage;
      final ctrl = TextEditingController(
        text: pct.toStringAsFixed(1),
      );
      ctrl.addListener(() => _onTextChanged(dbVal, ctrl.text));
      _controllers[dbVal] = ctrl;
    }
    _initialized = true;
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
          SnackBar(
            content: Text(AppLocalizations.of(context).budgetRebalanced),
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
    final catsMap = ref.read(categoriesMapProvider);
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
          AppLocalizations.of(ctx).previewChanges,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: changed.entries.map((e) {
              final cat = catsMap[e.key];
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
                        cat?.name ?? e.key,
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
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(ctx).save,
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

  @override
  Widget build(BuildContext context) {
    _initializeOnce();
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final catsMap = ref.watch(categoriesMapProvider);
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
                        l10n.rebalanceBudget,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.rebalanceSubtitle,
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
                    label: Text(
                      l10n.normalize,
                      style: const TextStyle(fontSize: 12),
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
                  children: _orderedCategoryIds.map((dbVal) {
                    final cat = catsMap[dbVal];
                    return _RebalanceRow(
                      categoryName: cat?.name ?? dbVal,
                      emoji: cat?.emoji ?? '💰',
                      dbValue: dbVal,
                      controller: _controllers[dbVal]!,
                      onDecrement: () => _step(dbVal, -0.5),
                      onIncrement: () => _step(dbVal, 0.5),
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
                            ? l10n.save
                            : total > 100.5
                                ? '${l10n.translate('rebalance_budget')} — ${(total - 100.0).toStringAsFixed(1)}% Over'
                                : '${l10n.translate('rebalance_budget')} — ${(100.0 - total).toStringAsFixed(1)}% Under',
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
  final String categoryName;
  final String emoji;
  final String dbValue;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final FarolColors colors;

  const _RebalanceRow({
    required this.categoryName,
    required this.emoji,
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
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              categoryName,
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
