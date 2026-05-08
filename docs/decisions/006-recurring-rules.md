# ADR-006: Recurring Rules Engine — Substituição do isFixed+copy

**Fecha**: 2026-05-07
**Estado**: Propuesto — pendiente de implementación
**Área**: Domain · Database · UI

---

## Contexto

O único mecanismo de recorrência atual é `fixedExpensePropagationProvider`: ao abrir um novo mês, os gastos com `isFixed = true` são copiados do mês anterior. Um SnackBar notifica o usuário: "X gastos fixos copiados do mês anterior".

Problemas concretos:
- Valor variável (aluguel que sobe) → a cópia usa o valor antigo
- Sem frequências alternativas (semanal, semestral, anual)
- Sem pausa/cancelamento sem deletar
- Sem data de início futura
- Gastos futuros não existem no DB → ForecastingEngine cego para recorrentes
- A UX de "copiar expenses" é frágil: se o usuário não abrir o mês, os gastos não existem

## Decisão

**Substituir o mecanismo `isFixed + copy` por um motor real de recorrência**:

1. `RecurringRule` — define o template do recorrente (frequência, valor, vigência)
2. `RecurringOccurrence` — instâncias concretas geradas pela regra para um date range
3. `RecurrenceResolver` — algoritmo puro Dart que gera ocorrências a partir de uma regra

As ocorrências são geradas proativamente para os próximos 3 meses ao abrir o app. O `ObligationEngine` do `ForecastingEngine` lê `recurring_occurrences WHERE status = 'pending'` para calcular obrigações futuras.

`fixedExpensePropagationProvider` é removido após migração dos gastos `isFixed = true` para `RecurringRule`.

## Consequências

### Positivas
- ForecastingEngine tem visibilidade de recorrentes futuros (sem eles, projeção está errada em R$2.000+/mês)
- Suporte a frequências reais: mensal, semanal, quinzenal, semestral, anual
- Pausa com data de reativação automática
- Valor variável: `amount_type = 'range'` usa a média, `'variable'` usa histórico
- Detecção automática de padrões recorrentes no histórico
- Histórico real: ocorrências antigas marcadas como `paid` com link para o expense original

### Negativas / Trade-offs
- Migração dos gastos `isFixed = true` exige script + revisão manual (alguns podem não ser realmente recorrentes)
- `fixedExpensePropagationProvider` não pode ser removido antes do RecurringEngine estar estável em produção
- O usuário precisa aprender o novo conceito (RecurringRule vs Expense manual)

### Riscos aceitos
- **Migração cria RecurringRules duplicadas**: se o usuário tinha o mesmo recorrente em múltiplos meses como expenses separadas → o agrupamento por `(category, store_description)` pode criar duplicatas. Mitigado com step de revisão no onboarding pós-migração.

## Alternativas Consideradas

### Melhorar `isFixed + copy` (adicionar frequência, valor variável)
Adicionar campo `recurrence_type` ao `Expense` e melhorar o mecanismo de cópia.

**Descartada porque**: O modelo `Expense` representa uma transação passada — não um template de recorrência. Misturar os dois conceitos no mesmo modelo aumenta a deuda técnica. O mecanismo de cópia nunca produz ocorrências futuras, impedindo o forecasting.

### Usar biblioteca de RRULE (RFC 5545)
Adotar uma biblioteca existente de recorrência (como o padrão iCalendar RRULE).

**Avaliada positivamente mas descartada para v1**: RRULE é muito poderoso para os casos de uso do Farol (a maioria é mensal/semanal/anual). A implementação própria cobre 99% dos casos com muito menos complexidade. Pode ser adotada em v2 se o RecurrenceResolver mostrar limitações.

## Critérios de Sucesso

- [ ] `RecurrenceResolver.generateOccurrences()` com testes para todas as frequências suportadas
- [ ] `fixedExpensePropagationProvider` removido e SnackBar de "gastos copiados" eliminado
- [ ] `ObligationEngine` lê `recurring_occurrences` pendentes e retorna obrigações corretas
- [ ] Detecção automática com precision >= 80% nos testes com dados reais

## Referências

- Plano: `plans/recurring_rules.md`
- Desbloqueia: `plans/forecasting.md` (ObligationEngine)
- Depende de: ADR-001 (CategoryRef) · ADR-002 (FinancialSnapshot)
