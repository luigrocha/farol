# Plan: Installments Redesign (Cuotas/Parcelas)
**Area**: Domain · Database · Repositories · UI
**Prioridade**: P1 — bloqueia o Forecasting Engine
**Dependências**: `categories_redesign.md` Phase 1-2 (category_id disponível)
**Arquivos impactados**: `card_installment.dart`, `installment_repository.dart`, `add_installment_bottom_sheet.dart`, `installments_screen.dart`, `app_database.dart`

---

## 🔍 Contexto do Problema

### Estado atual (confirmado no código)

```dart
// PROBLEMA CENTRAL: CardInstallment e Expense são mundos paralelos

// CardInstallment rastreia o plano — mas não gera expenses automaticamente
class CardInstallment {
  final int currentInstallment;  // contador manual
  final int numInstallments;
  final double monthlyAmount;
  // Não tem: due_date, link para expenses reais, histórico de pagamentos
}

// Expense tem installmentPlanId — mas CardInstallments não referencia expenses
class Expense {
  final int? installmentPlanId;  // campo existe mas não é usado de forma coerente
  // Não tem: installment_num, link bidirecional com o plano
}

// O fluxo atual:
// 1. Usuário registra expense de R$100 (1a parcela) — manualmente
// 2. Usuário cria CardInstallment com numInstallments=12 — separadamente
// 3. Todo mês: usuário faz advance() manualmente
// 4. Meses futuros: sem expenses registradas → forecasting cego
```

```dart
// InstallmentRepository.advance() — avanço manual, sem automação
Future<void> advance(int id, int newCurrent, int numInstallments) async {
  final newStatus = newCurrent >= numInstallments ? 'Settled' : 'Active';
  await _supabase.from('card_installments').update({
    'current_installment': newCurrent,
    'status': newStatus,
  }).eq('id', id);
  // Não cria expense, não atualiza forecasting, não gera histórico
}
```

### Por que isso bloqueia o Forecasting

O `ForecastingEngine` precisa saber: "nos próximos 6 meses, quais são os compromissos financeiros confirmados?". Com o modelo atual:
- R$800/mês em 10 parcelas ativas → o engine não sabe de nenhuma dessas parcelas futuras
- A projeção de saldo fica errada em R$8.000 (10 × R$800) para os próximos meses

---

## 📐 Modelo Correto: InstallmentPlan + InstallmentPayments

### Diagrama conceitual

```
InstallmentPlan (a compra original)
  │ id, description, total_amount, num_installments
  │ purchase_date, first_due_date, status (active/completed/cancelled)
  │
  └─── InstallmentPayment (cada parcela — gerada automaticamente)
         installment_num: 1, due_date: 2026-02-10, amount: R$800, status: pending
         installment_num: 2, due_date: 2026-03-10, amount: R$800, status: pending
         ...
         installment_num: 10, due_date: 2026-11-10, amount: R$800, status: pending
                │
                └── Expense (criada ao marcar como paga)
                      transaction_date: 2026-02-10
                      amount: R$800
                      installment_plan_id: <uuid>
                      installment_payment_id: <uuid>
```

### Schema Supabase

