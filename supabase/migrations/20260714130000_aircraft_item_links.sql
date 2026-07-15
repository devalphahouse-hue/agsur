-- ============================================================================
-- Vínculo item ↔ aeronave (N:N) + RPC get_proposal_details versionada
-- ============================================================================
-- Demanda 2026-07-14: cada aeronave tem seus itens de série; um item pode
-- valer para vários aviões (decisão do dono: multi-vínculo). Opcionais também
-- passam a ser filtrados pelo avião na proposta.
--
-- Antes desta migration:
--   - aircraft_items não tinha NENHUM vínculo com aeronave (só category_id);
--   - a RPC get_proposal_details juntava série com `ON ai.item_type='series'`
--     (sem condição de avião) — todo item de série entraria em toda proposta;
--   - a RPC não era versionada (criada via Studio = drift conhecido, citado no
--     CLAUDE.md). Este arquivo a versiona pela primeira vez; a única mudança
--     de comportamento é o filtro de série por avião. Os placeholders
--     'Não cadastrado' foram mantidos como estão (o cliente depende deles;
--     armadilha de UUID documentada no CLAUDE.md).
--
-- Itens legados sem vínculo (4 opcionais em 2026-07-14) deixam de aparecer em
-- propostas novas até serem vinculados pela tela de edição (decisão do dono).
--
-- Segurança: espelha as regras vigentes de aircraft_items (SELECT p/
-- authenticated; write seller-or-admin via RLS + trigger BEFORE). Quando a
-- Fase 7 (rbac_level_enforcement) entrar e apertar aircraft_items para
-- documentação, apertar esta tabela junto.
-- ============================================================================

-- ── 1) Tabela de vínculo ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.aircraft_item_links (
  aircraft_item_id uuid NOT NULL REFERENCES public.aircraft_items(id) ON DELETE CASCADE,
  aircraft_id      uuid NOT NULL REFERENCES public.aircrafts(id) ON DELETE CASCADE,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       uuid DEFAULT auth.uid(),
  PRIMARY KEY (aircraft_item_id, aircraft_id)
);
COMMENT ON TABLE public.aircraft_item_links IS
  'Vínculo N:N entre aircraft_items e aircrafts. Item sem linha aqui não aparece em proposta nenhuma.';
CREATE INDEX IF NOT EXISTS idx_aircraft_item_links_aircraft
  ON public.aircraft_item_links (aircraft_id);

ALTER TABLE public.aircraft_item_links ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.aircraft_item_links FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.aircraft_item_links TO authenticated;

DROP POLICY IF EXISTS aircraft_item_links_select_authenticated ON public.aircraft_item_links;
CREATE POLICY aircraft_item_links_select_authenticated
  ON public.aircraft_item_links FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS aircraft_item_links_write_seller_or_admin ON public.aircraft_item_links;
CREATE POLICY aircraft_item_links_write_seller_or_admin
  ON public.aircraft_item_links FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.aircraft_item_links;
CREATE TRIGGER hardening_require_seller_or_admin
  BEFORE INSERT OR UPDATE OR DELETE ON public.aircraft_item_links
  FOR EACH ROW EXECUTE FUNCTION public.tg_require_seller_or_admin();

-- ── 2) View para as queries do painel (item + avião, uma linha por par) ─────
DROP VIEW IF EXISTS public.vw_aircraft_items_by_aircraft;
CREATE VIEW public.vw_aircraft_items_by_aircraft AS
SELECT
  ai.id,
  ai.category_id,
  ai.item_name,
  ai.qty,
  ai.price,
  ai.active,
  ai.deleted,
  ai.created_at,
  ai.item_type,
  l.aircraft_id
FROM public.aircraft_items ai
JOIN public.aircraft_item_links l ON l.aircraft_item_id = ai.id;

ALTER VIEW public.vw_aircraft_items_by_aircraft SET (security_invoker = on);
REVOKE ALL ON public.vw_aircraft_items_by_aircraft FROM anon, PUBLIC;
GRANT SELECT ON public.vw_aircraft_items_by_aircraft TO authenticated;

