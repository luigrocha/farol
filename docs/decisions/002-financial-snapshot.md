# ADR-002: FinancialSnapshot como Única Fuente de Verdad del Dashboard

**Fecha**: 2026-05-08
**Estado**: Implementado ✅
**Área**: Domain · Providers · UI

---

## Contexto

El dashboard actual tiene múltiples widgets que calculan sus propias versiones del estado financiero de forma independiente:

- `KpiGrid` calcula totales de expenses via su propio provider
- `PeriodBalanceHero` calcula el balance con lógica propia
- `HealthGaugeCard` llama directamente a `FinancialCalculatorService.calculateHealthScore()` con inputs que puede tener incompletos

El `FinancialCalculatorService` es una colección de métodos estáticos sin estado. No existe un "snapshot" del estado financiero del período — cada widget construye su propia visión parcial.

Esto genera: posibles inconsistencias entre widgets, queries duplicadas a la misma fuente de datos, dificultad para agregar forecasting (¿en qué widget vive?), y complejidad para cachear el estado financiero.

## Decisión

**Crear `FinancialSnapshot` como la única fuente de verdad** del estado financiero de un período. El `FinancialEngine` produce este snapshot. Todos los widgets del dashboard lo consumen como único observable.

```dart
// Antes: cada widget tiene su provider propio
class KpiGrid extends ConsumerWidget {
  Widget build(context, ref) {
    final expenses = ref.watch(expensesProvider(period)); // query propia
    // ...
  }
}

// Después: todos consumen el mismo snapshot
class KpiGrid extends ConsumerWidget {
  final FinancialSnapshot snapshot;
  Widget build(context, ref) {
    // snapshot.totalSpent, snapshot.healthScore, etc. — ya calculados
  }
}
```

El `FinancialSnapshot` incluye: balances (income/expenses/current), envelopes, health score, savings rate, obligaciones futuras. En versiones futuras: burn rate, projected balance, insights.

## Consecuencias

### Positivas
- Una sola fuente de verdad → imposible tener widgets mostrando números inconsistentes
- Cache centralizado → un solo TTL, invalidación coordinada
- Forecasting tiene un lugar natural de vivir (extiende FinancialSnapshot)
- Tests más simples: testear el engine, no cada widget
- Performance: N queries → 1 snapshot bien construido

### Negativas / Trade-offs
- Refactoring del dashboard requiere coordinar cambios en 4-5 widgets
- El snapshot puede ser más pesado de calcular que los queries individuales simples
- Si un campo del snapshot cambia, todos los widgets que lo usan necesitan actualización

### Riesgos aceptados
- **Loading state**: mientras el snapshot carga, los widgets muestran skeleton. Mitigado con `FinancialSnapshot.empty()` factory.
- **Granularidad de rebuild**: si un solo campo cambia, todos los widgets que usan el snapshot se rebuilden. Mitigado con `ref.select()` de Riverpod.

## Alternativas Consideradas

### Alternativa 1: Múltiples providers especializados (estado actual)
Mantener un provider por tipo de dato (incomes, expenses, health, etc.).

**Descartada porque**: No escala con forecasting. Los datos son interdependientes (el health score necesita income + expenses + installments + emergency fund). Mantenerlos separados garantiza inconsistencias eventuales.

### Alternativa 2: Un BLoC global de estado financiero
Usar BLoC en vez de Riverpod para el estado del dashboard.

**Descartada porque**: Farol usa Riverpod en todo el codebase. Introducir BLoC crea inconsistencia arquitectónica. El problema se resuelve con Riverpod correctamente.

## Criterios de Éxito

- [ ] `DashboardScreen` hace exactamente 1 `ref.watch()` para obtener el estado financiero
- [ ] `KpiGrid`, `PeriodBalanceHero`, `HealthGaugeCard` reciben `FinancialSnapshot` como parámetro
- [ ] 0 queries duplicadas entre widgets del dashboard para el mismo período
- [ ] Test: `FinancialSnapshot.totalIncome - totalSpent == currentBalance` siempre verdadero

## Referencias

- Plan de implementación: `plans/financial_engine.md`
- Código afectado: `lib/features/dashboard/`
- Depende de: ADR-001 (categorías unificadas)
- Habilita: ADR-003 (forecasting)
