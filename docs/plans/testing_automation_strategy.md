# Testing Automation Strategy — Farol

## Estado Actual

*   **Cobertura actual**: < 5% (casi inexistente).
*   **Gaps**:
    *   Sin Integration Tests (flujos reales entre capas).
    *   Sin E2E (flujos de usuario completos en dispositivos reales).
    *   Tests de Auth frágiles (acoplados a Supabase real sin entorno controlado).
    *   Sin validación de persistencia offline (Drift queue).
*   **Riesgos**:
    *   Regresiones en lógica financiera crítica (forecasting/budgets).
    *   Errores de sincronización entre Drift y Supabase.
    *   Fallas de Auth en diferentes plataformas (Web vs Mobile).
*   **Deuda Técnica**:
    *   Dependencia directa de singletons estáticos (`Supabase.instance`).
    *   Lógica de negocio mezclada con providers en algunos casos.

## Estrategia Global

Adoptaremos la pirámide de testing adaptada para Flutter:

1.  **Unit Tests (60%)**: Lógica de dominio (FinancialEngine, ForecastingEngine, Repositories).
    *   *Herramientas*: `flutter_test`, `mocktail`.
2.  **Widget Tests (25%)**: Componentes UI aislados y flujos de pantalla.
    *   *Foco*: Comportamiento, no píxeles.
3.  **Integration Tests (10%)**: Flujos entre múltiples capas (UI -> Repo -> Local DB).
    *   *Herramientas*: `integration_test`.
4.  **E2E Tests (5%)**: Flujos críticos en ambientes reales.
    *   *Herramientas*: `Patrol` (por su capacidad de interactuar con permisos de sistema y web/native bridges).
5.  **Smoke Tests**: Ejecución rápida post-deploy para verificar que el app inicia y el login básico funciona.

## Prioridades (Roadmap Incremental)

### Fase 1: Cimientos y Auth (Actual)
*   **Auth**: Registro, Login, Logout, Session Recovery.
*   **Infra**: Setup de Mocks/Fakes, integración CI.

### Fase 2: Transacciones y Ledger
*   **Transactions**: CRUD, validaciones financieras.
*   **Sync**: Verificación del `SyncManager` y `OperationQueue`.

### Fase 3: Financial Core
*   **Budgets**: Envelopes, rollover, límites.
*   **Forecasting**: Proyecciones deterministas.

### Fase 4: Experiencia Pro
*   **Workspace Switching**: Aislamiento de datos.
*   **Offline Experience**: Modo offline, resolución de conflictos.
*   **Installments/Recurring**: Generación de cuotas y ocurrencias.

## Estrategia Técnica

| Herramienta | Uso | Tradeoff |
| :--- | :--- | :--- |
| `flutter_test` | Unit/Widget | Rápido, sin device. No prueba integraciones reales. |
| `integration_test` | Integration | Corre en device. Más lento, pero alta confianza. |
| `Patrol` | E2E | Maneja permisos nativos y flujos complejos. Mayor setup. |
| `Mocktail` | Mocking | Type-safe, fácil de usar. Evitar mocks masivos. |
| `Supabase Local` | Backend | Entorno reproducible. Requiere Docker en CI. |

### Filosofía: Behavior-Driven
*   No testeamos "si el botón es azul", testeamos "si al pulsar el botón el gasto se resta del presupuesto".
*   Preferimos **Fakes** sobre **Mocks** para Repositorios (bases de datos en memoria).
