-- ============================================================================
-- Backfill: liga user_aircraft órfãos ao contrato correspondente.
--
-- PROBLEMA
-- A conversão proposta->contrato (view_edit_proposal) criava o user_aircraft
-- apenas com proposal_id, SEM contract_id. A view vw_my_aircrafts_home (usada
-- pelo app cliente) junta `user_aircraft.contract_id = contract.id`, então sem
-- esse vínculo a view retornava 0 linhas e NENHUM cliente/piloto/oficina via a
-- aeronave no app.
--
-- O código já foi corrigido para popular contract_id nas conversões futuras.
-- Esta migration corrige os registros já existentes.
--
-- Idempotente: só toca em user_aircraft com contract_id nulo que tenham um
-- contrato correspondente pelo proposal_id. Determinístico (1 contrato por
-- proposal_id; em empate, o de menor id).
-- ============================================================================

UPDATE public.user_aircraft ua
SET contract_id = (
  SELECT c.id
  FROM public.contract c
  WHERE c.proposal_id = ua.proposal_id
  ORDER BY c.id
  LIMIT 1
)
WHERE ua.contract_id IS NULL
  AND ua.proposal_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.contract c2 WHERE c2.proposal_id = ua.proposal_id
  );
