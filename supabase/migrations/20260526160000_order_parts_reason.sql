-- ============================================================================
-- Adiciona coluna `reason` (motivo) em order_parts.
--
-- Usada quando o admin revisa a cotação de peças no painel: ao recusar (ou
-- mudar o status), pode registrar o motivo, que o app cliente exibe no
-- histórico da oficina ("por que foi reprovada").
-- ============================================================================

ALTER TABLE public.order_parts
  ADD COLUMN IF NOT EXISTS reason text;
