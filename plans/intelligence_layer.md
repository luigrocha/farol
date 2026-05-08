# Plan: Budget Intelligence Layer (Copiloto Financeiro)
**Área**: Domain · Analytics · UI
**Prioridade**: P6 — o toque final do produto
**Dependências**: `forecasting.md` (completo) · `recurring_rules.md` (Fase 2+) · `installments_redesign.md` (Fase 2+)
**Arquivos impactados**: Novos em `lib/core/domain/`, novos widgets no dashboard

---

## 🔍 Contexto e Motivação

### O que o produto precisa

Farol com Financial Engine + Forecasting já é melhor que 95% dos apps de finanças. A Intelligence Layer é o que transforma Farol de "ótima ferramenta" em "copiloto financeiro indispensável".

A diferença:
- **Ferramenta**: "Você gastou R$840 em Lazer este mês"
- **Copiloto**: "Você está 43% acima do seu ritmo usual em Lazer — se continuar, vai superar o orçamento em 8 dias"

### Princípio: Não é IA, é inteligência contextual

Esta camada é **100% determinista e baseada em regras**. Não há LLM, não há modelos de ML, não há chamadas a APIs externas. É um conjunto de regras especialistas que operam sobre os dados reais do usuário.

Isso garante:
- Funciona offline
- Resultados reproduzíveis e explicáveis
- Zero custo por request
- Sem alucinações

ML pode ser adicionado em v2+ como camada adicional, mas as regras deterministas são a base.

---

## 📐 Arquitetura da Intelligence Layer

### Estrutura de um Insight

```dart
class FinancialInsight {
  final String id;
  final InsightType type;
  final InsightPriority priority;   // critical | warning | info | achievement
  final String title;               // curto, max 40 chars
  final String body;                // explicação detalhada
  final String? actionLabel;        // "Ver Lazer" | "Ajustar orçamento" | null
  final String? actionRoute;        // rota para navegar ao tap
  final double confidence;          // 0.0 – 1.0
  final Map<String, dynamic> data;  // dados de suporte (para debug e analytics)
  final DateTime generatedAt;
  final DateTime? expiresAt;        // alguns insights têm prazo de validade
  final bool isDismissable;
  final String? dismissGroup;       // ao dispensar, dispensa todos do grupo
}

enum InsightType {
  // Alertas preventivos (vermelho/laranja)
  overdraftRisk,        // risco de fechar período negativo
  liquidityAlert,       // dinheiro curto nos próximos 7 dias
  budgetOverrun,        // categoria vai superar o orçamento

  // Padrões detectados (amarelo)
  spendingSpike,        // gasto muito acima do histórico em categoria
  subscriptionCreep,    // assinaturas aumentaram nos últimos 3 meses
  duplicateCharge,      // cobrança duplicada provável
  unusualMerchant,      // primeira compra neste estabelecimento por valor alto

  // Oportunidades (azul/verde)
  savingsOpportunity,   // categoria com excesso vs histórico = economia possível
  earlyPayoff,          // pagamento antecipado reduziria meses de parcelas
  investmentOpportunity,// saldo livre > umbral → sugestão de investir

  // Conquistas (verde)
  budgetStreak,         // N períodos consecutivos dentro do orçamento
  savingsRecord,        // melhor poupança do histórico
  debtReduction,        // parcelas ativas reduziram significativamente
  categoryUnderControl, // categoria problemática voltou ao normal
}

enum InsightPriority { critical, warning, info, achievement }
```

### Regras do Motor (as 12 regras core)

