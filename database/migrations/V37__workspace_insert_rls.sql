-- V37: Add INSERT policies for workspace creation flow
--
-- Two bugs fixed:
--   1. No INSERT policy on workspaces → authenticated users cannot create
--      workspaces from the Flutter app (anon key). The auto-creation trigger
--      works because it's SECURITY DEFINER, but WorkspaceRepository.create()
--      runs as the authenticated user.
--   2. workspace_members INSERT policy uses get_my_workspace_ids_as_admin(),
--      which queries workspace_members — the first member (owner) isn't there
--      yet → chicken-and-egg. Need a helper to check workspace ownership.

-- ─── Fix 1: Allow authenticated users to create workspaces ──────
-- The user can only set themselves as owner.

CREATE POLICY "authenticated_users_can_create_workspaces"
  ON workspaces FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- ─── Fix 2: Allow workspace owner to insert self as first member ─

-- Helper: workspace IDs where the user is the owner (bypasses RLS via
-- SECURITY DEFINER, avoiding recursion with workspaces SELECT policy).
CREATE OR REPLACE FUNCTION get_owned_workspace_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.workspaces WHERE owner_id = auth.uid();
$$;

-- Replace the INSERT policy on workspace_members to also allow the
-- owner to insert themselves (as 'owner' role) when creating a workspace.
DROP POLICY IF EXISTS "admin_can_insert_members" ON workspace_members;

CREATE POLICY "owner_can_insert_self_or_admin_can_insert"
  ON workspace_members FOR INSERT
  WITH CHECK (
    -- Existing: admin+ can add members (via the SECURITY DEFINER helper)
    workspace_id IN (SELECT get_my_workspace_ids_as_admin())
    OR
    -- New: workspace owner inserting themselves as the first member
    (
      user_id = auth.uid()
      AND role = 'owner'
      AND workspace_id IN (SELECT get_owned_workspace_ids())
    )
  );

-- ─── Verification ──────────────────────────────────────────────
-- After applying, test from the Flutter app:
--   1. Create a shared workspace → should succeed (was error 42501)
--   2. Invite a member → should still work
--   3. Sign up a new user → personal workspace still auto-created

COMMENT ON POLICY "authenticated_users_can_create_workspaces" ON workspaces
  IS 'Any authenticated user can create a workspace (must set owner_id = own uid)';

COMMENT ON POLICY "owner_can_insert_self_or_admin_can_insert" ON workspace_members
  IS 'Owner inserts self as first member; admin+ can add others';
