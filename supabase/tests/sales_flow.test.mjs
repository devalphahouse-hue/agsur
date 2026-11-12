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

const seller = '77777777-7777-4777-8777-777777777777';
const manager = '88888888-8888-4888-8888-888888888888';
const otherAircraft = 'a0000000-0000-4000-8000-000000000001';
const firstUnit = 'b0000000-0000-4000-8000-000000000001';
const secondUnit = 'b0000000-0000-4000-8000-000000000002';

async function setupAdjustments() {
  const db = await setup();
  try {
    await db.exec(`
      RESET ROLE;
      CREATE ROLE service_role BYPASSRLS;
      ALTER TABLE public.users ADD COLUMN access_level text;
      CREATE OR REPLACE FUNCTION public.auth_is_seller_or_admin() RETURNS boolean LANGUAGE sql SECURITY DEFINER AS
        $$ SELECT EXISTS (SELECT 1 FROM public.users WHERE id=auth.uid() AND profile_type IN ('Admin Master','Vendedor')) $$;
      CREATE FUNCTION public.auth_is_vendedor() RETURNS boolean LANGUAGE sql SECURITY DEFINER AS
        $$ SELECT EXISTS (SELECT 1 FROM public.users WHERE id=auth.uid() AND profile_type='Vendedor') $$;
      CREATE FUNCTION public.auth_is_service_request() RETURNS boolean LANGUAGE sql AS
        $$ SELECT false $$;
      CREATE FUNCTION public.tg_require_documentacao() RETURNS trigger LANGUAGE plpgsql AS
        $$ BEGIN IF NOT public.auth_is_admin_documentacao() THEN RAISE EXCEPTION 'Sem permissão'; END IF; RETURN coalesce(new, old); END $$;
      ALTER TABLE public.leads ADD COLUMN seller_id uuid, ADD COLUMN created_by uuid;
      UPDATE public.leads SET seller_id='${seller}';
      ALTER TABLE public.proposal ADD COLUMN created_at timestamptz DEFAULT now();
      ALTER TABLE public.proposal_item ADD COLUMN id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        ADD COLUMN created_at timestamptz DEFAULT now(), ALTER COLUMN aircraft_item_id SET NOT NULL;
      ALTER TABLE public.contract ADD COLUMN available_aircraft_id uuid, ADD COLUMN created_at timestamptz DEFAULT now(),
        ADD COLUMN cancelled_by uuid, ADD COLUMN cancellation_reason text, ADD COLUMN cancellation_note text;
      ALTER TABLE public.user_aircraft ADD COLUMN deleted boolean DEFAULT false,
        ADD COLUMN created_at timestamptz DEFAULT now();
      ALTER TABLE public.tracking ADD COLUMN link text, ADD COLUMN created_at timestamptz DEFAULT now();
      CREATE FUNCTION public.auth_owns_user_aircraft(uuid) RETURNS boolean LANGUAGE sql AS $$ SELECT false $$;
      CREATE FUNCTION public.auth_is_linked_to_user_aircraft(uuid) RETURNS boolean LANGUAGE sql AS $$ SELECT false $$;
      CREATE TABLE public.aircraft_manuals (
        id uuid primary key, aircraft_id uuid, type text, documention_url text, deleted boolean
      );
      ALTER TABLE public.aircrafts ADD COLUMN aircraft_model text, ADD COLUMN aircraft_year text,
        ADD COLUMN aircraft_description text, ADD COLUMN aircraft_photo_url text, ADD COLUMN hopper numeric,
        ADD COLUMN featured boolean DEFAULT false;
      ALTER TABLE public.aircraft_items ADD COLUMN category_id uuid, ADD COLUMN item_name text,
        ADD COLUMN created_at timestamptz DEFAULT now();
      CREATE TABLE public.category (id uuid primary key, category_name text);
      CREATE TABLE public.company (
        id uuid primary key, lead_id uuid, company_name text, cnpj text, cpf text, phone text, type_doc text
      );
      CREATE TABLE public.address (
        id uuid primary key, company_id uuid, zipcode text, street text, number text,
        neighborhood text, city text, state text, complement text
      );
      CREATE TABLE public.available_aircrafts (
        id uuid primary key, aircraft_model uuid, serial_number text, registration_prefix text,
        manufacture_date date, configuration_deadline date, delivery_date date, entry_year text,
        status text default 'Disponível', in_stock boolean default true, created_at timestamptz default now()
      );
      CREATE TABLE public.contract_terms (id uuid primary key);
      CREATE TABLE public.tracking_details (tracking_id uuid, payment_method text);
      INSERT INTO public.users(id, name, profile_type, access_level) VALUES
        ('${admin}','Admin','Admin Master',null), ('${seller}','Vendedor','Vendedor',null),
        ('${manager}','Gerente','Vendedor','vendedor_admin');
      UPDATE public.aircrafts SET aircraft_model='Modelo inicial';
      INSERT INTO public.aircrafts(id,price,aircraft_model) VALUES('${otherAircraft}',120000,'Outro modelo');
      UPDATE public.aircraft_items SET item_name='Opcional';
      INSERT INTO public.available_aircrafts(id,aircraft_model,serial_number,delivery_date) VALUES
        ('${firstUnit}','${aircraft}','A-001','2027-01-15'),
        ('${secondUnit}','${otherAircraft}','B-001','2027-02-20');
      CREATE VIEW public.vw_aircraft_items_by_aircraft AS SELECT i.id, i.category_id, i.item_name, i.qty, i.price,
        i.active, i.deleted, i.created_at, i.item_type, l.aircraft_id
        FROM public.aircraft_items i JOIN public.aircraft_item_links l ON l.aircraft_item_id = i.id;
      CREATE INDEX contract_unit_unique ON public.contract(available_aircraft_id) WHERE cancelled_at IS NULL;
      ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.financial ENABLE ROW LEVEL SECURITY;
      CREATE POLICY fixture_sales ON public.sales FOR SELECT TO authenticated USING (true);
      CREATE POLICY fixture_finance ON public.financial FOR SELECT TO authenticated USING (true);
      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
    `);
    for (const file of ['20261112120000_sales_adjustments.sql', '20261112121000_sales_followups.sql']) {
      await db.exec(await readFile(new URL(`../migrations/${file}`, import.meta.url), 'utf8'));
    }
    await db.exec(`
      CREATE TRIGGER test_contract_stock BEFORE INSERT OR UPDATE OF available_aircraft_id, cancelled_at
        ON public.contract FOR EACH ROW EXECUTE FUNCTION public.tg_contract_stock_before();
    `);
    return db;
  } catch (error) {
    await db.close();
    throw error;
  }
}

