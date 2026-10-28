-- Administrative bootstrap invoked only by the authenticated deployment pipeline.
-- The generated key is stored in Vault, never in the migration or returned to clients.
create function public.configure_signature_dispatcher(p_secret text) returns void
language plpgsql security definer set search_path=public as $$
declare secret_id uuid; item record;
begin
 if p_secret is null or p_secret !~ '^[a-f0-9]{64}$' then raise exception 'Segredo inválido'; end if;
 perform pg_advisory_xact_lock(hashtext('signature_dispatch_configuration'));
 for item in select * from (values
  ('signature_functions_url','https://bkzybtmxxzpxtztesdye.supabase.co/functions/v1'),
  ('signature_dispatch_secret',p_secret)) as v(name,value) loop
  select id into secret_id from vault.secrets where name=item.name;
  if found then perform vault.update_secret(secret_id,item.value);
  else perform vault.create_secret(item.value,item.name); end if;
 end loop;
end $$;
revoke all on function public.configure_signature_dispatcher(text) from public,anon,authenticated;
grant execute on function public.configure_signature_dispatcher(text) to service_role;
