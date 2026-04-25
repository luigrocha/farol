import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/models/enums.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'quick_add_bottom_sheet.dart';
import 'edit_expense_bottom_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final expensesAsync = ref.watch(expensesProvider);
    ref.watch(fixedExpensePropagationProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(children: [
              _Avatar(),
              const SizedBox(width: 10),
              Text('${AppLocalizations.of(context).months[month-1]} $year', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            actions: const [Icon(Icons.calendar_today, size: 22), SizedBox(width: 20)],
          ),
          const SliverToBoxAdapter(child: Column(children: [
            _SearchBar(),
            _CategoryChips(),
            _TotalMonthlyHero(),
            SizedBox(height: 16),
          ])),
          expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) return const SliverFillRemaining(child: Center(child: Text('Nenhum gasto encontrado')));
              final grouped = _groupExpensesByDay(expenses);
              return SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                final date = grouped.keys.elementAt(i);
                final dayExpenses = grouped[date]!;
                return Column(children: [
                  _DaySeparator(date: date, total: dayExpenses.fold(0.0, (s, e) => s + e.amount)),
                  ...dayExpenses.map((e) => _TxRow(expense: e)),
                ]);
              }, childCount: grouped.length));
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erro: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const QuickAddBottomSheet()),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
      ),
    );
  }

  Map<DateTime, List<dynamic>> _groupExpensesByDay(List<dynamic> expenses) {
    final Map<DateTime, List<dynamic>> grouped = {};
    for (final e in expenses) {
      final date = e.transactionDate;
      grouped.putIfAbsent(DateTime(date.year, date.month, date.day), () => []).add(e);
    }
    return grouped;
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 36, height: 36, decoration: const BoxDecoration(gradient: LinearGradient(colors: [tokens.FarolColors.tide, tokens.FarolColors.beam]), shape: BoxShape.circle), child: const Center(child: Text('RA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))));
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(99)),
      child: Row(children: [
        Icon(Icons.search, size: 18, color: colors.onSurfaceFaint),
        const SizedBox(width: 10),
        Text('Buscar gasto...', style: TextStyle(fontSize: 14, color: colors.onSurfaceFaint)),
      ]),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chips = ['Todas', 'Categoría', 'Mes', 'Swile'];
    return SizedBox(height: 56, child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: chips.length,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: i == 0 ? tokens.FarolColors.navy : colors.surfaceLowest, borderRadius: BorderRadius.circular(99)),
        child: Center(child: Text(chips[i], style: TextStyle(color: i == 0 ? Colors.white : colors.onSurface, fontSize: 13, fontWeight: FontWeight.w600))),
      ),
    ));
  }
}

class _TotalMonthlyHero extends ConsumerWidget {
  const _TotalMonthlyHero();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cashExpensesProvider);
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF244A72), tokens.FarolColors.navy])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TOTAL MENSUAL', style: TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Colors.white60)),
        const SizedBox(height: 6),
        _BRLBig(value: total, size: 32, color: Colors.white),
        const SizedBox(height: 18),
        ...sorted.take(3).map((e) {
          String label; try { label = ExpenseCategory.fromDb(e.key).localizedLabel(context); } catch (_) { label = e.key; }
          final pct = total > 0 ? (e.value / total) : 0.0;
          return _HeroBar(label: label, value: e.value, pct: pct, color: tokens.FarolColors.getCategoryColor(e.key));
        }),
      ]),
    );
  }
}

class _HeroBar extends StatelessWidget {
  final String label; final double value; final double pct; final Color color;
  const _HeroBar({required this.label, required this.value, required this.pct, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
        _BRLSmall(value: value, size: 13, weight: FontWeight.w600, color: Colors.white),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(color))),
    ]));
  }
}

class _DaySeparator extends StatelessWidget {
  final DateTime date; final double total;
  const _DaySeparator({required this.date, required this.total});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('DIA ${date.day}', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: colors.onSurfaceSoft, fontWeight: FontWeight.w700)),
      _BRLSmall(value: total, size: 12, color: colors.onSurfaceSoft, weight: FontWeight.w600),
    ]));
  }
}

class _TxRow extends ConsumerWidget {
  final dynamic expense;
  const _TxRow({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    String catLabel;
    try { catLabel = ExpenseCategory.fromDb(expense.category).localizedLabel(context); } catch (_) { catLabel = expense.category; }

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
          Text(l10n.delete, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(l10n.cannotUndo),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        try {
          await ref.read(expenseRepositoryProvider).delete(expense.id as int);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.transactionDeleted)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.errorSaving}: $e'), backgroundColor: Colors.red.shade700),
            );
          }
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
            Container(width: 38, height: 38, decoration: BoxDecoration(color: colors.surfaceLow, shape: BoxShape.circle), child: Icon(Icons.shopping_bag_outlined, size: 18, color: colors.onSurfaceMuted)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.storeDescription ?? 'Gasto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface, height: 1.3)),
              const SizedBox(height: 4),
              Row(children: [
                Text(catLabel, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
                const SizedBox(width: 6),
                Text('•', style: TextStyle(color: colors.onSurfaceFaint)),
                const SizedBox(width: 6),
                if (expense.payType == 'Swile')
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: tokens.FarolColors.tide.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: const Text('SWILE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: tokens.FarolColors.tide, letterSpacing: 0.5)))
                else
                  Text(expense.payType ?? 'Cash', style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                if (expense.isFixed) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('FIXO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blue, letterSpacing: 0.5))),
                ],
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _BRLSmall(value: expense.amount, size: 15, weight: FontWeight.w700),
              Text('12:00', style: TextStyle(fontSize: 11, color: colors.onSurfaceFaint)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _BRLBig extends StatelessWidget {
  final double value; final double size; final Color? color;
  const _BRLBig({required this.value, required this.size, this.color});
  @override
  Widget build(BuildContext context) {
    const w = FontWeight.w800;
    final c = color ?? context.colors.onSurface;
    final f = FinancialCalculatorService.formatBRL(value).split(',')[0];
    final cents = FinancialCalculatorService.formatBRL(value).split(',')[1];
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('R\$ ', style: GoogleFonts.manrope(fontSize: size * 0.48, fontWeight: FontWeight.w500, color: c)),
      Text(f.replaceFirst('R\$ ', ''), style: GoogleFonts.manrope(fontSize: size, fontWeight: w, color: c, letterSpacing: -size * 0.028)),
      Text(',$cents', style: GoogleFonts.manrope(fontSize: size * 0.56, fontWeight: w, color: c.withOpacity(0.85))),
    ]);
  }
}

class _BRLSmall extends StatelessWidget {
  final double value; final double size; final Color? color; final FontWeight weight;
  const _BRLSmall({required this.value, required this.size, this.color, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    return Text(FinancialCalculatorService.formatBRL(value), style: GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? context.colors.onSurface, fontFeatures: const [FontFeature.tabularFigures()]));
  }
}
