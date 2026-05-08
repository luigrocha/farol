import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/recurring_rule.dart';
import '../../core/domain/services/recurring_detector.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/widgets/farol_snackbar.dart';

const _teal = Color(0xFF00897B);

class RecurringSuggestionsScreen extends ConsumerWidget {
  const RecurringSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(recurringCandidatesProvider);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Sugestões de recorrentes',
              style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Identifiquei padrões no seu histórico de gastos.\nConfirme os que forem recorrentes.',
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 16),
              candidatesAsync.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator())),
                error: (e, _) => Text('Erro: $e'),
                data: (List<RecurringRuleCandidate> candidates) {
                  if (candidates.isEmpty) {
                    return const _EmptyState();
                  }
                  return Column(
                    children: candidates
                        .map((c) => _CandidateTile(candidate: c))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Candidate tile ───────────────────────────────────────────────────────────

class _CandidateTile extends ConsumerStatefulWidget {
  const _CandidateTile({required this.candidate});
  final RecurringRuleCandidate candidate;

  @override
  ConsumerState<_CandidateTile> createState() => _CandidateTileState();
}

class _CandidateTileState extends ConsumerState<_CandidateTile> {
  bool _saving = false;
  bool _ignored = false;

  @override
  Widget build(BuildContext context) {
    if (_ignored) return const SizedBox.shrink();

    final c = widget.candidate;
    final confidencePct = (c.confidence * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name,
                    style: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${c.frequency.label}  ·  dia ${c.dayOfMonth}  ·  ${c.sourceExpenses.length} ocorrências',
                  style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                FinancialCalculatorService.formatBRL(c.baseAmount),
                style: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _teal),
              ),
              _ConfidenceBadge(pct: confidencePct),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _ignored = true),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Ignorar',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Confirmar',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final c = widget.candidate;
      final service = ref.read(recurringServiceProvider);
      final now = DateTime.now();

      final firstDate = c.sourceExpenses.first.transactionDate;
      final rule = RecurringRule(
        id: '',
        userId: '',
        name: c.name,
        categorySlug: c.category,
        baseAmount: c.baseAmount,
        frequency: c.frequency,
        dayOfMonth: c.dayOfMonth,
        startsOn: DateTime(firstDate.year, firstDate.month, c.dayOfMonth.clamp(1, 28)),
        paymentMethod: c.paymentMethod,
        isAutoDetected: true,
        detectionConfidence: c.confidence,
        createdAt: now,
        updatedAt: now,
      );

      await service.createRule(rule);
      if (mounted) {
        setState(() => _ignored = true); // hide after confirm
        context.showSuccessSnackBar('Recorrente "${c.name}" criado');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showErrorSnackBar(e);
      }
    }
  }
}

// ─── Confidence badge ─────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.pct});
  final int pct;

  @override
  Widget build(BuildContext context) {
    final color = pct >= 90 ? _teal : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$pct% confiança',
          style: GoogleFonts.manrope(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'Nenhum padrão recorrente encontrado\nno seu histórico.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}
