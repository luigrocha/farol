# ADR-004: Sync Strategy — Optimistic Updates + Persistent Queue

**Date**: 2026-05-07
**Status**: Implemented ✅
**Area**: Infrastructure · Database

---

## Context

Farol is defined as "offline-first" in the original CLAUDE.md, but in practice the repositories use `SupabaseClient` directly without any offline strategy. If the user is on the subway without internet and tries to record an expense, the operation fails silently.

The dilemma: how much sync complexity justifies the current user base?

## Decision

**Strategy: Optimistic Updates + Persistent Operation Queue.**

This is not extreme offline-first (like Notion with CRDTs). It is **realistic offline-resilient**:

1. **Apply immediately to local state** (Drift) → UI responds instantly
2. **If network available → execute in Supabase** → remote confirmation
3. **If no network → queue in Drift** → automatic retry on reconnection
4. **Idempotency keys (UUID)** → never duplicate on retry
5. **Max 3 retries with exponential backoff** → if fails → mark failed, notify user

### What is NOT included

- CRDTs (conflict-free replicated data types) → unnecessary complexity for a single device
- Real-time bidirectional sync → polling on open + sync events is sufficient
- Sophisticated conflict resolution → Last-Write-Wins for 99% of cases

## Consequences

### Positive
- User can record expenses without internet → data is not lost
- UI always responds instantly (optimistic)
- Drift as a coherent cache of the current period
- Simple to understand and implement

### Negative / Trade-offs
- The queue can grow if the user is offline for a long time
- Local and remote data may temporarily diverge
- Sync errors take time to be visible to the user

### Accepted Risks
- **Queue overflow**: if the user records >500 operations offline → trim oldest. Very unlikely.
- **Idempotency key collisions**: UUID v4 → astronomically low probability.
- **Supabase rate limiting on batch sync**: mitigated with 100ms delay between requests.

## Alternatives Considered

### Alternative 1: Pure offline-first (CRDT/Automerge)
Each object has a CRDT. Automatic bidirectional sync.

**Discarded because**: Very high implementation complexity (weeks), Drift doesn't natively support CRDTs, overkill for a single device per user.

### Alternative 2: Online-only (current state)
Keep the current state: Supabase direct, no local cache.

**Discarded because**: A user on the subway can't record expenses. Data is lost if there's a network failure. Unacceptable for a personal finance app.

### Alternative 3: Firebase Firestore (native offline-first)
Migrate from Supabase to Firestore which has offline-first built-in.

**Discarded because**: Massive backend migration, Supabase has advantages (real SQL, RLS, RPCs), Firestore cost scales differently, the app already has significant investment in Supabase.

## Success Criteria

- [x] User can record expense without internet → appears immediately in UI
- [x] On reconnection → expense appears in Supabase → no duplicates
- [x] 0 data loss in scenario: offline expense → app closed → app opened → reconnected
- [x] Queue automatically clears completed items (doesn't grow indefinitely)

## References

- Implementation plan: `plans/offline_sync.md`
- Depends on: `plans/financial_engine.md` (domain entities)
- Revisit if there are users with multiple devices
