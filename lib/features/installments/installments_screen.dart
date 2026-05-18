import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/installment_plan.dart';
import '../../core/domain/entities/installment_payment.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../design/ds_tokens.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/farol_colors.dart';
import '../../core/providers/workspace_providers.dart'
    show canWriteProvider, isSharedWorkspaceProvider, memberDisplayMapProvider;
import '../../core/widgets/member_chip.dart';
import 'add_installment_bottom_sheet.dart';
import '../../core/widgets/farol_dialogs.dart';
import '../../core/widgets/farol_snackbar.dart';
import '../../design/branding/branding.dart';

const _purple = Color(0xFF6B3FA0);

// ─── Screen ──────────────────────────────────────────────────────────────────

class InstallmentsScreen extends ConsumerStatefulWidget {
  const InstallmentsScreen({super.key});
  @override
  ConsumerState<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends ConsumerState<InstallmentsScreen> {
  _Filter _filter = _Filter.active;

  static const double _desktopBreakpoint = 800;
  static const double _contentMaxWidth = 900;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(installmentPlansStreamProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    final content = SliverList(
      delegate: SliverChildListDelegate([
        _HeroCard(plansAsync: plansAsync),
        const SizedBox(height: 16),
        _FilterChips(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 12),
        plansAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text('${context.l10n.error}: $e')),
          data: (all) {
            final plans = _filtered(all, _filter);
            if (plans.isEmpty) return _EmptyState(filter: _filter);
            return Column(
              children: plans.map((p) => _PlanTile(plan: p)).toList(),
            );
          },
        ),
        const SizedBox(height: 80),
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
          title: Text(context.l10n.installments,
              style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
          actions: const [
            FarolMark(size: FarolBrand.markSizeCompact, variant: FarolLogoVariant.dark),
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
            heroTag: 'fab_installments',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddInstallmentBottomSheet(),
            ),
            backgroundColor: tokens.FarolColors.beam,
            child: const Icon(Icons.add, color: tokens.FarolColors.navy),
          );
        },
      ),
    );
  }

  List<InstallmentPlan> _filtered(List<InstallmentPlan> all, _Filter f) {
    switch (f) {
      case _Filter.active:
        return all.where((p) => p.isActive).toList();
      case _Filter.completed:
        return all.where((p) => p.isComplete).toList();
      case _Filter.all:
        return all;
    }
  }
}

enum _Filter { active, completed, all }

// ─── Hero card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final AsyncValue<List<InstallmentPlan>> plansAsync;
  const _HeroCard({required this.plansAsync});

  @override
  Widget build(BuildContext context) {
    final plans = plansAsync.value?.where((p) => p.isActive).toList() ?? [];
    final monthly =
        plans.fold(0.0, (s, p) => s + p.installmentAmount);
    final remaining =
        plans.fold(0.0, (s, p) => s + p.remainingAmount);

    return DSCard(
      radius: DSRadius.lg,
      padding: const EdgeInsets.all(DSSpacing.xxl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D1B69), Color(0xFF6B3FA0)],
      ),
      enableHover: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.installmentsMonthlyCommitment,
            style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
                color: Colors.white60)),
        const SizedBox(height: DSSpacing.sm - 2),
        _BRLBig(value: monthly, size: 32, color: Colors.white),
        const SizedBox(height: DSSpacing.xl - 2),
        Row(children: [
          _HeroPill(label: context.l10n.installmentsActivePlans, value: '${plans.length}'),
          const SizedBox(width: DSSpacing.sm),
          _HeroPill(
              label: context.l10n.remainingBalance,
              value: FinancialCalculatorService.formatBRL(remaining)),
        ]),
      ]),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label, value;
  const _HeroPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: DSSpacing.md),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: DSRadius.mdBR,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final _Filter selected;
  final ValueChanged<_Filter> onChanged;
  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(children: [
      _Chip(label: l10n.installmentsFilterActive, value: _Filter.active, selected: selected, onTap: onChanged),
      const SizedBox(width: 8),
      _Chip(label: l10n.installmentsFilterCompleted, value: _Filter.completed, selected: selected, onTap: onChanged),
      const SizedBox(width: 8),
      _Chip(label: l10n.installmentsFilterAll, value: _Filter.all, selected: selected, onTap: onChanged),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final _Filter value, selected;
  final ValueChanged<_Filter> onTap;
  const _Chip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: DSDuration.normal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _purple : context.colors.surfaceLowest,
          borderRadius: DSRadius.fullBR,
          border: Border.all(
              color: active ? _purple : context.colors.surfaceLow),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : context.colors.onSurfaceSoft)),
      ),
    );
  }
}

