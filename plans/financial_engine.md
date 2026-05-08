# Plan: Financial Engine Central
**Área**: Domain · Services · Providers
**Prioridad**: P1
**Dependencias**: `categories_redesign.md` (Fase 3 completa)
**Archivos impactados**: Nuevos archivos en `lib/core/domain/`, refactor de `DashboardScreen`, providers

---

## 🔍 Contexto del Problema

### Estado actual (confirmado en código)

```dart
// PROBLEMA: Cada widget calcula su propia versión de la verdad financiera

// Widget A: calcula totalExpenses de una forma
class KpiGrid extends ConsumerWidget {
  // ref.watch(expenseProvider) → suma expenses del período
}

// Widget B: calcula el balance de otra forma
class PeriodBalanceHero extends ConsumerWidget {
  // ref.watch(incomeProvider) - ref.watch(expenseProvider)
  // usa lógica diferente, diferente filtrado
}

// Widget C: calcula health score con sus propios inputs
class HealthGaugeCard extends ConsumerWidget {
  // llama FinancialCalculatorService.calculateHealthScore(...)
  // con datos que puede no tener completos
}

// RESULTADO: 3 widgets, 3 fuentes de verdad, posibles inconsistencias
```

```dart
// FinancialCalculatorService es un conjunto de funciones estáticas
// No tiene estado, no produce un snapshot coherente
// No hay "el estado financiero del período" — solo cálculos aislados
class FinancialCalculatorService {
  static double calculateSavingsRate(...)   // solo esto
  static int calculateHealthScore(...)       // solo esto
  // etc.
}
```

### ¿Qué se necesita?

Un único observable que produzca **el estado financiero completo del período**. Todos los widgets consumen este observable — una sola fuente de verdad.

```dart
// OBJETIVO: esto
final snapshot = ref.watch(financialSnapshotProvider(period));
// snapshot.totalIncome, snapshot.totalSpent, snapshot.healthScore,
// snapshot.envelopes, snapshot.burnRate, ...
```

---

## 📐 Arquitectura Propuesta

### Estructura de archivos nuevos

```
lib/core/domain/
├── entities/
│   ├── financial_snapshot.dart      ← el objeto central
│   ├── envelope.dart                ← presupuesto por categoría
│   └── scheduled_payment.dart       ← cuotas + recurrentes futuros
├── value_objects/
│   ├── money.dart                   ← tipo seguro para dinero
│   ├── category_ref.dart            ← (del plan categories_redesign)
│   └── burn_rate.dart               ← velocidad de gasto
└── services/
    ├── financial_engine.dart        ← orquestador central
    └── envelope_engine.dart         ← lógica de envelopes
```

### El `FinancialSnapshot`

```dart
/// La única fuente de verdad financiera del período.
/// Producida por FinancialEngine, consumida por toda la UI.
class FinancialSnapshot {
  final FinancialPeriod period;
  final DateTime generatedAt;

  // ── Ingresos ──────────────────────────────────────
  final Money totalIncome;
  final Money cashIncome;      // excluye Swile
  final Money swileIncome;

  // ── Gastos ────────────────────────────────────────
  final Money totalSpent;
  final Money cashSpent;       // excluye Swile
  final Money swileSpent;

  // ── Balance ───────────────────────────────────────
  final Money currentBalance;  // cashIncome - cashSpent
  final Money swileBalance;    // swileIncome - swileSpent

  // ── Envelopes ─────────────────────────────────────
  final List<EnvelopeStatus> envelopes;
  final Money totalAllocated;
  final Money totalBudgeted;

  // ── Salud financiera ──────────────────────────────
  final int healthScore;           // 0-10
  final String healthColor;        // 'green' | 'amber' | 'red'
  final double savingsRate;        // %

  // ── Compromisos futuros ───────────────────────────
  final List<ScheduledPayment> upcomingPayments;
  final Money totalFutureObligations;

  // ── Computed conveniences ─────────────────────────
  bool get isPositive => currentBalance > Money.zero;
  Money get remainingBudget => totalAllocated - cashSpent;
}
```

### Value Object: `Money`

