import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
// Isolated PostgreSQL in WASM; never connects to Supabase or sends messages.
const { PGlite } = await import(process.env.PGLITE_MODULE ?? '@electric-sql/pglite');
const caller = '11111111-1111-1111-1111-111111111111';
const lead = '22222222-2222-2222-2222-222222222222';
const employee = '33333333-3333-3333-3333-333333333333';
const outsider = '44444444-4444-4444-4444-444444444444';

test('atomic scheduling, recipient authorization, queue claims and webhook ordering', async () => {
  const db = new PGlite();
  try {
    await db.exec(`
      CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
      CREATE SCHEMA auth;
      CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS $$ SELECT nullif(current_setting('test.uid', true), '')::uuid $$;
      CREATE TABLE public.users(id uuid PRIMARY KEY, name text, fullname text, phone text, profile_type text, is_active boolean, is_deleted boolean);
      CREATE TABLE public.leads(id uuid PRIMARY KEY, name text, fullname text, phone text, seller_id uuid, is_deleted boolean);
      CREATE TABLE public.notes(id uuid PRIMARY KEY DEFAULT gen_random_uuid(), lead_id uuid, note text, created_by uuid);
      CREATE FUNCTION public.auth_is_seller_or_admin() RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
        SELECT EXISTS(SELECT 1 FROM public.users WHERE id = auth.uid() AND profile_type IN ('Admin Master','Admin','Vendedor')) $$;
      GRANT USAGE ON SCHEMA auth TO authenticated;
      GRANT SELECT ON public.users TO authenticated;
      INSERT INTO public.users VALUES
        ('${caller}', 'Vendedor', NULL, '11999999999', 'Vendedor', true, false),
        ('${employee}', 'Equipe', NULL, '11888888888', 'Colaborador', true, false),
        ('${outsider}', 'Cliente', NULL, '11777777777', 'Cliente', true, false);
      INSERT INTO public.leads VALUES ('${lead}', 'Lead', NULL, '(11) 99999-9999', '${caller}', false);
      SELECT set_config('test.uid','${caller}',false);
    `);
    await db.exec(await readFile(new URL('../migrations/20261013120000_whatsapp_reminders.sql', import.meta.url), 'utf8'));
    const rpc = 'SELECT public.create_note_with_whatsapp_reminder($1::uuid,$2::text,$3::text,$4::uuid[],$5::timestamptz,$6::boolean) AS id';
    const future = new Date(Date.now() + 3600000).toISOString();
    await db.exec('SET ROLE authenticated');
    await assert.rejects(db.query(rpc, [lead, 'Invalid', 'equipe', [outsider], future, true]), /Destinatário indisponível/);
    await assert.rejects(db.query(rpc, [lead, 'Past', 'cliente', [lead], '2020-01-01', true]), /data futura/);
    await assert.rejects(db.query(rpc, [lead, 'No consent', 'cliente', [lead], future, false]), /autorização/);
    await assert.rejects(db.query(rpc, [lead, 'Too long'.repeat(200), 'cliente', [lead], future, true]), /900/);
    await assert.rejects(db.query('SELECT * FROM public.claim_whatsapp_reminders()'), /permission denied/);
    await assert.rejects(db.query(`INSERT INTO public.whatsapp_reminders DEFAULT VALUES`), /permission denied/);
    await db.query(rpc, [lead, 'Equipe meeting', 'equipe', [caller, employee], future, true]);
    await db.query(rpc, [lead, 'Client meeting', 'cliente', [lead], future, true]);
    const rows = (await db.query('SELECT * FROM public.whatsapp_reminders')).rows;
    assert.equal(rows.length, 3);
    assert.ok(rows.every(r => r.recipient_phone.startsWith('55')));
    await db.exec('RESET ROLE');
    assert.equal((await db.query('SELECT count(*)::int AS n FROM public.notes')).rows[0].n, 2, 'invalid recipients roll back note');
    await db.exec(`SELECT set_config('test.uid','${outsider}',false); SET ROLE authenticated`);
    assert.equal((await db.query('SELECT * FROM public.whatsapp_reminders')).rows.length, 0);
    await assert.rejects(db.query(rpc, [lead, 'Forbidden', null, [], null, false]), /Acesso negado/);
    await db.exec('RESET ROLE; SET ROLE service_role');
    assert.equal((await db.query('SELECT * FROM public.claim_whatsapp_reminders()')).rows.length, 0, 'future reminders wait');
    await db.exec("RESET ROLE; UPDATE public.whatsapp_reminders SET scheduled_at = now() - interval '1 minute'; SET ROLE service_role");
    const claimed = (await db.query('SELECT * FROM public.claim_whatsapp_reminders()')).rows;
    assert.equal(claimed.length, 3);
    assert.equal((await db.query('SELECT * FROM public.claim_whatsapp_reminders()')).rows.length, 0, 'claims cannot be repeated');
    const id = claimed[0].id;
    const statusRpc = 'SELECT public.record_whatsapp_status($1,$2,$3::timestamptz,$4,$5::uuid)';
    await db.query(statusRpc, ['wamid.test','delivered','2026-10-13T12:02:00Z',null,id]);
    await db.query(statusRpc, ['wamid.test','sent','2026-10-13T12:01:00Z',null,id]);
    await db.query(statusRpc, ['wamid.test','failed','2026-10-13T12:03:00Z','error',id]);
    let row = (await db.query('SELECT * FROM public.whatsapp_reminders WHERE id = $1', [id])).rows[0];
    assert.equal(row.delivery_status, 'delivered', 'late failure cannot downgrade delivered');
    await db.query(statusRpc, ['wamid.test','read','2026-10-13T12:04:00Z',null,id]);
    await db.query(statusRpc, ['wamid.test','read','2026-10-13T12:04:00Z',null,id]);
    row = (await db.query('SELECT * FROM public.whatsapp_reminders WHERE id = $1', [id])).rows[0];
    assert.equal(row.delivery_status, 'read');
    assert.equal(row.meta_message_id, 'wamid.test', 'early webhook attaches provider ID');
    await db.exec("RESET ROLE; UPDATE public.whatsapp_reminders SET claimed_at = now() - interval '11 minutes' WHERE status = 'Processando'; SET ROLE service_role");
    assert.equal((await db.query('SELECT * FROM public.claim_whatsapp_reminders()')).rows.length, 0, 'stale claims never resend');
    assert.equal((await db.query("SELECT count(*)::int AS n FROM public.whatsapp_reminders WHERE error_code = 'dispatch_outcome_unknown'")).rows[0].n, 2);
  } finally { await db.close(); }
});

