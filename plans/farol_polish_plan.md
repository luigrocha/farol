# Plan: Farol Polish
**Area**: Product · UI/UX · Backend · Monetization · Quality
**Priority**: Strategic — complete roadmap toward v1.0 ready for launch
**Date**: 2026-05-11
**Status**: 🟡 Planning

---

## 🎯 Strategic Context

Farol's technical engine is complete. All predictive engine phases (P0–P6) are implemented and in production. The multi-user workspace model is live. Structural technical debt has been eliminated.

What remains is the gap between an **"app that works technically"** and a **"product users love and pay for"**.

This plan maps exactly that gap across 6 work areas, ordered by impact/effort.

---

## 📊 Current Diagnosis

| Area | Status | Main Gap |
|---|---|---|
| Financial Engine | ✅ Complete | — |
| Multi-user + Workspaces | ✅ Complete (Phases 1–4) | Monetization pending |
| Signup + Profile | 🟡 Basic | Missing fields, no real photo, no CPF validation |
| Budget Goals | 🟡 Functional | No localization, no accumulated % validation, no recommendations |
| Test Coverage | 🟡 Partial | Partial in financial_engine, forecasting, categories |
| i18n (doc translation) | 🟡 60% done | Internal plans/docs still in Spanish/Portuguese |
| UX / Onboarding | 🔴 Nonexistent | No tutorial, no narrative empty state, no guided first use |
| Monetization (Freemium) | 🔴 Pending | No Stripe/RevenueCat, no paywall, no pricing |
| Avatar / Storage | 🔴 Stub | URL-text field, no real upload |
| Web Adaptation | ✅ Complete | NavigationRail + adaptive layouts on all screens |

---

## 🗂️ Work Areas

### Area A — Signup + User Profile *(High priority)*
### Area B — Budget Goals: Localization + Validation + AI *(High priority)*
### Area C — Freemium Monetization: Stripe + Paywall *(Strategic)*
### Area D — Onboarding + Empty State *(High priority for retention)*
### Area E — Quality: Tests + Static Analysis *(Medium priority)*
### Area F — Internal Documentation: Complete migration to English *(Low priority)*

---

## AREA A — Signup + User Profile

> **Source plan**: `PLAN_PERFIL_SIGNUP.md` (already exists, detailed)

### Goal
Align signup and profile with the target design. Capture key user data from the very start (name, CPF). Enable real profile photo upload.

### Phases

**Phase A1 — Signup: name + CPF + terms**
- Fields: Full name (required), CPF (optional, masked), terms checkbox
- `signup_screen.dart` + `auth_repository.dart`
- CPF goes into Supabase Auth `metadata` (no DB migration yet)
- No DB changes in this phase

**Phase A2 — Edit Profile: UI redesign with sections**
- Header with circular avatar (initials), name, subtitle "Farol since [month] · Free Plan"
- Section PERSONAL DATA: Name, Email (read-only), Phone, CPF
- Section PROFESSIONAL PROFILE: Company, Role
- Phone/company/role go into `UserProfile.metadata` until Phase A3
- File: `edit_profile_screen.dart`

**Phase A3 — Data model: extend `profiles` in Supabase**
- Migration V37: columns `phone`, `cpf`, `company`, `role`, `plan` on `profiles` table
- `UserProfile` model updated with new fields
- Backfill from `metadata` → dedicated columns
- RLS: verify UPDATE works on new columns

**Phase A4 — Validation + UX: masks and badges**
- CPF mask `000.000.000-00`
- Phone mask `+55 (00) 00000-0000`
- Real CPF validation (modulus 11 algorithm)
- Green ✓ badge on Email if `emailConfirmedAt != null`
- CPF read-only if already set (lock icon)

**Phase A5 — Avatar: real upload to Supabase Storage**
- `image_picker` → upload to bucket `avatars/{uid}.jpg`
- Supabase Storage RLS policy by uid
- `AppUser.photoUrl` connected to real column
- Fallback to initials if no photo
- New dependency: `image_picker: ^1.x`

