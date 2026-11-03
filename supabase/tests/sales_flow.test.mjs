import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE ?? '@electric-sql/pglite');
const admin = '11111111-1111-4111-8111-111111111111';
const lead = '22222222-2222-4222-8222-222222222222';
const aircraft = '33333333-3333-4333-8333-333333333333';
const optional = '44444444-4444-4444-8444-444444444444';
const proposal = '55555555-5555-4555-8555-555555555555';
const client = '66666666-6666-4666-8666-666666666666';
const migration = await readFile(new URL('../migrations/20261103134251_atomic_sales_flow.sql', import.meta.url), 'utf8');
const financing = {term_length:5,credit_date:'2026-11-03',down_payment:0.05,initial_deposit:0.15};

async function setup() {
  const db = new PGlite();
  await db.exec(`
    CREATE ROLE anon; CREATE ROLE authenticated;
    CREATE SCHEMA auth;
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS $$ SELECT nullif(current_setting('test.uid',true),'')::uuid $$;
    CREATE FUNCTION public.auth_is_seller_or_admin() RETURNS boolean LANGUAGE sql AS $$ SELECT auth.uid()='${admin}'::uuid $$;
    CREATE TABLE public.users(id uuid primary key,name text,lastname text,fullname text,email text,phone text,cpf text,
      profile_type text,is_admin boolean,status text,lead_id uuid,profile_photo_url text,is_deleted boolean default false);
    CREATE TABLE public.leads(id uuid primary key,name text,last_name text,fullname text,email text,phone text,cpf text,
      active boolean default true,is_deleted boolean default false,is_referral boolean default false);
    CREATE TABLE public.financing_rates(id uuid primary key,premium_rate_five numeric,premium_rate_seven numeric,sofr_rate numeric,interest_rate numeric);
    CREATE TABLE public.aircrafts(id uuid primary key,price numeric,deleted boolean default false);
    CREATE TABLE public.aircraft_items(id uuid primary key,price numeric,qty integer,active boolean default true,deleted boolean default false,item_type text);
    CREATE TABLE public.aircraft_item_links(aircraft_item_id uuid,aircraft_id uuid);
    CREATE TABLE public.proposal(id uuid primary key default gen_random_uuid(),lead_id uuid references public.leads,
      aircraft_id uuid references public.aircrafts,fullprice numeric,created_by uuid,available_aircraft_id uuid,id_ref text,
      active boolean default true,is_deleted boolean default false,is_contract boolean default false);
    CREATE TABLE public.proposal_financing(id uuid default gen_random_uuid(),proposal_id uuid references public.proposal,
      created_by uuid,term_length integer,credit_date date,down_payment numeric,initial_deposit numeric,total_deposit numeric,
      premium_rate numeric,sofr_rate numeric,interest_rate numeric);
    CREATE TABLE public.proposal_item(proposal_id uuid references public.proposal,aircraft_item_id uuid references public.aircraft_items);
    CREATE TABLE public.contract(id uuid primary key default gen_random_uuid(),"user_Id" uuid references public.users,
      proposal_id uuid references public.proposal,fullprice numeric,created_by uuid,cancelled_at timestamptz);
    CREATE TABLE public.user_aircraft(id uuid primary key default gen_random_uuid(),created_by uuid,aircraft_status text,
      proposal_id uuid references public.proposal,contract_id uuid references public.contract);
    CREATE TABLE public.sales(id uuid primary key default gen_random_uuid(),seller_id uuid,proposal_id uuid references public.proposal,
      fullprice numeric,seller_commission numeric,company_commission numeric,created_by uuid);
    CREATE TABLE public.financial(id uuid primary key default gen_random_uuid(),financial_type text,sale_id uuid references public.sales,
      description text,financial_status text,created_by uuid);
    CREATE TABLE public.tracking(id uuid primary key default gen_random_uuid(),user_aircraft uuid references public.user_aircraft,
      tracking_description text,"isCheck" boolean,"order" smallint);
    INSERT INTO public.leads(id,name,last_name,fullname,email) VALUES ('${lead}','QA','Fluxo','QA Fluxo','qa@example.com');
    INSERT INTO public.financing_rates VALUES('ce659e4b-caee-4b88-8d99-46f15c7e9b69',0.05,0.07,0.04,0.02);
    INSERT INTO public.aircrafts(id,price) VALUES('${aircraft}',100000);
    INSERT INTO public.aircraft_items(id,price,qty,item_type) VALUES('${optional}',950,2,'optional');
    INSERT INTO public.aircraft_item_links VALUES('${optional}','${aircraft}');
    SELECT set_config('test.uid','${admin}',false);
    GRANT USAGE ON SCHEMA auth TO authenticated;
    GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
  `);
  await db.exec(migration);
  await db.exec('SET ROLE authenticated');
  return db;
}
const create = (db, id=proposal, options=[optional], data=financing) => db.query(
  'select public.create_proposal_atomic($1,$2,$3,null,$4,$5::jsonb,$6::uuid[]) id',
  [id,lead,aircraft,'123456',JSON.stringify(data),options]);
const convert = db => db.query('select public.convert_proposal_atomic($1,$2,$3) result',[proposal,'qa@example.com',client]);
const count = async (db,table) => Number((await db.query(`select count(*) n from public.${table}`)).rows[0].n);

