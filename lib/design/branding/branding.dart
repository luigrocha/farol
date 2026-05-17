/// Farol Branding Module
///
/// Single import for all canonical branding widgets and constants.
///
/// ```dart
/// import 'package:farol/design/branding/branding.dart';
/// ```
///
/// Exports:
/// - [FarolBrand]      — brand constants, palette aliases, dimensions
/// - [FarolMark]       — icon mark widget (smallest brand atom)
/// - [FarolLogo]       — mark + wordmark widget
/// - [FarolLogoStack]  — stacked mark + wordmark
/// - [FarolLogoVariant] — light / dark / mono
/// - [FarolGreeting]   — time-aware personalized greeting
/// - [FarolGreetingVariant] — dashboard / compact / onboarding
/// - [FarolGreetingHelper] — pure utility for time-bucket + subtitle-key logic
/// - [FarolEmptyState] — branded empty state component
/// - [FarolEmptyState.custom] — custom-copy empty state
/// - [SliverFarolEmptyState] — sliver wrapper for CustomScrollViews
/// - [FarolEmptyStateType]  — type enum driving i18n key resolution
library branding;

export 'farol_brand.dart';
export 'farol_logo.dart';
export 'farol_greeting.dart';
export 'farol_empty_state.dart';
