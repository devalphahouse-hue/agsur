-- ============================================================================
-- RLS de SELECT de garantias para PILOTO vinculado ao cliente.
--
-- PROBLEMA (mesma classe do bug de pilot_certificates / certificates)
-- guarantee tem policy "oficina reads linked client guarantee" (via
-- oficina_clients), mas NÃO há equivalente para o PILOTO. O agsur-app
-- (guarantees_widget) lê pilot_clients (pilot_id = auth.uid()) e consulta
-- guarantee para os clientes vinculados — tanto para Oficina quanto para
-- Piloto. Sem policy, o Piloto vê só as próprias garantias e recebe ZERO
-- linhas das garantias dos clientes vinculados (tela aparece vazia).
--
-- Confirmado em produção: para o piloto 82332883 vinculado ao cliente
-- 24564eae, auth_is_linked_to_client(client) = true, mas o caminho da policy
-- atual (EXISTS em oficina_clients) = false.
--
-- CORREÇÃO
-- Policy permissiva de SELECT usando auth_is_linked_to_client(user_id), que já
-- cobre AMBOS os vínculos (oficina_clients E pilot_clients) — o mesmo helper
-- usado por service_letter (service_letter_select). Permissiva (OR), só libera;
-- as policies existentes seguem como defesa em camadas. A policy antiga
-- "oficina reads linked client guarantee" passa a ser redundante, mas é
-- mantida (inofensiva).
-- ============================================================================

ALTER TABLE public.guarantee ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS guarantee_linked_client_select ON public.guarantee;
CREATE POLICY guarantee_linked_client_select ON public.guarantee
  FOR SELECT TO authenticated
  USING (public.auth_is_linked_to_client(user_id));