test('proposal and financing roll back when an optional insert fails; retry is idempotent', async () => {
  const db=await setup();
  try {
    await db.exec(`RESET ROLE; CREATE FUNCTION public.fail_item() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'injected item failure'; END $$;
      CREATE TRIGGER fail_item BEFORE INSERT ON public.proposal_item FOR EACH ROW EXECUTE FUNCTION public.fail_item(); SET ROLE authenticated;`);
    await assert.rejects(create(db),/injected item failure/);
    assert.equal(await count(db,'proposal'),0);
    assert.equal(await count(db,'proposal_financing'),0);
    await db.exec('RESET ROLE; DROP TRIGGER fail_item ON public.proposal_item; SET ROLE authenticated;');
    await create(db,proposal,[optional,optional]);
    await create(db);
    assert.equal(await count(db,'proposal'),1);
    assert.equal(await count(db,'proposal_financing'),1);
    assert.equal(await count(db,'proposal_item'),1);
    assert.equal(Number((await db.query('select fullprice from public.proposal')).rows[0].fullprice),101900);
    assert.equal(Number((await db.query('select total_deposit from public.proposal_financing')).rows[0].total_deposit),0.2);
  } finally {await db.close();}
});

test('late conversion failure rolls back client, stock side effects and every business record', async () => {
  const db=await setup();
  try {
    await create(db);
    await db.exec(`RESET ROLE;
      CREATE TABLE public.test_stock(in_stock boolean); INSERT INTO public.test_stock VALUES(true);
      CREATE FUNCTION public.test_stock_move() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN UPDATE public.test_stock SET in_stock=false; RETURN NEW; END $$;
      CREATE TRIGGER test_stock_move AFTER INSERT ON public.contract FOR EACH ROW EXECUTE FUNCTION public.test_stock_move();
      CREATE FUNCTION public.fail_tracking() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW."order"=20 THEN RAISE EXCEPTION 'injected last stage failure'; END IF; RETURN NEW; END $$;
      CREATE TRIGGER fail_tracking BEFORE INSERT ON public.tracking FOR EACH ROW EXECUTE FUNCTION public.fail_tracking(); SET ROLE authenticated;`);
    await assert.rejects(convert(db),/injected last stage failure/);
    for (const table of ['users','contract','user_aircraft','sales','financial','tracking']) assert.equal(await count(db,table),0,table);
    assert.equal((await db.query('select is_contract from public.proposal')).rows[0].is_contract,false);
    await db.exec('RESET ROLE');
    assert.equal((await db.query('select in_stock from public.test_stock')).rows[0].in_stock,true);
    await db.exec('DROP TRIGGER fail_tracking ON public.tracking; SET ROLE authenticated;');
    const first=await convert(db);
    const again=await convert(db);
    assert.equal(first.rows[0].result.contract_id,again.rows[0].result.contract_id);
    assert.equal(first.rows[0].result.client_created,true);
    assert.equal(again.rows[0].result.client_created,false);
    for (const table of ['users','contract','user_aircraft','sales','financial']) assert.equal(await count(db,table),1,table);
    assert.equal(await count(db,'tracking'),21);
    assert.equal((await db.query('select count(distinct "order") n from public.tracking')).rows[0].n,21);
    const sale=(await db.query('select * from public.sales')).rows[0];
    assert.equal(Number(sale.seller_commission),7500);
    assert.equal(Number(sale.company_commission),2038);
  } finally {await db.close();}
});

test('invalid selection, other client email and RLS denial do not leave partial conversions', async () => {
  const db=await setup();
  try {
    await assert.rejects(create(db,proposal,['99999999-9999-4999-8999-999999999999']),/opcionais/);
    assert.equal(await count(db,'proposal'),0);
    await create(db);
    await db.exec(`INSERT INTO public.users(id,email,profile_type,lead_id) VALUES('${client}','qa@example.com','Cliente','99999999-9999-4999-8999-999999999999');`);
    await assert.rejects(convert(db),/outro lead/);
    assert.equal(await count(db,'contract'),0);
    await db.exec(`UPDATE public.users SET lead_id=null; RESET ROLE; ALTER TABLE public.financial ENABLE ROW LEVEL SECURITY; SET ROLE authenticated;`);
    await assert.rejects(convert(db),/row-level security/);
    assert.equal((await db.query('select lead_id from public.users')).rows[0].lead_id,null);
    assert.equal(await count(db,'sales'),0);
    await db.exec(`RESET ROLE; ALTER TABLE public.financial DISABLE ROW LEVEL SECURITY; SET ROLE authenticated; UPDATE public.leads SET is_referral=true;`);
    await convert(db);
    assert.equal((await db.query('select lead_id from public.users')).rows[0].lead_id,lead);
    assert.equal(Number((await db.query('select seller_commission from public.sales')).rows[0].seller_commission),4500);
    await db.exec(`SELECT set_config('test.uid','${client}',false);`);
    await assert.rejects(create(db),/Sem permissão/);
    await assert.rejects(convert(db),/Sem permissão/);
    await db.exec('SET ROLE anon');
    await assert.rejects(convert(db),/permission denied/);
  } finally {await db.close();}
});
