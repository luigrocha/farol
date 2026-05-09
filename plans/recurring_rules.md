# Plan: Recurring Rules Engine (Gastos Recorrentes)
**Area**: Domain · Database · Repositories · UI
**Prioridade**: P3 — alimenta o ObligationEngine do Forecasting
**Dependências**: `categories_redesign.md` (complete) · `financial_engine.md` (Phase 1-2)
**Arquivos impactados**: `app_database.dart`, novos em `lib/core/domain/`, UI nova em `features/`

---

## 🔍 Contexto do Problema

### Estado atual (confirmado no código)

```dart
// ÚNICO mecanismo de recorrência existente:
// DashboardScreen.dart — ao abrir o mês, copia os gastos com isFixed = true

ref.listen<AsyncValue<int>>(fixedExpensePropagationProvider, (_, next) {
  next.whenData((count) {
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count gasto(s) fixo(s) copiado(s) do mês anterior')),
      );
    }
  });
});

// Expense com isFixed = true
// Esse é o "motor de recorrência" — uma cópia de linha por mês
```

### Problemas concretos com `isFixed + copy`

1. **Valor variável**: O aluguel subiu R$100 em março — mas a cópia usa o valor antigo
2. **Sem frequências alternativas**: Netflix é mensal mas seguro do carro é semestral — impossível no modelo atual
3. **Sem pausa**: Para pausar um recorrente, precisa deletar e recriar
4. **Sem data de início/fim**: Um recorrente que começa em 3 meses não pode ser planejado
5. **Sem detecção automática**: O sistema não identifica que você paga "Netflix R$45" todo mês
6. **Sem forecasting real**: Os recorrentes futuros não impactam a projeção de saldo
7. **SnackBar como UX**: Notificar cópia com SnackBar é UX de emergência, não de produto

### Por que isso bloqueia o Forecasting

O `ObligationEngine` precisa saber: "nos próximos 3 meses, quais são os gastos recorrentes confirmados?". Com `isFixed + copy`:
- Os recorrentes futuros não existem até o mês chegar
- A projeção de saldo ignora R$2.000+/mês em gastos fixos (aluguel, planos, etc.)

---

## 📐 Modelo de Recorrentes

### Conceito: RecurringRule + RecurringOccurrence

```
RecurringRule (a regra — o "template" do recorrente)
  │ name: 'Aluguel', category: moradia, amount: R$2.500, frequency: monthly, day: 10
  │ starts_on: 2025-01-10, ends_on: null (indefinido)
  │ status: active
  │
  └─── RecurringOccurrence (cada instância gerada pela regra)
         scheduled_date: 2026-02-10, amount: R$2.500, status: pending
         scheduled_date: 2026-03-10, amount: R$2.500, status: pending
         scheduled_date: 2026-04-10, amount: R$2.500, status: pending
                │
                └── Expense (criada ao marcar como paga)
                      transaction_date: 2026-02-10
                      amount: R$2.500
                      recurring_rule_id: <uuid>
                      recurring_occurrence_id: <uuid>
```

### Schema Supabase

