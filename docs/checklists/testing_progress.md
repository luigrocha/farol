# Automation Checklist — Farol

## 🔐 Auth (Phase 1 — COMPLETE)

### Unit Tests (AuthNotifier)
- [x] Registration: happy path → AsyncData
- [x] Registration: duplicate email → AsyncError "already registered"
- [x] Registration: weak password → AsyncError
- [x] Registration: password < 6 chars rejected by FakeRepo
- [x] Login: successful login → AsyncData
- [x] Login: invalid credentials → AsyncError "Invalid email or password"
- [x] Login: network error → AsyncError
- [x] Login: unknown user → AsyncError
- [x] Logout → AsyncData, session cleared
- [x] Password reset: happy path → AsyncData
- [x] Password reset: network error → AsyncError

### Widget Tests — LoginScreen
- [x] Empty form → validation errors
- [x] Invalid email → email error
- [x] Password < 6 chars → length error
- [x] Valid email + password → no validation errors
- [x] Loading state: button disabled during request
- [x] Error recovery: button re-enabled after error
- [x] Invalid credentials → error visible in UI
- [x] Network error → error visible in UI
- [x] "Sign up" link → navigates to /signup
- [x] "Forgot password" empty → SnackBar
- [x] "Forgot password" with email → confirmation SnackBar
- [x] Password obscured by default
- [x] Password visibility toggle

### Widget Tests — SignUpScreen
- [x] Empty form → errors on all required fields
- [x] Invalid email → email error
- [x] Passwords don't match → "don't match" error
- [x] Terms not accepted → blocks submission and shows error
- [x] Weak password → strength meter "Very weak"
- [x] Strong password → strength meter "Strong/Good"
- [x] Duplicate email → "already registered" error
- [x] Network error → error visible in UI
- [x] Button disabled during loading
- [x] "Sign in" link → navigates to /login

### Integration Tests — Auth Flow
- [x] Cold start without session → landing on onboarding/login
- [x] New user registration → form without validation errors
- [x] Valid login → navigates away from login
- [x] Invalid login → stays on login with error
- [x] Session recovery: authenticated user → skips login
- [x] Logout → session cleared, stream emits Unauthenticated

### Infrastructure
- [x] `FakeAuthRepository` (in-memory, no network)
- [x] `test_helpers.dart` (pumpApp, pumpAppWithFakeAuth)
- [x] `supabaseClientProvider` (DI for testability)
- [x] `SupabaseAuthRepository` accepts `SupabaseClient` via constructor
- [x] CI: GitHub Actions (unit/widget + integration + web build)

---

## 🏢 Workspace (Phase 4)
- [ ] Workspace switcher
- [ ] Data isolation across workspaces
- [ ] Permissions (Viewer vs Owner)

## 💸 Transactions (Phase 2)
### Unit Tests — Fakes
- [x] `FakeExpenseRepository` (CRUD, watchAll, updateFixedSeriesFrom, error simulation)
- [x] `FakeIncomeRepository` (CRUD, watchAll, seedId, error simulation)

### Unit Tests — Fake correctness
- [x] `FakeExpenseRepository` — 13 tests (insert, getAll, getByRange, update, delete, watchAll, updateFixedSeriesFrom, error recovery)
- [x] `FakeIncomeRepository` — 18 tests (insert, getAll, getByRange, update, delete, watchAll, error recovery)

### Widget Tests — QuickAddBottomSheet (create expense)
- [x] Form rendered (amount, categories, payment methods, fixed toggle, save)
- [x] Validation: empty amount → snackbar
- [x] Installment field appears when Credit (Installments) selected
- [x] Create simple expense → saved to repository
- [x] Create expense with selected category
- [x] Create fixed expense → isFixed = true
- [x] Network error → snackbar

### Widget Tests — EditExpenseBottomSheet (edit expense)
- [x] Loads existing amount into text field
- [x] Shows edit expense title
- [x] Shows category grid
- [x] Shows payment method chips
- [x] Shows save button
- [x] Save updates expense in repository
- [x] Save with different category updates category
- [x] Fixed expense shows scope dialog
- [x] Network error shows snackbar
> ✅ Fixed: ensureVisible before SAVE tap (off-screen), scope dialog text now matches hardcoded pt_BR

### Widget Tests — EditIncomeBottomSheet (edit income) ✅ NEW
- [x] Loads existing amount into text field
- [x] Shows edit income title
- [x] Shows income type chips
- [x] Shows net value toggle
- [x] Shows notes field with pre-filled value
- [x] Shows save button
- [x] Save updates income in repository
- [x] Save with notes updates notes
- [x] Shows salary calculation for NET_SALARY type
- [x] Hides salary calculation for other types
- [x] Shows breakdown when income has inss/irrf deductions
- [x] Invalid amount shows snackbar
- [x] Network error shows snackbar

## 📅 Recurring & Installments (Phase 4)
- [ ] Payment generation
- [ ] Propagation of changes in recurring rules
- [ ] Completion of installment plans

## 📊 Budget & Forecasting (Phase 3)
### Domain Logic — existing (103 tests)
- [x] FinancialEngine: income, expenses, balance, savingsRate, healthScore (20 tests)
- [x] EnvelopeEngine: basic allocation, rollover, status, aggregates (16 tests)
- [x] ForecastingEngine: BurnRate, Projection, DaysUntilEmpty, LiquidityRisk, ObligationEngine (38 tests)
- [x] IntelligenceLayer: overdraft, liquidity, duplicates, investment, streak, debt, unusual merchants (29 tests)

### Fakes
- [x] `FakePeriodBudgetRepository` — in-memory seed/upsert/getBudgets/delete/copyFromPeriod with error simulation

### Widget Tests — BudgetEditSheet (10 tests) ✅ NEW
- [x] Shows "New Budget" title when creating
- [x] Shows category dropdown
- [x] Shows amount field
- [x] Shows "Create Budget" button
- [x] Shows "Edit Budget" title when editing
- [x] Shows "Save Changes" button when editing
- [x] Create budget saves to repository (no error)
- [x] Empty amount shows snackbar
- [x] Edit shows goal amount label
- [x] Network error shows snackbar

### Missing
- [ ] PeriodBudgetScreen widget tests (main budget screen)
- [ ] BudgetGoalsSheet widget tests (percentage allocation)
- [ ] BudgetSettingsSheet widget tests (net salary / Swile settings)

## 🔄 Sync & Offline (Phase 4)
### Unit Tests — SyncManager path (ExpenseRepository.insert)
- [x] Routes through SyncManager in offline mode → returns 0 sentinel
- [x] InsertExpenseOperation carries correct payload fields
- [x] Real SyncManager enqueues operation when offline
- [x] Without SyncManager, insert goes directly to Supabase (no queueing)
> ✅ Fixed 2026-05-13: setOnlineForTest(false) required after repo refactored to write directly to Supabase when online
- [ ] Synchronization when network recovers
- [ ] Basic conflict resolution
