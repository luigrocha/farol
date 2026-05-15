# Sprint 1 — Spaces v2 Foundation
## Implementation Plan

> **Status:** Complete (2026-05-15) — migrations + models + repository + providers written  
> **Architecture reference:** `docs/architecture/workspace_architecture_v2.md`  
> **Sprint 2:** Complete (2026-05-15) — CreateSpaceSheet, AddSpaceTransactionSheet, SpaceDashboardScreen, context switcher extended  
> **Next:** Sprint 3 — Space settings, settlement flow, full transaction list, member management

---

## What was built

### Database migrations

| File | Description |
|---|---|
| `V43__spaces_foundation.sql` | Creates 9 new tables + 3 SECURITY DEFINER helper functions + full RLS |
| `V44__spaces_backfill.sql` | Backfills personal_ledgers + spaces + space_members + space_categories from existing workspace data. Also updates `create_personal_workspace()` trigger |

### Dart files

| File | Description |
|---|---|
| `lib/core/models/space.dart` | `Space`, `SpaceMember`, `SpaceType`, `SpaceRole`, `SplitRule` |
| `lib/core/models/space_transaction.dart` | `SpaceTransaction`, `SpaceTransactionShare`, `SpaceCategory`, `SpaceSettlement`, `LedgerContribution`, `PersonalLedger`, `MemberBalance`, `SettlementSuggestion` |
| `lib/core/repositories/space_repository.dart` | Full CRUD + Splitwise algorithm |
| `lib/core/providers/space_providers.dart` | Riverpod providers (all `autoDispose`) |

---

## Key design decisions made in this sprint

### Decision 1: Purely additive migration
No existing tables (workspaces, workspace_members, expenses, etc.) were modified. The new schema lives alongside the old one. This allows:
- Zero risk of breaking existing functionality
- Gradual migration of UX from "workspace" to "space" model
- Rollback is possible by simply not running V40/V41

### Decision 2: `personal_ledgers` is 1:1, never joinable
RLS policy: `user_id = auth.uid()` — no exceptions, no sharing, no roles.
This is enforced at DB level, making it impossible to expose via any API call regardless of application bugs.

### Decision 3: `ledger_contributions` as bridge, not duplication
Instead of copying space transaction data into the personal ledger, `ledger_contributions` holds a reference (`share_id`) and the amount. Cascade deletes keep them in sync. This satisfies the mathematical consistency rule:

```
Personal monthly spend = SUM(private expenses) + SUM(ledger_contributions)
```

No double-counting, no stale data.

### Decision 4: `space_transaction_shares` with sum validation at repo layer
The DB has a UNIQUE constraint on `(transaction_id, user_id)` to prevent duplicate shares, but the SUM validation (`shares == transaction.amount`) is done in `SpaceRepository.createTransaction()` before any INSERT. This allows atomic multi-row inserts without the complexity of a deferred trigger.

### Decision 5: Splitwise simplification in Dart, not SQL
The debt simplification algorithm runs in `SpaceRepository.computeSettlements()` as pure Dart. Results are saved to `space_settlements` only when the user explicitly triggers a settlement cycle. This keeps the DB simple and the algorithm easy to test.

### Decision 6: Capability overrides on `space_members`
Five nullable boolean columns (`can_add_expenses`, `can_see_balances`, etc.) allow per-member overrides without a custom role. This supports the "Solo gastos" UX preset without adding a new role enum value.

---

## Applying the migrations

```bash
# Apply in order — must run sequentially
# Via Supabase dashboard: SQL Editor → paste and run

# Step 1
cat database/migrations/V43__spaces_foundation.sql | supabase db push

# Step 2
cat database/migrations/V44__spaces_backfill.sql | supabase db push

# Or via Supabase CLI if using linked project:
supabase db push
```

### Verification after V43
```sql
-- 9 new tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'personal_ledgers','spaces','space_members','space_invites',
    'space_categories','space_transactions','space_transaction_shares',
    'space_settlements','ledger_contributions'
  )
ORDER BY table_name;
-- Expected: 9 rows

-- 3 helper functions
SELECT proname FROM pg_proc
WHERE proname IN ('get_my_space_ids','get_my_space_ids_as_writer','get_my_space_ids_as_admin');
-- Expected: 3 rows
```

### Verification after V41
```sql
-- personal_ledgers count = users with personal workspace
SELECT COUNT(*) FROM personal_ledgers;

-- spaces count = shared workspaces
SELECT COUNT(*) FROM spaces;
SELECT COUNT(*) FROM workspaces WHERE workspace_type = 'shared'; -- should match

-- No space missing its owner as member
SELECT id, name FROM spaces s
WHERE NOT EXISTS (
  SELECT 1 FROM space_members sm
  WHERE sm.space_id = s.id AND sm.role = 'owner'
);
-- Expected: 0 rows
```

---

## How to use in Sprint 2

### Creating a space from UI
```dart
final repo = ref.read(spaceRepositoryProvider);

// 1. Create the space
final space = await repo.createSpace(
  name: 'Casa',
  type: SpaceType.household,
  emoji: '🏠',
);

// 2. Seed default categories
await repo.createDefaultCategories(space.id, SpaceType.household);

// 3. Set as active
await ref.read(activeSpaceProvider.notifier).select(space);

// 4. Invalidate list
ref.invalidate(userSpacesProvider);
```

### Adding a shared expense
```dart
final tx = await repo.createTransaction(
  spaceId:    space.id,
  categoryId: category.id,
  amount:     1800.00,
  description: 'Aluguel maio',
  date:       DateTime.now(),
  splitRule:  SplitRule.equal,
  sharesPerUser: {
    currentUserId: 900.00,
    partnerId:     900.00,
  },
);

// Optionally link to personal ledger
final myShare = tx.shares.firstWhere((s) => s.userId == currentUserId);
await repo.linkToLedger(
  spaceId:           space.id,
  shareId:           myShare.id,
  amount:            myShare.amount,
  date:              tx.date,
  ledgerCategoryId:  personalMoradiaCategory.id, // user picks
);
```

### Computing and saving settlements
```dart
// 1. Compute (pure, no DB write)
final suggestions = await repo.computeSettlements(space.id);

// 2. Show to user for confirmation

// 3. Save
await repo.saveSettlements(space.id, suggestions,
  periodStart: DateTime(2026, 5, 1),
  periodEnd:   DateTime(2026, 5, 31),
);

// 4. Invalidate
ref.invalidate(pendingSettlementsProvider);
```

---

## Remaining Sprint 1 TODOs (none — sprint complete)

- [x] V43 migration — all 9 tables + RLS
- [x] V44 backfill — personal_ledgers, spaces, space_members, space_categories
- [x] `space.dart` model
- [x] `space_transaction.dart` model (includes PersonalLedger, LedgerContribution)
- [x] `space_repository.dart` — full CRUD + settlement algorithm
- [x] `space_providers.dart` — Riverpod providers

---

## Sprint 2 scope (next)

- `CreateSpaceSheet` — type picker, emoji/color, category checklist, invite step
- `AddSpaceTransactionSheet` — amount, category, split rule, ledger link toggle
- `SpaceDashboardScreen` — budget envelopes, recent transactions, member avatars
- Context switcher redesign — "Personal" + Spaces list, privacy lock icon
- Privacy indicators in UI
