# ADR-007: Intelligence Layer — Deterministic Rules, Not ML

**Date**: 2026-05-07
**Status**: Implemented ✅
**Area**: Domain · Analytics · UI

---

## Context

With the Financial Engine + Forecasting running, Farol has all the data needed to generate contextual financial insights. The architectural question is: how to generate these insights in a way that is useful, reliable, and non-invasive?

Two possible approaches: (1) Machine Learning / LLM, or (2) deterministic expert rules. The choice affects cost, latency, reliability, offline support, and maintenance complexity.

## Decision

**Intelligence Layer v1 is 100% deterministic and rule-based**. Twelve core rules operate on the `FinancialSnapshot` and historical data to produce `List<FinancialInsight>`. No external API calls, no ML models, no training required.

The rules are:
1. Risk of negative balance at end of period
2. Critical liquidity in the next 7 days
3. Category above historical pace (spike)
4. Probable duplicate charge
5. Subscription creep (growing subscriptions)
6. Savings opportunity (category chronically above budget)
7. Investment opportunity (projected balance > R$500)
8. Achievement: streak of periods within budget
9. Achievement: best savings in history
10. Debt reduction (active installments decreased)
11. Problem category returned to normal
12. Unknown merchant for a high value

**UX**: maximum 3 insights visible simultaneously. Priority: critical > warning > info > achievement. User can dismiss for 7/30/always.

## Consequences

### Positive
- Works 100% offline (no external APIs)
- Reproducible and auditable results — each insight has supporting `data`
- Zero cost per request
- No hallucinations or unpredictable outputs
- Can be tested with synthetic data deterministically

### Negative / Trade-offs
- Doesn't learn from individual user behavior (no personalization)
- Thresholds are hardcoded — require manual adjustment based on real data
- Doesn't detect complex patterns that ML would detect (e.g. seasonality)

### Accepted Risks
- **False positive in duplicate detection**: legitimate transactions may be flagged as duplicates. Mitigated with conservative confidence threshold (0.70+) and permanent dismiss option.
- **Irrelevant insights generate distrust**: if the user dismisses insights frequently, the feature loses value. Mitigated with dismiss rate tracking and threshold adjustment.

## On ML/LLM in Future Versions

The deterministic Intelligence Layer is the **correct foundation** for v1. When there are:
- >500 users with >6 months of history
- Infrastructure to serve models (or budget for external APIs)

Then it makes sense to add:
- **Automatic transaction classification**: NLP on `store_description` (OpenAI embeddings or local TFLite model)
- **Anomaly detection**: Isolation Forest on historical spending patterns
- **Variable expense prediction**: ARIMA on monthly time series
- **Conversational copilot**: LLM with context of the current `FinancialSnapshot`

The design of `IntelligenceLayer` as an isolated service facilitates this evolution: ML can be added as an additional source of `FinancialInsight` without changing the display architecture.

## Alternatives Considered

### LLM from v1 (e.g. Claude API with financial context)
**Discarded**: Unacceptable latency for mobile (300–2000ms), per-request cost, no offline support, risk of hallucinations on sensitive financial data.

### Third-party analytics library (Mixpanel, Amplitude smart alerts)
**Discarded**: Requires sending financial data to external servers, conflicts with Farol's privacy positioning, less customizable for the Brazil/CLT context.

## Success Criteria

- [ ] Insight dismiss rate < 40% (relevance indicator)
- [ ] Tap rate on warning insights > 25% (actionability indicator)
- [ ] 0 critical false positives in 30 days of real use (e.g. incorrect "duplicate charge")
- [x] No insight displays data inconsistent with the FinancialSnapshot
- [ ] Users with Intelligence Layer have higher 30d retention than control group

## References

- Plan: `plans/intelligence_layer.md`
- Depends on: ADR-002 (FinancialSnapshot), ADR-003 (ForecastingEngine)
- Implemented: 2026-05-08 — all 12 rules, InsightsPanel, InsightsScreen, dismiss rate tracking
- Revisit for v2 when there is sufficient usage data
