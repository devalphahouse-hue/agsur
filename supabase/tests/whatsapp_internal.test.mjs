import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { stripTypeScriptTypes } from 'node:module';
const { PGlite } = await import(process.env.PGLITE_MODULE ?? '@electric-sql/pglite');
const master='11111111-1111-1111-1111-111111111111';
const lead='22222222-2222-2222-2222-222222222222';
const teammate='33333333-3333-3333-3333-333333333333';
const outsider='44444444-4444-4444-4444-444444444444';
const request='55555555-5555-5555-5555-555555555555';
const scheduled = new Date(Date.now()+3600000).toISOString();
const future = () => scheduled;
async function database() {
 const db=new PGlite();
 await db.exec(`CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
 CREATE SCHEMA auth;
 CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS $$SELECT nullif(current_setting('test.uid',true),'')::uuid$$;
 CREATE TABLE public.users(id uuid PRIMARY KEY,name text,fullname text,phone text,profile_type text,is_active boolean,is_deleted boolean);
 CREATE TABLE public.leads(id uuid PRIMARY KEY,name text,fullname text,phone text,seller_id uuid,is_deleted boolean);
 CREATE TABLE public.notes(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),lead_id uuid,note text,created_by uuid);
 CREATE FUNCTION public.auth_is_seller_or_admin() RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
 SELECT EXISTS(SELECT 1 FROM public.users WHERE id=auth.uid() AND profile_type IN ('Admin Master','Admin','Vendedor'))$$;
 CREATE FUNCTION public.auth_is_admin_master() RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
 SELECT EXISTS(SELECT 1 FROM public.users WHERE id=auth.uid() AND profile_type='Admin Master')$$;
 GRANT USAGE ON SCHEMA auth TO authenticated;
 GRANT SELECT ON public.users,public.leads TO authenticated;
 INSERT INTO public.users VALUES('${master}','Master',NULL,'(11) 98765-4321','Admin Master',true,false),
 ('${teammate}','Equipe',NULL,'(12) 99876-5432','Colaborador',true,false),
 ('${outsider}','Cliente',NULL,'(21) 98765-4321','Cliente',true,false);
 INSERT INTO public.leads VALUES('${lead}','Cliente teste',NULL,'(11) 98765-4321','${master}',false);
 SELECT set_config('test.uid','${master}',false);`);
 for (const name of ['20261013120000_whatsapp_reminders.sql','20261016120000_whatsapp_internal_workflow.sql','20261016130000_whatsapp_panel_notifications.sql']) {
  await db.exec(await readFile(new URL(`../migrations/${name}`,import.meta.url),'utf8'));
 }
 return db;
}
async function schedule(db,kind='cliente',ids=[lead],text='Nota\n com\t detalhes',key=null) {
 const reminder={subject:'Atendimento',recipient_type:kind,recipient_ids:ids,scheduled_at:future(),consent:true};
 return db.query('SELECT public.create_lead_note($1::uuid,$2,$3::jsonb,$4::uuid) AS id',[lead,text,JSON.stringify(reminder),key]);
}
async function due(db) { await db.exec("RESET ROLE; UPDATE public.whatsapp_reminders SET next_attempt_at=now()-interval '1 minute'; SET ROLE service_role"); }
async function claim(db) {return (await db.query('SELECT * FROM public.claim_whatsapp_dispatches()')).rows;}
async function complete(db,d,{id=null,error=null,retry=false,provider='meta'}={}) {
 return (await db.query('SELECT public.complete_whatsapp_dispatch($1::uuid,$2::uuid,$3,$4,$5,$6) AS ok',[d.id,d.claim_token,provider,id,error,retry])).rows[0].ok;
}

test('phone normalization and parameter snapshots match application contract', async()=>{
 const db=await database();try{
 const cases=[['(11) 98765-4321','+5511987654321'],['(11) 98765.4321','+5511987654321'],['11 98765 4321','+5511987654321'],['+55 (11) 98765-4321','+5511987654321'],['005511987654321','+5511987654321'],['02111987654321','+5511987654321'],['(11) 3456-7890','+551134567890'],['',null],[null,null],['abc',null],['11111111111',null],['(01) 98765-4321',null],['5511887654321',null],['123',null]];
 for(const [raw,expected] of cases) assert.equal((await db.query('SELECT public.phone_to_e164($1) AS v',[raw])).rows[0].v,expected,raw);
 assert.equal((await db.query("SELECT public.wa_param(E'  Nota\\ncom\\t detalhes  ') AS v")).rows[0].v,'Nota com detalhes');
 await schedule(db);
 const row=(await db.query('SELECT * FROM public.whatsapp_reminders')).rows[0];
 assert.equal(row.message,'Atendimento — Nota com detalhes');
 assert.equal(row.template_name,'agsur_lembrete_atendimento');
 }finally{await db.close();}
});