```sql
-- Regras de recorrência
CREATE TABLE recurring_rules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id) NOT NULL,
  category_id     UUID REFERENCES categories(id),

  -- Identificação
  name            TEXT NOT NULL,
  description     TEXT,

  -- Valor
  base_amount     NUMERIC(12,2) NOT NULL CHECK (base_amount > 0),
  amount_type     TEXT NOT NULL DEFAULT 'fixed'
    CHECK (amount_type IN ('fixed', 'variable', 'range')),
  amount_min      NUMERIC(12,2),  -- para range
  amount_max      NUMERIC(12,2),  -- para range

  -- Regra de frequência
  frequency       TEXT NOT NULL
    CHECK (frequency IN ('weekly', 'biweekly', 'monthly', 'quarterly', 'semiannual', 'yearly')),
  interval_count  INT NOT NULL DEFAULT 1,  -- a cada N frequências
  day_of_month    INT CHECK (day_of_month BETWEEN 1 AND 28),  -- para monthly
  month_of_year   INT[] ,                  -- para semiannual/yearly (ex: [1, 7])

  -- Vigência da regra
  starts_on       DATE NOT NULL,
  ends_on         DATE,                    -- null = indefinido
  ends_after_n    INT,                     -- ou termina após N ocorrências

  -- Estado
  status          TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'paused', 'cancelled')),
  paused_until    DATE,                    -- reativação automática

  -- Método de pagamento
  payment_method  TEXT,

  -- Detecção automática
  is_auto_detected  BOOLEAN DEFAULT FALSE,
  detection_confidence  NUMERIC(4,3),     -- 0.0 – 1.0

  -- Migração do isFixed legacy
  legacy_expense_id INT,                  -- expense original com isFixed=true

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Ocorrências geradas pela regra
CREATE TABLE recurring_occurrences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id         UUID REFERENCES recurring_rules(id) ON DELETE CASCADE NOT NULL,
  user_id         UUID REFERENCES auth.users(id) NOT NULL,

  -- Quando e quanto
  scheduled_date  DATE NOT NULL,
  expected_amount NUMERIC(12,2) NOT NULL,

  -- Estado
  status          TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'skipped', 'overridden')),
  paid_date       DATE,
  actual_amount   NUMERIC(12,2),

  -- Link para a transação real
  expense_id      UUID REFERENCES expenses(id),

  -- Exceção: essa ocorrência foi modificada manualmente
  is_exception    BOOLEAN DEFAULT FALSE,
  exception_notes TEXT,

  created_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(rule_id, scheduled_date)
);

-- Índice para ObligationEngine
CREATE INDEX idx_recurring_occurrences_pending
  ON recurring_occurrences(user_id, scheduled_date, status)
  WHERE status = 'pending';
```

---

## ⚡ Análise de Impacto

### Arquivos a criar
```
lib/core/domain/entities/recurring_rule.dart
lib/core/domain/entities/recurring_occurrence.dart
lib/core/domain/services/recurrence_resolver.dart   ← gera ocorrências a partir da regra
lib/core/domain/services/recurring_detector.dart    ← detecção automática
lib/core/repositories/recurring_rules_repository.dart
lib/core/repositories/recurring_occurrences_repository.dart
lib/features/recurring/recurring_screen.dart        ← nova tela
lib/features/recurring/add_recurring_bottom_sheet.dart
```

### Arquivos a modificar
```
lib/core/database/app_database.dart  ← novas tabelas Drift (migration)
lib/core/models/expense.dart         ← recurring_rule_id, recurring_occurrence_id
lib/features/dashboard/dashboard_screen.dart  ← remover fixedExpensePropagationProvider
```

### Breaking Changes

| Mudança | Severidade | Mitigação |
|---|---|---|
| Remover `fixedExpensePropagationProvider` do dashboard | 🟡 MÉDIO | Substituir por RecurringEngine antes de remover |
| Expenses com `isFixed=true` → migrar para RecurringRule | 🟡 MÉDIO | Migration script + legacy_expense_id para rastreabilidade |
| SnackBar de "X gastos copiados" → remover | 🟢 BAIXO | Substituir por indicador sutil no RecurringCard |

---

## 🗺️ Estratégia Incremental

### PHASE 1 — RecurrenceResolver (puro Dart, sem UI)
**Objetivo**: O coração da lógica — gerar ocorrências a partir de uma regra.
**Reversibilidade**: 100% — código novo, sem tocar no existente.

```
Tarefa 1.1: RecurringRule entity
  - Todos os campos do schema
  - nextOccurrenceDate() computed
  - isActiveOn(date) computed
  - Testes unitários de nextOccurrenceDate() para todas as frequências

Tarefa 1.2: RecurrenceResolver.generateOccurrences(rule, dateRange)
  - Algoritmo: começa em firstOccurrenceInOrAfter(range.start)
  - Loop até range.end ou ends_on ou ends_after_n
  - Retorna List<RecurringOccurrence> com status = pending
  - Edge cases:
    → daysOfMonth > dias do mês (ex: dia 31 em fevereiro) → último dia do mês
    → ends_after_n: conta ocorrências, não dias
    → paused_until: pula ocorrências até a data de reativação

Tarefa 1.3: Testes do RecurrenceResolver
  - Mensal dia 10 por 12 meses → 12 ocorrências corretas
  - Semestral (jan + jul) → 2 ocorrências por ano
  - Termina após 6 ocorrências → exatamente 6
  - Pausado até março → ocorrências de jan/fev ausentes
```

