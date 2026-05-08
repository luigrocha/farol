# ADR-007: Intelligence Layer — Regras Deterministas, Não ML

**Fecha**: 2026-05-07
**Estado**: Propuesto — pendiente de implementación
**Área**: Domain · Analytics · UI

---

## Contexto

Com o Financial Engine + Forecasting em funcionamento, o Farol tem todos os dados necessários para gerar insights financeiros contextuais. A questão arquitetônica é: como gerar esses insights de forma que sejam úteis, confiáveis e não-invasivos?

Duas abordagens possíveis: (1) Machine Learning / LLM, ou (2) regras deterministas baseadas em especialistas. A escolha afeta custo, latência, confiabilidade, offline support e complexidade de manutenção.

## Decisão

**Intelligence Layer v1 é 100% determinista e baseada em regras**. Doze regras core operam sobre o `FinancialSnapshot` e dados históricos para produzir `List<FinancialInsight>`. Sem chamadas a APIs externas, sem modelos de ML, sem treinamento necessário.

As regras são:
1. Risco de saldo negativo ao fechar o período
2. Liquidez crítica nos próximos 7 dias
3. Categoria acima do ritmo histórico (spike)
4. Cobrança duplicada provável
5. Subscription creep (assinaturas crescendo)
6. Oportunidade de economia (categoria cronicamente acima do orçamento)
7. Oportunidade de investimento (saldo projetado > R$500)
8. Conquista: streak de períodos dentro do orçamento
9. Conquista: melhor poupança do histórico
10. Redução de dívidas (parcelas ativas diminuíram)
11. Categoria problemática voltou ao normal
12. Merchant desconhecido por valor alto

**UX**: máximo 3 insights visíveis simultaneamente. Prioridade: critical > warning > info > achievement. Usuário pode dispensar por 7/30/sempre.

## Consequências

### Positivas
- Funciona 100% offline (sem APIs externas)
- Resultados reproduzíveis e auditáveis — cada insight tem `data` de suporte
- Zero custo por request
- Sem alucinações ou outputs imprevisíveis
- Pode ser testado com dados sintéticos de forma determinista

### Negativas / Trade-offs
- Não aprende com o comportamento individual do usuário (sem personalização)
- Thresholds são hardcoded — requerem ajuste manual baseado em dados reais
- Não detecta padrões complexos que ML detectaria (ex: sazonalidade)

### Riscos aceitos
- **Falso positivo na detecção de duplicatas**: transações legítimas podem ser flagradas como duplicatas. Mitigado com threshold de confidence conservador (0.70+) e opção de dispensar permanentemente.
- **Insights irrelevantes geram desconfiança**: se o usuário dispensa insights frequentemente, a feature perde valor. Mitigado com tracking de dismiss rate e ajuste de thresholds.

## Sobre ML/LLM em versões futuras

A Intelligence Layer determinista é a **base correta** para v1. Quando houver:
- >500 usuários com >6 meses de histórico
- Infra para servir modelos (ou orçamento para APIs externas)

Então faz sentido adicionar:
- **Classificação automática de transações**: NLP sobre `store_description` (OpenAI embeddings ou modelo local TFLite)
- **Anomaly detection**: Isolation Forest sobre padrões de gasto histórico
- **Previsão de gastos variáveis**: ARIMA sobre séries temporais mensais
- **Copiloto conversacional**: LLM com contexto do `FinancialSnapshot` atual

O design da `IntelligenceLayer` como serviço isolado facilita essa evolução: ML pode ser adicionado como fonte adicional de `FinancialInsight` sem alterar a arquitetura de display.

## Alternativas Consideradas

### LLM desde v1 (ex: Claude API com contexto financeiro)
**Descartada**: Latência inaceitável para mobile (300–2000ms), custo por request, sem suporte offline, risco de alucinações em dados financeiros sensíveis.

### Biblioteca de analytics de terceiros (Mixpanel, Amplitude smart alerts)
**Descartada**: Requer envio de dados financeiros para servidores externos, conflita com o posicionamento de privacidade do Farol, menos customizável para o contexto Brasil/CLT.

## Critérios de Sucesso

- [ ] Dismiss rate de insights < 40% (indicador de relevância)
- [ ] Tap rate em insights de warning > 25% (indicador de actionabilidade)
- [ ] 0 falsos positivos críticos em 30 dias de uso real (ex: "cobrança duplicada" incorreta)
- [ ] Nenhum insight exibe dados inconsistentes com o FinancialSnapshot
- [ ] Usuários com Intelligence Layer têm retenção 30d superior ao grupo de controle

## Referências

- Plano: `plans/intelligence_layer.md`
- Depende de: ADR-002 (FinancialSnapshot), ADR-003 (ForecastingEngine)
- Revisitar para v2 quando houver dados de uso suficientes
