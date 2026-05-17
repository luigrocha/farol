# Branding Unification Plan — Farol
> Status: ACTIVE · Audited: 2026-05-16 · Author: CTO Assistant

---

## 0 · Executive Summary

Farol has a solid design system foundation — tokens, theme extensions, Manrope + Inter typography, a well-structured color palette, and good component coverage. The problem is **fragmentation at the identity layer**: the brand is expressed differently in every surface that "introduces" the product (onboarding, login, nav rail, dashboard header). There is no canonical `FarolLogo` widget, no `FarolGreeting` system, and no `FarolEmptyState` component. The result is a technically coherent app that feels visually inconsistent at the moments that matter most.

This plan evolves the app **incrementally** — no big-bang redesigns, no provider changes, no architectural disruption — respecting the NON-NEGOTIABLE rules in `CLAUDE.md`.

**Scope: 5 phases, ~3–4 sessions of work each.**

---

## 1 · Visual Audit

### 1.1 Design System — What's Already Good ✅

| Area | Status | Details |
|---|---|---|
| Color tokens | ✅ Strong | `FarolColors` (design/) is the canonical palette. Navy `#1B3A5C`, Beam `#F5A623`, Tide, Coral all well-defined. Light + dark variants present. |
| Theme extension | ✅ Strong | `FarolColors` ThemeExtension (core/theme/) provides `context.colors` — properly consumed across most screens. |
| Typography | ✅ Strong | Manrope (display/headings) + Inter (body) loaded via GoogleFonts. `FarolTypography` helper class exists. |
| Spacing tokens | ✅ Strong | `DSSpacing` (xs→pp) consistently used across almost all files. |
| Radius tokens | ✅ Strong | `DSRadius` (xs→full + convenience BRs) consistently used. |
| Shadow tokens | ✅ Strong | `DSShadow` (card, cardHover, hero) well-defined. |
| Animation tokens | ✅ Strong | `DSDuration` + `DSCurve` consistently used. |
| Card component | ✅ Good | `FarolCard` + `DSCard` (with hover). |
| Button component | ✅ Good | `FarolButton` (primary/secondary/ghost). |
| Skeleton/shimmer | ✅ Good | `ShimmerBox` + `DashboardCardSkeleton` exist. |
| Material 3 | ✅ Full | `useMaterial3: true`, proper ColorScheme mapping. |
| Dark mode | ✅ Full | Both light + dark themes, all tokens have variants. |
| i18n | ✅ Full | `AppLocalizations` across all screens (except one regression — see below). |

---

### 1.2 Inconsistencies Found ❌

#### IC-01 · Logo icon is not standardized (CRITICAL)
Three different icons represent "Farol" across the app — with no canonical widget:

| Surface | Icon used | Color treatment |
|---|---|---|
| Desktop NavRail (`main.dart`) | `Icons.local_fire_department_rounded` (fire) | Amber gradient on rounded square |
| Onboarding screen | `Icons.anchor_rounded` (anchor) | Beam fill, navy icon, glow shadow |
| Login screen (`_FarolMark`) | `Icons.anchor_rounded` (anchor) | Navy fill, white icon, no glow |
| Signup screen | Unknown (not audited yet) | Unknown |

**No canonical `FarolLogo` widget exists.** Every branded surface implements its own version inline.

#### IC-02 · No `FarolGreeting` / welcome system
The dashboard app bar shows only a month picker — no personalized greeting (the "Boa tarde, Mariana" moment visible in the mockup is completely absent from the current dashboard). The onboarding has a static tagline. There is no reusable greeting system.

#### IC-03 · Desktop NavRail uses fully hardcoded colors
`_DesktopNavRail` in `main.dart` hardcodes `Color(0xFF111827)` (background), `Color(0xFF1A2436)` (hover), `Color(0xFFF5A623)` (amber), `Color(0x1FF5A623)` (selected bg) — none of these reference `FarolColors` or `DSTokens`. They are correct values but unlinked from the token system.

