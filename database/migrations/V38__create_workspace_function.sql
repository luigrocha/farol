-- V38: SECURITY DEFINER function for workspace creation
--
-- The INSERT policy (V37) should work in theory, but auth.uid() matching
-- can fail in edge cases (e.g. session role mismatch). This function
-- follows the proven pattern already used by create_personal_workspace()
-- trigger — SECURITY DEFINER bypasses RLS entirely.
--
-- The Flutter app calls supabase.rpc('create_workspace', {...}) instead of
-- inserting directly, solving the 42501 error at the root.

CREATE OR REPLACE FUNCTION create_workspace(
  name TEXT,
  workspace_type TEXT DEFAULT 'personal',
  emoji TEXT DEFAULT NULL,
  color TEXT DEFAULT NULL,
  description TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  new_workspace_id UUID;
  result JSONB;
BEGIN
  INSERT INTO workspaces (name, owner_id, plan, workspace_type, emoji, color, description)
  VALUES (name, auth.uid(), 'free', workspace_type, emoji, color, description)
  RETURNING id INTO new_workspace_id;

  INSERT INTO workspace_members (workspace_id, user_id, role)
  VALUES (new_workspace_id, auth.uid(), 'owner');

  SELECT to_jsonb(w) INTO result
  FROM workspaces w
  WHERE w.id = new_workspace_id;

  RETURN result;
END;
$$;

COMMENT ON FUNCTION create_workspace IS 'Creates a workspace and adds the caller as the owner member. SECURITY DEFINER.';
