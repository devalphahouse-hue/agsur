import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { stripTypeScriptTypes } from 'node:module';
import { createHmac } from 'node:crypto';
import { templatePayload, validSignature, constantTimeEqual, classifyMetaFailure } from '../functions/_shared/whatsapp.ts';

async function handler(file, env, db) {
  globalThis.Deno = { env: { get: (key) => env[key] }, serve: (fn) => { globalThis.__handler = fn; } };
  globalThis.__createClient = () => db;
  let source = await readFile(new URL(`../functions/${file}/index.ts`, import.meta.url), 'utf8');
  source = source.replace(/import \{ createClient \} from .*?;/, 'const createClient = globalThis.__createClient;');
  source = source.replace(/from "\.\.\/_shared\/whatsapp.ts"/, `from "${new URL('../functions/_shared/whatsapp.ts', import.meta.url).href}"`);
  await import(`data:text/javascript;base64,${Buffer.from(stripTypeScriptTypes(source)).toString('base64')}#${Math.random()}`);
  return globalThis.__handler;
}
const env = { WHATSAPP_DISPATCH_SECRET: 'dispatch-secret', WHATSAPP_ACCESS_TOKEN: 'meta-token', WHATSAPP_PHONE_NUMBER_ID: '123', WHATSAPP_GRAPH_VERSION: 'v99.0', WHATSAPP_TEMPLATE_NAME: 'reminder', WHATSAPP_APP_SECRET: 'app-secret', WHATSAPP_WEBHOOK_VERIFY_TOKEN: 'verify' };
const post = () => new Request('https://local.test', { method: 'POST', headers: { Authorization: 'Bearer dispatch-secret' } });

test('template is addressed individually and normalizes body whitespace', () => {
  const p = templatePayload('5511999999999', 'Nota\n com\t espaços', 'job-1', 'reminder', 'pt_BR');
  assert.equal(p.type, 'template');
  assert.equal(p.messaging_product, 'whatsapp');
  assert.equal(p.to, '5511999999999');
  assert.equal(p.biz_opaque_callback_data, 'job-1');
  assert.equal(p.template.components[0].parameters[0].text, 'Nota com espaços');
});
test('webhook signature rejects missing, forged and altered bodies', async () => {
  const raw = '{"test":true}';
  const sig = `sha256=${createHmac('sha256', 'secret').update(raw).digest('hex')}`;
  assert.equal(await validSignature(raw, sig, 'secret'), true);
  assert.equal(await validSignature(`${raw} `, sig, 'secret'), false);
  assert.equal(await validSignature(raw, sig, 'different'), false);
  assert.equal(await validSignature(raw, null, 'secret'), false);
});
test('worker never claims without its secret or configured Meta settings', async () => {
  const db = { rpc: () => { throw new Error('must not claim'); }, auth: {getUser: async () => ({error:true})} };
  const run = await handler('whatsapp-reminders', env, db);
  assert.equal((await run(new Request('https://local.test', { method: 'POST' }))).status, 401);
  assert.equal((await run(new Request('https://local.test'))).status, 405);
  const missing = await handler('whatsapp-reminders', { ...env, WHATSAPP_ACCESS_TOKEN: '' }, db);
  assert.equal((await missing(post())).status, 503);
});
test('worker records accepted, rejected and uncertain outcomes; sends only once per item', async () => {
  const oldFetch = globalThis.fetch;
  try {
    for (const outcome of ['accepted', 'rejected', 'timeout']) {
      let calls = 0;
      let stored;
      const db = {
        rpc: async (name, data) => {
          if(name==='complete_whatsapp_dispatch'){stored=data;return {data:true};}
          assert.equal(name, 'claim_whatsapp_dispatches'); return { data: [{ id: 'job-1', claim_token:'claim-1', recipient_phone: '5511999999999', message: 'Teste', template_name:'reminder',template_language:'pt_BR' }] };
        },
      };
      globalThis.fetch = async (url, options) => {
        calls++;
        assert.equal(url, 'https://graph.facebook.com/v99.0/123/messages');
        assert.equal(options.headers.Authorization, 'Bearer meta-token');
        if (outcome === 'timeout') throw new Error('timeout');
        return Response.json(outcome === 'accepted' ? { messages: [{ id: 'wamid.1' }] } : { error: { code: 132001 } }, { status: outcome === 'accepted' ? 200 : 400 });
      };
      const run = await handler('whatsapp-reminders', env, db);
      assert.equal((await run(post())).status, 200);
      assert.equal(calls, 1);
      assert.equal(stored.p_provider, 'meta');
      assert.equal(stored.p_retriable, false);
      if (outcome === 'timeout') assert.equal(stored.p_error, 'dispatch_outcome_unknown');
      if (outcome === 'accepted') assert.equal(stored.p_message_id, 'wamid.1');
    }
  } finally { globalThis.fetch = oldFetch; }
});
test('webhook verification and signed delivery events', async () => {
  const updates = [];
  const run = await handler('whatsapp-webhook', env, { rpc: async (name, params) => { updates.push([name, params]); return {}; } });
  assert.equal((await run(new Request('https://local.test?hub.mode=subscribe&hub.verify_token=verify&hub.challenge=123'))).status, 200);
  assert.equal((await run(new Request('https://local.test?hub.mode=subscribe&hub.verify_token=wrong'))).status, 403);
  const body = JSON.stringify({ object: 'whatsapp_business_account', entry: [{ changes: [{ value: { metadata: { phone_number_id: '123' }, statuses: [{ id: 'wamid.1', status: 'delivered', timestamp: '1790000000', biz_opaque_callback_data: '11111111-1111-1111-1111-111111111111' }] } }] }] });
  const signed = `sha256=${createHmac('sha256', env.WHATSAPP_APP_SECRET).update(body).digest('hex')}`;
  assert.equal((await run(new Request('https://local.test', { method: 'POST', body }))).status, 401);
  assert.equal(updates.length, 0);
  assert.equal((await run(new Request('https://local.test', { method: 'POST', body, headers: { 'x-hub-signature-256': signed } }))).status, 200);
  assert.equal(updates[0][1].p_status, 'delivered');
  assert.equal(updates[0][1].p_reminder_id, '11111111-1111-1111-1111-111111111111');
});

test('dispatch secrets and Meta retry classification', async () => {
 assert.equal(await constantTimeEqual('secret','secret'),true);
 assert.equal(await constantTimeEqual('secret','wrong'),false);
 for(const code of [190,131009,131026,131042,132000,132001]) assert.equal(classifyMetaFailure(500,code).retriable,false);
 assert.equal(classifyMetaFailure(429,130429).retriable,true);
 assert.equal(classifyMetaFailure(503,undefined).retriable,true);
 assert.equal(classifyMetaFailure(400,999).retriable,false);
});
test('worker rejects client JWT and accepts CORS preflight without dispatch', async () => {
 const db={auth:{getUser:async()=>({data:{user:{id:'client'}}})},from:()=>({select:()=>({eq:()=>({maybeSingle:async()=>({data:{is_active:true,is_deleted:false,profile_type:'Cliente'}})})})}),rpc:()=>{throw new Error('must not dispatch');}};
 const run=await handler('whatsapp-reminders',env,db);
 assert.equal((await run(new Request('https://local.test',{method:'POST',headers:{Authorization:'Bearer client-jwt'}}))).status,403);
 assert.equal((await run(new Request('https://local.test',{method:'OPTIONS'}))).status,200);
});