test('note transaction, deduplication, team opt-in and caller permissions',async()=>{
 const db=await database();try{
 await db.exec('SET ROLE authenticated');
 await assert.rejects(schedule(db,'equipe',[teammate]),/indisponível/);
 await db.exec('RESET ROLE');
 assert.equal((await db.query('SELECT count(*)::int n FROM public.notes')).rows[0].n,0);
 await db.exec('SET ROLE authenticated');
 await db.query('SELECT public.set_whatsapp_team_member($1,true)',[teammate]);
 await schedule(db,'equipe',[teammate]);
 await schedule(db,'cliente',[lead],'Nota com chave',request);
 await schedule(db,'cliente',[lead],'Nota com chave',request);
 await assert.rejects(schedule(db,'cliente',[lead],'Conteúdo diferente',request),/já utilizada/);
 assert.equal((await db.query('SELECT * FROM public.vw_reminder_dispatches')).rows.length,2);
 for(const name of ['note_reminders','whatsapp_reminders','whatsapp_dispatch_attempts','reminder_team_members']) {
  await assert.rejects(db.query(`INSERT INTO public.${name} DEFAULT VALUES`),/permission denied/);
  await assert.rejects(db.query(`UPDATE public.${name} SET ${name==='reminder_team_members'?'enabled=false':name==='whatsapp_dispatch_attempts'?"outcome='Enviado'":"status='Enviado'"}`),/permission denied/);
 }
 await assert.rejects(db.query('SELECT * FROM public.claim_whatsapp_dispatches()'),/permission denied/);
 await assert.rejects(db.query('SELECT public.refresh_whatsapp_reminder($1)',[request]),/permission denied/);
 await db.exec(`RESET ROLE; SELECT set_config('test.uid','${outsider}',false); SET ROLE authenticated`);
 assert.equal((await db.query('SELECT * FROM public.vw_reminder_dispatches')).rows.length,0);
 await assert.rejects(schedule(db),/Acesso negado/);
 await assert.rejects(db.query('SELECT public.set_whatsapp_team_member($1,true)',[master]),/Admin Master/);
 await db.exec('RESET ROLE; SET ROLE anon');
 for(const name of ['phone_to_e164','create_lead_note','claim_whatsapp_dispatches','complete_whatsapp_dispatch','record_whatsapp_status']) {
  assert.equal((await db.query("SELECT bool_or(has_function_privilege('anon',p.oid,'EXECUTE')) v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname=$1",[name])).rows[0].v,false);
 }
 }finally{await db.close();}
});

test('durable claims, backoff, maximum four attempts, and no retry after uncertain send',async()=>{
 const db=await database();try{
 await schedule(db);await due(db);
 let d=(await claim(db))[0];assert.equal(d.attempt_count,1);
 assert.equal((await claim(db)).length,0);
 assert.equal(await complete(db,{...d,claim_token:request},{id:'wrong-owner'}),false);
 await complete(db,d,{error:'130429',retry:true});
 let row=(await db.query('SELECT * FROM public.whatsapp_reminders')).rows[0];
 assert.equal(row.status,'Agendado');assert.ok(new Date(row.next_attempt_at)>new Date(Date.now()+115000));
 assert.equal((await claim(db)).length,0,'retry waits for backoff');
 for(let attempt=2;attempt<=4;attempt++) {await due(db);d=(await claim(db))[0];assert.equal(d.attempt_count,attempt);await complete(db,d,{error:'130429',retry:true});}
 row=(await db.query('SELECT * FROM public.whatsapp_reminders')).rows[0];assert.equal(row.status,'Falha');
 await db.exec('RESET ROLE; SET ROLE authenticated');await db.query('SELECT public.retry_whatsapp_dispatch($1)',[row.id]);
 await due(db);d=(await claim(db))[0];await complete(db,d,{error:'dispatch_outcome_unknown',retry:true});
 assert.equal((await db.query('SELECT * FROM public.whatsapp_reminders')).rows[0].status,'Falha');
 await db.exec('RESET ROLE; SET ROLE authenticated');
 await assert.rejects(db.query('SELECT public.retry_whatsapp_dispatch($1)',[row.id]),/Resultado incerto/);
 }finally{await db.close();}
});

