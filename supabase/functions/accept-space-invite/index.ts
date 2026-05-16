/**
 * accept-space-invite
 *
 * Validates a space invite token, creates the space_members row,
 * and returns the space data so the caller can immediately navigate to it.
 *
 * POST /functions/v1/accept-space-invite
 * Body: { "token": "<invite_token>" }
 * Auth: Bearer <user JWT>
 *
 * Returns:
 *   200 { space: { id, name, emoji, color, type } }
 *   400 { error: "missing_token" | "invalid_body" }
 *   401 { error: "unauthorized" }
 *   404 { error: "invite_not_found" }
 *   405 { error: "method_not_allowed" }
 *   409 { error: "already_member" }
 *   410 { error: "invite_expired" | "invite_already_used" }
 *   500 { error: "internal_error" }
 *
 * Mirrors accept-workspace-invite exactly, adapted for spaces:
 *   workspace_invites  → space_invites
 *   workspace_members  → space_members
 *   workspaces         → spaces (columns: id, name, emoji, color, type)
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── CORS headers ──────────────────────────────────────────────────────────────
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return respond(405, { error: "method_not_allowed" });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond(401, { error: "unauthorized" });

  // Use service-role key so we can bypass space_invites RLS
  // (invitee has no membership yet → cannot SELECT their own invite row).
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify the caller's JWT and resolve their user ID.
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
    .from("space_invites")
    .select("id, space_id, role, expires_at, accepted_at, declined_at")
    .eq("token", token)
    .maybeSingle();

  if (inviteError) return respond(500, { error: "internal_error" });
  if (!invite)     return respond(404, { error: "invite_not_found" });

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
    .from("space_members")
    .select("id")
    .eq("space_id", invite.space_id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (existing) return respond(409, { error: "already_member" });

  // ── Create membership ─────────────────────────────────────────────────────
  const { error: insertError } = await supabase
    .from("space_members")
    .insert({
      space_id: invite.space_id,
      user_id:  user.id,
      role:     invite.role ?? "member",
    });

  if (insertError) return respond(500, { error: "internal_error" });

  // ── Mark invite as accepted ───────────────────────────────────────────────
  await supabase
    .from("space_invites")
    .update({ accepted_at: new Date().toISOString() })
    .eq("id", invite.id);

  // ── Return space data ─────────────────────────────────────────────────────
  const { data: space, error: spaceError } = await supabase
    .from("spaces")
    .select("id, name, emoji, color, type")
    .eq("id", invite.space_id)
    .single();

  if (spaceError || !space) return respond(500, { error: "internal_error" });

  // ── Log member_joined to space_activity ──────────────────────────────────
  // Fetch display name for the notification body.
  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name, email")
    .eq("id", user.id)
    .maybeSingle();

  const actorName: string =
    profile?.display_name ?? profile?.email?.split("@")[0] ?? user.id.substring(0, 6);

  // Insert activity row (bypasses RLS via service role).
  await supabase.from("space_activity").insert({
    space_id:     invite.space_id,
    user_id:      user.id,
    action:       "member_joined",
    entity_type:  "space_member",
    entity_label: actorName,
    metadata:     {},
  });

  // ── Dispatch push notification to existing members ────────────────────────
  // Fire-and-forget — invite acceptance succeeds even if push delivery fails.
  try {
    await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/send-space-notification`, {
      method: "POST",
      headers: {
        Authorization:  `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        spaceId:     invite.space_id,
        event:       "member_joined",
        actorUserId: user.id,
        actorName,
        payload:     {},
      }),
    });
  } catch (e) {
    console.warn("[accept-space-invite] push notification failed:", e);
  }

  return respond(200, { space });
});

function respond(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}
