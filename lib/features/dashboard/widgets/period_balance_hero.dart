import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../design/farol_colors.dart' as tokens;
import 'shared/brl_display.dart';

class PeriodBalanceHero extends ConsumerWidget {
  const PeriodBalanceHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(totalIncomeProvider);
    final expenses = ref.watch(cashExpensesProvider);
    final balance = ref.watch(monthlyBalanceProvider);
    final isPositive = balance >= 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/patrimonio'),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPositive
                ? [const Color(0xFF1A4A3A), const Color(0xFF0D2B23)]
                : [const Color(0xFF4A2A1A), const Color(0xFF2B150D)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'BALANCE DEL PERÍODO',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: Colors.white30),
              ],
            ),
            const SizedBox(height: 6),
            BrlBig(value: balance, size: 36, color: Colors.white),
            const SizedBox(height: 16),
            Row(
              children: [
                MiniStat(
                  label: 'Receitas',
                  value: income,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                MiniStat(
                  label: 'Despesas',
                  value: expenses,
                  color: tokens.FarolColors.coral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
