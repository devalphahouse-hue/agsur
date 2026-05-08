-- ============================================================================
-- FASE 3 — Helpers de ownership para tabelas operacionais
--
-- Cliente loga com email; o vínculo com o domínio passa por:
--   leads.email = users.email
--   proposal.lead_id  -> leads.id
--   user_aircraft.proposal_id -> proposal.id
--   tracking.user_aircraft -> user_aircraft.id
--   contract.user_Id direto OU contract.proposal_id -> proposal.id
--
-- Estes helpers SECURITY DEFINER encapsulam os joins pesados e evitam
-- recursão de policy quando uma policy de tabela A consulta tabela B
-- que também tem RLS habilitada.
-- ============================================================================

-- Email do usuário atual (auth.users → public.users)
CREATE OR REPLACE FUNCTION public.auth_user_email()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT email FROM auth.users WHERE id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.auth_user_email() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_user_email() TO authenticated, anon, service_role;


-- True se o caller é dono do user_aircraft via cadeia
-- user_aircraft -> proposal -> leads -> users(email)
CREATE OR REPLACE FUNCTION public.auth_owns_user_aircraft(p_user_aircraft_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_aircraft ua
    JOIN public.proposal p ON p.id = ua.proposal_id
    JOIN public.leads l ON l.id = p.lead_id
    WHERE ua.id = p_user_aircraft_id
      AND lower(l.email) = lower(public.auth_user_email())
  );
$$;

REVOKE ALL ON FUNCTION public.auth_owns_user_aircraft(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_owns_user_aircraft(uuid) TO authenticated, anon, service_role;


-- True se o caller é dono da proposal via leads.email
CREATE OR REPLACE FUNCTION public.auth_owns_proposal(p_proposal_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.proposal p
    JOIN public.leads l ON l.id = p.lead_id
    WHERE p.id = p_proposal_id
      AND lower(l.email) = lower(public.auth_user_email())
  );
$$;

REVOKE ALL ON FUNCTION public.auth_owns_proposal(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_owns_proposal(uuid) TO authenticated, anon, service_role;


-- True se o caller é dono do contract (campo é "user_Id" com I maiúsculo)
CREATE OR REPLACE FUNCTION public.auth_owns_contract(p_contract_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.contract c
    WHERE c.id = p_contract_id
      AND (
        c."user_Id" = auth.uid()
        OR public.auth_owns_proposal(c.proposal_id)
      )
  );
$$;

REVOKE ALL ON FUNCTION public.auth_owns_contract(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_owns_contract(uuid) TO authenticated, anon, service_role;


-- True se o caller é Oficina/Piloto vinculado ao client_id passado.
-- (Usado por service_letter, guarantee de oficina, etc.)
CREATE OR REPLACE FUNCTION public.auth_is_linked_to_client(p_client_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.oficina_clients oc
    WHERE oc.oficina_id = auth.uid() AND oc.client_id = p_client_id
  )
  OR EXISTS (
    SELECT 1 FROM public.pilot_clients pc
    WHERE pc.pilot_id = auth.uid() AND pc.client_id = p_client_id
  );
$$;

REVOKE ALL ON FUNCTION public.auth_is_linked_to_client(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_linked_to_client(uuid) TO authenticated, anon, service_role;
