-- ============================================================================
-- RLS de SELECT do acompanhamento (tracking) para Oficina/Piloto vinculado.
--
-- PROBLEMA (mesma classe do bug de pilot_certificates / guarantee)
-- tracking_select = auth_is_seller_or_admin() OR auth_owns_user_aircraft(...).
-- auth_owns_user_aircraft() resolve a aeronave pelo EMAIL do dono
-- (user_aircraft -> proposal -> leads.email = auth_user_email()), então só o
-- próprio CLIENTE lê. O agsur-app mostra as aeronaves dos clientes vinculados
-- para Oficina/Piloto na home (via oficina_clients/pilot_clients +
-- vw_my_aircrafts_home, que é SECURITY DEFINER e ignora RLS) e oferece o botão
-- "Acompanhar" -> tela de tracking consulta a tabela `tracking` direto, sob a
-- RLS do chamador. Resultado: Oficina/Piloto abre o acompanhamento de um
-- cliente vinculado e vê a timeline VAZIA.
--
-- Confirmado em produção: piloto 82332883 é vinculado ao cliente 24564eae, que
-- tem a aeronave 2c4bec1e com 21 trackings; lendo como o piloto, count = 0.
--
-- CORREÇÃO
-- Helper SECURITY DEFINER auth_is_linked_to_user_aircraft(uuid): resolve a
-- aeronave -> contract."user_Id" (o cliente dono, mesma coluna usada por
-- vw_my_aircrafts_home) e aplica auth_is_linked_to_client() — cobre Oficina
-- (oficina_clients) E Piloto (pilot_clients). É SECURITY DEFINER para que os
-- JOINs internos em user_aircraft/contract não sejam barrados pela própria RLS
-- dessas tabelas. Depois, policy permissiva de SELECT em `tracking`. Permissiva
-- (OR), só libera o fluxo legítimo já autorizado pelo produto (o vínculo).
--
-- Escopo: só `tracking` (o bug confirmado e lido direto pelo app). user_aircraft
-- e tracking_details hoje só são lidos pelo app via views SECURITY DEFINER
-- (não batem na RLS), então ficam fora — ver "candidatos" no README.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auth_is_linked_to_user_aircraft(p_user_aircraft_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_aircraft ua
    JOIN public.contract c ON c.id = ua.contract_id
    WHERE ua.id = p_user_aircraft_id
      AND public.auth_is_linked_to_client(c."user_Id")
  );
$function$;

ALTER TABLE public.tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tracking_linked_client_select ON public.tracking;
CREATE POLICY tracking_linked_client_select ON public.tracking
  FOR SELECT TO authenticated
  USING (public.auth_is_linked_to_user_aircraft(user_aircraft));
