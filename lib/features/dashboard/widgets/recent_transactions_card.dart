import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final expensesAsync = ref.watch(expensesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Últimas Transacciones',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/transactions'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ver todas →',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.FarolColors.beam,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: _HeaderCell('DESCRIPCIÓN', colors),
                ),
                Expanded(
                  flex: 25,
                  child: _HeaderCell('CATEGORÍA', colors),
                ),
                Expanded(
                  flex: 20,
                  child: _HeaderCell('FECHA', colors),
                ),
                Expanded(
                  flex: 20,
                  child: _HeaderCell('VALOR', colors, align: TextAlign.end),
                ),
              ],
            ),
            const Divider(height: 12),
            expensesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (expenses) {
                final recent = expenses.take(5).toList();
                if (recent.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Nenhuma transação este mês.',
                        style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft),
                      ),
                    ),
                  );
                }
                return Column(
                  children: recent.map((e) => _TxRow(expense: e, colors: colors)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, this.colors, {this.align = TextAlign.start});
  final String label;
  final dynamic colors;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: colors.onSurfaceFaint,
        ),
      );
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.expense, required this.colors});
  final Expense expense;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final isSwile = expense.payType == 'Swile';
    final catLabel = expense.category;
    final day = expense.transactionDate.day;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 35,
            child: Text(
              expense.storeDescription ?? expense.category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 25,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    catLabel,
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expense.isFixed) ...[
                  const SizedBox(width: 4),
                  const _Badge('FIXO', Colors.blue),
                ] else if (isSwile) ...[
                  const SizedBox(width: 4),
                  const _Badge('SWILE', tokens.FarolColors.tide),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'Día $day',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              FinancialCalculatorService.formatBRL(expense.amount),
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      );
}
