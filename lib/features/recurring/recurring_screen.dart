import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/recurring_rule.dart';
import '../../core/domain/entities/recurring_occurrence.dart';
import '../../core/i18n/app_localizations.dart';
import '../../design/ds_tokens.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/widgets/farol_snackbar.dart';
import 'add_recurring_bottom_sheet.dart';
import '../../core/providers/workspace_providers.dart'
    show canWriteProvider, isSharedWorkspaceProvider, memberDisplayMapProvider;
import '../../core/widgets/member_chip.dart';
import '../../design/branding/branding.dart';
import '../../design/layout/layout.dart';

const _teal = Color(0xFF00897B);

// ─── Screen ──────────────────────────────────────────────────────────────────

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});
  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  _Filter _filter = _Filter.active;

  static const double _contentMaxWidth = FarolBreakpoints.contentMedium;

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(recurringRulesStreamProvider);
    final isDesktop = FarolBreakpoints.isDesktop(context);

    final content = SliverList(
      delegate: SliverChildListDelegate([
        _HeroCard(rulesAsync: rulesAsync),
        const SizedBox(height: 16),
        _FilterChips(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 12),
        rulesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Center(child: Text(context.l10n.recurringError(e.toString()))),
          data: (all) {
            final rules = _filtered(all, _filter);
            if (rules.isEmpty) return _EmptyState(filter: _filter);
            return Column(
              children: rules.map((r) => _RuleTile(rule: r)).toList(),
            );
          },
        ),
        const FarolBottomPadding(),
      ]),
    );

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(context.l10n.recurringScreenTitle,
              style: GoogleFonts.manrope(
                  fontSize: 17, fontWeight: FontWeight.w800)),
          actions: const [
            FarolMark(
                size: FarolBrand.markSizeCompact,
                variant: FarolLogoVariant.dark),
            SizedBox(width: 16),
          ],
        ),
        if (isDesktop)
          SliverLayoutBuilder(
            builder: (_, constraints) {
              final hPad =
                  ((constraints.crossAxisExtent - _contentMaxWidth) / 2)
                      .clamp(16.0, double.infinity);
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                sliver: content,
              );
            },
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: content,
          ),
      ]),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          if (!ref.watch(canWriteProvider)) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: 'fab_recurring',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddRecurringBottomSheet(),
            ),
            backgroundColor: _teal,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  List<RecurringRule> _filtered(List<RecurringRule> all, _Filter f) =>
      switch (f) {
        _Filter.active =>
          all.where((r) => r.status == RecurringStatus.active).toList(),
        _Filter.paused =>
          all.where((r) => r.status == RecurringStatus.paused).toList(),
        _Filter.cancelled =>
          all.where((r) => r.status == RecurringStatus.cancelled).toList(),
      };
}