test('cron stays inactive without Vault secrets and calls only the configured worker', async () => {
  const db = new PGlite();
  try {
    await db.exec(`
      CREATE SCHEMA cron; CREATE SCHEMA net; CREATE SCHEMA vault;
      CREATE TABLE cron.jobs(name text, schedule text, command text);
      CREATE TABLE vault.decrypted_secrets(name text, decrypted_secret text);
      CREATE TABLE net.calls(url text, headers jsonb, body jsonb, timeout integer);
      CREATE FUNCTION cron.schedule(text,text,text) RETURNS integer LANGUAGE plpgsql AS $$ BEGIN
        INSERT INTO cron.jobs VALUES ($1,$2,$3); RETURN 1; END; $$;
      CREATE FUNCTION net.http_post(url text, headers jsonb, body jsonb, timeout_milliseconds integer) RETURNS bigint LANGUAGE plpgsql AS $$ BEGIN
        INSERT INTO net.calls VALUES ($1,$2,$3,$4); RETURN 1; END; $$;
    `);
    let migration = await readFile(new URL('../migrations/20261013121000_whatsapp_reminders_cron.sql', import.meta.url), 'utf8');
    migration = migration.replace(/^CREATE EXTENSION.*;$/gm, ''); // Extensions are Supabase-native; mock interfaces locally.
    await db.exec(migration);
    const job = (await db.query('SELECT * FROM cron.jobs')).rows[0];
    assert.equal(job.schedule, '* * * * *');
    await db.exec(job.command);
    assert.equal((await db.query('SELECT * FROM net.calls')).rows.length, 0);
    await db.exec("INSERT INTO vault.decrypted_secrets VALUES ('whatsapp_functions_url','https://test.supabase.co/functions/v1/'),('whatsapp_dispatch_secret','secret');");
    await db.exec(job.command);
    const call = (await db.query('SELECT * FROM net.calls')).rows[0];
    assert.equal(call.url, 'https://test.supabase.co/functions/v1/whatsapp-reminders');
    assert.equal(call.headers.Authorization, 'Bearer secret');
    assert.equal(call.timeout, 60000);
  } finally { await db.close(); }
});
