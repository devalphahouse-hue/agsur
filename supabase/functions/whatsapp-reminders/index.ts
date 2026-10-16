import { createClient } from "npm:@supabase/supabase-js@2";
import { templatePayload, constantTimeEqual, classifyMetaFailure } from "../_shared/whatsapp.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization,apikey,content-type,x-client-info,x-agsur-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, value: unknown) => Response.json(value, { status, headers: cors });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });
  const expected = Deno.env.get("WHATSAPP_DISPATCH_SECRET");
  const authorization = req.headers.get("Authorization") ?? "";
  const supplied = req.headers.get("x-agsur-cron-secret") ?? authorization.replace(/^Bearer /, "");
  const cron = Boolean(expected) && await constantTimeEqual(supplied, expected!);
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  if (!cron) {
    if (!authorization.startsWith("Bearer ")) return json(401, { error: "unauthorized" });
    const { data, error } = await db.auth.getUser(authorization.slice(7));
    if (error || !data?.user) return json(401, { error: "unauthorized" });
    const { data: caller, error: callerError } = await db.from("users").select("profile_type,is_active,is_deleted").eq("id", data.user.id).maybeSingle();
    if (callerError || !caller?.is_active || caller.is_deleted || !["Admin Master", "Admin", "Vendedor"].includes(caller.profile_type)) {
      return json(403, { error: "forbidden" });
    }
  }
  // Dry-run is explicitly configured on the server. It never calls Meta and is labelled in the history.
  const dryRun = Deno.env.get("WHATSAPP_DRY_RUN") === "true";
  const token = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
  const phoneId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  const version = Deno.env.get("WHATSAPP_GRAPH_VERSION");
  if (!dryRun && (!token || !phoneId || !/^\d+$/.test(phoneId) || !version || !/^v\d+\.\d+$/.test(version))) {
    return json(503, { error: "whatsapp_configuration_missing" });
  }
  const { data: jobs, error } = await db.rpc("claim_whatsapp_dispatches", { p_limit: 20, p_run_id: crypto.randomUUID() });
  if (error) return json(500, { error: "queue_unavailable" });
  let persistenceFailed = false;
  await Promise.all((jobs ?? []).map(async (job: {
    id: string; recipient_phone: string; message: string; claim_token: string; template_name: string; template_language: string;
  }) => {
    let messageId: string | null = null;
    let failure: string | null = null;
    let retriable = false;
    if (dryRun) {
      messageId = `dryrun.${job.claim_token}`;
    } else {
      try {
        const response = await fetch(`https://graph.facebook.com/${version}/${phoneId}/messages`, {
          method: "POST", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
          body: JSON.stringify(templatePayload(job.recipient_phone, job.message, job.id, job.template_name, job.template_language)),
          signal: AbortSignal.timeout(15000),
        });
        let body;
        try { body = await response.json(); } catch {
          // A successful but unreadable response may already represent an accepted send.
          failure = response.ok ? "dispatch_outcome_unknown" : `http_${response.status}`;
          retriable = !response.ok && (response.status === 429 || response.status >= 500);
        }
        if (body) {
          const id = body.messages?.[0]?.id;
          if (response.ok && typeof id === "string" && id.length > 0) messageId = id;
          else if (response.ok) failure = "dispatch_outcome_unknown";
          else {
            const classified = classifyMetaFailure(response.status, body.error?.code);
            failure = classified.code; retriable = classified.retriable;
          }
        }
      } catch {
        failure = "dispatch_outcome_unknown";
      }
    }
    const { error: saveError } = await db.rpc("complete_whatsapp_dispatch", {
      p_id: job.id, p_claim_token: job.claim_token, p_provider: dryRun ? "dryrun" : "meta",
      p_message_id: messageId, p_error: failure, p_retriable: retriable,
    });
    if (saveError) persistenceFailed = true;
  }));
  return json(persistenceFailed ? 500 : 200, { processed: jobs?.length ?? 0, dry_run: dryRun });
});
