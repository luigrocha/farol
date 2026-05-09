# CLAUDE.md — Farol Project Intelligence

> Este archivo define cómo Claude opera en este proyecto.
> Claude actúa como **CTO Assistant**, **Architecture Reviewer** e **Implementation Partner**.
> Lee este archivo al inicio de cada sesión antes de cualquier acción.

---

## 🧭 Roles de Claude en este proyecto

### 1. CTO Assistant
- Evalúa decisiones técnicas con perspectiva de producto y negocio
- Identifica trade-offs entre velocidad de entrega y deuda técnica
- Sugiere prioridades de implementación según ROI y riesgo
- Mantiene coherencia arquitectónica entre sesiones

### 2. Architecture Reviewer
- Antes de implementar cualquier plan: analiza impacto, riesgos y dependencias
- Detecta breaking changes antes de que ocurran
- Propone estrategia incremental (nunca big bang rewrite)
- Documenta cada decisión en `docs/decisions/`

### 3. Implementation Partner
- Implementa por fases pequeñas y verificables
- Muestra plan detallado **antes** de modificar código
- Mantiene compatibilidad backward en cada paso
- Genera tests para cada cambio significativo

---

## 🔄 Workflow Estándar de Implementación

Cada plan en `plans/` sigue este flujo. **No saltear pasos.**

```
1. ANALIZA  → Lee el plan + código existente + dependencias
2. PROPONE  → Muestra plan detallado con impacto y riesgos
3. VALIDA   → Espera confirmación explícita antes de tocar código
4. FASE 1   → Implementa solo la primera fase (pequeña, reversible)
5. REVIEW   → Verifica: funciona, no rompe nada, backward compat
6. FASE N   → Continúa con la siguiente fase solo si review OK
```

**Comandos de activación:**
- `"Analiza plans/X.md"` → solo análisis, sin tocar código
- `"Implementa Fase 1 de plans/X.md"` → implementa fase 1 únicamente
- `"Review de plans/X.md Fase 1"` → verifica lo implementado
- `"Propone estrategia para X"` → análisis + propuesta sin implementar

---

## ⚖️ Reglas de Implementación (NO NEGOCIABLES)

```
✅ SIEMPRE:
  - Leer el plan completo antes de comenzar
  - Mostrar qué archivos se van a modificar antes de modificarlos
  - Mantener compatibilidad backward con código existente
  - Implementar cambios aditivos primero (add before replace)
  - Documentar breaking changes en docs/decisions/
  - Preferir extensión sobre reescritura

❌ NUNCA:
  - Refactorizar arquitectura sin solicitud explícita
  - Implementar más de una fase sin confirmación
  - Cambiar el schema Drift sin migration strategy
  - Romper providers Riverpod existentes
  - Eliminar código antes de tener el reemplazo en producción
  - Sobreingeniería: si la solución tiene >3 capas de abstracción, cuestionar
```

---

## 📁 Estructura del Proyecto

```
farol/
├── CLAUDE.md                    ← Este archivo (leer primero)
├── FAROL_PREDICTIVE_ENGINE.md   ← Documento estratégico maestro
│
├── plans/                       ← Planes de implementación por área
│   ├── categories_redesign.md   ← FASE 1: Sistema de categorías unificado
│   ├── financial_engine.md      ← FASE 2: Motor financiero central
│   ├── forecasting.md           ← FASE 3: Motor predictivo
│   └── offline_sync.md          ← FASE 4: Sincronización robusta
│
├── docs/
│   ├── architecture/            ← Documentación de arquitectura viva
│   ├── decisions/               ← ADRs (Architecture Decision Records)
│   ├── plans/                   ← Planes completados (archivo)
│   └── roadmaps/                ← Roadmaps de producto
│
└── lib/                         ← Código Flutter
    ├── core/
    ├── features/
    └── design/
```

---

## 🏗️ Stack

- Flutter 3 / Dart 3
- Riverpod 2 (autoDispose)
- Drift (SQLite) — offline-first
- Supabase (backend + realtime)
- Material 3 · fl_chart · Google Fonts

## 🇧🇷 Contexto de Negocio

- App de finanzas personales para trabajadores CLT en Brasil
- Diferenciadores: `cutoffDay` personalizable, Swile como bucket separado, FGTS/13°/INSS/IRRF
- Idioma: pt_BR (i18n habilitado)
- Estado: motor preditivo completo — foco atual em UI polish, testes e web adaptation

## 🗄️ Base de Dados

- Schema Supabase: 25 migrations aplicadas (V1–V25) — fonte de verdade em produção
- Schema Drift: `lib/core/database/app_database.dart` — device-local (UserSettings, OperationQueue, dismissed insights)
- Drift: mirror local + fila de operações offline (`OperationQueue`)
- **Regra**: sempre ter migration strategy antes de mudar schema

