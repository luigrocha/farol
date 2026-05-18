import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/ds_tokens.dart';

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final expensesAsync = ref.watch(expensesProvider);

    return DSCard(
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Últimas Transações',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              DSTextButton(
                label: 'Ver todas',
                onTap: () => Navigator.pushNamed(context, '/transactions'),
                icon: Icons.chevron_right_rounded,
              ),
            ],
          ),

          const SizedBox(height: DSSpacing.md),

          // ── Table header ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(flex: 35, child: _HeaderCell('DESCRIÇÃO', colors)),
              Expanded(flex: 25, child: _HeaderCell('CATEGORIA', colors)),
              Expanded(flex: 20, child: _HeaderCell('DATA', colors)),
              Expanded(
                flex: 20,
                child: _HeaderCell('VALOR', colors, align: TextAlign.end),
              ),
            ],
          ),

          const SizedBox(height: DSSpacing.xs),
          Divider(
            height: 1,
            color: colors.onSurfaceFaint.withValues(alpha: 0.3),
          ),
          const SizedBox(height: DSSpacing.xs),

          // ── Rows ────────────────────────────────────────────────────────
          expensesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: DSSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.xl),
              child: Center(
                child: Text(
                  'Não foi possível carregar as transações.',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (expenses) {
              final recent = expenses.take(5).toList();
              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: DSSpacing.xl),
                  child: Center(
                    child: Text(
                      'Nenhuma transação este mês.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceSoft,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: recent
                    .map((e) => _TxRow(expense: e))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, this.colors, {this.align = TextAlign.start});

  final String label;
  final FarolColors colors;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: colors.onSurfaceFaint,
        ),
      );
}

class _TxRow extends StatefulWidget {
  const _TxRow({required this.expense});
  final Expense expense;

  @override
  State<_TxRow> createState() => _TxRowState();
}

class _TxRowState extends State<_TxRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSwile = widget.expense.payType == 'Swile';
    final day = widget.expense.transactionDate.day;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: DSDuration.fast,
        padding: const EdgeInsets.symmetric(
          vertical: DSSpacing.sm,
          horizontal: DSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFF1B3A5C).withValues(alpha: 0.025))
              : Colors.transparent,
          borderRadius: DSRadius.xsBR,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 35,
              child: Text(
                widget.expense.storeDescription ?? widget.expense.category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
                      widget.expense.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.expense.isFixed) ...[
                    const SizedBox(width: 4),
                    const _Badge('FIXO', Color(0xFF3B6A9C)),
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
                'Dia $day',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft),
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                FinancialCalculatorService.formatBRL(widget.expense.amount),
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
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: DSRadius.xsBR,
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
