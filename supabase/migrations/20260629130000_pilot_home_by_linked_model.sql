-- ============================================================================
-- Piloto: home e detalhe passam a ser por MODELO VINCULADO (pilot_aircrafts ->
-- aircrafts), não mais por avião entregue (user_aircraft).
-- ============================================================================
-- Decisão de produto: o modal "Cadastrar piloto" lista todo o catálogo e diz
-- "selecione as aeronaves que este piloto poderá acessar". A expectativa é que
-- o que for marcado apareça na home do app — marcou 1, mostra 1; marcou todas,
-- mostra todas — INDEPENDENTE de existir avião entregido daquele modelo.
--
-- Até aqui a home do piloto lia vw_my_aircrafts_home (uma linha por user_aircraft
-- entregue), então um modelo vinculado sem aeronave entregue não aparecia. Isto
-- adiciona as fontes "por modelo" que o app cliente passa a consumir para o
-- perfil Piloto. Não altera o que Cliente/Oficina enxergam.
--
-- Afeta o agsur-app (perfil Piloto). Nada some para os outros perfis.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Helper: piloto logado está vinculado a este MODELO do catálogo?
-- ---------------------------------------------------------------------------
create or replace function public.auth_is_linked_to_aircraft_model(p_aircraft_id uuid)
 returns boolean
 language sql
 stable security definer
 set search_path = public
as $$
  select exists (
    select 1
      from public.pilot_aircrafts pa
     where pa.pilot_id = auth.uid()
       and pa.aircraft_id = p_aircraft_id
  );
$$;

-- ---------------------------------------------------------------------------
-- Home do piloto: modelos vinculados a ele. SECURITY DEFINER (default) +
-- filtro por auth.uid(); anon revogado. Uma linha por vínculo pilot_aircrafts.
-- Colunas batem com AircraftsRow do app (id / aircraft_model / aircraft_photo_url).
-- ---------------------------------------------------------------------------
drop view if exists public.vw_my_pilot_aircrafts;
create view public.vw_my_pilot_aircrafts as
  select
    a.id                              as id,
    a.aircraft_model                  as aircraft_model,
    coalesce(a.aircraft_photo_url,'') as aircraft_photo_url
  from public.pilot_aircrafts pa
  join public.aircrafts a on a.id = pa.aircraft_id
  where pa.pilot_id = auth.uid()
    and a.deleted = false;
revoke all on public.vw_my_pilot_aircrafts from anon;
grant select on public.vw_my_pilot_aircrafts to authenticated;

-- ---------------------------------------------------------------------------
-- Detalhe por MODELO (manuais/specs por aircraft_id), para o piloto abrir um
-- modelo vinculado mesmo sem avião entregue. Mesma forma de vw_my_aircraft_details
-- (reaproveita VwMyAircraftDetailsRow), só que sem o join em user_aircraft e
-- com authz por modelo. Sem rastreamento — piloto não acessa tracking.
-- ---------------------------------------------------------------------------
drop view if exists public.vw_my_aircraft_model_details;
create view public.vw_my_aircraft_model_details as
  select
    a.id                  as aircraft_id,
    a.aircraft_photo_url,
    a.aircraft_model      as name,
    a.aircraft_description,
    a.hopper,
    a.price,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual de voo', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual de voo'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS flight_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual do proprietário', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual do proprietário'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS owner_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual de peças', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual de peças'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS parts_manuals
  from public.aircrafts a
    left join public.aircraft_manuals da on da.aircraft_id = a.id
  where a.deleted = false
    and (public.auth_is_seller_or_admin() or public.auth_is_linked_to_aircraft_model(a.id))
  group by a.id, a.aircraft_photo_url, a.aircraft_model, a.aircraft_description, a.hopper, a.price;
revoke all on public.vw_my_aircraft_model_details from anon;
grant select on public.vw_my_aircraft_model_details to authenticated;
