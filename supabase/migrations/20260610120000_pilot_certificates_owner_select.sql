-- ============================================================================
-- RLS de SELECT do DONO em pilot_certificates.
--
-- PROBLEMA
-- pilot_certificates tem RLS habilitado, mas as únicas policies existentes
-- (adm_select/adm_insert/adm_update) liberam apenas admins (users.is_admin =
-- true). Não há nenhuma policy permitindo o PRÓPRIO piloto LER seus
-- certificados. A view pilot_certificates_view é security_invoker=on, então
-- aplica a RLS da tabela base no contexto do chamador: o painel (admin)
-- enxerga via adm_select, mas o agsur-app (perfil Piloto) recebe ZERO linhas e
-- mostra "Nenhum certificado por aqui", mesmo com o certificado cadastrado e
-- corretamente vinculado (user_id = auth.uid() do piloto).
--
-- Mesma classe de bug já corrigida para order_parts/requested_parts
-- (20260526150000) e guarantee (20260526170000): RLS ligado sem policy do dono.
--
-- CORREÇÃO
-- Policy permissiva de SELECT espelhando a trigger de ownership
-- (tg_pilot_certificates_ownership): dono (user_id = auth.uid()) OU admin.
-- Para o dono filtramos is_deleted = false (a view e a query do app NÃO
-- filtram is_deleted, então sem isso o piloto veria certificados apagados);
-- admin (auth_is_admin, cobre Admin/Admin Master mesmo com is_admin=false)
-- continua vendo tudo, consistente com o resto do schema. É permissiva (OR),
-- só libera o fluxo legítimo; a trigger segue como defesa em camadas.
-- ============================================================================

ALTER TABLE public.pilot_certificates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pilot_certificates_owner_select ON public.pilot_certificates;
CREATE POLICY pilot_certificates_owner_select ON public.pilot_certificates
  FOR SELECT TO authenticated
  USING (
    public.auth_is_admin()
    OR (user_id = auth.uid() AND is_deleted = false)
  );

-- ----------------------------------------------------------------------------
-- certificates (catálogo de TIPOS de certificado) também só tinha adm_select
-- (is_admin = true). A view pilot_certificates_view é security_invoker e faz
-- JOIN em certificates, então mesmo com a policy acima o piloto recebia 0
-- linhas: o JOIN com o catálogo era barrado e zerava o resultado. O catálogo é
-- dado de referência não-sensível (apenas nomes de tipo) — liberar leitura a
-- qualquer autenticado. Escrita continua restrita às policies adm_* existentes.
-- ----------------------------------------------------------------------------

ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS certificates_read_all_authenticated ON public.certificates;
CREATE POLICY certificates_read_all_authenticated ON public.certificates
  FOR SELECT TO authenticated
  USING (true);
