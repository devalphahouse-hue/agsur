-- ============================================================================
-- Vínculo do PILOTO passa a ser por AERONAVE (não mais por cliente).
-- ============================================================================
-- Antes: o piloto era vinculado a CLIENTES (pilot_clients) e via TODAS as
-- aeronaves de cada cliente vinculado. Agora o admin escolhe AERONAVES
-- específicas (user_aircraft) — uma, várias ou todas.
--
-- Mudança de modelo (afeta os DOIS apps):
--   1) Nova tabela pilot_aircrafts(pilot_id, user_aircraft_id) + RLS + trigger
--      de endurecimento (mesma defesa de pilot_clients).
--   2) Migra os vínculos atuais: cada pilot_clients -> pilot_aircrafts de TODAS
--      as aeronaves daqueles clientes (ninguém perde acesso no cutover).
--   3) auth_is_linked_to_client passa a ser SÓ Oficina (remove o ramo do
--      piloto via pilot_clients).
--   4) auth_is_linked_to_user_aircraft ganha o ramo do piloto via
--      pilot_aircrafts -> conserta home/detalhe (vw_my_aircraft*) e tracking.
--   5) Novo helper auth_pilot_linked_to_client(client_id): piloto vinculado a
--      alguma aeronave daquele cliente. Usado para liberar garantia e service
--      letter (tabelas keyed por cliente, sem FK de aeronave).
--   6) pilot_clients fica ÓRFÃ (parada de uso). NÃO é removida aqui para não
--      quebrar o app cliente atual (service_letters lê pilot_clients direto)
--      antes do rebuild mobile — remover em migration futura.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Tabela pilot_aircrafts
-- ---------------------------------------------------------------------------
create table if not exists public.pilot_aircrafts (
  id               uuid primary key default gen_random_uuid(),
  pilot_id         uuid not null references public.users(id) on delete cascade,
  user_aircraft_id uuid not null references public.user_aircraft(id) on delete cascade,
  created_at       timestamptz not null default now(),
  unique (pilot_id, user_aircraft_id)
);

create index if not exists idx_pilot_aircrafts_pilot
  on public.pilot_aircrafts(pilot_id);
create index if not exists idx_pilot_aircrafts_ua
  on public.pilot_aircrafts(user_aircraft_id);

alter table public.pilot_aircrafts enable row level security;

-- SELECT: gerência (vendedor/admin) tudo; o próprio piloto lê os seus vínculos.
drop policy if exists pilot_aircrafts_select on public.pilot_aircrafts;
create policy pilot_aircrafts_select on public.pilot_aircrafts
  for select to authenticated
  using (public.auth_is_seller_or_admin() or pilot_id = auth.uid());

-- WRITE: só gerência (vendedor/admin).
drop policy if exists pilot_aircrafts_write_seller on public.pilot_aircrafts;
create policy pilot_aircrafts_write_seller on public.pilot_aircrafts
  for all to authenticated
  using (public.auth_is_seller_or_admin())
  with check (public.auth_is_seller_or_admin());

-- Defesa em camadas (independe de RLS): mesmo trigger usado em pilot_clients.
drop trigger if exists hardening_require_seller_or_admin on public.pilot_aircrafts;
create trigger hardening_require_seller_or_admin
  before insert or update or delete on public.pilot_aircrafts
  for each row execute function public.tg_require_seller_or_admin();

-- ---------------------------------------------------------------------------
-- 2) Migra vínculos atuais (pilot_clients -> pilot_aircrafts)
-- ---------------------------------------------------------------------------
insert into public.pilot_aircrafts (pilot_id, user_aircraft_id)
select distinct pc.pilot_id, ua.id
  from public.pilot_clients pc
  join public.contract c      on c."user_Id" = pc.client_id
  join public.user_aircraft ua on ua.contract_id = c.id and ua.deleted = false
on conflict (pilot_id, user_aircraft_id) do nothing;

-- ---------------------------------------------------------------------------
-- 3) auth_is_linked_to_client -> SÓ Oficina (remove ramo do piloto)
-- ---------------------------------------------------------------------------
create or replace function public.auth_is_linked_to_client(p_client_id uuid)
 returns boolean
 language sql
 stable security definer
 set search_path = public