```dart
class IntelligenceLayer {

  // REGRA 1: Risco de saldo negativo ao final do período
  FinancialInsight? _checkOverdraftRisk(FinancialSnapshot snapshot) {
    final projected = snapshot.projection?.projectedClosingBalance;
    if (projected == null || !projected.isNegative) return null;

    return FinancialInsight(
      type: InsightType.overdraftRisk,
      priority: InsightPriority.critical,
      title: 'Risco de saldo negativo',
      body: 'Com o ritmo atual, você fechará o período com ${projected.formatted}. '
            'Há ${snapshot.totalFutureObligations.formatted} em compromissos confirmados.',
      actionLabel: 'Ver projeção',
      actionRoute: '/analytics/cashflow',
      confidence: 0.85,
      expiresAt: snapshot.period.end,  // expira no fim do período
    );
  }

  // REGRA 2: Liquidez crítica nos próximos 7 dias
  FinancialInsight? _checkLiquidityAlert(FinancialSnapshot snapshot) {
    final risk = snapshot.projection?.liquidityRisk;
    if (risk == null || risk.index < LiquidityRisk.medium.index) return null;

    final next7Days = snapshot.upcomingPayments
        .where((p) => p.daysFromNow <= 7)
        .map((p) => p.amount)
        .fold(Money.zero, (a, b) => a + b);

    return FinancialInsight(
      type: InsightType.liquidityAlert,
      priority: risk == LiquidityRisk.critical
          ? InsightPriority.critical
          : InsightPriority.warning,
      title: risk == LiquidityRisk.critical ? 'Semana muito apertada' : 'Semana apertada',
      body: 'Você tem ${snapshot.currentBalance.formatted} disponível e '
            '${next7Days.formatted} em pagamentos esta semana.',
      confidence: 0.95,
    );
  }

  // REGRA 3: Categoria acima do ritmo histórico (spike)
  List<FinancialInsight> _checkSpendingSpikes(FinancialSnapshot snapshot) {
    return snapshot.categoryVelocities
        .where((v) => v.deviationPercent > 40 && v.currentSpend.amount > 30)
        .map((v) => FinancialInsight(
          type: InsightType.spendingSpike,
          priority: InsightPriority.warning,
          title: 'Aceleração em ${v.category.name}',
          body: '${v.currentSpend.formatted} até agora vs. média de '
                '${v.historicalAverage.formatted}. '
                '${v.deviationPercent.round()}% acima do usual.',
          actionLabel: 'Ver ${v.category.name}',
          confidence: 0.80,
          data: {'categoryId': v.category.id, 'deviation': v.deviationPercent},
        ))
        .toList();
  }

  // REGRA 4: Cobrança duplicada provável
  List<FinancialInsight> _detectDuplicates(List<Expense> recentExpenses) {
    final candidates = <FinancialInsight>[];
    final groups = _groupSimilarExpenses(recentExpenses);

    for (final group in groups) {
      if (group.length < 2) continue;
      final sorted = group..sort((a, b) => a.date.compareTo(b.date));
      final daysBetween = sorted.last.date.difference(sorted.first.date).inDays;

      if (daysBetween <= 3 && group.length >= 2) {
        candidates.add(FinancialInsight(
          type: InsightType.duplicateCharge,
          priority: InsightPriority.warning,
          title: 'Possível cobrança duplicada',
          body: '${group.length}x "${group.first.storeDescription}" '
                'por ${group.first.amount.formatted} em ${daysBetween} dias.',
          actionLabel: 'Verificar',
          confidence: _calculateDuplicateConfidence(group, daysBetween),
          isDismissable: true,
          dismissGroup: 'duplicate_${group.first.storeDescription}',
        ));
      }
    }
    return candidates;
  }

  // REGRA 5: Assinaturas crescendo (subscription creep)
  FinancialInsight? _checkSubscriptionCreep(
    List<List<Envelope>> lastThreePeriods,
  ) {
    final subscriptionCategory = 'subscriptions';
    final amounts = lastThreePeriods
        .map((envelopes) => envelopes
            .firstWhereOrNull((e) => e.category.slug == subscriptionCategory)
            ?.spent ?? Money.zero)
        .toList();

    if (amounts.length < 3) return null;
    final growth = (amounts.last.amount - amounts.first.amount);
    if (growth < 50) return null;  // crescimento < R$50 não é relevante

    return FinancialInsight(
      type: InsightType.subscriptionCreep,
      priority: InsightPriority.info,
      title: 'Assinaturas crescendo',
      body: 'Seus gastos com assinaturas aumentaram '
            '${FinancialCalculatorService.formatBRL(growth)} '
            'nos últimos 3 períodos.',
      actionLabel: 'Ver assinaturas',
      confidence: 0.75,
    );
  }

  // REGRA 6: Oportunidade de poupança (categoria com excesso recorrente)
  List<FinancialInsight> _findSavingsOpportunities(
    List<EnvelopeStatus> envelopes,
    List<List<Envelope>> history,
  ) {
    return envelopes
        .where((e) => e.isOverspent && e.overspentAmount.amount > 50)
        .where((e) => _isChronicallyOverspent(e.category.id, history))
        .map((e) => FinancialInsight(
          type: InsightType.savingsOpportunity,
          priority: InsightPriority.info,
          title: 'Economia possível em ${e.category.name}',
          body: 'Você costuma gastar ${e.overspentAmount.formatted} acima do '
                'orçamento em ${e.category.name}. Ajustar o orçamento ou '
                'reduzir o gasto pode liberar ${e.overspentAmount.formatted}/período.',
          actionLabel: 'Ajustar orçamento',
          confidence: 0.65,
        ))
        .toList();
  }

  // REGRA 7: Investimento possível (saldo livre projetado > R$500)
  FinancialInsight? _checkInvestmentOpportunity(FinancialSnapshot snapshot) {
    final predicted = snapshot.projection?.predictedSavings;
    if (predicted == null || predicted.amount < 500) return null;

    return FinancialInsight(
      type: InsightType.investmentOpportunity,
      priority: InsightPriority.info,
      title: 'Você vai sobrar ${predicted.formatted}',
      body: 'Com base no seu ritmo atual, você terá ${predicted.formatted} '
            'livres no final do período. Que tal destinar uma parte?',
      actionLabel: 'Ver opções',
      confidence: 0.70,
    );
  }

  // REGRA 8: Conquista — N períodos dentro do orçamento
  FinancialInsight? _checkBudgetStreak(List<FinancialSnapshot> history) {
    final consecutiveUnderBudget = history
        .takeWhile((s) => !s.envelopes.any((e) => e.isOverspent))
        .length;

    if (consecutiveUnderBudget < 2) return null;

    return FinancialInsight(
      type: InsightType.budgetStreak,
      priority: InsightPriority.achievement,
      title: '$consecutiveUnderBudget períodos dentro do orçamento! 🎉',
      body: 'Você está mantendo suas finanças sob controle por '
            '$consecutiveUnderBudget períodos consecutivos.',
      confidence: 1.0,
      isDismissable: true,
    );
  }

  // REGRA 9: Melhor poupança do histórico
  FinancialInsight? _checkSavingsRecord(
    Money currentSavings,
    List<Money> historicalSavings,
  ) {
    if (historicalSavings.isEmpty) return null;
    final previousBest = historicalSavings.reduce(
        (a, b) => a.amount > b.amount ? a : b);

    if (currentSavings <= previousBest) return null;

    return FinancialInsight(
      type: InsightType.savingsRecord,
      priority: InsightPriority.achievement,
      title: 'Recorde de poupança! 🏆',
      body: 'Este período você está poupando ${currentSavings.formatted} — '
            'seu melhor resultado em ${historicalSavings.length} períodos.',
      confidence: 1.0,
    );
  }

  // REGRA 10: Redução de dívidas (parcelas ativas diminuíram)
  FinancialInsight? _checkDebtReduction(
    Money currentInstallmentTotal,
    Money previousInstallmentTotal,
  ) {
    final reduction = previousInstallmentTotal - currentInstallmentTotal;
    if (reduction.amount < 200) return null;  // redução < R$200 não é relevante

    return FinancialInsight(
      type: InsightType.debtReduction,
      priority: InsightPriority.achievement,
      title: 'Parcelas reduzindo!',
      body: 'Suas parcelas ativas caíram ${reduction.formatted} '
            'nos últimos 2 meses.',
      confidence: 0.9,
    );
  }

  // REGRA 11: Categoria problemática voltou ao normal
  FinancialInsight? _checkCategoryRecovery(
    CategoryVelocity velocity,
    List<CategoryVelocity> lastPeriod,
  ) {
    final previous = lastPeriod.firstWhereOrNull(
        (v) => v.category.id == velocity.category.id);
    if (previous == null) return null;
    if (previous.deviationPercent <= 30) return null;  // não estava problemática
    if (velocity.deviationPercent > 10) return null;   // ainda problemática

    return FinancialInsight(
      type: InsightType.categoryUnderControl,
      priority: InsightPriority.achievement,
      title: '${velocity.category.name} sob controle 👍',
      body: 'No período passado ${velocity.category.name} estava '
            '${previous.deviationPercent.round()}% acima do normal. '
            'Este período está dentro do ritmo habitual.',
      confidence: 0.80,
    );
  }

  // REGRA 12: Merchant desconhecido por valor alto
  FinancialInsight? _checkUnusualMerchant(
    Expense expense,
    List<Expense> history,
  ) {
    if (expense.amount.amount < 200) return null;  // só para valores > R$200
    final knownMerchants = history
        .map((e) => e.storeDescription?.toLowerCase())
        .whereNotNull()
        .toSet();

    final merchantKey = expense.storeDescription?.toLowerCase();
    if (merchantKey == null || knownMerchants.contains(merchantKey)) return null;

    return FinancialInsight(
      type: InsightType.unusualMerchant,
      priority: InsightPriority.info,
      title: 'Nova compra de alto valor',
      body: '"${expense.storeDescription}" por ${expense.amount.formatted} — '
            'primeira vez que aparece no seu histórico.',
      actionLabel: 'Ver gasto',
      confidence: 0.85,
      isDismissable: true,
    );
  }
}
```

