import { createClient } from "npm:@supabase/supabase-js@2";
import { validSignature } from "../_shared/whatsapp.ts";

Deno.serve(async (req) => {
  const url = new URL(req.url);
  if (req.method === "GET") {
    const token = Deno.env.get("WHATSAPP_WEBHOOK_VERIFY_TOKEN");
    return token && url.searchParams.get("hub.mode") === "subscribe" && url.searchParams.get("hub.verify_token") === token
      ? new Response(url.searchParams.get("hub.challenge"), { status: 200 })
      : new Response(null, { status: 403 });
  }
  if (req.method !== "POST") return new Response(null, { status: 405 });
  const secret = Deno.env.get("WHATSAPP_APP_SECRET");
  if (!secret) return new Response(null, { status: 503 });
  const raw = await req.text();
  if (!await validSignature(raw, req.headers.get("x-hub-signature-256"), secret)) return new Response(null, { status: 401 });
  let body;
  try { body = JSON.parse(raw); } catch { return new Response(null, { status: 400 }); }
  if (body.object !== "whatsapp_business_account") return new Response(null, { status: 400 });
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  for (const entry of body.entry ?? []) {
    for (const change of entry.changes ?? []) {
      if (change.value?.metadata?.phone_number_id !== Deno.env.get("WHATSAPP_PHONE_NUMBER_ID")) continue;
      for (const status of change.value?.statuses ?? []) {
        if (!["sent", "delivered", "read", "failed"].includes(status.status)) continue;
        const seconds = Number(status.timestamp);
        if (!Number.isFinite(seconds) || seconds <= 0) return new Response(null, { status: 400 });
        const reminderId = status.biz_opaque_callback_data;
        const { error } = await db.rpc("record_whatsapp_status", {
          p_message_id: status.id, p_status: status.status,
          p_at: new Date(seconds * 1000).toISOString(), p_error: String(status.errors?.[0]?.code ?? "delivery_failed"),
          p_reminder_id: typeof reminderId === "string" && /^[a-f0-9-]{36}$/i.test(reminderId) ? reminderId : null,
        });
        if (error) return new Response(null, { status: 500 });
      }
    }
  }
  return new Response("ok");
});
