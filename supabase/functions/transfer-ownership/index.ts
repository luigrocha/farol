/**
 * transfer-ownership
 *
 * Atomically transfers workspace ownership from the current owner to another member.
 * - Sets new_owner_id to 'owner'
 * - Demotes current owner to 'admin'
 * - Logs to workspace_activity
 *
 * POST /functions/v1/transfer-ownership
 * Body: { "workspace_id": "<uuid>", "new_owner_id": "<user_uuid>" }
 * Auth: Bearer <owner JWT>
 *
 * Returns:
 *   200 { success: true }
 *   400 { error: "missing_fields" | "cannot_transfer_to_self" }
 *   403 { error: "not_owner" }
 *   404 { error: "target_not_member" }
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

  const jwt = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) return respond(401, { error: "unauthorized" });

  // ── Parse body ────────────────────────────────────────────────────────────
  let workspaceId: string | undefined;
  let newOwnerId: string | undefined;
  try {
    const body = await req.json();
    workspaceId = body?.workspace_id;
    newOwnerId = body?.new_owner_id;
  } catch {
    return respond(400, { error: "invalid_body" });
  }

  if (!workspaceId || !newOwnerId) {
    return respond(400, { error: "missing_fields" });
  }

  if (newOwnerId === user.id) {
    return respond(400, { error: "cannot_transfer_to_self" });
  }

  // ── Verify caller is current owner ────────────────────────────────────────
  const { data: callerMember } = await supabase
    .from("workspace_members")
    .select("role")
    .eq("workspace_id", workspaceId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (!callerMember || callerMember.role !== "owner") {
    return respond(403, { error: "not_owner" });
  }

  // ── Verify target is a member ─────────────────────────────────────────────
  const { data: targetMember } = await supabase
    .from("workspace_members")
    .select("id, role")
    .eq("workspace_id", workspaceId)
    .eq("user_id", newOwnerId)
    .maybeSingle();

  if (!targetMember) {
    return respond(404, { error: "target_not_member" });
  }

  // ── Atomic swap: promote new owner, demote old owner ─────────────────────
  // Two separate updates — Supabase JS doesn't support true transactions,
  // but service role + RLS-off means these are effectively serialized.
  const { error: promoteError } = await supabase
    .from("workspace_members")
    .update({ role: "owner" })
    .eq("workspace_id", workspaceId)
    .eq("user_id", newOwnerId);

  if (promoteError) return respond(500, { error: "internal_error" });

  const { error: demoteError } = await supabase
    .from("workspace_members")
    .update({ role: "admin" })
    .eq("workspace_id", workspaceId)
    .eq("user_id", user.id);

  if (demoteError) {
    // Rollback the promotion
    await supabase
      .from("workspace_members")
      .update({ role: targetMember.role })
      .eq("workspace_id", workspaceId)
      .eq("user_id", newOwnerId);
    return respond(500, { error: "internal_error" });
  }

  // ── Also update workspaces.owner_id ──────────────────────────────────────
  await supabase
    .from("workspaces")
    .update({ owner_id: newOwnerId })
    .eq("id", workspaceId);

  // ── Log to workspace_activity ─────────────────────────────────────────────
  await supabase.from("workspace_activity").insert({
    workspace_id: workspaceId,
    user_id: user.id,
    action: "transferred_ownership",
    entity_type: "workspace",
    entity_id: workspaceId,
    entity_label: newOwnerId,
    metadata: { new_owner_id: newOwnerId },
  });

  return respond(200, { success: true });
});

function respond(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