#### IC-04 · `period_balance_hero.dart` hardcodes gradient colors inline
The hero card uses `Color(0xFF0D2238)`, `Color(0xFF1A3A5C)`, `Color(0xFF0D3328)` etc. inline. These are correct navy/teal values but not token-referenced. If the palette ever shifts they will drift.

#### IC-05 · `_FarolMark` (login) is visually inconsistent with onboarding logo
- Login: `Icons.anchor_rounded`, navy container, white icon, 56×56, radius 16 — no glow
- Onboarding: `Icons.anchor_rounded`, beam container, navy icon, 46×46, radius 14 — amber glow

Same icon, opposite color treatments, different sizes. They should be the same widget with a `variant` param.

#### IC-06 · No `FarolEmptyState` component
Empty states are implemented ad-hoc per screen, if at all. No shared illustration language, no consistent copy structure, no beam/lighthouse metaphor applied.

#### IC-07 · `FarolBottomNav` (design/widgets/) contains hardcoded Spanish strings
`farol_bottom_nav.dart` hardcodes `'Inicio'`, `'Invertir'`, `'Lanzar'` — bypassing `AppLocalizations`. This widget appears to be a legacy component not currently wired into the main navigation (MainShell uses `NavigationBar` directly), but it should be cleaned up.

#### IC-08 · Duplicate color system creates confusion
- `lib/design/farol_colors.dart` → static `Color` constants (canonical palette)
- `lib/core/theme/farol_colors.dart` → `ThemeExtension` class (runtime theming)

Both are necessary but their relationship is never documented. Files importing both use `as tokens` aliasing which is inconsistent (some files alias one, some the other, some neither).

#### IC-09 · `branding/` directory does not exist
The plan calls for `farol_brand.dart`, `farol_assets.dart`, `farol_logo.dart` etc. None of these exist. Branding is split across `design/farol_colors.dart`, `design/farol_typography.dart`, `core/theme/`, and inline in `main.dart`.

#### IC-10 · No `FarolGreeting` or contextual welcome messages
The dashboard header is purely functional (month picker + icons). There is no personalized greeting, no time-of-day awareness, no financial context tagline. Compare to the reference mockup: "Boa tarde, Mariana / Seu dinheiro no rumo certo."

#### IC-11 · `AppTheme` legacy class in `core/theme/app_theme.dart`
Legacy static class still defines `AppTheme.primaryColor`, `AppTheme.navy`, etc. as duplicates of `FarolColors`. Not widely used but creates confusion about the canonical source.

---

### 1.3 Screens Inventory by Branding Quality

| Screen | Logo | Greeting | Empty state | Skeleton | Tokens |
|---|---|---|---|---|---|
| Onboarding | ⚠️ Inline, inconsistent | ✅ Good tagline | N/A | N/A | ✅ Good |
| Login | ⚠️ Inline, wrong variant | N/A | N/A | N/A | ✅ Good |
| Signup | ❓ Not audited | N/A | N/A | N/A | ❓ |
| Dashboard | ❌ None | ❌ None | N/A | ✅ Partial | ✅ Good |
| Desktop NavRail | ⚠️ Fire icon, hardcoded | N/A | N/A | N/A | ❌ Hardcoded |
| Transactions | N/A | N/A | ❌ Missing | ✅ Partial | ✅ Good |
| Analytics | N/A | N/A | ❌ Missing | ✅ Good | ✅ Good |
| Budget | N/A | N/A | ❌ Missing | ✅ Good | ✅ Good |
| Investments | N/A | N/A | ❌ Missing | ✅ Good | ✅ Good |
| Settings | N/A | N/A | N/A | N/A | ✅ Good |
| Workspace Switcher | N/A | N/A | ⚠️ Basic | N/A | ✅ Good |
| Space dashboard | N/A | N/A | ⚠️ Basic | N/A | ✅ Good |

---

## 2 · Branding Principles (The Beam)

> These principles guide every implementation decision in this plan.

