-- ============================================================================
-- RBAC do painel — sub-nível de acesso para colaboradores Admin
--
-- Introduz a coluna `access_level` em public.users. Ela só se aplica quando
-- profile_type = 'Admin' e distingue:
--   'recepcao'      — vê Pilotos, Oficinas, Garantias, Certificados,
--                     Cartas de serviço e Cotação de peças.
--   'documentacao'  — vê Solicitações, Funil de vendas, Rastreio, Aeronaves,
--                     Cartas de serviço, Garantias, Taxas e juros e Termos.
-- Para os demais profile_type (Admin Master, Vendedor, Cliente, Piloto,
-- Oficina) a coluna fica NULL — o profile_type já governa o acesso.
--
-- Backfill: colaboradores Admin existentes viram 'recepcao' (decisão do dono).
-- ============================================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS access_level text;

UPDATE public.users
SET access_level = 'recepcao'
WHERE profile_type = 'Admin'
  AND access_level IS NULL;

COMMENT ON COLUMN public.users.access_level IS
  'Sub-nivel do painel para profile_type=Admin: recepcao | documentacao. NULL para os demais.';