```sql
-- Plano mãe: a compra original
CREATE TABLE installment_plans (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES auth.users(id) NOT NULL,
  category_id         UUID REFERENCES categories(id),

  -- Descrição da compra
  description         TEXT NOT NULL,
  store_name          TEXT,
  purchase_date       DATE NOT NULL,

  -- Valores
  total_amount        NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
  num_installments    INT NOT NULL CHECK (num_installments >= 2),
  installment_amount  NUMERIC(12,2) NOT NULL,  -- valor base (sem a diferença de arredondamento)

  -- Método de pagamento
  payment_method      TEXT NOT NULL,           -- 'CREDIT_ITAU', 'CREDIT_NUBANK', etc.

  -- Calendário
  first_due_date      DATE NOT NULL,           -- data do 1º vencimento

  -- Estado
  status              TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'completed', 'cancelled', 'paused')),

  -- Link retroativo para o expense da compra original (opcional)
  original_expense_id UUID REFERENCES expenses(id),

  -- Migração: referência ao card_installments antigo
  legacy_card_installment_id INT,

  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Parcelas individuais — geradas automaticamente ao criar o plano
CREATE TABLE installment_payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id         UUID REFERENCES installment_plans(id) ON DELETE CASCADE NOT NULL,
  user_id         UUID REFERENCES auth.users(id) NOT NULL,

  -- Identificação da parcela
  installment_num INT NOT NULL CHECK (installment_num >= 1),
  due_date        DATE NOT NULL,
  amount          NUMERIC(12,2) NOT NULL,  -- pode diferir na última (arredondamento)

  -- Estado
  status          TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'overdue', 'skipped')),
  paid_date       DATE,
  paid_amount     NUMERIC(12,2),           -- pode diferir do amount (pagamento parcial)

  -- Link para a transação real (criada ao pagar)
  expense_id      UUID REFERENCES expenses(id),

  -- Cache do período financeiro desta parcela
  financial_period_start  DATE,
  financial_period_end    DATE,

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(plan_id, installment_num)
);

-- Índices para performance do ForecastingEngine
CREATE INDEX idx_installment_payments_due_date
  ON installment_payments(user_id, due_date, status)
  WHERE status = 'pending';

CREATE INDEX idx_installment_payments_period
  ON installment_payments(user_id, financial_period_start, financial_period_end);
```

---

## ⚡ Análise de Impacto

### Arquivos a criar (novos)
```
lib/core/domain/entities/installment_plan.dart
lib/core/domain/entities/installment_payment.dart
lib/core/domain/services/installment_service.dart
lib/core/repositories/installment_plan_repository.dart
lib/core/repositories/installment_payment_repository.dart
```

### Arquivos a modificar
```
lib/core/database/app_database.dart            ← nova tabela Drift (migration v3)
lib/features/installments/installments_screen.dart  ← migrar para novo modelo
lib/features/installments/add_installment_bottom_sheet.dart  ← novo fluxo
lib/core/models/expense.dart                   ← campos installment_payment_id
```

### Arquivos a deprecar (gradualmente)
```
lib/core/models/card_installment.dart          ← substituído por InstallmentPlan
lib/core/repositories/installment_repository.dart  ← substituído por novos repos
```

### Breaking Changes

| Mudança | Severidade | Mitigação |
|---|---|---|
| `card_installments` → `installment_plans + payments` | 🔴 ALTO | Migração gradual com tabela legado em paralelo |
| `InstallmentRepository.advance()` → `payInstallment()` | 🟡 MÉDIO | Manter `advance()` como wrapper durante transição |
| UI de installments completamente remodelada | 🟡 MÉDIO | Feature flag para novo UI |

---

## 🗺️ Estratégia Incremental

```
analisa → propõe → valida → phase 1 → review → phase 2 → review → ...
```

### PHASE 1 — Schema + Entidades (sem UI)
**Objetivo**: Criar a infraestrutura nova sem quebrar nada existente.
**Reversibilidade**: 100% — apenas novos arquivos e tabelas.

```
Tarefa 1.1: Schema Supabase
  - CREATE TABLE installment_plans (...)
  - CREATE TABLE installment_payments (...)
  - Índices para ForecastingEngine
  - RLS policies (user_id = auth.uid())

Tarefa 1.2: Entidades Dart
  - lib/core/domain/entities/installment_plan.dart
    → InstallmentPlan com todos os campos + computed properties
    → remainingPayments, remainingAmount, progressPercent
    → isComplete, isActive, isOverdue
  - lib/core/domain/entities/installment_payment.dart
    → InstallmentPayment com daysUntilDue computed
    → isOverdue: due_date < today && status == 'pending'

Tarefa 1.3: Repositórios básicos
  - InstallmentPlanRepository.create(), getActive(), watchAll()
  - InstallmentPaymentRepository.getPending(), getByPlan(), getPendingInRange()
```

