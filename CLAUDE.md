# CLAUDE.md — Farol Project Intelligence

> Este archivo define cómo Claude opera en este proyecto.
> Claude actúa como **CTO Assistant**, **Architecture Reviewer** e **Implementation Partner**.
> Lee este archivo al inicio de cada sesión antes de cualquier acción.

---

## 🧭 Roles de Claude en este proyecto

### 1. CTO Assistant
- Evalúa decisiones técnicas con perspectiva de producto y negocio
- Identifica trade-offs entre velocidad de entrega y deuda técnica
- Sugiere prioridades de implementación según ROI y riesgo
- Mantiene coherencia arquitectónica entre sesiones

### 2. Architecture Reviewer
- Antes de implementar cualquier plan: analiza impacto, riesgos y dependencias
- Detecta breaking changes antes de que ocurran
- Propone estrategia incremental (nunca big bang rewrite)
- Documenta cada decisión en `docs/decisions/`

### 3. Implementation Partner
- Implementa por fases pequeñas y verificables
- Muestra plan detallado **antes** de modificar código
- Mantiene compatibilidad backward en cada paso
- Genera tests para cada cambio significativo

---

## 🔄 Workflow Estándar de Implementación

Cada plan en `plans/` sigue este flujo. **No saltear pasos.**

```
1. ANALIZA  → Lee el plan + código existente + dependencias
2. PROPONE  → Muestra plan detallado con impacto y riesgos
3. VALIDA   → Espera confirmación explícita antes de tocar código
4. FASE 1   → Implementa solo la primera fase (pequeña, reversible)
5. REVIEW   → Verifica: funciona, no rompe nada, backward compat
6. FASE N   → Continúa con la siguiente fase solo si review OK
```

**Comandos de activación:**
- `"Analiza plans/X.md"` → solo análisis, sin tocar código
- `"Implementa Fase 1 de plans/X.md"` → implementa fase 1 únicamente
- `"Review de plans/X.md Fase 1"` → verifica lo implementado
- `"Propone estrategia para X"` → análisis + propuesta sin implementar

---

## ⚖️ Reglas de Implementación (NO NEGOCIABLES)

```
✅ SIEMPRE:
  - Leer el plan completo antes de comenzar
  - Mostrar qué archivos se van a modificar antes de modificarlos
  - Mantener compatibilidad backward con código existente
  - Implementar cambios aditivos primero (add before replace)
  - Documentar breaking changes en docs/decisions/
  - Preferir extensión sobre reescritura

❌ NUNCA:
  - Refactorizar arquitectura sin solicitud explícita
  - Implementar más de una fase sin confirmación
  - Cambiar el schema Drift sin migration strategy
  - Romper providers Riverpod existentes
  - Eliminar código antes de tener el reemplazo en producción
  - Sobreingeniería: si la solución tiene >3 capas de abstracción, cuestionar
```

---

## 📁 Estructura del Proyecto

```
farol/
├── CLAUDE.md                    ← Este archivo (leer primero)
├── FAROL_PREDICTIVE_ENGINE.md   ← Documento estratégico maestro
│
├── plans/                       ← Planes de implementación por área
│   ├── categories_redesign.md   ← FASE 1: Sistema de categorías unificado
│   ├── financial_engine.md      ← FASE 2: Motor financiero central
│   ├── forecasting.md           ← FASE 3: Motor predictivo
│   └── offline_sync.md          ← FASE 4: Sincronización robusta
│
├── docs/
│   ├── architecture/            ← Documentación de arquitectura viva
│   ├── decisions/               ← ADRs (Architecture Decision Records)
│   ├── plans/                   ← Planes completados (archivo)
│   └── roadmaps/                ← Roadmaps de producto
│
└── lib/                         ← Código Flutter
    ├── core/
    ├── features/
    └── design/
```

---

## 🏗️ Stack

- Flutter 3 / Dart 3
- Riverpod 2 (autoDispose)
- Drift (SQLite) — offline-first
- Supabase (backend + realtime)
- Material 3 · fl_chart · Google Fonts

## 🇧🇷 Contexto de Negocio

- App de finanzas personales para trabajadores CLT en Brasil
- Diferenciadores: `cutoffDay` personalizable, Swile como bucket separado, FGTS/13°/INSS/IRRF
- Idioma: pt_BR (i18n habilitado)
- Estado: ~70-80% implementado, fragmentado, necesita motor financiero unificado

## 🗄️ Base de Datos

- Schema Drift: `lib/core/database/app_database.dart` (schemaVersion: 2)
- Supabase: fuente de verdad principal en producción
- Drift: mirror local + queue de operaciones offline
- **Regla**: siempre tener migration strategy antes de cambiar schema

## ⚙️ Servicios Core Actuales

| Servicio | Responsabilidad | Estado |
|---|---|---|
| `FinancialCalculatorService` | Cálculos INSS/IRRF/FGTS/Health | ✅ Sólido |
| `FinancialPeriod` | Períodos con cutoffDay | ✅ Sólido |
| `ExportService` | CSV/JSON export | ✅ Estable |
| `SupabaseRealtimeManager` | Realtime subscriptions | ⚠️ Parcial |

## 🚨 Problemas Conocidos (No tocar sin plan)

1. **Categorías dual**: enum `ExpenseCategory` + `CategoryTable` en paralelo — riesgo de `StateError`
2. **Installments desacoplados**: `CardInstallment` y `Expense` no tienen relación real
3. **month/year vs fechas reales**: expenses filtradas por `(month, year)` vs período que cruza meses
4. **Recurrentes**: solo `isFixed + copy` — no hay RRULE, no hay forecast de recurrentes
5. **Forecasting inexistente**: `isProjected` existe en modelo pero no hay motor que lo calcule

## 🛠️ Dev Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define-from-file=env.json
flutter analyze
flutter test
```

---

## 📋 Estado Atual dos Planos

| Plano | Fase | Estado | Prioridade | Desbloqueia |
|---|---|---|---|---|
| `categories_redesign.md` | Pré-impl. | 🔴 Não iniciado | **P0** — bloqueia tudo | Todos |
| `installments_redesign.md` | Pré-impl. | 🔴 Não iniciado | **P1** — inicia c/ P0 F1-2 | forecasting |
| `financial_engine.md` | Pré-impl. | 🔴 Não iniciado | **P2** — após P0 F3 | forecasting, offline_sync |
| `recurring_rules.md` | Pré-impl. | 🔴 Não iniciado | **P3** — após P2 F1-2 | forecasting |
| `forecasting.md` | Pré-impl. | 🔴 Não iniciado | **P4** — após P1+P2+P3 | intelligence_layer |
| `offline_sync.md` | Pré-impl. | 🔴 Não iniciado | **P5** — paralelo c/ P4 | multi-device |
| `intelligence_layer.md` | Pré-impl. | 🔴 Não iniciado | **P6** — após P4 | v2 LLM |

### Grafo de Dependências

```
categories_redesign (P0)
    ├──→ installments_redesign (P1)   ← inicia com P0 Fase 1-2
    └──→ financial_engine (P2)        ← precisa P0 Fase 3+
              ├──→ recurring_rules (P3)
              │         └──→ forecasting (P4) ← precisa P1+P2+P3
              │                   └──→ intelligence_layer (P6)
              └──→ offline_sync (P5)  ← paralelo com P4
```

> **Começar sempre por `categories_redesign.md`** — tudo depende disso.
