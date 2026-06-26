-- ============================================================================
-- Vínculo do PILOTO passa de AERONAVE REAL (user_aircraft) para MODELO do
-- catálogo (aircrafts).
-- ============================================================================
-- Ontem (20260625130000) o vínculo do piloto virou por aeronave entregue a um
-- dono (user_aircraft, via contrato). Decisão de produto: o seletor do painel
-- deve listar TODO o catálogo de aeronaves (tabela aircrafts), não só as
-- entregues. Então o vínculo passa a ser por MODELO do catálogo.
--
-- ⚠️ CONSEQUÊNCIA DE ACESSO (intencional): um piloto vinculado a um modelo passa
--    a enxergar TODAS as aeronaves daquele modelo, de QUALQUER dono (home,
--    tracking, garantia, service letter). Antes era só a aeronave específica.
--
-- Mudança (afeta os DOIS apps):
--   1) pilot_aircrafts: troca user_aircraft_id (FK user_aircraft) por aircraft_id
--      (FK aircrafts). Backfill dos vínculos atuais via
--      user_aircraft -> contract -> proposal -> aircraft.
--   2) auth_is_linked_to_user_aircraft: ramo do piloto passa a casar o MODELO da
--      aeronave (proposal.aircraft_id) com pilot_aircrafts.aircraft_id.
--   3) auth_pilot_linked_to_client: idem (cliente que tem aeronave de modelo
--      vinculado ao piloto).
--   4) vw_aircraft_options: passa a listar o catálogo (aircrafts) em vez de
--      user_aircraft. Sem dono (catálogo não tem dono).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) pilot_aircrafts: user_aircraft_id -> aircraft_id
-- ---------------------------------------------------------------------------
alter table public.pilot_aircrafts
  add column if not exists aircraft_id uuid references public.aircrafts(id) on delete cascade;

-- Backfill: cada vínculo por aeronave real vira vínculo pelo modelo dela.
update public.pilot_aircrafts pa
   set aircraft_id = p.aircraft_id
  from public.user_aircraft ua
  join public.contract c on c.id = ua.contract_id
  join public.proposal p on p.id = c.proposal_id
 where pa.user_aircraft_id = ua.id
   and pa.aircraft_id is null;

-- Vínculos que não puderam ser mapeados (aeronave sem proposta/modelo válido)
-- são descartados — não há modelo de catálogo para apontar.
delete from public.pilot_aircrafts where aircraft_id is null;

-- Troca a unicidade (pilot, aeronave) -> (pilot, modelo) e remove a coluna antiga.
alter table public.pilot_aircrafts
  drop constraint if exists pilot_aircrafts_pilot_id_user_aircraft_id_key;
drop index if exists idx_pilot_aircrafts_ua;
alter table public.pilot_aircrafts drop column if exists user_aircraft_id;
alter table public.pilot_aircrafts alter column aircraft_id set not null;
alter table public.pilot_aircrafts
  add constraint pilot_aircrafts_pilot_id_aircraft_id_key unique (pilot_id, aircraft_id);
create index if not exists idx_pilot_aircrafts_aircraft
  on public.pilot_aircrafts(aircraft_id);

comment on table public.pilot_aircrafts is
  'Vínculo piloto -> MODELO de aeronave (aircrafts). O piloto enxerga todas as aeronaves daquele modelo. Gerenciado por Vendedor/Admin.';

-- ---------------------------------------------------------------------------
-- 2) auth_is_linked_to_user_aircraft -> piloto por MODELO (+ oficina por cliente)
-- ---------------------------------------------------------------------------
create or replace function public.auth_is_linked_to_user_aircraft(p_user_aircraft_id uuid)
 returns boolean
 language sql
 stable security definer
 set search_path = public
as $$
  -- Piloto: vínculo pelo MODELO da aeronave (catálogo).
  select exists (
    select 1
      from public.pilot_aircrafts pa
      join public.user_aircraft ua on ua.id = p_user_aircraft_id
      join public.contract c       on c.id = ua.contract_id
      join public.proposal p       on p.id = c.proposal_id
     where pa.pilot_id = auth.uid()
       and pa.aircraft_id = p.aircraft_id
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
-- 3) auth_pilot_linked_to_client -> via modelo vinculado
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
      join public.proposal p on p.aircraft_id = pa.aircraft_id
      join public.contract c on c.proposal_id = p.id
     where pa.pilot_id = auth.uid()
       and c."user_Id" = p_client_id
  );
$$;

-- ---------------------------------------------------------------------------
-- 4) vw_aircraft_options: catálogo (aircrafts) para o seletor do painel
-- ---------------------------------------------------------------------------
-- Muda a lista de colunas (some o dono), então DROP + CREATE (não CREATE OR
-- REPLACE, que proíbe remover/renomear colunas).
-- SECURITY DEFINER (default) + guarda auth_is_seller_or_admin() no WHERE: só
-- vendedor/admin recebem linhas; anon revogado.
drop view if exists public.vw_aircraft_options;
create view public.vw_aircraft_options as
  select
    a.id                 as aircraft_id,
    a.aircraft_model     as aircraft_model,
    a.aircraft_photo_url as aircraft_photo_url
  from public.aircrafts a
  where a.deleted = false
    and public.auth_is_seller_or_admin();

revoke all on public.vw_aircraft_options from anon;
grant select on public.vw_aircraft_options to authenticated;
