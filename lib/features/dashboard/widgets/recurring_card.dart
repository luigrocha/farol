import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../recurring/recurring_screen.dart';

const _teal = Color(0xFF00897B);

class RecurringCard extends ConsumerWidget {
  const RecurringCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pendingAsync = ref.watch(pendingRecurringOccurrencesProvider);
    final activeRules = ref.watch(activeRecurringRulesProvider);

    if (activeRules.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecurringScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.repeat_rounded, size: 18, color: _teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.recurringCardTitle,
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ]),
            const SizedBox(height: 12),
            pendingAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const SizedBox.shrink(),
              data: (pending) {
                final total =
                    pending.fold<double>(0, (s, o) => s + o.expectedAmount);
                return Row(children: [
                  _Stat(
                    label: l10n.recurringPending,
                    value: '${pending.length}',
                    color: pending.any((o) => o.isOverdue) ? Colors.red : _teal,
                  ),
                  const SizedBox(width: 24),
                  _Stat(
                    label: l10n.recurringTotalExpected,
                    value: FinancialCalculatorService.formatBRL(total),
                    color: _teal,
                  ),
                  const Spacer(),
                  _Stat(
                    label: l10n.recurringActiveRules,
                    value: '${activeRules.length}',
                    color: Colors.grey,
                  ),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey)),
        ],
      );
}
