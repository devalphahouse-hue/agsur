-- ============================================================================
-- FASE 3 — Drop all_access em tabelas com fluxo cliente
--
-- Para cada tabela: drop policy permissiva, criar policies por operação
-- + perfil. Writes já estão protegidos pelas triggers; aqui o foco é READS.
--
-- Convenção:
--   - SELECT cliente: ownership chain via helpers SECURITY DEFINER
--   - SELECT vendedor/admin: liberado para tudo na tabela
--   - INSERT/UPDATE/DELETE: trigger genérica já bloqueia; mas adicionamos
--     policies coerentes para o PostgREST aceitar a operação após bypass
--     dos triggers (admin/vendedor)
--
-- Para "catálogos" (aircrafts, available_aircrafts, aircraft_items, category,
-- services_offering) → SELECT liberado para qualquer authenticated.
-- ============================================================================

-- ===================================================================
-- CATÁLOGOS — leitura aberta para authenticated, writes via trigger
-- ===================================================================

-- aircrafts
DROP POLICY IF EXISTS all_access ON public.aircrafts;
DROP POLICY IF EXISTS aircrafts_select_authenticated ON public.aircrafts;
CREATE POLICY aircrafts_select_authenticated ON public.aircrafts
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS aircrafts_write_seller_or_admin ON public.aircrafts;
CREATE POLICY aircrafts_write_seller_or_admin ON public.aircrafts
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- aircraft_items
DROP POLICY IF EXISTS all_access ON public.aircraft_items;
DROP POLICY IF EXISTS aircraft_items_select_authenticated ON public.aircraft_items;
CREATE POLICY aircraft_items_select_authenticated ON public.aircraft_items
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS aircraft_items_write_seller_or_admin ON public.aircraft_items;
CREATE POLICY aircraft_items_write_seller_or_admin ON public.aircraft_items
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- available_aircrafts
DROP POLICY IF EXISTS all_access ON public.available_aircrafts;
DROP POLICY IF EXISTS available_aircrafts_select_authenticated ON public.available_aircrafts;
CREATE POLICY available_aircrafts_select_authenticated ON public.available_aircrafts
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS available_aircrafts_write_seller_or_admin ON public.available_aircrafts;
CREATE POLICY available_aircrafts_write_seller_or_admin ON public.available_aircrafts
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- category
DROP POLICY IF EXISTS all_access ON public.category;
DROP POLICY IF EXISTS category_select_authenticated ON public.category;
CREATE POLICY category_select_authenticated ON public.category
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS category_write_seller_or_admin ON public.category;
CREATE POLICY category_write_seller_or_admin ON public.category
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- services_offering
DROP POLICY IF EXISTS all_access ON public.services_offering;
DROP POLICY IF EXISTS services_offering_select_authenticated ON public.services_offering;
CREATE POLICY services_offering_select_authenticated ON public.services_offering
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS services_offering_write_seller_or_admin ON public.services_offering;
CREATE POLICY services_offering_write_seller_or_admin ON public.services_offering
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());


-- ===================================================================
-- VENDEDOR/ADMIN ONLY — leads e notes
-- ===================================================================

-- leads
DROP POLICY IF EXISTS all_access ON public.leads;
DROP POLICY IF EXISTS leads_seller_or_admin_only ON public.leads;
CREATE POLICY leads_seller_or_admin_only ON public.leads
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- notes
DROP POLICY IF EXISTS all_access ON public.notes;
DROP POLICY IF EXISTS notes_seller_or_admin_only ON public.notes;
CREATE POLICY notes_seller_or_admin_only ON public.notes
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());


-- ===================================================================
-- ADDRESS — owner OR seller/admin
-- ===================================================================
DROP POLICY IF EXISTS all_access ON public.address;
DROP POLICY IF EXISTS address_owner_or_seller_select ON public.address;
CREATE POLICY address_owner_or_seller_select ON public.address
  FOR SELECT TO authenticated
  USING (
    created_by = auth.uid()
    OR public.auth_is_seller_or_admin()
  );
-- writes: trigger já cuida; criamos policies permissivas alinhadas
DROP POLICY IF EXISTS address_owner_or_seller_write ON public.address;
CREATE POLICY address_owner_or_seller_write ON public.address
  FOR INSERT TO authenticated
  WITH CHECK (
    created_by = auth.uid()
    OR public.auth_is_seller_or_admin()
  );
DROP POLICY IF EXISTS address_owner_or_seller_update ON public.address;
CREATE POLICY address_owner_or_seller_update ON public.address
  FOR UPDATE TO authenticated
  USING (
    created_by = auth.uid()
    OR public.auth_is_seller_or_admin()
  )
  WITH CHECK (
    created_by = auth.uid()
    OR public.auth_is_seller_or_admin()
  );
DROP POLICY IF EXISTS address_owner_or_seller_delete ON public.address;
CREATE POLICY address_owner_or_seller_delete ON public.address
  FOR DELETE TO authenticated
  USING (
    created_by = auth.uid()
    OR public.auth_is_seller_or_admin()
  );


-- ===================================================================
-- PROPOSAL CHAIN — proposal, proposal_item, proposal_financing
-- Cliente vê via leads.email = users.email
-- ===================================================================

-- proposal
DROP POLICY IF EXISTS all_access ON public.proposal;
DROP POLICY IF EXISTS proposal_seller_or_owner_select ON public.proposal;
CREATE POLICY proposal_seller_or_owner_select ON public.proposal
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR public.auth_owns_proposal(id)
  );