```dart
/// Tipo seguro para moneda. Evita errores de double arithmetic.
/// Internamente trabaja con centavos (int) para precisión exacta.
class Money {
  final int _cents;
  final String currencyCode; // 'BRL' por default

  static const Money zero = Money._(0);

  Money.fromDouble(double amount) : _cents = (amount * 100).round();
  Money.fromCents(int cents) : _cents = cents;

  double get amount => _cents / 100;
  int get cents => _cents;

  Money operator +(Money other) => Money.fromCents(_cents + other._cents);
  Money operator -(Money other) => Money.fromCents(_cents - other._cents);
  Money operator *(double factor) => Money.fromCents((_cents * factor).round());

  bool operator >(Money other) => _cents > other._cents;
  bool operator <(Money other) => _cents < other._cents;

  bool get isZero => _cents == 0;
  bool get isNegative => _cents < 0;

  String get formatted => FinancialCalculatorService.formatBRL(amount);

  @override
  bool operator ==(Object other) => other is Money && _cents == other._cents;
}
```

---

## ⚡ Análisis de Impacto

### Archivos a crear (sin tocar código existente)
```
lib/core/domain/entities/financial_snapshot.dart  ← NUEVO
lib/core/domain/entities/envelope.dart             ← NUEVO
lib/core/domain/value_objects/money.dart           ← NUEVO
lib/core/domain/services/financial_engine.dart     ← NUEVO
lib/core/domain/services/envelope_engine.dart      ← NUEVO
lib/core/providers/financial_snapshot_provider.dart← NUEVO
```

### Archivos a modificar (con backward compat)
```
lib/features/dashboard/dashboard_screen.dart       ← agregar watch del snapshot
lib/features/dashboard/widgets/kpi_grid.dart       ← migrar a snapshot
lib/features/dashboard/widgets/period_balance_hero.dart
lib/features/dashboard/widgets/health_gauge_card.dart
```

### Breaking Changes
| Change | Severidad | Mitigación |
|---|---|---|
| Providers del dashboard refactorizados | 🟡 MEDIO | Migrar widget por widget, no todo a la vez |
| `FinancialCalculatorService` → métodos internos del engine | 🟢 BAJO | Mantener métodos estáticos como wrappers |

---

## 🗺️ Estrategia Incremental

### FASE 1 — Money Value Object (sin UI)
**Objetivo**: Tipo seguro para dinero. Prerequisito de todo.
**Reversibilidad**: 100%.

```
Tarea 1.1: Crear lib/core/domain/value_objects/money.dart
  - Money.fromDouble(), Money.fromCents()
  - Operadores aritméticos (+, -, *)
  - Comparadores (>, <, ==)
  - money.formatted → usa FinancialCalculatorService.formatBRL()
  - Money.zero como constante

Tarea 1.2: Tests de Money
  - Money(100.00) + Money(50.50) == Money(150.50)
  - Money(10.00) * 3 == Money(30.00)
  - Sin errores de floating point: Money(0.1) + Money(0.2) == Money(0.3)
```

**Test de éxito**: `dart test test/core/money_test.dart` → todos pasan.

---

### FASE 2 — FinancialSnapshot Entity (sin lógica de calculo)
**Objetivo**: Definir el contrato del objeto central.
**Reversibilidad**: 100%.

```
Tarea 2.1: Crear lib/core/domain/entities/financial_snapshot.dart
  - Definir todos los campos con Money y tipos correctos
  - Factory FinancialSnapshot.empty(period) para loading states
  - copyWith() para actualizaciones parciales

Tarea 2.2: Crear lib/core/domain/entities/envelope.dart
  - EnvelopeStatus (ok | warning | overspent)
  - Campos: category, allocated, spent, remaining, rolloverPolicy

Tarea 2.3: Crear lib/core/domain/entities/scheduled_payment.dart
  - Para cuotas e recurrentes futuros
  - daysFromNow computed property
```

---

### FASE 3 — FinancialEngine Service
**Objetivo**: El servicio que produce el FinancialSnapshot.
**Reversibilidad**: Alta — el engine es nuevo, no reemplaza nada todavía.

