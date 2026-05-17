# ADR: Dual Color System Contract

**Status:** Accepted  
**Date:** 2026-05-16  
**Context:** Branding Unification — Phase 5

---

## Problem

The codebase has two color systems that serve different purposes but are
easily confused:

1. **`design/farol_colors.dart`** — static compile-time constants, imported
   as `tokens.FarolColors.*`
2. **`core/theme/farol_colors.dart`** — `ThemeExtension<FarolColors>` with
   light/dark variants, accessed via `context.colors.*`

Using the wrong one in the wrong context produces either:
- **Hardcoded colors** that don't respond to dark mode (static tokens in
  adaptive widgets), or
- **Unnecessary BuildContext dependencies** in places that only need a
  constant (ThemeExtension in `const` constructors).

---

## Decision

### Layer 1 — `design/farol_colors.dart` (static tokens)

**Canonical alias:** `import '../../design/farol_colors.dart' as tokens;`

**Use for:**
- Brand palette constants that are the same in both light and dark mode:
  `tokens.FarolColors.navy`, `tokens.FarolColors.beam`, `tokens.FarolColors.tide`
- Any `const` decoration, gradient, or BoxDecoration
- The `colorScheme` slots in `ThemeData` (primary, secondary, tertiary, error)

**Do NOT use for:**
- Surface colors, text colors, or anything that needs to flip between
  light and dark

---

### Layer 2 — `core/theme/farol_colors.dart` (ThemeExtension)

**Canonical alias:** `context.colors` (via `extension FarolColorsX` in the same file)

**Use for:**
- Surface colors: `context.colors.surface`, `.surfaceLow`, `.surfaceLowest`
- Text/icon colors: `context.colors.onSurface`, `.onSurfaceSoft`, `.onSurfaceFaint`
- Any color that must change between light and dark themes
- Inside `build()` methods and widget trees where `BuildContext` is available

**Do NOT use for:**
- `const` constructors — ThemeExtension values are runtime, not compile-time
- Static / global providers outside the widget tree

---

### Layer 3 — `design/branding/farol_brand.dart` (semantic aliases)

**Use for:**
- Any branded surface that needs semantic naming rather than raw hex:
  `FarolBrand.navy`, `FarolBrand.beam`, `FarolBrand.navySidebar`
- Hero gradient color lists: `FarolBrand.heroGradientPositive/Negative`
- Logo dimension constants: `FarolBrand.markSizeAuth`, etc.

`FarolBrand` values are `const` — they delegate to Layer 1 tokens.

---

## Decision Matrix

| Situation | Use |
|---|---|
| Brand color in gradient / BoxDecoration | `tokens.FarolColors.*` or `FarolBrand.*` |
| Surface / text color in widget build | `context.colors.*` |
| Logo size, sidebar color, hero gradient | `FarolBrand.*` |
| ThemeData colorScheme slot | `tokens.FarolColors.*` |

---

## Dead Code Removed

- `lib/design/widgets/farol_bottom_nav.dart` — hardcoded Spanish nav labels
  replaced with `AppLocalizations` getters (`navHome`, `navInvestments`,
  `navAdd`, `navCards`, `navSettings`). The widget itself remains available
  but is not currently wired into the app shell.

- `lib/core/theme/app_theme.dart` (`AppTheme` class) — confirmed dead:
  zero external imports. The class is retained for reference but should not
  be imported. The live theme is built in `main.dart` via `farolLightTheme`
  / `farolDarkTheme` (defined in `core/theme/farol_colors.dart`).

---

## Migration Path

If you encounter an inline hex color in a widget:

1. Check if it belongs to the brand palette → extract to `FarolBrand` or
   reference `tokens.FarolColors.*`
2. If it's a surface/text color → replace with `context.colors.*`
3. Never add new `const Color(0xFF...)` inline in widget files

Run `grep -r "const Color(0xFF" lib/features` periodically to catch
regressions.
