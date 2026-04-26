# 📋 Next Steps - Farol

## Strategic Recommendations

Based on the analysis of the current state (April 25, 2026), here are the priority recommendations for future development of Farol.

---

## 🎯 Priority 1: Cleanup & Stabilization (Short Term)

### 1.1 Feature Branch Audit
**Status**: There are 11 feature branches that may be outdated  
**Recommended action**:
- Review each branch vs. `develop` to identify:
  - ✅ Work in Progress (WIP) that can be merged
  - ⚠️ Outdated code that needs rebasing
  - ❌ Abandoned features that should be deleted

**Critical branches to review**:
```
origin/feature/dark-mode              # Potential conflict with recent design system
origin/feature/user-preferences-sync  # May affect Supabase integration
origin/feature/recurring-fixed-expenses
origin/feature/edit-delete-transaction
origin/feature/messages-toast
```

**Useful commands**:
```bash
# View differences between feature and develop
git diff develop..feature/dark-mode --stat

# Check if rebase is needed
git merge-base develop feature/dark-mode
git log develop..feature/dark-mode --oneline
```

### 1.2 Test Verification
**Status**: Basic tests exist but coverage is limited  
**Recommended action**:
- Run full suite: `flutter test`
- Verify coverage in critical areas:
  - ✅ Financial calculations (INSS, IRRF, health score)
  - ✅ Budget and alert logic
  - ⚠️ Supabase authentication flow
  - ⚠️ User preferences sync

**Implement**:
- Unit tests for `FinancialCalculatorService`
- Integration tests for Supabase auth
- Widget tests for new design system components

### 1.3 Remove Code Duplication
**Status**: i18n recently integrated; potential duplication in features  
**Recommended action**:
- Search for remaining hardcoded strings
- Unify access to `context.l10n` vs. local methods
- Consolidate notification styles (snackbars, dialogs)

---

## 🚀 Priority 2: Important Features (Medium Term)

### 2.1 Cloud Sync (Supabase)
**Status**: Supabase imported but integrations are partial  
**Impact**: Critical for multi-device support, automatic backup

**Features to implement**:
1. **Automatic data sync**
   - Incomes, expenses, investments → Supabase in real time
   - Pull sync on app open
   - Offline-first handling (local change queue)

2. **Backup & Restore**
   - Automatic daily backup → Supabase
   - Restore from backup on new device
   - Data versioning

3. **Synced user preferences**
   - Already partially implemented; complete:
     - Theme mode
     - Budget goals (selected categories)
     - Future currencies (if extended)

**Effort**: 2–3 weeks  
**Dependencies**: Defined Supabase schema, RLS policies

### 2.2 Multi-Currency Support (Expansion)
**Status**: Hardcoded to BRL  
**Impact**: Opens international markets

**Features**:
1. Currency selector in settings
2. Real-time exchange rates (OpenExchangeRates API)
3. Automatic conversions in analytics
4. Dynamic formatting (BRL, USD, EUR, etc.)

**Effort**: 1–2 weeks  
**Blockers**: Financial calculator changes, DB schema

### 2.3 Advanced Categorization
**Status**: Fixed categories; audit requires flexibility

**Features**:
1. **Custom categories** (create/edit/delete)
2. **Subcategories** (Grocery → Vegetables, Fruits)
3. **Auto-tags** (by text pattern)
4. **Recategorization rules** (when importing CSV)

**Effort**: 1.5 weeks  
**Dependencies**: DB schema update, new providers

---

## 🔧 Priority 3: Experience Improvements (Long Term)

### 3.1 Data Import
**Status**: Exports CSV/JSON; no import  
**Impact**: Easier migration from other apps

**Implement**:
- CSV importer (auto-detects columns)
- JSON importer (from Farol or Splitwise)
- Validation and preview before import
- Duplicate handling

**Effort**: 1 week

### 3.2 Advanced Reports
**Status**: Basic analytics (line charts, pie charts)  
**Impact**: Informed financial decisions