```
Tarea 3.1: Crear lib/core/domain/services/financial_engine.dart
  - Inyecta: ExpenseRepository, IncomeRepository, InstallmentRepository
  - buildSnapshot(period, userId) → Future<FinancialSnapshot>
  - Internamente usa FinancialCalculatorService para health score
  - Cache simple: Map<String, FinancialSnapshot> por período

Tarea 3.2: Crear financialSnapshotProvider en Riverpod
  - @riverpod Future<FinancialSnapshot> financialSnapshot(period)
  - autoDispose
  - Invalida cuando cambian expenses o incomes del período

Tarea 3.3: Test de integración del engine
  - Datos sintéticos en test
  - Verificar que totalIncome + totalSpent + balance son coherentes
```

---

### FASE 4 — Migración del Dashboard
**Objetivo**: El dashboard consume un único observable.
**Reversibilidad**: Media — cambios en UI visibles.

```
Tarea 4.1: Dashboard consume financialSnapshotProvider
  - Agregar ref.watch(financialSnapshotProvider(period)) en DashboardScreen
  - Pasar snapshot como parámetro a widgets hijos

Tarea 4.2: Migrar KpiGrid a snapshot
  - KpiGrid(snapshot: snapshot) en vez de queries individuales

Tarea 4.3: Migrar PeriodBalanceHero a snapshot
  - PeriodBalanceHero(snapshot: snapshot)

Tarea 4.4: Migrar HealthGaugeCard a snapshot
  - HealthGaugeCard(snapshot: snapshot)
  - healthScore viene del snapshot, no calculado en el widget
```

---

### FASE 5 — EnvelopeEngine
**Objetivo**: Lógica de presupuesto por categoría con rollover.
**Reversibilidad**: Alta.
**Pre-condición**: `categories_redesign.md` Fase 3 completa.

```
Tarea 5.1: Crear lib/core/domain/services/envelope_engine.dart
  - getEnvelopes(period, userId) → Future<List<EnvelopeStatus>>
  - calculateRollover(envelope) → Money
  - suggestAllocation(category, history) → Money

Tarea 5.2: Integrar envelopes en FinancialSnapshot
  - snapshot.envelopes viene del EnvelopeEngine

Tarea 5.3: UI: EnvelopeCard en period_budget_screen.dart
  - Mostrar rollover si existe
  - Badge "Acumulado: +R$120" en envelopes con saldo positivo
```

---

## 🚨 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Double arithmetic en Money | Alta | Datos incorrectos | Usar centavos internamente (int) |
| FinancialSnapshot inconsistente si queries parciales | Media | UI incorrecta | Factory FinancialSnapshot.empty() para loading |
| Provider rebuild en cascada | Media | Performance | autoDispose + select() para campos específicos |
| Migración del dashboard rompe UI temporalmente | Media | UX degradada | Migrar widget por widget, no todo de golpe |

---

## ✅ Checklist de Completitud

### Fase 1 — Money
- [ ] `Money` value object con centavos internos
- [ ] Operadores aritméticos correctos
- [ ] Test: 0.1 + 0.2 == 0.3 (sin floating point error)

### Fase 2 — Entities
- [ ] `FinancialSnapshot` con todos los campos
- [ ] `FinancialSnapshot.empty(period)` factory
- [ ] `EnvelopeStatus` entity
- [ ] `ScheduledPayment` entity

### Fase 3 — Engine
- [ ] `FinancialEngine.buildSnapshot()` funcional
- [ ] `financialSnapshotProvider` en Riverpod
- [ ] Test de integración con datos sintéticos

### Fase 4 — Dashboard
- [ ] Dashboard usa único `financialSnapshotProvider`
- [ ] KpiGrid, PeriodBalanceHero, HealthGaugeCard usan snapshot
- [ ] 0 queries duplicadas entre widgets del dashboard

### Fase 5 — Envelopes
- [ ] `EnvelopeEngine` con rollover
- [ ] Envelopes integrados en snapshot
- [ ] UI muestra rollover en budget screen
- [ ] Documentar en `docs/decisions/002-financial-snapshot.md`

---

## 📎 Referencias

- Análisis detallado: `FAROL_PREDICTIVE_ENGINE.md` → Secciones 2 y 4
- ADR pendiente: `docs/decisions/002-financial-snapshot.md`
- Depende de: `categories_redesign.md`
- Desbloquea: `forecasting.md`
