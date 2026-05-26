-- ============================================================================
-- Corrige cadastro de usuários pelo Admin Master (painel).
--
-- PROBLEMA
-- A policy `user_security_insert` (criada em 20260508120600_drop_all_access_phase1)
-- usa `WITH CHECK (auth.uid() = id)`, ou seja, só permite self-insert. Isso
-- bloqueia o Admin Master de inserir linhas em public.users para OUTROS
-- usuários — quebrando os cadastros de Cliente, Piloto, Oficina, Vendedor e
-- Colaborador no painel, e também a criação do usuário Cliente durante a
-- conversão de proposta em contrato. O `.insert(...).select().single()` do
-- app então lança PostgrestException (parece que "não salvou" e o modal não
-- fecha).
--
-- Isso é INCOERENTE com a trigger `tg_users_block_privilege_escalation`
-- (20260508120100_users_table_hardening), que JÁ permite o Admin Master criar
-- usuários para terceiros (TG_OP=INSERT, is_master => RETURN NEW) e restringe
-- os demais a self-signup de Cliente/Piloto/Oficina, sem is_admin.
--
-- CORREÇÃO
-- Alinhar a RLS à trigger: permitir INSERT quando for self-insert OU quando o
-- caller for Admin Master. A trigger continua como defesa em camadas
-- (escalation de profile_type / is_admin / criação por não-master).
--
-- Nota: regular Admin e Vendedor continuam SEM poder criar usuários de
-- terceiros (tanto pela policy quanto pela trigger). Se o negócio exigir que
-- eles também criem usuários, será preciso ajustar ESTA policy e a trigger
-- juntas, numa migration própria.
-- ============================================================================

DROP POLICY IF EXISTS user_security_insert ON public.users;
CREATE POLICY user_security_insert
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = id
    OR public.auth_is_admin_master()
  );
