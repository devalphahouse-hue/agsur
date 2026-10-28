import { createClient } from 'npm:@supabase/supabase-js@2';
import { limitedBytes, parseClicksignEvent, sha256 } from '../_shared/clicksign.ts';
import { validSignature } from '../_shared/whatsapp.ts';

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response(null, { status: 405 });
  const secret = Deno.env.get('CLICKSIGN_WEBHOOK_SECRET');
  const environment = Deno.env.get('CLICKSIGN_ENVIRONMENT');
  if (!secret || !['sandbox', 'production'].includes(environment ?? '')) return new Response(null, { status: 503 });
  const header = req.headers.get('content-hmac');
  if (!header || !/^sha256=[a-f0-9]{64}$/i.test(header)) return new Response(null, { status: 401 });
  let raw: Uint8Array;
  try { raw = await limitedBytes(new Response(req.body, { headers: req.headers }), 256 * 1024); }
  catch { return new Response(null, { status: 413 }); }
  const text = new TextDecoder().decode(raw);
  if (!await validSignature(text, header, secret)) return new Response(null, { status: 401 });
  let event;
  try { event = parseClicksignEvent(JSON.parse(text)); }
  catch { return new Response(null, { status: 400 }); }
  if (!event) return new Response(null, { status: 204 });
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  // Acknowledge only after durable storage; retries and duplicate callbacks are safe.
  const { error } = await db.rpc('signature_ingest_clicksign', {
    p_id: await sha256(raw), p_document: event.document, p_environment: environment,
    p_name: event.name, p_at: event.at, p_email: event.email,
  });
  return new Response(null, { status: error ? 503 : 202 });
});
