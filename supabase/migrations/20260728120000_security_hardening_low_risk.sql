-- ============================================================================
-- Endurecimento de baixo risco — achados da auditoria de 2026-07-28.
-- ============================================================================
-- Cobre 4 dos 7 achados. NÃO mexe em nenhum fluxo do painel nem do app:
-- são revokes de acesso que já é negado por checagem interna, restauração de
-- atributos perdidos e uma opção de planejador. A escalada de privilégio em
-- public.users (o achado grave) vai na migration IRMÃ 20260728121000, que é
-- separada de propósito porque exige validação com login real de cada perfil.
--
--   F2 — chat_participants: o UPDATE deixava a pessoa mover a PRÓPRIA linha
--        para outra thread e ler a DM alheia.
--   F3 — 6 funções ficaram de fora do revoke de anon de 20260722202000.
--   F4 — get_proposal_details perdeu SECURITY/search_path num CREATE OR REPLACE.
--   F6 — as 5 views definer de autorização não são security_barrier.
--
-- Rollback de cada bloco está comentado junto dele.
-- ============================================================================


-- ── F2 — chat_participants: thread_id passa a ser imutável ──────────────────
-- A policy chat_participants_update_own (20260628120000) valida só
-- `user_id = auth.uid()` no WITH CHECK. Como a PK é (thread_id, user_id), o
-- thread_id ficava livre: um usuário do painel movia a própria participação
-- para a conversa de outros dois e passava a ler mensagens e anexos
-- (chat_is_member vira true). Ele nunca conseguiria INSERIR essa linha — não
-- há policy de INSERT, threads nascem só pela RPC chat_get_or_create_dm —
-- então o UPDATE levava a linha a um estado inalcançável por criação.
--
-- RLS não expressa "coluna imutável", então o caminho é grant por coluna: o
-- único UPDATE legítimo desta tabela é marcar leitura (last_read_at).
REVOKE UPDATE ON public.chat_participants FROM authenticated;
GRANT  UPDATE (last_read_at) ON public.chat_participants TO authenticated;
-- Rollback: GRANT UPDATE ON public.chat_participants TO authenticated;


-- ── F3 — revoke de anon nas funções que sobraram ────────────────────────────
-- 20260722202000 documentou que `revoke ... from public` NÃO remove o grant
-- direto que o `alter default privileges` do Supabase dá a `anon` em toda
-- função nova de public — e corrigiu as 5 RPCs admin. Estas 6 ficaram de fora
-- (duas delas sem revoke nenhum). O impacto prático hoje é nulo: todas têm
-- gate interno e devolvem false/42501 sem JWT. É redução de superfície.
-- assinatura real é (retention_days int DEFAULT 365) — ver 20260508121500
REVOKE EXECUTE ON FUNCTION public.purge_security_audit_log(int)          FROM anon;
REVOKE EXECUTE ON FUNCTION public.auth_pilot_linked_to_client(uuid)      FROM anon;
REVOKE EXECUTE ON FUNCTION public.chat_is_member(uuid)                   FROM anon;
REVOKE EXECUTE ON FUNCTION public.chat_get_or_create_dm(uuid)            FROM anon;
REVOKE EXECUTE ON FUNCTION public.auth_is_linked_to_aircraft_model(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_proposal_details(uuid)             FROM anon;
-- tg_chat_bump_thread é função de trigger: não é chamável por REST, mas o
-- grant existe do mesmo jeito. Revogado por consistência.
REVOKE EXECUTE ON FUNCTION public.tg_chat_bump_thread()                  FROM anon;
-- Rollback: GRANT EXECUTE ON FUNCTION <nome> TO anon;


-- ── F4 — get_proposal_details: restaura search_path ─────────────────────────
-- 20260714130000 recriou a função para filtrar itens de série pelo avião da
-- proposta, mas o CREATE OR REPLACE omitiu as cláusulas SECURITY/SET — e em
-- Postgres atributo não especificado VOLTA AO DEFAULT. A função ficou sem
-- search_path pinado, que é o vetor de escalonamento que o batch de maio
-- fechou em todas as outras.
--
-- Deliberadamente NÃO mexemos em SECURITY DEFINER/INVOKER aqui: o estado
-- anterior a 14/07 não está versionado em lugar nenhum, então promover para
-- definer às cegas ampliaria acesso. Invoker + RLS é o lado seguro; se a tela
-- de detalhe da proposta perder dado para algum perfil, é sinal de que ela
-- dependia do definer — e aí a decisão é consciente, não acidental.
ALTER FUNCTION public.get_proposal_details(uuid) SET search_path = public;
-- Rollback: ALTER FUNCTION public.get_proposal_details(uuid) RESET search_path;


-- ── F6 — security_barrier nas views definer de autorização ──────────────────
-- Estas 5 views são SECURITY DEFINER com o predicado de autorização no WHERE.
-- Sem security_barrier o planejador pode empurrar uma qual do usuário para
-- baixo do predicado; com função/operador *leaky* no filtro dá para inferir
-- conteúdo de linha que a view não deveria devolver (canal lateral por erro ou
-- por custo). Não é leitura direta de dado alheio — daí a gravidade baixa —
-- mas a correção é de uma linha por view.
ALTER VIEW public.vw_my_aircrafts_home           SET (security_barrier = true);
ALTER VIEW public.vw_my_aircraft_details         SET (security_barrier = true);
ALTER VIEW public.vw_aircraft_options            SET (security_barrier = true);
ALTER VIEW public.vw_my_pilot_aircrafts          SET (security_barrier = true);
ALTER VIEW public.vw_my_aircraft_model_details   SET (security_barrier = true);
-- Rollback: ALTER VIEW public.<v> RESET (security_barrier);
--
-- ⚠️ CUIDADO PARA O FUTURO: um `create or replace view` posterior sem a
-- cláusula WITH reseta as reloptions e derruba isto — mesma armadilha do
-- security_invoker registrada em 20260622140000. Ao recriar qualquer uma
-- destas 5, reaplique o ALTER logo em seguida.