enum _Filter { active, paused, cancelled }

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.rulesAsync});
  final AsyncValue<List<RecurringRule>> rulesAsync;

  @override
  Widget build(BuildContext context) {
    final active = rulesAsync.value
            ?.where((r) => r.status == RecurringStatus.active)
            .toList() ??
        [];
    final monthlyTotal =
        active.fold<double>(0, (sum, r) => sum + _monthlyEquivalent(r));

    return DSCard(
      color: _teal,
      radius: DSRadius.lg,
      padding: const EdgeInsets.all(DSSpacing.xl),
      enableHover: false,
      child: Builder(builder: (context) {
        final l10n = context.l10n;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.recurringTotalMonthly,
              style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: DSSpacing.xs),
          Text(
            FinancialCalculatorService.formatBRL(monthlyTotal),
            style: GoogleFonts.manrope(
                fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            l10n.recurringActiveCount(active.length),
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.white70),
          ),
        ]);
      }),
    );
  }

  double _monthlyEquivalent(RecurringRule r) => switch (r.frequency) {
        RecurringFrequency.weekly => r.baseAmount * 4.33,
        RecurringFrequency.biweekly => r.baseAmount * 2.17,
        RecurringFrequency.monthly => r.baseAmount,
        RecurringFrequency.quarterly => r.baseAmount / 3,
        RecurringFrequency.semiannual => r.baseAmount / 6,
        RecurringFrequency.yearly => r.baseAmount / 12,
      };
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});
  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Filter.values.map((f) {
        final l10n = context.l10n;
        final label = switch (f) {
          _Filter.active => l10n.recurringFilterActive,
          _Filter.paused => l10n.recurringFilterPaused,
          _Filter.cancelled => l10n.recurringFilterCancelled,
        };
        final isSelected = f == selected;
        return Padding(
          padding: const EdgeInsets.only(right: DSSpacing.sm),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(f),
            selectedColor: _teal,
            shape: RoundedRectangleBorder(borderRadius: DSRadius.fullBR),
            labelStyle: GoogleFonts.manrope(
              fontSize: 12,
              color: isSelected ? Colors.white : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Rule tile ────────────────────────────────────────────────────────────────

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule});
  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShared = ref.watch(isSharedWorkspaceProvider);
    final memberMap = ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
    final author = isShared && rule.authorUserId != null
        ? memberMap[rule.authorUserId]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.sm + 2),
      child: DSCard(
        onTap: () => _showDetail(context, ref),
        padding: const EdgeInsets.all(DSSpacing.lg),
        child: Row(children: [
          _CategoryIcon(slug: rule.categorySlug),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rule.name,
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${rule.frequency.localizedLabel(context.l10n.locale.languageCode)}  ·  dia ${rule.dayOfMonth ?? '—'}',
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (author != null) ...[
                const SizedBox(height: DSSpacing.xs),
                MemberChip(member: author),
              ],
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              FinancialCalculatorService.formatBRL(rule.baseAmount),
              style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _teal),
            ),
            const SizedBox(height: DSSpacing.xs),
            _StatusBadge(status: rule.status),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RuleDetailSheet(rule: rule),
    );
  }
}

// ─── Detail sheet ─────────────────────────────────────────────────────────────