### Impacted files
```
lib/features/auth/screens/signup_screen.dart
lib/features/auth/repositories/auth_repository.dart
lib/features/profile/screens/edit_profile_screen.dart
lib/features/profile/repositories/profile_repository.dart
lib/core/models/app_user.dart
database/migrations/V37__profiles_extended_fields.sql
```

### Risks
- CPF in metadata → column requires careful backfill (some users may not have it)
- RLS on `profiles` may not cover new columns automatically — verify `profiles_update` policy
- `image_picker` requires gallery/camera permissions on iOS and Android — check `Info.plist` and `AndroidManifest`

---

## AREA B — Budget Goals: Localization + Validation + AI

> **Source plan**: `docs/BUDGET_PLAN.md` (already exists, detailed)

### Goal
Fix two critical problems: categories shown in English regardless of user language, and the possibility that `target_percentage` sums exceed 100%. Then add intelligent budget recommendations.

### Phases

**Phase B1 — Category localization in UI**
- Add i18n keys for all categories (`category_housing`, `category_transport`, etc.)
- Complete EN / ES / PT-BR
- Helper `categoryLabel(BuildContext)` in `lib/core/models/`
- Replace all hardcoded mappings in: period budget screen, budget goals list, budget edit sheet, analytics breakdown, transaction list
- Clean `flutter analyze` at the end

**Phase B2 — Percentage validation + real-time feedback**
- Provider: `budgetPercentageTotalProvider` — sum of `target_percentage` excluding Swile categories
- Budget edit sheet: show remaining available %; disable save if over 100%
- Budget goals list: warning banner if total > 100%
- "How to fix" message pointing to each over-budget category

**Phase B3 — Swile separation from cash pool**
- Categories marked as Swile (`isSwile = true`) have their own budget pool
- `budgetPercentageTotalProvider` excludes Swile categories from the 100% calculation
- UI: show two separate bars — cash pool and Swile pool
- Independent validation per pool

**Phase B4 — AI budget recommendations**
- Based on historical expenses from the last 3 months
- 50/30/20 rule as baseline (Needs/Wants/Invest aligned with `BudgetGoalType`)
- `BudgetRecommendationService` in `core/domain/services/`
- UI: "Generate recommendation" button on budget goals screen → sheet with proposal + apply option
- Consider user's salary (from `incomes`) to calculate absolute % in BRL

### Impacted files
```
lib/core/i18n/app_localizations.dart
lib/core/models/category_ref.dart (or new helper)
lib/features/budget/screens/period_budget_screen.dart
lib/features/budget/screens/budget_goals_screen.dart
lib/features/budget/widgets/budget_edit_sheet.dart
lib/core/providers/providers.dart
lib/core/domain/services/budget_recommendation_service.dart (new)
```

### Risks
- Localization requires auditing ALL points where a category is displayed — use `grep` to find them all
- `budgetPercentageTotalProvider` must be `autoDispose` to avoid stale state
- History-based recommendations may not work well for new users — needs fallback to reasonable defaults

---

## AREA C — Freemium Monetization

> **Source plan**: `plans/multiuser_freemium.md` Phase 4 (pending)

### Goal
Convert the technical freemium model (already implemented with `FeatureGate` and `PremiumFeature`) into a real monetization flow with payments.

### Tier definition (proposal)

| Feature | Free | Premium (R$19.90/month) |
|---|---|---|
| Own workspaces | 1 | Unlimited |
| Members per workspace | Solo | Up to 5 |
| History | 3 months | Unlimited |
| PDF export | ❌ | ✅ |
| Cashflow forecast (90 days) | ❌ | ✅ |
| Advanced insights | 3 rules | 12 rules |
| AI budget recommendations | ❌ | ✅ |

### Phases

**Phase C1 — Define concrete Free tier limits**
- Map each `PremiumFeature` enum to a concrete limit
- Implement real checks in `FeatureGate` (currently the gate exists but blocks nothing)
- No payment integration yet — just "demo mode" UI

