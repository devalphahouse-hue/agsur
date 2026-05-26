-- ============================================================================
-- Corrige as views "minhas aeronaves" usadas pelo app cliente (agsur-app).
--
-- (2) vw_my_aircrafts_home filtrava `a.deleted = false`, mas aircrafts.deleted
--     vem da ação "Remover do catálogo" no painel. Resultado: cliente que já
--     contratou um avião perdia o acesso a ele no app se o modelo fosse
--     removido do catálogo depois. Removemos esse filtro (mantendo
--     ua.deleted = false, que é o soft-delete de posse, correto).
--
-- (3) vw_my_aircraft_details era chaveada por aircraft_id e NÃO tinha a coluna
--     user_aircraft_id — mas o app filtra por user_aircraft_id, então a tela de
--     detalhes não funcionava. Re-chaveamos a view por user_aircraft (join
--     user_aircraft -> contract -> proposal -> aircraft) e expomos
--     user_aircraft_id. Também removemos o filtro a.deleted = false aqui.
--
-- CREATE OR REPLACE preserva os GRANTs existentes (authenticated).
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_my_aircrafts_home AS
SELECT ua.id AS user_aircraft_id,
       c."user_Id" AS user_id,
       a.aircraft_photo_url,
       a.aircraft_model AS name,
       a.hopper,
       a.price
FROM public.user_aircraft ua
  JOIN public.contract c ON ua.contract_id = c.id
  JOIN public.proposal p ON c.proposal_id = p.id
  JOIN public.aircrafts a ON p.aircraft_id = a.id
WHERE ua.deleted = false;

-- vw_my_aircraft_details: mantém as colunas/ordem originais e ADICIONA
-- user_aircraft_id no final (requisito do CREATE OR REPLACE).
CREATE OR REPLACE VIEW public.vw_my_aircraft_details AS
SELECT a.id AS aircraft_id,
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
FROM public.user_aircraft ua
  JOIN public.contract c ON ua.contract_id = c.id
  JOIN public.proposal p ON c.proposal_id = p.id
  JOIN public.aircrafts a ON p.aircraft_id = a.id
  LEFT JOIN public.aircraft_manuals da ON da.aircraft_id = a.id
  LEFT JOIN public.aircraft_items ai ON ai.item_type = 'series'::aircraft_item_type AND ai.active = true AND ai.deleted = false
WHERE ua.deleted = false
GROUP BY ua.id, a.id, a.aircraft_photo_url, a.aircraft_model, a.aircraft_description, a.hopper, a.price;