### Identity
- **The Beam** — a lighthouse reduced to its single directional gesture: tower + 45° growth ray
- The logo mark IS the app's mental model: "your money, going in the right direction"
- Navy = depth, stability, trust. Amber = direction, clarity, warmth.

### Visual rules
- Logo always: navy mark + amber beam ray. Never reversed. Never other colors.
- One logo widget. One set of props. Infinite surface adaptations.
- Greeting = human + contextual + calm. Never generic, never alarming.
- Empty states = beam metaphor. "The lighthouse is waiting for data."
- Loaders = calm. Shimmer is neutral. No spinner anxiety.

### Tone
- Calm financial clarity — not crypto casino energy
- Confidence through restraint — one accent, used deliberately
- Premium through whitespace — not through decoration

---

## 3 · New Architecture: `lib/design/branding/`

```
lib/design/branding/
├── farol_logo.dart          ← Canonical FarolLogo widget (all variants)
├── farol_greeting.dart      ← FarolGreeting system (time-aware, contextual)
├── farol_empty_state.dart   ← FarolEmptyState component
├── farol_brand.dart         ← Brand constants barrel + narrative copy
└── branding.dart            ← Barrel export for the whole module
```

This sits alongside existing `lib/design/` files — **no migrations required** of existing code. Screens gradually adopt the new widgets.

---

## 4 · Implementation Roadmap

---

### Phase 1 — Brand Architecture Foundation
**Goal:** Create the canonical branding module. Zero UI changes to existing screens.
**Risk:** None — purely additive.
**Confirmation required before Phase 2.**

#### Tasks

- [x] **P1-T1** · Create `lib/design/branding/farol_logo.dart`

  The canonical logo widget. All logo appearances in the app will eventually use this.

  ```dart
  enum FarolLogoVariant { light, dark, mono }
  enum FarolLogoSize { sm, md, lg, xl }

  class FarolLogo extends StatelessWidget {
    // Renders: beam icon mark + optional "Farol" wordmark
    // Props: variant, size, showWordmark, showGlow
  }

  class FarolMark extends StatelessWidget {
    // Icon mark only — the beacon square with the beam ray
    // Used in: app bar, nav rail, favicons, compact contexts
  }
  ```

  The icon: **custom `CustomPaint` beam mark** — tower + 45° ray — NOT `Icons.anchor_rounded` or `Icons.local_fire_department_rounded`. The new logo IS the brand. This is the only place where we render it.

  Fallback for Phase 1: use `Icons.anchor_rounded` as placeholder, flagged with `// TODO: replace with custom beam painter` comment.

- [x] **P1-T2** · Create `lib/design/branding/farol_brand.dart`

  Brand constants and narrative copy barrel:

  ```dart
  abstract final class FarolBrand {
    // Identity
    static const appName = 'Farol';
    static const tagline = 'Seu dinheiro no rumo certo.';
    static const taglineEn = 'Your money on the right course.';
    static const taglineEs = 'Tu dinero en el rumbo correcto.';

    // Palette aliases (re-exports from FarolColors with semantic names)
    static const navy = FarolColors.navy;
    static const beam = FarolColors.beam;
    static const navyDeep = FarolColors.navyDeep;

    // Logo dimensions by context
    static const markSizeNavRail  = 36.0;
    static const markSizeOnboarding = 46.0;
    static const markSizeAuth     = 52.0;
    static const markRadiusDefault = 12.0;
  }
  ```

