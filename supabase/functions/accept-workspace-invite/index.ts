/**
 * accept-workspace-invite
 *
 * Validates a workspace invite token, creates the workspace_member row,
 * and returns the workspace data so the caller can immediately switch to it.
 *
 * POST /functions/v1/accept-workspace-invite
 * Body: { "token": "<invite_token>" }
 * Auth: Bearer <user JWT>
 *
 * Returns:
 *   200 { workspace: { id, name, emoji, color, workspace_type } }
 *   400 { error: "missing_token" }
 *   404 { error: "invite_not_found" }
 *   410 { error: "invite_expired" }
 *   409 { error: "already_member" }
 *   500 { error: "internal_error" }
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return respond(405, { error: "method_not_allowed" });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond(401, { error: "unauthorized" });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify JWT and get caller's user ID
  const jwt = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) return respond(401, { error: "unauthorized" });

  // ── Parse body ────────────────────────────────────────────────────────────
  let token: string | undefined;
  try {
    const body = await req.json();
    token = body?.token;
  } catch {
    return respond(400, { error: "invalid_body" });
  }

  if (!token) return respond(400, { error: "missing_token" });

  // ── Look up invite ────────────────────────────────────────────────────────
  const { data: invite, error: inviteError } = await supabase
    .from("workspace_invites")
    .select("id, workspace_id, role, expires_at, accepted_at")
    .eq("token", token)
    .maybeSingle();

  if (inviteError) return respond(500, { error: "internal_error" });
  if (!invite) return respond(404, { error: "invite_not_found" });

  // Check expiry
  if (invite.expires_at && new Date(invite.expires_at) < new Date()) {
    return respond(410, { error: "invite_expired" });
  }

  // Check already accepted
  if (invite.accepted_at) {
    return respond(410, { error: "invite_already_used" });
  }

  // ── Check if already a member ─────────────────────────────────────────────
  const { data: existing } = await supabase
    .from("workspace_members")
    .select("id")
    .eq("workspace_id", invite.workspace_id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (existing) return respond(409, { error: "already_member" });

  // ── Create membership ─────────────────────────────────────────────────────
  const { error: insertError } = await supabase
    .from("workspace_members")
    .insert({
      workspace_id: invite.workspace_id,
      user_id: user.id,
      role: invite.role ?? "member",
    });

  if (insertError) return respond(500, { error: "internal_error" });

  // ── Mark invite as accepted ───────────────────────────────────────────────
  await supabase
    .from("workspace_invites")
    .update({ accepted_at: new Date().toISOString() })
    .eq("id", invite.id);

  // ── Log to workspace_activity ─────────────────────────────────────────────
  await supabase.from("workspace_activity").insert({
    workspace_id: invite.workspace_id,
    user_id: user.id,
    action: "joined_workspace",
    entity_type: "workspace",
    entity_id: invite.workspace_id,
    entity_label: "workspace",
  });

  // ── Return workspace data ─────────────────────────────────────────────────
  const { data: workspace } = await supabase
    .from("workspaces")
    .select("id, name, emoji, color, workspace_type")
    .eq("id", invite.workspace_id)
    .single();

  return respond(200, { workspace });
});

function respond(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
