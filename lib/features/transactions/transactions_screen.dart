import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/enums.dart';
import '../../core/models/income.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/farol_dialogs.dart';
import '../../core/widgets/farol_snackbar.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/domain/auth_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quick_add_bottom_sheet.dart';
import 'edit_expense_bottom_sheet.dart';
import 'edit_income_bottom_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  bool _showCategories = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeRealtime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _unsubscribeRealtime();
    }
  }

  void _unsubscribeRealtime() {
    ref.read(incomeRepositoryProvider).unsubscribeRealtime();
    ref.read(expenseRepositoryProvider).unsubscribeRealtime();
  }

  bool get _onExpensesTab => _tabController.index == 0;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final filteredAsync = ref.watch(expensesProvider);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    ref.watch(fixedExpensePropagationProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            floating: true,
            title: Row(children: [
              _Avatar(),
              const SizedBox(width: 10),
              Text(
                '${AppLocalizations.of(context).months[month - 1]} $year',
                style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ]),
            actions: const [Icon(Icons.calendar_today, size: 22), SizedBox(width: 20)],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Gastos'),
                Tab(text: 'Ingresos'),
              ],
              labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500),
              indicatorColor: tokens.FarolColors.beam,
              labelColor: tokens.FarolColors.navy,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 0: Gastos ──
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(children: [
                    const _SearchBar(),
                    _FilterChips(
                      showCategories: _showCategories,
                      onToggleCategories: (v) => setState(() => _showCategories = v),
                    ),
                    const _TotalMonthlyHero(),
                    const SizedBox(height: 16),
                  ]),
                ),
                if (filteredAsync.isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (filteredAsync.hasError)
                  SliverFillRemaining(child: Center(child: Text('Erro: ${filteredAsync.error}')))
                else if (filteredExpenses.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('Nenhum gasto encontrado')))
                else ...[
                  SliverList(
                    delegate: _buildExpenseDelegate(filteredExpenses),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
            // ── Tab 1: Ingresos ──
            const _IncomeTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _onExpensesTab
              ? const QuickAddBottomSheet()
              : const _AddIncomeSheet(),
        ),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
      ),
    );
  }

  // Groups expenses once and builds the delegate from the same map instance,
  // preventing the RangeError that occurs when the list changes between the
  // childCount call and the builder call.
  SliverChildBuilderDelegate _buildExpenseDelegate(List<dynamic> expenses) {
    final grouped = _groupExpensesByDay(expenses);
    final dates = grouped.keys.toList();
    return SliverChildBuilderDelegate(
      (ctx, i) {
        final date = dates[i];
        final dayExpenses = grouped[date]!;
        return Column(children: [
          _DaySeparator(date: date, total: dayExpenses.fold(0.0, (s, e) => s + e.amount)),
          ...dayExpenses.map((e) => _TxRow(expense: e)),
        ]);
      },
      childCount: dates.length,
    );
  }

  Map<DateTime, List<dynamic>> _groupExpensesByDay(List<dynamic> expenses) {
    final Map<DateTime, List<dynamic>> grouped = {};
    for (final e in expenses) {
      final date = e.transactionDate as DateTime;
      grouped.putIfAbsent(DateTime(date.year, date.month, date.day), () => []).add(e);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }
}