- [x] **P1-T3** · Create `lib/design/branding/farol_greeting.dart`

  Time-aware, locale-aware greeting system:

  ```dart
  class FarolGreeting extends ConsumerWidget {
    // Renders greeting line ("Boa tarde, Ana") + optional subtitle
    // Props: userName, subtitle, style variant (dashboard | compact | onboarding)
  }

  abstract final class FarolGreetingHelper {
    static String greetingKey(DateTime now); // returns 'good_morning' | 'good_afternoon' | 'good_evening'
    static String financialSubtitle(FinancialSnapshot snap); // contextual tagline based on balance/period
  }
  ```

  **Time buckets:**
  - 05:00–11:59 → `bom_dia` / `good_morning` / `buenos_días`
  - 12:00–17:59 → `boa_tarde` / `good_afternoon` / `buenas_tardes`
  - 18:00–04:59 → `boa_noite` / `good_evening` / `buenas_noches`

  **Financial subtitles (contextual):**
  - Balance positive, high savings rate → "Tudo sob controle."
  - Balance positive, moderate → "Seu dinheiro no rumo certo."
  - Balance negative → "Vamos ajustar o rumo."
  - First days of period → "Novo período, novas metas."

  All strings routed through `AppLocalizations` keys — no hardcoding.

- [x] **P1-T4** · Create `lib/design/branding/farol_empty_state.dart`

  ```dart
  enum FarolEmptyStateType {
    transactions,
    budget,
    investments,
    recurring,
    insights,
    workspace,
    generic,
  }

  class FarolEmptyState extends StatelessWidget {
    // Props: type, title, subtitle, actionLabel, onAction
    // Visual: beam mark (dimmed), title, subtitle, optional CTA button
    // Metaphor: "O farol está pronto. Adicione seu primeiro [X]."
  }
  ```

- [x] **P1-T5** · Create `lib/design/branding/branding.dart` barrel export

- [x] **P1-T6** · Write ADR `docs/decisions/adr_branding_architecture.md`

  Documents: why `branding/` lives under `design/`, the canonical logo spec, the greeting system contract, the empty state system contract.

---

### Phase 2 — Logo Standardization
**Goal:** Replace all inline logo implementations with `FarolLogo`/`FarolMark`.
**Risk:** Low — visual-only changes to 4 surfaces.
**Confirmation required before Phase 3.**

Affected files:
1. `lib/main.dart` → `_DesktopNavRail` logo section
2. `lib/features/onboarding/onboarding_screen.dart` → logo row
3. `lib/features/auth/presentation/login_screen.dart` → `_FarolMark` widget
4. `lib/features/auth/presentation/signup_screen.dart` → logo (to be audited)

#### Tasks

- [x] **P2-T1** · Replace `_DesktopNavRail` logo in `main.dart`

  ```dart
  // Before:
  Container(
    width: 36, height: 36,
    decoration: BoxDecoration(gradient: LinearGradient(...), borderRadius: ...),
    child: const Icon(Icons.local_fire_department_rounded, ...),
  )

  // After:
  FarolMark(size: FarolBrand.markSizeNavRail)
  ```

  Also: extract `_navyBg`, `_amber`, `_selectedBg` constants to reference `FarolColors` and `FarolBrand` instead of hardcoded hex.

- [x] **P2-T2** · Replace onboarding logo in `onboarding_screen.dart`

  ```dart
  // Before: inline Container + Icon + Text("Farol")
  // After:
  FarolLogo(
    variant: FarolLogoVariant.dark, // white wordmark on dark bg
    size: FarolLogoSize.md,
    showGlow: true,
  )
  ```

- [x] **P2-T3** · Replace `_FarolMark` in `login_screen.dart`

  ```dart
  // Before: inline Container(navy bg, white anchor icon)
  // After:
  FarolMark(size: FarolBrand.markSizeAuth)
  ```

- [x] **P2-T4** · Audit + replace logo in `signup_screen.dart` (same pattern)

- [x] **P2-T5** · Verify: `flutter analyze` passes, no regressions

---

### Phase 3 — Dashboard Greeting + Header Identity
**Goal:** Make the dashboard header feel personal and premium. The "Boa tarde, Mariana" moment.
**Risk:** Medium — modifies `dashboard_screen.dart` `_PremiumAppBar`. No provider changes.
**Confirmation required before Phase 4.**

#### Design spec

```
┌──────────────────────────────────────────────────────────┐
│  [←] Maio 2026 [→]          [workspace] [👁] [🔔]        │
│       1 mai – 25 mai                                      │
└──────────────────────────────────────────────────────────┘
```