### Orquestrador: análise e priorização

```dart
class IntelligenceLayer {
  static const _maxInsightsVisible = 3;
  static const _minConfidence = 0.60;

  List<FinancialInsight> analyze({
    required FinancialSnapshot current,
    required List<FinancialSnapshot> history,
    required List<Expense> recentExpenses,
  }) {
    final raw = <FinancialInsight>[];

    // Rodar todas as regras
    _checkOverdraftRisk(current)?.let(raw.add);
    _checkLiquidityAlert(current)?.let(raw.add);
    raw.addAll(_checkSpendingSpikes(current));
    raw.addAll(_detectDuplicates(recentExpenses));
    _checkSubscriptionCreep(history.map((s) => s.envelopes).toList())?.let(raw.add);
    raw.addAll(_findSavingsOpportunities(current.envelopes, history.map((s) => s.envelopes).toList()));
    _checkInvestmentOpportunity(current)?.let(raw.add);
    _checkBudgetStreak(history)?.let(raw.add);
    // ... restante das regras

    return raw
        .where((i) => i.confidence >= _minConfidence)
        .where((i) => !_isDismissed(i))       // filtrar dispensados pelo usuário
        .sorted(_byPriority)                   // critical primeiro
        .take(_maxInsightsVisible)             // máximo 3 visíveis
        .toList();
  }

  int _byPriority(FinancialInsight a, FinancialInsight b) {
    const order = [
      InsightPriority.critical,
      InsightPriority.warning,
      InsightPriority.info,
      InsightPriority.achievement,
    ];
    return order.indexOf(a.priority).compareTo(order.indexOf(b.priority));
  }
}
```