// ─── Plan tile ───────────────────────────────────────────────────────────────

class _PlanTile extends ConsumerWidget {
  final InstallmentPlan plan;
  const _PlanTile({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final nextDue = _nextDueDate();
    final isShared = ref.watch(isSharedWorkspaceProvider);
    final memberMap = ref.watch(memberDisplayMapProvider).valueOrNull ?? {};
    final author = isShared && plan.authorUserId != null
        ? memberMap[plan.authorUserId]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.sm + 2),
      child: DSCard(
        onTap: () => _openDetail(context, ref),
        radius: DSRadius.lg,
        padding: const EdgeInsets.all(DSSpacing.lg),
        color: colors.surfaceLowest,
        child: Column(children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.12),
                borderRadius: DSRadius.mdBR,
              ),
              child: const Center(
                  child: Text('💳', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.description,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      _ProgressBadge(
                          paid: plan.paidCount,
                          total: plan.numInstallments),
                      if (nextDue != null) ...[
                        const SizedBox(width: DSSpacing.sm - 2),
                        Icon(Icons.schedule,
                            size: 10, color: colors.onSurfaceFaint),
                        const SizedBox(width: 2),
                        Text(_fmtDate(nextDue),
                            style: TextStyle(
                                fontSize: 10, color: colors.onSurfaceFaint)),
                      ],
                    ]),
                  ]),
            ),
            const SizedBox(width: DSSpacing.sm + 2),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _BRLSmall(value: plan.installmentAmount, size: 14),
              const SizedBox(height: 2),
              Text(context.l10n.installmentsPerInstallment,
                  style: TextStyle(
                      fontSize: 10, color: colors.onSurfaceFaint)),
            ]),
          ]),
          const SizedBox(height: DSSpacing.md),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                  context.l10n.installmentsPaidOf(plan.paidCount, plan.numInstallments),
                  style:
                      TextStyle(fontSize: 10, color: colors.onSurfaceSoft)),
              Text(
                  context.l10n.installmentsRemainingAmount(FinancialCalculatorService.formatBRL(plan.remainingAmount)),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceSoft)),
            ]),
            const SizedBox(height: DSSpacing.sm - 2),
            DSProgressBar(
              value: plan.progressPercent,
              height: 5,
              color: plan.isComplete ? Colors.green : _purple,
              backgroundColor: _purple.withValues(alpha: 0.12),
            ),
            // Attribution — shared workspaces only
            if (author != null) ...[
              const SizedBox(height: DSSpacing.sm),
              MemberChip(member: author),
            ],
          ]),
        ]),
      ),
    );
  }

  DateTime? _nextDueDate() {
    if (plan.paidCount >= plan.numInstallments) return null;
    return plan.dueDateFor(plan.paidCount + 1);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  void _openDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlanDetailSheet(plan: plan),
    );
  }
}

// ─── Plan detail sheet ────────────────────────────────────────────────────────

class _PlanDetailSheet extends ConsumerStatefulWidget {
  final InstallmentPlan plan;
  const _PlanDetailSheet({required this.plan});
  @override
  ConsumerState<_PlanDetailSheet> createState() => _PlanDetailSheetState();
}

