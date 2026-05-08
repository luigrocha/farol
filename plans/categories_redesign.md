# Plan: Categories System Redesign
**Área**: Domain · Database · Repositories
**Prioridad**: P0 — bloquea todo lo demás
**Dependencias**: Ninguna (este plan es el punto de partida)
**Archivos impactados**: `enums.dart`, `category.dart`, `app_database.dart`, `category_repository.dart`, todos los repositorios que usan `ExpenseCategory`

---

## 🔍 Contexto del Problema

### Estado actual (confirmado en código)

```dart
// PROBLEMA 1: Dos sistemas paralelos e incompatibles

// Sistema A — enum hardcodeado en Dart (enums.dart)
enum ExpenseCategory {
  housing('HOUSING', ...), transport('TRANSPORT', ...),
  // ... 9 valores fijos, no extensibles sin recompilar
}

// Sistema B — tabla en DB (app_database.dart + Supabase)
class CategoryTable extends Table {
  // dbValue, name, emoji, isSwile, isSystem, orderIndex
  // Permite custom categories del usuario
}

// BOMBA DE TIEMPO:
ExpenseCategory.fromDb('CUSTOM_ROPA') // → StateError: No element
```

```dart
// PROBLEMA 2: Los expenses almacenan category como String raw
class Expense {
  final String category; // 'HOUSING', 'CUSTOM_ROPA', ...
  // En algunos flujos: ExpenseCategory.fromDb(category) → puede lanzar
  // En otros flujos: se usa como string raw → inconsistente
}
```

### Impacto actual
- Cualquier categoría custom del usuario puede crashear la app
- `BudgetGoals` usa `category` como string → misma bomba de tiempo
- `PeriodBudget` usa `category` como string → inconsistente con CategoryTable
- El forecasting no puede operar sobre categorías si no hay un modelo unificado

---

## 📐 Arquitectura Propuesta

### Modelo unificado: `CategoryRef`

```dart
// Reemplaza el enum ExpenseCategory completamente
// Es un value object en el dominio — siempre válido, nunca lanza
class CategoryRef {
  final String id;           // UUID (Supabase) o slug local
  final String slug;         // 'housing', 'custom_ropa'
  final String name;         // 'Moradia' (localizado)
  final String emoji;
  final String? colorHex;
  final FinancialType financialType; // need | want | investment | income | transfer
  final String? parentId;
  final bool isSystem;
  final bool isSwile;
  final bool isFixed;        // típicamente fijo

  bool get isCustom => !isSystem;

  // Compatibilidad backward — nunca lanza StateError
  static CategoryRef fromLegacyString(String dbValue, List<CategoryRef> all) {
    return all.firstWhere(
      (c) => c.slug.toUpperCase() == dbValue.toUpperCase(),
      orElse: () => CategoryRef.uncategorized(dbValue),
    );
  }
}
```

### Schema DB propuesto

```sql
-- Supabase migration
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id),  -- NULL = sistema global
  parent_id     UUID REFERENCES categories(id),
  slug          TEXT NOT NULL,
  name          TEXT NOT NULL,
  emoji         TEXT NOT NULL DEFAULT '📋',
  color_hex     TEXT,
  financial_type TEXT NOT NULL DEFAULT 'want'
    CHECK (financial_type IN ('need','want','investment','income','transfer')),
  is_system     BOOLEAN DEFAULT FALSE,
  is_swile      BOOLEAN DEFAULT FALSE,
  is_fixed      BOOLEAN DEFAULT FALSE,
  is_archived   BOOLEAN DEFAULT FALSE,
  display_order INT DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, slug)
);

-- Campo adicional en expenses (backward compat: nullable primero)
ALTER TABLE expenses ADD COLUMN category_id UUID REFERENCES categories(id);
```

---

## ⚡ Análisis de Impacto

### Archivos que usan `ExpenseCategory` enum directamente
```
lib/core/models/enums.dart                    ← definición del enum
lib/features/transactions/quick_add_bottom_sheet.dart
lib/features/transactions/edit_expense_bottom_sheet.dart
lib/features/analytics/analytics_screen.dart
lib/features/dashboard/widgets/expense_breakdown.dart
lib/features/budget/presentation/budget_goals_sheet.dart
lib/features/period_budget/presentation/budget_edit_sheet.dart
lib/features/period_budget/presentation/period_budget_screen.dart
lib/features/settings/categories_management_screen.dart
lib/core/repositories/category_repository.dart
```