---

## ⚡ Análise de Impacto

### Arquivos a criar
```
lib/core/domain/entities/financial_insight.dart
lib/core/domain/services/intelligence_layer.dart
lib/core/repositories/dismissed_insights_repository.dart  ← persiste dispensas
lib/features/insights/insights_panel.dart                 ← widget do dashboard
lib/features/insights/insight_card.dart
lib/features/insights/insights_screen.dart                ← "Ver todos"
```

### Arquivos a modificar
```
lib/core/domain/entities/financial_snapshot.dart  ← insights: List<FinancialInsight>
lib/features/dashboard/dashboard_screen.dart       ← InsightsPanel widget
lib/features/dashboard/widgets/alert_banner.dart   ← substituído pelo InsightsPanel
```

---

## 🗺️ Estratégia Incremental

### FASE 1 — Foundation: Entidades + Regras Básicas
**Objetivo**: Infrastructure + as 4 regras de maior impacto.
**Reversibilidade**: 100% — código novo.

```
Tarefa 1.1: FinancialInsight entity + InsightType + InsightPriority enums

Tarefa 1.2: DismissedInsightsRepository
  - Persistir em UserSettings (Drift): chave = 'dismissed_insights', valor = JSON array
  - isDismissed(insightId | dismissGroup): bool
  - dismiss(insightId, dismissGroup?)
  - clearExpired()

Tarefa 1.3: IntelligenceLayer — 4 regras core
  1. _checkOverdraftRisk() — crítica, alta frequência de ativação
  2. _checkLiquidityAlert() — crítica, baseada em LiquidityRisk do Forecasting
  3. _checkSpendingSpikes() — warning, mais útil no dia a dia
  4. _checkInvestmentOpportunity() — info, engagement positivo

Tarefa 1.4: Integrar IntelligenceLayer no FinancialEngine
  - snapshot.insights = intelligenceLayer.analyze(current, history, recentExpenses)
```

---

### FASE 2 — InsightsPanel no Dashboard
**Objetivo**: Os insights aparecem na UI de forma não-invasiva.

