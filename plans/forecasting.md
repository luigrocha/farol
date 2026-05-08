# Plan: Forecasting Engine (Motor Predictivo)
**Área**: Domain · Analytics · UI
**Prioridad**: P2 — el "momento wow" del producto
**Dependencias**: `financial_engine.md` (Fases 1-4 completas) · `categories_redesign.md` (completo)
**Archivos impactados**: Nuevos en `lib/core/domain/`, nuevos widgets en dashboard

---

## 🔍 Contexto del Problema

### Estado actual (confirmado en código)

```dart
// ÚNICO forecasting real que existe:
static double projectFgts(double currentBalance, int monthsAhead, {double? grossSalary}) {
  final monthly = (grossSalary ?? AppConstants.defaultGrossSalary) * AppConstants.fgtsRate;
  return currentBalance + (monthly * monthsAhead); // proyección lineal simple
}

// Campo isProjected en Expense — intención sin implementación:
class Expense {
  final bool isProjected; // existe pero ningún servicio lo usa para calcular
}

// Health Score estático (no predice el futuro):
static int calculateHealthScore({...}) {
  // calcula el estado ACTUAL, no el PROYECTADO
  // no considera cuotas futuras, recurrentes, burn rate
}
```

### ¿Por qué es la parte más importante?

Un usuario que puede ver "si sigues así, terminas el período con -R$120" **cambia su comportamiento**. Un usuario que solo ve "gastaste R$800 hasta ahora" no tiene información accionable. El forecasting es el salto de contador a copiloto.

---

## 📐 Arquitectura del Forecasting Engine

### Jerarquía de métricas (de más simple a más compleja)

```
Nivel 1: Estado actual (ya existe en FinancialEngine)
  ├── currentBalance
  ├── totalSpent
  └── healthScore (estático)

Nivel 2: Velocidad (nuevo — requiere historial)
  ├── BurnRate (gasto/día)
  ├── DailyRate (promedio diario real)
  └── PaceVsBudget (relación entre velocidad y plan)

Nivel 3: Proyección a corto plazo (nuevo — requiere obligaciones)
  ├── ProjectedClosingBalance
  ├── DaysUntilEmpty
  └── LiquidityRisk

Nivel 4: Proyección a largo plazo (nuevo — requiere historial + ML futuro)
  ├── CashflowForecast (90 días)
  ├── CategoryVelocity por categoría
  └── SavingsPrediction

Nivel 5: Intelligence (plan separado: Intelligence Layer)
  ├── BudgetRiskScore
  ├── Anomaly Detection
  └── Recommendations
```

### Nuevos archivos a crear

```
lib/core/domain/
├── entities/
│   ├── financial_projection.dart    ← el objeto de forecasting
│   ├── burn_rate.dart               ← velocidad de gasto
│   ├── cashflow_forecast.dart       ← proyección día por día
│   └── liquidity_risk.dart          ← riesgo de iliquidez
└── services/
    ├── forecasting_engine.dart      ← motor predictivo
    └── obligation_engine.dart       ← cuotas + recurrentes futuros
```

---

## ⚡ Análisis de Impacto

### Lo que se necesita del plan anterior (`financial_engine.md`)
- `Money` value object (Fase 1) → prerequisito
- `FinancialSnapshot` (Fase 2-3) → el forecasting extiende el snapshot
- `ScheduledPayment` entity (Fase 2) → prerequisito para obligaciones

### Lo que se necesita de `categories_redesign.md`
- `CategoryRef` → para CategoryVelocity por categoría

### Breaking Changes
Este plan **solo agrega**. No modifica código existente.
El `FinancialSnapshot` se extiende con campos opcionales de forecasting.

```dart
// FinancialSnapshot extendiéndose (backward compat)
class FinancialSnapshot {
  // ... campos existentes ...

  // Nuevos campos opcionales (null = forecasting no disponible todavía)
  final FinancialProjection? projection; // null hasta que Forecasting Engine esté listo
}
```

---

## 🗺️ Estrategia Incremental

### FASE 1 — BurnRate (la métrica más simple y de mayor impacto inmediato)
**Objetivo**: Calcular y mostrar la velocidad de gasto actual.
**Reversibilidad**: 100% — widget nuevo, no modifica nada.

