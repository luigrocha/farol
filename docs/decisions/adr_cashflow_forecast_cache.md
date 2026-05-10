# ADR: Cashflow Forecast Cache — Client-Side TTL vs. Supabase Edge Function

**Date:** 2026-05-08
**Status:** Accepted ✅
**Context:** Task #23 — optimize analytics screen performance (90-day cashflow chart)

---

## Context

The `cashflowForecastProvider` makes 4 async queries when the analytics screen opens:
1. `pendingInstallmentPaymentsProvider` (Supabase)
2. `pendingRecurringOccurrencesProvider` (Supabase)
3. `expenseRepositoryProvider.getAll()` (Supabase — potentially hundreds of records)
4. `ForecastingEngine.buildProjection(buildForecastChart: true)` — 90-day simulation

On slow devices or slow connections, this introduces a visible delay every time the user opens the analytics screen.

---

## Decision: Client-Side Cache with TTL (instead of Supabase Edge Function)

### Rejected option: Supabase Edge Function

**Why it was considered:** An Edge Function co-located with the database would execute queries without network latency between client and DB, and could serve cached results to multiple users.

**Why it was rejected:**

1. **Personal data, not shared.** Each user has 100% different data. A server-side cache has no sharing benefit — it is essentially a per-user session cache, identical to client-side.

2. **Logic duplication.** The `ForecastingEngine` is pure Dart with `Money` (cents as int). Rewriting it in TypeScript/Deno creates two implementations that must be kept in sync. High risk of divergence.

3. **No Edge Function infrastructure exists in the project.** There is no `supabase/functions/` directory. Creating from scratch includes: deploy pipeline setup, secrets, CORS, JWT authentication, monitoring.

4. **Breaks offline-first.** The app uses `SyncManager` + Drift to work without network. An Edge Function would require a fallback to local computation anyway — the Edge Function would just be an online optimization that duplicates code.

5. **Domain entities without JSON serialization.** `CashflowForecast`, `BurnRate`, `LiquidityRisk`, `ScheduledPayment` had no `toJson`/`fromJson`. Implementing them for all entities to consume the Edge Function response would be the same amount of work — with no extra benefit.

### Chosen option: Client-Side Cache in Drift UserSettings

**Implementation:**
- `ForecastCacheRepository` persists serialized `CashflowForecast` in `UserSettings['cashflow_forecast_cache']`
- Cache key includes the financial period (`periodStart_periodEnd`) — period change = automatic cache miss
- TTL: 2 hours (configurable in `ForecastCacheRepository._ttl`)
- `cashflowForecastProvider` checks the cache first; on cache hit, recomputes only `BurnRate`/`LiquidityRisk`/`projectedClosing` from the live snapshot and attaches the cached chart

**Advantages:**
- ✅ Works 100% offline (data already in Drift)
- ✅ Zero new infrastructure
- ✅ Calculation logic exists in a single place (Dart)
- ✅ Re-opening the analytics screen within 2h: instant
- ✅ Period change: automatic cache miss

**Known limitation:**
- If the user adds transactions and reopens analytics within 2h, the chart may show slightly stale data. Acceptable: the `InsightsPanel` and `BurnRateCard` on the dashboard always use live data (not cached).

---

## Additional items implemented in the same session

- `CashflowDataPoint.toJson`/`fromJson` and `CashflowForecast.toJson`/`fromJson` added to the domain entity (pure values, no I/O — acceptable)
- `forecastCacheRepositoryProvider` added to `providers.dart`
