# Farol — Product Roadmap
> Última atualização: 2026-05-08 (auditado no código real)
> Baseado em: `FAROL_PREDICTIVE_ENGINE.md`

---

> ## 🚨 Status Revisado — 2026-05-08
>
> Auditoria do código revelou que o **motor preditivo completo está implementado**.
> Todos os planos P0–P6 estão concluídos no domínio, infraestrutura e providers.
> O foco atual mudou para: **UI polish · Testes · Web/Desktop adaptation**.
>
> Ver `CLAUDE.md` → seção "Estado Real dos Planos" para status detalhado.

---

## Grafo de Dependências (histórico — todos concluídos)

```
categories_redesign (P0)  ✅ CONCLUÍDO
    ├──→ installments_redesign (P1)   ✅ CONCLUÍDO
    └──→ financial_engine (P2)        ✅ CONCLUÍDO
              ├──→ recurring_rules (P3)         ✅ CONCLUÍDO
              │         └──→ forecasting (P4)   ✅ CONCLUÍDO
              │                   └──→ intelligence_layer (P6)  ✅ CONCLUÍDO
              └──→ offline_sync (P5)            ✅ CONCLUÍDO
```

---

## P0 · categories_redesign · 🟢 Concluído

**Plano**: `plans/categories_redesign.md`
**Concluído**: Migrations V12, V17–V20 aplicadas. `CategoryRef` + `CategoryResolver` implementados. `category_id NOT NULL` em expenses.
**Pendente**: UI polish em `categories_management_screen`.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | CategoryRef + Resolver | Value object sem StateError | 🔴 |
| 2 | Backfill de dados | category_id em expenses existentes | 🔴 |
| 3 | Migração de Providers | UI usa CategoryRef | 🔴 |
| 4 | Eliminação do enum | Cleanup final | 🔴 |

**ADR**: `docs/decisions/001-category-unification.md`

---

## P1 · installments_redesign · 🔴 Não iniciado

**Plano**: `plans/installments_redesign.md`
**ETA estimada**: Semanas 3–7 (inicia com P0 Fase 1-2)
**Crítico**: O ForecastingEngine é cego sem as parcelas futuras em DB.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Schema + Entidades | installment_plans + installment_payments | ✅ |
| 2 | InstallmentService | createPurchase() gera N parcelas auto | ✅ |
| 3 | Migração | card_installments → novo modelo (V21–V23) | ✅ |
| 4 | Nova UI | `installments_screen` com timeline | ✅ |
| 5 | Integração Forecasting | ObligationEngine lê parcelas pendentes | ✅ |

**ADR**: `docs/decisions/005-installments-redesign.md`

---

## P2 · financial_engine · 🟢 Concluído

**Plano**: `plans/financial_engine.md`
**Concluído**: `Money`, `FinancialSnapshot`, `FinancialEngine`, `EnvelopeEngine` implementados e wired no `financialSnapshotProvider`. Dashboard usa `BurnRateCard`, `HealthGaugeCard`, `PeriodBalanceHero`.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Money value object | Tipo seguro para dinheiro | ✅ |
| 2 | FinancialSnapshot entity | Contrato do objeto central | ✅ |
| 3 | FinancialEngine service | Produz o snapshot completo | ✅ |
| 4 | Dashboard refactoring | 1 provider → todos os widgets | ✅ |
| 5 | EnvelopeEngine | Rollover + alocação automática | ✅ |

**ADR**: `docs/decisions/002-financial-snapshot.md`

---

## P3 · recurring_rules · 🟢 Concluído

**Plano**: `plans/recurring_rules.md`
**Concluído**: `RecurringRule/Occurrence`, `RecurrenceResolver`, `RecurringDetector`, migrations V24–V25, UI screens completas.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | RecurrenceResolver | Gera ocorrências a partir da regra (puro Dart) | ✅ |
| 2 | Schema + Repositórios | recurring_rules + recurring_occurrences | ✅ |
| 3 | Migração isFixed | gastos isFixed=true → RecurringRule | ✅ |
| 4 | UI de Recorrentes | `recurring_screen`, `add_recurring_bottom_sheet` | ✅ |
| 5 | Detecção automática | `RecurringDetector` + `recurring_suggestions_screen` | ✅ |

**ADR**: `docs/decisions/006-recurring-rules.md`

---

## P4 · forecasting · 🟡 Domínio completo — falta testes