### Archivos que usan `category` como String raw
```
lib/core/database/app_database.dart           ← DAOs con category String
lib/core/models/expense.dart                  ← category: String
lib/core/models/period_budget.dart            ← category: String
lib/core/models/budget_goal.dart              ← category: String
lib/core/repositories/period_budget_repository.dart
lib/core/repositories/budget_goals_repository.dart
```

### Breaking Changes Identificados
| Change | Severidad | Mitigación |
|---|---|---|
| Eliminar enum `ExpenseCategory` | 🔴 CRÍTICO | Mantener en paralelo hasta Fase 4 |
| `Expense.category` String → `CategoryRef` | 🔴 CRÍTICO | Campo nullable `categoryRef` adicional |
| `BudgetGoal.category` String | 🟡 MEDIO | `CategoryResolver` como adapter |
| `category_id` en expenses (Supabase) | 🟡 MEDIO | Nullable + backfill job |
| DAOs Drift con `CategoryTable` | 🟢 BAJO | Extensión, no reemplazo |

---

## 🗺️ Estrategia Incremental

```
analiza → propone → validar → fase 1 → review → fase 2 → review → ...
```

### FASE 1 — El Puente Seguro (sin breaking changes)
**Objetivo**: Crear la infraestructura nueva sin tocar código existente.
**Reversibilidad**: 100% — solo se agregan archivos nuevos.

```
Tarea 1.1: Crear CategoryRef value object
  - lib/core/domain/value_objects/category_ref.dart
  - FinancialType enum
  - CategoryRef.uncategorized() factory (safe fallback)
  - CategoryRef.fromLegacyString() (adapter sin excepciones)

Tarea 1.2: Crear CategoryResolver service
  - lib/core/domain/services/category_resolver.dart
  - Carga categorías del DB (Supabase + Drift)
  - Mapea String legacy → CategoryRef (nunca lanza)
  - Cache en memoria (invalidar on category change)

Tarea 1.3: Crear tabla categories en Supabase
  - Migration SQL con todos los slugs sistema
  - Seed: mapeo 1:1 con enum actual (HOUSING → housing, etc.)
  - RLS policies

Tarea 1.4: Agregar category_id a expenses (nullable)
  - Supabase: ALTER TABLE expenses ADD COLUMN category_id UUID
  - Drift: agregar campo nullable al schema (migration)
  - NO actualizar ningún query existente todavía
```

**Test de éxito**: `CategoryResolver.resolve('CUSTOM_XYZ')` retorna `CategoryRef.uncategorized()` — nunca StateError.

---

### FASE 2 — El Backfill (datos existentes)
**Objetivo**: Poblar `category_id` en expenses existentes.
**Reversibilidad**: Alta — el campo viejo `category` String sigue intacto.

```
Tarea 2.1: Job de backfill Supabase
  - Script SQL: UPDATE expenses SET category_id = (
      SELECT id FROM categories WHERE slug = LOWER(expenses.category)
    )
  - Ejecutar en Supabase SQL editor (no en código app)
  - Verificar: COUNT(*) WHERE category_id IS NULL después del backfill

Tarea 2.2: Asegurar que nuevos expenses siempre tengan category_id
  - Modificar ExpenseRepository.insert() para resolver y guardar category_id
  - Usar CategoryResolver para mapear el string a UUID
  - El campo String 'category' sigue guardándose (backward compat)
```

**Test de éxito**: Todos los expenses nuevos tienen `category_id` NOT NULL. Los viejos tienen el campo poblado post-backfill.

---

### FASE 3 — La Migración de Providers
**Objetivo**: Los providers de Riverpod usan `CategoryRef` en vez del enum.
**Reversibilidad**: Media — requiere cambios coordinados en UI.

