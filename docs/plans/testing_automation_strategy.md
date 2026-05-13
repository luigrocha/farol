# Testing Automation Strategy — Farol

## Current State

*   **Current coverage**: < 5% (almost nonexistent).
*   **Gaps**:
    *   No Integration Tests (real flows between layers).
    *   No E2E (complete user flows on real devices).
    *   Fragile Auth tests (coupled to real Supabase without controlled environment).
    *   No offline persistence validation (Drift queue).
*   **Risks**:
    *   Regressions in critical financial logic (forecasting/budgets).
    *   Sync errors between Drift and Supabase.
    *   Auth failures on different platforms (Web vs Mobile).
*   **Technical Debt**:
    *   Direct dependency on static singletons (`Supabase.instance`).
    *   Business logic mixed with providers in some cases.

## Global Strategy

Adopting the testing pyramid adapted for Flutter:

1.  **Unit Tests (60%)**: Domain logic (FinancialEngine, ForecastingEngine, Repositories).
    *   *Tools*: `flutter_test`, `mocktail`.
2.  **Widget Tests (25%)**: Isolated UI components and screen flows.
    *   *Focus*: Behavior, not pixels.
3.  **Integration Tests (10%)**: Flows across multiple layers (UI -> Repo -> Local DB).
    *   *Tools*: `integration_test`.
4.  **E2E Tests (5%)**: Critical flows in real environments.
    *   *Tools*: `Patrol` (for system permissions and web/native bridges).
5.  **Smoke Tests**: Quick post-deploy execution to verify app starts and basic login works.

## Priorities (Incremental Roadmap)

### Phase 1: Foundations and Auth (Current)
*   **Auth**: Registration, Login, Logout, Session Recovery.
*   **Infra**: Mocks/Fakes setup, CI integration.

### Phase 2: Transactions and Ledger
*   **Transactions**: CRUD, financial validations.
*   **Sync**: `SyncManager` and `OperationQueue` verification.

### Phase 3: Financial Core
*   **Budgets**: Envelopes, rollover, limits.
*   **Forecasting**: Deterministic projections.

### Phase 4: Pro Experience
*   **Workspace Switching**: Data isolation.
*   **Offline Experience**: Offline mode, conflict resolution.
*   **Installments/Recurring**: Payment and occurrence generation.

## Technical Strategy

| Tool | Usage | Tradeoff |
| :--- | :--- | :--- |
| `flutter_test` | Unit/Widget | Fast, no device needed. Does not test real integrations. |
| `integration_test` | Integration | Runs on device. Slower but high confidence. |
| `Patrol` | E2E | Handles native permissions and complex flows. More setup. |
| `Mocktail` | Mocking | Type-safe, easy to use. Avoid massive mocks. |
| `Supabase Local` | Backend | Reproducible environment. Requires Docker in CI. |

### Philosophy: Behavior-Driven
*   We don't test "if the button is blue", we test "if pressing the button subtracts the expense from the budget".
*   Prefer **Fakes** over **Mocks** for Repositories (in-memory databases).