Current: ✅ already clean. The month picker is good. What's missing is the **greeting section above the app bar** — a separate `SliverPersistentHeader` that collapses on scroll.

**New layout (mobile):**

```
┌──────────────────────────────────────────────────────────┐
│  Boa tarde, Ana            [workspace] [👁] [🔔]          │
│  Seu dinheiro no rumo certo.                              │  ← collapses on scroll
├──────────────────────────────────────────────────────────┤
│  [←] Maio 2026 [→]                                       │  ← always visible (floating)
└──────────────────────────────────────────────────────────┘
```

**Desktop:** greeting appears in the NavRail header below the workspace chip (replacing the current empty space) — not in the main content area.

#### Tasks

- [x] **P3-T1** · Add `FarolGreeting` to `AppLocalizations`

  Add i18n keys: `good_morning`, `good_afternoon`, `good_evening`, `greeting_format` (`{greeting}, {name}`), `subtitle_on_track`, `subtitle_adjust`, `subtitle_new_period`, `subtitle_controlled`.

- [x] **P3-T2** · Implement `FarolGreeting` widget (from Phase 1 spec)

  Must consume: `ref.watch(profileProvider)` for name, current `DateTime.now()` for time bucket, optional `FinancialSnapshot` for subtitle variant.

- [x] **P3-T3** · Add collapsible greeting sliver to `DashboardScreen`

  Insert `_GreetingSliver` as first sliver, before `_PremiumAppBar`. Collapses on scroll. Pinned: false, floating: false.

  ```dart
  SliverPersistentHeader(
    pinned: false,
    delegate: _GreetingHeaderDelegate(
      minExtent: 0,
      maxExtent: 72,
      child: FarolGreeting(variant: GreetingVariant.dashboard),
    ),
  )
  ```

- [x] **P3-T4** · Add greeting to `_NavRailHeader` in desktop shell

  Below the workspace chip, show a compact `FarolGreeting(variant: GreetingVariant.compact)` — name only, no subtitle, muted white text.

- [x] **P3-T5** · Verify responsive: greeting hidden when `isDesktop = true` in main content, shown in rail instead.

- [x] **P3-T6** · Verify: screen tested at 375px (mobile min), 800px (desktop breakpoint), 1200px (wide)

---

### Phase 4 — Empty States
**Goal:** Consistent, branded empty states across all list screens.
**Risk:** Low — purely additive widgets in screens that currently show nothing.
**Confirmation required before Phase 5.**

#### Screens to wire

| Screen | Empty condition | Message key |
|---|---|---|
| `TransactionsScreen` | No expenses in period | `empty_transactions` |
| `InstallmentsScreen` | No active plans | `empty_installments` |
| `RecurringScreen` | No recurring rules | `empty_recurring` |
| `InvestmentsScreen` | No investments | `empty_investments` |
| `InsightsScreen` | No insights | `empty_insights` |
| `WorkspaceSwitcherSheet` | No shared workspaces | `empty_workspaces` |
| `SpaceTransactionsScreen` | No space transactions | `empty_space_transactions` |

#### Tasks

- [ ] **P4-T1** · Implement `FarolEmptyState` widget (from Phase 1 spec)

  Visual anatomy:
  ```
  [FarolMark — dimmed to 30% opacity, size 48]
  [Title — Manrope 18 w700]
  [Subtitle — Inter 14 soft, max 2 lines]
  [CTA button — FarolButton.ghost, optional]
  ```

- [ ] **P4-T2** · Add i18n keys for all 7 empty state messages (title + subtitle pairs)

- [ ] **P4-T3** · Wire into `TransactionsScreen`

- [ ] **P4-T4** · Wire into `InstallmentsScreen` + `RecurringScreen`

- [ ] **P4-T5** · Wire into `InvestmentsScreen`

- [ ] **P4-T6** · Wire into `InsightsScreen` + `WorkspaceSwitcherSheet`

- [ ] **P4-T7** · Wire into `SpaceTransactionsScreen`

---

