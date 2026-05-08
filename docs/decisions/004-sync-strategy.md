# ADR-004: Sync Strategy — Optimistic Updates + Persistent Queue

**Fecha**: 2026-05-07
**Estado**: Propuesto — pendiente de implementación
**Área**: Infrastructure · Database

---

## Contexto

Farol se define como "offline-first" en el CLAUDE.md original, pero en la práctica los repositories usan `SupabaseClient` directamente sin ninguna estrategia offline. Si el usuario está en el metro sin internet e intenta registrar un gasto, la operación falla silenciosamente.

El dilema: cuánta complejidad de sincronización justifica la base de usuarios actual?

## Decisión

**Estrategia: Optimistic Updates + Persistent Operation Queue.**

No es offline-first extremo (tipo Notion con CRDTs). Es **offline-resilient realista**:

1. **Aplicar inmediatamente al estado local** (Drift) → UI responde instantáneamente
2. **Si hay red → ejecutar en Supabase** → confirmación remota
3. **Si no hay red → encolar en Drift** → retry automático al reconectar
4. **Idempotency keys (UUID)** → nunca duplicar en retry
5. **Máx 3 retries con backoff exponencial** → si falla → marcar failed, notificar usuario

### Lo que NO incluye

- CRDTs (conflict-free replicated data types) → complejidad innecesaria para un único dispositivo
- Sincronización bidireccional en tiempo real → polling al abrir + sync events es suficiente
- Resolución de conflictos sofisticada → Last-Write-Wins para el 99% de casos

## Consecuencias

### Positivas
- Usuario puede registrar gastos sin internet → datos no se pierden
- UI siempre responde instantáneamente (optimistic)
- Drift como cache coherente del período actual
- Simple de entender e implementar

### Negativas / Trade-offs
- La queue puede crecer si el usuario está offline por mucho tiempo
- Los datos locales y remotos pueden divergir temporalmente
- Errores de sync tardan en ser visibles al usuario

### Riesgos aceptados
- **Queue overflow**: si el usuario registra >500 operaciones offline → trim oldest. Muy improbable.
- **Idempotency key collisions**: UUID v4 → probabilidad astronómicamente baja.
- **Supabase rate limiting en batch sync**: mitigado con 100ms delay entre requests.

## Alternativas Consideradas

### Alternativa 1: Offline-first puro (CRDT/Automerge)
Cada objeto tiene un CRDT. Sync bidireccional automático.

**Descartada porque**: Complejidad de implementación muy alta (semanas), Drift no soporta CRDTs nativamente, overkill para un único dispositivo por usuario.

### Alternativa 2: Solo online (estado actual)
Mantener el estado actual: Supabase directo, sin cache local.

**Descartada porque**: Un usuario en el metro no puede registrar gastos. Los datos se pierden si hay falla de red. No acceptable para una app de finanzas personales.

### Alternativa 3: Firebase Firestore (offline-first nativo)
Migrar de Supabase a Firestore que tiene offline-first built-in.

**Descartada porque**: Migración masiva del backend, Supabase tiene ventajas (SQL real, RLS, RPCs), el costo de Firestore escala diferente, la app ya tiene inversión significativa en Supabase.

## Criterios de Éxito

- [ ] Usuario puede registrar gasto sin internet → aparece inmediatamente en UI
- [ ] Al reconectar → gasto aparece en Supabase → sin duplicados
- [ ] 0 pérdida de datos en escenario: gasto offline → app cerrada → app abierta → reconexión
- [ ] Queue se limpia automáticamente de items completados (no crece indefinidamente)

## Referencias

- Plan de implementación: `plans/offline_sync.md`
- Depende de: `plans/financial_engine.md` (entidades del dominio)
- Revisitar si hay usuarios con múltiples dispositivos
