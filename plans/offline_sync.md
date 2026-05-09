# Plan: Offline Sync & Operation Queue
**Area**: Infrastructure · Database · Sync  
**Priority**: P3  
**Dependencies**: `financial_engine.md` (complete) — queue operates on engine entities  
**Files impacted**: `app_database.dart`, new in `lib/core/infrastructure/sync/`

---

## 🔍 Problem Context

### Current state (confirmed in code)

```dart
// App uses Supabase directly in all repositories
class InstallmentRepository {
  final SupabaseClient _supabase;

  Future<int> insert({...}) async {
    // No network → throws SocketException
    // No retry, no queue, no user feedback
    final result = await _supabase.from('card_installments').insert({...});
    return result;
  }
}

// SupabaseRealtimeManager existe pero no hay sync bidireccional
class SupabaseRealtimeManager {
  // Subscriptions para updates remotos
  // Pero si el cliente está offline → los updates se pierden
}
```

### El problema concreto
- Usuario en el metro registra un gasto → error silencioso
- Usuario sin wifi no puede ver su historial (no hay cache local coherente)
- El Drift schema existe pero los repositorios no lo usan como cache

### ¿Qué NO necesitamos?
- CRDTs (conflict-free replicated data types) → overkill
- Sincronización bidireccional compleja → un solo dispositivo por usuario
- Offline-first extremo tipo Notion → complejidad innecesaria

### ¿Qué SÍ necesitamos?
- Registrar gastos sin red → operación encolada → ejecutar al reconectar
- Ver datos del período actual sin red → cache local en Drift
- Sin pérdida de datos nunca → queue persistente en Drift
- Sin duplicados en retry → idempotency keys (UUID)

---

## 📐 Proposed Architecture

### Diagrama de flujo

```
Usuario registra gasto
        │
        ▼
SyncManager.execute(InsertExpenseOp)
        │
        ├── applyLocally() → Drift insert (inmediato, optimista)
        │      └── UI se actualiza inmediatamente ✓
        │
        ├── [¿hay red?]
        │   ├── SÍ → executeRemote(supabase) → markCompleted()
        │   └── NO → enqueue(op) → UI muestra indicador "sync pendiente"
        │
        └── Al reconectar → processPending() → retry con backoff
```

### News archivos a create

```
lib/core/infrastructure/
└── sync/
    ├── sync_manager.dart         ← orquestador principal
    ├── operation_queue.dart      ← queue persistente en Drift
    ├── sync_operations.dart      ← tipos de operaciones soportadas
    └── conflict_resolver.dart    ← resolución de conflictos
```

### Extension de AppDatabase para la queue

```dart
// Nueva tabla en Drift
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();      // 'insert_expense' | 'update_envelope' | ...
  TextColumn get payload => text()();            // JSON serializado
  TextColumn get idempotencyKey => text().unique()(); // UUID — evita duplicados en retry
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}
```

---

## ⚡ Impact Analysis

### Archivos a create (sin tocar repositorios existentes)
```
lib/core/infrastructure/sync/sync_manager.dart
lib/core/infrastructure/sync/operation_queue.dart
lib/core/infrastructure/sync/sync_operations.dart
lib/core/infrastructure/sync/conflict_resolver.dart
```

### Archivos a modificar
```
lib/core/database/app_database.dart   ← agregar SyncQueueItems table (migration v3)
lib/core/repositories/expense_repository.dart  ← envolver en SyncManager
```

### Breaking Changes
| Change | Severidad | Mitigación |
|---|---|---|
| Drift schema v3 (nueva tabla) | 🟡 MEDIO | Migration `onUpgrade` simple — solo add table |
| Repositories pasan por SyncManager | 🟡 MEDIO | Wrapper pattern — interface sin cambios |

---

## 🗺️ Incremental Strategy

### PHASE 1 — Connectivity Detection + Indicador UI
**Objetivo**: La app sabe si hay red y lo muestra.
**Reversibilidad**: 100%.

```
Task 1.1: Agregar connectivity_plus package
  - Stream<ConnectivityResult> → provider Riverpod
  - connectivityProvider

Task 1.2: ConnectivityBanner en UI
  - Banner discreto en la parte superior del dashboard
  - "Sin conexión · Los datos se sincronizarán al reconectar"
  - Solo visible cuando isOffline == true
  - No bloquear la UI — solo informar
```

---

### PHASE 2 — Operation Queue (el core)
**Objetivo**: Operaciones encoladas que sobreviven reinicios de app.
**Reversibilidad**: Alta — la queue es aditiva.

