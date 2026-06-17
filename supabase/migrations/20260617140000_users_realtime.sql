-- ============================================================================
-- Realtime na tabela public.users
-- ============================================================================
-- O app cliente assina mudanças da PRÓPRIA linha em `users` para "cair na hora"
-- quando o painel desativa (is_active=false) ou exclui (is_deleted=true) a
-- conta com a sessão aberta. Para os eventos chegarem, a tabela precisa estar
-- na publication `supabase_realtime`.
--
-- A RLS de SELECT de users (`id = auth.uid() OR auth_is_seller_or_admin()`) já
-- limita o que cada cliente recebe à própria linha — o Realtime respeita RLS,
-- então ninguém vê mudanças de outros usuários. Não exige policy nova.
--
-- Idempotente: só adiciona se ainda não for membro da publication.
-- ============================================================================

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1
        from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'users'
    ) then
      alter publication supabase_realtime add table public.users;
    end if;
  end if;
end
$$;
