import 'package:farol/core/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/farol_snackbar.dart';
import '../../../core/models/budget_goal.dart';
import '../../../core/providers/providers.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import '../../../core/services/financial_calculator_service.dart';

class BudgetGoalsSheet extends ConsumerStatefulWidget {
  const BudgetGoalsSheet({super.key});

  @override
  ConsumerState<BudgetGoalsSheet> createState() => _BudgetGoalsSheetState();
}

class _BudgetGoalsSheetState extends ConsumerState<BudgetGoalsSheet> {
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;
  double _totalPct = 0.0;
  bool _initialized = false;

  void _initControllers(List<Category> categories) {
    if (_initialized) return;
    final goalsMap = ref.read(budgetGoalsMapProvider);
    for (final cat in categories) {
      final dbValue = cat.dbValue;
      final goal = goalsMap[dbValue];
      final ctrl = TextEditingController(
        text: goal?.targetAmount.toStringAsFixed(2) ?? '',
      );
      ctrl.addListener(_onAmountChanged);
      _controllers[dbValue] = ctrl;
    }
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAmountChanged());
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.removeListener(_onAmountChanged);
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onAmountChanged() {
    final categories = ref.read(categoriesStreamProvider).value ?? [];
    final salary = ref.read(effectiveNetSalaryProvider);
    double total = 0.0;
    for (final cat in categories) {
      if (cat.isSwile) continue;
      final text = _controllers[cat.dbValue]?.text ?? '';
      final amount = _parse(text);
      if (amount > 0 && salary > 0) {
        total += (amount / salary) * 100;
      }
    }
    if (mounted) setState(() => _totalPct = total);
  }

  double _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (_totalPct > 100) return;

    final categories = ref.read(categoriesStreamProvider).value ?? [];
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final effectiveSalary = ref.read(effectiveNetSalaryProvider);

      for (final cat in categories) {
        final dbValue = cat.dbValue;
        final amountText = _controllers[dbValue]?.text ?? '';
        if (amountText.isEmpty) continue;

        final amount = _parse(amountText);
        if (amount <= 0) continue;

        final percentage = cat.isSwile
            ? 0.0
            : (effectiveSalary > 0 ? (amount / effectiveSalary) * 100 : 0.0);

        final goal = BudgetGoal(
          id: 0,
          userId: '',
          category: dbValue,
          targetPercentage: percentage,
          targetAmount: amount,
          type: 'Need',
          createdAt: DateTime.now(),
        );

        await ref.read(budgetGoalsNotifierProvider.notifier).save(goal);
      }

