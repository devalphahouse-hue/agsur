import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
const {PGlite}=await import(process.env.PGLITE_MODULE ?? '@electric-sql/pglite');
const ids={master:'10000000-0000-0000-0000-000000000001',seller:'10000000-0000-0000-0000-000000000002',other:'10000000-0000-0000-0000-000000000003',client:'10000000-0000-0000-0000-000000000004',doc:'10000000-0000-0000-0000-000000000005'};
const uuid=n=>`20000000-0000-0000-0000-${String(n).padStart(12,'0')}`;
async function fixture(){
 const db=new PGlite();
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;
 alter default privileges in schema public grant all on tables to anon,authenticated;
 alter default privileges in schema public grant execute on functions to anon,authenticated;
 create schema auth;create schema storage;create schema vault;
 create table vault.secrets(id uuid primary key default gen_random_uuid(),name text unique,secret text);
 create function vault.create_secret(text,text) returns uuid language sql as $$insert into vault.secrets(secret,name) values($1,$2) returning id$$;
 create function vault.update_secret(uuid,text) returns void language sql as $$update vault.secrets set secret=$2 where id=$1$$;
 create function auth.uid() returns uuid language sql as $$select nullif(current_setting('test.uid',true),'')::uuid$$;
 create table users(id uuid primary key,name text,profile_type text,is_active boolean default true,is_deleted boolean default false);
 create table leads(id uuid primary key,is_referral boolean);
 create table aircrafts(id uuid primary key,aircraft_model text);
 create table available_aircrafts(id uuid primary key,serial_number text,registration_prefix text,manufacture_date date,delivery_date date);
 create table proposal(id uuid primary key,id_ref text,created_by uuid,lead_id uuid,aircraft_id uuid);
 create table sales(id uuid primary key default gen_random_uuid(),proposal_id uuid,seller_id uuid,fullprice numeric,seller_commission numeric,company_commission numeric,created_at timestamptz default now());
 create table contract(id uuid primary key,proposal_id uuid,cancelled_at timestamptz,"user_Id" uuid,created_at timestamptz default now(),fullprice numeric,available_aircraft_id uuid);
 create table storage.objects(id uuid,bucket_id text,name text);alter table storage.objects enable row level security;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table test_audit(table_name text,op text,actor uuid);
 create function auth_is_admin_master() returns boolean language sql security definer set search_path=public as $$select exists(select 1 from users where id=auth.uid() and profile_type='Admin Master')$$;
 create function auth_is_admin_documentacao() returns boolean language sql security definer set search_path=public as $$select exists(select 1 from users where id=auth.uid() and profile_type in ('Admin Master','Documentacao'))$$;
 create function auth_is_vendedor() returns boolean language sql security definer set search_path=public as $$select exists(select 1 from users where id=auth.uid() and profile_type='Vendedor')$$;
 create function auth_owns_contract(uuid) returns boolean language sql security definer set search_path=public as $$select exists(select 1 from contract where id=$1 and "user_Id"=auth.uid())$$;
 create function tg_audit_write() returns trigger language plpgsql security definer set search_path=public as $$begin insert into test_audit values(tg_table_name,tg_op,auth.uid());return coalesce(new,old);end$$;
 grant usage on schema public,auth,storage to authenticated,service_role,anon;
 grant execute on function auth.uid() to authenticated,service_role,anon;
 grant select,insert on storage.objects to authenticated;grant all on storage.objects to service_role;
 insert into users(id,name,profile_type) values('${ids.master}','Master','Admin Master'),('${ids.seller}','Seller','Vendedor'),('${ids.other}','Other','Vendedor'),('${ids.client}','Client','Cliente'),('${ids.doc}','Doc','Documentacao');
 insert into leads values('${uuid(1)}',false),('${uuid(2)}',true);
 insert into aircrafts values('${uuid(3)}','Cirrus');
 insert into available_aircrafts values('${uuid(7)}','SERIAL-001','PR-AAA','2026-01-01','2026-12-01');
 insert into proposal values('${uuid(4)}','001','${ids.seller}','${uuid(1)}','${uuid(3)}'),('${uuid(5)}','002','${ids.seller}','${uuid(2)}','${uuid(3)}');
 insert into contract(id,proposal_id,"user_Id",fullprice,available_aircraft_id) values('${uuid(6)}','${uuid(4)}','${ids.client}',100000,'${uuid(7)}');
 -- Deliberately different historic numbers must remain unchanged.
 insert into sales(id,proposal_id,fullprice,seller_commission,company_commission) values('${uuid(9)}','${uuid(4)}',100,321,123);
 `);
 for(const name of ['20261019120000_commercial_commissions.sql','20261019121000_contract_signatures.sql','20261028120000_clicksign_runtime.sql','20261028121500_signature_dispatch_config.sql'])await db.exec(await readFile(new URL('../migrations/'+name,import.meta.url),'utf8'));
 const as=async(who,role='authenticated')=>db.exec(`reset role;select set_config('test.uid','${ids[who]??''}',false);set role ${role}`);
 return {db,as};
}
const value=async(db,sql,params=[])=>(await db.query(sql,params)).rows[0];

test('frozen rules, direct/referral defaults, tiers, exact rounding and no historic recalculation',async()=>{
 const {db,as}=await fixture();try{
 assert.equal((await value(db,`select seller_pool from sale_commission_snapshots where sale_id='${uuid(9)}'`)).seller_pool,'321.00');
 await db.exec(`insert into sales(id,proposal_id,fullprice,seller_commission,company_commission) values('${uuid(10)}','${uuid(4)}',100000.25,1,1),('${uuid(11)}','${uuid(5)}',100000.25,1,1)`);
 const rows=(await db.query(`select * from sale_commission_snapshots where sale_id in ('${uuid(10)}','${uuid(11)}') order by sale_id`)).rows;
 assert.equal(rows[0].seller_pool,'7500.00');assert.equal(rows[0].company_amount,'2000.01');
 assert.equal(rows[1].seller_pool,'4500.00');assert.equal(rows[1].referral_pool,'3000.00');
 await assert.rejects(db.exec(`update sales set seller_commission=999 where id='${uuid(10)}'`),/congelada/);
 await db.exec(`update sales set fullprice=1000 where id='${uuid(10)}'`);
 assert.equal((await value(db,`select company_amount from sale_commission_snapshots where sale_id='${uuid(10)}'`)).company_amount,'2000.01');
 await as('seller');await assert.rejects(db.exec(`select commission_create_rule('X',now()+interval '1 day',.02,8000,0,3000,'[]')`),/Somente/);
 await as('master');await assert.rejects(db.exec(`select commission_create_rule('Past',now()-interval '1 day',.02,8000,0,3000,'[]')`),/futura/);
 await assert.rejects(db.exec(`select commission_create_rule('Bad',now()+interval '1 day',.02,8000,0,3000,'[{"fixed":1}]')`),/Faixa inválida/);
 await assert.rejects(db.exec(`select commission_create_rule('BadNaN',now()+interval '1 day',.02,'NaN',0,3000,'[]')`));
 await db.exec(`select commission_create_rule('Future',now()+interval '1 day',.03,8000,.01,3000,'[]')`);
 await assert.rejects(db.exec(`update commission_rules set seller_fixed=1`),/permission denied/);
 await db.exec('reset role');
 // Simulate reaching the future effective date with an administrative fixture change.
 await db.exec(`update commission_rules set effective_at=now()-interval '1 minute',tiers='[{"min_price":100000,"min_sales":1,"fixed":9000,"rate":0.01}]' where label='Future';insert into sales(id,proposal_id,fullprice) values('${uuid(12)}','${uuid(4)}',100000)`);
 const s=await value(db,`select * from sale_commission_snapshots where sale_id='${uuid(12)}'`);
 assert.equal(s.seller_pool,'10000.00');assert.equal(s.company_amount,'3000.00');
 assert.equal((await value(db,`select seller_pool from sale_commission_snapshots where sale_id='${uuid(10)}'`)).seller_pool,'7500.00');
 }finally{await db.close();}
});

test('allocation budgets, own statements, deductions, settlement idempotency and audit',async()=>{
 const {db,as}=await fixture();try{
 await db.exec(`insert into sales(id,proposal_id,fullprice) values('${uuid(10)}','${uuid(4)}',100000)`);
 const allocation=`select commission_allocate('${uuid(20)}','${uuid(10)}','${ids.seller}',null,'seller',4000.10,100.05,'Despesa combinada')`;
 await as('master');await db.exec(allocation);await db.exec(allocation);
 await assert.rejects(db.exec(`select commission_allocate('${uuid(20)}','${uuid(10)}','${ids.seller}',null,'seller',4000,0,null)`),/reutilizada/);
 await assert.rejects(db.exec(`select commission_allocate('${uuid(21)}','${uuid(10)}','${ids.other}',null,'seller',3500,0,null)`),/excede/);
 await assert.rejects(db.exec(`select commission_allocate('${uuid(21)}','${uuid(10)}','${ids.client}',null,'seller',1,0,null)`),/Beneficiário inválido/);
 await assert.rejects(db.exec(`select commission_allocate('${uuid(21)}','${uuid(10)}','${ids.other}',null,'seller',1,1,null)`));
 await assert.rejects(db.exec(`select commission_allocate('${uuid(22)}','${uuid(10)}',null,null,'seller',1,0,null)`));
 await assert.rejects(db.exec(`select commission_allocate('${uuid(22)}','${uuid(10)}','${ids.other}',null,'seller',1,0.50,null)`));
 await db.exec(`select commission_allocate('${uuid(21)}','${uuid(10)}','${ids.other}',null,'seller',3499.90,0,null)`);
 const statement=`select commission_statement('2000-01-01','2100-01-01') data`;
 await as('seller');const own=(await value(db,statement)).data;
 assert.equal(own.count,1);assert.equal(own.provisioned,3900.05);assert.equal(own.deductions,100.05);assert.equal(own.paid,0);
 assert.equal((await db.query('select * from commission_allocations')).rows.length,1);
 assert.equal((await db.query('select * from sale_commission_snapshots')).rows.length,0);
 await assert.rejects(db.exec(`select commission_statement('2000-01-01','2100-01-01','all','${ids.other}')`),/outro vendedor/);
 await assert.rejects(db.exec(`select commission_settle('${uuid(30)}','${uuid(20)}','PIX-01')`),/Somente/);
 await assert.rejects(db.exec('delete from commission_allocations'),/permission denied/);
 await as('master');const pay=`select commission_settle('${uuid(30)}','${uuid(20)}','PIX-01')`;
 await Promise.all([db.exec(pay),db.exec(pay),db.exec(pay)]);
 await assert.rejects(db.exec(`select commission_settle('${uuid(31)}','${uuid(20)}','PIX-01')`),/já registrado/);
 await as('seller');const paid=(await value(db,statement)).data;assert.equal(paid.paid,3900.05);assert.equal(paid.due,0);
 await as('client');await assert.rejects(db.exec(statement),/Sem acesso/);assert.equal((await db.query('select * from commission_payments')).rows.length,0);
 await db.exec('reset role');assert.equal((await value(db,"select count(*)::int n from test_audit where table_name='commission_payments'")).n,1);
 }finally{await db.close();}
});

test('private PDF preparation, authorization, approval and queue are idempotent',async()=>{
 const {db,as}=await fixture();try{
 const path=`${ids.master}/${uuid(40)}/source.pdf`;
 const args=[uuid(40),uuid(6),'zapsign',path,'a'.repeat(64),JSON.stringify([{name:'Cliente',email:'cliente@example.com'}])];
 const prepare='select signature_prepare($1,$2,$3,$4,$5,$6::jsonb)';
 await as('seller');await assert.rejects(db.query(prepare,args),/Requer documentação/);
 await assert.rejects(db.exec(`insert into storage.objects(bucket_id,name) values('contract-signatures','${path}')`),/row-level security/);
 await as('master');await db.query('insert into storage.objects(bucket_id,name) values($1,$2)',['contract-signatures',path]);
 await db.query(prepare,args);await db.query(prepare,args);
 const frozen=(await value(db,`select snapshot from contract_signature_envelopes where id='${uuid(40)}'`)).snapshot;
 assert.equal(frozen.unit.serial_number,'SERIAL-001');
 await db.exec(`reset role;update available_aircrafts set serial_number='SERIAL-CHANGED' where id='${uuid(7)}'`);
 await as('master');
 assert.equal((await value(db,`select snapshot from contract_signature_envelopes where id='${uuid(40)}'`)).snapshot.unit.serial_number,'SERIAL-001');
 await assert.rejects(db.query(prepare,[...args.slice(0,5),JSON.stringify([{name:'X',email:'bad-email'}])]),/reutilizada/);
 await as('other');assert.equal((await db.query('select * from contract_signature_envelopes')).rows.length,0);
 await assert.rejects(db.exec('select * from signature_claim()'),/permission denied/);
 await as('client');assert.equal((await db.query('select * from contract_signature_envelopes')).rows.length,1);
 await assert.rejects(db.exec(`select signature_approve('${uuid(40)}')`),/Requer documentação/);
 await as('master');await db.exec(`select signature_approve('${uuid(40)}');select signature_approve('${uuid(40)}')`);
 await as('', 'service_role');assert.equal((await db.query('select * from signature_claim()')).rows.length,1);
 assert.equal((await db.query('select * from signature_claim()')).rows.length,0);
 await db.exec(`select signature_dispatched('${uuid(40)}','remote-123')`);
 await db.exec(`select signature_receive_event('zapsign','remote-123','view-1','viewed',now(),'cliente@example.com')`);
 await db.exec(`select signature_receive_event('zapsign','remote-123','send-late','sent',now())`);
 assert.equal((await value(db,`select status from contract_signature_envelopes where id='${uuid(40)}'`)).status,'viewed');
 await assert.rejects(db.exec(`select signature_receive_event('zapsign','remote-123','sign-1','signed',now(),null,'${uuid(40)}/signed.pdf')`),/não arquivado/);
 await db.exec(`insert into storage.objects(bucket_id,name) values('contract-signatures','${uuid(40)}/signed.pdf');select signature_receive_event('zapsign','remote-123','sign-1','signed',now(),null,'${uuid(40)}/signed.pdf');select signature_receive_event('zapsign','remote-123','sign-1','signed',now(),null,'${uuid(40)}/signed.pdf');select signature_receive_event('zapsign','remote-123','late-declined','declined',now())`);
 assert.equal((await value(db,`select status from contract_signature_envelopes where id='${uuid(40)}'`)).status,'signed');
 assert.equal((await value(db,`select count(*)::int n from contract_signature_events where event_id='sign-1'`)).n,1);
 await as('other');assert.equal((await db.query('select * from storage.objects')).rows.length,0);
 await as('client');assert.equal((await db.query('select * from storage.objects')).rows.length,2);
 }finally{await db.close();}
});


test('cancelled preparations can be corrected, cancelled contracts cannot be dispatched, expired claims never retry',async()=>{
 const {db,as}=await fixture();try{
 await as('master');
 const prep=async(n)=>{
 const path=`${ids.master}/${uuid(n)}/source.pdf`;
 await db.query('insert into storage.objects(bucket_id,name) values($1,$2)',['contract-signatures',path]);
 await db.query('select signature_prepare($1,$2,$3,$4,$5,$6::jsonb)',[uuid(n),uuid(6),'clicksign',path,'b'.repeat(64),JSON.stringify([{name:'Cliente',email:'cliente@example.com'}])]);
 };
 await prep(50);await db.exec(`select signature_withdraw('${uuid(50)}');select signature_withdraw('${uuid(50)}')`);
 await prep(51);await db.exec(`select signature_approve('${uuid(51)}')`);
 await as('', 'service_role');await db.exec('select signature_claim()');
 await as('master');await assert.rejects(db.exec(`select signature_withdraw('${uuid(51)}')`),/Envio iniciado/);
 await db.exec(`reset role;update contract_signature_envelopes set updated_at=now()-interval '20 minutes' where id='${uuid(51)}'`);
 await as('', 'service_role');assert.equal((await db.query('select * from signature_claim()')).rows.length,0);
 assert.equal((await value(db,`select status from contract_signature_envelopes where id='${uuid(51)}'`)).status,'uncertain');
 await db.exec(`reset role;update contract set cancelled_at=now() where id='${uuid(6)}'`);
 await as('master');await assert.rejects(prep(52),/cancelado/);
 await as('other');await assert.rejects(db.exec(`select signature_withdraw('${uuid(50)}')`),/Requer documentação/);
 }finally{await db.close();}
});


test('Supabase default grants do not expose financial tables or worker RPCs',async()=>{
 const {db}=await fixture();try{
 const functions=(await db.query(`select proname,has_function_privilege('anon',p.oid,'execute') anon,has_function_privilege('authenticated',p.oid,'execute') client,proconfig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and (proname like 'commission_%' or proname like 'signature_%')`)).rows;
 assert.ok(functions.length>=15);
 for(const f of functions){assert.equal(f.anon,false,f.proname);assert.ok(f.proconfig?.some(x=>x.startsWith('search_path=')),f.proname);}
 for(const name of ['signature_claim','signature_dispatched','signature_receive_event','commission_freeze_sale','commission_snapshot_sale'])assert.equal(functions.find(x=>x.proname===name).client,false,name);
 for(const name of ['commission_rules','sale_commission_snapshots','commission_allocations','commission_payments','contract_signature_envelopes','contract_signature_events']){
 const p=await value(db,`select has_table_privilege('anon',$1,'select') anon,has_table_privilege('authenticated',$1,'insert,update,delete') writes,relrowsecurity rls from pg_class where oid=$1::regclass`,[name]);
 assert.equal(p.anon,false,name);assert.equal(p.writes,false,name);assert.equal(p.rls,true,name);
 }
 assert.equal((await value(db,"select public from storage.buckets where id='contract-signatures'")).public,false);
 }finally{await db.close();}
});


test('Clicksign claims are isolated by provider and fenced by execution token',async()=>{
 const {db,as}=await fixture();try{
  const path=`${ids.master}/${uuid(70)}/source.pdf`;
  await as('master');await db.query('insert into storage.objects(bucket_id,name) values($1,$2)',['contract-signatures',path]);
  await db.query('select signature_prepare($1,$2,$3,$4,$5,$6::jsonb)',[uuid(70),uuid(6),'clicksign',path,'a'.repeat(64),JSON.stringify([{name:'Cliente',email:'cliente@example.com'}])]);
  await db.exec(`select signature_approve('${uuid(70)}')`);
  await assert.rejects(db.exec("select * from signature_claim_clicksign('sandbox')"),/permission denied/);
  await as('','service_role');
  const job=(await db.query("select * from signature_claim_clicksign('sandbox')")).rows[0];
  assert.equal(job.provider_environment,'sandbox');assert.ok(job.worker_claim);
  assert.equal((await db.query("select * from signature_claim_clicksign('production')")).rows.length,0);
  await assert.rejects(db.query('select signature_checkpoint_clicksign($1,$2,$3)',[job.id,uuid(99),'remote']),/execução/);
  await db.query('select signature_checkpoint_clicksign($1,$2,$3,$4)',[job.id,job.worker_claim,'remote-70','doc-70']);
  await db.query('select signature_finish_clicksign($1,$2,$3,$4)',[job.id,job.worker_claim,'notification_uncertain',true]);
  const stored=await value(db,'select status,provider_id,provider_document_id from contract_signature_envelopes where id=$1',[job.id]);
  assert.equal(stored.status,'uncertain');assert.equal(stored.provider_id,'remote-70');assert.equal(stored.provider_document_id,'doc-70');
  assert.equal((await db.query("select * from signature_claim_clicksign('sandbox')")).rows.length,0);
 }finally{await db.close();}
});

test('Clicksign inbox survives reversed callbacks and only signs after ALL signers and private archive',async()=>{
 const {db,as}=await fixture();try{
  await db.exec(`insert into contract_signature_envelopes(id,contract_id,provider,status,source_path,source_sha256,snapshot,signers,created_by,provider_environment,provider_id,provider_document_id)
  values('${uuid(80)}','${uuid(6)}','clicksign','sent','source-80.pdf','${'a'.repeat(64)}','{}','[{"name":"A","email":"a@example.com"},{"name":"B","email":"b@example.com"}]','${ids.master}','sandbox','remote-80','doc-80')`);
  await as('','service_role');
  const ingest=async(n,name,email)=>db.query('select signature_ingest_clicksign($1,$2,$3,$4,now(),$5)',[String(n).padStart(64,'0'),'doc-80','sandbox',name,email]);
  await assert.rejects(ingest(4,'sign','outsider@example.com'),/não pertence/);
  assert.equal((await value(db,"select signature_ingest_clicksign($1,'doc-80','production','close',now()) ok",['9'.repeat(64)])).ok,false);
  const apply=async(n,name,email)=>{
   await ingest(n,name,email);await ingest(n,name,email);
   const tasks=(await db.query("select * from signature_claim_events('sandbox')")).rows;
   assert.equal(tasks.length,1);
   const task=tasks[0];
   const data=(await value(db,'select signature_apply_clicksign($1,$2) data',[task.id,task.claim_token])).data;
   return {task,data};
  };
  const closed=await apply(1,'document_closed',null);assert.equal(closed.data.archive_required,false);
  await db.query('select signature_complete_event($1,$2)',[closed.task.id,closed.task.claim_token]);
  const first=await apply(2,'sign','a@example.com');assert.equal(first.data.archive_required,false);
  await db.query('select signature_complete_event($1,$2)',[first.task.id,first.task.claim_token]);
  assert.notEqual((await value(db,'select status from contract_signature_envelopes where id=$1',[uuid(80)])).status,'signed');
  const last=await apply(3,'sign','b@example.com');assert.equal(last.data.archive_required,true);
  await assert.rejects(db.query('select signature_apply_clicksign($1,$2,$3)',[last.task.id,last.task.claim_token,`${uuid(80)}/signed.pdf`]),/não arquivado/);
  await db.query('insert into storage.objects(bucket_id,name) values($1,$2)',['contract-signatures',`${uuid(80)}/signed.pdf`]);
  await db.query('select signature_apply_clicksign($1,$2,$3)',[last.task.id,last.task.claim_token,`${uuid(80)}/signed.pdf`]);
  await db.query('select signature_complete_event($1,$2)',[last.task.id,last.task.claim_token]);
  assert.equal((await value(db,'select status from contract_signature_envelopes where id=$1',[uuid(80)])).status,'signed');
  assert.equal((await value(db,'select count(*)::int n from contract_signature_events where envelope_id=$1',[uuid(80)])).n,3);
  await as('client');assert.equal((await db.query('select * from storage.objects')).rows.length,1);
  await as('other');assert.equal((await db.query('select * from storage.objects')).rows.length,0);
 }finally{await db.close();}
});

test('Clicksign inbox and service RPCs are never public and failed archives are retried',async()=>{
 const {db,as}=await fixture();try{
  const privileges=(await db.query(`select proname,has_function_privilege('anon',p.oid,'execute') anon,has_function_privilege('authenticated',p.oid,'execute') client from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and proname in ('signature_claim_clicksign','signature_checkpoint_clicksign','signature_finish_clicksign','signature_ingest_clicksign','signature_claim_events','signature_apply_clicksign','signature_complete_event')`)).rows;
  assert.equal(privileges.length,7);for(const x of privileges){assert.equal(x.anon,false);assert.equal(x.client,false);}
  assert.equal((await value(db,"select relrowsecurity rls from pg_class where oid='signature_webhook_inbox'::regclass")).rls,true);
  await as('client');await assert.rejects(db.exec('select * from signature_webhook_inbox'),/permission denied/);
  await db.exec('reset role');
  await db.exec(`insert into contract_signature_envelopes(id,contract_id,provider,status,source_path,source_sha256,snapshot,signers,created_by,provider_environment,provider_id,provider_document_id) values('${uuid(81)}','${uuid(6)}','clicksign','sent','source-81.pdf','${'a'.repeat(64)}','{}','[{"name":"A","email":"a@example.com"}]','${ids.master}','sandbox','remote-81','doc-81')`);
  await as('','service_role');await db.query("select signature_ingest_clicksign($1,'doc-81','sandbox','document_closed',now())",['a'.repeat(64)]);
  const task=(await db.query("select * from signature_claim_events('sandbox')")).rows[0];
  await assert.rejects(db.query('select signature_complete_event($1,$2)',[task.id,uuid(99)]),/execução/);
  await db.query("select signature_complete_event($1,$2,'download_pending')",[task.id,task.claim_token]);
  const pending=await value(db,'select * from signature_webhook_inbox where id=$1',[task.id]);
  assert.equal(pending.completed_at,null);assert.equal(pending.attempts,1);assert.ok(pending.next_attempt_at>pending.received_at);
 }finally{await db.close();}
});


test('scheduler bootstrap is service-only and rotates its two named secrets without duplicates',async()=>{
 const {db,as}=await fixture();try{
  await as('master');await assert.rejects(db.query('select configure_signature_dispatcher($1)',['a'.repeat(64)]),/permission denied/);
  await as('','service_role');await assert.rejects(db.query('select configure_signature_dispatcher($1)',['short']),/inválido/);
  await db.query('select configure_signature_dispatcher($1)',['a'.repeat(64)]);
  await db.query('select configure_signature_dispatcher($1)',['b'.repeat(64)]);
  await db.exec('reset role');
  const rows=(await db.query('select name,secret from vault.secrets order by name')).rows;
  assert.equal(rows.length,2);assert.equal(rows[0].secret,'b'.repeat(64));
  assert.equal(rows[1].secret,'https://bkzybtmxxzpxtztesdye.supabase.co/functions/v1');
 }finally{await db.close();}
});
