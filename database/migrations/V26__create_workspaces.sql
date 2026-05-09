-- V26__create_workspaces.sql
-- Workspace model: workspaces + workspace_members + workspace_invites.
-- Adds personal workspace auto-creation trigger for every new auth user.
-- Prerequisite: V1–V25 applied.

-- ─── workspaces ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS workspaces (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  slug            TEXT,
  owner_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan            TEXT NOT NULL DEFAULT 'free'
                  CHECK (plan IN ('free', 'premium')),
  plan_expires_at TIMESTAMPTZ,               -- NULL = free forever
  settings        JSONB NOT NULL DEFAULT '{}', -- cutoffDay, currency, etc.
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── workspace_members ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS workspace_members (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          TEXT NOT NULL DEFAULT 'member'
                CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  invited_by    UUID REFERENCES auth.users(id),
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (workspace_id, user_id)
);

-- ─── workspace_invites ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS workspace_invites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'member'
                CHECK (role IN ('admin', 'member', 'viewer')),
  token         TEXT NOT NULL UNIQUE DEFAULT gen_random_uuid()::text,
  invited_by    UUID NOT NULL REFERENCES auth.users(id),
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days',
  accepted_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Indexes ──────────────────────────────────────────────────

CREATE INDEX ON workspace_members (user_id);
CREATE INDEX ON workspace_members (workspace_id);
CREATE INDEX ON workspace_invites (token);
CREATE INDEX ON workspace_invites (invited_email);

-- ─── Row Level Security ───────────────────────────────────────

ALTER TABLE workspaces        ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_invites ENABLE ROW LEVEL SECURITY;

-- workspaces: any member can read
CREATE POLICY "workspace_members_can_select"
  ON workspaces FOR SELECT
  USING (
    id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid())
  );

-- workspaces: owner can update
CREATE POLICY "workspace_owner_can_update"
  ON workspaces FOR UPDATE
  USING (owner_id = auth.uid());

-- workspace_members: members can see who else is in the same workspace
CREATE POLICY "members_can_see_members"
  ON workspace_members FOR SELECT
  USING (
    workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid())
  );

-- workspace_members: owner/admin can add members
CREATE POLICY "admin_can_insert_members"
  ON workspace_members FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- workspace_members: owner can remove anyone; member can remove themselves
CREATE POLICY "owner_can_delete_members"
  ON workspace_members FOR DELETE
  USING (
    user_id = auth.uid()
    OR workspace_id IN (
      SELECT workspace_id FROM workspace_members
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

-- workspace_invites: admin+ can create invites
CREATE POLICY "admin_can_create_invites"
  ON workspace_invites FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- workspace_invites: admin+ can view invites for their workspace
CREATE POLICY "admin_can_see_invites"
  ON workspace_invites FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- ─── Trigger: auto-update updated_at ──────────────────────────

CREATE OR REPLACE FUNCTION update_workspace_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workspace_updated_at
  BEFORE UPDATE ON workspaces
  FOR EACH ROW EXECUTE FUNCTION update_workspace_updated_at();

-- ─── Trigger: personal workspace for every new user ───────────

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_personal_workspace();

CREATE OR REPLACE FUNCTION create_personal_workspace()
RETURNS TRIGGER AS $$
DECLARE
  new_workspace_id UUID;
  display_name     TEXT;
BEGIN
  display_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    split_part(NEW.email, '@', 1),
    'My Workspace'
  );

  INSERT INTO public.workspaces (name, owner_id, plan)
  VALUES (display_name, NEW.id, 'free')
  RETURNING id INTO new_workspace_id;

  INSERT INTO public.workspace_members (workspace_id, user_id, role)
  VALUES (new_workspace_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_personal_workspace();

-- Verification (run after applying):
-- SELECT COUNT(*) FROM workspaces;       -- 0 for new installs (trigger fires on new users)
-- SELECT COUNT(*) FROM workspace_members;
-- V28 handles backfill for existing users.