test('one cancellation covers team fan-out and opts-out cancel before dispatch',async()=>{
 const db=await database();try{
 await db.query('SELECT public.set_whatsapp_team_member($1,true)',[master]);
 await db.query('SELECT public.set_whatsapp_team_member($1,true)',[teammate]);
 await schedule(db,'equipe',[master,teammate]);
 const parent=(await db.query('SELECT id FROM public.note_reminders')).rows[0].id;
 await db.exec('SET ROLE authenticated'); await db.query('SELECT public.cancel_note_reminder($1)',[parent]);
 await due(db);assert.equal((await claim(db)).length,0);
 assert.equal((await db.query('SELECT status FROM public.note_reminders')).rows[0].status,'Cancelado');
 await db.exec('RESET ROLE');await schedule(db);await db.exec('SET ROLE authenticated');
 await db.query('SELECT public.set_whatsapp_opt_out($1,true)',[lead]);
 await assert.rejects(schedule(db),/indisponível/);
 await due(db);assert.equal((await claim(db)).length,0);
 assert.equal((await db.query("SELECT count(*)::int n FROM public.whatsapp_reminders WHERE status='Cancelado'")).rows[0].n,3);
 }finally{await db.close();}
});

test('webhook wins before completion, tolerates out-of-order events and reconciles unknown outcome',async()=>{
 const db=await database();try{
 await schedule(db);await due(db);let d=(await claim(db))[0];
 const status=async(id,value,at,dispatch=d.id)=>db.query('SELECT public.record_whatsapp_status($1,$2,$3::timestamptz,NULL,$4::uuid)',[id,value,at,dispatch]);
 await status('wamid.first','delivered','2026-10-16T15:02:00Z');
 assert.equal(await complete(db,d,{id:'wamid.first'}),false,'stale worker cannot overwrite webhook');
 await status('wamid.first','sent','2026-10-16T15:01:00Z');
 await status('wamid.first','failed','2026-10-16T15:03:00Z');
 let row=(await db.query('SELECT * FROM public.whatsapp_reminders')).rows[0];assert.equal(row.delivery_status,'delivered');
 await db.exec('RESET ROLE');await schedule(db,'cliente',[lead],'Unknown network outcome');await due(db);d=(await claim(db))[0];
 await complete(db,d,{error:'dispatch_outcome_unknown'});
 await status('wamid.recovered','delivered','2026-10-16T15:05:00Z');
 row=(await db.query('SELECT * FROM public.whatsapp_reminders WHERE id=$1',[d.id])).rows[0];assert.equal(row.status,'Enviado');
 assert.equal(row.delivery_status,'delivered');
 const attempt=(await db.query('SELECT * FROM public.whatsapp_dispatch_attempts WHERE dispatch_id=$1',[d.id])).rows[0];
 assert.equal(attempt.provider_message_id,'wamid.recovered');
 }finally{await db.close();}
});

test('old attempt callbacks cannot hijack a later retry',async()=>{
 const db=await database();try{
 await schedule(db);await due(db);let d=(await claim(db))[0];await complete(db,d,{id:'wamid.old'});
 await db.query("SELECT public.record_whatsapp_status('wamid.old','failed',now(),'131026',$1)",[d.id]);
 await db.exec('RESET ROLE; SET ROLE authenticated');await db.query('SELECT public.retry_whatsapp_dispatch($1)',[d.id]);await due(db);d=(await claim(db))[0];
 await db.query("SELECT public.record_whatsapp_status('wamid.old','sent',now(),NULL,$1)",[d.id]);
 let row=(await db.query('SELECT * FROM public.whatsapp_reminders WHERE id=$1',[d.id])).rows[0];assert.equal(row.status,'Processando');
 assert.equal(await complete(db,d,{id:'wamid.new'}),true);
 assert.equal((await db.query('SELECT count(*)::int n FROM public.whatsapp_dispatch_attempts')).rows[0].n,2);
 }finally{await db.close();}
});