```
Tarea 3.1: CategoryRepository refactorizado
  - watchCategories() → Stream<List<CategoryRef>>
  - Internamente: combina CategoryTable (Drift) + Supabase categories
  - Provee CategoryRef para sistema + custom del usuario

Tarea 3.2: categoryProvider en Riverpod
  - Provider global de categorías cacheadas
  - Usado por todos los screens que necesitan la lista
  - Invalida cuando el usuario agrega/edita categoría

Tarea 3.3: Migrar screens uno a uno (coordinado)
  - categories_management_screen.dart → usa CategoryRef
  - quick_add_bottom_sheet.dart → dropdown usa CategoryRef
  - expense_breakdown.dart → usa CategoryRef para display
  - Mantener adapter para código que aún usa String
```

**Test de éxito**: Abrir la app, crear una categoría custom, crear un gasto con esa categoría, cerrar y reabrir → el gasto muestra la categoría correcta. Sin StateError.

---

### FASE 4 — Eliminación del Enum (cleanup)
**Objetivo**: Remover el enum `ExpenseCategory` del código.
**Reversibilidad**: Baja — cambio irreversible, hacer último.
**Pre-condición**: Fases 1-3 completas y en producción estable por ≥2 semanas.

```
Tarea 4.1: Audit final de uso del enum
  - grep -r "ExpenseCategory" lib/ → debe retornar 0 usos

Tarea 4.2: Eliminar enum de enums.dart
  - Mantener swileCategories como Set<String> (o migrar a CategoryRef.isSwile)

Tarea 4.3: Hacer category_id NOT NULL en expenses
  - Supabase migration: ALTER TABLE expenses ALTER COLUMN category_id SET NOT NULL
  - Verificar primero que NO existen nulls en producción

Tarea 4.4: Marcar campo String 'category' como deprecated
  - Mantenerlo en DB por 1 período más (backward compat con exports)
  - Eventualmente: DROP COLUMN category (fuera de scope de este plan)
```

---

## 🚨 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| StateError en producción (categoría desconocida) | Alta (ya ocurre) | Crash | Fase 1: CategoryRef.uncategorized() como fallback |
| Backfill incompleto (slugs que no matchean) | Media | Datos huérfanos | Verificar COUNT IS NULL post-backfill, manual fix si hay outliers |
| Provider rebuild cascade al cambiar CategoryRef | Media | Performance | autoDispose + family providers por categoría |
| Drift migration error (campo nullable) | Baja | Crash en upgrade | Test migration en emulador antes de release |
| Categoría custom con slug que choca con sistema | Baja | Conflicto DB | UNIQUE constraint `(user_id, slug)` — user_id NULL = sistema |

---

## ✅ Checklist de Completitud

### Fase 1
- [ ] `CategoryRef` value object creado y testeado
- [ ] `FinancialType` enum creado
- [ ] `CategoryResolver` creado con `fromLegacyString()` sin excepciones
- [ ] Tabla `categories` creada en Supabase con seed de categorías sistema
- [ ] Campo `category_id UUID` agregado a `expenses` en Supabase (nullable)
- [ ] Drift schema actualizado con migration
- [ ] Test: `CategoryResolver.resolve('CUALQUIER_COSA')` nunca lanza

### Fase 2
- [ ] Backfill SQL ejecutado en Supabase
- [ ] Verificación: 0 nulls en `category_id` post-backfill
- [ ] `ExpenseRepository.insert()` guarda `category_id`
- [ ] Test: expense nuevo tiene `category_id` NOT NULL

### Fase 3
- [ ] `CategoryRepository.watchCategories()` retorna `List<CategoryRef>`
- [ ] `categoryProvider` en Riverpod funciona
- [ ] Al menos 3 screens migrados a `CategoryRef`
- [ ] Test: crear categoría custom → aparece en dropdown → crear expense → se muestra correctamente

### Fase 4
- [ ] 0 usos de `ExpenseCategory` enum en código
- [ ] `category_id` NOT NULL en producción
- [ ] Documentar decisión en `docs/decisions/001-category-unification.md`

---

## 📎 Referencias

- Análisis detallado: `FAROL_PREDICTIVE_ENGINE.md` → Sección 3
- ADR pendiente: `docs/decisions/001-category-unification.md`
- Depende de: ningún otro plan
- Desbloquea: `financial_engine.md`, `forecasting.md`
