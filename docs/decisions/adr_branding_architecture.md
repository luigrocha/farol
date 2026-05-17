# ADR — Branding Architecture
> Date: 2026-05-16 · Status: ACCEPTED

## Context

Farol had no canonical way to render its brand identity. Every surface that
needed a logo — the onboarding screen, login screen, and desktop nav rail —
implemented its own inline `Container + Icon` with different sizes, different
icons (`Icons.anchor_rounded` vs `Icons.local_fire_department_rounded`), and
different color treatments. There was no `FarolLogo` widget, no greeting
system, and no empty state component.

## Decision

Create `lib/design/branding/` as the canonical brand identity module. It sits
alongside the existing `lib/design/` files and adds zero coupling to them:

```
lib/design/branding/
├── farol_brand.dart       Brand constants, palette aliases, dimensions
├── farol_logo.dart        FarolMark + FarolLogo + FarolLogoStack widgets
├── farol_greeting.dart    FarolGreeting + FarolGreetingHelper
├── farol_empty_state.dart FarolEmptyState + SliverFarolEmptyState
└── branding.dart          Barrel export
```

### Logo canonical spec

- `FarolMark` — the smallest brand atom. Rounded square container +
  beam symbol inside. Variant controls color treatment (light/dark/mono).
- `FarolLogo` — `FarolMark` + "Farol" wordmark in a `Row`.
- `FarolLogoStack` — stacked layout for constrained-width surfaces.
- Icon: `Icons.anchor_rounded` placeholder. Replace with custom `BeamPainter`
  when the vector asset is finalized.

### Greeting system

`FarolGreeting` is a `ConsumerWidget` that reads `currentProfileProvider` and
`financialSnapshotProvider`. It renders three variants:
- `dashboard` — two-line (salutation + financial subtitle), collapses on scroll
- `compact` — single-line for the desktop nav rail header
- `onboarding` — large display text for pre-auth surfaces

`FarolGreetingHelper` is a pure Dart class (no Flutter/Riverpod deps) for the
time-bucket and subtitle-key logic — safe to unit test.

### Empty state system

`FarolEmptyState` resolves i18n copy from a `FarolEmptyStateType` enum.
`SliverFarolEmptyState` wraps it in `SliverFillRemaining` for `CustomScrollView`
use. Both accept an optional CTA button.

## Consequences

**Positive:**
- All brand surfaces become consistent by construction — any screen that uses
  `FarolMark` will always show the correct icon, size, and color for its variant.
- Adding a new branded surface requires zero copy-paste: one import, one widget.
- The greeting system provides the "Boa tarde, Mariana" moment the product vision
  calls for, with zero coupling to screen layout decisions.
- Empty states are consistent across all list screens with a single widget call.

**Negative / Trade-offs:**
- `FarolGreeting` depends on `currentProfileProvider` (network call on first
  load). It gracefully degrades to the generic greeting if the profile is null
  or loading — no visual jank.
- The custom `BeamPainter` (the real logo mark) is deferred. The placeholder
  anchor icon is visually close but not pixel-perfect to the new identity.
  This is intentional: ship the architecture first, then drop in the asset.

## Migration path

See `docs/plans/branding_unification_plan.md` for the incremental phase plan.
Phase 1 (this ADR) is purely additive. Existing screens are not touched until
Phase 2 (logo standardization) is confirmed.