-- ── 3) RPC get_proposal_details — série filtrado pelo avião da proposta ─────
-- Corpo idêntico ao de produção (extraído em 2026-07-14), exceto o JOIN de
-- série, que era:
--     LEFT JOIN public.aircraft_items ai ON ai.item_type = 'series'
CREATE OR REPLACE FUNCTION public.get_proposal_details(p_proposal_id uuid)
 RETURNS TABLE(proposal json, proposal_lead json, proposal_company json, proposal_address json, proposal_aircraft json, proposal_series_items json, proposal_optional_items json)
 LANGUAGE plpgsql
AS $function$BEGIN
    RETURN QUERY
    WITH ordered_optional_items AS (
        SELECT
            pi.id,
            pi.proposal_id,
            pi.aircraft_item_id,
            pi.created_at,
            ai2.id AS item_id,
            ai2.qty,
            ai2.price,
            ai2.category_id,
            ai2.item_name,
            cat2.category_name
        FROM
            public.proposal_item pi
        JOIN
            public.aircraft_items ai2 ON ai2.id = pi.aircraft_item_id
        JOIN
            public.category cat2 ON cat2.id = ai2.category_id
        WHERE
            pi.proposal_id = p_proposal_id
            AND ai2.item_type = 'optional'
        ORDER BY
            cat2.category_name
    )
    SELECT
        -- Proposal
        json_build_object(
            'id', p.id,
            'lead_id', p.lead_id,
            'aircraft_id', p."aircraft_id",
            'fullprice', p.fullprice,
            'created_at', p.created_at,
            'created_by', p.created_by,
            'id_ref', p.id_ref
        ) AS proposal,
        -- Lead
        json_build_object(
            'id', l.id,
            'fullname', COALESCE(l.name || ' ' || COALESCE(l.last_name, ''), 'Não cadastrado'),
            'email', COALESCE(l.email, 'Não cadastrado'),
            'phone', COALESCE(l.phone, 'Não cadastrado')
        ) AS proposal_lead,
        -- Company
        json_build_object(
            'id', COALESCE(c.id::text, 'Não cadastrado'),
            'company_name', COALESCE(c.company_name, 'Não cadastrado'),
            'cnpj', COALESCE(c.cnpj, 'Não cadastrado'),
            'phone', COALESCE(c.phone, 'Não cadastrado'),
            'cpf', COALESCE(c.cpf, 'Não cadastrado'),
            'type_doc', COALESCE(c.type_doc, '0')
        ) AS proposal_company,
        -- Address
        json_build_object(
            'id', COALESCE(a.id::text, 'Não cadastrado'),
            'zipcode', COALESCE(a.zipcode, 'Não cadastrado'),
            'street', COALESCE(a.street, 'Não cadastrado'),
            'number', COALESCE(a.number, 'Não cadastrado'),
            'neighborhood', COALESCE(a.neighborhood, 'Não cadastrado'),
            'city', COALESCE(a.city, 'Não cadastrado'),
            'state', COALESCE(a.state, 'Não cadastrado'),
            'complement', COALESCE(NULLIF(a.complement, ''), 'Não cadastrado')
        ) AS proposal_address,
        -- Aircraft
        json_build_object(
            'aircraft_photo_url', COALESCE(air.aircraft_photo_url, 'Não cadastrado'),
            'aircraft_model', COALESCE(air.aircraft_model, 'Não cadastrado'),
            'aircraft_year', COALESCE(air.aircraft_year, 'Não cadastrado'),
            'aircraft_description', COALESCE(air.aircraft_description, 'Não cadastrado'),
            'hopper', COALESCE(air.hopper, 0)
        ) AS proposal_aircraft,
        -- Series Items: SÓ os itens vinculados ao avião da proposta
        COALESCE(
            json_agg(
                json_build_object(
                    'item_name', ai.item_name,
                    'item_type', ai.item_type,
                    'qty', ai.qty,
                    'price', ai.price,
                    'category_id', ai.category_id,
                    'category_name', (SELECT cat.category_name FROM public.category cat WHERE cat.id = ai.category_id)
                )
            ) FILTER (WHERE ai.item_type = 'series' AND ai.active = true AND ai.deleted = false),
            '[]'
        ) AS proposal_series_items,
        -- Optional Items (ordenados por category_name)
        COALESCE(
            (SELECT json_agg(
                json_build_object(
                    'id', oi.id,
                    'proposal_id', oi.proposal_id,
                    'aircraft_item_id', oi.aircraft_item_id,
                    'created_at', oi.created_at,
                    'item', json_build_object(
                        'id', oi.item_id,
                        'qty', oi.qty,
                        'price', oi.price,
                        'category_id', oi.category_id,
                        'item_name', oi.item_name,
                        'category_name', oi.category_name
                    )
                )
            ) FROM ordered_optional_items oi),
            '[]'
        ) AS proposal_optional_items
    FROM
        public.proposal p
    LEFT JOIN
        public.leads l ON l.id = p.lead_id
    LEFT JOIN
        public.company c ON c.lead_id = p.lead_id
    LEFT JOIN
        public.address a ON a.company_id = c.id
    LEFT JOIN
        public.users u ON u.id = p.created_by
    LEFT JOIN
        public.aircrafts air ON air.id = p."aircraft_id"
    LEFT JOIN
        public.aircraft_item_links ail ON ail.aircraft_id = p."aircraft_id"
    LEFT JOIN
        public.aircraft_items ai ON ai.id = ail.aircraft_item_id AND ai.item_type = 'series'
    WHERE
        p.id = p_proposal_id
    GROUP BY
        p.id, p.lead_id, p."aircraft_id", p.fullprice, p.created_at, p.created_by, p.id_ref, l.id,
        l.name, l.last_name, l.email, l.phone,
        c.id, c.company_name, c.cnpj, c.phone,
        a.id, a.zipcode, a.street, a.number, a.neighborhood, a.city, a.state, a.complement,
        u.fullname,
        air.aircraft_photo_url, air.aircraft_model, air.aircraft_year, air.aircraft_description, air.hopper;

    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            '{"id": "Não cadastrado", "lead_id": "Não cadastrado", "aircraft_id": "Não cadastrado", "fullprice": 0, "created_at": "Não cadastrado", "created_by": "Não cadastrado", "id_ref": "Não cadastrado"}'::json AS proposal,
            '{"fullname": "Não cadastrado", "email": "Não cadastrado", "phone": "Não cadastrado"}'::json AS proposal_lead,
            '{"id": "Não cadastrado", "company_name": "Não cadastrado", "cnpj": "Não cadastrado", "phone": "Não cadastrado"}'::json AS proposal_company,
            '{"id": "Não cadastrado", "zipcode": "Não cadastrado", "street": "Não cadastrado", "number": "Não cadastrado", "neighborhood": "Não cadastrado", "city": "Não cadastrado", "state": "Não cadastrado", "complement": "Não cadastrado"}'::json AS proposal_address,
            '{"aircraft_photo_url": "Não cadastrado", "aircraft_model": "Não cadastrado", "aircraft_year": "Não cadastrado", "aircraft_description": "Não cadastrado", "hopper": 0}'::json AS aircraft,
            '[]'::json AS proposal_series_items,
            '[]'::json AS proposal_optional_items;
    END IF;
END;$function$;

-- ============================================================================
-- ROLLBACK:
--   drop view if exists public.vw_aircraft_items_by_aircraft;
--   drop table if exists public.aircraft_item_links;   -- (drop da view antes)
--   -- RPC: reaplicar a definição anterior (scratchpad rpc_atual.sql / histórico
--   -- deste arquivo no git), cujo único diff é o JOIN de série sem condição
--   -- de avião.
-- ============================================================================
