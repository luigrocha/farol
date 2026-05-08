# ADR-001: Unificación del Sistema de Categorías

**Fecha**: 2026-05-07
**Estado**: Propuesto — pendiente de implementación
**Área**: Domain · Database

---

## Contexto

Farol tiene dos sistemas de categorías paralelos e incompatibles:

1. **Enum `ExpenseCategory`** en `lib/core/models/enums.dart` — 9 valores hardcodeados en Dart, no extensibles sin recompilar. Tiene lógica de localización y clasificación Swile.

2. **`CategoryTable`** en Drift + tabla `categories` en Supabase — permite categorías custom del usuario, tiene `dbValue`, `name`, `emoji`, `isSwile`, `isSystem`, `orderIndex`.

El problema crítico: `ExpenseCategory.fromDb(value)` lanza `StateError: No element` cuando el `value` es una categoría custom creada por el usuario. Esto es una bomba de tiempo en producción. Los expenses almacenan `category` como `String` raw, y diferentes partes del código convierten o no convierten ese String al enum de forma inconsistente.

Adicionalmente, el sistema de forecasting planificado requiere un modelo de categorías enriquecido (`FinancialType`, `isFixed`, `typical_recurrence`) que el enum no puede proveer.

## Decisión

**Crear un `CategoryRef` value object unificado** que:
- Reemplaza el enum `ExpenseCategory` completamente (migración gradual en 4 fases)
- Mapea 1:1 con una tabla `categories` en Supabase (y su mirror en Drift)
- Nunca lanza excepción para categorías desconocidas (fallback a `uncategorized`)
- Soporta categorías sistema (is_system: true) y custom (user_id not null)
- Incluye `FinancialType` para el forecasting engine

La migración es **aditiva-primero**: se agrega el nuevo sistema sin eliminar el viejo, se migran datos, se migra UI, y solo entonces se elimina el enum.

## Consecuencias

### Positivas
- Elimina la posibilidad de `StateError` por categoría desconocida
- Habilita categorías custom ilimitadas del usuario
- Provee `FinancialType` (need|want|investment) para el forecasting
- Permite subcategorías (parent_id)
- Una sola fuente de verdad para categorías (no dos sistemas)

### Negativas / Trade-offs
- Migración de 4 fases requiere ~3-4 semanas de trabajo
- Durante la transición, ambos sistemas coexisten (complejidad temporal)
- Los queries que filtran por categoría necesitan actualizarse para usar UUID en vez de String
- `BudgetGoals.category` y `PeriodBudget.category` también son String → necesitan migración similar

### Riesgos aceptados
- **Backfill incompleto**: si un expense tiene un `category` String que no matchea ningún slug → se asigna a `uncategorized`. Requiere auditoría post-backfill.
- **Drift migration fallaría si hay datos corruptos**: mitigado con migration `onUpgrade` defensiva.

## Alternativas Consideradas

### Alternativa 1: Extender el enum
Agregar más valores al enum `ExpenseCategory` para cubrir categorías custom.

**Descartada porque**: Los enums Dart son estáticos — no pueden crearse en runtime. Un usuario no puede crear un enum value. Esto no resuelve el problema de las categorías custom.

### Alternativa 2: Solo usar CategoryTable (eliminar enum inmediatamente)
Eliminar el enum en la primera PR y migrar todo de una vez.

**Descartada porque**: Big bang rewrite con alto riesgo de regresiones. Los enums están en ~15 archivos. La migración gradual reduce el riesgo significativamente.

### Alternativa 3: Mantener ambos sistemas indefinidamente con un adapter
Crear un adapter que mapea entre enum y CategoryTable, manteniendo ambos.

**Descartada porque**: Aumenta la deuda técnica, no resuelve el StateError (el adapter necesitaría el fallback de todas formas), y no provee `FinancialType`.

## Criterios de Éxito

- [ ] `CategoryResolver.resolve('CUALQUIER_STRING')` nunca lanza excepción en producción
- [ ] 0 ocurrencias de `ExpenseCategory.fromDb()` en el codebase final
- [ ] Los usuarios pueden crear categorías custom y usarlas sin crashear la app
- [ ] Los gastos con categorías custom se muestran correctamente en todos los screens
- [ ] El `FinancialType` de cada categoría es correcto (need/want/investment)

## Referencias

- Plan de implementación: `plans/categories_redesign.md`
- Código afectado principal: `lib/core/models/enums.dart`, `lib/core/models/category.dart`
- Desbloquea: `plans/financial_engine.md`, `plans/forecasting.md`