```
Tarea 1.1: Crear lib/core/domain/entities/burn_rate.dart
  - totalSpent: Money
  - daysElapsed: int
  - daysRemaining: int
  - dailyRate: Money (computed: totalSpent / daysElapsed)
  - projectedTotalSpend: Money (computed: totalSpent + dailyRate * daysRemaining)
  - paceVsBudget: double (projected / allocated)

Tarea 1.2: Integrar BurnRate en FinancialEngine.buildSnapshot()
  - Calcular daysElapsed desde period.start hasta hoy
  - Calcular dailyRate = totalSpent / daysElapsed
  - snapshot.burnRate = BurnRate(...)

Tarea 1.3: Widget BurnRateCard en dashboard
  - Muestra: "R$ X/día promedio"
  - Muestra: "Proyección al cierre: R$ Y"
  - Semáforo: verde si paceVsBudget < 0.8, amarillo < 1.0, rojo >= 1.0
```

**Test de éxito**: El dashboard muestra la velocidad de gasto actualizada al registrar un nuevo gasto.

---

### FASE 2 — DaysUntilEmpty + LiquidityRisk
**Objetivo**: La métrica más emocionalmente impactante.
**Pre-condición**: Fase 1 completa. `InstallmentPlan` de `categories_redesign.md` Fase 3.

```
Tarea 2.1: Crear ObligationEngine
  - lib/core/domain/services/obligation_engine.dart
  - getScheduledPayments(userId, dateRange) → List<ScheduledPayment>
  - Fuentes: installment_payments pending + recurring_occurrences pending
  - Ordenados por due_date

Tarea 2.2: Implementar DaysUntilEmpty algorithm
  - Input: currentBalance, dailyBurnRate, List<ScheduledPayment>
  - Algoritmo iterativo día por día
  - Returns: int días (o -1 si >365 días, solvente)

Tarea 2.3: Implementar LiquidityRisk assessment
  - Inputs: currentBalance, upcoming7Days obligations, dailyBurnRate
  - Returns: LiquidityRisk enum (none | low | medium | high | critical)

Tarea 2.4: Widget de alerta en dashboard (condicional)
  - Solo visible si LiquidityRisk >= medium
  - "Semana apertada: R$580 em compromissos esta semana"
  - Tap → ver breakdown de obligaciones
```

---

### FASE 3 — ProjectedClosingBalance
**Objetivo**: Responder "¿cómo voy a terminar el período?"

```
Tarea 3.1: Implementar calculateProjectedClosingBalance()
  - currentBalance + projectedIncome - projectedVariableSpend - confirmedObligations
  - projectedIncome: ingresos esperados antes del cierre (salary si no llegó)
  - projectedVariableSpend: dailyBurnRate * daysRemaining

Tarea 3.2: UI — extender PeriodBalanceHero
  - Línea adicional: "Proyección: R$X al cierre"
  - Color según positivo/negativo
  - Tooltip explicativo en tap

Tarea 3.3: Alerta de balance negativo proyectado
  - Si projectedClosingBalance < 0: InsightCard crítica en dashboard
  - Acción: "Ver compromisos del período"
```

---

### FASE 4 — CashflowForecast (Chart 90 días)
**Objetivo**: Visualización predictiva completa.
**Pre-condición**: Fases 1-3 completas. Datos de recurrentes disponibles.

```
Tarea 4.1: Algoritmo CashflowForecast
  - buildCashflowForecast(userId, period, days: 90)
  - List<CashflowDataPoint> con { date, balance, hasObligation, dailyExpense, dailyIncome }
  - Cada día: balance anterior - dailyBurnRate - obligaciones_del_día + ingresos_del_día

Tarea 4.2: ForecastingEngine con cache
  - Cache TTL 5 minutos
  - Invalidar por evento: TransactionCreated | ObligationChanged
  - Cálculo asíncrono en background (no bloquear UI)

Tarea 4.3: Chart widget
  - fl_chart LineChart
  - Línea sólida: balance real (pasado)
  - Línea punteada: proyección (futuro)
  - Drops marcados: cuotas grandes (installmentAmount > umbral)
  - Picos marcados: ingresos esperados (salario)
  - Tab en Analytics screen (no en dashboard principal — demasiado complejo para home)
```

---

### FASE 5 — CategoryVelocity
**Objetivo**: Detectar qué categorías están "fuera de control".
**Pre-condición**: Historial de al menos 2 períodos.

```
Tarea 5.1: Calcular historial por categoría
  - Últimos 3 períodos → promedio de gasto por CategoryRef
  - Período actual → gasto actual

Tarea 5.2: CategoryVelocity per category
  - deviationPercent = (current - avg) / avg * 100
  - isOverPace: deviation > 20%
  - isUnderPace: deviation < -20%

Tarea 5.3: UI CategoryVelocity indicator
  - Chip en cada EnvelopeCard: "↑23% vs promedio"
  - En Analytics: tabla "Categorías fuera de ritmo"
```