**Reports to add**:
1. **Monthly income/expense report**
   - Exportable PDF, comparative charts
2. **Annual trend analysis**
   - Average spending by category, seasonality
3. **Projections** (based on trends)
   - Expected spending in 12 months
   - Savings goal progress
4. **Budget vs. actual comparison**
   - Deviations by category

**Effort**: 2–3 weeks

### 3.3 Push Notifications (Optional)
**Status**: Not implemented  
**Impact**: Reminders, real-time alerts

**Use cases**:
- Budget near limit (daily at 8:00 PM)
- Transaction pending categorization
- Goal reached (savings, investment)
- Reminder to log income (1st of each month)

**Effort**: 1 week  
**Note**: Requires Firebase Cloud Messaging setup

---

## 📊 Priority 4: Optimization & Maintenance

### 4.1 Performance Tuning
**Areas to review**:
- Complex queries in analytics (large charts)
- Riverpod watch chains (eliminate unnecessary rebuilds)
- Bundle size (disable unused services)

### 4.2 Security
- JSON backup encryption (AES-256)
- Rate limiting on Supabase auth
- Input validation (SQL injection prevention)
- Secure token handling (Keychain/Secure Storage)

### 4.3 Documentation
- Video tutorial (5–10 min): "Getting started with Farol"
- Use case guide (CLT worker, freelancer, etc.)
- FAQ (13th salary calculation, FGTS, etc.)

---

## 📅 Recommended Roadmap (6 Months)

| Month | Goal | Status |
|-------|------|--------|
| **April** | Branch cleanup, tests, i18n (✅ DONE) | ✅ |
| **May** | Supabase sync, backup/restore | 🔲 |
| **June** | Advanced categorization, CSV import | 🔲 |
| **July** | PDF reports, projections | 🔲 |
| **August** | Multi-currency support | 🔲 |
| **September** | Optimization, security, v2.0 release | 🔲 |

---

## ⚠️ Current Technical Debt

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Outdated feature branches | Confusion, merge conflicts | 1–2 days | 🔴 High |
| Low test coverage | Production bugs | 1–2 weeks | 🔴 High |
| Supabase partially integrated | Incomplete sync | 2–3 weeks | 🟡 Medium |
| Potentially hardcoded strings | Inconsistent i18n | 1 day | 🟡 Medium |
| No input validation | Weak security | 3–4 days | 🟡 Medium |

---

## 🎯 Quick Wins (1–2 days)

Fast tasks that add immediate value:

1. **Merge ready feature branches**
   - Command: `git merge origin/feature/XXX --ff-only`
   - Validate tests pass before merging

2. **Validation script**
   - Create `scripts/validate.sh` that runs:
     ```bash
     flutter analyze
     flutter test
     dart run build_runner build
     ```

3. **Document Supabase schema**
   - Create `docs/SUPABASE_SCHEMA.md`
   - List tables, RLS policies, triggers

4. **Setup CI/CD pipeline** (GitHub Actions)
   - Test on every push to develop
   - Build APK/IPA on release
   - Auto-deploy to TestFlight/Play Console

---

## 📝 How to Use This Document

1. **For each sprint**: Select tasks from a priority section
2. **Tracking**: Update status (✅ Done, 🔄 In Progress, 🔲 To Do)
3. **Blockers**: If a task is blocked, document the reason here
4. **Retrospective**: At month end, review what went well/poorly

---

## 📚 Useful References

- **Feature Branches Status**: `git branch -vv`
- **Unmerged commits**: `git log main..develop --oneline`
- **Test Coverage**: `flutter test --coverage && lcov --list coverage/lcov.info`
- **Bundle Size**: `flutter build apk --split-per-abi && ls -lh build/app/outputs/`
- **Performance**: `flutter run --profile && DevTools`

---

**Last updated**: April 25, 2026  
**Owner**: Luis Rocha
