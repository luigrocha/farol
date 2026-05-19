/// FarolEmptyState — consistent, branded empty state component.
///
/// Uses the beam mark as a visual anchor (dimmed) with a title, subtitle,
/// and optional CTA. All copy is driven by [FarolEmptyStateType] which
/// resolves to the correct i18n keys automatically.
///
/// Usage:
/// ```dart
/// // Fully automatic — type drives all copy
/// FarolEmptyState(type: FarolEmptyStateType.transactions)
///
/// // With a CTA
/// FarolEmptyState(
///   type: FarolEmptyStateType.investments,
///   actionLabel: l10n.addInvestment,
///   onAction: () => showAddSheet(context),
/// )
///
/// // Custom copy (override type-driven defaults)
/// FarolEmptyState.custom(
///   title: 'Nenhum insight',
///   subtitle: 'Continue registrando para ver análises.',
/// )
/// ```
library farol_empty_state;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/farol_colors.dart';
import '../ds_tokens.dart';
import '../widgets/farol_button.dart';
import 'farol_logo.dart';

// ── Type ──────────────────────────────────────────────────────────────────────

enum FarolEmptyStateType {
  transactions,
  installments,
  recurring,
  investments,
  insights,
  workspaces,
  spaceTransactions,
  generic,
}

// ── i18n key resolver ─────────────────────────────────────────────────────────

extension _EmptyStateKeys on FarolEmptyStateType {
  String get titleKey => switch (this) {
        FarolEmptyStateType.transactions => 'empty_transactions_title',
        FarolEmptyStateType.installments => 'empty_installments_title',
        FarolEmptyStateType.recurring => 'empty_recurring_title',
        FarolEmptyStateType.investments => 'empty_investments_title',
        FarolEmptyStateType.insights => 'empty_insights_title',
        FarolEmptyStateType.workspaces => 'empty_workspaces_title',
        FarolEmptyStateType.spaceTransactions =>
          'empty_space_transactions_title',
        FarolEmptyStateType.generic => 'empty_generic_title',
      };

  String get subtitleKey => switch (this) {
        FarolEmptyStateType.transactions => 'empty_transactions_sub',
        FarolEmptyStateType.installments => 'empty_installments_sub',
        FarolEmptyStateType.recurring => 'empty_recurring_sub',
        FarolEmptyStateType.investments => 'empty_investments_sub',
        FarolEmptyStateType.insights => 'empty_insights_sub',
        FarolEmptyStateType.workspaces => 'empty_workspaces_sub',
        FarolEmptyStateType.spaceTransactions => 'empty_space_transactions_sub',
        FarolEmptyStateType.generic => 'empty_generic_sub',
      };
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Branded empty state widget.
///
/// Anatomy (top-to-bottom, centered):
/// ```
///   [FarolMark — dimmed, 48px]
///   [title — Manrope 17 w700]
///   [subtitle — Inter 13 soft, max 2 lines]
///   [CTA button — FarolButton.ghost, optional]
/// ```
class FarolEmptyState extends StatelessWidget {
  const FarolEmptyState({
    super.key,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.customTitle,
    this.customSubtitle,
  });

  /// Named constructor for fully custom copy (not driven by type).
  const FarolEmptyState.custom({
    super.key,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    required String title,
    required String subtitle,
  })  : type = FarolEmptyStateType.generic,
        customTitle = title,
        customSubtitle = subtitle;

  final FarolEmptyStateType type;

  /// Label for the optional CTA button. If null, no button is shown.
  final String? actionLabel;

  /// Callback for the CTA button. Required when [actionLabel] is set.
  final VoidCallback? onAction;

  /// If true, renders a smaller, more compact layout (less vertical padding).
  final bool compact;

  /// Optional title override — used by [FarolEmptyState.custom].
  final String? customTitle;

  /// Optional subtitle override — used by [FarolEmptyState.custom].
  final String? customSubtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = customTitle ?? l10n.translate(type.titleKey);
    final subtitle = customSubtitle ?? l10n.translate(type.subtitleKey);

    // Mark opacity: slightly visible on dark bg, more dimmed on light
    final markOpacity = isDark ? 0.20 : 0.15;
    final markVariant = isDark ? FarolLogoVariant.mono : FarolLogoVariant.light;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DSSpacing.xxl,
          vertical: compact ? DSSpacing.xl : DSSpacing.p,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dimmed beam mark ─────────────────────────────────────────
            Opacity(
              opacity: markOpacity,
              child: FarolMark(
                size: compact ? 36 : 48,
                variant: markVariant,
              ),
            ),

            SizedBox(height: compact ? DSSpacing.lg : DSSpacing.xl),

            // ── Title ────────────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: DSSpacing.sm),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: compact ? 12 : 13,
                color: colors.onSurfaceSoft,
                height: 1.5,
              ),
            ),

            // ── CTA ──────────────────────────────────────────────────────
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? DSSpacing.lg : DSSpacing.xxl),
              FarolButton.ghost(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sliver variant ────────────────────────────────────────────────────────────

/// A [SliverFillRemaining] wrapper around [FarolEmptyState].
/// Drop this directly into a [CustomScrollView] when the list is empty.
///
/// ```dart
/// if (items.isEmpty)
///   SliverFarolEmptyState(
///     type: FarolEmptyStateType.transactions,
///     actionLabel: l10n.addExpense,
///     onAction: () => showQuickAdd(context),
///   )
/// ```
class SliverFarolEmptyState extends StatelessWidget {
  const SliverFarolEmptyState({
    super.key,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  final FarolEmptyStateType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: FarolEmptyState(
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}