**Phase C2 — Paywall UI**
- `PaywallScreen` with clear value proposition
- List of features unlocked with Premium
- Anchored pricing (R$19.90/month · R$179/year = 2 free months)
- Primary CTA: "Subscribe Premium" → stub that simulates payment for now
- Secondary CTA: "Continue free"

**Phase C3 — RevenueCat integration (mobile)**
- RevenueCat SDK for iOS + Android
- Products in App Store Connect + Google Play Console
- `RevenueCatService` in `core/services/`
- `workspacePlanProvider` updated to read real RevenueCat entitlement
- Webhook to mark `workspaces.plan = 'premium'` in Supabase

**Phase C4 — Stripe integration (web)**
- Stripe Checkout for web users
- Edge Function `create-checkout-session` in Supabase
- Stripe Webhook → update `workspaces.plan` in Supabase
- Unify with RevenueCat via `workspacePlanProvider`

**Phase C5 — Trial + Offboarding**
- 14-day auto trial on signup (no credit card)
- Trial banner in AppBar showing remaining days
- Expiration email (Supabase Edge Function + Resend)
- 7-day grace period post-expiration before blocking features

### Impacted files
```
lib/core/widgets/feature_gate.dart
lib/core/providers/workspace_providers.dart
lib/features/paywall/screens/paywall_screen.dart (new)
lib/core/services/revenue_cat_service.dart (new)
supabase/functions/create-checkout-session/index.ts (new)
supabase/functions/stripe-webhook/index.ts (new)
database/migrations/V38__workspace_plan_trial.sql (new)
```

### Risks
- App Store Review may reject if paywall blocks core features — ensure the app is usable on Free
- RevenueCat and Stripe require developer accounts and approval — non-trivial setup time
- Auto-trial without credit card may lead to high post-trial churn — needs good email sequence

---

## AREA D — Onboarding + Empty State

### Goal
Farol's first use currently drops users into an empty dashboard with no context. This kills retention within the first 5 minutes. The onboarding should guide the user to their first "aha moment": seeing their projected financial situation.

### Phases

**Phase D1 — Narrative empty states**
- Each empty screen must have: illustration, explanatory title, subtitle with CTA
- Empty dashboard: "Add your first income to see how your money will behave this month"
- Empty transactions: "No transactions yet. Start with the + button below"
- Empty recurring: "Fixed expenses saved here appear automatically every month"
- Empty installments: "Credit card installments organized on a timeline"
- Reusable `EmptyStateWidget` with `illustration`, `title`, `subtitle`, `actionLabel`, `onAction`

**Phase D2 — Initial setup checklist**
- Card on dashboard for new users (first 7 days): "Complete your financial profile"
- Items: ✓ Add income · ✓ Set budget · ✓ Record first expense · ✓ Set up a recurring
- Persists in Drift `UserSettings` (key `'onboarding_checklist'`)
- Hides when all items are checked or when user dismisses it

**Phase D3 — Interactive tutorial (first use)**
- 3-4 steps when opening the app for the first time (post-signup)
- Step 1: "Welcome to Farol! Let's set up your financial period" → `cutoffDay` picker
- Step 2: "What's your monthly income?" → quick income entry
- Step 3: "Set your budget goals" → top 3 categories with suggested %
- Step 4: "Done! Here's what Farol projects for you" → real dashboard with user data
- Flag `'onboarding_completed'` in Drift `UserSettings`

**Phase D4 — Push notifications (optional, mobile)**
- "You haven't recorded any expenses this week" (Wednesday if no activity)
- "Your projected balance will go negative in X days" (when `LiquidityRisk` is high)
- FCM setup in Flutter + Supabase Edge Function for sending
- Explicit opt-in during onboarding

### Impacted files
```
lib/core/widgets/empty_state_widget.dart (new)
lib/features/dashboard/widgets/onboarding_checklist_card.dart (new)
lib/features/onboarding/screens/onboarding_flow_screen.dart (new)
lib/core/database/app_database.dart (new keys in UserSettings)
lib/main.dart (check onboarding_completed flag on startup)
```