DROP POLICY IF EXISTS proposal_seller_write ON public.proposal;
CREATE POLICY proposal_seller_write ON public.proposal
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- proposal_item
DROP POLICY IF EXISTS all_access ON public.proposal_item;
DROP POLICY IF EXISTS proposal_item_select ON public.proposal_item;
CREATE POLICY proposal_item_select ON public.proposal_item
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR public.auth_owns_proposal(proposal_id)
  );
DROP POLICY IF EXISTS proposal_item_write_seller ON public.proposal_item;
CREATE POLICY proposal_item_write_seller ON public.proposal_item
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- proposal_financing
DROP POLICY IF EXISTS all_access ON public.proposal_financing;
DROP POLICY IF EXISTS proposal_financing_select ON public.proposal_financing;
CREATE POLICY proposal_financing_select ON public.proposal_financing
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR public.auth_owns_proposal(proposal_id)
  );
DROP POLICY IF EXISTS proposal_financing_write_seller ON public.proposal_financing;
CREATE POLICY proposal_financing_write_seller ON public.proposal_financing
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());


-- ===================================================================
-- CONTRACT CHAIN — contract, contract_terms
-- ===================================================================

-- contract (campo "user_Id" com I maiúsculo)
DROP POLICY IF EXISTS all_access ON public.contract;
DROP POLICY IF EXISTS contract_select ON public.contract;
CREATE POLICY contract_select ON public.contract
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR "user_Id" = auth.uid()
    OR public.auth_owns_proposal(proposal_id)
  );
DROP POLICY IF EXISTS contract_write_seller ON public.contract;
CREATE POLICY contract_write_seller ON public.contract
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- contract_terms — só admin/vendedor (agsur-app não consome essa tabela diretamente).
DROP POLICY IF EXISTS all_access ON public.contract_terms;
DROP POLICY IF EXISTS contract_terms_seller_only ON public.contract_terms;
CREATE POLICY contract_terms_seller_only ON public.contract_terms
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());


-- ===================================================================
-- TRACKING CHAIN — tracking, tracking_details, user_aircraft
-- ===================================================================

-- user_aircraft
DROP POLICY IF EXISTS all_access ON public.user_aircraft;
DROP POLICY IF EXISTS user_aircraft_select ON public.user_aircraft;
CREATE POLICY user_aircraft_select ON public.user_aircraft
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR public.auth_owns_user_aircraft(id)
  );
DROP POLICY IF EXISTS user_aircraft_write_seller ON public.user_aircraft;
CREATE POLICY user_aircraft_write_seller ON public.user_aircraft
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- tracking
DROP POLICY IF EXISTS all_access ON public.tracking;
DROP POLICY IF EXISTS tracking_select ON public.tracking;
CREATE POLICY tracking_select ON public.tracking
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR public.auth_owns_user_aircraft(user_aircraft)
  );
DROP POLICY IF EXISTS tracking_write_seller ON public.tracking;
CREATE POLICY tracking_write_seller ON public.tracking
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- tracking_details
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.tracking_details;
DROP POLICY IF EXISTS tracking_details_select ON public.tracking_details;
CREATE POLICY tracking_details_select ON public.tracking_details
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR EXISTS (
      SELECT 1 FROM public.tracking t
      WHERE t.id = tracking_details.tracking_id
        AND public.auth_owns_user_aircraft(t.user_aircraft)
    )
  );
DROP POLICY IF EXISTS tracking_details_write_seller ON public.tracking_details;
CREATE POLICY tracking_details_write_seller ON public.tracking_details
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());


-- ===================================================================
-- LINKS — oficina_clients, pilot_clients
-- ===================================================================

-- oficina_clients
DROP POLICY IF EXISTS all_access ON public.oficina_clients;
DROP POLICY IF EXISTS oficina_clients_select ON public.oficina_clients;
CREATE POLICY oficina_clients_select ON public.oficina_clients
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR oficina_id = auth.uid()
    OR client_id = auth.uid()
  );
DROP POLICY IF EXISTS oficina_clients_write_seller ON public.oficina_clients;
CREATE POLICY oficina_clients_write_seller ON public.oficina_clients
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());

-- pilot_clients
DROP POLICY IF EXISTS all_access ON public.pilot_clients;
DROP POLICY IF EXISTS pilot_clients_select ON public.pilot_clients;
CREATE POLICY pilot_clients_select ON public.pilot_clients
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR pilot_id = auth.uid()
    OR client_id = auth.uid()
  );
DROP POLICY IF EXISTS pilot_clients_write_seller ON public.pilot_clients;
CREATE POLICY pilot_clients_write_seller ON public.pilot_clients
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());


-- ===================================================================
-- SERVICE LETTER — cliente vê o próprio; oficina/piloto vê dos vinculados
-- ===================================================================
DROP POLICY IF EXISTS all_access ON public.service_letter;
DROP POLICY IF EXISTS service_letter_select ON public.service_letter;
CREATE POLICY service_letter_select ON public.service_letter
  FOR SELECT TO authenticated
  USING (
    public.auth_is_seller_or_admin()
    OR client_id = auth.uid()
    OR public.auth_is_linked_to_client(client_id)
  );
-- Writes (já tem trigger) — policies admin/vendedor
DROP POLICY IF EXISTS service_letter_write_seller ON public.service_letter;
CREATE POLICY service_letter_write_seller ON public.service_letter
  FOR ALL TO authenticated
  USING (public.auth_is_seller_or_admin())
  WITH CHECK (public.auth_is_seller_or_admin());
