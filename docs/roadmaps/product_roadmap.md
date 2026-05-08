# Farol — Product Roadmap
> Última atualização: Maio 2026
> Baseado em: `FAROL_PREDICTIVE_ENGINE.md`

---

## Grafo de Dependências (lei fundamental)

```
categories_redesign (P0)  ← COMEÇAR AQUI
    ├──→ installments_redesign (P1)   ← pode iniciar com P0 Fase 1-2
    └──→ financial_engine (P2)        ← precisa P0 Fase 3+
              ├──→ recurring_rules (P3)
              │         └──→ forecasting (P4) ← precisa P1 + P2 + P3
              │                   └──→ intelligence_layer (P6)
              └──→ offline_sync (P5)  ← paralelo com P4
```

**Regra**: nenhum plano começa sem que suas dependências estejam na fase correta.
**Exceção permitida**: P1 (`installments_redesign`) pode iniciar em paralelo com P0 após a Fase 1-2 de P0.

---

## P0 · categories_redesign · 🔴 Não iniciado

**Plano**: `plans/categories_redesign.md`
**ETA estimada**: Semanas 1–4
**Crítico**: Bloqueia absolutamente tudo. Sem isso, categorias custom crasham a app.

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
| 1 | Schema + Entidades | installment_plans + installment_payments | 🔴 |
| 2 | InstallmentService | createPurchase() gera N parcelas auto | 🔴 |
| 3 | Migração | card_installments → novo modelo | 🔴 |
| 4 | Nova UI | Tela com timeline, fluxo novo | 🔴 |
| 5 | Integração Forecasting | ObligationEngine lê parcelas pendentes | 🔴 |

**ADR**: `docs/decisions/005-installments-redesign.md`

---

## P2 · financial_engine · 🔴 Não iniciado

**Plano**: `plans/financial_engine.md`
**ETA estimada**: Semanas 5–10 (após P0 Fase 3)
**Crítico**: Sem o FinancialSnapshot, o Forecasting não tem onde viver.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Money value object | Tipo seguro para dinheiro | 🔴 |
| 2 | FinancialSnapshot entity | Contrato do objeto central | 🔴 |
| 3 | FinancialEngine service | Produz o snapshot completo | 🔴 |
| 4 | Dashboard refactoring | 1 provider → todos os widgets | 🔴 |
| 5 | EnvelopeEngine | Rollover + alocação automática | 🔴 |

**ADR**: `docs/decisions/002-financial-snapshot.md`

---

## P3 · recurring_rules · 🔴 Não iniciado

**Plano**: `plans/recurring_rules.md`
**ETA estimada**: Semanas 11–16 (após P2 Fase 1-2)
**Crítico**: O ObligationEngine do Forecasting precisa dos recorrentes futuros.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | RecurrenceResolver | Gera ocorrências a partir da regra (puro Dart) | 🔴 |
| 2 | Schema + Repositórios | recurring_rules + recurring_occurrences | 🔴 |
| 3 | Migração isFixed | gastos isFixed=true → RecurringRule | 🔴 |
| 4 | UI de Recorrentes | Tela dedicada, detalhe, fluxo de criação | 🔴 |
| 5 | Detecção automática | RecurringDetector com confidence scoring | 🔴 |

**ADR**: `docs/decisions/006-recurring-rules.md`

---

## P4 · forecasting · 🔴 Não iniciado

**Plano**: `plans/forecasting.md`
**ETA estimada**: Semanas 17–22 (após P1+P2+P3)
**O momento wow do produto**: o usuário vê o futuro das suas finanças.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | BurnRate | Velocidade de gasto + widget no dashboard | 🔴 |
| 2 | DaysUntilEmpty + LiquidityRisk | Métrica mais impactante | 🔴 |
| 3 | ProjectedClosingBalance | "Como vou fechar o período?" | 🔴 |
| 4 | CashflowForecast 90 dias | Chart sólido/pontilhado + drops de parcelas | 🔴 |
| 5 | CategoryVelocity | Categorias "fora de controle" | 🔴 |
| 6 | SavingsPrediction | "Quanto vou poupar?" | 🔴 |

**ADR**: `docs/decisions/003-forecasting-deterministic.md`

---

## P5 · offline_sync · 🔴 Não iniciado

**Plano**: `plans/offline_sync.md`
**ETA estimada**: Semanas 18–22 (paralelo com P4)
**Sem este plano**: registrar gasto no metrô → erro silencioso.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Connectivity detection | Banner offline discreto | 🔴 |
| 2 | OperationQueue | Queue persistente em Drift com retry | 🔴 |
| 3 | SyncManager | Orquestrador online/offline | 🔴 |
| 4 | Expense Repository | Wrap com SyncManager + cache Drift | 🔴 |
| 5 | Conflict Resolution | Last-Write-Wins + merge semântico | 🔴 |

**ADR**: `docs/decisions/004-sync-strategy.md`

---

## P6 · intelligence_layer · 🔴 Não iniciado

**Plano**: `plans/intelligence_layer.md`
**ETA estimada**: Semanas 23–28 (após P4 completo)
**O toque final**: de ferramenta a copiloto.

| # | Fase | Objetivo | Status |
|---|---|---|---|
| 1 | Foundation + 4 regras core | Overdraft, Liquidez, Spike, Investimento | 🔴 |
| 2 | InsightsPanel no dashboard | UI não-invasiva, max 3 insights | 🔴 |
| 3 | 8 regras avançadas | Duplicatas, Assinaturas, Conquistas, etc. | 🔴 |
| 4 | Analytics de insights | Medir relevância, ajustar thresholds | 🔴 |

**ADR**: `docs/decisions/007-intelligence-layer.md`

---

## Planos Completados

*(Mover aqui quando uma fase for concluída)*

---

## Métricas de Sucesso por Plano

| Plano | Métrica principal |
|---|---|
| categories_redesign | 0 `StateError` em produção por categoria desconhecida |
| installments_redesign | Parcelas futuras visíveis no ForecastingEngine |
| financial_engine | Dashboard com 1 único `ref.watch()` para estado financeiro |
| recurring_rules | Recorrentes projetados 3 meses à frente automaticamente |
| forecasting | Usuário responde "quanto vou poupar?" olhando o app |
| offline_sync | 0 perda de dados no cenário offline → online |
| intelligence_layer | Dismiss rate de insights < 40% |

---

## Linha do Tempo Estimada

```
Semana  1–4   │ P0: Categories Redesign
Semana  3–7   │ P1: Installments Redesign (paralelo com P0 F3-4)
Semana  5–10  │ P2: Financial Engine
Semana 11–16  │ P3: Recurring Rules
Semana 17–22  │ P4: Forecasting Engine
Semana 18–22  │ P5: Offline Sync (paralelo com P4)
Semana 23–28  │ P6: Intelligence Layer
              └──────────────────────────────────────────
                                             ≈ 7 meses total
```

> **Nota**: Estimativas conservadoras. Trabalho em paralelo pode reduzir o total para 5 meses.

---

## Histórico de Versões

| Data | Mudança |
|---|---|
| 2026-05-07 | Roadmap inicial (4 planos: P0–P3) |
| 2026-05-07 | Revisão completa: 7 planos, grafo de dependências, prioridades redefinidas |