### Risks
- Tutorial too long → user skips it → no data → app still looks empty. Keep to max 4 steps.
- Checklist may create negative pressure ("pending tasks") — use motivating language, not obligation
- Push notifications require iOS permission — ask only after user has seen real value

---

## AREA E — Quality: Tests + Static Analysis

### Goal
Close the test coverage gaps marked as `⚠️ partial` on the roadmap. Ensure `flutter analyze` stays clean at all times.

### Current test status

| Suite | Tests | Status |
|---|---|---|
| `forecasting_engine_test.dart` | 30 | ✅ |
| `intelligence_layer_test.dart` | 22 | ✅ |
| `recurrence_resolver_test.dart` | — | ✅ |
| `installment_service_test.dart` | — | ✅ |
| `sync/` | 29 | ✅ |
| `financial_engine_test.dart` | ⚠️ | Partial |
| `categories_resolver_test.dart` | ⚠️ | Partial |
| `envelope_engine_test.dart` | ❌ | Missing |
| `budget_recommendation_service_test.dart` | ❌ | Missing (new service) |
| Widget tests | ❌ | Nonexistent |

### Phases

**Phase E1 — Complete FinancialEngine tests**
- Cases: snapshot with 0 income, snapshot with only recurring, snapshot with active installments
- Edge cases: `cutoffDay` on day 28/29/30/31, February month
- Minimum 20 new tests

**Phase E2 — EnvelopeEngine tests**
- Cases: positive rollover, negative rollover, envelope without budget defined
- Edge cases: Swile envelope separated from cash pool

**Phase E3 — CategoryResolver tests**
- Cases: system category, custom category, deleted category (soft delete), Swile category

**Phase E4 — Tests for new BudgetRecommendationService** *(depends on Area B)*
- Cases: user with no history, user with < 1 month history, user with spending outlier

**Phase E5 — Basic widget tests**
- `BurnRateCard` — rendered with empty snapshot vs. with data
- `InsightsPanel` — rendered with empty list, with 1 insight, with 3 insights
- `WorkspaceAppBarChip` — personal vs. shared, with/without presence

### Impacted files
```
test/unit/financial_engine_test.dart
test/unit/envelope_engine_test.dart
test/unit/category_resolver_test.dart
test/unit/budget_recommendation_service_test.dart
test/widget/burn_rate_card_test.dart
test/widget/insights_panel_test.dart
test/widget/workspace_app_bar_chip_test.dart
```

---

## AREA F — Internal Documentation: Migration to English

> **Source plan**: `PHASE_2_TRANSLATION_STATUS.md` (already exists)

### Current status (60% complete)

Code files are 100% in English. Internal documents (`plans/`, `docs/`) have mixed Spanish/English content.

### Phases

**Phase F1 — Remaining plans** (30–45 min each)
- `plans/installments_redesign.md`
- `plans/recurring_rules.md`
- `plans/intelligence_layer.md`
- `plans/ui_provider_migration.md`
- `plans/multiuser_freemium.md`

**Phase F2 — Architecture docs**
- `docs/architecture/overview.md`
- `docs/architecture/ui_audit_2026_05_08.md`

**Strategy**: batch replace common terms (see `PHASE_2_TRANSLATION_STATUS.md`), then manual review of critical sections.

**Note**: This area is low priority — does not impact the product. Address only once the rest is well advanced.

---

## 📋 Recommended Implementation Order

