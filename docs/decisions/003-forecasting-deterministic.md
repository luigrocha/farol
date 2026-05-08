# ADR-003: Forecasting Engine Determinista (No ML en v1)

**Fecha**: 2026-05-07
**Estado**: Propuesto — pendiente de implementación
**Área**: Domain · Analytics

---

## Contexto

El objetivo de Farol es ser un "Predictive Financial Engine". Existe la tentación de implementar Machine Learning (regresión, redes neuronales, etc.) para predecir gastos futuros. Alternativas como Copilot Money usan ML para categorización automática y predicciones. ¿Debería Farol hacer lo mismo en v1?

## Decisión

**El Forecasting Engine v1 es completamente determinista y matemático.** No usa ML, no usa modelos estadísticos complejos, no usa APIs de IA externas. Usa:

1. **Burn Rate**: gasto / días transcurridos → proyección lineal
2. **Obligaciones conocidas**: installment_payments + recurring_occurrences → datos exactos en DB
3. **Promedio histórico ponderado**: los últimos 3 períodos tienen diferente peso
4. **Reglas heurísticas explícitas**: umbrales hardcodeados (>20% de desviación = spike)

### ¿Por qué no ML?

- **Sin datos**: un usuario nuevo tiene 0 períodos de historial. ML necesita mínimo 6-12 meses.
- **Explicabilidad**: "gastaste R$180 en 10 días a R$18/día → proyección de R$540/mes" es comprensible. Un modelo de regresión no lo es.
- **Complejidad operacional**: modelos ML necesitan infrastructure (training, serving, versionamiento). Overkill para v1.
- **Precisión**: con pocos datos, la proyección lineal supera a modelos ML en RMSE.

### ¿Cuándo agregar ML?

En v2/v3, con suficiente historial:
- Clasificación automática de transacciones (NLP sobre store_description)
- Detección de anomalías (isolation forest sobre patrones de gasto)
- Predicción de gastos variables (ARIMA sobre historial mensual)

Candidatos: Vertex AI (Google Cloud), OpenAI embeddings, modelos locales en dispositivo (TFLite).

## Consecuencias

### Positivas
- Funciona desde el día 1 con 0 datos históricos (burn rate = datos actuales)
- Resultados completamente explicables al usuario
- Sin dependencies externas, sin latencia de API
- Tests deterministas: mismo input → mismo output, siempre
- Implementable en Dart puro, en el cliente

### Negativas / Trade-offs
- Proyección lineal asume ritmo constante (no detecta estacionalidad)
- Sin categorización automática de transacciones (el usuario clasifica manualmente)
- La precisión mejora lentamente con historial (vs ML que mejora exponencialmente)

### Riesgos aceptados
- **Proyección incompleta**: si hay pocos datos, la proyección es menos precisa. Mitigado mostrando "confidence" en la UI (solo mostrar proyección si hay ≥7 días de datos).

## Alternativas Consideradas

### Alternativa 1: ML desde v1 con API externa
Usar OpenAI/Claude API para análisis financiero conversacional y predicción.

**Descartada porque**: Latencia inaceptable para UI mobile, costo por request acumula con uso, sin datos históricos el modelo hallucina, complejidad de integración.

### Alternativa 2: TFLite local con modelo pre-entrenado
Modelo de regresión entrenado con datos financieros generales (no del usuario).

**Descartada porque**: Un modelo genérico no conoce el cutoffDay personalizado del usuario, ni el Swile, ni el patrón CLT brasileño específico. La proyección lineal sobre los datos reales del usuario supera a un modelo genérico.

## Criterios de Éxito

- [ ] `ForecastingEngine.projectPeriod()` retorna resultado en <500ms
- [ ] Proyección correcta cuando daysElapsed = 1 (no divide-by-zero)
- [ ] Proyección correcta cuando hay 0 obligaciones futuras conocidas
- [ ] La proyección incluye correctamente las cuotas vencidas en el período
- [ ] Test determinista: mismo snapshot de input → mismo FinancialProjection output

## Referencias

- Plan de implementación: `plans/forecasting.md`
- Depende de: ADR-001 (categorías), ADR-002 (snapshot)
- Revisitar para v2 cuando haya >100 usuarios con >6 meses de historial
