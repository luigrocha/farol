-- V41: Invite decline support + owner notifications on accept/decline
--
-- Changes:
--   1. workspace_invites: add declined_at column
--   2. user_notifications: add 'invite_accepted' and 'invite_declined' types
--   3. Function + trigger to notify workspace owner when invite is accepted or declined

-- ── 1. workspace_invites: declined_at column ──────────────────────────────────

ALTER TABLE workspace_invites
  ADD COLUMN IF NOT EXISTS declined_at TIMESTAMPTZ;

-- ── 2. user_notifications: expand type constraint ─────────────────────────────

ALTER TABLE user_notifications
  DROP CONSTRAINT IF EXISTS user_notifications_type_check;

ALTER TABLE user_notifications
  ADD CONSTRAINT user_notifications_type_check
  CHECK (type IN ('workspace_invite', 'invite_accepted', 'invite_declined'));

-- ── 3. Function: notify workspace owner when invite resolves ──────────────────

CREATE OR REPLACE FUNCTION notify_owner_invite_resolved()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_action           TEXT;
  v_owner_id         UUID;
  v_invitee_name     TEXT;
  v_workspace_name   TEXT;
  v_notification_type TEXT;
BEGIN
  -- Only fire when accepted_at or declined_at is newly set (was NULL before)
  IF TG_OP = 'UPDATE' THEN
    IF NEW.accepted_at IS NOT NULL AND OLD.accepted_at IS NULL THEN
      v_action := 'accepted';
      v_notification_type := 'invite_accepted';
    ELSIF NEW.declined_at IS NOT NULL AND OLD.declined_at IS NULL THEN
      v_action := 'declined';
      v_notification_type := 'invite_declined';
    ELSE
      RETURN NEW; -- nothing changed that we care about
    END IF;
  ELSE
    RETURN NEW;
  END IF;

  -- Get workspace owner
  SELECT owner_id INTO v_owner_id
    FROM workspaces
   WHERE id = NEW.workspace_id;

  IF v_owner_id IS NULL THEN RETURN NEW; END IF;

  -- Get invitee display name (they must now be in profiles if they accepted)
  SELECT COALESCE(p.display_name, p.email, 'Someone')
    INTO v_invitee_name
    FROM profiles p
    JOIN auth.users u ON u.id = p.id
   WHERE u.email = NEW.invited_email
   LIMIT 1;

  SELECT name INTO v_workspace_name
    FROM workspaces
   WHERE id = NEW.workspace_id;

  -- Don't notify the owner about themselves
  IF v_owner_id = NEW.invited_by THEN
    -- Still notify if someone else invited on owner's behalf
    NULL;
  END IF;

  INSERT INTO user_notifications (user_id, type, payload)
  VALUES (
    v_owner_id,
    v_notification_type,
    jsonb_build_object(
      'invitee_name',   COALESCE(v_invitee_name, NEW.invited_email),
      'invitee_email',  NEW.invited_email,
      'workspace_name', v_workspace_name,
      'workspace_id',   NEW.workspace_id::text,
      'role',           NEW.role,
      'action',         v_action
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_owner_invite_resolved
  AFTER UPDATE ON workspace_invites
  FOR EACH ROW EXECUTE FUNCTION notify_owner_invite_resolved();