```
SPRINT 1 (Day-1 user impact)
  D1 → Narrative empty states
  D2 → Initial setup checklist
  A1 → Enhanced signup (name + CPF + terms)
  A2 → Edit Profile UI redesign

SPRINT 2 (Data quality + Budget UX)
  B1 → Category localization in Budget
  B2 → Percentage validation
  A3 → Extended profiles data model
  A4 → Validation + masks

SPRINT 3 (Product completeness)
  B3 → Swile pool separation
  D3 → First-use tutorial
  A5 → Real avatar upload
  E1 → FinancialEngine tests
  E2 → EnvelopeEngine tests

SPRINT 4 (Monetization)
  B4 → AI budget recommendations
  C1 → Define Free tier limits
  C2 → Paywall UI
  E3–E5 → Remaining tests

SPRINT 5 (Real monetization)
  C3 → RevenueCat (mobile)
  C4 → Stripe (web)
  C5 → Trial + Offboarding
  D4 → Push notifications

PARALLEL / WHEN THERE'S TIME
  F1, F2 → Migrate docs to English
```

---

## 🔗 Cross-Area Dependencies

```
A1 → A2 → A3 → A4 → A5   (profile: sequential)
B1 → B2 → B3 → B4         (budget: sequential)
D1 → D2 → D3 → D4         (onboarding: sequential)
C1 → C2 → C3              (monetization: sequential)
C3 || C4                   (RevenueCat and Stripe: parallel to each other)
B4 → C2                    (AI recommendations as Premium feature for paywall)
A3 → C3                    (`plan` column in profiles used by RevenueCat webhook)
E4 → B4                    (new service tests depend on the service existing)
```

---

## 📈 Success Metrics

| Area | Metric | Target |
|---|---|---|
| Onboarding | % users completing initial checklist | > 60% |
| Onboarding | Time to first recorded expense | < 3 min post-signup |
| Budget | Budget % > 100% alerts in production | 0 |
| Budget | Categories shown in wrong language | 0 |
| Monetization | Free → Premium conversion (post-trial) | > 8% |
| Monetization | Monthly Premium churn | < 5% |
| Quality | `flutter analyze` warnings | 0 at all times |
| Quality | Domain layer test coverage | > 80% |
| Profile | Users with profile photo | > 30% (month 3) |

---

## 🚨 Global Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| App Store / Play Store paywall rejection | Medium | High | Ensure Free is genuinely functional, not artificially limited |
| RevenueCat or Stripe takes longer than expected to set up | High | Medium | Phase C2 (paywall UI without real payments) as testable MVP before integration |
| Onboarding tutorial increases time to first use | Medium | Medium | A/B test: with tutorial vs. without, measure time to first expense |
| Migration A3 (`plan` column) may break existing RLS | Low | High | Test on staging before production, have rollback SQL ready |
| Budget recommendations with sparse history generate absurd suggestions | High | Medium | Fallback to hardcoded 50/30/20 rule when history < 30 days |

---

## 📁 New Files Created by This Plan

```
lib/core/widgets/empty_state_widget.dart
lib/features/dashboard/widgets/onboarding_checklist_card.dart
lib/features/onboarding/screens/onboarding_flow_screen.dart
lib/features/paywall/screens/paywall_screen.dart
lib/core/services/revenue_cat_service.dart
lib/core/domain/services/budget_recommendation_service.dart
test/unit/financial_engine_test.dart (complete)
test/unit/envelope_engine_test.dart
test/unit/category_resolver_test.dart
test/unit/budget_recommendation_service_test.dart
test/widget/burn_rate_card_test.dart
test/widget/insights_panel_test.dart
test/widget/workspace_app_bar_chip_test.dart
supabase/functions/create-checkout-session/index.ts
supabase/functions/stripe-webhook/index.ts
database/migrations/V37__profiles_extended_fields.sql
database/migrations/V38__workspace_plan_trial.sql
```

---

## ▶️ Activation Commands

Use the standard project commands (see `CLAUDE.md`):

```
"Analyze plans/farol_polish_plan.md"                    → analysis of a specific area
"Implement Phase D1 of plans/farol_polish_plan.md"      → implement empty states
"Implement Phase A1 of plans/farol_polish_plan.md"      → implement enhanced signup
"Implement Phase B1 of plans/farol_polish_plan.md"      → budget localization
"Implement Phase C2 of plans/farol_polish_plan.md"      → paywall UI
```

---

*Plan created on 2026-05-11. Next review: when Sprint 1 is complete.*
