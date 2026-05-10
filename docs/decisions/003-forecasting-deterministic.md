# ADR-003: Deterministic Forecasting Engine (No ML in v1)

**Date**: 2026-05-07
**Status**: Implemented ✅
**Area**: Domain · Analytics

---

## Context

Farol's goal is to be a "Predictive Financial Engine". There is a temptation to implement Machine Learning (regression, neural networks, etc.) to predict future expenses. Alternatives like Copilot Money use ML for automatic categorization and predictions. Should Farol do the same in v1?

## Decision

**The Forecasting Engine v1 is completely deterministic and mathematical.** It uses no ML, no complex statistical models, no external AI APIs. It uses:

1. **Burn Rate**: spending / elapsed days → linear projection
2. **Known obligations**: installment_payments + recurring_occurrences → exact data in DB
3. **Weighted historical average**: the last 3 periods have different weights
4. **Explicit heuristic rules**: hardcoded thresholds (>20% deviation = spike)

### Why no ML?

- **No data**: a new user has 0 periods of history. ML needs a minimum of 6-12 months.
- **Explainability**: "you spent R$180 in 10 days at R$18/day → projection of R$540/month" is understandable. A regression model is not.
- **Operational complexity**: ML models need infrastructure (training, serving, versioning). Overkill for v1.
- **Accuracy**: with limited data, linear projection outperforms ML models in RMSE.

### When to add ML?

In v2/v3, with sufficient history:
- Automatic transaction classification (NLP on store_description)
- Anomaly detection (isolation forest on spending patterns)
- Variable expense prediction (ARIMA on monthly historical series)

Candidates: Vertex AI (Google Cloud), OpenAI embeddings, on-device models (TFLite).

## Consequences

### Positive
- Works from day 1 with 0 historical data (burn rate = current data)
- Results completely explainable to the user
- No external dependencies, no API latency
- Deterministic tests: same input → same output, always
- Implementable in pure Dart, on the client

### Negative / Trade-offs
- Linear projection assumes constant pace (doesn't detect seasonality)
- No automatic transaction categorization (user classifies manually)
- Accuracy improves slowly with history (vs ML that improves exponentially)

### Accepted Risks
- **Incomplete projection**: if there are few data points, the projection is less accurate. Mitigated by showing "confidence" in the UI (only show projection if there are ≥7 days of data).

## Alternatives Considered

### Alternative 1: ML from v1 with external API
Use OpenAI/Claude API for conversational financial analysis and prediction.

**Discarded because**: Unacceptable latency for mobile UI, per-request cost accumulates with use, without historical data the model hallucinates, integration complexity.

### Alternative 2: On-device TFLite with pre-trained model
A regression model trained on generic financial data (not the user's).

**Discarded because**: A generic model doesn't know the user's custom cutoffDay, nor Swile, nor the specific Brazilian CLT pattern. Linear projection over the user's real data outperforms a generic model.

## Success Criteria

- [x] `ForecastingEngine.projectPeriod()` returns result in <500ms
- [x] Correct projection when daysElapsed = 1 (no divide-by-zero)
- [x] Correct projection when there are 0 known future obligations
- [x] Projection correctly includes installments due in the period
- [x] Deterministic test: same input snapshot → same FinancialProjection output

## References

- Implementation plan: `plans/forecasting.md`
- Depends on: ADR-001 (categories), ADR-002 (snapshot)
- Revisit for v2 when there are >100 users with >6 months of history