class _PlanDetailSheetState extends ConsumerState<_PlanDetailSheet> {
  bool _loading = false;
  List<InstallmentPayment>? _payments;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await ref
        .read(installmentPaymentRepositoryProvider)
        .getByPlan(widget.plan.id);
    if (mounted) setState(() => _payments = payments);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plan = widget.plan;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    // Find next pending payment
    final nextPending = _payments?.firstWhere(
        (p) => p.isPending,
        orElse: () => _payments!.first);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(DSSpacing.xl, DSSpacing.md, DSSpacing.xl, bottom + DSSpacing.xxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: colors.surfaceLow,
                    borderRadius: DSRadius.xsBR))),
        const SizedBox(height: 20),

        // Header
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.12),
                borderRadius: DSRadius.mdBR),
            child: const Center(
                child: Text('💳', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.description,
                style: GoogleFonts.manrope(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            _ProgressBadge(
                paid: plan.paidCount, total: plan.numInstallments),
          ])),
        ]),
        const SizedBox(height: 16),

        // Progress bar
        DSProgressBar(
          value: plan.progressPercent,
          height: 8,
          color: plan.isComplete ? Colors.green : _purple,
          backgroundColor: _purple.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(context.l10n.installmentsPctComplete((plan.progressPercent * 100).toInt()),
              style:
                  TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
          Text(
              context.l10n.installmentsRemainingPayments(plan.remainingPayments),
              style:
                  TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
        ]),
        const SizedBox(height: 16),

        // Stats row
        Container(
          padding: const EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
              color: colors.surfaceLowest,
              borderRadius: DSRadius.lgBR),
          child: Row(children: [
            _StatBox(
                label: context.l10n.installmentsPerInstallmentLabel,
                value: FinancialCalculatorService.formatBRL(
                    plan.installmentAmount),
                color: _purple),
            _StatDivider(),
            _StatBox(
                label: context.l10n.remaining.toUpperCase(),
                value: FinancialCalculatorService.formatBRL(
                    plan.remainingAmount),
                color: colors.onSurface),
            _StatDivider(),
            _StatBox(
                label: context.l10n.total.toUpperCase(),
                value: FinancialCalculatorService.formatBRL(plan.totalAmount),
                color: colors.onSurface),
          ]),
        ),
        const SizedBox(height: 16),

        // Payment timeline
        if (_payments != null && _payments!.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(context.l10n.installments,
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _payments!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) =>
                  _PaymentRow(payment: _payments![i]),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_payments == null) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
        ],

        // Actions
        if (!plan.isComplete && nextPending != null &&
            nextPending.isPending) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : () => _pay(nextPending),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                nextPending.installmentNum >= plan.numInstallments
                    ? context.l10n.installmentsBtnComplete
                    : context.l10n.installmentsBtnRegisterNth(
                        '${nextPending.installmentNum}',
                        FinancialCalculatorService.formatBRL(nextPending.amount)),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: DSRadius.mdBR),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _skip(nextPending),
              icon: const Icon(Icons.skip_next_outlined, size: 18),
              label: Text(
                  context.l10n.installmentsBtnSkipNth('${nextPending.installmentNum}'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurfaceSoft,
                side: BorderSide(color: colors.surfaceLow),
                shape: RoundedRectangleBorder(
                    borderRadius: DSRadius.mdBR),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Delete
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(context.l10n.installmentsBtnDeletePlan,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _pay(InstallmentPayment payment) async {
    setState(() => _loading = true);
    try {
      await ref.read(installmentServiceProvider).payInstallment(
            payment: payment,
            plan: widget.plan,
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(installmentPlansStreamProvider);
      ref.invalidate(activeInstallmentPlansProvider);
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(
            payment.installmentNum >= widget.plan.numInstallments
                ? context.l10n.installmentsCompletedSnack(widget.plan.description)
                : context.l10n.installmentsRegisteredSnack('${payment.installmentNum}'));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip(InstallmentPayment payment) async {
    setState(() => _loading = true);
    try {
      await ref.read(installmentServiceProvider).skipInstallment(payment);
      await _loadPayments();
      if (mounted) {
        context.showSuccessSnackBar(
            context.l10n.installmentsSkippedSnack('${payment.installmentNum}'));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: context.l10n.installmentsPlanTitle,
      body: context.l10n.installmentsDeleteConfirm(widget.plan.description),
    );
    if (confirmed && context.mounted) {
      try {
        await ref
            .read(installmentPlanRepositoryProvider)
            .delete(widget.plan.id);
        ref.invalidate(installmentPlansStreamProvider);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) context.showErrorSnackBar(e);
      }
    }
  }
}

// ─── Payment row (timeline) ───────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final InstallmentPayment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPaid = payment.isPaid;
    final isSkipped = payment.status == 'skipped';
    final isOverdue = payment.isOverdue;

    Color dotColor;
    IconData dotIcon;
    if (isPaid) {
      dotColor = Colors.green;
      dotIcon = Icons.check_circle;
    } else if (isSkipped) {
      dotColor = colors.onSurfaceFaint;
      dotIcon = Icons.remove_circle_outline;
    } else if (isOverdue) {
      dotColor = Colors.orange;
      dotIcon = Icons.warning_amber_rounded;
    } else {
      dotColor = _purple.withValues(alpha: 0.4);
      dotIcon = Icons.radio_button_unchecked;
    }

    return Row(children: [
      Icon(dotIcon, size: 16, color: dotColor),
      const SizedBox(width: 8),
      Text('${payment.installmentNum}ª',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPaid ? Colors.green : colors.onSurface)),
      const SizedBox(width: 8),
      Text(_fmtDate(payment.dueDate),
          style:
              TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
      const Spacer(),
      Text(FinancialCalculatorService.formatBRL(payment.amount),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPaid ? Colors.green : colors.onSurface)),
      if (isSkipped)
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(context.l10n.installmentsSkippedLabel,
              style: TextStyle(
                  fontSize: 9,
                  color: colors.onSurfaceFaint,
                  fontWeight: FontWeight.w600)),
        ),
    ]);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Filter filter;
  const _EmptyState({required this.filter});
  @override
  Widget build(BuildContext context) {
    return const FarolEmptyState(type: FarolEmptyStateType.installments);
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _ProgressBadge extends StatelessWidget {
  final int paid, total;
  const _ProgressBadge({required this.paid, required this.total});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.1),
        borderRadius: DSRadius.xsBR,
      ),
      child: Text(context.l10n.installmentsPaidOf(paid, total),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _purple,
              letterSpacing: 0.3)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: [
      Text(label,
          style: TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceFaint)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()]),
          overflow: TextOverflow.ellipsis),
    ]));
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: context.colors.surfaceLow);
}