as $$
  select exists (
    select 1 from public.oficina_clients oc
    where oc.oficina_id = auth.uid() and oc.client_id = p_client_id
  );
$$;

-- ---------------------------------------------------------------------------
-- 4) auth_is_linked_to_user_aircraft -> piloto via pilot_aircrafts (+ oficina)
-- ---------------------------------------------------------------------------
create or replace function public.auth_is_linked_to_user_aircraft(p_user_aircraft_id uuid)
 returns boolean
 language sql
 stable security definer
 set search_path = public
as $$
  -- Piloto: vínculo direto com a aeronave.
  select exists (
    select 1 from public.pilot_aircrafts pa
    where pa.pilot_id = auth.uid() and pa.user_aircraft_id = p_user_aircraft_id
  )
  -- Oficina: vínculo com o cliente dono da aeronave.
  or exists (
    select 1
      from public.user_aircraft ua
      join public.contract c on c.id = ua.contract_id
     where ua.id = p_user_aircraft_id
       and public.auth_is_linked_to_client(c."user_Id")
  );
$$;

-- ---------------------------------------------------------------------------
-- 5) Novo helper: piloto vinculado a alguma aeronave do cliente
-- ---------------------------------------------------------------------------
create or replace function public.auth_pilot_linked_to_client(p_client_id uuid)
 returns boolean
 language sql
 stable security definer
 set search_path = public
as $$
  select exists (
    select 1
      from public.pilot_aircrafts pa
      join public.user_aircraft ua on ua.id = pa.user_aircraft_id
      join public.contract c       on c.id = ua.contract_id
     where pa.pilot_id = auth.uid()
       and c."user_Id" = p_client_id
  );
$$;

revoke all on function public.auth_pilot_linked_to_client(uuid) from public;
grant execute on function public.auth_pilot_linked_to_client(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 5a) Garantia: piloto vê garantias dos clientes de aeronave vinculada
-- ---------------------------------------------------------------------------
drop policy if exists guarantee_linked_client_select on public.guarantee;
create policy guarantee_linked_client_select on public.guarantee
  for select to authenticated
  using (
    public.auth_is_linked_to_client(user_id)        -- oficina
    or public.auth_pilot_linked_to_client(user_id)  -- piloto (por aeronave)
  );

-- ---------------------------------------------------------------------------
-- 5b) Service letter: idem (cliente vê o próprio; oficina/piloto vinculados)
-- ---------------------------------------------------------------------------
drop policy if exists service_letter_select on public.service_letter;
create policy service_letter_select on public.service_letter
  for select to authenticated
  using (
    public.auth_is_seller_or_admin()
    or client_id = auth.uid()
    or public.auth_is_linked_to_client(client_id)        -- oficina
    or public.auth_pilot_linked_to_client(client_id)     -- piloto (por aeronave)
  );

-- ---------------------------------------------------------------------------
-- 6) View de opções de aeronave para o seletor do painel (modelo + dono)
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER (default) + guarda auth_is_seller_or_admin() no WHERE:
-- só vendedor/admin recebem linhas; anon revogado. Mesmo padrão das
-- vw_my_aircraft* (definer com predicado de autorização).
create or replace view public.vw_aircraft_options as
  select
    ua.id                as user_aircraft_id,
    a.aircraft_model     as aircraft_model,
    a.aircraft_photo_url as aircraft_photo_url,
    c."user_Id"          as owner_id,
    u.fullname           as owner_name
  from public.user_aircraft ua
  join public.contract c   on c.id = ua.contract_id
  join public.proposal p   on p.id = c.proposal_id
  join public.aircrafts a  on a.id = p.aircraft_id
  left join public.users u on u.id = c."user_Id"
  where ua.deleted = false
    and public.auth_is_seller_or_admin();

revoke all on public.vw_aircraft_options from anon;
grant select on public.vw_aircraft_options to authenticated;

comment on table public.pilot_aircrafts is
  'Vínculo piloto -> aeronave (user_aircraft). Substitui o antigo vínculo por cliente (pilot_clients) para o perfil Piloto. Gerenciado por Vendedor/Admin.';