**Plano**: `plans/forecasting.md`
**Concluído**: `ForecastingEngine`, `ObligationEngine`, todos os providers wired. `analytics_screen` + `cashflow_chart` existem.
**Pendente**: testes unitários para algoritmos críticos.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | BurnRate | Widget no dashboard (`BurnRateCard`) | ✅ |
| 2 | DaysUntilEmpty + LiquidityRisk | `LiquidityAlertCard` no dashboard | ✅ |
| 3 | ProjectedClosingBalance | `financialProjectionProvider` | ✅ |
| 4 | CashflowForecast 90 dias | `cashflow_chart.dart` na analytics screen | ✅ |
| 5 | CategoryVelocity | Implementado em `ForecastingEngine` | ✅ |
| 6 | Testes unitários | BurnRate, DaysUntilEmpty, ProjectedBalance | 🔴 |

**ADR**: `docs/decisions/003-forecasting-deterministic.md`

---

## P5 · offline_sync · 🟡 Domínio completo — falta testes

**Plano**: `plans/offline_sync.md`
**Concluído**: `SyncManager`, `OperationQueue`, `ConflictResolver`, `ConnectivityBanner`, providers wired.
**Pendente**: testes dos cenários offline→online.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Connectivity detection | `ConnectivityBanner` no dashboard | ✅ |
| 2 | OperationQueue | Queue persistente em Drift com retry | ✅ |
| 3 | SyncManager | Orquestrador online/offline | ✅ |
| 4 | Expense Repository | Wrap com SyncManager | ✅ |
| 5 | Conflict Resolution | Last-Write-Wins + merge semântico | ✅ |
| 6 | Testes de integração | Cenários offline→online, retry, conflito | 🔴 |

**ADR**: `docs/decisions/004-sync-strategy.md`

---

## P6 · intelligence_layer · 🟡 Domínio completo — falta testes

**Plano**: `plans/intelligence_layer.md`
**Concluído**: `IntelligenceLayer` com 12 regras, `InsightsPanel`, `insights_screen`, `insightsProvider`, `DismissedInsightsRepository`.
**Pendente**: testes das 12 regras com dados sintéticos, dismiss rate tracking.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Foundation + 4 regras core | Overdraft, Liquidez, Spike, Investimento | ✅ |
| 2 | InsightsPanel no dashboard | UI não-invasiva, max 3 insights | ✅ |
| 3 | 8 regras avançadas | Duplicatas, Assinaturas, Conquistas, etc. | ✅ |
| 4 | Analytics de insights | Testes + dismiss rate tracking | 🔴 |

**ADR**: `docs/decisions/007-intelligence-layer.md`

---

## Próximos Passos Reais (pós-auditoria)

| Prioridade | Tarefa | Impacto |
|---|---|---|
| 🔴 P1 | Testes: `ForecastingEngine` (BurnRate, DaysUntilEmpty) | Confiabilidade do motor |
| 🔴 P1 | Testes: `IntelligenceLayer` (12 regras com dados sintéticos) | Confiabilidade dos insights |
| 🔴 P1 | Confirmar migrations V21–V25 no Supabase de produção | Sem isso: crash em produção |
| 🟡 P2 | Audit UI: quais screens ainda usam providers legados | Consistência de dados |
| 🟡 P2 | Web/Desktop: sidebar nav + layouts adaptativos | Usuários avançados |
| 🟢 P3 | Testes: `SyncManager` (offline→online, conflito) | Resiliência offline |

---

## Métricas de Sucesso

| Plano | Métrica | Status |
|---|---|---|
| categories_redesign | 0 `StateError` em produção | ✅ Resolvido |
| installments_redesign | Parcelas futuras visíveis no ForecastingEngine | ✅ Implementado |
| financial_engine | Dashboard com 1 único `ref.watch()` para estado financeiro | ✅ `financialSnapshotProvider` |
| recurring_rules | Recorrentes projetados 3 meses à frente automaticamente | ✅ Implementado |
| forecasting | Usuário responde "quanto vou poupar?" olhando o app | 🟡 Funcional, sem testes |
| offline_sync | 0 perda de dados no cenário offline → online | 🟡 Funcional, sem testes |
| intelligence_layer | Dismiss rate de insights < 40% | 🔴 Sem tracking ainda |

---

## Histórico de Versões

| Data | Mudança |
|---|---|
| 2026-05-07 | Roadmap inicial (4 planos: P0–P3) |
| 2026-05-07 | Revisão completa: 7 planos, grafo de dependências, prioridades redefinidas |
