/// FarolGreeting — time-aware, locale-aware greeting system.
///
/// Provides personalized, contextual greetings that adapt to:
/// - Time of day (morning / afternoon / evening)
/// - User's first name (from profile)
/// - Financial context (balance state, period timing)
/// - Current locale (pt, es, en)
///
/// Usage:
/// ```dart
/// // Dashboard: full greeting with financial subtitle
/// FarolGreeting(variant: FarolGreetingVariant.dashboard)
///
/// // Nav rail: compact first-name only
/// FarolGreeting(variant: FarolGreetingVariant.compact)
/// ```
library farol_greeting;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../core/theme/farol_colors.dart';
import 'farol_brand.dart';

// ── Variant ───────────────────────────────────────────────────────────────────

enum FarolGreetingVariant {
  /// Full two-line greeting: salutation + financial subtitle.
  /// Used in the dashboard collapsible header (legacy standalone sliver).
  dashboard,

  /// Two-line greeting embedded inside the AppBar: smaller font, no padding.
  /// Used in the mobile dashboard AppBar first row.
  appBar,

  /// Single line: salutation only (no subtitle).
  /// Used in the compact nav rail header.
  compact,

  /// Centered layout for onboarding/splash — larger display text.
  onboarding,
}

// ── Helper ────────────────────────────────────────────────────────────────────

/// Pure utility class — no widgets, no Flutter deps.
/// Safe to use in tests without a widget tree.
abstract final class FarolGreetingHelper {
  /// Returns the i18n key for the time-of-day greeting.
  static String greetingKey(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return FarolBrand.keyGoodMorning;
    if (hour >= 12 && hour < 18) return FarolBrand.keyGoodAfternoon;
    return FarolBrand.keyGoodEvening;
  }

  /// Returns the i18n key for the financial subtitle.
  ///
  /// [isPositive] — whether the current period balance is positive.
  /// [savingsRate] — current savings rate (0–100).
  /// [dayOfPeriod] — how many days into the current period (1-based).
  static String subtitleKey({
    required bool isPositive,
    required double savingsRate,
    required int dayOfPeriod,
  }) {
    if (dayOfPeriod <= 2) return FarolBrand.keySubtitleNewPeriod;
    if (!isPositive) return FarolBrand.keySubtitleAdjust;
    if (savingsRate >= 20) return FarolBrand.keySubtitleControlled;
    if (savingsRate >= 10) return FarolBrand.keySubtitleOnTrack;
    return FarolBrand.keySubtitleNeutral;
  }

  /// Extracts the first name from a full display name.
  /// Returns null if [displayName] is null or empty.
  static String? firstName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return null;
    return displayName.trim().split(' ').first;
  }
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Personalized greeting widget that reads user profile and financial state.
///
/// Gracefully degrades when:
/// - Profile is loading → shows generic greeting without name
/// - Profile has no name → shows greeting without name
/// - Financial data unavailable → shows default subtitle
class FarolGreeting extends ConsumerWidget {
  const FarolGreeting({
    super.key,
    this.variant = FarolGreetingVariant.dashboard,
    this.overrideName,
    this.now,
  });

  final FarolGreetingVariant variant;

  /// Override the displayed name — useful for previews and testing.
  final String? overrideName;

  /// Override the current time — useful for testing time buckets.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final profileAsync = ref.watch(currentProfileProvider);
    final snap = ref.watch(financialSnapshotProvider);
    final period = ref.watch(selectedPeriodProvider);

    final effectiveNow = now ?? DateTime.now();
    final greetingWord =
        l10n.translate(FarolGreetingHelper.greetingKey(effectiveNow));

    final name = overrideName ??
        profileAsync.whenOrNull(
          data: (p) => FarolGreetingHelper.firstName(p?.displayName),
        );

    final dayOfPeriod = effectiveNow.difference(period.start).inDays + 1;
    final subtitleKey = FarolGreetingHelper.subtitleKey(
      isPositive: snap.isPositive,
      savingsRate: snap.savingsRate,
      dayOfPeriod: dayOfPeriod,
    );
    final subtitle = l10n.translate(subtitleKey);

    return switch (variant) {
      FarolGreetingVariant.dashboard => _DashboardGreeting(
          greetingWord: greetingWord,
          name: name,
          subtitle: subtitle,
          colors: colors,
        ),
      FarolGreetingVariant.appBar => _AppBarGreeting(
          greetingWord: greetingWord,
          name: name,
          subtitle: subtitle,
          colors: colors,
        ),
      FarolGreetingVariant.compact => _CompactGreeting(
          greetingWord: greetingWord,
          name: name,
          colors: colors,
        ),
      FarolGreetingVariant.onboarding => _OnboardingGreeting(
          greetingWord: greetingWord,
          name: name,
          subtitle: subtitle,
        ),
    };
  }
}

// ── Dashboard variant ─────────────────────────────────────────────────────────

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting({
    required this.greetingWord,
    required this.name,
    required this.subtitle,
    required this.colors,
  });

  final String greetingWord;
  final String? name;
  final String subtitle;
  final FarolColors colors;

  @override
  Widget build(BuildContext context) {
    final greeting = name != null ? '$greetingWord, $name' : greetingWord;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greeting,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: colors.onSurfaceSoft,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── AppBar embedded variant ───────────────────────────────────────────────────
//
// Two-line greeting sized for the AppBar first row: smaller headline (15px),
// no padding (the AppBar provides it), and a tighter subtitle (11px).

class _AppBarGreeting extends StatelessWidget {
  const _AppBarGreeting({
    required this.greetingWord,
    required this.name,
    required this.subtitle,
    required this.colors,
  });

  final String greetingWord;
  final String? name;
  final String subtitle;
  final FarolColors colors;

  @override
  Widget build(BuildContext context) {
    final greeting = name != null ? '$greetingWord, $name' : greetingWord;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
            height: 1.2,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: colors.onSurfaceSoft,
            height: 1.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Compact variant ───────────────────────────────────────────────────────────

class _CompactGreeting extends StatelessWidget {
  const _CompactGreeting({
    required this.greetingWord,
    required this.name,
    required this.colors,
  });

  final String greetingWord;
  final String? name;
  final FarolColors colors;

  @override
  Widget build(BuildContext context) {
    final greeting = name != null ? '$greetingWord, $name' : greetingWord;

    return Text(
      greeting,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.55),
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Onboarding variant ────────────────────────────────────────────────────────

class _OnboardingGreeting extends StatelessWidget {
  const _OnboardingGreeting({
    required this.greetingWord,
    required this.name,
    required this.subtitle,
  });

  final String greetingWord;
  final String? name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final greeting = name != null ? '$greetingWord, $name.' : '$greetingWord.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.70),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