// ─────────────────────────────────────────
// Income Tab
// ─────────────────────────────────────────
class _IncomeTab extends ConsumerWidget {
  const _IncomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(incomesProvider);
    final total = ref.watch(totalIncomeProvider);
    final colors = context.colors;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tokens.FarolColors.tide, Color(0xFF0F5C37)],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL INGRESOS',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Colors.white60)),
              const SizedBox(height: 6),
              _BRLBig(value: total, size: 32, color: Colors.white),
            ]),
          ),
        ),
        incomesAsync.when(
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erro: $e'))),
          data: (incomes) {
            if (incomes.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 56, color: colors.onSurfaceFaint),
                    const SizedBox(height: 12),
                    Text('Nenhum ingresso neste mês',
                        style: GoogleFonts.manrope(fontSize: 15, color: colors.onSurfaceSoft)),
                    const SizedBox(height: 6),
                    Text('Toca + para registrar salário, bonus, etc.',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceFaint)),
                  ]),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _IncomeRow(income: incomes[i]),
                childCount: incomes.length,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _IncomeRow extends ConsumerWidget {
  final Income income;
  const _IncomeRow({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final type = IncomeType.fromDb(income.incomeType);
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(l10n.delete, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) async => showConfirmDeleteDialog(context, title: l10n.confirmDelete, body: l10n.cannotUndo),
      onDismissed: (_) async {
        try {
          await ref.read(incomeNotifierProvider.notifier).delete(income.id);
          if (context.mounted) context.showSuccessSnackBar(l10n.transactionDeleted);
        } catch (e) {
          if (context.mounted) context.showErrorSnackBar(e);
        }
      },
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => EditIncomeBottomSheet(income: income),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: tokens.FarolColors.tide.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(type.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(type.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
              if (income.notes != null && income.notes!.isNotEmpty)
                Text(income.notes!,
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _BRLSmall(value: income.amount, size: 15, weight: FontWeight.w700, color: tokens.FarolColors.tide),
              Text(income.isNet ? 'Líquido' : 'Bruto',
                  style: TextStyle(fontSize: 11, color: colors.onSurfaceFaint)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Add Income Sheet
// ─────────────────────────────────────────
class _AddIncomeSheet extends ConsumerStatefulWidget {
  const _AddIncomeSheet();

  @override
  ConsumerState<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends ConsumerState<_AddIncomeSheet> {
  IncomeType _type = IncomeType.netSalary;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dependentsController = TextEditingController(text: '0');
  bool _isNet = true;
  bool _saving = false;
  NetSalaryResult? _calculatedNet;
  bool _showCalculation = false;

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
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      double? inssDeducted;
      double? irrfDeducted;
      if (_showCalculation && _calculatedNet != null) {
        inssDeducted = _calculatedNet!.inss;
        irrfDeducted = _calculatedNet!.irrf;
      }

      final month = ref.read(selectedMonthProvider);
      final year = ref.read(selectedYearProvider);
      await ref.read(incomeNotifierProvider.notifier).insert(
            month: month,
            year: year,
            incomeType: _type.dbValue,
            amount: amount,
            isNet: _isNet,
            inssDeducted: inssDeducted,
            irrfDeducted: irrfDeducted,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Novo Ingresso',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
            const SizedBox(height: 20),
            Text('Tipo', style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
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
                      child: Text('${t.emoji} ${t.label}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : colors.onSurface,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('Valor líquido (ya descontado INSS/IRRF)',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceMuted))),
              Switch(
                value: _isNet,
                onChanged: (v) => setState(() => _isNet = v),
                activeThumbColor: tokens.FarolColors.tide,
              ),
            ]),
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
                            'Dependentes (IRRF)',
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
                        label: const Text('Calcular líquido'),
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
                      'Desglose del salario',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.FarolColors.tide,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAddCalcRow('Bruto', _calculatedNet!.gross, colors.onSurface),
                    _buildAddCalcRow('INSS', -_calculatedNet!.inss, const Color(0xFFFF6B35)),
                    _buildAddCalcRow('IRRF', -_calculatedNet!.irrf, const Color(0xFFFF6B35)),
                    const Divider(height: 20),
                    _buildAddCalcRow('Líquido', _calculatedNet!.net, tokens.FarolColors.tide, bold: true),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _useNetValue,
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Usar valor líquido'),
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
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observación (opcional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: tokens.FarolColors.tide),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar ingresso'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAddCalcRow(String label, double value, Color color, {bool bold = false}) {
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

// ─────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────
class _Avatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).value;
    String initials = 'U';
    if (authState is AppAuthAuthenticated) {
      final name = authState.user.displayName ?? authState.user.email ?? '';
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
        initials = parts.first[0].toUpperCase();
      }
    }
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [tokens.FarolColors.tide, tokens.FarolColors.beam]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(99)),
      child: Row(children: [
        Icon(Icons.search, size: 18, color: colors.onSurfaceFaint),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _ctrl,
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            style: TextStyle(fontSize: 14, color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Buscar gasto...',
              hintStyle: TextStyle(fontSize: 14, color: colors.onSurfaceFaint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                      child: Icon(Icons.close, size: 16, color: colors.onSurfaceSoft),
                    )
                  : null,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Filter Chips
// ─────────────────────────────────────────
class _FilterChips extends ConsumerWidget {
  final bool showCategories;
  final ValueChanged<bool> onToggleCategories;
  const _FilterChips({required this.showCategories, required this.onToggleCategories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payFilter = ref.watch(txPayTypeFilterProvider);
    final catFilter = ref.watch(txCategoryFilterProvider);
    final categories = ref.watch(categoriesStreamProvider).value ?? [];

    const payChips = [
      ('all', 'Todas'),
      ('cash', 'Cash'),
      ('swile', 'Swile'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            scrollDirection: Axis.horizontal,
            children: [
              ...payChips.map((chip) {
                final active = payFilter == chip.$1;
                return _Chip(
                  label: chip.$2,
                  active: active,
                  onTap: () {
                    ref.read(txPayTypeFilterProvider.notifier).state = chip.$1;
                    ref.read(txCategoryFilterProvider.notifier).state = null;
                    if (chip.$1 != 'all') onToggleCategories(false);
                  },
                );
              }),
              _Chip(
                label: 'Categoría',
                active: showCategories || catFilter != null,
                onTap: () => onToggleCategories(!showCategories),
              ),
            ],
          ),
        ),
        if (showCategories && categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              scrollDirection: Axis.horizontal,
              children: categories.map((cat) {
                final active = catFilter == cat.dbValue;
                return _Chip(
                  label: '${cat.emoji} ${cat.name}',
                  active: active,
                  small: true,
                  onTap: () {
                    ref.read(txCategoryFilterProvider.notifier).state =
                        active ? null : cat.dbValue;
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final bool small;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18, vertical: small ? 6 : 10),
        decoration: BoxDecoration(
          color: active ? tokens.FarolColors.navy : colors.surfaceLowest,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : colors.onSurface,
            fontSize: small ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Total Hero
// ─────────────────────────────────────────
class _TotalMonthlyHero extends ConsumerWidget {
  const _TotalMonthlyHero();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(filteredTotalProvider);
    final byCategory = ref.watch(filteredByCategoryProvider);
    final payFilter = ref.watch(txPayTypeFilterProvider);
    final catsMap = ref.watch(categoriesMapProvider);
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    String label = 'TOTAL MENSUAL';
    if (payFilter == 'swile') label = 'TOTAL SWILE';
    if (payFilter == 'cash') label = 'TOTAL CASH';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244A72), tokens.FarolColors.navy],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Colors.white60)),
        const SizedBox(height: 6),
        _BRLBig(value: total, size: 32, color: Colors.white),
        const SizedBox(height: 18),
        ...sorted.take(3).map((e) {
          final cat = catsMap[e.key];
          final catLabel = cat?.name ?? e.key;
          final pct = total > 0 ? (e.value / total) : 0.0;
          return _HeroBar(
              label: catLabel,
              value: e.value,
              pct: pct,
              color: tokens.FarolColors.getCategoryColor(e.key));
        }),
      ]),
    );
  }
}

class _HeroBar extends StatelessWidget {
  final String label;
  final double value;
  final double pct;
  final Color color;
  const _HeroBar({required this.label, required this.value, required this.pct, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
          _BRLSmall(value: value, size: 13, weight: FontWeight.w600, color: Colors.white),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Day separator
// ─────────────────────────────────────────
class _DaySeparator extends StatelessWidget {
  final DateTime date;
  final double total;
  const _DaySeparator({required this.date, required this.total});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('DIA ${date.day}',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: colors.onSurfaceSoft,
                fontWeight: FontWeight.w700)),
        _BRLSmall(value: total, size: 12, color: colors.onSurfaceSoft, weight: FontWeight.w600),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Transaction row
// ─────────────────────────────────────────
class _TxRow extends ConsumerWidget {
  final dynamic expense;
  const _TxRow({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final catsMap = ref.watch(categoriesMapProvider);
    
    final dbCat = expense.category as String;
    final cat = catsMap[dbCat];
    final catLabel = cat?.name ?? dbCat;
    final catEmoji = cat?.emoji ?? '💰';

    final txDate = expense.transactionDate as DateTime;
    final timeLabel =
        '${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';

    final isSwile = (expense.payType as String) == 'Swile';

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(l10n.delete,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) async => showConfirmDeleteDialog(context,
          title: l10n.confirmDelete, body: l10n.cannotUndo),
      onDismissed: (_) async {
        try {
          await ref.read(expenseRepositoryProvider).delete(expense.id as int);
          if (context.mounted) context.showSuccessSnackBar(l10n.transactionDeleted);
        } catch (e) {
          if (context.mounted) context.showErrorSnackBar(e);
        }
      },
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => EditExpenseBottomSheet(expense: expense),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSwile
                    ? const Color(0xFFF97366).withValues(alpha: 0.15)
                    : colors.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  catEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  expense.storeDescription as String? ?? 'Gasto',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      height: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Text(catLabel, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: colors.onSurfaceFaint)),
                  const SizedBox(width: 6),
                  if (isSwile)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.FarolColors.tide.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('SWILE',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: tokens.FarolColors.tide,
                              letterSpacing: 0.5)),
                    )
                  else
                    Text(expense.payType as String? ?? 'Cash',
                        style: TextStyle(
                            fontSize: 10,
                            color: colors.onSurfaceSoft,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600)),
                  if (expense.isFixed as bool) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('FIXO',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue,
                              letterSpacing: 0.5)),
                    ),
                  ],
                  if (expense.isProjected as bool) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.4))),
                      child: const Text('PREVISTO',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _BRLSmall(value: expense.amount as double, size: 15, weight: FontWeight.w700),
              Text(timeLabel, style: TextStyle(fontSize: 11, color: colors.onSurfaceFaint)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BRL helpers
// ─────────────────────────────────────────
class _BRLBig extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  const _BRLBig({required this.value, required this.size, this.color});
  @override
  Widget build(BuildContext context) {
    const w = FontWeight.w800;
    final c = color ?? context.colors.onSurface;
    final parts = FinancialCalculatorService.formatBRL(value).split(',');
    final f = parts[0];
    final cents = parts.length > 1 ? parts[1] : '00';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('R\$ ',
            style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
        Text(f.replaceFirst('R\$ ', ''),
            style: GoogleFonts.manrope(
                fontSize: size, fontWeight: w, color: c, letterSpacing: -size * 0.028)),
        Text(',$cents',
            style: GoogleFonts.manrope(
                fontSize: size * 0.56, fontWeight: w, color: c.withValues(alpha: 0.85))),
      ],
    );
  }
}

class _BRLSmall extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  final FontWeight weight;
  const _BRLSmall(
      {required this.value, required this.size, this.color, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    return Text(
      FinancialCalculatorService.formatBRL(value),
      style: GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.colors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