### Phase 5 — Polish + Token Cleanup
**Goal:** Eliminate remaining hardcoded values, clean up legacy classes, ensure 100% token coverage across all branded surfaces.
**Risk:** Low — incremental refactors.
**No blocking confirmation required — can be done in parallel with other work.**

#### Tasks

- [ ] **P5-T1** · Extract `_DesktopNavRail` palette constants to `FarolColors` + `FarolBrand`

  Replace: `Color(0xFF111827)` → `FarolColors.navyDeep` (or add `navySidebar` token)
  Replace: `Color(0xFF1A2436)` → new token `navySidebarHover`
  Replace: `Color(0x1FF5A623)` → `FarolColors.beam.withValues(alpha: 0.12)`

- [ ] **P5-T2** · Extract `PeriodBalanceHero` gradient colors to named tokens

  Add to `FarolColors`: `heroGradientPositive`, `heroGradientNegative` (list of colors).
  Extract to `FarolBrand.heroGradientColors(bool isPositive)` helper.

- [ ] **P5-T3** · Delete `lib/core/theme/app_theme.dart` legacy class

  Audit: confirm no files import `AppTheme.*`. If any still do, migrate to `FarolColors.*`. Then delete.

- [ ] **P5-T4** · Fix `farol_bottom_nav.dart` i18n regression

  Replace hardcoded `'Inicio'`, `'Invertir'`, `'Lanzar'` with `AppLocalizations` keys.
  Note: confirm if this widget is live in the navigation or dead code — if dead, mark for deletion.

- [ ] **P5-T5** · Document the dual-color-system contract in `design/README.md`

  One paragraph explaining:
  - `design/farol_colors.dart` → static constants (import this for hardcoded palette values in painters, gradients, inline decorations)
  - `core/theme/farol_colors.dart` → ThemeExtension (use `context.colors.*` in build methods for theme-responsive values)

- [ ] **P5-T6** · Add `// coverage: branding` lint comment pattern

  Tag every file in `design/branding/` and every screen that has completed Phase 2–4 migration with `// @branded` so future audits can grep for untagged files.

- [ ] **P5-T7** · Final `flutter analyze` + verify no import cycles

---

## 5 · Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Custom beam painter complex to implement | Medium | Low | Phase 1 ships with `Icons.anchor_rounded` placeholder; painter deferred to Phase 5 |
| Greeting sliver disrupts scroll physics on mobile | Low | Medium | Test at 375px; use `SliverToBoxAdapter` fallback if `SliverPersistentHeader` has issues |
| `profileProvider` not available in all surfaces | Low | Low | `FarolGreeting` gracefully degrades to generic greeting if name is null |
| i18n keys missing for some locales | Low | Low | Use `translate()` with fallback; add keys in same PR as widget |
| `AppTheme` deletion breaks something | Medium | High | Grep all imports before deletion; confirm zero usages |

---

## 6 · File Modification Map

### New files (all additive)
```
lib/design/branding/farol_logo.dart          ← NEW (Phase 1)
lib/design/branding/farol_brand.dart         ← NEW (Phase 1)
lib/design/branding/farol_greeting.dart      ← NEW (Phase 1)
lib/design/branding/farol_empty_state.dart   ← NEW (Phase 1)
lib/design/branding/branding.dart            ← NEW (Phase 1)
docs/decisions/adr_branding_architecture.md  ← NEW (Phase 1)
lib/design/README.md                         ← NEW (Phase 5)
```

### Modified files
```
lib/main.dart                                ← Phase 2 (logo), Phase 3 (greeting in rail), Phase 5 (tokens)
lib/features/onboarding/onboarding_screen.dart ← Phase 2
lib/features/auth/presentation/login_screen.dart ← Phase 2
lib/features/auth/presentation/signup_screen.dart ← Phase 2
lib/features/dashboard/dashboard_screen.dart ← Phase 3
lib/features/transactions/transactions_screen.dart ← Phase 4
lib/features/installments/installments_screen.dart ← Phase 4
lib/features/recurring/recurring_screen.dart ← Phase 4
lib/features/investments/investments_screen.dart ← Phase 4
lib/features/insights/insights_screen.dart   ← Phase 4
lib/features/workspace/workspace_switcher_sheet.dart ← Phase 4
lib/features/space/space_transactions_screen.dart ← Phase 4
lib/features/dashboard/widgets/period_balance_hero.dart ← Phase 5
lib/core/i18n/app_localizations.dart         ← Phase 3 + 4 (new keys)
lib/design/widgets/farol_bottom_nav.dart     ← Phase 5
```

