# English Migration Plan

**Status**: ✅ COMPLETE (2026-05-09)
**Scope**: Translate all documentation, plans, and code comments to English

---

## Phase 1: Critical Documentation ✅ COMPLETE

- ✅ `CLAUDE.md` — translated and updated

---

## Phase 2: Implementation Plans + Architecture Docs ✅ COMPLETE

- ✅ `plans/categories_redesign.md` — was already in English
- ✅ `plans/financial_engine.md` — was already in English
- ✅ `plans/forecasting.md` — was already in English
- ✅ `plans/offline_sync.md` — was already in English
- ✅ `plans/installments_redesign.md` — translated from Portuguese/mixed
- ✅ `plans/recurring_rules.md` — translated from Portuguese
- ✅ `plans/intelligence_layer.md` — translated from Portuguese
- ✅ `plans/ui_provider_migration.md` — translated from Portuguese
- ✅ `plans/multiuser_freemium.md` — rewritten in English (was Portuguese)
- ✅ `docs/architecture/overview.md` — was mostly in English, updated with current status
- ✅ `docs/architecture/ui_audit_2026_05_08.md` — translated from Portuguese

---

## Phase 3: Architecture Decision Records (ADRs) ✅ COMPLETE

- ✅ `docs/decisions/ADR_TEMPLATE.md` — translated from Spanish
- ✅ `docs/decisions/001-category-unification.md` — translated from Spanish
- ✅ `docs/decisions/002-financial-snapshot.md` — translated from Spanish
- ✅ `docs/decisions/003-forecasting-deterministic.md` — translated from Spanish
- ✅ `docs/decisions/004-sync-strategy.md` — translated from Spanish
- ✅ `docs/decisions/005-installments-redesign.md` — translated from Portuguese/Spanish
- ✅ `docs/decisions/006-recurring-rules.md` — translated from Portuguese/Spanish
- ✅ `docs/decisions/007-intelligence-layer.md` — translated from Portuguese
- ✅ `docs/decisions/adr_cashflow_forecast_cache.md` — translated from Portuguese

---

## Phase 4: Product Roadmap + Memory Files ✅ COMPLETE

- ✅ `docs/roadmaps/product_roadmap.md` — rewritten in English, statuses updated
- ✅ `docs/plans/README.md` — translated from Spanish
- ✅ `/memory/farol_project_context.md` — updated in English
- ✅ `/memory/farol_project_conventions.md` — was already in English

---

## Phase 5: Dart Code Comments (Ongoing)

- Scan `lib/**/*.dart` for Portuguese/Spanish comments
- Translate inline comments and docstrings as code is edited
- Follow convention: all new code in English

**Priority**: Medium (migrate incrementally with feature work)

---

## Notes

- All file names unchanged — only content translated
- Technical terms (`Workspace`, `Provider`, `CategoryRef`, etc.) remain unchanged
- Portuguese pt_BR content in app strings stays pt_BR (only code/docs in English)
- ADR statuses updated to reflect actual implementation state (all marked ✅ Implemented)
