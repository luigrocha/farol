# Farol — Predictive Financial Engine
## Strategic Architecture Document
**Version 1.0 · May 2026**
**Author: Principal Software Architect (AI) · For: Luis Grocha**

---

> **Premise**: This document does not describe cosmetic improvements. It describes transforming Farol into a real predictive financial engine — the kind of system that makes a user say *"this app knows me better than I know myself"*. Every decision here was made based on the actual repository code, not on generic assumptions.

---

# TABLE OF CONTENTS

1. [Current System Diagnosis](#1-current-system-diagnosis)
2. [Ideal Financial Engine Architecture](#2-ideal-architecture)
3. [Category System Redesign](#3-category-redesign)
4. [Envelope Budgeting Engine](#4-envelopes)
5. [Recurring System](#5-recurring-system)
6. [Installments Integration](#6-installments)
7. [Forecasting Engine](#7-forecasting)
8. [Budget Intelligence Layer](#8-intelligence)
9. [Sync Architecture](#9-sync-architecture)
10. [Implementation Roadmap](#10-roadmap)
11. [Risks and Common Mistakes](#11-risks)
12. [Expected Final Result](#12-result)

---

# 1. CURRENT SYSTEM DIAGNOSIS

## 1.1 What I Found in the Code (Not Assumptions)

After analyzing the complete repository, here is the actual state:

### Data Layer

**`app_database.dart` (Drift/SQLite local)**
The local schema has 8 tables: `Incomes`, `Expenses`, `CardInstallments`, `Investments`, `NetWorthSnapshots`, `BudgetGoals`, `UserSettings`, `CategoryTable`. There is a `schemaVersion: 2` with a migration that populates system categories. The critical problem: **most real logic lives in Supabase, not Drift**. Drift tables exist but repositories in `features/` use `SupabaseClient` directly. This creates an **unresolved persistence duality**: it is not truly offline-first, it is Supabase-first with Drift as an artifact.

**`Expense` model**
The model has `installmentPlanId` (reference to an installment plan) and `isProjected` (flag for projected expenses). These fields *exist* but no service uses them coherently. They are evidence of incomplete architectural intentions.

**`CardInstallment` model**
Has `currentInstallment` (manual counter), `remainingInstallments`, `remainingBalance`. Advancement is manual — the user calls `advance()`. There is no automatic generation of installments as `expenses` rows. The `installmentPlanId` in `Expense` has no counterpart in `CardInstallments` (no foreign key to expenses). They are **two parallel worlds that don't communicate**.

### Domain Layer

**`FinancialCalculatorService`**
A service with pure static methods. Calculates: savings rate, health score (5 factors), FGTS projection, budget alerts, net worth, 13th salary, INSS/IRRF, severance, FGTS anniversary withdrawal. It is conceptually correct but **has no state, no streams, no caching**. Each calculation is independent and does not compose with others. There is no unified "period financial result" — each widget performs its own calculations in parallel.

**`FinancialPeriod`**
Excellent abstraction. The customizable `cutoffDay` is a real competitive advantage. The `current()`, `next()`, `previous()` logic is correct. **This is the most solid component in the system**.

**`PeriodBudget` + `PeriodBudgetEntry`**
The per-period budget model has a good foundation: goal as reference, override per period, spend tracking. `BudgetStatus` (ok/warning/overspent) is correct. But missing: rollover, carry-over, automatic envelopes, recurring rule linking.

### Category System: The Dual Problem

This is the most structural problem. There are **two parallel and incompatible systems**:

```
System 1: enum ExpenseCategory (enums.dart)
→ 9 hardcoded Dart values
→ Has localization, isSwile, localizedLabel
→ Used in UI, filters, calculations

System 2: CategoryTable (app_database.dart)
→ SQLite table with dbValue/name/emoji/isSwile/isSystem
→ Also in Supabase (inferred by CategoryRepository)
→ Allows user custom categories
```

The result: expenses store `category` as `String`. In some flows it is converted to the enum, in others used as raw string. `ExpenseCategory.fromDb()` throws `StateError` if the category is custom. **This is a time bomb when users create their own categories**.

### Recurring: Barely Exists

"Fixed" expenses (`isFixed = true`) are copied from the previous month via `fixedExpensePropagationProvider`. This is the only recurrence mechanism. There is no: RRULE, exceptions, pauses, automatic detection, amount prediction. The `DashboardScreen` shows a SnackBar when fixed expenses are copied — emergency UX, not product UX.

### Forecasting: Practically Nonexistent

The `isProjected` field on `Expense` suggests intent. `projectFgts()` in `FinancialCalculatorService` is the only real forecasting. There is no: projected balance, burn rate, liquidity risk, end-of-period prediction. The 10-point Health Score is a static proxy, not predictive.

---

## 1.2 Real Strengths (Reusable)

| Component | Why It Is Solid |
|---|---|
| `FinancialPeriod` with `cutoffDay` | Competitive differentiator. Mathematically correct. 100% reusable. |
| `FinancialCalculatorService` (methods) | Correct fiscal logic (INSS/IRRF 2025). Good algorithms, needs composition. |
| `PeriodBudget` + `BudgetGoal` | Valid envelope foundation. The goal→override model is extensible. |
| `BudgetGoalType` system (Need/Want/Invest) | Good classification. Compatible with 50/30/20 methodology. |
| Supabase Realtime manager | Sync infrastructure exists. Lacks orchestration. |
| Feature-based architecture | Folder structure is correct. No changes needed. |
| Swile as separate bucket concept | Financially correct for Brazil CLT. Keep it. |

## 1.3 Structural Limitations (Blocking Evolution)

1. **Categories as hardcoded Dart enum**: Impossible to extend without recompiling. Incompatible with custom categories in production.
2. **Installments and Expenses decoupled**: An installment does not generate an expense line; an expense does not bidirectionally reference an installment plan.
3. **Drift/Supabase duality without strategy**: Neither offline-first nor online-first. It is both halfway.
4. **`FinancialCalculatorService` stateless without composition**: Cannot calculate "period financial state" holistically.
5. **`month/year` as primary temporal axis**: Expenses live in `(month, year)`, not real dates. Collides with `FinancialPeriod` that crosses months.
6. **No financial event exists**: No unified concept of "something that impacts the balance on a future date".

## 1.4 Technical Debt Quantified

| Debt | Impact | Resolution Effort |
|---|---|---|
| Category enum + CategoryTable duplication | CRITICAL | 2 weeks |
| Installments with no relationship to expenses | HIGH | 1 week |
| month/year without exact date in expenses | HIGH | 3 days (migration) |
| FinancialCalculatorService without composition | MEDIUM | 1 week |
| Recurring = isFixed copy | HIGH | 2 weeks |
| Offline/online duality without strategy | MEDIUM | 2 weeks |
| Static Health Score | LOW | 3 days |

---

# 2. IDEAL FINANCIAL ENGINE ARCHITECTURE

## 2.1 Guiding Principle

Farol's Financial Engine must be **completely Flutter-agnostic**. It is a pure Dart library that could run on a server, in tests, in an isolate. Flutter is just the presentation channel.

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

## 2.2 Financial Bounded Contexts

The system is divided into 6 bounded contexts with clear boundaries:

### BC1: Identity & Period Context
**Responsibility**: Who the user is and what financial period they are in.
```
Entities: User, FinancialProfile, FinancialPeriod
Services: PeriodResolver, CutoffDayManager
Events: PeriodChanged, ProfileUpdated
```

### BC2: Ledger Context
**Responsibility**: Immutable record of all past monetary events.
```
Entities: Transaction, Income, Expense, Transfer
Value Objects: Money, CategoryRef, DateRange
Services: LedgerService, TransactionClassifier
Events: TransactionCreated, TransactionUpdated, TransactionDeleted
```

### BC3: Budget Context (Envelopes)
**Responsibility**: How much is planned to spend and how money is allocated.
```
Entities: Envelope, BudgetPlan, BudgetPeriod
Value Objects: AllocationRule, RolloverPolicy
Services: EnvelopeEngine, AllocationService
Events: EnvelopeAllocated, BudgetOverspent, RolloverCalculated
```

### BC4: Obligations Context (Future Commitments)
**Responsibility**: All known future financial commitments.
```
Entities: InstallmentPlan, InstallmentPayment, RecurringRule, RecurringOccurrence
Value Objects: RRule, PaymentSchedule
Services: ObligationEngine, RecurrenceResolver
Events: PaymentDue, InstallmentAdvanced, RecurringDetected
```

### BC5: Forecasting Context (Predictive Engine)
**Responsibility**: Projection of future financial state.
```
Entities: FinancialProjection, CashflowForecast, LiquidityRisk
Value Objects: BurnRate, VelocityVector, RiskScore
Services: ForecastingEngine, ScenarioSimulator
Events: ProjectionUpdated, RiskThresholdBreached
```

### BC6: Intelligence Context (Co-pilot)
**Responsibility**: Patterns, anomalies, and recommendations.
```
Entities: FinancialInsight, SpendingPattern, Anomaly
Value Objects: InsightType, ConfidenceScore
Services: PatternDetector, AnomalyDetector, RecommendationEngine
Events: InsightGenerated, AnomalyDetected
```

## 2.3 Main Data Flow

```
User records expense
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

## 2.4 Proposed Directory Structure

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

## 2.5 FinancialEngine: The Central Core

```dart
/// The central financial engine. Produces the complete financial state
/// of the current period. It is the single source of financial truth in the app.
class FinancialEngine {
  final LedgerRepository _ledger;
  final EnvelopeEngine _envelopes;
  final ObligationEngine _obligations;
  final ForecastingEngine _forecasting;

  /// Produces the complete financial snapshot for the period.
  /// All dashboard widgets consume this single object.
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

# 3. COMPLETE CATEGORY SYSTEM REDESIGN

## 3.1 The Real Problem (from the code)

The problem is not philosophical, it is concrete. In `enums.dart` there is `ExpenseCategory` with 9 values. In `app_database.dart` there is `CategoryTable`. In `Expense` the `category` field is `String`. In `CategoryRepository` there are Supabase queries. When a user creates a custom category with `dbValue = 'ROPA'`, `ExpenseCategory.fromDb('ROPA')` throws `StateError: No element`.

**Unification is not optional. It is a precondition for everything else.**

## 3.2 Unified Category Model

### Ideal Schema (Supabase + Drift mirror)

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

### System Category Hierarchy (Brazil, CLT)

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

## 3.3 CategoryRef: Domain Value Object

```dart
/// Value object that replaces the ExpenseCategory enum.
/// Can be system or custom. Never throws StateError.
class CategoryRef {
  final String id;       // UUID
  final String slug;     // 'housing', 'custom_ropa'
  final String name;     // localized display name
  final String emoji;
  final String? colorHex;
  final FinancialType financialType;
  final String? parentId;
  final bool isSystem;
  final bool isSwile;
  final bool isFixed;

  bool get isCustom => !isSystem;
  bool get isTopLevel => parentId == null;

  /// Backward compatibility with old 'HOUSING' enum string
  static CategoryRef fromLegacyDbValue(String dbValue, List<CategoryRef> all) {
    return all.firstWhere(
      (c) => c.slug.toUpperCase() == dbValue,
      orElse: () => CategoryRef.uncategorized(),
    );
  }
}

enum FinancialType { need, want, investment, income, transfer }
```

## 3.4 Gradual Migration from Current System

**Step 1 (no breaking changes)**: Create new `categories` table with all slugs matching current enum `dbValue` values. Keep the enum in parallel.

**Step 2**: Add `category_id UUID` (nullable) to `expenses` table in Supabase. Run backfill job mapping `category` string to corresponding UUID.

**Step 3**: Write `CategoryResolver` that receives a `String` (legacy) or `UUID` and always returns a valid `CategoryRef`. Never throws an exception.

**Step 4**: Replace all enum usages in UI with `CategoryRef`. Remove the enum.

**Step 5**: Make `category_id` NOT NULL. Deprecate the `category` (string) field.

---

# 4. ENVELOPE BUDGETING ENGINE

## 4.1 Conceptual Model

YNAB invented envelopes. Farol must improve them for Brazil. The key difference: in Brazil you have Swile (separate bucket), credit card installments (known future obligations), 13th salary (predictable but irregular income), and monthly cashflow that often crosses periods (cutoffDay ≠ 1).

An **envelope** in Farol is the budget for a category in a period, with full state:

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

## 4.2 DB Schema for Envelopes

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

## 4.3 Engine Mathematical Logic

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

## 4.4 Critical Edge Cases

**Negative envelope**: If `rolloverPolicy = rolloverNegative` and the user spent R$200 with a R$150 envelope, the next period starts at -R$50. The UI must show this clearly — "You owe R$50 from January".

**Installment envelope**: Each active installment plan automatically generates an `obligation` type envelope in each future period. That is, if you have 6x R$500 for a TV, Farol creates locked R$500 envelopes for the next 6 periods. They are not editable by the user.

**Investment envelope**: Treated as an expense in cashflow (reduces liquid balance) but marked as `financial_type: investment`. Forecasting separates it from current spending.

**Partial income**: If salary has not arrived yet (mid-period), the engine works with projected income, not actual. The `isProjected: true` field on Income indicates this.

---

# 5. RECURRING SYSTEM

## 5.1 Why `isFixed + copy` Does Not Scale

The current `fixedExpensePropagationProvider` mechanism copies last month's expenses with `isFixed = true`. Problems:

- The amount can vary (rent increased R$100 in March)
- Users can have recurring expenses starting on a future date
- There is no way to pause one without deleting it
- No support for non-monthly frequencies (annual seasonal rent, semi-annual insurance)
- Does not automatically detect recurring patterns

## 5.2 Recurring Model

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

### Occurrence Generation

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

## 5.3 Automatic Recurring Detection

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

## 5.4 Recommended UX for Recurring

The UI flow should be: when a candidate is detected, show a non-invasive card on the dashboard: *"Looks like you pay Netflix every month (~R$45). Would you like Farol to track it automatically?"* → [Confirm] [Edit] [Ignore]. If confirmed, the engine creates the `RecurringRule` and retroactively marks past occurrences as `paid`. Do not interrupt the expense entry flow with questions.

---

# 6. INSTALLMENTS INTEGRATION

## 6.1 The Real Problem (from the code)

`CardInstallment` and `Expense` are completely independent entities. `Expense.installmentPlanId` exists but `CardInstallments` has no reference to expenses. The current flow:

1. User records a R$1200 expense in 12 installments → creates an `Expense` for R$100 in the current month
2. Separately creates a `CardInstallment` with `numInstallments=12, monthlyAmount=100`
3. Each month, *manually* calls `advance()` to increment the counter
4. Future months do not have the expense recorded until the user advances them

This is fundamentally incorrect for forecasting. If you buy a TV in 12 installments, the engine must know you have R$100/month committed for 12 months.

## 6.2 Correct Model: InstallmentPlan + Payments

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

### Complete Installment Purchase Flow

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

### Forecasting Impact

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

## 7.1 Predictive Engine Philosophy

Farol's Forecasting Engine is not an AI chatbot. It is a deterministic mathematical engine with statistical heuristics. It must give concrete answers to concrete questions. When the user asks "how much will I save this month?", Farol does not say "it depends on your habits." It says "**R$847** based on your current spending velocity and confirmed obligations for the next 18 days."

## 7.2 The 7 Core Forecasting Metrics

### Metric 1: Burn Rate

**Definition**: Rate of consumption of available budget.

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

### Metric 2: Projected Closing Balance

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

### Metric 3: Days Until Empty (DUE)

**The most emotionally impactful metric.** If the user sees "8 days of cash left" → immediate action.

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

### Metric 4: Budget Risk Score (BRS)

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

### Metric 5: Category Velocity

Detects which categories are "out of control" based on their history.

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

### Metric 6: Savings Prediction

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

### Metric 7: Liquidity Risk

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

## 7.3 ForecastingEngine Architecture

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

## 7.4 Incremental Calculations and Performance

Forecasting is NOT recalculated on every widget rebuild. The strategy:

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

**Layered calculation strategy**:
- **Layer 1 (instant)**: Current balance = DB data, no calculation
- **Layer 2 (<50ms)**: BurnRate = simple division
- **Layer 3 (<200ms)**: Projected balance = burnrate + obligations (simple query)
- **Layer 4 (<500ms)**: Category velocities = comparison with history
- **Layer 5 (<1s)**: Full 90-day cashflow forecast = iterative calculation

The UI shows Layer 1-2 immediately and reveals layers progressively with skeleton loaders.

---

# 8. BUDGET INTELLIGENCE LAYER

## 8.1 The Co-pilot Farol Needs

You don't want a generic chatbot that answers questions. You want a co-pilot that observes, detects, and warns *before* the problem occurs. The intelligence is not artificial in the ML sense — it is a set of expert rules with contextual scoring.

## 8.2 Insight Types

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

## 8.3 Intelligence Engine Rules

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

## 8.4 UX of Insights: Non-Invasive

Insights are **not push notifications** on app launch. They are a contextual panel on the dashboard that appears when something relevant is detected. Rules:

- Maximum 1 `critical` insight visible at a time
- `achievement` insights are only shown if the user is on the Health tab
- The user can silence an insight type for 30 days
- Insights expire: yesterday's "negative balance risk" is not relevant today
- Never show more than 5 insights in a list (the 6th is hidden behind "View all")

---

# 9. SYNCHRONIZATION ARCHITECTURE

## 9.1 The Right Principle for Farol

Farol is not Notion or Obsidian. It does not need extreme bidirectional offline-first sync. The typical Farol user (Brazilian CLT worker) uses the app with connectivity 95% of the time. What they need:

- **Fast data entry without waiting for the network** (optimistic updates)
- **No data loss if the network drops** (persistent queue)
- **No duplicate data** (idempotency)
- **Immediate sync on reconnect** (automatic retry)

## 9.2 Strategy: Optimistic + Queue

```dart
class SyncManager {
  final OperationQueue _queue;
  final SupabaseClient _supabase;
  final ConnectivityMonitor _connectivity;

  /// Registers an operation. If online → executes immediately.
  /// If offline → enqueues for retry.
  Future<void> execute(SyncOperation op) async {
    // 1. Apply immediately to local state (optimistic update)
    await op.applyLocally();

    if (await _connectivity.isOnline) {
      try {
        await op.executeRemote(_supabase);
        await op.markCompleted();
      } catch (e) {
        // If remote fails, enqueue for retry
        await _queue.enqueue(op);
        // Local state is already updated (optimistic)
        // User sees no error except in critical cases
      }
    } else {
      await _queue.enqueue(op);
    }
  }
}

class OperationQueue {
  // Persists the queue in Drift to survive app restarts
  final AppDatabase _db;

  Future<void> enqueue(SyncOperation op) async {
    await _db.insertQueueItem(QueueItemsCompanion(
      operationType: Value(op.type.name),
      payload: Value(jsonEncode(op.toJson())),
      idempotencyKey: Value(op.idempotencyKey), // operation UUID
      retryCount: const Value(0),
      status: Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Process pending queue. Called on reconnect.
  Future<void> processPending() async {
    final pending = await _db.getPendingQueueItems();

    for (final item in pending) {
      try {
        final op = SyncOperation.fromJson(jsonDecode(item.payload));
        await op.executeRemote(_supabase);
        await _db.markQueueItemCompleted(item.id);
      } catch (e) {
        if (item.retryCount >= 3) {
          // After 3 attempts → mark as failed and notify the user
          await _db.markQueueItemFailed(item.id, e.toString());
        } else {
          await _db.incrementRetryCount(item.id);
        }
      }
    }
  }
}
```

## 9.3 Queue Schema (Drift)

```dart
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()(); // 'insert_expense' | 'update_envelope' | etc.
  TextColumn get payload => text()();       // Serialized JSON
  TextColumn get idempotencyKey => text().unique()(); // UUID, prevents duplicates on retry
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}
```

## 9.4 Conflict Resolution

For Farol, conflicts are rare but can happen (two devices from the same user). Strategy: **Last-Write-Wins with timestamp + semantic merge for envelopes**.

```dart
class ConflictResolver {
  /// For transactions: Last-Write-Wins (most recent wins)
  Transaction resolveTransaction(Transaction local, Transaction remote) {
    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }

  /// For envelopes: semantic merge (higher allocated wins,
  /// spent is summed if both have distinct transactions)
  Envelope resolveEnvelope(Envelope local, Envelope remote) {
    // Same updatedAt → no real conflict
    if (local.updatedAt == remote.updatedAt) return local;

    return Envelope(
      id: local.id,
      allocated: Money.max(local.allocated, remote.allocated),
      spent: Money.max(local.spent, remote.spent), // actual value recalculated from transactions
      updatedAt: DateTime.now(),
      // Rest: last-write-wins
    );
  }
}
```

---

# 10. REALISTIC IMPLEMENTATION ROADMAP

## Principle: No Big Bang Rewrite

Each phase has independent product value. The user feels improvement after each phase. Technical debt is reduced incrementally.

---

## PHASE 1: Solid Foundations
**ROI**: Eliminates current bugs, prepares the ground. Without this phase, everything else collapses.

### 1.1 Category system unification
- Create `categories` table in Supabase (with slugs matching the enum dbValues)
- Create `CategoryRef` value object in Dart
- Write `CategoryResolver` that handles string legacy → CategoryRef without exceptions
- Backfill: `category_id UUID` field in `expenses` (nullable first)
- Keep the enum in parallel temporarily
- **Critical test**: `ExpenseCategory.fromDb('CUSTOM_XYZ')` never throws StateError

**Complexity**: Medium | **Risk**: Low (additive changes) | **Dependencies**: None

### 1.2 Migrate Expenses to real dates
- Add `transaction_date DATE` to the `expenses` table (already exists in the Dart model)
- Ensure all period queries use `transaction_date BETWEEN` instead of `month/year`
- The `month/year` field can be kept as an additional index for compatibility
- Update `getExpensesByRange` to use real date range

**Complexity**: Low | **Risk**: Medium (may affect existing queries)

### 1.3 InstallmentPlan + InstallmentPayments
- Create `installment_plans` and `installment_payments` tables in Supabase
- Migrate existing `card_installments`: each record generates a plan with N payments
- Update `InstallmentRepository` to use the new schema
- The installments UI can stay the same — only the backend changes
- Keep old `card_installments` table in read-only mode during transition

**Complexity**: High | **Risk**: Medium | **Dependencies**: Real dates (1.2)

### Phase 1 success metrics
- 0 StateError from unknown category in production
- Installments show future due dates
- Financial periods filter by real date, not month/year

---

## PHASE 2: Central Engine
**ROI**: The product starts to "think" for the user. First real differentiation.

### 2.1 RecurringRule Engine
- Create `recurring_rules` and `recurring_occurrences` tables
- Implement `RecurrenceResolver.generateOccurrences()`
- UI: new "Recurring Expenses" screen (replaces the isFixed copy)
- Migrate existing `isFixed = true` expenses to equivalent `RecurringRule`
- Configure background job to generate next month's occurrences

**Complexity**: High | **Risk**: Medium

### 2.2 EnvelopeEngine with Rollover
- Extend `period_budgets` → `envelopes` with rollover_policy
- Implement `EnvelopeEngine.calculateRollover()`
- UI: badge "Rollover: R$120 from previous period" on budget card
- Implement automatic envelope for installments

**Complexity**: Medium | **Risk**: Low

### 2.3 Unified FinancialSnapshot
- Create `FinancialEngine` that produces `FinancialSnapshot`
- Migrate `DashboardScreen` to consume only the snapshot
- Remove duplicate calculations from individual widgets
- Implement cache with event-based invalidation

**Complexity**: High | **Risk**: High (dashboard refactoring)

### Phase 2 success metrics
- Dashboard loads with a single observable (FinancialSnapshot)
- Recurring items auto-project 3 months forward
- Envelope rollover works correctly across periods

---

## PHASE 3: Real Forecasting
**ROI**: The product's "wow moment". The user sees the future of their finances.

### 3.1 BurnRate + DaysUntilEmpty
- Implement `BurnRate` calculation in `ForecastingEngine`
- UI: new "Financial Velocity" widget on the dashboard
- Show DaysUntilEmpty with traffic light (green/yellow/red)
- Proactive alerts on dashboard when DUE < 14 days

### 3.2 Projected Balance + Cashflow Chart
- Implement `calculateProjectedClosingBalance()`
- UI: Balance projection chart (solid line = actual, dashed line = projected)
- Integrate future installments as points on the chart (visible drops)
- Integrate projected income as points (income events)

### 3.3 Category Velocity + Risk Score (Week 15-16)
- Implement `CategoryVelocity` for all categories
- UI: per-category velocity indicator on the budget screen
- Implement overall `BudgetRiskScore`
- UI: Health Score migrates from static to dynamic/predictive

### Phase 3 success metrics
- The user can answer "how much will I save this month?" by looking at the app
- The cashflow chart correctly shows drops from future installments
- The Risk Score changes in real-time when an expense is recorded

---

## PHASE 4: Intelligence & Polish
**ROI**: Retention. The user who reaches this phase does not abandon the app.

### 4.1 Intelligence Layer
- Implement `IntelligenceLayer` with the 8 core rules
- UI: insights panel on the dashboard (maximum 3 visible)
- Implement dismissal and silencing of insight types
- Implement automatic recurring detection
- UI: suggestion "I noticed you pay Netflix every month — track it?"

### 4.2 Automatic Recurring Detection
- Implement `RecurringDetector.detect()`
- UI: onboarding flow proposing detected recurring items
- Confirmation/rejection system for candidates

### 4.3 Robust Synchronization
- Implement `OperationQueue` in Drift
- Implement `SyncManager` with retry logic
- UI: sync status indicator (discrete, non-invasive)
- Sync tests: offline → record → reconnect → consistent data

### 4.4 Supabase Edge Functions for heavy calculations
- Move cashflow forecast calculation to an Edge Function
- Client only requests the cached result
- Invalidate cache on the server when new transactions arrive

### Phase 4 success metrics
- System detects recurring items with >75% accuracy on real user history
- Insights have dismissal rate < 30% (they are relevant)
- Zero data loss in offline → online scenario

---

## Roadmap Dependencies

```
Phase 1.1 (Categories) ←── Everything else depends on this
     │
     ├──→ Phase 1.2 (Dates) ←── Phase 1.3 (Installments)
     │                                    │
     └──→ Phase 2.1 (Recurring)           │
               │                         │
               └──→ Phase 2.2 (Envelopes)─┘
                         │
                         └──→ Phase 2.3 (FinancialSnapshot)
                                    │
                                    └──→ Phase 3 (Forecasting)
                                               │
                                               └──→ Phase 4 (Intelligence)
```

---

# 11. RISKS AND COMMON MISTAKES

## 11.1 Architectural Mistakes

**Mistake 1: Forecasting as ML from day one**
Many finance apps try to implement machine learning for expense prediction before having enough historical data. A new user has no history. The deterministic mathematical engine (burnrate, obligations, velocity) yields better results with sparse data than any ML model. ML is Phase 5+.

**Mistake 2: Bidirectional sync before having users**
Spending weeks on conflict resolution for a product with a single active user is classic over-engineering. Last-Write-Wins is sufficient for the first 1,000 users.

**Mistake 3: Infinitely nested categories**
Parent/child hierarchy is correct but maximum 2 levels (category → subcategory). 3+ levels create a UX nightmare on mobile and complex JOIN queries. YNAB has 0 nesting. Farol can have 2.

**Mistake 4: Ultra-granular envelopes**
Don't make an envelope per subcategory. One envelope per root category is sufficient. Excessive granularity creates cognitive overload. The average YNAB user has 15-20 envelopes, not 50.

**Mistake 5: Invalidating the forecast cache on every tick**
If the ForecastingEngine recalculates every time the Riverpod timer fires, CPU usage on mobile is unacceptable. The TTL cache must be at least 5 minutes, with invalidation only on real events (new transaction, new recurring item).

## 11.2 UX Risks

**Risk: Too many simultaneous insights**
If the user sees 8 insights when opening the app, they learn to ignore all of them. Maximum 3 on screen, with strict priority. Less is more.

**Risk: Forecast causes anxiety**
"You have 8 days of cash left" is useful. "Solvency projection: 8.2 days with 73% confidence interval" is terrifying and useless. The language must be human and actionable, not statistical.

**Risk: Confusing rollover**
YNAB users take weeks to understand rollover. The UI must explain it with concrete examples: "R$120 leftover from Entertainment in January → added to your Entertainment budget in February". Never show numbers without context.

**Risk: Installment vs expense**
If a purchase paid in installments generates both an `Expense` and an `InstallmentPayment`, the user may see the amount duplicated. The UI must be explicit: "This expense is part of the 'iPhone 15 - 12x' plan. Installment 1 of 12."

## 11.3 Performance Risks

**Risk: Forecasting queries without indexes**
The cashflow forecast queries all future transactions. Without an index on `due_date` + `user_id`, this is a full table scan. Add a composite index `(user_id, due_date, status)` on `installment_payments` and `recurring_occurrences`.

**Risk: Materializing too early**
Materialized views in Supabase are useful but add operational complexity (they need refresh). Start with regular queries and materialize only what is provably slow with real users.

**Risk: Supabase Realtime for everything**
Supabase Realtime consumes WebSocket connections. Forecasting does not need millisecond-level realtime — polling every 30 seconds or write-event invalidation is sufficient.

## 11.4 Common Finance App Mistakes

1. **YNAB-copy without adaptation**: The YNAB model is for stable economies with fixed monthly income. Brazil has: 13th salary (January vs December), Swile (separate bucket), FGTS (non-liquid), installment culture. Copying YNAB literally is a mistake.

2. **Categories in English for a Latin American market**: "Leisure" has no cultural meaning for a Brazilian. "Lazer", "Alimentação", "Moradia" do.

3. **Ignoring the cutoff period**: Most apps use the calendar month. Farol's `cutoffDay` is a real competitive advantage — most Brazilians receive their salary between the 5th and the 15th, not the 1st.

4. **Health Score without predictivity**: A score showing "your current situation" does not generate engagement. A score showing "how you'll end the period if you keep this up" does.

5. **Forcing budgeting from day one**: New users have no history. Onboarding should start with pure tracking (no budget) and suggest budgeting after 30 days of data.

---

# 12. EXPECTED FINAL RESULT

## 12.1 How should Farol feel after this evolution?

The user opens Farol in the morning before going to work. In 3 seconds, without reading anything, they know:
- **Green / Yellow / Red**: their financial situation for the period
- **One key number**: "You have R$1,240 left in budget"
- **A specific alert if something is urgent**: "You have 3 installments this week: R$580"

At the end of the period, without the user doing anything, Farol:
- Closes the envelopes, calculates the rollover
- Generates the recurring items for the next period
- Tells them how much they can invest this month

After 6 months of use, Farol knows the user's spending profile better than they do and can say: "Historically, you spend R$400 more in December on gifts. Your December budget already includes that adjustment."

## 12.2 Why it wins against the competition

| Dimension | YNAB | Copilot | Monarch | Mobills | **Farol** |
|---|---|---|---|---|---|---|
| Customizable cutoff period | ❌ | ❌ | ❌ | ❌ | ✅ |
| Brazil context (Swile, FGTS, 13th salary) | ❌ | ❌ | ❌ | Partial | ✅ |
| Predictive forecasting | Basic | ✅ | Basic | ❌ | ✅ |
| Installments integrated with cashflow | ❌ | Partial | Partial | ✅ | ✅ |
| Affordable price for LATAM | ❌ ($15/mo) | ❌ ($13/mo) | ❌ ($10/mo) | Freemium | ✅ |
| Real offline-first | ❌ | ❌ | ❌ | ❌ | ✅ (Drift) |
| Recurring with RRULE | ✅ | Basic | Basic | Basic | ✅ |
| Predictive Health Score | ❌ | Basic | ❌ | ❌ | ✅ |

## 12.3 The Real Competitive Advantage

**Farol has something no Western app can easily copy: it understands the financial reality of the Brazilian CLT worker.**

The cutoffDay = 10 because salary arrives on the 10th. Swile is a separate bucket because the benefit is not money, it's credit. The 13th salary is not a bonus, it's planned. Installments on a credit card are not debt, they're how you buy in Brazil.

This cultural understanding, integrated into the financial engine from the architecture, not in the UI, is the competitive advantage. It's not a feature. It's the correct mental model.

## 12.4 Vision: Farol as SaaS

With the Financial Engine decoupled from Flutter:
- **Farol API**: expose the engine as a REST API → Open Finance integrations
- **Farol Web**: same engine, React UI
- **Multi-account**: the engine handles N users without architecture changes
- **Multi-currency**: the `Money` Value Object can already have `currencyCode`
- **Contextual AI**: rule-based insights enriched with LLM (embeddings on financial history, natural language questions)
- **Family**: a single `userId` can have multiple `FinancialProfile` (me, my spouse, joint account)

The Predictive Financial Engine is not version 2.0 of Farol. It is the foundation upon which the definitive product is built.

---

## APPENDIX: Phase-by-Phase Implementation Checklist

### Phase 1 ✅ Foundations
- [ ] Create `categories` table in Supabase with all system slugs
- [ ] Implement `CategoryRef` value object
- [ ] Implement `CategoryResolver` (string → CategoryRef, never throws)
- [ ] Backfill `category_id` in `expenses`
- [ ] Create `installment_plans` + `installment_payments` tables
- [ ] Migrate `card_installments` → new schema
- [ ] Add real `transaction_date` to expenses (all flows)
- [ ] Tests: period filter uses real date, not month/year

### Phase 2 ✅ Central Engine
- [ ] Create `recurring_rules` + `recurring_occurrences` tables
- [ ] Implement `RecurrenceResolver.generateOccurrences()`
- [ ] UI: Recurring screen
- [ ] Migrate `isFixed` expenses → `RecurringRule`
- [ ] Implement `EnvelopeEngine` with rollover
- [ ] Implement `FinancialEngine` → `FinancialSnapshot`
- [ ] Refactor Dashboard to consume only `FinancialSnapshot`

### Phase 3 ✅ Forecasting
- [ ] Implement `BurnRate` + `DaysUntilEmpty`
- [ ] Implement `ProjectedClosingBalance`
- [ ] Implement `CashflowForecast` (90 days)
- [ ] UI: financial velocity widget
- [ ] UI: projected cashflow chart
- [ ] Implement `CategoryVelocity`
- [ ] Implement dynamic `BudgetRiskScore`

### Phase 4 ✅ Intelligence
- [ ] Implement `IntelligenceLayer` with 8 rules
- [ ] UI: insights panel on dashboard
- [ ] Implement `RecurringDetector`
- [ ] UI: automatic recurring suggestions
- [ ] Implement `OperationQueue` in Drift
- [ ] Implement `SyncManager` with retry
- [ ] Offline → online sync tests

---

*Documento generado en Mayo 2026 · Farol Predictive Financial Engine v1.0*
*Basado en análisis del código fuente real del repositorio Farol*