      if (mounted) {
        Navigator.of(context).pop();
        context.showSuccessSnackBar(l10n.budgetGoalsSaved);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final monthExpensesByCategory = ref.watch(expensesByCategoryProvider);
    final effectiveSalary = ref.watch(effectiveNetSalaryProvider);
    final swileBalance = ref.watch(effectiveSwileProvider);
    final remaining = (100.0 - _totalPct).clamp(0.0, 100.0);
    final isOver = _totalPct > 100;

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (categories) {
        _initControllers(categories);
        
        final cashCats = categories.where((c) => !c.isSwile).toList();
        final swileCats = categories.where((c) => c.isSwile).toList();

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: colors.surfaceLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: colors.iconTintBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        size: 20,
                        color: tokens.FarolColors.navy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('category_budgets'),
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.translate('set_monthly_spending_limits'),
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Cash Budget section ───────────────────────────
                        _SectionHeader(
                          label: l10n.translate('cash_budget'),
                          icon: Icons.account_balance_wallet_outlined,
                          color: tokens.FarolColors.navy,
                        ),
                        const SizedBox(height: 10),
                        _PercentageBar(
                          totalPct: _totalPct,
                          remaining: remaining,
                          isOver: isOver,
                        ),
                        if (isOver) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Adjusting this would exceed your 100% budget limit. '
                                    'Free up ${(_totalPct - 100).toStringAsFixed(1)}% first.',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        for (final cat in cashCats)
                          _BudgetCategoryRow(
                            category: cat,
                            controller: _controllers[cat.dbValue]!,
                            currentSpending:
                                monthExpensesByCategory[cat.dbValue] ?? 0,
                            effectiveSalary: effectiveSalary,
                            isSwile: false,
                            swileBalance: 0,
                          ),
                        // ── Swile Budget section ──────────────────────────
                        if (swileCats.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SectionHeader(
                            label: l10n.translate('swile_budget'),
                            icon: Icons.restaurant_outlined,
                            color: const Color(0xFF00A86B),
                          ),
                          const SizedBox(height: 4),
                          _SwileBalanceBadge(balance: swileBalance),
                          const SizedBox(height: 12),
                          for (final cat in swileCats)
                            _BudgetCategoryRow(
                              category: cat,
                              controller: _controllers[cat.dbValue]!,
                              currentSpending:
                                  monthExpensesByCategory[cat.dbValue] ?? 0,
                              effectiveSalary: effectiveSalary,
                              isSwile: true,
                              swileBalance: swileBalance,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_saving || isOver) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isOver ? Colors.grey : tokens.FarolColors.navy,
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
                            l10n.saveBudget,
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
      },
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─── Swile balance badge ──────────────────────────────────────────────────────

class _SwileBalanceBadge extends StatelessWidget {
  final double balance;

  const _SwileBalanceBadge({required this.balance});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF00A86B).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet,
              size: 13, color: Color(0xFF00A86B)),
          const SizedBox(width: 6),
          Text(
            'Swile: ${FinancialCalculatorService.formatBRL(balance)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Percentage bar ───────────────────────────────────────────────────────────

class _PercentageBar extends StatelessWidget {
  final double totalPct;
  final double remaining;
  final bool isOver;

  const _PercentageBar({
    required this.totalPct,
    required this.remaining,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barColor = isOver
        ? Colors.red
        : totalPct >= 90
            ? Colors.orange
            : tokens.FarolColors.navy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${totalPct.toStringAsFixed(1)}% used',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOver ? Colors.red : colors.onSurface,
                ),
              ),
              Text(
                isOver
                    ? '${(totalPct - 100).toStringAsFixed(1)}% over limit'
                    : '${remaining.toStringAsFixed(1)}% remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: isOver ? Colors.red : colors.onSurfaceSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (totalPct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.onSurfaceFaint.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category row ─────────────────────────────────────────────────────────────

class _BudgetCategoryRow extends StatelessWidget {
  final Category category;
  final TextEditingController controller;
  final double currentSpending;
  final double effectiveSalary;
  final bool isSwile;
  final double swileBalance;

  const _BudgetCategoryRow({
    required this.category,
    required this.controller,
    required this.currentSpending,
    required this.effectiveSalary,
    required this.isSwile,
    required this.swileBalance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final budgetAmount = double.tryParse(controller.text) ?? 0;
    final isOver = currentSpending > budgetAmount && budgetAmount > 0;

    Widget? badge;
    if (isSwile) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF00A86B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Swile',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00A86B),
          ),
        ),
      );
    } else if (budgetAmount > 0) {
      final pct =
          effectiveSalary > 0 ? (budgetAmount / effectiveSalary) * 100 : 0;
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceSoft,
          ),
        ),
      );
    }

    String? hintSuffix;
    if (isSwile && swileBalance > 0) {
      hintSuffix =
          '${l10n.translate('swile_balance')}: ${FinancialCalculatorService.formatBRL(swileBalance)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOver ? Colors.orange : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${l10n.translate('current_spending')}: ${FinancialCalculatorService.formatBRL(currentSpending)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: l10n.translate('budget_amount'),
              prefixText: 'R\$ ',
              prefixStyle: TextStyle(color: colors.onSurfaceSoft),
              helperText: hintSuffix,
              helperStyle:
                  const TextStyle(fontSize: 10, color: Color(0xFF00A86B)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