### Files to delete (after migration)
```
lib/core/theme/app_theme.dart                ← Phase 5 (after audit confirms zero usages)
```

---

## 7 · i18n Key Plan

Keys to add to `app_localizations.dart` (all 3 locales: pt, es, en):

```
// Greeting system
good_morning          → "Bom dia"         / "Buenos días"    / "Good morning"
good_afternoon        → "Boa tarde"       / "Buenas tardes"  / "Good afternoon"
good_evening          → "Boa noite"       / "Buenas noches"  / "Good evening"
greeting_name         → "{greeting}, {name}"  (parameterized)

// Financial subtitles
subtitle_on_track     → "Seu dinheiro no rumo certo."
subtitle_adjust       → "Vamos ajustar o rumo."
subtitle_new_period   → "Novo período, novas metas."
subtitle_controlled   → "Tudo sob controle."
subtitle_neutral      → "Acompanhando seu dinheiro."

// Empty states
empty_transactions_title    → "Nenhuma transação ainda"
empty_transactions_sub      → "Adicione sua primeira receita ou despesa."
empty_installments_title    → "Sem parcelamentos ativos"
empty_installments_sub      → "Seus parcelamentos aparecerão aqui."
empty_recurring_title       → "Sem lançamentos recorrentes"
empty_recurring_sub         → "Configure despesas e receitas que se repetem."
empty_investments_title     → "Carteira vazia"
empty_investments_sub       → "Adicione seus primeiros investimentos."
empty_insights_title        → "Sem insights no momento"
empty_insights_sub          → "O Farol está monitorando seus dados."
empty_workspaces_title      → "Apenas seu espaço pessoal"
empty_workspaces_sub        → "Crie ou aceite um convite para colaborar."
empty_space_transactions_title → "Nenhuma transação no espaço"
empty_space_transactions_sub   → "Adicione a primeira transação compartilhada."
```

---

## 8 · Success Criteria

After all 5 phases complete, the app must satisfy:

- [ ] One and only one `FarolLogo`/`FarolMark` widget used across all brand surfaces
- [ ] Dashboard greets user by name with time-aware salutation
- [ ] Dashboard greeting collapses gracefully on scroll
- [ ] All 7 list screens have a consistent empty state using `FarolEmptyState`
- [ ] `flutter analyze` passes with zero warnings
- [ ] No hardcoded color hex values in `main.dart` NavRail
- [ ] No hardcoded color hex values in `period_balance_hero.dart`
- [ ] `app_theme.dart` legacy class deleted or confirmed as dead code
- [ ] `farol_bottom_nav.dart` i18n regression fixed
- [ ] All 3 locales (pt, es, en) covered for all new keys
- [ ] All new widgets have `///` dartdoc comments
- [ ] Dark mode tested for all new components

---

## 9 · Phase Execution Order

```
Phase 1 → [confirm] → Phase 2 → [confirm] → Phase 3 → [confirm] → Phase 4 → Phase 5
  (arch)                (logo)               (greeting)             (empty)   (polish)
```

Phases 4 and 5 can overlap — Phase 5 tasks are independent cleanups that don't block Phase 4.

**Activation:**
- `"Implement Phase 1 of docs/plans/branding_unification_plan.md"` → creates branding/ module
- `"Implement Phase 2 of docs/plans/branding_unification_plan.md"` → logo standardization
- etc.

---

*Last updated: 2026-05-16 · No code changes made in this session — plan only.*
