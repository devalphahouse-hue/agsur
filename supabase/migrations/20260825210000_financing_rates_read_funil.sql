-- =============================================================================
-- financing_rates: separa LEITURA de ESCRITA
-- =============================================================================
-- Sintoma: PDF de proposta saindo com "TAXA DE JUROS 0.0000%", "TAXA DE SOFR
-- 0.0000%" e juros $ 0.00 em todas as parcelas, com o premium correto (7%).
--
-- Causa: `create_proposal` lê `financing_rates` para gravar sofr_rate e
-- interest_rate em `proposal_financing`. A política `admin_only`
-- (20260508120600) é FOR ALL USING auth_is_admin(), e Vendedor NÃO é admin —
-- então a leitura volta VAZIA em vez de dar erro, e o insert gravava 0.0.
-- O premium não zerava porque é calculado no cliente a partir do prazo.
--
-- Correção: Vendedor passa a LER as taxas (dado que ele já vê no PDF que emite);
-- INSERT/UPDATE/DELETE continuam restritos a admin, e o trigger
-- `hardening_require_documentacao` (20260701171000) segue exigindo
-- Admin Master / Admin documentação para escrever. Nenhum perfil de app cliente
-- é alcançado — a política é TO authenticated com predicado de perfil de painel.
-- =============================================================================

DROP POLICY IF EXISTS admin_only ON public.financing_rates;
DROP POLICY IF EXISTS financing_rates_read_painel ON public.financing_rates;
DROP POLICY IF EXISTS financing_rates_write_admin ON public.financing_rates;

-- Leitura: admin (master/admin/is_admin) + vendedor.
CREATE POLICY financing_rates_read_painel
  ON public.financing_rates
  FOR SELECT
  TO authenticated
  USING (public.auth_is_admin() OR public.auth_is_vendedor());

-- Escrita: só admin (o trigger ainda aperta para documentação/master).
CREATE POLICY financing_rates_write_admin
  ON public.financing_rates
  FOR INSERT
  TO authenticated
  WITH CHECK (public.auth_is_admin());

CREATE POLICY financing_rates_update_admin
  ON public.financing_rates
  FOR UPDATE
  TO authenticated
  USING (public.auth_is_admin())
  WITH CHECK (public.auth_is_admin());

CREATE POLICY financing_rates_delete_admin
  ON public.financing_rates
  FOR DELETE
  TO authenticated
  USING (public.auth_is_admin());

COMMENT ON TABLE public.financing_rates IS
  'Taxas vigentes de financiamento (linha única ce659e4b-caee-4b88-8d99-46f15c7e9b69). '
  'Leitura: admin + vendedor (o vendedor precisa das taxas para gravar proposal_financing). '
  'Escrita: admin, com trigger exigindo documentação/master.';
