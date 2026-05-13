# Automation Checklist — Farol

## 🔐 Auth (Fase 1 — COMPLETO)

### Unit Tests (AuthNotifier)
- [x] Registro: happy path → AsyncData
- [x] Registro: email duplicado → AsyncError "already registered"
- [x] Registro: password débil → AsyncError
- [x] Registro: password < 6 chars rechazada por FakeRepo
- [x] Login: login exitoso → AsyncData
- [x] Login: credenciales inválidas → AsyncError "Invalid email or password"
- [x] Login: error de red → AsyncError
- [x] Login: usuario desconocido → AsyncError
- [x] Logout → AsyncData, sesión limpiada
- [x] Password reset: happy path → AsyncData
- [x] Password reset: error de red → AsyncError

### Widget Tests — LoginScreen
- [x] Formulario vacío → errores de validación
- [x] Email inválido → error de email
- [x] Password < 6 chars → error de longitud
- [x] Email + password válidos → sin errores de validación
- [x] Loading state: botón deshabilitado durante request
- [x] Error recovery: botón re-habilitado tras error
- [x] Credenciales inválidas → error visible en UI
- [x] Error de red → error visible en UI
- [x] Link "Sign up" → navega a /signup
- [x] "Forgot password" vacío → SnackBar
- [x] "Forgot password" con email → SnackBar confirmación
- [x] Password es obscura por defecto
- [x] Toggle visibilidad de password

### Widget Tests — SignUpScreen
- [x] Formulario vacío → errores en todos los campos requeridos
- [x] Email inválido → error de email
- [x] Passwords no coinciden → error "don't match"
- [x] Sin aceptar términos → bloquea envío y muestra error
- [x] Password débil → strength meter "Very weak"
- [x] Password fuerte → strength meter "Strong/Good"
- [x] Email duplicado → error "already registered"
- [x] Error de red → error visible en UI
- [x] Botón deshabilitado durante loading
- [x] Link "Sign in" → navega a /login

### Integration Tests — Auth Flow
- [x] Cold start sin sesión → landing en onboarding/login
- [x] Registro nuevo usuario → formulario sin errores de validación
- [x] Login válido → navega fuera del login
- [x] Login inválido → permanece en login con error
- [x] Session recovery: usuario autenticado → salta login
- [x] Logout → sesión limpiada, stream emite Unauthenticated

### Infraestructura
- [x] `FakeAuthRepository` (in-memory, sin red)
- [x] `test_helpers.dart` (pumpApp, pumpAppWithFakeAuth)
- [x] `supabaseClientProvider` (DI para testeabilidad)
- [x] `SupabaseAuthRepository` acepta `SupabaseClient` por constructor
- [x] CI: GitHub Actions (unit/widget + integration + web build)

---

## 🏢 Workspace (Fase 4)
- [ ] Switch de workspace
- [ ] Aislamiento de datos entre workspaces
- [ ] Permisos (Viewer vs Owner)

## 💸 Transactions (Fase 2)
### Unit Tests — Fakes
- [x] `FakeExpenseRepository` (CRUD, watchAll, updateFixedSeriesFrom, error simulation)
- [x] `FakeIncomeRepository` (CRUD, watchAll, seedId, error simulation)

### Unit Tests — Fake correctness
- [x] `FakeExpenseRepository` — 13 tests (insert, getAll, getByRange, update, delete, watchAll, updateFixedSeriesFrom, error recovery)
- [x] `FakeIncomeRepository` — 18 tests (insert, getAll, getByRange, update, delete, watchAll, error recovery)

### Widget Tests — QuickAddBottomSheet (criar gasto)
- [x] Formulário renderizado (amount, categories, payment methods, fixed toggle, save)
- [x] Validação: empty amount → snackbar
- [x] Installment field aparece quando Credit (Installments) selecionado
- [x] Criar gasto simples → salvo no repositório
- [x] Criar gasto com categoria selecionada
- [x] Criar gasto fixo → isFixed = true
- [x] Network error → snackbar

### Widget Tests — EditExpenseBottomSheet (editar gasto)
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

### Widget Tests — EditIncomeBottomSheet (editar receita) ✅ NEW
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

## 📅 Recurring & Installments (Fase 4)
- [ ] Generación de cuotas
- [ ] Propagación de cambios en recurrentes
- [ ] Finalización de planes de cuotas

## 📊 Budget & Forecasting (Fase 3)
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

## 🔄 Sync & Offline (Fase 4)
### Unit Tests — SyncManager path (ExpenseRepository.insert)
- [x] Routes through SyncManager in offline mode → returns 0 sentinel
- [x] InsertExpenseOperation carries correct payload fields
- [x] Real SyncManager enqueues operation when offline
- [x] Without SyncManager, insert goes directly to Supabase (no queueing)
> ✅ Fixed 2026-05-13: setOnlineForTest(false) required after repo refactored to write directly to Supabase when online
- [ ] Sincronización al recuperar red
- [ ] Resolución de conflictos básica