## ⚙️ Arquitetura de Domínio (implementada)

| Camada | Componente | Localização | Estado |
|---|---|---|---|
| Value Objects | `Money`, `CategoryRef` | `core/domain/value_objects/` | ✅ |
| Entities | `FinancialSnapshot`, `InstallmentPlan/Payment`, `RecurringRule/Occurrence`, `Envelope`, `FinancialInsight`, `FinancialProjection` | `core/domain/entities/` | ✅ |
| Services | `FinancialEngine`, `ForecastingEngine`, `ObligationEngine`, `EnvelopeEngine`, `IntelligenceLayer`, `InstallmentService`, `RecurringService`, `RecurrenceResolver`, `RecurringDetector`, `CategoryResolver` | `core/domain/services/` | ✅ |
| Infrastructure | `SyncManager`, `OperationQueue`, `ConflictResolver` | `core/infrastructure/sync/` | ✅ |
| Providers | `financialSnapshotProvider`, `financialProjectionProvider`, `cashflowForecastProvider`, `insightsProvider`, `recurringRulesStreamProvider`, `installmentPlansStreamProvider`, `isOfflineProvider`, `categoriesRefProvider` | `core/providers/providers.dart` | ✅ |

## 🚨 Foco Atual — O que realmente falta

1. ~~**UI audit + migração**~~ ✅ **Concluído 2026-05-08** — ver `plans/ui_provider_migration.md` e `docs/architecture/ui_audit_2026_05_08.md`
   - `categoriesStreamProvider` removido de quick_add e edit_expense → `categoriesRefProvider`
   - `categoriesMapProvider` removido de expense_breakdown → `categoriesRefProvider`
   - `cashExpensesProvider`, `cashRemainingProvider`, `installmentsProvider` (CardInstallment) removidos de health_screen → `financialSnapshotProvider`
   - `deleteFixedSeriesFrom` **removido** de `expense_repository.dart` em 2026-05-08
2. ~~**Testes**~~ ✅ **Concluído 2026-05-08** — `test/unit/forecasting_engine_test.dart` (30 testes), `test/unit/intelligence_layer_test.dart` (22 testes)
3. ~~**Web layout**~~ ✅ **Concluído 2026-05-08** — NavigationRail no MainShell + layout adaptativo em todas as screens principais (Dashboard, Transactions, Analytics, Budget, Installments, Recurring)
4. ~~**Migrations em produção**~~ ✅ **Confirmado 2026-05-08** — V21–V25 aplicadas. Tabelas `installment_plans`, `installment_payments`, `recurring_rules`, `recurring_occurrences` presentes em produção.
5. ~~**`fixedExpensePropagationProvider`**~~ ✅ Confirmado removido — não existe mais no codebase
6. ~~**Empty/loading states nos widgets do dashboard**~~ ✅ **Concluído 2026-05-08**
   - `BurnRateCard`: loading → `DashboardCardSkeleton(height: 130)` (antes: `SizedBox.shrink`)
   - `InsightsPanel`: loading → 2 shimmer boxes com label (antes: `SizedBox.shrink`)
   - `HealthGaugeCard`, `InstallmentsSummaryCard`: já tinham `DashboardCardSkeleton` ✅

## ✅ Migração card_installments — Concluída (2026-05-08)

A migração está **totalmente completa**. Todos os consumers usam `activeInstallmentPlansProvider` / `InstallmentPlan`:
- `InstallmentsSummaryCard`, `HealthGaugeCard`, `NetWorthSettingsSheet`, `PdfReportService` → ✅ `activeInstallmentPlansProvider`
- `totalMonthlyInstallmentsProvider`, `totalRemainingInstallmentsProvider` → ✅ derivados de `activeInstallmentPlansProvider`

O shim foi **removido** após confirmação de migração de dados de produção:
- `InstallmentRepository` — classe removida
- `installmentRepositoryProvider` — removido de `providers.dart`
- `transactions_screen.dart` — fallback `legacyPlanId` removido; delete agora usa apenas `planUuid`
- O campo `Expense.installmentPlanId` (int?) permanece no modelo/DB por compatibilidade mas não é mais usado na lógica de negócio

