// lib/features/dashboard/widgets/space_contributions_card.dart
//
// Dashboard card: shows a breakdown of the current user's space contributions
// for the active month (expenses linked to shared Spaces via the personal
// ledger bridge).  Hidden automatically when there are no linked contributions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/space_transaction.dart' show LedgerContribution;
import '../../../core/providers/providers.dart'
    show selectedMonthProvider, selectedYearProvider;
import '../../../core/providers/space_providers.dart'
    show ledgerContributionsProvider;

final _brlFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Visible only when the current user has at least one ledger-linked contribution
/// in the selected month.
class SpaceContributionsCard extends ConsumerWidget {
  const SpaceContributionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final year  = ref.watch(selectedYearProvider);
    final period = (year: year, month: month);

    final contribAsync = ref.watch(ledgerContributionsProvider(period));

    return contribAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (contributions) {
        if (contributions.isEmpty) return const SizedBox.shrink();
        return _SpaceContributionsContent(contributions: contributions);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Content
// ─────────────────────────────────────────────────────────────────

class _SpaceContributionsContent extends StatelessWidget {
  final List<LedgerContribution> contributions;

  const _SpaceContributionsContent({required this.contributions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group by space and sum amounts
    final bySpace = <String, _SpaceTotal>{};
    for (final c in contributions) {
      final key   = c.spaceId;
      final entry = bySpace[key];
      if (entry == null) {
        bySpace[key] = _SpaceTotal(
          name:   c.spaceName ?? 'Espaço',
          emoji:  c.spaceEmoji,
          amount: c.amount,
        );
      } else {
        bySpace[key] = entry.copyWithAmount(entry.amount + c.amount);
      }
    }

    final totals    = bySpace.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final grandTotal = totals.fold(0.0, (s, t) => s + t.amount);

    return Card(
      margin:       const EdgeInsets.symmetric(horizontal: 0),
      elevation:    0,
      color:        theme.colorScheme.surfaceContainerLow,
      shape:        RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contribuições a espaços',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize:   14,
                    color:      theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  _brlFmt.format(grandTotal),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize:   14,
                    color:      theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress bars + rows ─────────────────────────────
            ...totals.map((t) => _SpaceRow(
              total:      t,
              fraction:   grandTotal > 0 ? t.amount / grandTotal : 0,
              theme:      theme,
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Space row
// ─────────────────────────────────────────────────────────────────

class _SpaceRow extends StatelessWidget {
  final _SpaceTotal total;
  final double fraction;
  final ThemeData theme;

  const _SpaceRow({
    required this.total,
    required this.fraction,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (total.emoji != null)
                Text(total.emoji!, style: const TextStyle(fontSize: 14))
              else
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  total.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _brlFmt.format(total.amount),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:      theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:            fraction,
              minHeight:        4,
              backgroundColor:  theme.colorScheme.outlineVariant.withOpacity(0.3),
              valueColor:       AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Value object
// ─────────────────────────────────────────────────────────────────

class _SpaceTotal {
  final String  name;
  final String? emoji;
  final double  amount;

  const _SpaceTotal({
    required this.name,
    required this.emoji,
    required this.amount,
  });

  _SpaceTotal copyWithAmount(double newAmount) =>
      _SpaceTotal(name: name, emoji: emoji, amount: newAmount);
}
