-- V40: user_notifications table + trigger to notify registered users on workspace invite

CREATE TABLE user_notifications (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL CHECK (type IN ('workspace_invite')),
  payload    JSONB       NOT NULL DEFAULT '{}',
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON user_notifications (user_id, read_at) WHERE read_at IS NULL;

ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users manage own notifications"
  ON user_notifications FOR ALL
  USING (user_id = auth.uid());

-- Trigger: insert notification when a workspace invite is created for a registered user
CREATE OR REPLACE FUNCTION notify_invited_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id        UUID;
  v_inviter_name   TEXT;
  v_workspace_name TEXT;
BEGIN
  SELECT id INTO v_user_id
    FROM auth.users
   WHERE email = NEW.invited_email
   LIMIT 1;

  IF v_user_id IS NULL THEN RETURN NEW; END IF;

  IF EXISTS (
    SELECT 1 FROM workspace_members
     WHERE workspace_id = NEW.workspace_id AND user_id = v_user_id
  ) THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_inviter_name  FROM profiles  WHERE id = NEW.invited_by;
  SELECT name         INTO v_workspace_name FROM workspaces WHERE id = NEW.workspace_id;

  INSERT INTO user_notifications (user_id, type, payload)
  VALUES (
    v_user_id,
    'workspace_invite',
    jsonb_build_object(
      'invite_token',    NEW.token,
      'workspace_id',    NEW.workspace_id::text,
      'workspace_name',  v_workspace_name,
      'invited_by_name', COALESCE(v_inviter_name, 'Someone'),
      'role',            NEW.role,
      'expires_at',      NEW.expires_at
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_invited_user
  AFTER INSERT ON workspace_invites
  FOR EACH ROW EXECUTE FUNCTION notify_invited_user();
