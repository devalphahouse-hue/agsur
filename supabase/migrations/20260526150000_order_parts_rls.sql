-- ============================================================================
-- RLS de order_parts / requested_parts (cotação de peças).
--
-- PROBLEMA
-- O app cliente (oficina) envia a cotação inserindo em order_parts
-- (user_id = auth.uid()) e requested_parts (order do próprio caller). As
-- triggers de ownership (tg_order_parts_ownership / tg_requested_parts_ownership)
-- já PERMITEM esse caso (dono OU admin), mas NÃO há policy de RLS versionada
-- para essas tabelas — sem policy permissiva, o PostgREST nega (HTTP 403) e a
-- cotação falha com "Não foi possível enviar agora".
--
-- CORREÇÃO
-- Cria policies espelhando as triggers:
--   order_parts:     dono (user_id = auth.uid()) OU admin
--   requested_parts: dono da order_parts vinculada OU admin
-- São permissivas (OR), então apenas liberam o fluxo legítimo; a trigger
-- continua como defesa em camadas.
-- ============================================================================

-- =========================== order_parts ===========================
ALTER TABLE public.order_parts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS all_access ON public.order_parts;

DROP POLICY IF EXISTS order_parts_select ON public.order_parts;
CREATE POLICY order_parts_select ON public.order_parts
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.auth_is_admin());

DROP POLICY IF EXISTS order_parts_write ON public.order_parts;
CREATE POLICY order_parts_write ON public.order_parts
  FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.auth_is_admin())
  WITH CHECK (user_id = auth.uid() OR public.auth_is_admin());

-- =========================== requested_parts ===========================
ALTER TABLE public.requested_parts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS all_access ON public.requested_parts;

DROP POLICY IF EXISTS requested_parts_select ON public.requested_parts;
CREATE POLICY requested_parts_select ON public.requested_parts
  FOR SELECT TO authenticated
  USING (
    public.auth_is_admin()
    OR EXISTS (
      SELECT 1 FROM public.order_parts o
      WHERE o.id = requested_parts.order_id
        AND o.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS requested_parts_write ON public.requested_parts;
CREATE POLICY requested_parts_write ON public.requested_parts
  FOR ALL TO authenticated
  USING (
    public.auth_is_admin()
    OR EXISTS (
      SELECT 1 FROM public.order_parts o
      WHERE o.id = requested_parts.order_id
        AND o.user_id = auth.uid()
    )
  )
  WITH CHECK (
    public.auth_is_admin()
    OR EXISTS (
      SELECT 1 FROM public.order_parts o
      WHERE o.id = requested_parts.order_id
        AND o.user_id = auth.uid()
    )
  );