async function useRole(db, user) {
  await db.exec('RESET ROLE');
  await db.query("select set_config('test.uid', $1, false)", [user]);
  await db.exec('SET ROLE authenticated');
}

const createWithItems = (db, items, unit=firstUnit) =>
  db.query('select public.create_proposal_with_items($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb)', [
    proposal, lead, aircraft, unit, '123456',
    JSON.stringify({...financing, initial_deposit: .10}), JSON.stringify(items),
  ]);

test('legacy catalog items, manual rows, restricted discount and 15% financing use one proposal total', async () => {
  const db = await setupAdjustments();
  try {
    await db.exec('DELETE FROM public.aircraft_item_links');
    await useRole(db, seller);
    await assert.rejects(createWithItems(db, [{aircraft_item_id: optional, discount_percent: 10}]), /Somente Admin/);
    assert.equal(await count(db, 'proposal'), 0);
    await createWithItems(db, [
      {aircraft_item_id: optional},
      {manual_name: 'Instalação adicional', quantity: 2, unit_price: 100},
    ]);
    assert.equal(Number((await db.query('select total_deposit from public.proposal_financing')).rows[0].total_deposit), 0.15);
    assert.equal(Number((await db.query('select fullprice from public.proposal')).rows[0].fullprice), 102100);
    await assert.rejects(db.exec("UPDATE public.proposal SET is_contract=true"), /administrador/);
    await db.exec("UPDATE public.proposal SET fullprice=1");
    assert.equal(Number((await db.query('select fullprice from public.proposal')).rows[0].fullprice), 102100);
    await useRole(db, manager);
    await db.query('update public.proposal_item set discount_percent=10 where aircraft_item_id=$1', [optional]);
    const detail = (await db.query('select * from public.get_proposal_details($1)', [proposal])).rows[0];
    assert.equal(detail.proposal.fullprice, 101910);
    assert.equal(detail.proposal.delivery_date, '2027-01-15');
    assert.deepEqual(detail.proposal_optional_items.map((row) => row.item.item_name).sort(), ['Instalação adicional', 'Opcional']);
    await useRole(db, seller);
    await db.query('delete from public.proposal_item where aircraft_item_id=$1', [optional]);
    assert.equal(Number((await db.query('select fullprice from public.proposal')).rows[0].fullprice), 100200);
    assert.deepEqual((await db.query('select open_proposal_refs from public.vw_stock_units where id=$1', [firstUnit])).rows[0].open_proposal_refs, ['123456']);
  } finally {
    await db.close();
  }
});