## 🛠️ Dev Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define-from-file=env.json
flutter analyze
flutter test
```

---

## 📋 Estado Real dos Planos (auditado em 2026-05-08)

> ⚠️ O status abaixo reflete o código real — não o planejado originalmente.
> O motor preditivo completo foi implementado. O foco agora é UI + testes + web.

| Plano | Domínio | DB (Migrations) | Providers | UI Screens | Testes | Status Real |
|---|---|---|---|---|---|---|
| `categories_redesign.md` | ✅ `CategoryRef`, `CategoryResolver` | ✅ V12, V17–V20 | ✅ `categoriesRefProvider` | ✅ `categories_management_screen` | ⚠️ parcial | 🟢 **Completo** |
| `installments_redesign.md` | ✅ `InstallmentPlan/Payment`, `InstallmentService` | ✅ V21–V23 | ✅ `installmentPlansStreamProvider`, `activeInstallmentPlansProvider` | ✅ `installments_screen`, `InstallmentsSummaryCard`, `HealthGaugeCard` | ✅ `installment_service_test` | 🟢 **Completo** |
| `financial_engine.md` | ✅ `Money`, `FinancialSnapshot`, `FinancialEngine`, `EnvelopeEngine` | ✅ (sem schema próprio) | ✅ `financialSnapshotProvider`, `envelopesProvider` | ✅ dashboard widgets: `BurnRateCard`, `PeriodBalanceHero`, `HealthGaugeCard` | ⚠️ parcial | 🟢 **Completo** |
| `recurring_rules.md` | ✅ `RecurringRule/Occurrence`, `RecurrenceResolver`, `RecurringDetector` | ✅ V24–V25 | ✅ `recurringRulesStreamProvider`, `generateRecurringOccurrencesProvider` | ✅ `recurring_screen`, `add_recurring_bottom_sheet`, `recurring_suggestions_screen` | ✅ `recurrence_resolver_test` | 🟢 **Completo** |
| `forecasting.md` | ✅ `ForecastingEngine`, `ObligationEngine`, `BurnRate`, `LiquidityRisk`, `CashflowForecast` | ✅ (lê tabelas existentes) | ✅ `financialProjectionProvider`, `cashflowForecastProvider` | ✅ `analytics_screen` + `cashflow_chart` | ⚠️ parcial | 🟢 **Completo** |
| `offline_sync.md` | ✅ `SyncManager`, `OperationQueue`, `ConflictResolver` | ✅ (Drift `sync_queue`) | ✅ `syncStatusProvider`, `isOfflineProvider` | ✅ `ConnectivityBanner` no dashboard | ✅ 29 testes (sync/) | 🟢 **Completo** |
| `intelligence_layer.md` | ✅ `IntelligenceLayer` (12 regras), `DismissedInsightsRepository` | ✅ (Drift UserSettings) | ✅ `insightsProvider`, `dismissedInsightsProvider` | ✅ `InsightsPanel`, `insight_card`, `insights_screen` | ✅ 22 testes | 🟢 **Completo** |

### O que realmente está pendente

- **Dismiss rate tracking** ✅ **Concluído 2026-05-08**
  - `InsightStats` entity em `core/domain/entities/insight_stats.dart`
  - `DismissedInsightsRepository.trackDismiss()` + `getStats()` — key `'insight_dismissal_stats'` em UserSettings (Drift)
  - `insightStatsProvider` em `providers.dart`
  - `InsightCard` chama `trackDismiss` + invalida `insightStatsProvider` no dismiss
  - `InsightsScreen` exibe seção "Tipos mais ignorados" para tipos com ≥2 dismissals

- **Cashflow forecast cache** ✅ **Concluído 2026-05-08** — ver ADR em `docs/decisions/adr_cashflow_forecast_cache.md`
  - Edge Function descartada (ver ADR); implementado cache client-side em Drift UserSettings
  - `CashflowDataPoint`/`CashflowForecast` agora têm `toJson`/`fromJson`
  - `ForecastCacheRepository` — TTL 2h, chave inclui período financeiro
  - `forecastCacheRepositoryProvider` + `cashflowForecastProvider` atualizado: cache hit evita fetch de todas as despesas
- **UI polish** ✅ **Concluído 2026-05-08** — fechar planos 🟡 `categories_redesign`, `financial_engine`, `forecasting`
  - `CategoriesManagementScreen`: `_CategoryTile` mostra chip `financialType` + badge "Sistema"; `_CategoryDialog` tem seletor de tipo financeiro
  - `AnalyticsScreen`: textos em espanhol corrigidos → pt_BR ("Tendência Mensal", "Receita", "Distribuição por Categoria", "Comparativo Mensal", "MÉDIA/MÊS", subtítulo da tela)
  - `CashflowChart`: loading state → `ShimmerBox` (antes: `CircularProgressIndicator`); card de saldo mínimo projetado adicionado abaixo do gráfico

Nenhum débito técnico de UI ou infraestrutura em aberto. O shim `InstallmentRepository` foi removido em 2026-05-08 após confirmação de migração de dados de produção.