class _BRLBig extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  const _BRLBig({required this.value, required this.size, this.color});
  @override
  Widget build(BuildContext context) {
    const w = FontWeight.w800;
    final c = color ?? context.colors.onSurface;
    final parts = FinancialCalculatorService.formatBRL(value).split(',');
    final intPart = parts[0].replaceFirst('R\$ ', '');
    final centsPart = parts.length > 1 ? parts[1] : '00';
    return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('R\$ ',
              style: GoogleFonts.manrope(
                  fontSize: size * 0.48,
                  fontWeight: FontWeight.w500,
                  color: c)),
          Text(intPart,
              style: GoogleFonts.manrope(
                  fontSize: size,
                  fontWeight: w,
                  color: c,
                  letterSpacing: -size * 0.028)),
          Text(',$centsPart',
              style: GoogleFonts.manrope(
                  fontSize: size * 0.56,
                  fontWeight: w,
                  color: c.withValues(alpha: 0.85))),
        ]);
  }
}

class _BRLSmall extends StatelessWidget {
  final double value;
  final double size;
  const _BRLSmall({required this.value, required this.size});
  @override
  Widget build(BuildContext context) {
    return Text(FinancialCalculatorService.formatBRL(value),
        style: GoogleFonts.inter(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()]));
  }
}