test('manager swaps the contracted model without viewing receivables and seller sees the current stage or due callback', async () => {
  const db = await setupAdjustments();
  try {
    await useRole(db, seller);
    await createWithItems(db, []);
    await useRole(db, manager);
    const {contract_id: contractId} = (await convert(db)).rows[0].result;
    await db.query('update public.contract set available_aircraft_id=$1 where id=$2', [secondUnit, contractId]);
    assert.equal((await db.query('select aircraft_id from public.vw_contract_data')).rows[0].aircraft_id, otherAircraft);
    assert.equal(await count(db, 'sales'), 0);
    assert.equal(await count(db, 'financial'), 0);
    await useRole(db, seller);
    await assert.rejects(db.query('insert into public.contract(proposal_id,created_by) values($1,$2)', [proposal,seller]),
      /administrador/);
    await assert.rejects(db.query('update public.contract set available_aircraft_id=$1 where id=$2', [firstUnit, contractId]), /administrador/);
    const {id: requestId} = (await db.query(
      "select public.request_contract_change($1,'Solicito a revisão da aeronave.') id", [contractId])).rows[0];
    await assert.rejects(db.query('select public.resolve_contract_change($1)', [requestId]), /administrativo/);
    await useRole(db, manager);
    assert.equal((await db.query("select detail from public.operational_notifications(10) where kind='contract_change'")).rows[0].detail,
      'Solicito a revisão da aeronave.');
    assert.equal((await db.query('select public.resolve_contract_change($1) resolved', [requestId])).rows[0].resolved, true);
    await useRole(db, seller);
    await assert.rejects(db.exec("update public.proposal_financing set initial_deposit=0.3"), /administrador/);
    await db.exec(`RESET ROLE;
      UPDATE public.tracking SET "isCheck"=true WHERE "order"<9;
      UPDATE public.tracking SET due_on=current_date - 1 WHERE "order"=16;
      INSERT INTO public.tracking_details SELECT id,'vista' FROM public.tracking WHERE "order"=9;
      SET ROLE authenticated;`);
    const alerts = () => db.query('select * from public.operational_notifications(10)').then((r) => r.rows);
    assert.match((await alerts())[0].detail, /Formalização/);
    await db.exec('RESET ROLE; UPDATE public.tracking SET "isCheck"=true WHERE "order"=9; SET ROLE authenticated');
    assert.match((await alerts())[0].detail, /Contratação de Seguro/);
    await useRole(db, manager);
    await db.query("select public.cancel_contract_with_follow_up($1,'outro','Mudança de plano',now()+interval '1 hour',false)", [contractId]);
    await useRole(db, seller);
    assert.equal((await alerts()).length, 0, 'canceled tracking and future callback are absent');
    await useRole(db, manager);
    await db.exec("UPDATE public.contract SET cancellation_follow_up_at=now()-interval '1 minute'");
    await useRole(db, seller);
    assert.equal((await alerts())[0].kind, 'follow_up');
    assert.equal((await db.query('select public.complete_contract_follow_up($1) completed', [contractId])).rows[0].completed, true);
    assert.equal((await alerts()).length, 0);
    assert.equal((await db.query("select public.set_lead_waiting($1,current_date,'Aguarda confirmação') ok", [lead])).rows[0].ok, true);
    assert.equal((await alerts())[0].kind, 'client_waiting');
    assert.equal((await db.query('select public.set_lead_waiting($1) ok', [lead])).rows[0].ok, true);
    assert.equal((await alerts()).length, 0);
  } finally {
    await db.close();
  }
});
