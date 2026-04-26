# 🎯 Executive Recommendations - Farol

## Current Project Status ✨

- ✅ **i18n completed** (PT, EN, ES)
- ✅ **Design system implemented** (Material 3)
- ✅ **Financial calculations stable** (INSS, IRRF, Health Score)
- ✅ **Functional dashboard** with budget alerts
- ✅ **Data export** (CSV + JSON)
- ✅ **Simulators** (13th salary, FGTS Saque Aniversário)
- ⚠️ **Supabase partially integrated** (Auth OK, sync pending)
- ⚠️ **11 outdated feature branches**
- ⚠️ **Low test coverage**

---

## 🚀 Top 5 Recommendations (Priority Order)

### 1️⃣ CRITICAL: Audit & Clean Feature Branches (1–2 days)

**Problem**: 11 potentially outdated feature branches may cause merge conflicts  
**Action**:
```bash
# For each outdated branch:
git diff develop..origin/feature/XXX --stat
git rebase develop origin/feature/XXX
git push --force origin feature/XXX
```

**Branches to review first**:
- `feature/dark-mode` ← May conflict with design system
- `feature/user-preferences-sync` ← Affects Supabase
- `feature/recurring-fixed-expenses` ← High user demand

**Outcome**: Clarity on what can be merged vs. deleted

---

### 2️⃣ IMPORTANT: Complete Supabase Sync (2–3 weeks)

**Problem**: Local data is not synced across devices  
**Benefit**: Automatic backup, multi-device, data portability

**Phases**:
1. **Read-Only Sync** (week 1)
   - Pull `budget_goals`, `user_settings` on app open
   - Verify that preference changes in Supabase update the UI

2. **Write Sync** (week 2)
   - Save `expenses`, `incomes`, `investments` to Supabase
   - Offline-first handling (local change queue)
   - Conflict reconciliation

3. **Backup & Restore** (week 3)
   - Automatic daily backup (JSON)
   - Restore on new device

**Impact**: Premium feature ("always-synced data")

---

### 3️⃣ IMPORTANT: Improve Test Coverage (1–2 weeks)

**Critical areas without tests**:
- ❌ `FinancialCalculatorService` (INSS, IRRF, health score)
- ❌ Supabase auth flow
- ❌ Sync logic

**Plan**:
```bash
# Today: Run current suite
flutter test

# This week: Add tests for financial calculator
# Structure:
test/
├── core/
│   ├── services/
│   │   └── financial_calculator_service_test.dart
│   └── providers/
│       └── providers_test.dart
└── features/
    ├── auth/
    │   └── auth_integration_test.dart
    └── dashboard/
        └── dashboard_widget_test.dart
```

**Outcome**: Confidence in changes, fewer production bugs

---

### 4️⃣ FEATURE: Advanced Categorization (1.5 weeks)

**Current Problem**: Hardcoded categories limit flexibility  
**Solution**:
- Add `custom_categories` table to DB
- UI to create/edit/delete categories
- Providers to update categories dynamically

**Impact**: Users can organize expenses their way

---

### 5️⃣ FEATURE: CSV Import (1 week)

**Benefit**: Easy migration from Excel, Splitwise, N26, etc.

**Implement**:
1. FilePicker to select CSV
2. Automatic column detection (date, amount, category)
3. 10-row preview before import
4. Deduplication (avoid duplicate transactions)

---

## 📊 Effort vs. Impact Comparison

| Feature | Effort | Impact | Quick Win? |
|---------|--------|--------|------------|
| Clean branches | 2 days | 🟢 High | ✅ YES |
| Tests | 2 weeks | 🟢 High | ❌ NO |
| Supabase sync | 3 weeks | 🟢 High | ❌ NO |
| Custom categories | 1.5 wks | 🟡 Medium | ❌ NO |
| CSV import | 1 week | 🟡 Medium | ✅ YES |
| Multi-currency | 2 weeks | 🟡 Medium | ❌ NO |
| PDF reports | 2 weeks | 🟡 Medium | ❌ NO |
| Push notifications | 1 week | 🔴 Low | ✅ YES |

---

## 📅 Suggested 12-Week Plan

```
Weeks 1–2:   Branch cleanup + test setup
Weeks 3–5:   Supabase sync (read → write → backup)
Weeks 6–7:   Advanced categorization
Week 8:      CSV import
Weeks 9–10:  PDF reports + analytics
Week 11:     Optimization + security
Week 12:     Bug fixes + v2.0 release candidate
```

---

## 🔴 Risks to Mitigate

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Merge conflicts from old branches | 🔴 High | 🔴 High | Resolve NOW (1–2 days) |
| Incorrect Supabase RLS policies | 🟡 Medium | 🔴 High | Audit + tests before deploy |
| Data loss during sync | 🟡 Medium | 🔴 High | Implement local backup, versioning |
| Performance in analytics (big datasets) | 🟡 Medium | 🟡 Medium | Paginate, lazy load, memoization |

---

## ✨ Quick Wins (Do Today)

Tasks that take <1 day but add value:

1. **Create validation script**
   ```bash
   cat > scripts/validate.sh << 'EOF'
   #!/bin/bash
   echo "Running linter..."
   flutter analyze || exit 1
   echo "Running tests..."
   flutter test || exit 1
   echo "Running build_runner..."
   dart run build_runner build || exit 1
   echo "✅ All checks passed!"
   EOF
   chmod +x scripts/validate.sh
   ```

2. **Document Supabase schema**
   - Create `docs/SUPABASE.md` listing tables, columns, RLS policies
   - Speeds up onboarding for new devs

3. **Merge feature branches that are ready**
   - `git log develop..origin/feature/XXX` to see commits
   - If all good: `git merge origin/feature/XXX`

4. **Setup basic GitHub Actions**
   ```yaml
   name: Test & Lint
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - uses: subosito/flutter-action@v2
         - run: flutter pub get
         - run: flutter analyze
         - run: flutter test
   ```

---

## 📝 Tracking & Communication

**To keep the project healthy**:

1. **Update `NEXT_STEPS.md` monthly**
   - Mark tasks as ✅ Done, 🔄 In Progress, 🔲 To Do
   - Document blockers

2. **Branch review every 2 weeks**
   - Merge what's ready
   - Delete what's abandoned
   - Rebase what's needed

3. **Test coverage baseline**
   ```bash
   flutter test --coverage
   # Keep >70% coverage in core/ and features/
   ```

---

## 🎯 Conclusion

**Next action**: Spend 1–2 days cleaning up feature branches  
**Benefit**: Clarity, fewer merge conflicts, better productivity  
**After that**: Evaluate which feature is more urgent (sync or tests)

**The project is in good shape** 🚀 — it just needs cleanup and consolidation before scaling.

---

*Generated: April 25, 2026*  
*For questions or adjustments, see `NEXT_STEPS.md`*
