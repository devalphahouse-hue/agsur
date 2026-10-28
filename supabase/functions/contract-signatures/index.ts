import { createClient } from 'npm:@supabase/supabase-js@2';
import { Clicksign, type ClicksignConfig } from '../_shared/clicksign.ts';
import { constantTimeEqual } from '../_shared/whatsapp.ts';
import { processSignature, processSignatureEvent } from '../_shared/signature_workflow.ts';

const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization,apikey,content-type,x-client-info,x-agsur-signature-secret', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS' };
const json = (status: number, data: unknown) => Response.json(data, { status, headers: cors });
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (!['GET', 'POST'].includes(req.method)) return json(405, { error: 'method_not_allowed' });
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const environment = Deno.env.get('CLICKSIGN_ENVIRONMENT');
  const token = Deno.env.get('CLICKSIGN_ACCESS_TOKEN');
  const configured = ['sandbox', 'production'].includes(environment ?? '') && Boolean(token) && Boolean(Deno.env.get('CLICKSIGN_WEBHOOK_SECRET'));
  const enabled = Deno.env.get('CLICKSIGN_ENABLED') === 'true';
  if (req.method === 'GET') {
    const auth = req.headers.get('authorization') ?? '';
    if (!auth.startsWith('Bearer ')) return json(401, { error: 'unauthorized' });
    const { data, error } = await db.auth.getUser(auth.slice(7));
    if (error || !data.user) return json(401, { error: 'unauthorized' });
    const { data: caller, error: callerError } = await db.from('users').select('profile_type,is_active,is_deleted').eq('id', data.user.id).maybeSingle();
    if (callerError || !caller?.is_active || caller.is_deleted || !['Admin Master', 'Admin', 'Vendedor'].includes(caller.profile_type)) return json(403, { error: 'forbidden' });
    return json(200, { provider: 'clicksign', configured, enabled: enabled && configured, environment: configured ? environment : null });
  }
  const secret = Deno.env.get('SIGNATURE_DISPATCH_SECRET');
  if (!secret || !await constantTimeEqual(req.headers.get('x-agsur-signature-secret') ?? '', secret)) return json(401, { error: 'unauthorized' });
  if (!configured || !enabled) return json(503, { error: 'clicksign_configuration_pending' });
  const provider = new Clicksign({ environment, token } as ClicksignConfig);
  try {
    // Validate token before claiming. Invalid credentials leave documents queued.
    await provider.request('/envelopes?page[size]=1');
    const { data: events, error: eventError } = await db.rpc('signature_claim_events', { p_environment: environment });
    if (eventError) throw new Error('inbox_unavailable');
    for (const event of events ?? []) await processSignatureEvent(db, provider, event);
    const { data: jobs, error } = await db.rpc('signature_claim_clicksign', { p_environment: environment });
    if (error) throw new Error('queue_unavailable');
    for (const job of jobs ?? []) await processSignature(db, provider, job);
    return json(200, { processed: jobs?.length ?? 0, events: events?.length ?? 0, environment });
  } catch { return json(503, { error: 'signature_processing_unavailable' }); }
});
