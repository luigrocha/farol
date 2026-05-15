-- V44__spaces_backfill.sql
-- Sprint 1 — Backfill existing data into the new Spaces v2 schema
--
-- Maps existing workspace data into the new tables:
--   1. Creates a personal_ledger for every existing user (from personal workspaces)
--   2. Creates a space for every existing shared workspace
--   3. Copies space_members from workspace_members (shared workspaces only)
--   4. Seeds space_categories from the shared workspace's user-created categories
--   5. Updates create_personal_workspace() trigger so new signups also get a personal_ledger
--
-- All INSERTs use ON CONFLICT DO NOTHING — safe to re-run.
-- No existing rows in workspaces / workspace_members / expenses are modified.
-- space_transactions and ledger_contributions start empty; the new UX populates them.
--
-- Prerequisite: V43 applied.

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1 — personal_ledgers from personal workspaces
-- One per user who owns a personal workspace.
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO personal_ledgers (user_id, currency, cutoff_day, settings, created_at)
SELECT DISTINCT
  wm.user_id,
  COALESCE(w.settings->>'currency', 'BRL')          AS currency,
  COALESCE((w.settings->>'cutoffDay')::SMALLINT, 5) AS cutoff_day,
  COALESCE(w.settings, '{}'::jsonb)                 AS settings,
  w.created_at
FROM workspaces w
JOIN workspace_members wm ON wm.workspace_id = w.id AND wm.role = 'owner'
WHERE w.workspace_type = 'personal'
ON CONFLICT (user_id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2 — spaces from shared workspaces
-- One space per shared workspace. Preserves name, emoji, color, owner.
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO spaces (
  name, emoji, color, description, type,
  owner_id, currency, settings,
  legacy_workspace_id, created_at, updated_at
)
SELECT
  w.name,
  COALESCE(w.emoji, '👥')                           AS emoji,
  w.color,
  w.description,
  'household'                                        AS type,  -- default; owner can change later
  w.owner_id,
  COALESCE(w.settings->>'currency', 'BRL')          AS currency,
  COALESCE(w.settings, '{}'::jsonb)                 AS settings,
  w.id                                               AS legacy_workspace_id,
  w.created_at,
  w.updated_at
FROM workspaces w
WHERE w.workspace_type = 'shared'
  AND NOT EXISTS (
    SELECT 1 FROM spaces s WHERE s.legacy_workspace_id = w.id
  );

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3 — space_members from workspace_members (shared workspaces only)
-- Role mapping: owner→owner, admin→admin, member→member, viewer→viewer
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO space_members (space_id, user_id, role, invited_by, joined_at)
SELECT
  s.id AS space_id,
  wm.user_id,
  wm.role,
  wm.invited_by,
  wm.joined_at
FROM workspace_members wm
JOIN workspaces w  ON w.id  = wm.workspace_id AND w.workspace_type = 'shared'
JOIN spaces     s  ON s.legacy_workspace_id = w.id
ON CONFLICT (space_id, user_id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4 — seed space_categories from shared workspace categories
-- Only user-created categories (user_id IS NOT NULL).
-- ═══════════════════════════════════════════════════════════════════

-- categories.emoji → space_categories.icon
-- categories.financial_type uses need/want/investment/income/transfer
-- Map to space_categories.financial_type: income→income, transfer→transfer, all others→expense
INSERT INTO space_categories (space_id, name, icon, financial_type, sort_order, created_by, created_at)
SELECT
  s.id                                                               AS space_id,
  c.name,
  c.emoji                                                            AS icon,
  CASE
    WHEN c.financial_type = 'income'   THEN 'income'
    WHEN c.financial_type = 'transfer' THEN 'transfer'
    ELSE 'expense'
  END                                                                AS financial_type,
  ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY c.name)::SMALLINT  AS sort_order,
  c.user_id                                                          AS created_by,
  c.created_at
FROM categories c
JOIN workspaces w ON w.id = c.workspace_id AND w.workspace_type = 'shared'
JOIN spaces     s ON s.legacy_workspace_id = w.id
WHERE c.user_id IS NOT NULL   -- skip system categories
ON CONFLICT (space_id, name) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5 — Update new-user trigger
-- Extends create_personal_workspace() so every signup also gets a personal_ledger.
-- Replacing the function body is sufficient — the trigger on auth.users is already in place.
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION create_personal_workspace()
RETURNS TRIGGER AS $$
DECLARE
  new_workspace_id UUID;
  display_name     TEXT;
BEGIN
  display_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    split_part(NEW.email, '@', 1),
    'My Finances'
  );

  -- Create personal workspace (existing behaviour — V26 / V33)
  INSERT INTO public.workspaces (name, owner_id, plan, workspace_type, emoji)
  VALUES (display_name, NEW.id, 'free', 'personal', '🏠')
  RETURNING id INTO new_workspace_id;

  INSERT INTO public.workspace_members (workspace_id, user_id, role)
  VALUES (new_workspace_id, NEW.id, 'owner');

  -- New (V44): also create a personal_ledger
  INSERT INTO public.personal_ledgers (user_id, currency, cutoff_day)
  VALUES (NEW.id, 'BRL', 5)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES (run after applying)
-- ═══════════════════════════════════════════════════════════════════

-- 1. personal_ledgers count should match users with personal workspaces:
-- SELECT COUNT(*) FROM personal_ledgers;
-- SELECT COUNT(DISTINCT wm.user_id) FROM workspace_members wm
--   JOIN workspaces w ON w.id = wm.workspace_id
--   WHERE w.workspace_type = 'personal' AND wm.role = 'owner';

-- 2. spaces count should match shared workspaces:
-- SELECT COUNT(*) FROM spaces;
-- SELECT COUNT(*) FROM workspaces WHERE workspace_type = 'shared';

-- 3. Every space has at least one owner member:
-- SELECT id, name FROM spaces s
-- WHERE NOT EXISTS (
--   SELECT 1 FROM space_members sm WHERE sm.space_id = s.id AND sm.role = 'owner'
-- );
-- → 0 rows

-- 4. No orphaned space_members (space_id must exist):
-- SELECT COUNT(*) FROM space_members sm
-- WHERE NOT EXISTS (SELECT 1 FROM spaces s WHERE s.id = sm.space_id);
-- → 0

-- 5. Trigger updated — new signups get a personal_ledger:
-- SELECT prosrc FROM pg_proc WHERE proname = 'create_personal_workspace';
-- → body should contain 'personal_ledgers'