class _RuleDetailSheet extends ConsumerWidget {
  const _RuleDetailSheet({required this.rule});
  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrencesAsync = ref.watch(_ruleOccurrencesProvider(rule.id));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
        ),
        padding: EdgeInsets.fromLTRB(
            DSSpacing.xl, DSSpacing.md, DSSpacing.xl, bottom + DSSpacing.xxl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.grey.shade300,
                  borderRadius: DSRadius.xsBR),
            ),
          ),
          const SizedBox(height: DSSpacing.lg),
          Row(children: [
            _CategoryIcon(slug: rule.categorySlug),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.name,
                        style: GoogleFonts.manrope(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(
                      '${rule.frequency.localizedLabel(context.l10n.locale.languageCode)}  ·  ${FinancialCalculatorService.formatBRL(rule.baseAmount)}',
                      style:
                          GoogleFonts.manrope(fontSize: 13, color: Colors.grey),
                    ),
                  ]),
            ),
            _StatusBadge(status: rule.status),
          ]),
          const SizedBox(height: 20),
          _ActionRow(rule: rule),
          const SizedBox(height: 20),
          Text(context.l10n.recurringUpcomingOccurrences,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Expanded(
            child: occurrencesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(context.l10n.recurringError(e.toString())),
              data: (occ) {
                final pending = occ
                    .where((o) => o.status.name == 'pending')
                    .take(6)
                    .toList();
                if (pending.isEmpty) {
                  return Center(
                    child: Text(context.l10n.recurringNoPending,
                        style: GoogleFonts.manrope(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  controller: ctrl,
                  itemCount: pending.length,
                  itemBuilder: (_, i) =>
                      _OccurrenceTile(occurrence: pending[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Action row (edit / pause / cancel) ──────────────────────────────────────

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.rule});
  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Row(children: [
      _ActionBtn(
        icon: Icons.edit_outlined,
        label: l10n.recurringActionEdit,
        onTap: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddRecurringBottomSheet(editRule: rule),
          );
        },
      ),
      const SizedBox(width: 8),
      if (rule.status == RecurringStatus.active)
        _ActionBtn(
          icon: Icons.pause_outlined,
          label: l10n.recurringActionPause,
          onTap: () async {
            Navigator.pop(context);
            await ref.read(recurringServiceProvider).pauseRule(rule.id);
            if (context.mounted)
              context.showSuccessSnackBar(context.l10n.recurringPausedSnack);
          },
        ),
      if (rule.status == RecurringStatus.paused) ...[
        _ActionBtn(
          icon: Icons.play_arrow_outlined,
          label: l10n.recurringActionResume,
          onTap: () async {
            Navigator.pop(context);
            await ref.read(recurringServiceProvider).resumeRule(rule.id);
            if (context.mounted)
              context.showSuccessSnackBar(context.l10n.recurringResumedSnack);
          },
        ),
      ],
      const SizedBox(width: 8),
      _ActionBtn(
        icon: Icons.cancel_outlined,
        label: l10n.recurringActionCancel,
        color: Colors.red,
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(ctx.l10n.recurringCancelDialogTitle),
              content: Text(ctx.l10n.recurringCancelDialogBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(ctx.l10n.recurringCancelDialogNo)),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(ctx.l10n.recurringActionCancel),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          if (!context.mounted) return;
          Navigator.pop(context);
          await ref.read(recurringServiceProvider).cancelRule(rule.id);
          if (context.mounted)
            context.showSuccessSnackBar(context.l10n.recurringCancelledSnack);
        },
      ),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _teal;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: c),
      label: Text(label, style: GoogleFonts.manrope(fontSize: 12, color: c)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.md, vertical: DSSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: DSRadius.smBR),
      ),
    );
  }
}

// ─── Occurrence tile ──────────────────────────────────────────────────────────

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.occurrence});
  final RecurringOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final d = occurrence.scheduledDate;
    final label =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final overdue = occurrence.isOverdue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined,
            size: 14, color: overdue ? Colors.red : Colors.grey),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 13,
                color: overdue ? Colors.red : null,
                fontWeight: overdue ? FontWeight.w600 : FontWeight.w500)),
        const Spacer(),
        Text(FinancialCalculatorService.formatBRL(occurrence.expectedAmount),
            style:
                GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Category icon ────────────────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({this.slug});
  final String? slug;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.12),
        borderRadius: DSRadius.smBR,
      ),
      child: Icon(_iconFor(slug), size: 20, color: _teal),
    );
  }

  IconData _iconFor(String? slug) => switch (slug) {
        'moradia' || 'housing' => Icons.home_outlined,
        'alimentacao' || 'food' => Icons.restaurant_outlined,
        'transporte' || 'transport' => Icons.directions_car_outlined,
        'saude' || 'health' => Icons.favorite_border_outlined,
        'educacao' || 'education' => Icons.school_outlined,
        'lazer' || 'leisure' => Icons.movie_outlined,
        'streaming' => Icons.play_circle_outline,
        _ => Icons.repeat_rounded,
      };
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RecurringStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      RecurringStatus.active => (l10n.recurringStatusActive, _teal),
      RecurringStatus.paused => (l10n.recurringStatusPaused, Colors.orange),
      RecurringStatus.cancelled => (l10n.recurringStatusCancelled, Colors.red),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DSSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DSRadius.fullBR,
      ),
      child: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    return const FarolEmptyState(type: FarolEmptyStateType.recurring);
  }
}

// ─── Provider: occurrences by rule ────────────────────────────────────────────

final _ruleOccurrencesProvider = FutureProvider.autoDispose
    .family<List<RecurringOccurrence>, String>((ref, ruleId) async {
  return ref.watch(recurringOccurrencesRepositoryProvider).getByRule(ruleId);
});
