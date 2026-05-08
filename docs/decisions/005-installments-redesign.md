# ADR-005: Redesign de Cuotas — InstallmentPlan + InstallmentPayments

**Fecha**: 2026-05-07
**Estado**: Propuesto — pendiente de implementación
**Área**: Domain · Database · Repositories

---

## Contexto

`CardInstallment` e `Expense` são entidades completamente independentes. O `Expense.installmentPlanId` existe no modelo Dart mas `CardInstallments` não tem referência bidirecional para expenses. O avance é manual via `advance()`. Os meses futuros não têm expenses registradas até o usuário fazer `advance()` manualmente.

Isso significa que o `ForecastingEngine` (planejado) não consegue ver compromissos futuros de parcelas — que podem somar R$5.000+/mês para usuários ativos. A projeção de saldo fica fundamentalmente incorreta.

## Decisão

**Substituir `card_installments` por dois modelos relacionados**:

1. `InstallmentPlan` — representa a compra original (a "cabeça" do parcelamento)
2. `InstallmentPayment` — representa cada parcela individual, **gerada automaticamente** ao criar o plano

Ao criar uma compra de R$1.200 em 12x, o sistema gera imediatamente 12 `InstallmentPayment` com `due_date` correto para cada mês. O `ForecastingEngine` lê esses registros com status `pending` para calcular obrigações futuras.

Ao marcar uma parcela como paga, o sistema cria automaticamente um `Expense` vinculado — não o contrário.

## Consequências

### Positivas
- `ForecastingEngine` tem visibilidade completa de obrigações futuras
- Sem necessidade de `advance()` manual — o sistema sabe quais parcelas vencem quando
- Histórico completo de pagamentos por plano (pagas, puladas, atrasadas)
- Arredondamento correto: última parcela absorbe diferença de centavos
- Relatórios precisos: "você tem R$X em parcelas para os próximos 6 meses"

### Negativas / Trade-offs
- Migração de dados existentes (`card_installments` → novo modelo) com risco de inconsistências
- `first_due_date` na migração precisa ser estimado (não existe no modelo antigo)
- A UI de installments precisa ser refeita — mais trabalho de design

### Riscos aceitos
- **Migração incompleta**: planos migrados sem firstDueDate correto → parcelas nos meses errados. Mitigado com campo `legacy_card_installment_id` para rastreabilidade e opção de editar a data após migração.

## Alternativas Consideradas

### Manter `card_installments` com melhorias
Adicionar `due_date` e `expense_id` ao modelo existente.

**Descartada porque**: O modelo `card_installments` é plano (flat) — não tem relação pai/filho. Adicionar parcelas individuais exigiria a mesma nova tabela `installment_payments`, tornando o modelo antigo desnecessário.

### Gerar expenses futuras (uma por mês)
Criar automaticamente um `Expense` futuro com `isProjected = true` para cada parcela.

**Descartada porque**: Polui a lista de transações com dados projetados. O campo `isProjected` já existe mas nunca foi usado coerentemente. `InstallmentPayment` é um conceito distinto de `Expense` — misturá-los cria ambiguidade.

## Critérios de Sucesso

- [ ] Criar compra parcelada → N pagamentos gerados automaticamente com due_dates corretos
- [ ] Soma de todos os `installment_payments.amount` == `installment_plans.total_amount`
- [ ] `ForecastingEngine` lê `getPendingInRange()` e retorna obrigações corretas
- [ ] `advance()` antigo redireciona para `payInstallment()` sem breaking changes na UI

## Referências

- Plano: `plans/installments_redesign.md`
- Desbloqueia: `plans/forecasting.md` (ObligationEngine)
- Depende de: ADR-001 (category_id disponível para installment_plans)