```
Task 2.1: Agregar SyncQueueItems a AppDatabase
  - Drift migration schemaVersion: 3
  - CREATE TABLE sync_queue_items (...)
  - DAOs: insertQueueItem, getPendingItems, markCompleted, markFailed, incrementRetry

Task 2.2: Create SyncOperation abstract class
  - operationType: String
  - idempotencyKey: String (UUID generado al create la op)
  - payload: Map<String, dynamic>
  - applyLocally(): Future<void>  ← write a Drift
  - executeRemote(SupabaseClient): Future<void>  ← write a Supabase
  - fromJson/toJson para serialización

Task 2.3: Implementar OperationQueue
  - enqueue(SyncOperation op): guarda en Drift
  - processPending(): itera pending, ejecuta remote, actualiza status
  - Backoff exponencial: retry 1 → espera 5s, retry 2 → 15s, retry 3 → fail
  - Max 3 retries → marcar como 'failed', notificar al usuario

Task 2.4: Implementar InsertExpenseOperation (primera operación)
  - applyLocally() → Drift insert expense
  - executeRemote() → Supabase insert expense
  - Usar el mismo idempotencyKey como expense.id (UUID) para evitar duplicados
```

---

### PHASE 3 — SyncManager
**Objetivo**: Orquestador que decide sync inmediato vs encolado.

```
Task 3.1: Create SyncManager
  - Inyecta: OperationQueue, ConnectivityMonitor, SupabaseClient
  - execute(SyncOperation): aplica local inmediatamente
    → si online: ejecuta remote, si falla: encola
    → si offline: encola directamente

Task 3.2: ConnectivityMonitor listener
  - Al detectar reconexión (offline → online):
    → processPending() automáticamente
    → Notificar UI con conteo de ops sincronizadas

Task 3.3: SyncStatusProvider en Riverpod
  - pendingCount: int
  - lastSyncAt: DateTime?
  - isSyncing: bool
  - hasFailedOps: bool
```

---

### PHASE 4 — Wrap Expense Repository
**Objetivo**: El repositorio más crítico pasa por SyncManager.

```
Task 4.1: Refactorizar ExpenseRepository.insert()
  - En vez de: await _supabase.from('expenses').insert(...)
  - New: await _syncManager.execute(InsertExpenseOperation(payload))
  - Interface externa idéntica — sin breaking changes para providers

Task 4.2: Cache local de expenses en Drift
  - Al cargar expenses del período: primero Drift, luego Supabase
  - Al recibir datos de Supabase: actualizar cache Drift
  - Drift como cache de lectura, Supabase como fuente de verdad

Task 4.3: Test offline → online
  - Simular corte de red
  - Registrar 3 gastos
  - Restaurar red → verificar que los 3 se sincronizan sin duplicados
```

---

### PHASE 5 — Conflict Resolution
**Objetivo**: Manejar el caso de multi-dispositivo o sesión recuperada.
**Nota**: Para usuario con un solo dispositivo, esto es raro. Implementar simple.

```
Task 5.1: Last-Write-Wins por defecto
  - Todos los objetos tienen updated_at
  - Al sync: si hay conflicto, gana el updated_at más reciente

Task 5.2: Merge semántico para envelopes
  - Si dos sesiones modificaron el mismo envelope:
    → allocated: el mayor valor gana
    → spent: se recalcula desde transactions (fuente de verdad)

Task 5.3: Indicador de conflicto resuelto en UI
  - Log en docs/decisions/ si hay conflictos frecuentes en producción
```

---

## 🚨 Risks and Mitigations

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Drift migration v3 falla en upgrade | Baja | Crash al actualizar | Test migration en emulador antes de release |
| Queue crece infinito (usuario sin red por semanas) | Muy baja | Storage uso | Limit queue a 500 items, oldest fail first |
| Duplicados en Supabase si idempotencyKey no funciona | Media | Datos duplicados | UNIQUE constraint en Supabase sobre idempotency_key |
| offline → online spike de requests | Media | Rate limit Supabase | Procesar queue con delay entre items (100ms) |
| Estado local y remoto divergen > 24h | Baja | Inconsistencia visible | Force sync al abrir app si last_sync > 24h |

---

## ✅ Completion Checklist

### Phase 1 — Connectivity
- [ ] `connectivity_plus` integrado
- [ ] `connectivityProvider` en Riverpod
- [ ] Banner offline en UI (discreto)

### Phase 2 — Operation Queue
- [ ] `SyncQueueItems` tabla en Drift (migration v3)
- [ ] `SyncOperation` abstract class con idempotencyKey
- [ ] `OperationQueue` con backoff exponencial
- [ ] `InsertExpenseOperation` implementada

### Phase 3 — SyncManager
- [ ] `SyncManager.execute()` con lógica online/offline
- [ ] Auto-procesamiento de queue al reconectar
- [ ] `SyncStatusProvider` en Riverpod

### Phase 4 — Expense Repository
- [ ] `ExpenseRepository.insert()` pasa por SyncManager
- [ ] Cache local de expenses en Drift
- [ ] Test offline → online: sin duplicados

### Phase 5 — Conflict Resolution
- [ ] Last-Write-Wins implementado
- [ ] Merge semántico para envelopes
- [ ] Documentar en `docs/decisions/004-sync-strategy.md`

---

## 📎 References

- Análisis detallado: `FAROL_PREDICTIVE_ENGINE.md` → Sección 9
- ADR pendiente: `docs/decisions/004-sync-strategy.md`
- Depends on: `financial_engine.md`
- Unblocks: multi-dispositivo futuro, Open Finance integrations
