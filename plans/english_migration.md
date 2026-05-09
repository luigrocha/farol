# English Migration Plan

**Status**: Phase 1 complete, Phase 2-4 planned  
**Updated**: 2026-05-09  
**Scope**: Translate all documentation, plans, and code comments to English

---

## Phase 1: Critical Documentation ✅ COMPLETE

- ✅ `CLAUDE.md` — translated
- ⏳ Strategic docs (FAROL_PREDICTIVE_ENGINE.md, README.md, NEXT_STEPS.md)

**Phase 1 Progress**: 50% (CLAUDE.md done, strategic docs pending)

---

## Phase 2: Implementation Plans + Architecture Docs (Next)

### Files to Translate
- `plans/categories_redesign.md`
- `plans/financial_engine.md`
- `plans/forecasting.md`
- `plans/offline_sync.md`
- `plans/installments_redesign.md`
- `plans/recurring_rules.md`
- `plans/intelligence_layer.md`
- `plans/ui_provider_migration.md`
- `plans/multiuser_freemium.md`
- `docs/architecture/overview.md`
- `docs/architecture/ui_audit_2026_05_08.md`

**Effort**: ~1,500 lines of technical documentation  
**Priority**: High (enables work planning and communication)  
**Estimated**: 2-3 hours

---

## Phase 3: Architecture Decision Records (ADRs)

### Files to Translate
- `docs/decisions/ADR_TEMPLATE.md`
- `docs/decisions/001-category-unification.md`
- `docs/decisions/002-financial-snapshot.md`
- `docs/decisions/003-forecasting-deterministic.md`
- `docs/decisions/004-sync-strategy.md`
- `docs/decisions/005-installments-redesign.md`
- `docs/decisions/006-recurring-rules.md`
- `docs/decisions/007-intelligence-layer.md`
- `docs/decisions/adr_cashflow_forecast_cache.md`

**Effort**: ~800 lines  
**Priority**: High (reference documentation)  
**Estimated**: 1-2 hours

---

## Phase 4: Product Roadmap + Memory Files

### Files to Translate
- `docs/roadmaps/product_roadmap.md`
- `/memory/farol_project_conventions.md`
- `/memory/farol_project_context.md`

**Effort**: ~200 lines  
**Priority**: Medium (context documentation)  
**Estimated**: 30-45 minutes

---

## Phase 5: Dart Code Comments (Ongoing)

- Scan `lib/**/*.dart` for Portuguese/Spanish comments
- Translate inline comments and docstrings as code is edited
- Follow convention: all new code in English

**Priority**: Medium (migrate incrementally with feature work)

---

## Workflow

For each phase:
1. **List files** to be translated
2. **Read** first file
3. **Translate** with care for technical terminology
4. **Verify** section by section
5. **Move to next**

---

## Activation Commands

- `"Implement Phase 2 of plans/english_migration.md"` → start translating plans
- `"Translate plans/categories_redesign.md"` → translate single file
- `"Review English migration progress"` → check status

---

## Notes

- Preserve all markdown formatting, code blocks, and special characters
- Keep file names unchanged (only content)
- Technical terms (e.g., `Workspace`, `Provider`) remain unchanged
- Portuguese pt_BR content in app strings stays pt_BR (only code/docs get English)
