-- V42: SECURITY DEFINER RPC so invitees can decline workspace invites
--
-- Problem: RLS on workspace_invites only allows SELECT/INSERT for workspace
-- admins/owners. The invitee has no UPDATE policy, so a direct
--   UPDATE workspace_invites SET declined_at = ... WHERE token = ...
-- silently affects 0 rows and the owner never receives the 'declined'
-- notification from the V41 trigger.
--
-- Solution: A SECURITY DEFINER function that runs as the DB owner and
-- sets declined_at atomically, with guards against replaying.

CREATE OR REPLACE FUNCTION decline_workspace_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite workspace_invites%ROWTYPE;
BEGIN
  -- Look up the invite by token
  SELECT * INTO v_invite
    FROM workspace_invites
   WHERE token = p_token
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'invite_not_found');
  END IF;

  -- Guard: already accepted
  IF v_invite.accepted_at IS NOT NULL THEN
    RETURN jsonb_build_object('error', 'invite_already_used');
  END IF;

  -- Guard: already declined (idempotent — just return ok)
  IF v_invite.declined_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', true);
  END IF;

  -- Guard: expired
  IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < NOW() THEN
    RETURN jsonb_build_object('error', 'invite_expired');
  END IF;

  -- Set declined_at — this fires trg_notify_owner_invite_resolved (V41)
  UPDATE workspace_invites
     SET declined_at = NOW()
   WHERE id = v_invite.id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- Grant execute to authenticated users only
REVOKE ALL ON FUNCTION decline_workspace_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION decline_workspace_invite(TEXT) TO authenticated;