**Teste de sucesso**: As novas tabelas existem em Supabase, os repositórios fazem CRUD básico.

---

### PHASE 2 — InstallmentService (a lógica central)
**Objetivo**: O serviço que orquestra criação de plano + geração automática de parcelas.

```
Tarefa 2.1: InstallmentService.createPurchase()
  - Recebe: description, purchaseDate, totalAmount, numInstallments, categoryId, paymentMethod
  - Calcula: installmentAmount com arredondamento correto
    → base = (total / n * 100).floor() / 100
    → remainder = total - (base * n)
    → última parcela = base + remainder
  - Calcula: firstDueDate (se não informado, próximo dia de vencimento do cartão)
  - Cria: 1 InstallmentPlan + N InstallmentPayments automaticamente
  - Evento: InstallmentPlanCreated → ForecastingEngine invalida cache

Tarefa 2.2: InstallmentService.payInstallment()
  - Recebe: paymentId, actualPaidDate?, actualAmount?
  - Cria: Expense real vinculado à parcela
  - Atualiza: InstallmentPayment → status: paid, paid_date, expense_id
  - Verifica: se última parcela → plan.status = completed
  - Evento: InstallmentPaid → ForecastingEngine invalida cache

Tarefa 2.3: InstallmentService.skipInstallment()
  - Marca parcela como skipped com nota
  - Não cria expense

Tarefa 2.4: Testes do InstallmentService
  - createPurchase(R$1200, 12x) → 12 InstallmentPayments de R$100
  - createPurchase(R$1000, 3x) → 2x R$333 + 1x R$334 (arredondamento correto)
  - payInstallment() → cria Expense, atualiza status
  - payInstallment() na última → fecha o plano
```

---

### PHASE 3 — Migração dos card_installments existentes
**Objetivo**: Converter dados existentes para o novo modelo.

```
Tarefa 3.1: Script de migração Supabase
  -- Para cada card_installment ativo:
  -- 1. Criar installment_plan
  INSERT INTO installment_plans (user_id, description, total_amount, num_installments,
    installment_amount, purchase_date, first_due_date, status, legacy_card_installment_id)
  SELECT user_id, description, total_value, num_installments,
    monthly_amount, purchase_date,
    -- estima o first_due_date a partir de purchase_date
    purchase_date + interval '1 month',
    CASE WHEN status = 'Active' THEN 'active' ELSE 'completed' END,
    id
  FROM card_installments;

  -- 2. Criar installment_payments para os meses restantes
  -- (parcelas já pagas: status = paid; futuras: status = pending)

Tarefa 3.2: Verificação pós-migração
  - COUNT: card_installments = COUNT installment_plans com legacy_id
  - Verificar: remainingPayments correto em todos os planos migrados
  - Verificar: total_amount = installment_amount * num_installments

Tarefa 3.3: Modo de compatibilidade
  - InstallmentRepository (antigo) funciona em modo read-only
  - Novos creates vão pelo InstallmentService
  - Advance() redireciona para payInstallment()
```

---

### PHASE 4 — Nova UI de Installments
**Objetivo**: UI que reflete o novo modelo e melhora a experiência.

```
Tarefa 4.1: InstallmentsScreen remodelada
  - Lista de planos ativos com progresso (ex: "iPhone 15 — 4/12 pagas")
  - Destaque para parcelas do mês atual
  - Filtros: Ativo / Concluído / Todos
  - Total de compromissos ativos em destaque

Tarefa 4.2: Detalhe do plano
  - Timeline de todas as parcelas (pagas / pendentes / futuras)
  - Botão "Registrar pagamento" para parcelas do período atual
  - Botão "Pular parcela" para exceções
  - Projeção: "Termina em março/2027"

Tarefa 4.3: Fluxo de nova compra parcelada
  - add_installment_bottom_sheet.dart remodelado
  - Campos: descrição, valor total, número de parcelas, data da compra, 1º vencimento
  - Preview das parcelas antes de confirmar
  - Cálculo automático do valor por parcela (com arredondamento visível)

Tarefa 4.4: Dashboard — InstallmentsSummaryCard
  - Mostrar parcelas do período atual (não apenas o total de cuotas ativas)
  - Diferenciar: pagas no período vs. pendentes no período
  - Link para ver detalhes
```

