import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../recurring/recurring_suggestions_screen.dart';

const _amber = Color(0xFFF59E0B);

/// Shows a non-invasive banner when recurring patterns are detected.
/// Hidden if no candidates found or user dismissed.
class RecurringSuggestionsCard extends ConsumerWidget {
  const RecurringSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(recurringCandidatesProvider);

    return candidatesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (candidates) {
        if (candidates.isEmpty) return const SizedBox.shrink();

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _amber.withValues(alpha: 0.4)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RecurringSuggestionsScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_outline, size: 18, color: _amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Encontrei ${candidates.length} possível${candidates.length == 1 ? '' : 'is'} recorrente${candidates.length == 1 ? '' : 's'}',
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text('Toque para revisar e confirmar',
                        style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
                  ]),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ]),
            ),
          ),
        );
      },
    );
  }
}