```
Tarefa 2.1: InsightCard widget
  - Ícone de prioridade (🔴 crítico / 🟡 warning / 🔵 info / 🟢 conquista)
  - Título em negrito + corpo resumido
  - Botão de ação (se houver)
  - Botão X para dispensar (se isDismissable)

Tarefa 2.2: InsightsPanel widget
  - Mostra máximo 3 InsightCards
  - Se há mais: link "Ver todos (N)"
  - Se nenhum insight: não renderiza o panel (zero height)
  - Posição no dashboard: abaixo do PeriodBalanceHero, acima dos KPIs

Tarefa 2.3: InsightsScreen (Ver todos)
  - Lista completa de insights ativos
  - Agrupados por prioridade
  - Insights dispensados visíveis com opção "Restaurar"

Tarefa 2.4: Substituir AlertBanner existente
  - O AlertBanner atual (alerta de budget) é absorvido pelo InsightsPanel
  - Remover AlertBanner após InsightsPanel estável
```

---

### FASE 3 — Regras Avançadas
**Objetivo**: As 8 regras restantes.

```
Tarefa 3.1: _detectDuplicates() — cobrança duplicada
Tarefa 3.2: _checkSubscriptionCreep() — assinaturas crescendo
Tarefa 3.3: _findSavingsOpportunities() — economia possível
Tarefa 3.4: _checkBudgetStreak() — conquista de consistência
Tarefa 3.5: _checkSavingsRecord() — melhor poupança
Tarefa 3.6: _checkDebtReduction() — parcelas diminuindo
Tarefa 3.7: _checkCategoryRecovery() — categoria voltou ao normal
Tarefa 3.8: _checkUnusualMerchant() — compra incomum
```

---

### FASE 4 — Analytics de Insights
**Objetivo**: Medir se os insights são úteis.

```
Tarefa 4.1: InsightEvent tracking (local, sem analytics externo)
  - Registrar: shown, tapped, dismissed, expired
  - Tabela local em Drift: insight_events(type, action, timestamp)

Tarefa 4.2: Ajuste de thresholds baseado em dados reais
  - Se um tipo de insight tem dismiss rate > 60%: aumentar o threshold de confidence
  - Se um tipo tem tap rate > 40%: é muito útil, priorizar

Tarefa 4.3: InsightsHealthCard nas Settings
  - "Preferências de alertas" — usuário pode silenciar tipos de insight
  - Silenciar por: 7 dias / 30 dias / sempre
```

---

## 🚨 Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Muitos insights simultâneos → usuário ignora tudo | Alta | Inutilidade | Máximo 3 visíveis + prioridade estrita |
| Insights irrelevantes geram desconfiança | Alta | Abandono da feature | Threshold de confidence alto + opção de dispensar |
| Linguagem técnica ou assustadora | Média | Ansiedade do usuário | Review de copy para cada insight: humano, acionável, sem jargão |
| IntelligenceLayer sobrecarrega o ForecastingEngine | Média | Performance | Calcular insights em background após snapshot; cache TTL 10min |
| Alertas críticos mal calibrados (falso positivo) | Média | Perda de confiança | Testar cada regra com dados sintéticos antes de produção |
| "Cobrança duplicada" acusa transações legítimas | Alta | Irritação | Threshold: mesma loja + mesmo valor + ≤3 dias → confidence base 0.70, só sugere com 0.70+ |

---

## ✅ Checklist de Completude

### Fase 1 — Foundation
- [ ] `FinancialInsight` entity completa
- [ ] `DismissedInsightsRepository` com persistência em Drift
- [ ] 4 regras core implementadas e testadas
- [ ] Integrado no `FinancialSnapshot`

### Fase 2 — UI
- [ ] `InsightCard` widget com todos os estados visuais
- [ ] `InsightsPanel` no dashboard (máximo 3)
- [ ] `InsightsScreen` para ver todos
- [ ] `AlertBanner` antigo removido

### Fase 3 — Regras Avançadas
- [ ] Todas as 12 regras implementadas
- [ ] Cada regra testada com dados sintéticos (true positive + false positive)
- [ ] Dismiss rate < 40% em uso real (indicador de relevância)

### Fase 4 — Analytics
- [ ] `InsightEvent` tracking local
- [ ] Thresholds ajustados com dados reais
- [ ] Preferências de alertas nas Settings
- [ ] Documentar em `docs/decisions/007-intelligence-layer.md`

---

## 📎 Referências

- Análise detalhada: `FAROL_PREDICTIVE_ENGINE.md` → Seção 8
- ADR pendente: `docs/decisions/007-intelligence-layer.md`
- Depende de: `forecasting.md` (completo) · `recurring_rules.md` · `installments_redesign.md`
- Desbloqueia: v2 — Intelligence com LLM contextual (fora do escopo atual)