**Teste de sucesso**: `dart test test/core/recurrence_resolver_test.dart` → todos passam.

---

### PHASE 2 — Schema + Repositórios
**Objetivo**: Persistência do novo modelo.

```
Tarefa 2.1: Schema Supabase
  - CREATE TABLE recurring_rules (...)
  - CREATE TABLE recurring_occurrences (...)
  - RLS policies
  - Índices de performance

Tarefa 2.2: RecurringRulesRepository
  - create(), update(), delete(), watchAll(), getActive()
  - updateStatus(id, status) para pause/cancel
  - getForPeriod(period) → regras ativas no período

Tarefa 2.3: RecurringOccurrencesRepository
  - getPendingInRange(userId, start, end)  ← usado pelo ObligationEngine
  - markPaid(id, expenseId, actualAmount)
  - markSkipped(id, notes)
  - upsertOccurrences(List<RecurringOccurrence>)  ← bulk insert com ON CONFLICT DO NOTHING

Tarefa 2.4: Job de geração de ocorrências
  - Gerar ocorrências dos próximos 3 meses ao abrir o app
  - Gerar ocorrências ao criar/editar uma RecurringRule
  - Lógica: só insere se não existe (idempotente)
```

---

### PHASE 3 — Migração dos gastos isFixed existentes
**Objetivo**: Converter `Expense.isFixed = true` para `RecurringRule`.

```
Tarefa 3.1: Detecção dos gastos fixos existentes
  - Query: SELECT DISTINCT category, store_description, amount, payment_method
    FROM expenses WHERE is_fixed = true
  - Agrupar por (category, store_description) para identificar recorrentes únicos

Tarefa 3.2: Criar RecurringRules para cada grupo
  - frequency: monthly (todos os atuais são mensais)
  - day_of_month: moda do dia de pagamento histórico
  - base_amount: mediana dos valores históricos
  - legacy_expense_id: id do expense mais recente do grupo

Tarefa 3.3: Remover fixedExpensePropagationProvider
  - Substituir a cópia automática por:
    → RecurringEngine gera ocorrências dos próximos 3 meses na inicialização
    → Dashboard mostra "X recorrentes previstos" em vez de copiar expenses
  - Remover o SnackBar de "gastos copiados"

Tarefa 3.4: Marcar expenses históricas como ocorrências pagas
  - Para cada expense com is_fixed = true no histórico:
    → Criar RecurringOccurrence com status = paid, expense_id = expense.id
    → Isso dá histórico real para o forecasting desde o início
```

---

### PHASE 4 — UI de Recorrentes
**Objetivo**: Tela dedicada para gerenciar recorrentes.

```
Tarefa 4.1: RecurringScreen
  - Lista de recorrentes ativos por categoria
  - Valor mensal equivalente de cada um
  - Total de compromissos recorrentes mensais em destaque
  - Filtros: Ativos / Pausados / Cancelados

Tarefa 4.2: Detalhe do recorrente
  - Histórico de ocorrências (pagas/puladas/pendentes)
  - Botões: Editar / Pausar / Cancelar
  - Próximas ocorrências: lista dos próximos 3 meses
  - Edição de ocorrência única (sem alterar a regra)
  - Edição "desta e futuras" (altera a regra a partir de uma data)

Tarefa 4.3: Fluxo de criação
  - Bottom sheet: nome, valor, categoria, frequência, dia do mês, início
  - Preview: "Próximas ocorrências: 10/fev, 10/mar, 10/abr"
  - Opção: adicionar ao envelope do período automaticamente

Tarefa 4.4: Dashboard — RecurringCard
  - Substituir o antigo alert de "gastos copiados"
  - Mostrar: "R$X em recorrentes este período (N confirmados)"
  - Parcelas pendentes do período atual com botão "Registrar"
```

