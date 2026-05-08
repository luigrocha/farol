# Farol — Predictive Financial Engine
## Documento Estratégico de Arquitectura
**Versión 1.0 · Mayo 2026**
**Autor: Principal Software Architect (IA) · Para: Luis Grocha**

---

> **Premisa**: Este documento no describe mejoras cosmética. Describe la transformación de Farol en un motor financiero predictivo real — el tipo de sistema que hace que un usuario diga *"esta app me conoce mejor que yo mismo"*. Cada decisión aquí fue tomada con base en el código real del repositorio, no en suposiciones genéricas.

---

# ÍNDICE

1. [Diagnóstico del Sistema Actual](#1-diagnóstico)
2. [Arquitectura Ideal del Financial Engine](#2-arquitectura)
3. [Rediseño del Sistema de Categorías](#3-categorías)
4. [Envelope Budgeting Engine](#4-envelopes)
5. [Sistema Real de Recurrentes](#5-recurrentes)
6. [Integración Correcta de Cuotas/Installments](#6-installments)
7. [Forecasting Engine](#7-forecasting)
8. [Budget Intelligence Layer](#8-inteligencia)
9. [Arquitectura de Sincronización](#9-sincronización)
10. [Roadmap de Implementación](#10-roadmap)
11. [Riesgos y Errores Comunes](#11-riesgos)
12. [Resultado Final Esperado](#12-resultado)

---

# 1. DIAGNÓSTICO DEL SISTEMA ACTUAL

## 1.1 Lo que encontré en el código (no supuestos)

Tras analizar el repositorio completo, el estado real es:

### Capa de Datos

**`app_database.dart` (Drift/SQLite local)**
El esquema local tiene 8 tablas: `Incomes`, `Expenses`, `CardInstallments`, `Investments`, `NetWorthSnapshots`, `BudgetGoals`, `UserSettings`, `CategoryTable`. Existe un `schemaVersion: 2` con una migración que popula las categorías sistema. El problema crítico: **la mayor parte de la lógica real vive en Supabase, no en Drift**. Las tablas Drift existen pero los repositorios en `features/` usan `SupabaseClient` directamente. Esto crea una **dualidad de persistencia no resuelta**: no es offline-first real, es Supabase-first con Drift como artefacto.

**`Expense` model**
El modelo tiene `installmentPlanId` (referencia a un plan de cuotas) e `isProjected` (flag para gastos proyectados). Estos campos *existen* pero ningún servicio los usa de forma coherente. Son la evidencia de intenciones arquitectónicas incompletas.

**`CardInstallment` model**
Tiene `currentInstallment` (contador manual), `remainingInstallments`, `remainingBalance`. El avance es manual — el usuario hace `advance()`. No existe generación automática de cuotas como filas de `expenses`. El `installmentPlanId` en `Expense` no tiene contrapartida en `CardInstallments` (no hay `foreign key` a expenses). Son **dos mundos paralelos que no se hablan**.

### Capa de Dominio

**`FinancialCalculatorService`**
Servicio con métodos estáticos puros. Calcula: savings rate, health score (5 factores), FGTS projection, budget alerts, net worth, 13th salary, INSS/IRRF, rescisión, FGTS aniversário. Es correcto conceptualmente pero **no tiene estado, no tiene streams, no tiene caching**. Cada cálculo es independiente y no compone con otros. No existe un "resultado financiero del período" unificado — cada widget hace sus propios cálculos en paralelo.

**`FinancialPeriod`**
Excelente abstracción. El `cutoffDay` personalizable es una ventaja competitiva real. La lógica `current()`, `next()`, `previous()` es correcta. **Este es el componente más sólido del sistema**.

**`PeriodBudget` + `PeriodBudgetEntry`**
El modelo de presupuesto por período tiene buena base: goal como referencia, override por período, tracking de gasto. El `BudgetStatus` (ok/warning/overspent) es correcto. Pero falta: rollover, carry-over, envelopes automáticos, vinculación con recurrentes.

### Sistema de Categorías: El Problema Dual

Este es el problema más estructural. Existen **dos sistemas paralelos e incompatibles**:

```
Sistema 1: enum ExpenseCategory (enums.dart)
→ 9 valores hardcodeados en Dart
→ Tiene localización, isSwile, localizedLabel
→ Usado en UI, en filtros, en cálculos

Sistema 2: CategoryTable (app_database.dart)
→ Tabla en SQLite con dbValue/name/emoji/isSwile/isSystem
→ También en Supabase (inferido por CategoryRepository)
→ Permite categorías custom del usuario
```

El resultado: los gastos almacenan `category` como `String`. En algunos flujos se convierte al enum, en otros se usa como string raw. El `ExpenseCategory.fromDb()` lanza `StateError` si la categoría es custom. **Esto es una bomba de tiempo cuando el usuario crea categorías propias**.

### Recurrentes: Casi No Existen

Los gastos "fijos" (`isFixed = true`) se copian del mes anterior mediante `fixedExpensePropagationProvider`. Este es el único mecanismo de recurrencia. No hay: RRULE, excepciones, pausas, detección automática, predicción de montos. El `DashboardScreen` muestra un SnackBar cuando se copian los gastos fijos — lo cual es UX de emergencia, no de producto.

### Forecasting: Prácticamente Inexistente

El campo `isProjected` en `Expense` sugiere intención. El `projectFgts()` en `FinancialCalculatorService` es el único forecasting real. No existe: projected balance, burn rate, liquidity risk, end-of-period prediction. El Health Score de 10 puntos es un proxy estático, no predictivo.

---

## 1.2 Fortalezas Reales (reutilizables)

| Componente | Por qué es sólido |
|---|---|
| `FinancialPeriod` con `cutoffDay` | Diferenciador competitivo. Correcto matemáticamente. Reutilizable 100%. |
| `FinancialCalculatorService` (métodos) | Lógica fiscal correcta (INSS/IRRF 2025). Los algoritmos son buenos, falta composición. |
| `PeriodBudget` + `BudgetGoal` | Base válida para envelopes. El modelo goal→override es extensible. |
| Sistema de `BudgetGoalType` (Need/Want/Invest) | Buena clasificación. Compatible con metodología 50/30/20. |
| Supabase Realtime manager | Infraestructura de sync existe. Falta orquestación. |
| Architecture feature-based | La estructura de carpetas es correcta. No hay que cambiarla. |
| Swile como concepto de bucket separado | Financieramente correcto para Brasil CLT. Mantener. |

## 1.3 Limitaciones Estructurales (que bloquean evolución)

1. **Categorías como enum Dart hardcodeado**: Imposible extender sin recompilar. Incompatible con categorías custom en producción.
2. **Installments y Expenses desacoplados**: Una cuota no genera una línea de gasto; un gasto no referencia un plan de cuotas de forma bidireccional.
3. **Dualidad Drift/Supabase sin estrategia**: No es offline-first ni online-first. Es ambos a medias.
4. **`FinancialCalculatorService` stateless sin composición**: No puede calcular "estado financiero del período" de forma holística.
5. **`month/year` como eje temporal principal**: Los gastos viven en `(month, year)`, no en fechas reales. Colisiona con `FinancialPeriod` que cruza meses.
6. **No existe un evento financiero**: No hay concepto unificado de "algo que impacta el balance en una fecha futura".

## 1.4 Deuda Técnica Cuantificada

| Deuda | Impacto | Esfuerzo de resolución |
|---|---|---|
| Enum de categorías + CategoryTable duplicado | CRÍTICO | 2 semanas |
| Installments sin relación con expenses | ALTO | 1 semana |
| month/year sin fecha exacta en expenses | ALTO | 3 días (migración) |
| FinancialCalculatorService sin composición | MEDIO | 1 semana |
| Recurrentes = isFixed copy | ALTO | 2 semanas |
| Offline/online dualidad sin estrategia | MEDIO | 2 semanas |
| Health Score estático | BAJO | 3 días |

---

# 2. ARQUITECTURA IDEAL DEL FINANCIAL ENGINE

## 2.1 Principio Rector

El Financial Engine de Farol debe ser **completamente agnóstico de Flutter**. Es una librería Dart pura que podría correr en un servidor, en tests, en un isolate. Flutter es solo el canal de presentación.

```
┌─────────────────────────────────────────────────────┐
│                    FLUTTER UI                       │
│  Screens → Widgets → Providers (Riverpod)           │
├─────────────────────────────────────────────────────┤
│              APPLICATION LAYER                      │
│  UseCases · Commands · Queries · Event Bus          │
├─────────────────────────────────────────────────────┤
│               DOMAIN LAYER                          │
│  Entities · Value Objects · Domain Services         │
│  Financial Engine · Forecasting Engine              │
│  Intelligence Layer · Rules Engine                  │
├─────────────────────────────────────────────────────┤
│            INFRASTRUCTURE LAYER                     │
│  Repositories (Drift + Supabase) · Sync Manager     │
│  Operation Queue · Conflict Resolver                │
└─────────────────────────────────────────────────────┘
```

## 2.2 Bounded Contexts Financieros

El sistema se divide en 6 bounded contexts con fronteras claras:

### BC1: Identity & Period Context
**Responsabilidad**: Quién es el usuario y en qué período financiero está.
```
Entidades: User, FinancialProfile, FinancialPeriod
Servicios: PeriodResolver, CutoffDayManager
Eventos: PeriodChanged, ProfileUpdated
```

### BC2: Ledger Context (Libro Mayor)
**Responsabilidad**: Registro inmutable de todos los eventos monetarios pasados.
```
Entidades: Transaction, Income, Expense, Transfer
Value Objects: Money, CategoryRef, DateRange
Servicios: LedgerService, TransactionClassifier
Eventos: TransactionCreated, TransactionUpdated, TransactionDeleted
```

### BC3: Budget Context (Envelopes)
**Responsabilidad**: Cuánto se planea gastar y cómo se asigna el dinero.
```
Entidades: Envelope, BudgetPlan, BudgetPeriod
Value Objects: AllocationRule, RolloverPolicy
Servicios: EnvelopeEngine, AllocationService
Eventos: EnvelopeAllocated, BudgetOverspent, RolloverCalculated
```

### BC4: Obligations Context (Compromisos Futuros)
**Responsabilidad**: Todos los compromisos financieros futuros conocidos.
```
Entidades: InstallmentPlan, InstallmentPayment, RecurringRule, RecurringOccurrence
Value Objects: RRule, PaymentSchedule
Servicios: ObligationEngine, RecurrenceResolver
Eventos: PaymentDue, InstallmentAdvanced, RecurringDetected
```

### BC5: Forecasting Context (Motor Predictivo)
**Responsabilidad**: Proyección del estado financiero futuro.
```
Entidades: FinancialProjection, CashflowForecast, LiquidityRisk
Value Objects: BurnRate, VelocityVector, RiskScore
Servicios: ForecastingEngine, ScenarioSimulator
Eventos: ProjectionUpdated, RiskThresholdBreached
```

### BC6: Intelligence Context (Copiloto)
**Responsabilidad**: Patrones, anomalías y recomendaciones.
```
Entidades: FinancialInsight, SpendingPattern, Anomaly
Value Objects: InsightType, ConfidenceScore
Servicios: PatternDetector, AnomalyDetector, RecommendationEngine
Eventos: InsightGenerated, AnomalyDetected
```

## 2.3 Flujo de Datos Principal

```
Usuario registra gasto
        │
        ▼
[TransactionCommand] → LedgerService → Transaction saved
        │
        ├──→ EnvelopeEngine.debitEnvelope(categoryRef, amount, period)
        │           │
        │           └──→ PeriodBudgetEntry updated (spent, remaining)
        │
        ├──→ ObligationEngine.checkIfInstallment()
        │           │
        │           └──→ InstallmentPayment.markPaid() if applicable
        │
        ├──→ ForecastingEngine.invalidateCache(period)
        │           │
        │           └──→ Recalculate: projected balance, burn rate, risk
        │
        └──→ IntelligenceLayer.analyze(transaction)
                    │
                    └──→ AnomalyDetector, PatternUpdater → Insights
```

## 2.4 Estructura de Directorios Propuesta

```
lib/
├── core/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── transaction.dart
│   │   │   ├── envelope.dart
│   │   │   ├── installment_plan.dart
│   │   │   ├── recurring_rule.dart
│   │   │   └── financial_projection.dart
│   │   ├── value_objects/
│   │   │   ├── money.dart
│   │   │   ├── category_ref.dart
│   │   │   ├── date_range.dart
│   │   │   └── rrule.dart
│   │   └── services/
│   │       ├── financial_engine.dart          ← NUEVO NÚCLEO
│   │       ├── forecasting_engine.dart        ← NUEVO
│   │       ├── envelope_engine.dart           ← NUEVO
│   │       ├── obligation_engine.dart         ← NUEVO
│   │       └── intelligence_layer.dart        ← NUEVO
│   ├── application/
│   │   ├── commands/
│   │   ├── queries/
│   │   └── use_cases/
│   ├── infrastructure/
│   │   ├── database/
│   │   │   ├── drift/              ← esquema Drift actualizado
│   │   │   └── supabase/           ← repos Supabase
│   │   └── sync/
│   │       ├── sync_manager.dart
│   │       ├── operation_queue.dart
│   │       └── conflict_resolver.dart
│   └── providers/                  ← Riverpod providers
│
└── features/                       ← igual que ahora
```

## 2.5 FinancialEngine: El Núcleo Central

```dart
/// El motor financiero central. Produce el estado financiero completo
/// del período actual. Es el único punto de verdad financiera en la app.
class FinancialEngine {
  final LedgerRepository _ledger;
  final EnvelopeEngine _envelopes;
  final ObligationEngine _obligations;
  final ForecastingEngine _forecasting;

  /// Produce el snapshot financiero completo del período.
  /// Todos los widgets del dashboard consumen este único objeto.
  Stream<FinancialSnapshot> watchPeriodSnapshot(
    FinancialPeriod period,
    String userId,
  );
}

class FinancialSnapshot {
  // Balance
  final Money openingBalance;
  final Money totalIncome;
  final Money totalExpenses;
  final Money currentBalance;
  final Money projectedClosingBalance;

  // Envelopes
  final List<EnvelopeStatus> envelopes;

  // Obligaciones futuras
  final List<ScheduledPayment> upcomingPayments;
  final Money totalFutureObligations;

  // Forecasting
  final BurnRate burnRate;
  final LiquidityRisk liquidityRisk;
  final DaysUntilEmpty daysUntilEmpty;

  // Health
  final HealthScore healthScore;
  final List<FinancialInsight> insights;
}
```

---

# 3. REDISEÑO COMPLETO DEL SISTEMA DE CATEGORÍAS

## 3.1 El Problema Real (desde el código)

El problema no es filosófico, es concreto. En `enums.dart` existe `ExpenseCategory` con 9 valores. En `app_database.dart` existe `CategoryTable`. En `Expense` el campo `category` es `String`. En `CategoryRepository` hay queries a Supabase. Cuando un usuario crea una categoría custom con `dbValue = 'ROPA'`, el `ExpenseCategory.fromDb('ROPA')` lanza `StateError: No element`.

**La unificación no es opcional. Es una pre-condición para todo lo demás.**

## 3.2 Modelo Unificado de Categorías

### Schema Ideal (Supabase + Drift mirror)

```sql
-- Categorías unificadas. Reemplaza enum + CategoryTable.
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id),  -- NULL = sistema global
  parent_id     UUID REFERENCES categories(id),  -- NULL = raíz
  
  -- Identificación
  slug          TEXT NOT NULL,         -- 'housing', 'food_grocery', 'custom_ropa'
  name          TEXT NOT NULL,         -- 'Moradia', 'Alimentação'
  emoji         TEXT NOT NULL DEFAULT '📋',
  color_hex     TEXT,                  -- '#FF6B6B' para UI
  
  -- Clasificación financiera (CRÍTICO para forecasting)
  financial_type TEXT NOT NULL         -- 'need' | 'want' | 'investment' | 'income' | 'transfer'
    CHECK (financial_type IN ('need','want','investment','income','transfer')),
  
  -- Comportamiento
  is_system     BOOLEAN DEFAULT FALSE, -- creada por Farol, no editable
  is_swile      BOOLEAN DEFAULT FALSE, -- financiada por benefício Swile
  is_fixed      BOOLEAN DEFAULT FALSE, -- gastos en esta cat son típicamente fijos
  is_archived   BOOLEAN DEFAULT FALSE, -- soft delete
  
  -- Metadata para forecasting
  typical_recurrence TEXT,            -- 'monthly' | 'variable' | 'annual' | null
  budget_strategy TEXT DEFAULT 'manual',  -- 'auto' | 'manual' | 'percentage'
  
  -- Orden y agrupación
  display_order INT DEFAULT 0,
  group_name    TEXT,                  -- 'Moradia & Transporte', 'Lazer & Vida'
  
  -- Timestamps
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, slug)
);

-- Reglas automáticas de categorización
CREATE TABLE category_rules (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id),
  category_id   UUID REFERENCES categories(id),
  
  rule_type     TEXT NOT NULL  -- 'keyword' | 'store_name' | 'amount_range' | 'merchant'
    CHECK (rule_type IN ('keyword','store_name','amount_range','merchant')),
  rule_value    JSONB NOT NULL,  -- {"keywords": ["netflix", "spotify"]} o {"min": 0, "max": 50}
  
  priority      INT DEFAULT 0,   -- mayor prioridad gana en conflicto
  is_active     BOOLEAN DEFAULT TRUE,
  
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Tags opcionales (cross-category)
CREATE TABLE transaction_tags (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id),
  name        TEXT NOT NULL,
  color_hex   TEXT,
  UNIQUE(user_id, name)
);

CREATE TABLE expense_tags (
  expense_id  UUID REFERENCES expenses(id) ON DELETE CASCADE,
  tag_id      UUID REFERENCES transaction_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (expense_id, tag_id)
);
```

### Jerarquía de Categorías Sistema (Brasil, CLT)

```
📦 NECESSIDADES (financial_type: need)
├── 🏠 Moradia
│   ├── Aluguel / Financiamento
│   ├── Condomínio
│   ├── Água & Luz
│   ├── Internet & TV
│   └── Manutenção
├── 🚗 Transporte
│   ├── Combustível
│   ├── Transporte Público
│   ├── Aplicativo (Uber/99)
│   ├── Seguro Auto
│   └── IPVA / Licenciamento
├── 🛒 Alimentação
│   ├── Supermercado [isSwile: true]
│   ├── Restaurante [isSwile: true]
│   ├── Delivery [isSwile: true]
│   └── Padaria / Café
├── 🏥 Saúde
│   ├── Plano de Saúde
│   ├── Medicamentos
│   ├── Consultas
│   └── Academia / Bem-estar
└── 📚 Educação
    ├── Cursos
    ├── Livros
    └── Escola / Faculdade

🎯 DESEJOS (financial_type: want)
├── 🎮 Lazer & Entretenimento
│   ├── Streaming (Netflix, etc.)
│   ├── Cinema / Shows
│   └── Jogos
├── 🛍️ Compras
│   ├── Roupas
│   ├── Eletrônicos
│   └── Casa & Decoração
└── ✈️ Viagens & Experiências

💎 INVESTIMENTOS (financial_type: investment)
├── 📈 Renda Variável
├── 🏛️ Renda Fixa
├── 🐷 Reserva de Emergência
└── 💰 Previdência

💳 ESPECIAIS (managed by engine)
├── Parcelas de Cartão     [is_system: true, linked to installment_plans]
└── Transferências         [financial_type: transfer]
```

## 3.3 CategoryRef: Value Object en el Dominio

```dart
/// Value object que reemplaza el enum ExpenseCategory.
/// Puede ser sistema o custom. Nunca lanza StateError.
class CategoryRef {
  final String id;       // UUID
  final String slug;     // 'housing', 'custom_ropa'
  final String name;     // display name localizado
  final String emoji;
  final String? colorHex;
  final FinancialType financialType;
  final String? parentId;
  final bool isSystem;
  final bool isSwile;
  final bool isFixed;

  bool get isCustom => !isSystem;
  bool get isTopLevel => parentId == null;

  /// Compatibilidad retroativa con el String 'HOUSING' del enum viejo
  static CategoryRef fromLegacyDbValue(String dbValue, List<CategoryRef> all) {
    return all.firstWhere(
      (c) => c.slug.toUpperCase() == dbValue,
      orElse: () => CategoryRef.uncategorized(),
    );
  }
}

enum FinancialType { need, want, investment, income, transfer }
```

## 3.4 Migración Gradual desde el Sistema Actual

**Paso 1 (sin breaking changes)**: Crear la nueva tabla `categories` con todos los slugs que matchean los `dbValue` del enum actual. Mantener el enum en paralelo.

**Paso 2**: Agregar campo `category_id UUID` (nullable) a la tabla `expenses` en Supabase. Correr job de backfill que mapea el string `category` al UUID correspondiente.

**Paso 3**: Escribir `CategoryResolver` que recibe un `String` (legado) o `UUID` y siempre retorna un `CategoryRef` válido. Nunca lanza excepción.

**Paso 4**: Reemplazar todos los usos del enum en la UI por `CategoryRef`. Eliminar el enum.

**Paso 5**: Hacer `category_id` NOT NULL. Deprecar el campo `category` (string).

---

# 4. ENVELOPE BUDGETING ENGINE

## 4.1 Modelo Conceptual

YNAB inventó los envelopes. Farol debe mejorarlos para Brasil. La diferencia clave: en Brasil tienes Swile (bucket separado), cuotas de cartão (obligaciones futuras conocidas), 13° salário (ingreso predecible pero irregular), y un cashflow mensual que frecuentemente cruza períodos (cutoffDay ≠ 1).

Un **envelope** en Farol es el presupuesto de una categoría en un período, con estado completo:

```dart
class Envelope {
  final String id;
  final String userId;
  final CategoryRef category;
  final FinancialPeriod period;

  // Asignación
  final Money allocated;       // cuánto asignaste
  final Money spent;           // cuánto gastaste (real, de transactions)
  final Money remaining;       // allocated - spent

  // Rollover
  final Money rolledOverFrom;  // saldo positivo del período anterior
  final RolloverPolicy rolloverPolicy;

  // Estado
  final EnvelopeStatus status; // ok | warning | overspent | frozen
  final bool isAutomated;      // calculado automáticamente o manual
  final AutomationRule? rule;

  // Computed
  Money get effectiveAllocated => allocated + rolledOverFrom;
  double get utilizationPercent => effectiveAllocated.amount > 0
      ? spent.amount / effectiveAllocated.amount
      : 0.0;
  bool get isOverspent => spent > effectiveAllocated;
  Money get overspentAmount => isOverspent
      ? spent - effectiveAllocated
      : Money.zero;
}

enum RolloverPolicy {
  none,             // el saldo no pasa al siguiente período (default)
  rolloverPositive, // solo pasa si sobra dinero
  rolloverNegative, // pasa el deficit también (carry-over negativo)
  rolloverFull,     // siempre pasa el saldo, positivo o negativo
}
```

## 4.2 Schema DB para Envelopes

```sql
-- Reemplaza period_budgets con modelo más completo
CREATE TABLE envelopes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id),
  category_id     UUID REFERENCES categories(id),
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,

  -- Asignación
  allocated       NUMERIC(12,2) DEFAULT 0,
  rolled_over     NUMERIC(12,2) DEFAULT 0,   -- viene del período anterior

  -- Políticas
  rollover_policy TEXT DEFAULT 'none'
    CHECK (rollover_policy IN ('none','positive','negative','full')),
  is_automated    BOOLEAN DEFAULT FALSE,

  -- Source de automatización
  automation_type TEXT   -- 'from_recurring', 'percentage_of_income', 'fixed_amount', 'copy_previous'
  automation_value JSONB, -- {"percentage": 0.30} o {"amount": 500}

  -- Timestamps
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, category_id, period_start, period_end)
);

-- Vista materializada para performance (recalcular solo cuando cambian transactions)
CREATE MATERIALIZED VIEW envelope_status AS
SELECT
  e.id,
  e.user_id,
  e.category_id,
  e.period_start,
  e.period_end,
  e.allocated,
  e.rolled_over,
  e.allocated + e.rolled_over AS effective_allocated,
  COALESCE(SUM(t.amount) FILTER (WHERE t.financial_type != 'income'), 0) AS spent,
  e.allocated + e.rolled_over - COALESCE(SUM(t.amount) FILTER (WHERE t.financial_type != 'income'), 0) AS remaining,
  e.rollover_policy
FROM envelopes e
LEFT JOIN transactions t ON
  t.category_id = e.category_id
  AND t.user_id = e.user_id
  AND t.transaction_date BETWEEN e.period_start AND e.period_end
GROUP BY e.id;
```

## 4.3 Lógica Matemática del Engine

```dart
class EnvelopeEngine {

  /// Calcula el rollover al cerrar un período
  Money calculateRollover(Envelope envelope) {
    final balance = envelope.effectiveAllocated - envelope.spent;

    return switch (envelope.rolloverPolicy) {
      RolloverPolicy.none => Money.zero,
      RolloverPolicy.rolloverPositive => balance > Money.zero ? balance : Money.zero,
      RolloverPolicy.rolloverNegative => balance < Money.zero ? balance : Money.zero,
      RolloverPolicy.rolloverFull => balance,
    };
  }

  /// Sugiere la asignación para el próximo período
  Money suggestAllocation(
    CategoryRef category,
    List<Envelope> history,         // últimos 3 períodos
    List<RecurringRule> recurrents, // obligaciones fijas
    Money availableToAssign,
  ) {
    // 1. Si hay recurrente fijo para esta categoría → usar ese monto
    final fixedRecurring = recurrents
        .where((r) => r.categoryId == category.id && r.isFixed)
        .firstOrNull;
    if (fixedRecurring != null) return fixedRecurring.typicalAmount;

    // 2. Si hay historial → usar el promedio ponderado (últimos 3 períodos)
    if (history.isNotEmpty) {
      final weightedAvg = _weightedAverage(history.map((e) => e.spent).toList());
      // Agregar 10% de buffer para categorías variables
      return category.isFixed ? weightedAvg : weightedAvg * 1.10;
    }

    // 3. Sin historial → aplicar regla 50/30/20 sobre income disponible
    return _applyBudgetRule(category.financialType, availableToAssign);
  }

  /// Distribución automática del ingreso en envelopes (YNAB-style "Ready to Assign")
  List<EnvelopeAllocation> autoDistribute({
    required Money totalIncome,
    required List<RecurringRule> obligationsThisPeriod,
    required List<CategoryRef> categories,
    required List<Envelope> previousPeriodEnvelopes,
    required BudgetProfile profile, // conservative | moderate | aggressive
  }) {
    Money remaining = totalIncome;
    final allocations = <EnvelopeAllocation>[];

    // Paso 1: Cubrir obligaciones conocidas primero
    for (final obligation in obligationsThisPeriod) {
      final amount = obligation.nextOccurrenceAmount;
      allocations.add(EnvelopeAllocation(
        categoryId: obligation.categoryId,
        amount: amount,
        reason: AllocationReason.obligation,
      ));
      remaining -= amount;
    }

    // Paso 2: Distribuir el resto según perfil
    final freeCategories = categories
        .where((c) => !obligationsThisPeriod.any((o) => o.categoryId == c.id))
        .toList();

    for (final cat in freeCategories) {
      final suggested = suggestAllocation(cat, previousPeriodEnvelopes.where((e) => e.category.id == cat.id).toList(), [], remaining);
      allocations.add(EnvelopeAllocation(
        categoryId: cat.id,
        amount: suggested,
        reason: AllocationReason.historical,
      ));
      remaining -= suggested;
    }

    return allocations;
  }

  // Promedio ponderado: período más reciente tiene mayor peso
  Money _weightedAverage(List<Money> amounts) {
    if (amounts.isEmpty) return Money.zero;
    final weights = List.generate(amounts.length, (i) => (i + 1).toDouble());
    final totalWeight = weights.reduce((a, b) => a + b);
    final weightedSum = amounts.indexed.map((e) => e.$2.amount * weights[e.$1]).reduce((a, b) => a + b);
    return Money.fromDouble(weightedSum / totalWeight);
  }
}
```

## 4.4 Edge Cases Críticos

**Envelope negativo**: Si `rolloverPolicy = rolloverNegative` y el usuario gastó R$200 con envelope de R$150, el próximo período arranca con -R$50. La UI debe mostrar esto claramente — "Debes R$50 de enero".

**Envelope para cuotas**: Cada plan de cuotas activo genera automáticamente un envelope de tipo `obligation` en cada período futuro. Es decir, si tienes 6x R$500 de una TV, Farol crea envelopes bloqueados de R$500 para los próximos 6 períodos. No son editables por el usuario.

**Envelope de inversión**: Tratado como gasto en cashflow (reduce balance líquido) pero marcado como `financial_type: investment`. El forecasting lo separa del gasto corriente.

**Income parcial**: Si el salario no llegó todavía (mitad de período), el engine trabaja con ingreso proyectado, no real. El campo `isProjected: true` en Income indica esto.

---

# 5. SISTEMA REAL DE RECURRENTES

## 5.1 ¿Por qué `isFixed + copy` no escala?

El mecanismo actual de `fixedExpensePropagationProvider` copia gastos del mes anterior con `isFixed = true`. Problemas:

- El monto puede variar (el alquiler subió R$100 en marzo)
- El usuario puede tener recurrentes que empiezan en una fecha futura
- No hay forma de pausar uno sin borrarlo
- No hay soporte para frecuencias no-mensuales (alquiler anual de temporada, seguro semestral)
- No detecta automáticamente patrones recurrentes

## 5.2 Modelo de Recurrentes

### Schema

```sql
-- Reglas de recurrencia
CREATE TABLE recurring_rules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id),
  category_id     UUID REFERENCES categories(id),

  -- Identificación
  name            TEXT NOT NULL,           -- 'Aluguel', 'Netflix', 'Plano de Saúde'
  description     TEXT,

  -- Monto
  base_amount     NUMERIC(12,2) NOT NULL,
  amount_type     TEXT DEFAULT 'fixed'     -- 'fixed' | 'variable' | 'range'
    CHECK (amount_type IN ('fixed','variable','range')),
  amount_min      NUMERIC(12,2),           -- para type='range'
  amount_max      NUMERIC(12,2),

  -- Regla de recurrencia (compatible con RRULE de RFC 5545)
  frequency       TEXT NOT NULL            -- 'daily'|'weekly'|'monthly'|'yearly'
    CHECK (frequency IN ('daily','weekly','biweekly','monthly','quarterly','semiannual','yearly')),
  interval        INT DEFAULT 1,           -- cada N períodos de frequency
  day_of_month    INT,                     -- día específico (1-28, o -1 para último día)
  day_of_week     INT[],                   -- 0=Dom...6=Sab (para weekly)
  month_of_year   INT[],                   -- 1-12 (para yearly o semiannual)

  -- Rango temporal de la regla
  starts_on       DATE NOT NULL,
  ends_on         DATE,                    -- NULL = indefinido
  ends_after_n    INT,                     -- o termina después de N ocurrencias

  -- Estado
  status          TEXT DEFAULT 'active'    -- 'active'|'paused'|'cancelled'
    CHECK (status IN ('active','paused','cancelled')),
  paused_until    DATE,                    -- reactivación automática

  -- Metadata
  payment_method  TEXT,
  is_auto_detected BOOLEAN DEFAULT FALSE,  -- detectado por el engine, no manual
  confidence      NUMERIC(4,3),           -- 0.0-1.0 (para auto-detected)

  -- Categoría de gasto para el forecasting
  financial_type  TEXT,                   -- sobrescribe la categoría padre si necesario

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Ocurrencias generadas
CREATE TABLE recurring_occurrences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id         UUID REFERENCES recurring_rules(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES auth.users(id),

  -- Cuándo y cuánto
  scheduled_date  DATE NOT NULL,
  expected_amount NUMERIC(12,2) NOT NULL,

  -- Estado
  status          TEXT DEFAULT 'pending'   -- 'pending'|'paid'|'skipped'|'overridden'
    CHECK (status IN ('pending','paid','skipped','overridden')),
  paid_date       DATE,
  actual_amount   NUMERIC(12,2),           -- puede diferir del expected

  -- Link a la transacción real
  transaction_id  UUID REFERENCES expenses(id),

  -- Excepciones
  is_exception    BOOLEAN DEFAULT FALSE,   -- esta ocurrencia fue modificada
  exception_notes TEXT,

  created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### Generación de Ocurrencias

```dart
class RecurrenceResolver {

  /// Genera todas las ocurrencias de una regla en un rango de fechas.
  /// Usado por el ForecastingEngine para proyectar cashflow futuro.
  List<RecurringOccurrence> generateOccurrences(
    RecurringRule rule,
    DateRange range,
  ) {
    if (rule.status != RecurringStatus.active) return [];

    final occurrences = <RecurringOccurrence>[];
    var current = _firstOccurrenceInOrAfter(rule, range.start);

    int count = 0;
    while (current != null && !current.isAfter(range.end)) {
      // Verificar límites de la regla
      if (rule.endsOn != null && current.isAfter(rule.endsOn!)) break;
      if (rule.endsAfterN != null && count >= rule.endsAfterN!) break;

      occurrences.add(RecurringOccurrence(
        ruleId: rule.id,
        scheduledDate: current,
        expectedAmount: _calculateAmountForDate(rule, current),
        status: OccurrenceStatus.pending,
      ));

      current = _nextOccurrence(rule, current);
      count++;
    }

    return occurrences;
  }

  DateTime? _nextOccurrence(RecurringRule rule, DateTime from) {
    return switch (rule.frequency) {
      RecurringFrequency.monthly => _addMonths(from, rule.interval, rule.dayOfMonth),
      RecurringFrequency.biweekly => from.add(Duration(days: 14 * rule.interval)),
      RecurringFrequency.weekly => from.add(Duration(days: 7 * rule.interval)),
      RecurringFrequency.yearly => _addYears(from, rule.interval),
      RecurringFrequency.quarterly => _addMonths(from, 3 * rule.interval, rule.dayOfMonth),
      RecurringFrequency.semiannual => _addMonths(from, 6 * rule.interval, rule.dayOfMonth),
      _ => null,
    };
  }

  /// Cálculo de monto variable (con inflación o ajuste histórico)
  Money _calculateAmountForDate(RecurringRule rule, DateTime date) {
    return switch (rule.amountType) {
      AmountType.fixed => Money.fromDouble(rule.baseAmount),
      AmountType.variable => _estimateVariableAmount(rule, date),
      AmountType.range => Money.fromDouble((rule.amountMin! + rule.amountMax!) / 2),
    };
  }
}
```

## 5.3 Detección Automática de Recurrentes

```dart
class RecurringDetector {
  static const _minOccurrences = 3;
  static const _minConfidence = 0.75;

  /// Analiza el historial de transacciones y detecta patrones recurrentes.
  List<RecurringRuleCandidate> detect(List<Transaction> history) {
    // Agrupar por (store_description, category, approximate_amount)
    final groups = _groupSimilarTransactions(history);

    return groups
        .map(_analyzeGroup)
        .where((c) => c.confidence >= _minConfidence)
        .where((c) => c.occurrences >= _minOccurrences)
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  RecurringRuleCandidate _analyzeGroup(List<Transaction> group) {
    // Calcular intervalos entre transacciones
    final sortedDates = group.map((t) => t.date).toList()..sort();
    final intervals = List.generate(
      sortedDates.length - 1,
      (i) => sortedDates[i + 1].difference(sortedDates[i]).inDays,
    );

    // Detectar frecuencia dominante
    final frequency = _detectFrequency(intervals);
    final consistency = _calculateConsistency(intervals, frequency);
    final amountVariance = _calculateAmountVariance(group.map((t) => t.amount).toList());

    return RecurringRuleCandidate(
      name: _inferName(group.first),
      category: group.first.category,
      baseAmount: _calculateMedianAmount(group),
      frequency: frequency,
      confidence: consistency * (1.0 - amountVariance * 0.5),
      occurrences: group.length,
      sampleTransactions: group,
    );
  }
}
```

## 5.4 UX Recomendada para Recurrentes

El flujo de UI debe ser: al detectar un candidato, mostrar una card no-invasiva en el dashboard: *"Parece que pagas Netflix todo los meses (~R$45). ¿Quieres que Farol lo rastree automáticamente?"* → [Confirmar] [Editar] [Ignorar]. Si confirma, el engine crea la `RecurringRule` y retroactivamente marca las ocurrencias pasadas como `paid`. No interrumpir el flujo de entrada de gastos con preguntas.

---

# 6. INTEGRACIÓN CORRECTA DE CUOTAS/INSTALLMENTS

## 6.1 El Problema Real (desde el código)

`CardInstallment` y `Expense` son entidades completamente independientes. El `Expense.installmentPlanId` existe pero `CardInstallments` no tiene referencia a expenses. El flujo actual:

1. Usuario registra un gasto de R$1200 en 12x → crea un `Expense` por R$100 en el mes actual
2. Separadamente crea un `CardInstallment` con `numInstallments=12, monthlyAmount=100`
3. Cada mes, *manualmente* hace `advance()` para avanzar el contador
4. Los meses futuros no tienen el gasto registrado hasta que el usuario los advance

Esto es fundamentalmente incorrecto para forecasting. Si compras una TV en 12x, el engine debe saber que tienes R$100/mes comprometidos durante 12 meses.

## 6.2 Modelo Correcto: InstallmentPlan + Payments

```sql
-- Plan madre: la compra original
CREATE TABLE installment_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id),
  category_id     UUID REFERENCES categories(id),

  -- Descripción de la compra
  description     TEXT NOT NULL,
  store_name      TEXT,
  purchase_date   DATE NOT NULL,

  -- Valores
  total_amount    NUMERIC(12,2) NOT NULL,
  num_installments INT NOT NULL CHECK (num_installments >= 2),
  installment_amount NUMERIC(12,2) NOT NULL,  -- total/num (puede tener diferencia en última)

  -- Tarjeta
  payment_method  TEXT NOT NULL,  -- 'CREDIT_ITAU', 'CREDIT_NUBANK', etc.
  card_id         UUID REFERENCES payment_methods(id),

  -- Estado del plan
  status          TEXT DEFAULT 'active'
    CHECK (status IN ('active','completed','cancelled')),
  first_due_date  DATE NOT NULL,   -- fecha del primer vencimiento

  -- Foto de la compra (para forecasting retroactivo)
  original_expense_id UUID REFERENCES expenses(id),

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Cuotas individuales (hijos del plan)
CREATE TABLE installment_payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id         UUID REFERENCES installment_plans(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES auth.users(id),

  installment_num INT NOT NULL,    -- 1, 2, 3...
  due_date        DATE NOT NULL,   -- fecha de vencimiento de esta cuota
  amount          NUMERIC(12,2) NOT NULL,  -- puede variar (última cuota tiene diferencia de centavos)

  -- Estado
  status          TEXT DEFAULT 'pending'
    CHECK (status IN ('pending','paid','overdue')),
  paid_date       DATE,
  paid_amount     NUMERIC(12,2),

  -- Link a transaction (cuando se registra el pago real)
  transaction_id  UUID REFERENCES expenses(id),

  -- Para el período financiero correcto
  financial_period_start DATE,
  financial_period_end   DATE,

  created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### Flujo Completo de una Compra Parcelada

```dart
class InstallmentService {

  /// Registra una compra en cuotas. Crea el plan + todas las cuotas automáticamente.
  Future<InstallmentPlan> createPurchase({
    required String description,
    required DateTime purchaseDate,
    required Money totalAmount,
    required int numInstallments,
    required String categoryId,
    required String paymentMethodId,
    DateTime? firstDueDate,
  }) async {
    // 1. Calcular la fecha del primer vencimiento
    final effectiveFirstDue = firstDueDate ?? _calculateFirstDueDate(purchaseDate, paymentMethodId);

    // 2. Calcular monto por cuota (con rounding correction en la última)
    final baseAmount = (totalAmount.amount / numInstallments * 100).floor() / 100;
    final remainder = totalAmount.amount - (baseAmount * numInstallments);

    // 3. Crear el plan
    final plan = await _createPlan(
      description: description,
      purchaseDate: purchaseDate,
      totalAmount: totalAmount,
      numInstallments: numInstallments,
      installmentAmount: Money.fromDouble(baseAmount),
      firstDueDate: effectiveFirstDue,
      categoryId: categoryId,
    );

    // 4. Generar todas las cuotas como filas individuales
    for (int i = 1; i <= numInstallments; i++) {
      final dueDate = _addMonths(effectiveFirstDue, i - 1);
      final amount = i == numInstallments
          ? Money.fromDouble(baseAmount + remainder)  // última cuota absorbe diferencia
          : Money.fromDouble(baseAmount);

      await _createPayment(
        planId: plan.id,
        installmentNum: i,
        dueDate: dueDate,
        amount: amount,
        status: i == 1 ? PaymentStatus.pending : PaymentStatus.future,
      );
    }

    // 5. Notificar al ForecastingEngine para invalidar cache
    _eventBus.emit(InstallmentPlanCreated(planId: plan.id));

    return plan;
  }

  /// Marca una cuota como pagada y crea la transaction correspondiente
  Future<void> payInstallment(
    String paymentId, {
    DateTime? actualPaidDate,
    Money? actualAmount,
  }) async {
    final payment = await _repo.getPayment(paymentId);

    // Crear expense real en la fecha de pago
    final expense = await _expenseRepo.create(
      amount: actualAmount ?? payment.amount,
      categoryId: payment.plan.categoryId,
      date: actualPaidDate ?? DateTime.now(),
      description: '${payment.plan.description} (${payment.installmentNum}/${payment.plan.numInstallments})',
      installmentPlanId: payment.planId,
      installmentPaymentId: payment.id,
    );

    // Marcar la cuota como pagada
    await _repo.updatePayment(paymentId, status: PaymentStatus.paid,
        paidDate: expense.date, transactionId: expense.id);

    // Si es la última cuota, cerrar el plan
    if (payment.installmentNum == payment.plan.numInstallments) {
      await _repo.updatePlan(payment.planId, status: PlanStatus.completed);
    }
  }
}
```

### Impacto en Forecasting

El `ForecastingEngine` consulta `installment_payments WHERE status = 'pending' AND due_date BETWEEN :periodStart AND :end` para conocer exactamente cuánto compromiso de cuotas hay en cada período futuro. No necesita inferir ni adivinar — la información está explícitamente en la DB.

```dart
// Cuotas futuras para los próximos 6 meses
List<ScheduledPayment> futureInstallments = await _installmentRepo
    .getPaymentsInRange(today, today.add(Duration(days: 180)));

Money totalInstallmentObligation = futureInstallments
    .map((p) => p.amount)
    .fold(Money.zero, (a, b) => a + b);
```

---

# 7. FORECASTING ENGINE

## 7.1 Filosofía del Motor Predictivo

El Forecasting Engine de Farol no es un chatbot de IA. Es un motor matemático determinista con heurísticas estadísticas. Debe dar respuestas concretas a preguntas concretas. Cuando el usuario pregunta "¿cuánto ahorraré este mes?", Farol no dice "depende de tus hábitos". Dice "**R$847** basado en tu velocidad actual de gasto y las obligaciones confirmadas de los próximos 18 días".

## 7.2 Las 7 Métricas Core del Forecasting

### Métrica 1: Burn Rate

**Definición**: Velocidad de consumo del presupuesto disponible.

```
BurnRate = TotalGastado / DíasTranscurridos

DíasRestantes = DíasTotalesPeriodo - DíasTranscurridos
GastoProyectado = TotalGastado + (BurnRate × DíasRestantes)
```

```dart
class BurnRate {
  final Money totalSpent;
  final int daysElapsed;
  final int daysRemaining;
  final Money dailyRate;

  // ¿Cuánto se gastará al final del período si el ritmo no cambia?
  Money get projectedTotalSpend => totalSpent + (dailyRate * daysRemaining);

  // ¿Qué porcentaje del período ha pasado vs qué porcentaje del budget se gastó?
  double get paceVsBudget; // >1.0 = gastando más rápido de lo planificado
}
```

### Métrica 2: Projected Closing Balance

```dart
Money calculateProjectedClosingBalance({
  required Money currentBalance,
  required Money projectedIncome,          // ingresos esperados antes del cierre
  required Money projectedVariableSpend,   // BurnRate × días restantes
  required List<ScheduledPayment> obligations, // cuotas + recurrentes conocidos
}) {
  final confirmedObligations = obligations
      .where((o) => o.status == PaymentStatus.pending)
      .map((o) => o.amount)
      .fold(Money.zero, (a, b) => a + b);

  return currentBalance
      + projectedIncome
      - projectedVariableSpend
      - confirmedObligations;
}
```

### Métrica 3: Days Until Empty (DUE)

**La métrica más impactante emocionalmente.** Si el usuario ve "quedan 8 días de efectivo" → acción inmediata.

```dart
int calculateDaysUntilEmpty({
  required Money currentBalance,
  required Money dailyBurnRate,
  required List<ScheduledPayment> upcomingObligations,
}) {
  var balance = currentBalance;
  var day = 0;

  while (balance > Money.zero) {
    day++;
    // Descontar burn rate diario
    balance -= dailyBurnRate;

    // Descontar obligaciones que vencen este día
    final todaysObligations = upcomingObligations
        .where((o) => o.daysFromNow == day)
        .map((o) => o.amount)
        .fold(Money.zero, (a, b) => a + b);
    balance -= todaysObligations;

    if (day > 365) return -1; // Solvente por más de un año
  }

  return day;
}
```

### Métrica 4: Budget Risk Score (BRS)

```dart
/// Score 0-100. 0 = sin riesgo. 100 = crisis financiera inminente.
double calculateBudgetRisk({
  required List<EnvelopeStatus> envelopes,
  required BurnRate burnRate,
  required int daysUntilEmpty,
  required Money currentBalance,
  required Money emergencyFund,
}) {
  double risk = 0;

  // Factor 1: Envelopes overspent (0-25 pts)
  final overspentCount = envelopes.where((e) => e.isOverspent).length;
  risk += (overspentCount / envelopes.length * 25).clamp(0, 25);

  // Factor 2: Burn rate por encima del plan (0-25 pts)
  if (burnRate.paceVsBudget > 1.0) {
    risk += ((burnRate.paceVsBudget - 1.0) * 50).clamp(0, 25);
  }

  // Factor 3: Días hasta cero (0-30 pts)
  if (daysUntilEmpty < 7) risk += 30;
  else if (daysUntilEmpty < 14) risk += 20;
  else if (daysUntilEmpty < 30) risk += 10;

  // Factor 4: Sin reserva de emergencia (0-20 pts)
  if (emergencyFund < Money.zero) risk += 20;
  else if (emergencyFund.amount < currentBalance.amount * 0.5) risk += 10;

  return risk.clamp(0, 100);
}
```

### Métrica 5: Category Velocity

Detecta qué categorías están "fuera de control" con base en su historial.

```dart
class CategoryVelocity {
  final CategoryRef category;
  final Money currentSpend;
  final Money historicalAverage;    // promedio de los últimos 3 períodos
  final Money projectedEndOfPeriod;
  final double deviationPercent;    // (current - avg) / avg * 100

  bool get isOverPace => deviationPercent > 20;  // más de 20% sobre promedio
  bool get isUnderPace => deviationPercent < -20;

  String get diagnosis {
    if (deviationPercent > 50) return 'Muy por encima del patrón histórico';
    if (deviationPercent > 20) return 'Ritmo acelerado respecto al promedio';
    if (deviationPercent < -20) return 'Por debajo del ritmo habitual';
    return 'Ritmo normal';
  }
}
```

### Métrica 6: Savings Prediction

```dart
Money predictSavings({
  required Money projectedIncome,
  required Money projectedSpend,
  required Money totalObligations,
  required List<Envelope> envelopes,
}) {
  // Ahorro = Ingreso - Gasto Variable Proyectado - Obligaciones Fijas
  final predictedSavings = projectedIncome - projectedSpend - totalObligations;

  // Aplicar factor de corrección histórica (los proyectados suelen estar ~5% abajo)
  final correctionFactor = _calculateHistoricalCorrectionFactor();

  return predictedSavings * correctionFactor;
}
```

### Métrica 7: Liquidity Risk

```dart
enum LiquidityRisk { none, low, medium, high, critical }

LiquidityRisk assessLiquidityRisk({
  required Money currentLiquidBalance,
  required List<ScheduledPayment> nextSevenDays,
  required Money dailyBurnRate,
}) {
  final obligationsNextWeek = nextSevenDays
      .map((p) => p.amount)
      .fold(Money.zero, (a, b) => a + b);

  final projectedBalanceInWeek = currentLiquidBalance
      - (dailyBurnRate * 7)
      - obligationsNextWeek;

  if (projectedBalanceInWeek < Money.zero) return LiquidityRisk.critical;
  if (projectedBalanceInWeek.amount < currentLiquidBalance.amount * 0.1)
    return LiquidityRisk.high;
  if (projectedBalanceInWeek.amount < currentLiquidBalance.amount * 0.25)
    return LiquidityRisk.medium;
  if (projectedBalanceInWeek.amount < currentLiquidBalance.amount * 0.50)
    return LiquidityRisk.low;
  return LiquidityRisk.none;
}
```

## 7.3 Arquitectura del ForecastingEngine

```dart
class ForecastingEngine {
  final LedgerRepository _ledger;
  final ObligationEngine _obligations;
  final EnvelopeEngine _envelopes;

  // Cache con invalidación basada en eventos
  final Map<String, CachedProjection> _cache = {};

  /// Genera la proyección completa para un período.
  /// Invalidar cuando: nueva transacción, nueva cuota, nuevo recurrente, cambio de budget.
  Future<FinancialProjection> projectPeriod({
    required FinancialPeriod period,
    required String userId,
    int forecastDaysAhead = 90,
  }) async {
    final cacheKey = '${userId}_${period.startIso}';
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isStale) {
      return _cache[cacheKey]!.projection;
    }

    // 1. Estado actual
    final currentBalance = await _ledger.getCurrentBalance(userId, period);
    final totalIncome = await _ledger.getTotalIncome(userId, period);
    final totalSpent = await _ledger.getTotalSpent(userId, period);
    final daysElapsed = _daysElapsed(period);
    final daysRemaining = _daysRemaining(period);

    // 2. Burn rate
    final burnRate = BurnRate(
      totalSpent: totalSpent,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
    );

    // 3. Obligaciones futuras (cuotas + recurrentes)
    final upcomingObligations = await _obligations.getScheduledPayments(
      userId,
      DateRange(start: DateTime.now(), end: period.end),
    );

    // 4. Proyectar balance al cierre
    final projectedIncome = await _projectRemainingIncome(userId, period);
    final projectedClosingBalance = calculateProjectedClosingBalance(
      currentBalance: currentBalance,
      projectedIncome: projectedIncome,
      projectedVariableSpend: burnRate.dailyRate * daysRemaining,
      obligations: upcomingObligations,
    );

    // 5. Days Until Empty
    final daysUntilEmpty = calculateDaysUntilEmpty(
      currentBalance: currentBalance,
      dailyBurnRate: burnRate.dailyRate,
      upcomingObligations: upcomingObligations,
    );

    // 6. Category velocities
    final envelopes = await _envelopes.getPeriodEnvelopes(userId, period);
    final categoryVelocities = await _calculateCategoryVelocities(
      userId, period, envelopes, daysElapsed,
    );

    // 7. Budget Risk Score
    final riskScore = calculateBudgetRisk(
      envelopes: envelopes,
      burnRate: burnRate,
      daysUntilEmpty: daysUntilEmpty,
      currentBalance: currentBalance,
      emergencyFund: await _ledger.getEmergencyFund(userId),
    );

    // 8. Savings prediction
    final predictedSavings = predictSavings(
      projectedIncome: totalIncome + projectedIncome,
      projectedSpend: burnRate.projectedTotalSpend,
      totalObligations: upcomingObligations.map((o) => o.amount).fold(Money.zero, (a, b) => a + b),
      envelopes: envelopes,
    );

    // 9. Proyección a futuro (próximos 90 días)
    final cashflowForecast = await _buildCashflowForecast(
      userId, period, forecastDaysAhead,
    );

    final projection = FinancialProjection(
      period: period,
      currentBalance: currentBalance,
      burnRate: burnRate,
      projectedClosingBalance: projectedClosingBalance,
      daysUntilEmpty: daysUntilEmpty,
      upcomingObligations: upcomingObligations,
      categoryVelocities: categoryVelocities,
      riskScore: riskScore,
      predictedSavings: predictedSavings,
      liquidityRisk: assessLiquidityRisk(...),
      cashflowForecast: cashflowForecast,
      generatedAt: DateTime.now(),
    );

    _cache[cacheKey] = CachedProjection(projection: projection);
    return projection;
  }

  /// Construye el forecast de cashflow día por día para los próximos N días
  Future<CashflowForecast> _buildCashflowForecast(
    String userId,
    FinancialPeriod currentPeriod,
    int days,
  ) async {
    final dataPoints = <CashflowDataPoint>[];
    var runningBalance = await _ledger.getCurrentBalance(userId, currentPeriod);
    final dailyBurn = (await _ledger.getTotalSpent(userId, currentPeriod)).amount
        / _daysElapsed(currentPeriod);

    final obligations = await _obligations.getScheduledPayments(
      userId,
      DateRange(start: DateTime.now(), end: DateTime.now().add(Duration(days: days))),
    );

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().add(Duration(days: i));

      // Obligaciones del día
      final dayObligations = obligations.where((o) => _isSameDay(o.date, date));
      final obligationAmount = dayObligations
          .map((o) => o.amount)
          .fold(Money.zero, (a, b) => a + b);

      // Ingresos esperados del día
      final dayIncome = await _projectIncomeForDate(userId, date);

      runningBalance = runningBalance + dayIncome - Money.fromDouble(dailyBurn) - obligationAmount;

      dataPoints.add(CashflowDataPoint(
        date: date,
        balance: runningBalance,
        dailyExpenses: Money.fromDouble(dailyBurn) + obligationAmount,
        dailyIncome: dayIncome,
        hasObligation: dayObligations.isNotEmpty,
      ));
    }

    return CashflowForecast(dataPoints: dataPoints, days: days);
  }
}
```

## 7.4 Incremental Calculations y Performance

El forecasting NO se recalcula en cada rebuild de widget. La estrategia:

```dart
// Provider Riverpod con cache y invalidación selectiva
@riverpod
Future<FinancialProjection> financialProjection(
  Ref ref, {
  required FinancialPeriod period,
  required String userId,
}) async {
  // Escuchar solo los eventos que invalidan el cache
  ref.listen(transactionStreamProvider(period), (_, __) {
    ref.invalidateSelf();
  });
  ref.listen(obligationsStreamProvider(userId), (_, __) {
    ref.invalidateSelf();
  });

  return ForecastingEngine.instance.projectPeriod(period: period, userId: userId);
}

// El ForecastingEngine tiene cache interno con TTL de 5 minutos
// + invalidación por evento. No recalcula si no cambió nada.
```

**Estrategia de cálculo por capas**:
- **Layer 1 (instantáneo)**: Balance actual = dato de DB, sin cálculo
- **Layer 2 (<50ms)**: BurnRate = división simple
- **Layer 3 (<200ms)**: Projected balance = burnrate + obligaciones (query simple)
- **Layer 4 (<500ms)**: Category velocities = comparación con histórico
- **Layer 5 (<1s)**: Full cashflow forecast 90 días = cálculo iterativo

La UI muestra Layer 1-2 inmediatamente y va revelando capas con skeleton loaders.

---

# 8. BUDGET INTELLIGENCE LAYER

## 8.1 El Copiloto que Farol Necesita

No quieres un chatbot genérico que responde preguntas. Quieres un copiloto que observa, detecta, y avisa *antes* de que el problema ocurra. La inteligencia no es artificial en el sentido de ML — es un conjunto de reglas expertas con scoring contextual.

## 8.2 Tipos de Insights

```dart
enum InsightType {
  // Alertas preventivas
  budgetRisk,          // "Tu presupuesto de Lazer va a superar el límite en 5 días"
  liquidityAlert,      // "Tienes R$340 líquidos con R$580 en obligaciones esta semana"
  overdraftWarning,    // "Si sigues así, cerrarás el período con -R$120"

  // Patrones detectados
  spendingSpike,       // "Gastaste 3x más en Delivery esta semana vs tu promedio"
  duplicateCharge,     // "Detecté 2 cobros de Netflix este mes"
  unusualMerchant,     // "Primera vez que aparece 'Shopee' por R$340 en tu historial"
  subscriptionCreep,   // "Tus suscripciones subieron R$180 en los últimos 3 meses"

  // Oportunidades
  savingsOpportunity,  // "Si reduces Delivery a tu promedio, ahorras R$200 más este mes"
  earlyPayoff,         // "Con R$50 extra/mes, tu iPhone se termina 2 meses antes"
  investmentOpportunity, // "Tienes R$800 libres este período que podrían ir a tu reserva"

  // Logros
  budgetMet,           // "¡Cerraste Transporte dentro del presupuesto por 3 meses seguidos!"
  savingsRecord,       // "Este mes ahorraste R$1,240 — tu mejor marca en 6 meses"
  debtReduction,       // "Tus cuotas activas bajaron de R$800 a R$300 en los últimos 60 días"
}

class FinancialInsight {
  final String id;
  final InsightType type;
  final String title;           // "Alerta: Lazer sobre el límite"
  final String body;            // Explicación detallada
  final String? actionLabel;   // "Ver Lazer" | "Ajustar presupuesto" | "Ignorar"
  final InsightPriority priority; // critical | warning | info | achievement
  final double confidence;     // 0.0-1.0
  final Map<String, dynamic> data; // datos que soportan el insight
  final DateTime generatedAt;
  final DateTime? expiresAt;   // algunos insights tienen vigencia
  final bool isDismissable;
}
```

## 8.3 Reglas del Motor de Inteligencia

```dart
class IntelligenceLayer {

  List<FinancialInsight> analyze(FinancialSnapshot snapshot) {
    final insights = <FinancialInsight>[];

    insights.addAll(_checkLiquidityAlerts(snapshot));
    insights.addAll(_checkBudgetRisk(snapshot));
    insights.addAll(_checkSpendingPatterns(snapshot));
    insights.addAll(_detectDuplicates(snapshot));
    insights.addAll(_findOpportunities(snapshot));
    insights.addAll(_checkAchievements(snapshot));

    // Deduplicar y priorizar
    return _prioritize(insights);
  }

  List<FinancialInsight> _checkLiquidityAlerts(FinancialSnapshot s) {
    final insights = <FinancialInsight>[];

    // Alerta crítica: balance negativo proyectado antes del cierre del período
    if (s.projectedClosingBalance < Money.zero) {
      insights.add(FinancialInsight(
        type: InsightType.overdraftWarning,
        title: 'Risco de saldo negativo',
        body: 'Com o ritmo atual, você fechará o período com ${s.projectedClosingBalance.formatted}. '
            'Há R${s.totalFutureObligations.formatted} em compromissos confirmados.',
        priority: InsightPriority.critical,
        confidence: 0.85,
        actionLabel: 'Ver projeção',
      ));
    }

    // Alerta high: liquidez para los próximos 7 días
    if (s.liquidityRisk == LiquidityRisk.high) {
      final obligationsThisWeek = s.upcomingPayments
          .where((p) => p.daysFromNow <= 7)
          .map((p) => p.amount)
          .fold(Money.zero, (a, b) => a + b);

      insights.add(FinancialInsight(
        type: InsightType.liquidityAlert,
        title: 'Semana apertada',
        body: 'Você tem ${s.currentBalance.formatted} disponível e '
            '${obligationsThisWeek.formatted} em pagamentos essa semana.',
        priority: InsightPriority.warning,
        confidence: 0.95,
      ));
    }

    return insights;
  }

  List<FinancialInsight> _checkSpendingPatterns(FinancialSnapshot s) {
    final insights = <FinancialInsight>[];

    for (final velocity in s.categoryVelocities) {
      // Spike: gastando >50% más que el promedio histórico
      if (velocity.deviationPercent > 50 && velocity.currentSpend.amount > 50) {
        insights.add(FinancialInsight(
          type: InsightType.spendingSpike,
          title: 'Spike em ${velocity.category.name}',
          body: 'Você já gastou ${velocity.currentSpend.formatted} em ${velocity.category.name} '
              'contra uma média de ${velocity.historicalAverage.formatted}. '
              '${velocity.deviationPercent.round()}% acima do normal.',
          priority: InsightPriority.warning,
          confidence: 0.80,
        ));
      }
    }

    return insights;
  }

  List<FinancialInsight> _detectDuplicates(FinancialSnapshot s) {
    // Agrupar transacciones por (store_name, amount, ±3 dias)
    // Si aparecen 2+ con los mismos atributos → duplicado probable
    final candidates = s.recentTransactions
        .groupBy((t) => '${t.storeName}_${t.amount.cents}')
        .where((group) => group.length >= 2)
        .where((group) => group.map((t) => t.date)
            .sorted()
            .consecutive()
            .any((pair) => pair.$2.difference(pair.$1).inDays <= 3));

    return candidates.map((group) => FinancialInsight(
      type: InsightType.duplicateCharge,
      title: 'Possível cobrança duplicada',
      body: 'Encontrei ${group.length} cobranças de "${group.first.storeName}" '
          'por ${group.first.amount.formatted} em dias seguidos.',
      priority: InsightPriority.warning,
      confidence: 0.70,
      actionLabel: 'Verificar',
    )).toList();
  }

  List<FinancialInsight> _findOpportunities(FinancialSnapshot s) {
    final insights = <FinancialInsight>[];

    // Oportunidad de ahorro: categoría variable con historial de exceso
    for (final envelope in s.envelopes.where((e) => e.isOverspent)) {
      final potentialSaving = envelope.overspentAmount;
      if (potentialSaving.amount > 20) {
        insights.add(FinancialInsight(
          type: InsightType.savingsOpportunity,
          title: 'Economia possível em ${envelope.category.name}',
          body: 'Se você reduzir ${envelope.category.name} ao orçamento planejado, '
              'sobraria mais ${potentialSaving.formatted} esse período.',
          priority: InsightPriority.info,
          confidence: 0.65,
        ));
      }
    }

    // Oportunidad de inversión: balance proyectado positivo > umbral
    if (s.predictedSavings.amount > 500) {
      insights.add(FinancialInsight(
        type: InsightType.investmentOpportunity,
        title: 'Você vai sobrar ${s.predictedSavings.formatted}',
        body: 'Com base na sua velocidade atual, você terá ${s.predictedSavings.formatted} '
            'livres no final do período. Que tal reservar uma parte?',
        priority: InsightPriority.info,
        confidence: 0.75,
        actionLabel: 'Ver opções',
      ));
    }

    return insights;
  }

  /// Deduplicar insights similares y ordenar por prioridad
  List<FinancialInsight> _prioritize(List<FinancialInsight> insights) {
    return insights
        .where((i) => i.confidence >= 0.60)      // filtrar baja confianza
        .toSet()                                   // deduplicar
        .sorted((a, b) {
          // Ordenar: critical > warning > info > achievement
          final priorityOrder = [
            InsightPriority.critical,
            InsightPriority.warning,
            InsightPriority.info,
            InsightPriority.achievement,
          ];
          return priorityOrder.indexOf(a.priority)
              .compareTo(priorityOrder.indexOf(b.priority));
        })
        .take(5)  // máximo 5 insights simultáneos (no abrumar al usuario)
        .toList();
  }
}
```

## 8.4 UX de Insights: No Invasivo

Los insights **no son notificaciones push** en el arranque de la app. Son un panel contextual en el dashboard que aparece cuando hay algo relevante. Reglas:

- Máximo 1 insight `critical` visible al mismo tiempo
- Los insights de `achievement` solo se muestran si el usuario está en el tab de Saúde
- El usuario puede silenciar un tipo de insight por 30 días
- Los insights expiran: un "risco de saldo negativo" de ayer no es relevante hoy
- Nunca mostrar más de 5 insights en lista (el sexto se oculta detrás de "Ver todos")

---

# 9. ARQUITECTURA DE SINCRONIZACIÓN

## 9.1 El Principio Correcto para Farol

Farol no es Notion ni Obsidian. No necesita sincronización bidireccional offline-first extrema. El usuario principal de Farol (CLT brasileño) usa la app con conexión 95% del tiempo. Lo que necesita:

- **Entrada de datos rápida sin esperar red** (optimistic updates)
- **Sin pérdida de datos si cae la red** (queue persistente)
- **Sin datos duplicados** (idempotency)
- **Sync inmediato al reconectar** (retry automático)

## 9.2 Estrategia: Optimistic + Queue

```dart
class SyncManager {
  final OperationQueue _queue;
  final SupabaseClient _supabase;
  final ConnectivityMonitor _connectivity;

  /// Registra una operación. Si hay red → ejecuta inmediatamente.
  /// Si no hay red → encola para retry.
  Future<void> execute(SyncOperation op) async {
    // 1. Aplicar inmediatamente al estado local (optimistic update)
    await op.applyLocally();

    if (await _connectivity.isOnline) {
      try {
        await op.executeRemote(_supabase);
        await op.markCompleted();
      } catch (e) {
        // Si falla remote, encolar para retry
        await _queue.enqueue(op);
        // El estado local ya está actualizado (optimistic)
        // El usuario no ve error excepto en casos críticos
      }
    } else {
      await _queue.enqueue(op);
    }
  }
}

class OperationQueue {
  // Persiste la queue en Drift para sobrevivir reinicios de app
  final AppDatabase _db;

  Future<void> enqueue(SyncOperation op) async {
    await _db.insertQueueItem(QueueItemsCompanion(
      operationType: Value(op.type.name),
      payload: Value(jsonEncode(op.toJson())),
      idempotencyKey: Value(op.idempotencyKey), // UUID de la operación
      retryCount: const Value(0),
      status: Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Procesar queue pendiente. Llamar al reconectar.
  Future<void> processPending() async {
    final pending = await _db.getPendingQueueItems();

    for (final item in pending) {
      try {
        final op = SyncOperation.fromJson(jsonDecode(item.payload));
        await op.executeRemote(_supabase);
        await _db.markQueueItemCompleted(item.id);
      } catch (e) {
        if (item.retryCount >= 3) {
          // Después de 3 intentos → marcar como fallido y notificar al usuario
          await _db.markQueueItemFailed(item.id, e.toString());
        } else {
          await _db.incrementRetryCount(item.id);
        }
      }
    }
  }
}
```

## 9.3 Schema de Queue (Drift)

```dart
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()(); // 'insert_expense' | 'update_envelope' | etc.
  TextColumn get payload => text()();       // JSON serializado
  TextColumn get idempotencyKey => text().unique()(); // UUID, evita duplicados en retry
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}
```

## 9.4 Resolución de Conflictos

Para Farol, los conflictos son raros pero pueden ocurrir (dos dispositivos del mismo usuario). Estrategia: **Last-Write-Wins con timestamp + merge semántico para envelopes**.

```dart
class ConflictResolver {
  /// Para transacciones: Last-Write-Wins (el más reciente gana)
  Transaction resolveTransaction(Transaction local, Transaction remote) {
    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }

  /// Para envelopes: merge semántico (el allocated más alto gana,
  /// el spent se suma si ambos tienen transacciones distintas)
  Envelope resolveEnvelope(Envelope local, Envelope remote) {
    // Si son del mismo updatedAt → no hay conflicto real
    if (local.updatedAt == remote.updatedAt) return local;

    return Envelope(
      id: local.id,
      allocated: Money.max(local.allocated, remote.allocated),
      spent: Money.max(local.spent, remote.spent), // el real se recalcula desde transactions
      updatedAt: DateTime.now(),
      // El resto: last-write-wins
    );
  }
}
```

---

# 10. ROADMAP DE IMPLEMENTACIÓN REALISTA

## Principio: No Big Bang Rewrite

Cada fase tiene valor de producto independiente. El usuario siente la mejora después de cada fase. La deuda técnica se reduce incrementalmente.

---

## FASE 1: Fundamentos Sólidos (Semanas 1-4)
**ROI**: Elimina errores actuales, prepara el terreno. Sin esta fase, todo lo demás colapsa.

### 1.1 Unificación del sistema de categorías (Semana 1-2)
- Crear tabla `categories` en Supabase (con slugs que matchean los dbValues del enum)
- Crear `CategoryRef` value object en Dart
- Escribir `CategoryResolver` que maneja string legacy → CategoryRef sin excepciones
- Backfill: campo `category_id UUID` en `expenses` (nullable primero)
- Mantener el enum en paralelo temporalmente
- **Test crítico**: `ExpenseCategory.fromDb('CUSTOM_XYZ')` nunca lanza StateError

**Complejidad**: Media | **Riesgo**: Bajo (cambios aditivos) | **Dependencias**: Ninguna

### 1.2 Migración de Expenses a fechas reales (Semana 2)
- Agregar `transaction_date DATE` en la tabla `expenses` (ya existe en el modelo Dart)
- Asegurar que todos los queries de período usen `transaction_date BETWEEN` en vez de `month/year`
- El campo `month/year` puede mantenerse como índice adicional para compatibilidad
- Actualizar `getExpensesByRange` para usar date range real

**Complejidad**: Baja | **Riesgo**: Medio (puede afectar queries existentes)

### 1.3 InstallmentPlan + InstallmentPayments (Semana 3-4)
- Crear tabla `installment_plans` y `installment_payments` en Supabase
- Migrar `card_installments` existentes: cada registro genera un plan con N payments
- Actualizar `InstallmentRepository` para usar el nuevo schema
- La UI de installments puede quedar igual — solo cambia el backend
- Mantener `card_installments` tabla vieja en readonly durante transición

**Complejidad**: Alta | **Riesgo**: Medio | **Dependencias**: Fechas reales (1.2)

### Métricas de éxito Fase 1
- 0 StateError por categoría desconocida en producción
- Los installments muestran fechas de vencimiento futuras
- Los períodos financieros filtran por fecha real, no month/year

---

## FASE 2: Motor Central (Semanas 5-10)
**ROI**: El producto empieza a "pensar" por el usuario. Primera diferenciación real.

### 2.1 RecurringRule Engine (Semana 5-6)
- Crear tabla `recurring_rules` y `recurring_occurrences`
- Implementar `RecurrenceResolver.generateOccurrences()`
- UI: nueva pantalla "Gastos Fixos & Recorrentes" (reemplaza el isFixed copy)
- Migrar gastos `isFixed = true` existentes a `RecurringRule` equivalentes
- Configurar job background para generar ocurrencias del próximo mes

**Complejidad**: Alta | **Riesgo**: Medio

### 2.2 EnvelopeEngine con Rollover (Semana 7-8)
- Extender `period_budgets` → `envelopes` con rollover_policy
- Implementar `EnvelopeEngine.calculateRollover()`
- UI: badge "Rollover: R$120 do período anterior" en budget card
- Implementar envelope automático para cuotas

**Complejidad**: Media | **Riesgo**: Bajo

### 2.3 FinancialSnapshot unificado (Semana 9-10)
- Crear `FinancialEngine` que produce `FinancialSnapshot`
- Migrar el `DashboardScreen` para consumir solo el snapshot
- Eliminar cálculos duplicados en widgets individuales
- Implementar cache con invalidación por evento

**Complejidad**: Alta | **Riesgo**: Alto (refactoring del dashboard)

### Métricas de éxito Fase 2
- Dashboard carga con un único observable (FinancialSnapshot)
- Recurrentes se proyectan 3 meses hacia adelante automáticamente
- El rollover de envelopes funciona correctamente entre períodos

---

## FASE 3: Forecasting Real (Semanas 11-16)
**ROI**: El "momento wow" del producto. El usuario ve el futuro de sus finanzas.

### 3.1 BurnRate + DaysUntilEmpty (Semana 11-12)
- Implementar `BurnRate` calculation en `ForecastingEngine`
- UI: nuevo widget "Velocidade Financeira" en el dashboard
- Mostrar DaysUntilEmpty con semáforo (verde/amarillo/rojo)
- Alertas proactivas en el dashboard cuando DUE < 14 días

### 3.2 Projected Balance + Cashflow Chart (Semana 13-14)
- Implementar `calculateProjectedClosingBalance()`
- UI: Chart de proyección de balance (línea sólida = real, línea punteada = proyectado)
- Integrar cuotas futuras como puntos en el chart (drops visibles)
- Integrar ingresos proyectados como puntos (income events)

### 3.3 Category Velocity + Risk Score (Semana 15-16)
- Implementar `CategoryVelocity` para todas las categorías
- UI: indicador de velocidad por categoría en el budget screen
- Implementar `BudgetRiskScore` general
- UI: Health Score migra de estático a dinámico/predictivo

### Métricas de éxito Fase 3
- El usuario puede responder "¿cuánto voy a ahorrar este mes?" mirando la app
- El cashflow chart muestra correctamente drops de cuotas futuras
- El Risk Score cambia en tiempo real cuando se registra un gasto

---

## FASE 4: Inteligencia y Pulido (Semanas 17-24)
**ROI**: Retención. El usuario que llega a esta fase no abandona la app.

### 4.1 Intelligence Layer (Semana 17-19)
- Implementar `IntelligenceLayer` con las 8 reglas core
- UI: panel de insights en el dashboard (máximo 3 visibles)
- Implementar dismissal y silenciado de tipos de insight
- Implementar detección de recurrentes automática
- UI: sugerencia "Detecté que pagas Netflix cada mes, ¿rastrearlo?"

### 4.2 Detección Automática de Recurrentes (Semana 20-21)
- Implementar `RecurringDetector.detect()`
- UI: onboarding flow que propone recurrentes detectados
- Sistema de confirmación/rechazo de candidatos

### 4.3 Sincronización Robusta (Semana 22-23)
- Implementar `OperationQueue` en Drift
- Implementar `SyncManager` con retry logic
- UI: indicador de estado de sync (discreto, no invasivo)
- Tests de sincronización: offline → registro → reconexión → datos coherentes

### 4.4 Supabase Edge Functions para cálculos pesados (Semana 24)
- Mover el cálculo del cashflow forecast a una Edge Function
- El cliente solo pide el resultado cacheado
- Invalidar cache en el servidor cuando llegan nuevas transacciones

### Métricas de éxito Fase 4
- El sistema detecta recurrentes con >75% de precisión en el historial real del usuario
- Los insights tienen tasa de dismiss < 30% (son relevantes)
- Cero pérdida de datos en escenario offline → online

---

## Dependencias del Roadmap

```
Fase 1.1 (Categorías) ←── Todo lo demás depende de esto
     │
     ├──→ Fase 1.2 (Fechas) ←── Fase 1.3 (Installments)
     │                                    │
     └──→ Fase 2.1 (Recurrentes)         │
               │                         │
               └──→ Fase 2.2 (Envelopes)─┘
                         │
                         └──→ Fase 2.3 (FinancialSnapshot)
                                    │
                                    └──→ Fase 3 (Forecasting)
                                               │
                                               └──→ Fase 4 (Intelligence)
```

---

# 11. RIESGOS Y ERRORES COMUNES

## 11.1 Errores Arquitectónicos

**Error 1: El forecasting como ML desde el día 1**
Muchas apps financieras intentan implementar machine learning para predecir gastos antes de tener datos históricos suficientes. Un usuario nuevo no tiene historial. El motor matemático determinista (burnrate, obligaciones, velocidad) da mejores resultados con datos escasos que cualquier modelo ML. ML es Fase 5+.

**Error 2: Sincronización bidireccional antes de tener usuarios**
Invertir semanas en conflict resolution para un producto con un solo usuario activo es over-engineering clásico. La estrategia Last-Write-Wins es suficiente para los primeros 1,000 usuarios.

**Error 3: Categorías infinitamente anidadas**
La jerarquía padre/hijo es correcta pero máximo 2 niveles (categoría → subcategoría). 3+ niveles crean UX pesadilla en mobile y queries JOIN complejos. YNAB tiene 0 anidamiento. Farol puede tener 2.

**Error 4: Envelopes ultra-granulares**
No hacer un envelope por subcategoría. Un envelope por categoría raíz es suficiente. La granularidad excesiva crea cognitive overload. El usuario de YNAB medio tiene 15-20 envelopes, no 50.

**Error 5: Invalidar el cache de forecasting en cada tick**
Si el ForecastingEngine se recalcula cada vez que el timer de Riverpod dispara, el CPU usage en mobile es inaceptable. El cache TTL debe ser de mínimo 5 minutos, con invalidación solo en eventos reales (nueva transacción, nuevo recurrente).

## 11.2 Riesgos de UX

**Riesgo: Demasiados insights simultáneos**
Si el usuario ve 8 insights al abrir la app, aprende a ignorarlos todos. Máximo 3 en pantalla, con prioridad estricta. Less is more.

**Riesgo: El forecast genera ansiedad**
"Te quedan 8 días de efectivo" es útil. "Proyección de solvencia: 8.2 días con intervalo de confianza 73%" es aterrador e inútil. El lenguaje debe ser humano y accionable, no estadístico.

**Riesgo: Rollover confuso**
Los usuarios de YNAB tardan semanas en entender el rollover. La UI debe explicarlo con ejemplos concretos: "Sobraron R$120 de Lazer en enero → se sumaron a tu presupuesto de Lazer en febrero". Nunca mostrar números sin contexto.

**Riesgo: Instalamento vs gasto**
Si una compra parcelada genera tanto un `Expense` como un `InstallmentPayment`, el usuario puede ver el monto duplicado. La UI debe ser explícita: "Este gasto forma parte del plan 'iPhone 15 - 12x'. Cuota 1 de 12."

## 11.3 Riesgos de Performance

**Riesgo: Queries de forecasting sin índices**
El cashflow forecast consulta todas las transacciones futuras. Sin índice en `due_date` + `user_id`, esto es un full table scan. Agregar índice compuesto `(user_id, due_date, status)` en `installment_payments` y `recurring_occurrences`.

**Riesgo: Materializar demasiado pronto**
Las vistas materializadas en Supabase son útiles pero añaden complejidad operacional (necesitan refresh). Empezar con queries normales y materializar solo lo que sea probadamente lento con usuarios reales.

**Riesgo: Supabase Realtime para todo**
Supabase Realtime consume WebSocket connections. Para el forecasting no es necesario realtime a nivel de milisegundos — polling cada 30 segundos o invalidación por evento de escritura es suficiente.

## 11.4 Errores Comunes de Apps Financieras

1. **YNAB-copy sin adaptación**: El modelo YNAB es para economías estables con ingresos mensuales fijos. Brasil tiene: 13° salário (enero vs diciembre), Swile (bucket separado), FGTS (no líquido), cuotas de cartão como cultura. Copiar YNAB literalmente es un error.

2. **Categorías en inglés para un mercado latinoamericano**: "Leisure" no significa nada culturalmente para un brasileño. "Lazer", "Alimentação", "Moradia" sí.

3. **Ignorar el período de corte**: La mayoría de apps usan mes calendario. El `cutoffDay` de Farol es una ventaja competitiva real — la mayoría de brasileños reciben el salario entre el 5 y el 15, no el 1.

4. **Health Score sin predictividad**: Un score de "tu situación actual" no genera engagement. Un score de "cómo vas a terminar el período si sigues así" sí lo genera.

5. **Forzar presupuesto desde el primer día**: Los usuarios nuevos no tienen historial. El onboarding debe empezar con tracking puro (sin presupuesto) y sugerir presupuesto después de 30 días de datos.

---

# 12. RESULTADO FINAL ESPERADO

## 12.1 ¿Cómo debe sentirse Farol después de esta evolución?

El usuario abre Farol en la mañana antes de ir al trabajo. En 3 segundos, sin leer nada, sabe:
- **Verde / Amarillo / Rojo**: su situación financiera del período
- **Un número clave**: "Te quedan R$1,240 libres de presupuesto"
- **Un alert específico si hay algo urgente**: "Tienes 3 cuotas esta semana: R$580"

A fin de período, sin que el usuario haga nada, Farol:
- Cierra los envelopes, calcula el rollover
- Genera los recurrentes del próximo período
- Le dice cuánto puede invertir este mes

En 6 meses de uso, Farol conoce el perfil de gasto del usuario mejor que él mismo y puede decir: "Históricamente, gastas R$400 más en diciembre por regalos. Tu presupuesto de diciembre ya tiene ese ajuste."

## 12.2 ¿Por qué gana contra la competencia?

| Dimensión | YNAB | Copilot | Monarch | Mobills | **Farol** |
|---|---|---|---|---|---|
| Período de corte personalizable | ❌ | ❌ | ❌ | ❌ | ✅ |
| Contexto Brasil (Swile, FGTS, 13°) | ❌ | ❌ | ❌ | Parcial | ✅ |
| Forecasting predictivo | Básico | ✅ | Básico | ❌ | ✅ |
| Cuotas integradas al cashflow | ❌ | Parcial | Parcial | ✅ | ✅ |
| Precio asequible para LATAM | ❌ ($15/mes) | ❌ ($13/mes) | ❌ ($10/mes) | Freemium | ✅ |
| Offline-first real | ❌ | ❌ | ❌ | ❌ | ✅ (Drift) |
| Recurrentes con RRULE | ✅ | Básico | Básico | Básico | ✅ |
| Health Score predictivo | ❌ | Básico | ❌ | ❌ | ✅ |

## 12.3 La Ventaja Competitiva Real

**Farol tiene algo que ninguna app occidental puede copiar fácilmente: entiende la realidad financiera del trabajador CLT brasileño.**

El cutoffDay = 10 porque el salário cae el día 10. El Swile es un bucket separado porque el benefício não é dinheiro, é crédito. O 13° salário não é bônus, é planejado. As parcelas no cartão não são dívidas, são o jeito de comprar no Brasil.

Esa comprensión cultural, integrada en el motor financiero desde la arquitectura, no en la UI, es la ventaja competitiva. No es una feature. Es el modelo mental correcto.

## 12.4 Visión a 18 meses: Farol como SaaS

Con el Financial Engine desacoplado de Flutter:
- **Farol API**: exponer el engine como API REST → Open Finance integrations
- **Farol Web**: mismo engine, UI React
- **Multi-cuenta**: el engine maneja N usuarios sin cambios de arquitectura
- **Multi-moneda**: el Value Object `Money` ya puede tener `currencyCode`
- **IA Contextual**: los insights basados en reglas se enriquecen con LLM (embeddings sobre historial financiero, preguntas en lenguaje natural)
- **Família**: un `userId` puede tener múltiples `FinancialProfile` (yo, minha esposa, conta conjunta)

El Predictive Financial Engine no es la versión 2.0 de Farol. Es la base sobre la que se construye el producto definitivo.

---

## APÉNDICE: Checklist de Implementación por Fase

### Fase 1 ✅ Fundamentos
- [ ] Crear tabla `categories` en Supabase con todos los slugs sistema
- [ ] Implementar `CategoryRef` value object
- [ ] Implementar `CategoryResolver` (string → CategoryRef, nunca lanza)
- [ ] Backfill `category_id` en `expenses`
- [ ] Crear tabla `installment_plans` + `installment_payments`
- [ ] Migrar `card_installments` → new schema
- [ ] Agregar `transaction_date` real a expenses (todos los flows)
- [ ] Tests: period filter usa fecha real, no month/year

### Fase 2 ✅ Motor Central
- [ ] Crear tabla `recurring_rules` + `recurring_occurrences`
- [ ] Implementar `RecurrenceResolver.generateOccurrences()`
- [ ] UI pantalla de Recurrentes
- [ ] Migrar gastos `isFixed` → `RecurringRule`
- [ ] Implementar `EnvelopeEngine` con rollover
- [ ] Implementar `FinancialEngine` → `FinancialSnapshot`
- [ ] Refactorizar Dashboard para consumir solo `FinancialSnapshot`

### Fase 3 ✅ Forecasting
- [ ] Implementar `BurnRate` + `DaysUntilEmpty`
- [ ] Implementar `ProjectedClosingBalance`
- [ ] Implementar `CashflowForecast` (90 días)
- [ ] UI: widget de velocidad financiera
- [ ] UI: chart de cashflow proyectado
- [ ] Implementar `CategoryVelocity`
- [ ] Implementar `BudgetRiskScore` dinámico

### Fase 4 ✅ Inteligencia
- [ ] Implementar `IntelligenceLayer` con 8 reglas
- [ ] UI: panel de insights en dashboard
- [ ] Implementar `RecurringDetector`
- [ ] UI: sugerencias de recurrentes automáticos
- [ ] Implementar `OperationQueue` en Drift
- [ ] Implementar `SyncManager` con retry
- [ ] Tests de sincronización offline → online

---

*Documento generado en Mayo 2026 · Farol Predictive Financial Engine v1.0*
*Basado en análisis del código fuente real del repositorio Farol*