test('scheduled note passes through the actual worker in dry-run, with history and zero Meta traffic',async()=>{
 const db=await database();const originalFetch=globalThis.fetch;try{
 await schedule(db);await due(db);let claims=0;
 const adapter={rpc:async(name,params)=>{
  try {
   if(name==='claim_whatsapp_dispatches'){claims++;return {data:(await db.query('SELECT * FROM public.claim_whatsapp_dispatches($1,$2::uuid)',[params.p_limit,params.p_run_id])).rows};}
   if(name==='complete_whatsapp_dispatch')return {data:(await db.query('SELECT public.complete_whatsapp_dispatch($1::uuid,$2::uuid,$3,$4,$5,$6)',[params.p_id,params.p_claim_token,params.p_provider,params.p_message_id,params.p_error,params.p_retriable])).rows};
   throw new Error(name);
  }catch(error){return {error};}
 }};
 const env={WHATSAPP_DISPATCH_SECRET:'internal-secret',WHATSAPP_DRY_RUN:'true',SUPABASE_URL:'https://local.test',SUPABASE_SERVICE_ROLE_KEY:'local'};
 globalThis.Deno={env:{get:k=>env[k]},serve:fn=>{globalThis.__waHandler=fn;}};globalThis.__waDb=adapter;
 let source=await readFile(new URL('../functions/whatsapp-reminders/index.ts',import.meta.url),'utf8');
 source=source.replace(/import \{ createClient \} from .*?;/,'const createClient=()=>globalThis.__waDb;');
 source=source.replace(/from "\.\.\/_shared\/whatsapp.ts"/,`from "${new URL('../functions/_shared/whatsapp.ts',import.meta.url).href}"`);
 await import(`data:text/javascript;base64,${Buffer.from(stripTypeScriptTypes(source)).toString('base64')}`);
 globalThis.fetch=async()=>{throw new Error('Meta must never be called during dry-run');};
 const invoke=()=>globalThis.__waHandler(new Request('https://local.test',{method:'POST',headers:{'x-agsur-cron-secret':'internal-secret'}}));
 let response=await invoke();assert.equal(response.status,200);assert.equal((await response.json()).processed,1);
 response=await invoke();assert.equal((await response.json()).processed,0);assert.equal(claims,2);
 const row=(await db.query('SELECT * FROM public.whatsapp_reminders')).rows[0];
 assert.equal(row.provider,'dryrun');assert.equal(row.status,'Enviado');assert.equal(row.delivery_status,null);assert.equal(row.attempt_count,1);
 assert.equal((await db.query('SELECT status FROM public.note_reminders')).rows[0].status,'Enviado');
 }finally{globalThis.fetch=originalFetch;await db.close();}
});

test('panel inbox is due-only, private to author/recipient, read once and independent of Meta',async()=>{
 const db=await database();try{
 await db.exec(`UPDATE public.users SET profile_type='Vendedor' WHERE id='${teammate}'`);
 await db.query('SELECT public.set_whatsapp_team_member($1,true)',[teammate]);
 await schedule(db,'equipe',[teammate],'Lembrete da equipe');
 await db.exec('SET ROLE authenticated');
 assert.equal((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows.length,0,'future reminder stays hidden');
 await db.exec("RESET ROLE; UPDATE public.note_reminders SET scheduled_at=now()-interval '1 minute'; SET ROLE authenticated");
 let rows=(await db.query('SELECT * FROM public.my_reminder_notifications(1)')).rows;
 assert.equal(rows.length,1);assert.equal(Number(rows[0].unread_count),1);
 const id=rows[0].id;
 await db.query('SELECT public.mark_reminder_notification_read($1)',[id]);
 await db.query('SELECT public.mark_reminder_notification_read($1)',[id]);
 assert.equal(Number((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows[0].unread_count),0);
 await assert.rejects(db.query("INSERT INTO public.reminder_notification_reads(reminder_id,user_id) VALUES($1,$2)",[id,teammate]),/permission denied/);
 await db.exec(`RESET ROLE; SELECT set_config('test.uid','${teammate}',false); SET ROLE authenticated`);
 rows=(await db.query('SELECT * FROM public.my_reminder_notifications()')).rows;
 assert.equal(Number(rows[0].unread_count),1,'author reading does not mark recipient read');
 assert.equal((await db.query('SELECT * FROM public.reminder_notification_reads')).rows.length,0,'RLS hides author receipt');
 await db.exec("RESET ROLE; UPDATE public.whatsapp_reminders SET status='Enviado',provider='dryrun'; SET ROLE authenticated");
 assert.equal((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows[0].status,'Simulação (não enviado)');
 await db.exec("RESET ROLE; UPDATE public.whatsapp_reminders SET status='Falha',provider='meta'; SET ROLE authenticated");
 assert.equal((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows.length,1,'Meta failure does not hide panel alert');
 await db.exec(`RESET ROLE; SELECT set_config('test.uid','${outsider}',false); SET ROLE authenticated`);
 assert.equal((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows.length,0);
 await assert.rejects(db.query('SELECT public.mark_reminder_notification_read($1)',[id]),/indisponível/);
 await db.exec(`RESET ROLE; UPDATE public.users SET profile_type='Vendedor' WHERE id='${outsider}'; SET ROLE authenticated`);
 assert.equal((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows.length,0,'unrelated seller cannot see reminder');
 await db.exec(`RESET ROLE; SELECT set_config('test.uid','${master}',false); SET ROLE authenticated`);
 await db.query('SELECT public.cancel_note_reminder($1)',[id]);
 assert.equal((await db.query('SELECT * FROM public.my_reminder_notifications()')).rows.length,0,'cancelled alert stays hidden');
 await db.exec('RESET ROLE; SET ROLE anon');
 await assert.rejects(db.query('SELECT * FROM public.my_reminder_notifications()'),/permission denied/);
 }finally{await db.close();}
});
