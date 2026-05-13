# Farol

[![CI](https://github.com/luigrocha/farol/actions/workflows/test.yml/badge.svg)](https://github.com/luigrocha/farol/actions/workflows/test.yml)

**Predictive personal finance for Brazilian CLT workers.** Offline-first, realtime-collaborative, with a deterministic forecasting engine that understands Swile, FGTS, 13th salary, and your cutoff day.

---

## Table of Contents

- [Features](#features)
- [Screens](#screens)
- [Architecture Overview](#architecture-overview)
- [Class Diagrams](#class-diagrams)
  - [Domain Entities](#domain-entities)
  - [Domain Services](#domain-services)
  - [Value Objects](#value-objects)
  - [Repository Layer](#repository-layer)
  - [Sync Infrastructure](#sync-infrastructure)
  - [Workspace & Collaboration](#workspace--collaboration)
- [Database Schema](#database-schema)
  - [Supabase (Remote)](#supabase-remote)
  - [Drift (Local SQLite)](#drift-local-sqlite)
- [Sequence Diagrams](#sequence-diagrams)
  - [App Startup](#app-startup)
  - [Add Expense (Offline-first)](#add-expense-offline-first)
  - [Create Installment Purchase](#create-installment-purchase)
  - [Financial Snapshot Computation](#financial-snapshot-computation)
  - [Workspace Invite & Accept](#workspace-invite--accept)
  - [Realtime Activity Feed](#realtime-activity-feed)
- [Stack](#stack)
- [Business Logic](#business-logic)
- [Setup](#setup)
- [Testing & Quality](#testing--quality)
- [License](#license)

---

## Features

- **Predictive Engine** — Burn rate, days until empty, projected closing balance, and cashflow forecast
- **CLT-native** — Customizable `cutoffDay`, Swile as a separate bucket, FGTS auto-projection, 13th salary simulator with INSS + IRRF 2025 progressive tables
- **Offline-first + Sync** — Drift SQLite local-first, optimistic updates, persistent operation queue, idempotent retry
- **Multi-user Workspaces** — Shared spending with role-based access, attribution, activity feed, and realtime presence
- **Budget with Envelopes** — Per-category targets with 4-level alerts, rollover between periods
- **Recurring Rules** — RRULE-based engine, auto-generates occurrences 3 months ahead, detects patterns in history
- **Intelligence Layer** — 12 deterministic insight rules (no ML), dismiss tracking and stats
- **Installment Plans** — Full lifecycle: create, track payments, integrate with cashflow forecast
- **31 test files, 0 lint warnings** — Unit, widget, sync, and integration tests enforced by CI

---

## Screens

| Screen | What it does |
|---|---|
| **Dashboard** | Net worth KPIs, health score (0–10), burn rate, contribution bar (shared workspaces), expense breakdown, activity feed preview |
| **Transactions** | Full expense/income/installment history with filters, date range, search. Member attribution in shared workspaces |
| **Analytics** | Cashflow forecast chart (actual + projected), revenue/expense trends, category distribution, monthly comparison |
| **Budget** | Period envelopes with progress bars, rollover badge, last-edit attribution, 4-level alerts |
| **Recurring** | Recurring rules with occurrence calendar, auto-detection suggestions |
| **Installments** | Active installment plans with payment schedule and cashflow impact |
| **Activity** | Day-grouped feed with infinite scroll, pull-to-refresh, realtime updates |
| **Workspace** | Switcher, create/invite members, manage roles, transfer ownership |
| **Settings** | Profile, salary config (gross/net/Swile), budget goals, 13th simulator, export, theme |
| **Investments** | Portfolio positions (Treasury, CDB, REIT), allocation insights |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                           │
│          Flutter Screens + Widgets  ←→  Riverpod Providers          │
└────────────────────────────┬────────────────────────────────────────┘
                             │ reads / watches
┌────────────────────────────▼────────────────────────────────────────┐
│                         DOMAIN LAYER                                │
│   FinancialEngine · ForecastingEngine · EnvelopeEngine              │
│   IntelligenceLayer · InstallmentService · RecurringService         │
│   ObligationEngine · RecurrenceResolver · RecurringDetector         │
│                  (pure Dart — no I/O)                               │
└──────────────┬───────────────────────────┬──────────────────────────┘
               │ calls                     │ reads
┌──────────────▼──────────┐   ┌────────────▼──────────────────────────┐
│     REPOSITORIES        │   │           INFRASTRUCTURE              │
│  21 repos (Supabase     │   │  SyncManager · OperationQueue         │
│  + workspace_id filter) │   │  ConflictResolver · Drift DAOs        │
└──────────────┬──────────┘   └────────────┬──────────────────────────┘
               │                           │
┌──────────────▼──────────┐   ┌────────────▼──────────────────────────┐
│     SUPABASE REMOTE     │   │      DRIFT LOCAL (SQLite)             │
│  36 migrations · RLS    │   │  8 tables · OperationQueue            │
│  Edge Functions         │   │  UserSettings · CategoryCache         │
│  Realtime channels      │   │  ForecastCache                        │
└─────────────────────────┘   └───────────────────────────────────────┘
```

```
lib/
├── core/
│   ├── domain/              # Pure Dart — entities, services, value objects
│   │   ├── entities/        FinancialSnapshot, Envelope, BurnRate, LiquidityRisk,
│   │   │                    InstallmentPlan/Payment, RecurringRule/Occurrence,
│   │   │                    FinancialInsight, FinancialProjection, WorkspaceActivity
│   │   ├── services/        FinancialEngine, ForecastingEngine, EnvelopeEngine,
│   │   │                    ObligationEngine, IntelligenceLayer, InstallmentService,
│   │   │                    RecurringService, RecurrenceResolver, RecurringDetector
│   │   └── value_objects/   Money (cents-based), CategoryRef, MemberDisplay
│   ├── repositories/        21 repositories — Supabase + workspace scoping
│   ├── providers/           providers.dart — 40+ Riverpod autoDispose providers
│   │                        workspace_providers.dart — 13 workspace/collab providers
│   ├── database/            Drift schema (SQLite), DAOs, migrations
│   ├── infrastructure/sync/ SyncManager, OperationQueue, ConflictResolver
│   ├── models/              Expense, Income, Account, Category, Workspace, etc.
│   ├── services/            WorkspaceRealtimeService, ExportService
│   └── widgets/             FeatureGate, MemberChip, WorkspaceAppBarChip, ActivityFeedTile
├── features/
│   ├── dashboard/           KPIs, health gauge, burn rate, contribution bar, insights
│   ├── transactions/        List, filters, quick-add, edit/delete
│   ├── analytics/           Cashflow chart, trends, distribution, velocity
│   ├── budget/              Period envelopes, budget edit sheet, progress bars
│   ├── recurring/           Rules list, occurrence calendar, suggestions
│   ├── installments/        Plans list, payment schedule
│   ├── activity/            Activity feed screen, infinite scroll
│   ├── workspace/           Switcher, create, invite, members management
│   ├── auth/                Login, signup, session management
│   └── settings/            Profile, salary, goals, 13th simulator, export
└── main.dart                Entry point, MainShell with responsive NavigationRail
```

---

## Class Diagrams

### Domain Entities

```mermaid
classDiagram
    class Money {
        -int _cents
        +double amount
        +int cents
        +bool isZero
        +bool isPositive
        +bool isNegative
        +String formatted
        +Money.zero()$
        +Money.fromDouble(double)$
        +Money.fromCents(int)$
        +Money operator+(Money)
        +Money operator-(Money)
        +Money operator*(double)
    }

    class CategoryRef {
        +String id
        +String slug
        +String name
        +String emoji
        +String? colorHex
        +String financialType
        +String? parentId
        +bool isSystem
        +bool isSwile
        +bool isFixed
        +bool isCustom
        +CategoryRef.fromCategory()$
        +CategoryRef.uncategorized()$
    }

    class FinancialSnapshot {
        +FinancialPeriod period
        +DateTime generatedAt
        +Money totalIncome
        +Money cashIncome
        +Money swileIncome
        +Money totalSpent
        +Money cashSpent
        +Money swileSpent
        +Money currentBalance
        +Money swileBalance
        +List~Envelope~ envelopes
        +int healthScore
        +double savingsRate
        +List~ScheduledPayment~ upcomingPayments
        +Money totalFutureObligations
        +FinancialProjection? projection
        +bool isPositive
        +Money remainingCash
        +Color healthColor
    }

    class Envelope {
        +CategoryRef category
        +Money allocated
        +Money spent
        +RolloverPolicy rolloverPolicy
        +Money rolloverAmount
        +Money remaining
        +Money effectiveAllocated
        +EnvelopeStatus status
        +double usagePercent
    }

    class BurnRate {
        +Money totalSpent
        +int daysElapsed
        +int daysRemaining
        +Money totalAllocated
        +Money dailyRate
        +Money projectedTotalSpend
        +double paceVsBudget
        +BurnPace pace
    }

    class LiquidityRisk {
        +LiquidityRiskLevel level
        +Money obligationsNext7Days
        +Money currentBalance
        +int daysUntilEmpty
        +List~ScheduledPayment~ upcomingObligations
        +bool isAtRisk
    }

    class FinancialProjection {
        +BurnRate burnRate
        +Money projectedClosingBalance
        +LiquidityRisk liquidityRisk
        +CashflowForecast? cashflowForecast
        +bool isProjectedNegative
    }

    class CashflowForecast {
        +List~CashflowDataPoint~ points
        +DateTime generatedAt
        +bool isEmpty
        +Money minBalance
        +bool goesNegative
    }

    class CashflowDataPoint {
        +DateTime date
        +double balance
        +bool hasObligation
        +double dailyExpense
        +double dailyIncome
        +bool isReal
    }

    class FinancialInsight {
        +String id
        +InsightType type
        +InsightPriority priority
        +String title
        +String body
        +String? actionLabel
        +String? actionRoute
        +double confidence
        +Map~String,dynamic~ data
        +DateTime generatedAt
        +DateTime? expiresAt
        +bool isDismissable
        +bool isExpired()
    }

    class InstallmentPlan {
        +String id
        +String userId
        +String? categoryId
        +String description
        +double totalAmount
        +int numInstallments
        +double installmentAmount
        +String paymentMethod
        +DateTime firstDueDate
        +String status
        +String? authorUserId
        +int paidCount
        +bool isActive
        +bool isComplete
        +int remainingPayments
        +double remainingAmount
        +double progressPercent
        +DateTime dueDateFor(int num)
    }

    class InstallmentPayment {
        +String id
        +String planId
        +int installmentNum
        +DateTime dueDate
        +double amount
        +String status
        +DateTime? paidDate
        +bool isPending
        +bool isPaid
        +bool isOverdue
        +int daysUntilDue
    }

    class RecurringRule {
        +String id
        +String name
        +double baseAmount
        +AmountType amountType
        +RecurringFrequency frequency
        +int intervalCount
        +int? dayOfMonth
        +DateTime startsOn
        +DateTime? endsOn
        +RecurringStatus status
        +String? authorUserId
        +bool isActiveOn(DateTime)
    }

    class RecurringOccurrence {
        +String id
        +String ruleId
        +DateTime scheduledDate
        +double expectedAmount
        +OccurrenceStatus status
        +DateTime? paidDate
        +int? expenseId
        +bool isPending
        +bool isPaid
        +bool isOverdue
    }

    class ScheduledPayment {
        +String id
        +String description
        +Money amount
        +DateTime dueDate
        +ScheduledPaymentType type
        +int daysFromNow
        +bool isOverdue
        +bool isDueThisWeek
    }

    class WorkspaceActivity {
        +String id
        +String workspaceId
        +String userId
        +String action
        +String entityType
        +String? entityLabel
        +double? amount
        +DateTime createdAt
        +bool isAddedExpense()
        +bool isDeletedExpense()
        +String actionLabel(bool isSelf)
    }

    FinancialSnapshot "1" --> "1" FinancialProjection
    FinancialSnapshot "1" --> "*" Envelope
    FinancialSnapshot "1" --> "*" ScheduledPayment
    FinancialProjection "1" --> "1" BurnRate
    FinancialProjection "1" --> "1" LiquidityRisk
    FinancialProjection "1" --> "0..1" CashflowForecast
    CashflowForecast "1" --> "*" CashflowDataPoint
    LiquidityRisk "1" --> "*" ScheduledPayment
    Envelope "1" --> "1" CategoryRef
    InstallmentPlan "1" --> "*" InstallmentPayment
    RecurringRule "1" --> "*" RecurringOccurrence
```

### Domain Services

```mermaid
classDiagram
    class FinancialEngine {
        +FinancialSnapshot buildSnapshot(period, incomes, expenses, netSalaryOverride, swileOverride, emergencyFund, activePlans, envelopes, totalAllocated)
    }

    class ForecastingEngine {
        +FinancialProjection buildProjection(period, totalSpent, totalAllocated, currentBalance, projectedIncome, obligations, expenseHistory, buildForecastChart)
    }

    class EnvelopeEngine {
        +List~Envelope~ buildEnvelopes(entries, categoriesBySlug, previousExpenses, previousPeriod)
        +Money totalAllocated(envelopes)
        +Money totalSpent(envelopes)
    }

    class ObligationEngine {
        +List~ScheduledPayment~ buildObligations(pendingInstallments, pendingOccurrences)
        +int daysUntilEmpty(balance, dailyRate, obligations)
    }

    class IntelligenceLayer {
        +int maxVisible$
        +double minConfidence$
        +List~FinancialInsight~ analyze(snapshot, projection, recentExpenses, allExpenses, dismissedIds, consecutiveUnderBudgetPeriods, previousInstallmentTotal)
    }

    class InstallmentService {
        -InstallmentPlanRepository _planRepo
        -InstallmentPaymentRepository _paymentRepo
        -ExpenseRepository _expenseRepo
        +Future~InstallmentPlan~ createPurchase(description, purchaseDate, totalAmount, numInstallments, paymentMethod, firstDueDate, categorySlug, cutoffDay)
        +Future~InstallmentPayment~ payInstallment(payment, paidDate, paidAmount, expenseId)
        +Future~InstallmentPayment~ skipInstallment(payment)
    }

    class RecurringService {
        -RecurringRulesRepository _rulesRepo
        -RecurringOccurrencesRepository _occurrencesRepo
        -ExpenseRepository _expenseRepo
        -RecurrenceResolver _resolver
        +Future~RecurringRule~ createRule(rule)
        +Future~RecurringRule~ updateRule(id, rule)
        +Future~void~ pauseRule(id, until)
        +Future~void~ cancelRule(id)
        +Future~void~ deleteRule(id)
        +Future~RecurringOccurrence~ payOccurrence(occurrence, paidDate, actualAmount, expenseId)
        +Future~RecurringOccurrence~ skipOccurrence(occurrence, notes)
        +Future~int~ generateUpcomingOccurrences(monthsAhead)
    }

    class RecurrenceResolver {
        +List~RecurringOccurrence~ generateOccurrences(rule, rangeStart, rangeEnd)
    }

    class RecurringDetector {
        +List~RecurringRuleCandidate~ detect(history, existingRuleNames)
    }

    class CategoryResolver {
        +void updateCache(List~CategoryRef~)
        +CategoryRef resolve(String rawValue)
        +bool isLoaded
    }

    InstallmentService --> InstallmentPlanRepository
    InstallmentService --> InstallmentPaymentRepository
    InstallmentService --> ExpenseRepository
    RecurringService --> RecurringRulesRepository
    RecurringService --> RecurringOccurrencesRepository
    RecurringService --> ExpenseRepository
    RecurringService --> RecurrenceResolver
    FinancialEngine --> FinancialSnapshot
    ForecastingEngine --> FinancialProjection
    ForecastingEngine --> BurnRate
    ForecastingEngine --> LiquidityRisk
    ForecastingEngine --> ObligationEngine
    EnvelopeEngine --> Envelope
    IntelligenceLayer --> FinancialInsight
```

### Value Objects

```mermaid
classDiagram
    class Money {
        -int _cents
        +double amount
        +int cents
        +bool isZero
        +bool isPositive
        +bool isNegative
        +String formatted
        +Money zero()$
        +Money fromDouble(double amount)$
        +Money fromCents(int cents)$
        +Money operator+(Money other)
        +Money operator-(Money other)
        +Money operator*(double factor)
        +Money operator-()
        +bool operator>(Money)
        +bool operator<(Money)
    }

    class CategoryRef {
        +String id
        +String slug
        +String name
        +String emoji
        +String? colorHex
        +String financialType
        +String? parentId
        +bool isSystem
        +bool isSwile
        +bool isFixed
        +bool isCustom
        +CategoryRef fromCategory(Category)$
        +CategoryRef uncategorized(String slug)$
        +CategoryRef fromLegacyString(String)$
    }

    class MemberDisplay {
        +String userId
        +String displayName
        +String? email
        +String? photoUrl
        +Color avatarColor
        +bool isSelf
        +Color avatarColorForUserId(String userId)$
    }

    class FinancialPeriod {
        +DateTime start
        +DateTime end
        +FinancialPeriod current(int cutoffDay)$
        +bool contains(DateTime date)
    }
```

### Repository Layer

```mermaid
classDiagram
    class ExpenseRepository {
        -SupabaseClient _supabase
        -String? workspaceId
        +Stream~List~Expense~~ watchPeriod(period)
        +Future~Expense~ insert(transactionDate, category, amount, paymentMethod, ...)
        +Future~void~ update(id, fields)
        +Future~void~ delete(id)
        +Future~List~Expense~~ fetchRange(start, end)
    }

    class InstallmentPlanRepository {
        -SupabaseClient _supabase
        -String? workspaceId
        +Future~List~InstallmentPlan~~ getActive()
        +Future~InstallmentPlan~ create(plan)
        +Future~void~ updateStatus(id, status)
        +Future~void~ delete(id)
    }

    class InstallmentPaymentRepository {
        -SupabaseClient _supabase
        +Future~List~InstallmentPayment~~ getByPlan(planId)
        +Future~List~InstallmentPayment~~ insertAll(payments)
        +Future~InstallmentPayment~ markPaid(id, paidDate, paidAmount)
        +Future~InstallmentPayment~ markSkipped(id)
    }

    class RecurringRulesRepository {
        -SupabaseClient _supabase
        -String? workspaceId
        +Future~List~RecurringRule~~ getActive()
        +Future~RecurringRule~ create(rule)
        +Future~RecurringRule~ update(id, rule)
        +Future~void~ updateStatus(id, status)
        +Future~void~ delete(id)
    }

    class RecurringOccurrencesRepository {
        -SupabaseClient _supabase
        +Future~List~RecurringOccurrence~~ getPending(before)
        +Future~void~ upsertOccurrences(occurrences)
        +Future~RecurringOccurrence~ markPaid(id, paidDate, actualAmount)
        +Future~RecurringOccurrence~ markSkipped(id, notes)
    }

    class WorkspaceRepository {
        -SupabaseClient _supabase
        +Future~List~Workspace~~ getUserWorkspaces()
        +Future~Workspace~ create(name, type, emoji, color)
        +Future~Workspace~ update(id, fields)
        +Future~void~ updateIdentity(id, emoji, color, name)
        +Future~void~ inviteMember(workspaceId, email, role)
        +Future~void~ removeMember(workspaceId, userId)
        +Future~void~ delete(id)
    }

    class WorkspaceActivityRepository {
        -SupabaseClient _supabase
        -String? workspaceId
        +Future~List~WorkspaceActivity~~ fetchLatest(limit)
        +Future~List~WorkspaceActivity~~ fetchPage(cursor, limit)
    }

    class CategoryRepository {
        -SupabaseClient _supabase
        -String? workspaceId
        +Stream~List~Category~~ watchAll()
        +Future~List~Category~~ getAll()
        +Future~Category~ insert(category)
        +Future~void~ update(id, fields)
        +Future~void~ delete(id)
        +Future~void~ bulkInsert(categories)
    }

    class ForecastCacheRepository {
        -AppDatabase _db
        +Future~CashflowForecast?~ get(periodKey)
        +Future~void~ put(periodKey, forecast)
        +Future~void~ invalidate(periodKey)
    }

    class DismissedInsightsRepository {
        -AppDatabase _db
        +Future~Set~String~~ getDismissed()
        +Future~void~ dismiss(id, type)
        +Future~void~ undismiss(id)
        +Future~List~InsightStats~~ getStats()
    }

    ExpenseRepository --> Expense
    InstallmentPlanRepository --> InstallmentPlan
    InstallmentPaymentRepository --> InstallmentPayment
    RecurringRulesRepository --> RecurringRule
    RecurringOccurrencesRepository --> RecurringOccurrence
    WorkspaceActivityRepository --> WorkspaceActivity
```

### Sync Infrastructure

```mermaid
classDiagram
    class SyncManager {
        -OperationQueue _queue
        -SupabaseClient _supabase
        -StreamController _statusCtrl
        +Stream~SyncStatus~ statusStream
        +SyncStatus currentStatus
        +Future~void~ execute(SyncOperation op)
        +Future~void~ processPendingQueue()
        -Future~void~ _startConnectivityMonitor()
    }

    class OperationQueue {
        -AppDatabase _db
        +int maxRetries$
        +int maxQueueSize$
        +Future~void~ enqueue(operation)
        +Future~List~SyncQueueItem~~ getPending()
        +Future~void~ markCompleted(id)
        +Future~void~ markFailed(id, error)
        +Future~int~ pendingCount()
        +bool hasFailedItems
    }

    class SyncOperation {
        <<abstract>>
        +String operationType
        +String payloadJson
        +String idempotencyKey
        +Future~void~ applyLocally()
        +Future~void~ executeRemote(SupabaseClient)
    }

    class ConflictResolver {
        +T resolve(local, remote, strategy)$
    }

    class SyncStatus {
        +SyncState state
        +int pendingCount
        +bool hasFailedOps
        +DateTime? lastSyncAt
        +bool isOnline
    }

    class SyncQueueItem {
        +int id
        +String operationType
        +String payload
        +String idempotencyKey
        +int retryCount
        +String status
        +String? error
        +DateTime createdAt
    }

    SyncManager --> OperationQueue
    SyncManager --> ConflictResolver
    SyncManager --> SyncStatus
    OperationQueue --> SyncQueueItem
    SyncOperation <|-- ExpenseInsertOperation
    SyncOperation <|-- ExpenseDeleteOperation
    SyncOperation <|-- RecurringRuleOperation
```

### Workspace & Collaboration

```mermaid
classDiagram
    class Workspace {
        +String id
        +String name
        +String slug
        +String ownerId
        +WorkspaceType type
        +WorkspacePlan plan
        +DateTime? planExpiresAt
        +String? emoji
        +String? color
        +String? description
        +List~WorkspaceMember~ members
        +DateTime createdAt
    }

    class WorkspaceMember {
        +String id
        +String workspaceId
        +String userId
        +WorkspaceRole role
        +String? invitedBy
        +DateTime joinedAt
    }

    class WorkspaceInvite {
        +String id
        +String workspaceId
        +String email
        +WorkspaceRole role
        +String token
        +DateTime expiresAt
        +DateTime? acceptedAt
    }

    class MemberDisplay {
        +String userId
        +String displayName
        +String? email
        +String? photoUrl
        +Color avatarColor
        +bool isSelf
    }

    class WorkspaceRealtimeService {
        -SupabaseClient _supabase
        -RealtimeChannel? _channel
        +Stream~Set~String~~ presenceStream
        +Stream~WorkspaceActivity~ activityStream
        +void subscribe(workspaceId, userId)
        +void unsubscribe()
        +void trackPresence()
    }

    class WorkspaceNotifier {
        +Workspace? state
        +Future~void~ switchTo(Workspace)
        +Future~void~ refresh()
    }

    Workspace "1" --> "*" WorkspaceMember
    Workspace "1" --> "*" WorkspaceInvite
    WorkspaceMember --> MemberDisplay : resolved via profiles
    WorkspaceRealtimeService --> WorkspaceActivity : emits

    note for Workspace "type: personal | shared\nplan: free | premium\nRLS via SECURITY DEFINER helpers"
    note for WorkspaceMember "role: owner | admin | member | viewer"
```

---

## Database Schema

### Supabase (Remote)

```mermaid
erDiagram
    profiles {
        uuid id PK
        text display_name
        text email
        text photo_url
    }

    workspaces {
        uuid id PK
        text name
        text slug
        uuid owner_id FK
        text type
        text plan
        timestamp plan_expires_at
        text emoji
        text color
        text description
        jsonb settings
        timestamp created_at
        timestamp updated_at
    }

    workspace_members {
        uuid id PK
        uuid workspace_id FK
        uuid user_id FK
        text role
        uuid invited_by FK
        timestamp joined_at
    }

    workspace_invites {
        uuid id PK
        uuid workspace_id FK
        text email
        text role
        text token
        timestamp expires_at
        timestamp accepted_at
    }

    workspace_activity {
        uuid id PK
        uuid workspace_id FK
        uuid user_id FK
        text action
        text entity_type
        uuid entity_id
        text entity_label
        numeric amount
        jsonb metadata
        timestamp created_at
    }

    expenses {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        date transaction_date
        int month
        int year
        text pay_type
        text category
        text subcategory
        numeric amount
        text payment_method
        int installments
        bool is_fixed
        text store_description
        uuid installment_plan_uuid_id FK
        uuid recurring_rule_id FK
        uuid author_user_id FK
        timestamp created_at
    }

    incomes {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        int month
        int year
        text income_type
        numeric amount
        bool is_net
        numeric inss_deducted
        numeric irrf_deducted
        text notes
        timestamp created_at
    }

    installment_plans {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        text description
        text store_name
        date purchase_date
        numeric total_amount
        int num_installments
        numeric installment_amount
        text payment_method
        date first_due_date
        text status
        uuid author_user_id FK
        timestamp created_at
        timestamp updated_at
    }

    installment_payments {
        uuid id PK
        uuid plan_id FK
        uuid user_id FK
        int installment_num
        date due_date
        numeric amount
        text status
        date paid_date
        numeric paid_amount
        int expense_id
        date financial_period_start
        date financial_period_end
        timestamp created_at
        timestamp updated_at
    }

    recurring_rules {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        text name
        numeric base_amount
        text amount_type
        text frequency
        int interval_count
        int day_of_month
        date starts_on
        date ends_on
        text status
        text payment_method
        bool is_auto_detected
        uuid author_user_id FK
        timestamp created_at
        timestamp updated_at
    }

    recurring_occurrences {
        uuid id PK
        uuid rule_id FK
        uuid user_id FK
        date scheduled_date
        numeric expected_amount
        text status
        date paid_date
        numeric actual_amount
        int expense_id
        bool is_exception
        timestamp created_at
    }

    categories {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        uuid parent_id FK
        text slug
        text name
        text emoji
        text color_hex
        text financial_type
        bool is_system
        bool is_swile
        bool is_fixed
        bool is_archived
        int display_order
    }

    period_budgets {
        uuid id PK
        uuid user_id FK
        uuid workspace_id FK
        date period_start
        date period_end
        jsonb category_amounts
        numeric total_amount
        bool is_custom
        timestamp created_at
    }

    budget_changes {
        uuid id PK
        uuid workspace_id FK
        uuid user_id FK
        date period_start
        text category_slug
        numeric old_amount
        numeric new_amount
        timestamp changed_at
    }

    user_salary_settings {
        uuid id PK
        uuid user_id FK
        numeric net_salary
        numeric swile_meal
        numeric swile_food
        int cutoff_day
        timestamp created_at
    }

    accounts {
        uuid id PK
        uuid user_id FK
        text name
        text institution
        text type
        numeric current_balance
        bool is_active
        timestamp created_at
        timestamp updated_at
    }

    investments {
        uuid id PK
        uuid user_id FK
        text type
        text product_name
        text institution
        date date_added
        numeric total_invested
        numeric current_balance
        numeric return_amount
        text liquidity
        timestamp created_at
    }

    net_worth_snapshots {
        uuid id PK
        uuid user_id FK
        int month
        int year
        numeric fgts_balance
        numeric investments_total
        numeric emergency_fund
        numeric pending_installments
        timestamp created_at
    }

    workspaces ||--o{ workspace_members : "has"
    workspaces ||--o{ workspace_invites : "has"
    workspaces ||--o{ workspace_activity : "logs"
    workspaces ||--o{ expenses : "scopes"
    workspaces ||--o{ incomes : "scopes"
    workspaces ||--o{ installment_plans : "scopes"
    workspaces ||--o{ recurring_rules : "scopes"
    workspaces ||--o{ period_budgets : "scopes"
    installment_plans ||--o{ installment_payments : "generates"
    recurring_rules ||--o{ recurring_occurrences : "generates"
    expenses }o--|| installment_plans : "belongs to"
    expenses }o--|| recurring_rules : "linked to"
    categories ||--o{ categories : "parent/child"
```

### Drift (Local SQLite)

```mermaid
erDiagram
    Expenses {
        int id PK
        int month
        int year
        text payType
        text category
        text subcategory
        real amount
        text paymentMethod
        int installments
        bool isFixed
        text storeDescription
        text createdAt
    }

    Incomes {
        int id PK
        int month
        int year
        text incomeType
        real amount
        bool isNet
        real inssDeducted
        real irrfDeducted
        text notes
        text createdAt
    }

    UserSettings {
        int id PK
        text key UK
        text value
    }

    SyncQueueItems {
        int id PK
        text operationType
        text payload
        text idempotencyKey UK
        int retryCount
        text status
        text error
        text createdAt
        text processedAt
    }

    Investments {
        int id PK
        text type
        text productName
        text institution
        text dateAdded
        real totalInvested
        real currentBalance
        real returnAmount
        text liquidity
        text notes
        text createdAt
    }

    NetWorthSnapshots {
        int id PK
        int month
        int year
        real fgtsBalance
        real investmentsTotal
        real emergencyFund
        real pendingInstallments
        text notes
        text createdAt
    }

    BudgetGoals {
        int id PK
        text category
        real targetPercentage
        real targetAmount
        text type
        text createdAt
    }

    CategoryTable {
        int id PK
        text dbValue UK
        text name
        text emoji
        bool isSwile
        bool isSystem
        int orderIndex
    }

    UserSettings ||--o{ UserSettings : "key-value store (forecast cache, insight stats, preferences)"
    SyncQueueItems ||--o{ SyncQueueItems : "idempotent — unique idempotencyKey"
```

---

## Sequence Diagrams

### App Startup

```mermaid
sequenceDiagram
    participant App as main.dart
    participant Shell as MainShell
    participant Auth as Supabase Auth
    participant DB as Drift (SQLite)
    participant WS as WorkspaceNotifier
    participant Sync as SyncManager

    App->>Auth: initialize()
    Auth-->>App: session (or null)
    App->>DB: open AppDatabase
    DB-->>App: ready
    App->>Shell: render (ProviderScope)

    alt Authenticated
        Shell->>WS: read activeWorkspaceProvider
        WS->>Auth: currentUser.id
        WS->>Supabase: getUserWorkspaces()
        Supabase-->>WS: List<Workspace>
        WS-->>Shell: activeWorkspace
        Shell->>Sync: processPendingQueue()
        Sync->>DB: getPendingOperations()
        DB-->>Sync: List<SyncQueueItem>
        Sync->>Supabase: executeRemote(ops)
        Supabase-->>Sync: success/failure
        Shell->>Supabase: subscribe realtime channel
    else Not Authenticated
        Shell->>Shell: navigate → AuthScreen
    end
```

### Add Expense (Offline-first)

```mermaid
sequenceDiagram
    participant UI as QuickAddBottomSheet
    participant ER as ExpenseRepository
    participant SB as Supabase
    participant SQ as OperationQueue (Drift)
    participant SM as SyncManager
    participant RP as Riverpod Providers

    UI->>ER: insert(transactionDate, category, amount, ...)
    ER->>ER: build payload (+ workspaceId, userId, authorUserId)

    alt Online
        ER->>SB: from('expenses').insert(payload).select()
        SB-->>ER: Expense (with server UUID)
        ER-->>UI: Expense
    else Offline
        ER->>SQ: enqueue(ExpenseInsertOperation, idempotencyKey)
        SQ->>SQ: insertOrIgnore (dedup)
        SQ-->>ER: queued
        ER-->>UI: optimistic Expense (local id)
    end

    ER->>RP: invalidate(financialSnapshotProvider)
    RP->>RP: recompute snapshot reactively

    note over SM: On reconnect
    SM->>SQ: getPending()
    SQ-->>SM: List<SyncQueueItem>
    SM->>SB: executeRemote(each op)
    SB-->>SM: success
    SM->>SQ: markCompleted(id)
```

### Create Installment Purchase

```mermaid
sequenceDiagram
    participant UI as QuickAddBottomSheet
    participant IS as InstallmentService
    participant IPR as InstallmentPlanRepository
    participant IPYR as InstallmentPaymentRepository
    participant ER as ExpenseRepository
    participant SB as Supabase

    UI->>IS: createPurchase(description, totalAmount, numInstallments, ...)

    IS->>IS: compute baseAmount = floor(total/n * 100)/100
    IS->>IS: compute lastAmount (remainder)

    IS->>IPR: create(InstallmentPlan)
    IPR->>IPR: inject userId + workspaceId + authorUserId
    IPR->>SB: from('installment_plans').insert(payload).select()
    SB-->>IPR: InstallmentPlan (UUID)
    IPR-->>IS: plan

    IS->>IS: generate N InstallmentPayment rows
    IS->>IPYR: insertAll(payments)
    IPYR->>IPYR: inject userId per row
    IPYR->>SB: from('installment_payments').insert(rows).select()
    SB-->>IPYR: List<InstallmentPayment>
    IPYR-->>IS: payments

    IS-->>UI: plan

    UI->>ER: insert(firstExpense, installmentPlanUuidId: plan.id)
    ER->>SB: from('expenses').insert(...)
    SB-->>ER: Expense
    ER-->>UI: done

    UI->>UI: invalidate(activeInstallmentPlansProvider)
    UI->>UI: invalidate(financialSnapshotProvider)
```

### Financial Snapshot Computation

```mermaid
sequenceDiagram
    participant P as financialSnapshotProvider
    participant FE as FinancialEngine
    participant EE as EnvelopeEngine
    participant FRE as ForecastingEngine
    participant OE as ObligationEngine
    participant IR as IncomeRepository
    participant ER as ExpenseRepository
    participant PR as PeriodBudgetRepository
    participant IPR as InstallmentPlanRepository
    participant ROR as RecurringOccurrencesRepository

    P->>IR: watchPeriod(period)
    IR-->>P: List<Income>
    P->>ER: watchPeriod(period)
    ER-->>P: List<Expense>
    P->>PR: getPeriodBudget(period)
    PR-->>P: PeriodBudget
    P->>IPR: getActive()
    IPR-->>P: List<InstallmentPlan>
    P->>ROR: getPending(period.end)
    ROR-->>P: List<RecurringOccurrence>

    P->>OE: buildObligations(pendingInstallments, pendingOccurrences)
    OE-->>P: List<ScheduledPayment>

    P->>EE: buildEnvelopes(budgetEntries, categoriesBySlug, prevExpenses, prevPeriod)
    EE-->>P: List<Envelope>

    P->>FE: buildSnapshot(period, incomes, expenses, salary, swile, emergencyFund, activePlans, envelopes)
    FE-->>P: FinancialSnapshot (without projection)

    P->>FRE: buildProjection(period, totalSpent, totalAllocated, currentBalance, obligations)
    FRE->>FRE: computeBurnRate()
    FRE->>FRE: computeLiquidityRisk()
    FRE->>FRE: buildCashflowForecast() (if enabled)
    FRE-->>P: FinancialProjection

    P->>FE: attach projection to snapshot
    FE-->>P: FinancialSnapshot (complete)
    P-->>P: emit to all watchers
```

### Workspace Invite & Accept

```mermaid
sequenceDiagram
    participant Admin as Admin User (UI)
    participant WR as WorkspaceRepository
    participant SB as Supabase
    participant Email as Email (Invite Link)
    participant Guest as Guest User (browser)
    participant EF as Edge Function: accept-workspace-invite

    Admin->>WR: inviteMember(workspaceId, email, role)
    WR->>SB: from('workspace_invites').insert({email, role, token: uuid(), expires_at})
    SB-->>WR: WorkspaceInvite
    WR-->>Admin: invite link (token)
    Admin->>Email: copy invite link

    Email->>Guest: click link (token in URL)
    Guest->>EF: POST /accept-workspace-invite {token}
    EF->>SB: validate token (not expired, not accepted)
    SB-->>EF: WorkspaceInvite row
    EF->>SB: insert workspace_members (workspace_id, user_id, role)
    EF->>SB: update workspace_invites SET accepted_at = now()
    EF->>SB: insert workspace_activity (action: 'member_joined')
    EF-->>Guest: {workspace} (200 OK)
    Guest->>Guest: switch active workspace
```

### Realtime Activity Feed

```mermaid
sequenceDiagram
    participant WRS as WorkspaceRealtimeService
    participant SB as Supabase Realtime
    participant WA as workspaceActivityRealtimeProvider
    participant AFCard as ActivityFeedPreviewCard
    participant Provider as latestWorkspaceActivityProvider

    Note over WRS: On app resume / workspace change
    WRS->>SB: subscribe channel workspace:{id}
    SB-->>WRS: connected

    WRS->>SB: track presence {userId, joinedAt}
    SB-->>WRS: presenceState (all online members)
    WRS->>WRS: emit Set<String> (online userIds)

    Note over AFCard: User in another tab adds expense
    SB->>WRS: INSERT event on workspace_activity
    WRS->>WA: emit(WorkspaceActivity)
    WA->>Provider: invalidate(latestWorkspaceActivityProvider)
    Provider->>SB: refetch latest activity
    SB-->>Provider: List<WorkspaceActivity>
    Provider-->>AFCard: rebuild with new items

    Note over WRS: App pause / workspace switch
    WRS->>SB: unsubscribe channel
    WRS->>SB: subscribe new channel workspace:{newId}
```

---

## Stack

| Layer | Technology |
|---|---|
| **Language** | Dart 3 |
| **Framework** | Flutter 3 (Material 3) |
| **State** | Riverpod 2 (autoDispose) |
| **Local DB** | Drift (SQLite) — type-safe DAOs, auto migrations |
| **Backend** | Supabase — auth, REST, realtime, Edge Functions |
| **RLS** | SECURITY DEFINER helper functions (workspace isolation) |
| **Charts** | fl_chart — line, pie, bar (animated, responsive) |
| **Fonts** | Google Fonts (Manrope) |
| **Code Gen** | build_runner (Drift, Riverpod) |

---

## Business Logic

### Predictive Financial Engine

The engine is **deterministic**, not ML. Works from day one with zero history:

- **Burn Rate** — Average daily spending, projected forward to period end
- **Days Until Empty** — Cash balance ÷ burn rate with scheduled obligations subtracted
- **Projected Closing Balance** — Current balance + projected income − burn projection − installment drops
- **Cashflow Forecast** — 90-day chart (solid = actual, dashed = projected) with obligation event markers
- **Category Velocity** — Spending rate per category vs historical average (2σ spike detection)

### Intelligence Layer (12 rules)

No ML. Pure deterministic rules triggered on each snapshot recomputation:

| Rule | Trigger |
|---|---|
| `overdraftRisk` | Projected balance goes negative before period end |
| `liquidityAlert` | Days-until-empty < 7 with known obligations |
| `budgetOverrun` | Envelope spent > 100% of allocated |
| `spendingSpike` | Category spend > 2σ above monthly average |
| `subscriptionCreep` | Total recurring rules increased month-over-month |
| `duplicateCharge` | Same merchant, same amount within 3 days |
| `savingsOpportunity` | Savings rate < historical average by >10% |
| `earlyPayoff` | Installment plan can be paid off with current balance |
| `budgetStreak` | N consecutive periods under budget |
| `savingsRecord` | Highest savings rate in last 12 periods |
| `debtReduction` | Installment total reduced vs previous period |
| `categoryUnderControl` | High-spend category now tracking under budget |

### Budget Envelope Alerts

- 🟢 Green — < 75% spent
- 🟡 Yellow — 75–89% spent
- 🟠 Orange — 90–99% spent
- 🔴 Red — ≥ 100% spent (overspent)

### CLT-specific Features

- **FGTS**: Auto-projected at 8% of gross salary
- **13th Salary**: Full INSS + IRRF 2025 progressive table simulation with dependent deductions
- **Swile**: Separate Meal/Food buckets excluded from cash burn rate
- **Cutoff Day**: Customizable period start (default day 1, most Brazilians use 5–15)

### Workspace Roles

| Role | Create/Edit Transactions | Manage Members | Transfer Ownership |
|---|---|---|---|
| **Owner** | ✅ | ✅ | ✅ (via Edge Function) |
| **Admin** | ✅ | ✅ | ❌ |
| **Writer** | ✅ | ❌ | ❌ |
| **Viewer** | ❌ | ❌ | ❌ |

---

## Setup

### Prerequisites

- Flutter 3.27+ ([install](https://flutter.dev))
- Dart SDK ≥ 3.0 (included with Flutter)
- Git

### Install

```bash
git clone https://github.com/luigrocha/farol.git
cd farol
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Web

```bash
flutter run -d chrome --dart-define-from-file=env.json
```

### Dev

```bash
flutter analyze          # 0 issues expected
flutter test             # 31 files, 182+ tests
```

---

## Testing & Quality

| Metric | Status |
|---|---|
| **Lint warnings** | 0 (`flutter analyze` clean) |
| **Test files** | 31 (unit + widget + sync + integration) |
| **Total tests** | 182+ |
| **CI** | GitHub Actions — Flutter 3.27, Ubuntu |
| **Coverage** | Forecasting engine, intelligence layer, sync (queue, conflict resolver, manager), financial engine, envelope engine, recurring engine, installment service, repositories, auth UI |

---

## License

© 2026 Luis Rocha. MIT.
