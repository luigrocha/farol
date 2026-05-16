/**
 * send-space-notification
 *
 * Sends FCM push notifications to all members of a space, excluding the actor.
 * Uses Firebase Cloud Messaging HTTP v1 API with a service-account JWT.
 *
 * POST /functions/v1/send-space-notification
 * Auth: Bearer <service-role key>  (called server-side, not from the user JWT)
 *
 * Body:
 * {
 *   spaceId:     string,           // target space
 *   event:       string,           // 'added_transaction' | 'deleted_transaction' |
 *                                  // 'recorded_settlement' | 'member_joined'
 *   actorUserId: string,           // user who triggered the event (excluded from recipients)
 *   actorName:   string,           // display name for notification body
 *   payload: {
 *     label?:  string,             // entity label (transaction description)
 *     amount?: number,             // formatted on server side
 *   }
 * }
 *
 * Returns:
 *   200 { sent: N, failed: M }
 *   400 { error: "missing_fields" | "invalid_body" }
 *   500 { error: "internal_error", detail: string }
 *
 * Required Supabase secrets:
 *   FIREBASE_SERVICE_ACCOUNT_JSON  — full service-account JSON from Firebase console
 *   FIREBASE_PROJECT_ID            — e.g. "farol-prod"
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── CORS headers ──────────────────────────────────────────────────────────────
const CORS_HEADERS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// ── Notification copy ─────────────────────────────────────────────────────────

const BRL = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });

function buildMessage(event: string, actorName: string, spaceName: string, payload: Record<string, unknown>) {
  const amount = typeof payload.amount === "number" ? BRL.format(payload.amount) : null;
  const label  = typeof payload.label  === "string"  ? payload.label  : null;

  const title = spaceName;
  let   body: string;

  switch (event) {
    case "added_transaction":
      body = label && amount
        ? `${actorName} adicionou ${label} — ${amount}`
        : `${actorName} adicionou um gasto`;
      break;
    case "deleted_transaction":
      body = label
        ? `${actorName} removeu ${label}`
        : `${actorName} removeu um gasto`;
      break;
    case "recorded_settlement":
      body = amount
        ? `${actorName} registrou um acerto de ${amount}`
        : `${actorName} registrou um acerto`;
      break;
    case "member_joined":
      body = `${actorName} entrou no espaço 🎉`;
      break;
    default:
      body = `${actorName} realizou uma ação`;
  }

  return { title, body };
}

// ── FCM HTTP v1 helpers ───────────────────────────────────────────────────────

/**
 * Exchanges the service-account JSON for a short-lived OAuth2 access token
 * to authenticate FCM HTTP v1 API requests.
 *
 * Uses the built-in Web Crypto API available in Deno Deploy.
 */
async function getFcmAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson);

  const now   = Math.floor(Date.now() / 1000);
  const claim = {
    iss:   sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud:   "https://oauth2.googleapis.com/token",
    exp:   now + 3600,
    iat:   now,
  };

  // Build JWT header + payload
  const header  = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" })).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const payload = btoa(JSON.stringify(claim)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const sigInput = `${header}.${payload}`;

  // Import private key
  const pemBody  = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const keyData  = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Sign
  const encoder = new TextEncoder();
  const sigBuf  = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, encoder.encode(sigInput));
  const sig     = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const jwt = `${sigInput}.${sig}`;

  // Exchange JWT for access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    const err = await tokenRes.text();
    throw new Error(`Failed to get FCM access token: ${err}`);
  }

  const tokenData = await tokenRes.json();
  return tokenData.access_token as string;
}

async function sendFcmMessage(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  accessToken: string,
  projectId: string,
): Promise<boolean> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(url, {
    method:  "POST",
    headers: {
      Authorization:  `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: { priority: "high" },
        apns:    { headers: { "apns-priority": "10" } },
      },
    }),
  });
  return res.ok;
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_body" }, 400);
  }

  const { spaceId, event, actorUserId, actorName, payload } = body as {
    spaceId:     string;
    event:       string;
    actorUserId: string;
    actorName:   string;
    payload:     Record<string, unknown>;
  };

  if (!spaceId || !event || !actorUserId || !actorName) {
    return json({ error: "missing_fields" }, 400);
  }

  // Service-role client to bypass RLS
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const projectId           = Deno.env.get("FIREBASE_PROJECT_ID");
  const serviceAccountJson  = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

  if (!projectId || !serviceAccountJson) {
    return json({ error: "internal_error", detail: "Missing Firebase env vars" }, 500);
  }

  try {
    // 1. Fetch all member user_ids for this space (excluding the actor)
    const { data: members, error: membersErr } = await supabase
      .from("space_members")
      .select("user_id")
      .eq("space_id", spaceId)
      .neq("user_id", actorUserId);

    if (membersErr) throw membersErr;
    if (!members || members.length === 0) {
      return json({ sent: 0, failed: 0 });
    }

    const memberIds = members.map((m: { user_id: string }) => m.user_id);

    // 2. Fetch push tokens for all recipients
    const { data: tokenRows, error: tokensErr } = await supabase
      .from("push_tokens")
      .select("token, platform")
      .in("user_id", memberIds);

    if (tokensErr) throw tokensErr;
    if (!tokenRows || tokenRows.length === 0) {
      return json({ sent: 0, failed: 0 });
    }

    // 3. Fetch space name for notification title
    const { data: spaceRow } = await supabase
      .from("spaces")
      .select("name, emoji")
      .eq("id", spaceId)
      .single();

    const spaceName = spaceRow
      ? `${spaceRow.emoji ?? ""} ${spaceRow.name}`.trim()
      : "Farol";

    // 4. Build notification content
    const { title, body: notifBody } = buildMessage(event, actorName, spaceName, payload ?? {});

    const data: Record<string, string> = {
      spaceId,
      event,
      ...(payload?.label  ? { label:  String(payload.label) }  : {}),
      ...(payload?.amount ? { amount: String(payload.amount) } : {}),
    };

    // 5. Get FCM access token (one token, reused for all sends)
    const accessToken = await getFcmAccessToken(serviceAccountJson);

    // 6. Send to each token
    let sent = 0, failed = 0;
    await Promise.all(
      tokenRows.map(async (row: { token: string; platform: string }) => {
        const ok = await sendFcmMessage(row.token, title, notifBody, data, accessToken, projectId);
        if (ok) sent++; else failed++;
      }),
    );

    return json({ sent, failed });
  } catch (e) {
    console.error("[send-space-notification]", e);
    return json({ error: "internal_error", detail: String(e) }, 500);
  }
});
