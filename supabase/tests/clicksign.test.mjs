import test from 'node:test';
import assert from 'node:assert/strict';
import {createHmac} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {stripTypeScriptTypes} from 'node:module';
import {Clicksign,ProviderError,parseClicksignEvent,sha256} from '../functions/_shared/clicksign.ts';
import {processSignature,processSignatureEvent} from '../functions/_shared/signature_workflow.ts';
const envelope='10000000-0000-0000-0000-000000000001';
const document='20000000-0000-0000-0000-000000000002';
const signer='30000000-0000-0000-0000-000000000003';
const pdf=new TextEncoder().encode('%PDF-1.7\ndemonstration');
const config={environment:'sandbox',token:'test-only-api-token'};
const env={SUPABASE_URL:'https://test.invalid',SUPABASE_SERVICE_ROLE_KEY:'test-only-service',CLICKSIGN_ENVIRONMENT:'sandbox',CLICKSIGN_ACCESS_TOKEN:config.token,CLICKSIGN_WEBHOOK_SECRET:'test-hmac',CLICKSIGN_ENABLED:'true',SIGNATURE_DISPATCH_SECRET:'worker-secret'};
async function handler(file,values,db){
 globalThis.Deno={env:{get:key=>values[key]},serve:fn=>{globalThis.__signatureHandler=fn;}};
 globalThis.__signatureDb=db;
 const url=new URL(`../functions/${file}/index.ts`,import.meta.url);
 let source=await readFile(url,'utf8');
 source=source.replace(/import \{ createClient \} from '[^']+';/,'const createClient=()=>globalThis.__signatureDb;');
 source=source.replace(/from '(\.\.[^']+)'/g,(_,path)=>`from '${new URL(path,url).href}'`);
 await import(`data:text/javascript;base64,${Buffer.from(stripTypeScriptTypes(source)).toString('base64')}#${Math.random()}`);
 return globalThis.__signatureHandler;
}
test('Clicksign v3 uploads exact PDF, creates two requirements per signer, activates and NOTIFIES',async()=>{
 const before=globalThis.fetch;const calls=[];
 try{
  globalThis.fetch=async(url,options)=>{
   assert.equal(options.headers.Authorization,config.token);assert.equal(options.redirect,'error');
   const body=JSON.parse(options.body);calls.push({url,body,method:options.method});
   if(url.endsWith('/envelopes'))return Response.json({data:{id:envelope}});
   if(url.endsWith('/documents')){
    assert.equal(body.data.attributes.content_base64,`data:application/pdf;base64,${Buffer.from(pdf).toString('base64')}`);
    return Response.json({data:{id:document}});
   }
   if(url.endsWith('/signers'))return Response.json({data:{id:signer}});
   return Response.json({data:{}});
  };
  const p=new Clicksign(config);const id=await p.create('Agsur test');const doc=await p.document(id,pdf);const s=await p.signer(id,'Teste','test@example.invalid');
  await p.requirements(id,doc,s);await p.activate(id);await p.notify(id);
  assert.equal(calls.length,7);assert.equal(calls[3].body.data.attributes.action,'agree');assert.equal(calls[4].body.data.attributes.auth,'email');
  assert.equal(calls[5].method,'PATCH');assert.equal(calls[6].body.data.type,'notifications');
 }finally{globalThis.fetch=before;}
});
test('provider never follows redirects or leaks Authorization to PDF downloads; blocks arbitrary hosts',async()=>{
 const before=globalThis.fetch;let malicious=false;let downloaded=0;
 try{
  globalThis.fetch=async(url,options)=>{
   url=String(url);
   if(url.endsWith(`/envelopes/${envelope}`))return Response.json({data:{id:envelope,attributes:{status:'closed'}}});
   if(url.endsWith(`/documents/${document}`))return Response.json({data:{id:document,links:{files:{signed:malicious?'https://169.254.169.254/secret':'https://clicksign-content-sandbox.s3.amazonaws.com/final.pdf'}}}});
   downloaded++;assert.equal(options.headers,undefined);assert.equal(options.redirect,'error');return new Response(pdf);
  };
  const p=new Clicksign(config);assert.deepEqual(await p.signedPdf(envelope,document),pdf);assert.equal(downloaded,1);
  malicious=true;await assert.rejects(p.signedPdf(envelope,document),/pdf_host_not_allowed/);assert.equal(downloaded,1);
 }finally{globalThis.fetch=before;}
});
test('worker checks private PDF hash BEFORE any provider mutation, and preserves unknown create outcomes',async()=>{
 let calls=0;const writes=[];
 const db={from:()=>({select:()=>({eq:()=>({single:async()=>({data:{cancelled_at:null}})})})}),
 storage:{from:()=>({download:async()=>({data:new Blob([pdf])})})},
 rpc:async(name,params)=>{writes.push({name,params});return {data:true};}};
 const p={create:async()=>{calls++;throw new ProviderError('clicksign_outcome_unknown',true);}};
 const job={id:envelope,contract_id:document,source_path:'source.pdf',source_sha256:'bad',worker_claim:signer,signers:[{name:'Teste',email:'test@example.invalid'}]};
 await processSignature(db,p,job);assert.equal(calls,0);assert.equal(writes.at(-1).params.p_error,'source_hash_mismatch');assert.equal(writes.at(-1).params.p_uncertain,false);
 job.source_sha256=await sha256(pdf);await processSignature(db,p,job);assert.equal(calls,1);assert.equal(writes.at(-1).params.p_uncertain,true);
});
test('checkpoint failure stops external writes and notification failures never create a second envelope',async()=>{
 for(const checkpointFails of [false,true]){
  const steps=[];const writes=[];
  const db={from:()=>({select:()=>({eq:()=>({single:async()=>({data:{cancelled_at:null}})})})}),storage:{from:()=>({download:async()=>({data:new Blob([pdf])})})},rpc:async(name,params)=>{
   writes.push({name,params});return name==='signature_checkpoint_clicksign'&&checkpointFails?{error:true}:{data:true};
  }};
  const p={create:async()=>{steps.push('create');return envelope;},document:async()=>{steps.push('document');return document;},signer:async()=>signer,requirements:async()=>{},activate:async()=>steps.push('activate'),notify:async()=>{throw new ProviderError('clicksign_http_500',true);}};
  await processSignature(db,p,{id:envelope,contract_id:document,source_path:'private.pdf',source_sha256:await sha256(pdf),worker_claim:signer,signers:[{name:'A',email:'a@example.invalid'}]});
  assert.equal(steps.filter(x=>x==='create').length,1);assert.equal(writes.at(-1).params.p_uncertain,true);
  if(checkpointFails)assert.deepEqual(steps,['create']);else assert.deepEqual(steps,['create','document','activate']);
 }
});
test('webhook accepts only authentic Content-Hmac and persists before acknowledgement',async()=>{
 const calls=[];let unavailable=false;
 const db={rpc:async(name,params)=>{calls.push({name,params});return unavailable?{error:true}:{data:true};}};
 const run=await handler('clicksign-webhook',env,db);
 const body=JSON.stringify({event:{name:'sign',occurred_at:'2026-10-28T12:00:00Z',data:{signer:{email:'a@example.invalid'}}},document:{key:document}});
 const signature=`sha256=${createHmac('sha256',env.CLICKSIGN_WEBHOOK_SECRET).update(body).digest('hex')}`;
 const request=(value,header)=>new Request('https://test.invalid',{method:'POST',headers:{'Content-Hmac':header??signature},body:value});
 assert.equal((await run(request(body,'sha256='+'0'.repeat(64)))).status,401);assert.equal(calls.length,0);
 assert.equal((await run(request(body))).status,202);assert.equal(calls[0].name,'signature_ingest_clicksign');assert.equal(calls[0].params.p_document,document);
 assert.equal((await run(request(body+' '))).status,401);
 unavailable=true;assert.equal((await run(request(body))).status,503);
});
test('worker rejects unauthorized requests and missing configuration BEFORE claiming',async()=>{
 let claims=0;
 const db={rpc:async()=>{claims++;throw Error('must not claim');},auth:{getUser:async()=>({error:true})}};
 let run=await handler('contract-signatures',env,db);
 assert.equal((await run(new Request('https://test.invalid',{method:'POST'}))).status,401);
 assert.equal((await run(new Request('https://test.invalid'))).status,401);
 run=await handler('contract-signatures',{...env,CLICKSIGN_ACCESS_TOKEN:''},db);
 assert.equal((await run(new Request('https://test.invalid',{method:'POST',headers:{'x-agsur-signature-secret':'worker-secret'}}))).status,503);assert.equal(claims,0);
});
test('archive retries never resend a contract and final state is not saved after a failed download',async()=>{
 const calls=[];let done;
 const db={from:()=>({select:()=>({eq:()=>({single:async()=>({data:{id:envelope,provider_environment:'sandbox',provider_id:envelope,provider_document_id:document}})})})}),rpc:async(name,params)=>{
  calls.push({name,params});if(name==='signature_apply_clicksign')return{data:{archive_required:true}};
  if(name==='signature_complete_event')done=params;
  return{data:true};
 }};
 let creates=0;
 await processSignatureEvent(db,{config,create:async()=>{creates++;},signedPdf:async()=>{throw Error('not ready');}},{id:'event',claim_token:'claim',envelope_id:envelope});
 assert.equal(creates,0);assert.equal(done.p_error,'signature_event_retry');assert.equal(calls.filter(x=>x.name==='signature_apply_clicksign').length,1);
});
test('one signer callback cannot be interpreted as final contract signature',()=>{
 const result=parseClicksignEvent({event:{name:'sign',data:{signer:{email:'A@example.invalid'}}},document:{id:document,updated_at:'2026-10-28T12:00:00Z'}});
 assert.equal(result.name,'sign');assert.equal(result.email,'a@example.invalid');
 assert.throws(()=>parseClicksignEvent({event:{name:'sign'},document:{id:document}}));
});
