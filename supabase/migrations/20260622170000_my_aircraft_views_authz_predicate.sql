-- ============================================================================
-- Segurança 2026-06-22 — fecha IDOR em vw_my_aircrafts_home / vw_my_aircraft_details.
-- ============================================================================
-- Essas views (lidas pelo APP CLIENTE) eram SECURITY DEFINER e a app filtrava por
-- user_id/user_aircraft_id — um cliente podia passar id alheio via PostgREST e ler
-- aeronave de terceiros. Ligar security_invoker quebraria leituras vinculadas
-- (Piloto/Oficina leem clientes via inFilter('user_id', clientIds)) e os manuais
-- (aircraft_manuals é admin-only).
--
-- Correção sem quebrar nada: mantém DEFINER e adiciona PREDICADO DE AUTORIZAÇÃO no
-- WHERE com os helpers que a RLS de `tracking` já usa com sucesso no app cliente:
--   auth_is_seller_or_admin() OR auth_owns_user_aircraft(ua.id)
--                             OR auth_is_linked_to_user_aircraft(ua.id)
-- auth.uid() funciona em contexto DEFINER (lê o claim do JWT). Verificado: consulta
-- sem JWT agora retorna 0 linhas. VALIDAR no app: Cliente vê a própria aeronave;
-- Piloto/Oficina veem as dos clientes vinculados.
-- ============================================================================

create or replace view public.vw_my_aircraft_details as  SELECT a.id AS aircraft_id,
    a.aircraft_photo_url,
    a.aircraft_model AS name,
    a.aircraft_description,
    a.hopper,
    a.price,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual de voo', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual de voo'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS flight_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual do proprietário', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual do proprietário'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS owner_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual de peças', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual de peças'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS parts_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', ai.id, 'item_name', COALESCE(ai.item_name, 'Não cadastrado'::text), 'qty', COALESCE(ai.qty::text, 'Não cadastrado'::text), 'price', COALESCE(ai.price::text, 'Não cadastrado'::text))) FILTER (WHERE ai.item_type = 'series'::aircraft_item_type AND ai.deleted = false AND ai.active = true AND ai.id IS NOT NULL), '[]'::json) AS items_series,
    ua.id AS user_aircraft_id
   FROM user_aircraft ua
     JOIN contract c ON ua.contract_id = c.id
     JOIN proposal p ON c.proposal_id = p.id
     JOIN aircrafts a ON p.aircraft_id = a.id
     LEFT JOIN aircraft_manuals da ON da.aircraft_id = a.id
     LEFT JOIN aircraft_items ai ON ai.item_type = 'series'::aircraft_item_type AND ai.active = true AND ai.deleted = false
  WHERE ua.deleted = false AND (auth_is_seller_or_admin() OR auth_owns_user_aircraft(ua.id) OR auth_is_linked_to_user_aircraft(ua.id))
  GROUP BY ua.id, a.id, a.aircraft_photo_url, a.aircraft_model, a.aircraft_description, a.hopper, a.price;
create or replace view public.vw_my_aircrafts_home as  SELECT ua.id AS user_aircraft_id,
    c."user_Id" AS user_id,
    a.aircraft_photo_url,
    a.aircraft_model AS name,
    a.hopper,
    a.price
   FROM user_aircraft ua
     JOIN contract c ON ua.contract_id = c.id
     JOIN proposal p ON c.proposal_id = p.id
     JOIN aircrafts a ON p.aircraft_id = a.id
  WHERE ua.deleted = false AND (auth_is_seller_or_admin() OR auth_owns_user_aircraft(ua.id) OR auth_is_linked_to_user_aircraft(ua.id));
