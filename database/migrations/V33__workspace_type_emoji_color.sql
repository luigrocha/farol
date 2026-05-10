-- V33: Add workspace type, emoji, color, and description columns
-- Supports the collaborative workspace UX (personal vs shared spaces)

ALTER TABLE workspaces
  ADD COLUMN IF NOT EXISTS workspace_type TEXT NOT NULL DEFAULT 'personal'
    CHECK (workspace_type IN ('personal', 'shared')),
  ADD COLUMN IF NOT EXISTS emoji TEXT,
  ADD COLUMN IF NOT EXISTS color TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT;

-- Backfill: workspaces with >1 member are shared, solo ones remain personal
UPDATE workspaces w
SET workspace_type = 'shared'
WHERE EXISTS (
  SELECT 1 FROM workspace_members wm
  WHERE wm.workspace_id = w.id
  GROUP BY wm.workspace_id
  HAVING COUNT(*) > 1
);

-- Default emojis by type
UPDATE workspaces
SET emoji = CASE
  WHEN workspace_type = 'shared' THEN '👥'
  ELSE '🏠'
END
WHERE emoji IS NULL;

COMMENT ON COLUMN workspaces.workspace_type IS 'personal | shared — determines UX and chip visibility';
COMMENT ON COLUMN workspaces.emoji IS 'Single emoji displayed in WorkspaceAppBarChip and switcher';
COMMENT ON COLUMN workspaces.color IS 'Hex color string (e.g. #4CAF50) for workspace accent';
COMMENT ON COLUMN workspaces.description IS 'Optional description shown in the workspace switcher';

-- Update the new-user trigger to also set workspace_type and emoji
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

  INSERT INTO public.workspaces (name, owner_id, plan, workspace_type, emoji)
  VALUES (display_name, NEW.id, 'free', 'personal', '🏠')
  RETURNING id INTO new_workspace_id;

  INSERT INTO public.workspace_members (workspace_id, user_id, role)
  VALUES (new_workspace_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