---

### FASE 6 — SavingsPrediction
**Objetivo**: Responder "¿cuánto voy a ahorrar este período?"

```
Tarea 6.1: predictSavings()
  - projectedIncome - projectedSpend - totalObligations
  - Con factor de corrección histórica (si el usuario tiende a gastar X% más de lo proyectado)

Tarea 6.2: UI en dashboard
  - Card: "Previsão de poupança: R$847 este período"
  - Solo mostrar si confidence > 60% (requiere historial)
  - Primer período: no mostrar (sin historial)
```

---

## 📊 Fórmulas y Algoritmos (referencia)

```dart
// BurnRate
double dailyRate = totalSpent.amount / max(daysElapsed, 1);
Money projectedSpend = Money.fromDouble(dailyRate * (daysElapsed + daysRemaining));
double pace = totalAllocated.amount > 0
    ? projectedSpend.amount / totalAllocated.amount
    : 0.0;

// DaysUntilEmpty (pseudocódigo)
int daysUntilEmpty(Money balance, Money dailyRate, List<ScheduledPayment> obligations) {
  var bal = balance;
  for (int day = 1; day <= 365; day++) {
    bal -= dailyRate;
    bal -= obligations.where(d => d.daysFromNow == day).map(p => p.amount).sum;
    if (bal.isNegative) return day;
  }
  return -1; // solvente >1 año
}

// ProjectedClosingBalance
Money projected = currentBalance
    + projectedIncome
    - Money.fromDouble(dailyRate * daysRemaining)
    - confirmedObligations;

// CategoryVelocity
double deviation = historicalAvg.amount > 0
    ? (currentSpend.amount - historicalAvg.amount) / historicalAvg.amount * 100
    : 0.0;
```

---

## 🚨 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Proyección incorrecta sin historial suficiente | Alta (usuarios nuevos) | Confusión | No mostrar proyección en primer período |
| Lenguaje del forecast genera ansiedad | Media | Abandono | Usar lenguaje humano, no estadístico |
| Recálculo del forecast en cada render | Alta | Performance | Cache TTL 5min + invalidación por evento |
| Obligaciones no sincronizadas (offline) | Media | Proyección incorrecta | Proyectar con datos locales, reconciliar al reconectar |
| daysElapsed = 0 (primer día del período) | Segura | Division by zero | max(daysElapsed, 1) en todo cálculo |

---

## ✅ Checklist de Completitud

### Fase 1 — BurnRate
- [ ] `BurnRate` entity con dailyRate y paceVsBudget
- [ ] Integrado en `FinancialSnapshot`
- [ ] Widget BurnRateCard en dashboard
- [ ] Test: BurnRate correcto con datos sintéticos

### Fase 2 — DaysUntilEmpty
- [ ] `ObligationEngine` con fuentes: installments + recurrentes
- [ ] Algoritmo DaysUntilEmpty iterativo
- [ ] `LiquidityRisk` assessment
- [ ] Widget alerta condicional en dashboard

### Fase 3 — ProjectedClosingBalance
- [ ] `calculateProjectedClosingBalance()` implementado
- [ ] PeriodBalanceHero muestra proyección
- [ ] Alerta de balance negativo proyectado

### Fase 4 — CashflowForecast
- [ ] `buildCashflowForecast()` con 90 días
- [ ] `ForecastingEngine` con cache TTL 5min
- [ ] Chart en Analytics screen (sólido=real, punteado=proyección)

### Fase 5 — CategoryVelocity
- [ ] `CategoryVelocity` calculado para todas las categorías
- [ ] Indicator en EnvelopeCard
- [ ] Tabla en Analytics

### Fase 6 — SavingsPrediction
- [ ] `predictSavings()` con corrección histórica
- [ ] Solo se muestra si hay historial (>1 período)
- [ ] Documentar en `docs/decisions/003-forecasting-engine.md`

---

## 📎 Referencias

- Análisis detallado: `FAROL_PREDICTIVE_ENGINE.md` → Sección 7
- ADR pendiente: `docs/decisions/003-forecasting-engine.md`
- Depende de: `categories_redesign.md` + `financial_engine.md`
- Desbloquea: Intelligence Layer (no planificado aún, siguiente iteración)
