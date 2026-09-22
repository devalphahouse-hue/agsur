-- Captura as RPCs não versionadas + trava o vocabulário de status do estoque
--
-- (1) DUAS FUNÇÕES DE PRODUÇÃO SÓ EXISTIAM NO BANCO VIVO
-- `get_aircraft_details_by_proposal` (lida pela criação de proposta, via
-- `api_calls.dart`) e `fn_available_aircrafts` (listagem antiga do estoque)
-- nunca estiveram no git: qualquer edição nelas era cega, sem diff e sem
-- histórico. Risco levantado no SPRINT_1.md ("o maior risco não
-- quantificado"). Os corpos abaixo são os de produção, extraídos com
-- `pg_get_functiondef` em 2026-09-22 — **o comportamento não muda**, com duas
-- exceções deliberadas e seguras:
--
--   * `set search_path = public` nas duas. Sem isso, função sem search_path
--     fixo resolve nomes pelo caminho de quem chama.
--   * `revoke ... from public, anon` + grant explícito. As duas estavam
--     executáveis por `anon` (herança do default ACL do Supabase; as duas
--     metades do revoke estão no CLAUDE.md). Não havia vazamento — são
--     SECURITY INVOKER e as policies de `proposal`/`available_aircrafts` são
--     todas `TO authenticated`, então anon não casa policy nenhuma e a RLS
--     nega. É defesa em camadas, não conserto de falha.
--
-- ⚠️ `fn_available_aircrafts` não é mais usada pela tela de estoque (que agora
-- lê `vw_stock_units`), mas segue chamada por `api_calls.dart`. Fica
-- versionada para poder ser removida com segurança depois.
--
-- (2) VOCABULÁRIO DE STATUS
-- A listagem antiga filtrava `Disponível/Vendido/Reservado` e o cadastro
-- gravava `Disponível/Em negociação/Entregue/Vendido`: `Reservado` era
-- filtrável e nunca gravável. Hoje a UI usa `stockStatusOptions`
-- (`lib/backend/stock.dart`), mas nada impedia gravar um valor novo por fora.
-- O CHECK abaixo é a UNIÃO de tudo que a UI usa e de tudo que existe no banco
-- hoje (medido: Disponível 3, Baixado 2, Entregue 1, Vendido 1) — nenhuma
-- linha existente fica ilegal, e não há DML (logo, sem desarmar trigger).

-- ── 1) Captura verbatim ──────────────────────────────────────────────────────

create or replace function public.get_aircraft_details_by_proposal(p_proposal_id uuid)
returns json
language sql
set search_path = public
as $function$
  SELECT row_to_json(t)
  FROM (
    SELECT *
    FROM proposal p
    LEFT JOIN aircrafts a ON a.id = p.aircraft_id
    WHERE p.id = p_proposal_id
    LIMIT 1
  ) t;
$function$;

comment on function public.get_aircraft_details_by_proposal(uuid) is
  'Proposta + modelo do catálogo em JSON. Lida por api_calls.dart na criação '
  'de proposta. Corpo capturado do banco em 2026-09-22 (antes só existia lá).';

create or replace function public.fn_available_aircrafts(
  p_entry_year text default null,
  p_status text default null
)
returns table(
  id uuid, aircraft_model_id uuid, serial_number text, manufacture_date text,
  configuration_deadline text, delivery_date text, status text,
  created_at timestamptz, created_by uuid, update_by uuid, entry_year text,
  aircraft_id uuid, aircraft_model text, aircraft_photo_url text
)
language plpgsql
set search_path = public
as $function$
BEGIN
  -- Se p_entry_year for nulo ou vazio, usa o ano atual (ex.: 2025 em 05/04/2025)
  -- Se p_status for nulo ou vazio, não filtra por status
  RETURN QUERY
  SELECT
    aa.id,
    aa.aircraft_model AS aircraft_model_id,
    aa.serial_number,
    TO_CHAR(aa.manufacture_date, 'DD/MM/YYYY') AS manufacture_date,
    TO_CHAR(aa.configuration_deadline, 'DD/MM/YYYY') AS configuration_deadline,
    TO_CHAR(aa.delivery_date, 'DD/MM/YYYY') AS delivery_date,
    aa.status,
    aa.created_at,
    aa.created_by,
    aa.update_by,
    aa.entry_year,
    a.id AS aircraft_id,
    a.aircraft_model,
    a.aircraft_photo_url
  FROM public.available_aircrafts aa
  INNER JOIN public.aircrafts a ON aa.aircraft_model = a.id
  WHERE aa.entry_year = COALESCE(NULLIF(p_entry_year, ''), EXTRACT(YEAR FROM CURRENT_DATE)::TEXT)
    AND (NULLIF(TRIM(LOWER(p_status)), '') IS NULL
    OR NULLIF(TRIM(LOWER(p_status)), '') = 'null'
    OR TRIM(p_status) = 'Todos'
    OR aa.status = p_status);
END;
$function$;

comment on function public.fn_available_aircrafts(text, text) is
  'Listagem antiga do estoque (uma linha por unidade, com o nome do modelo). '
  'Corpo capturado do banco em 2026-09-22. A tela de estoque usa vw_stock_units '
  'desde 20260922120000; esta segue em api_calls.dart.';

revoke all on function public.get_aircraft_details_by_proposal(uuid) from public, anon;
revoke all on function public.fn_available_aircrafts(text, text) from public, anon;
grant execute on function public.get_aircraft_details_by_proposal(uuid) to authenticated, service_role;
grant execute on function public.fn_available_aircrafts(text, text) to authenticated, service_role;

-- ── 2) Status: vocabulário único ────────────────────────────────────────────

alter table public.available_aircrafts
  drop constraint if exists ck_available_aircrafts_status;
alter table public.available_aircrafts
  add constraint ck_available_aircrafts_status
  check (status in (
    -- em estoque (escolhidos à mão; ver stockStatusOptions no Dart)
    'Disponível', 'Em negociação', 'Reservado',
    -- fora do estoque
    'Vendido',     -- trigger do contrato
    'Entregue',    -- manual
    'Baixado'      -- saída manual
  ));

comment on column public.available_aircrafts.status is
  'Estado comercial da unidade. Conjunto fechado pelo CHECK '
  'ck_available_aircrafts_status; espelhado em stockStatusOptions '
  '(lib/backend/stock.dart) — mexeu num, mexa no outro.';
