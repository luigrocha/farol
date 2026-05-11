import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/member_display.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/workspace_providers.dart'
    show isSharedWorkspaceProvider, memberDisplayMapProvider;
import '../../../core/services/financial_calculator_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

/// Maps each author_user_id to their total spend for the selected month.
/// Only meaningful in shared workspaces — returns empty map in personal ones.
final _contributionProvider =
    Provider.autoDispose<Map<String, double>>((ref) {
  final expenses = ref.watch(realExpensesProvider).valueOrNull ?? [];
  final totals = <String, double>{};
  for (final e in expenses) {
    if (e.authorUserId == null) continue;
    totals[e.authorUserId!] =
        (totals[e.authorUserId!] ?? 0.0) + e.amount;
  }
  return totals;
});

// ── Widget ────────────────────────────────────────────────────────────────────

/// Horizontal stacked bar showing each member's spending share for the period.
/// Only rendered in shared workspaces. Returns [SizedBox.shrink] otherwise.
class ContributionBar extends ConsumerWidget {
  const ContributionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    if (!isShared) return const SizedBox.shrink();

    final contributions = ref.watch(_contributionProvider);
    final memberMap = ref.watch(memberDisplayMapProvider).valueOrNull ?? {};

    if (contributions.isEmpty) return const SizedBox.shrink();

    final total = contributions.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();

    // Sort entries by amount descending for a stable bar order
    final entries = contributions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who spent what',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // ── Stacked bar ──
            _StackedBar(entries: entries, memberMap: memberMap, total: total),
            const SizedBox(height: 12),
            // ── Legend ──
            ...entries.map(
              (e) => _LegendRow(
                userId: e.key,
                amount: e.value,
                share: e.value / total,
                display: memberMap[e.key],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stacked bar ───────────────────────────────────────────────────────────────

class _StackedBar extends StatelessWidget {
  const _StackedBar({
    required this.entries,
    required this.memberMap,
    required this.total,
  });

  final List<MapEntry<String, double>> entries;
  final Map<String, MemberDisplay> memberMap;
  final double total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: entries.map((e) {
            final color = memberMap[e.key]?.avatarColor ??
                avatarColorForUserId(e.key);
            final flex = (e.value / total * 1000).round();
            return Expanded(
              flex: flex,
              child: ColoredBox(color: color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Legend row ────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.userId,
    required this.amount,
    required this.share,
    required this.display,
  });

  final String userId;
  final double amount;
  final double share;
  final MemberDisplay? display;

  @override
  Widget build(BuildContext context) {
    final color =
        display?.avatarColor ?? avatarColorForUserId(userId);
    final name = display?.displayName ?? '${userId.substring(0, 8)}…';
    final percent = (share * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Percentage
          Text(
            '$percent%',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Text(
            FinancialCalculatorService.formatBRL(amount),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
