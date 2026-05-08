-- ============================================================================
-- Índices para performance das policies RLS por ownership chain.
--
-- As policies de proposal/contract/tracking/etc. fazem joins via
-- proposal.lead_id, user_aircraft.proposal_id, tracking.user_aircraft,
-- tracking_details.tracking_id, contract.proposal_id, contract."user_Id",
-- e leads.email. Sem índices, cada SELECT do cliente faz seq scan.
--
-- Para email usamos lower(email) porque o helper auth_owns_proposal
-- compara via lower(l.email) = lower(public.auth_user_email()).
-- ============================================================================

-- proposal
CREATE INDEX IF NOT EXISTS idx_proposal_lead_id ON public.proposal (lead_id);

-- user_aircraft
CREATE INDEX IF NOT EXISTS idx_user_aircraft_proposal_id
  ON public.user_aircraft (proposal_id);

-- tracking
CREATE INDEX IF NOT EXISTS idx_tracking_user_aircraft
  ON public.tracking (user_aircraft);

-- tracking_details
CREATE INDEX IF NOT EXISTS idx_tracking_details_tracking_id
  ON public.tracking_details (tracking_id);

-- contract
CREATE INDEX IF NOT EXISTS idx_contract_proposal_id
  ON public.contract (proposal_id);
CREATE INDEX IF NOT EXISTS idx_contract_user_id
  ON public.contract ("user_Id");

-- leads (email lower-case para case-insensitive match)
CREATE INDEX IF NOT EXISTS idx_leads_email_lower
  ON public.leads (lower(email));

-- proposal_item / proposal_financing referenciam proposal_id
CREATE INDEX IF NOT EXISTS idx_proposal_item_proposal_id
  ON public.proposal_item (proposal_id);
CREATE INDEX IF NOT EXISTS idx_proposal_financing_proposal_id
  ON public.proposal_financing (proposal_id);

-- requested_parts.order_id (usado em auth_*)
CREATE INDEX IF NOT EXISTS idx_requested_parts_order_id
  ON public.requested_parts (order_id);

-- order_parts.user_id (policy + queries do app)
CREATE INDEX IF NOT EXISTS idx_order_parts_user_id
  ON public.order_parts (user_id);

-- pilot_certificates.user_id
CREATE INDEX IF NOT EXISTS idx_pilot_certificates_user_id
  ON public.pilot_certificates (user_id);

-- guarantee
CREATE INDEX IF NOT EXISTS idx_guarantee_user_id
  ON public.guarantee (user_id);

-- service_letter.client_id (queries do app)
CREATE INDEX IF NOT EXISTS idx_service_letter_client_id
  ON public.service_letter (client_id);

-- security_audit_log: já criado nas migrations anteriores, sem alteração

-- analyze para o planner pegar os novos índices
ANALYZE public.proposal;
ANALYZE public.user_aircraft;
ANALYZE public.tracking;
ANALYZE public.tracking_details;
ANALYZE public.contract;
ANALYZE public.leads;
ANALYZE public.proposal_item;
ANALYZE public.proposal_financing;
ANALYZE public.requested_parts;
ANALYZE public.order_parts;
ANALYZE public.pilot_certificates;
ANALYZE public.guarantee;
ANALYZE public.service_letter;