---

### PHASE 5 — Integração com Forecasting
**Objetivo**: O ForecastingEngine lê installment_payments pendentes.
**Pre-condição**: `forecasting.md` Phase 1-2 iniciados.

```
Tarefa 5.1: ObligationEngine.getScheduledPayments()
  - Fonte 1: installment_payments WHERE status = 'pending' AND due_date IN range
  - Retorna: List<ScheduledPayment> com due_date e amount
  - Usado pelo ForecastingEngine para projeção de saldo

Tarefa 5.2: EnvelopeEngine — envelopes automáticos para parcelas
  - Para cada InstallmentPlan ativo → criar envelope read-only no período
  - Envelope tipo 'obligation' — não editável pelo usuário
  - Valor = soma das parcelas do período

Tarefa 5.3: Dashboard — projeção de parcelas futuras
  - Chart: drops visíveis nas datas de vencimento das parcelas
  - Badge "R$X em parcelas esta semana"
```

---

## 🚨 Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Migração de card_installments com dados inconsistentes | Média | Dados errados | Script de verificação pós-migração antes de deprecar |
| Arredondamento incorreto em parcelas | Alta | Centavos perdidos | Teste explícito: soma das parcelas == total_amount |
| UI nova confunde usuários habituados ao fluxo antigo | Média | Abandono da feature | Feature flag: novo UI apenas para novos planos inicialmente |
| due_date calculado incorretamente na migração | Alta | Parcelas nos meses errados | Deixar firstDueDate como campo editável no onboarding do plano |
| Expense duplicada (via advance() legado + payInstallment() novo) | Baixa | Dados duplicados | Desativar advance() quando plano tem payments no novo modelo |

---

## ✅ Checklist de Completude

### Phase 1 — Schema + Entidades
- [ ] Tabelas `installment_plans` e `installment_payments` criadas em Supabase
- [ ] RLS policies configuradas
- [ ] Índices de performance criados
- [ ] `InstallmentPlan` e `InstallmentPayment` entities em Dart
- [ ] Repositórios básicos funcionando

### Phase 2 — InstallmentService
- [ ] `createPurchase()` gera N parcelas automaticamente
- [ ] Arredondamento correto: soma das parcelas == total
- [ ] `payInstallment()` cria Expense vinculada
- [ ] Última parcela fecha o plano
- [ ] Testes: arredondamento, fechamento, edge cases

### Phase 3 — Migração
- [ ] Script de migração executado em Supabase
- [ ] Verificação: 0 planos com dados inconsistentes
- [ ] `advance()` redireciona para `payInstallment()`

### Phase 4 — Nova UI
- [ ] InstallmentsScreen com lista de planos + progresso
- [ ] Timeline de parcelas no detalhe do plano
- [ ] Fluxo de nova compra com preview de parcelas
- [ ] Dashboard mostra parcelas do período atual

### Phase 5 — Forecasting
- [ ] `ObligationEngine` lê installment_payments pendentes
- [ ] Envelopes automáticos para planos ativos
- [ ] Documentar em `docs/decisions/005-installments-redesign.md`

---

## 📎 Referências

- Análise detalhada: `FAROL_PREDICTIVE_ENGINE.md` → Seção 6
- ADR pendente: `docs/decisions/005-installments-redesign.md`
- Depends on: `categories_redesign.md` (Phase 1-2)
- Desbloqueia: `forecasting.md` (ObligationEngine), `financial_engine.md` (Phase 5)