---

### PHASE 5 — Detecção Automática
**Objetivo**: O engine detecta padrões recorrentes no histórico.

```
Tarefa 5.1: RecurringDetector.detect(List<Expense> history)
  - Agrupar por (store_description, category, ~amount)
    → ~amount: variação de ±5% é considerada o mesmo recorrente
  - Para cada grupo com >= 3 ocorrências:
    → Calcular intervalos entre datas
    → Detectar frequência dominante (mensal, semanal, etc.)
    → Calcular consistência (desvio padrão dos intervalos)
    → confidence = consistência × (1 - variância_do_valor × 0.5)
  - Retornar List<RecurringRuleCandidate> com confidence >= 0.75

Tarefa 5.2: UI de sugestão (não-invasiva)
  - Card discreto no dashboard: "Encontrei 3 possíveis recorrentes"
  - Tap → tela de sugestões com [Confirmar] [Editar] [Ignorar]
  - Ao confirmar: cria RecurringRule + marca ocorrências históricas como pagas
  - Ao ignorar: não perguntar novamente por 30 dias para esse padrão

Tarefa 5.3: Limites do detector
  - Mínimo 3 ocorrências com confidence >= 0.75 para sugerir
  - Não sugerir se o usuário já tem uma RecurringRule similar
  - Não interromper o fluxo de entrada de gastos
```

---

## 🚨 Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Migração de isFixed gera RecurringRules duplicadas | Alta | Dados sujos | Agrupar por (category, store_description) antes de criar |
| RecurrenceResolver com bugs de calendário (ex: fevereiro) | Alta | Datas erradas | Testes exaustivos de edge cases de calendário |
| Detector sugere recorrentes falso-positivos | Média | Usuário desconfiante | Threshold de confidence alto (0.75) + opção "ignorar sempre" |
| Muitas ocorrências geradas (regra sem fim × 3 meses) | Média | Uso excessivo de storage | Gerar apenas 3 meses à frente; regenerar sob demanda |
| `fixedExpensePropagationProvider` removido antes do RecurringEngine estar estável | Alta | Gastos fixos desaparecem | Remover apenas na Phase 3, depois de RecurringEngine validado |

---

## ✅ Checklist de Completude

### Phase 1 — RecurrenceResolver
- [ ] `RecurringRule` entity com nextOccurrenceDate()
- [ ] `RecurrenceResolver.generateOccurrences()` implementado
- [ ] Edge cases: fevereiro, ends_after_n, paused_until
- [ ] Testes unitários: todas as frequências corretas

### Phase 2 — Schema + Repositórios
- [ ] Tabelas `recurring_rules` e `recurring_occurrences` em Supabase
- [ ] RLS e índices configurados
- [ ] Repositórios com getPendingInRange() para ObligationEngine
- [ ] Job de geração de ocorrências (idempotente)

### Phase 3 — Migração
- [ ] gastos isFixed → RecurringRules criadas
- [ ] `fixedExpensePropagationProvider` removido
- [ ] SnackBar de "gastos copiados" removido
- [ ] Dashboard não copia mais — projeta recorrentes

### Phase 4 — UI
- [ ] RecurringScreen com lista + totais
- [ ] Detalhe com histórico e próximas ocorrências
- [ ] Fluxo de criação com preview
- [ ] RecurringCard no dashboard

### Phase 5 — Detecção Automática
- [ ] `RecurringDetector.detect()` com confidence scoring
- [ ] Card de sugestões não-invasivo no dashboard
- [ ] Ao confirmar: cria regra + marca histórico como pago
- [ ] Documentar em `docs/decisions/006-recurring-rules.md`

---

## 📎 Referências

- Análise detalhada: `FAROL_PREDICTIVE_ENGINE.md` → Seção 5
- ADR pendente: `docs/decisions/006-recurring-rules.md`
- Depends on: `categories_redesign.md` (complete) · `financial_engine.md` Phase 1-2
- Desbloqueia: `forecasting.md` (ObligationEngine lê recurring_occurrences)
