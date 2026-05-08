# Arquitectura de Farol — Visión Viva

> Este documento se actualiza con cada cambio arquitectónico significativo.
> Última actualización: Mayo 2026

---

## Estado Actual de la Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER UI                         │
│  lib/features/*/presentation/                       │
│  Screens · Widgets · Bottom Sheets                  │
├─────────────────────────────────────────────────────┤
│              PROVIDERS (Riverpod 2)                  │
│  lib/core/providers/                                │
│  autoDispose · StreamProvider · FutureProvider      │
├─────────────────────────────────────────────────────┤
│              REPOSITORIES                            │
│  lib/core/repositories/ + lib/features/*/data/     │
│  SupabaseClient directo (mayoría)                   │
│  AppDatabase/Drift (algunos)                        │
├─────────────────────────────────────────────────────┤
│              SERVICIOS CORE                          │
│  FinancialCalculatorService (estático)              │
│  ExportService · CltCalculatorService               │
├─────────────────────────────────────────────────────┤
│              PERSISTENCIA                            │
│  Supabase PostgreSQL (fuente de verdad)             │
│  Drift/SQLite (mirror parcial, sin sync coherente)  │
└─────────────────────────────────────────────────────┘
```

## Arquitectura Objetivo (post-implementación de los planes)

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER UI                         │
│  Screens · Widgets (consumen solo FinancialSnapshot)│
├─────────────────────────────────────────────────────┤
│              APPLICATION LAYER                       │
│  UseCases · Commands · Queries                      │
├─────────────────────────────────────────────────────┤
│               DOMAIN LAYER                          │
│  FinancialEngine · ForecastingEngine                │
│  EnvelopeEngine · ObligationEngine                  │
│  IntelligenceLayer                                  │
├─────────────────────────────────────────────────────┤
│            INFRASTRUCTURE LAYER                     │
│  Repositories (Drift + Supabase via SyncManager)   │
│  OperationQueue · ConflictResolver                  │
└─────────────────────────────────────────────────────┘
```

## Bounded Contexts

| Context | Responsabilidad | Estado |
|---|---|---|
| Identity & Period | Usuario, perfil, períodos financieros | ✅ Implementado |
| Ledger | Registro de transacciones pasadas | ⚠️ Parcial |
| Budget (Envelopes) | Presupuesto por categoría | ⚠️ Básico |
| Obligations | Cuotas e recurrentes futuros | 🔴 Mínimo |
| Forecasting | Proyección financiera | 🔴 Inexistente |
| Intelligence | Insights y recomendaciones | 🔴 Inexistente |

## Decisiones Arquitectónicas Vigentes

Consultar `docs/decisions/` para el historial completo de ADRs.

| # | Decisión | Estado |
|---|---|---|
| 001 | Unificación del sistema de categorías | 🔴 Pendiente |
| 002 | FinancialSnapshot como fuente única de verdad | 🔴 Pendiente |
| 003 | Forecasting Engine determinista (no ML) | 🔴 Pendiente |
| 004 | Sync Strategy: Optimistic + Queue | 🔴 Pendiente |
