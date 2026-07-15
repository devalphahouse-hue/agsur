-- ============================================================================
-- CHAT INTERNO DO PAINEL (Sprint 1 — Demanda 2)
-- ============================================================================
-- Chat 1:1 (DM) entre usuários do PAINEL ADMINISTRATIVO apenas:
-- profile_type ∈ {'Admin Master','Admin','Vendedor'} (ou is_admin = true).
-- Perfis Cliente/Piloto/Oficina NÃO participam (fora de escopo).
--
-- Modelo:
--   chat_threads        uma conversa (DM entre 2 usuários do painel)
--   chat_participants    (thread, user) — membros da conversa + last_read_at
--   chat_messages        mensagens de texto e/ou anexo (PDF/imagem)
--
-- Acesso:
--   - Helper chat_is_member(thread) SECURITY DEFINER (evita recursão de RLS:
--     a policy de chat_messages consulta participants sem reativar RLS).
--   - RLS: só vê/escreve em thread onde participa E é seller/admin.
--   - Criação de thread/participantes só via RPC chat_get_or_create_dm()
--     (SECURITY DEFINER) — INSERT direto nessas duas tabelas fica negado.
--   - Anexos: bucket privado 'chat-attachments' (image/* + application/pdf),
--     policies de storage amarradas à participação na thread (pasta = thread_id).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Tabelas
-- ---------------------------------------------------------------------------
create table if not exists public.chat_threads (
  id              uuid primary key default gen_random_uuid(),
  created_by      uuid references public.users(id) on delete set null,
  created_at      timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);
comment on table public.chat_threads is
  'Conversa (DM 1:1) entre usuários do painel. Criada via RPC chat_get_or_create_dm.';

create table if not exists public.chat_participants (
  thread_id    uuid not null references public.chat_threads(id) on delete cascade,
  user_id      uuid not null references public.users(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  primary key (thread_id, user_id)
);
comment on table public.chat_participants is
  'Membros de uma conversa do painel. Em DM 1:1 há exatamente 2 linhas por thread.';
create index if not exists idx_chat_participants_user on public.chat_participants(user_id);

create table if not exists public.chat_messages (
  id              uuid primary key default gen_random_uuid(),
  thread_id       uuid not null references public.chat_threads(id) on delete cascade,
  sender_id       uuid not null references public.users(id) on delete set null,
  body            text,
  attachment_url  text,
  attachment_name text,
  attachment_kind text check (attachment_kind in ('image','pdf')),
  created_at      timestamptz not null default now(),
  -- Mensagem precisa ter texto OU anexo (não pode ser vazia).
  constraint chat_messages_has_content check (
    (body is not null and length(btrim(body)) > 0) or attachment_url is not null
  ),
  -- Se tem anexo, precisa do tipo; se tem tipo, precisa da url.
  constraint chat_messages_attachment_consistent check (
    (attachment_url is null and attachment_kind is null)
    or (attachment_url is not null and attachment_kind is not null)
  )
);
comment on table public.chat_messages is
  'Mensagens do chat do painel (texto e/ou anexo PDF/imagem). Append-only via RLS.';
create index if not exists idx_chat_messages_thread_created
  on public.chat_messages(thread_id, created_at);

-- ---------------------------------------------------------------------------
-- 2) Helper de membership (SECURITY DEFINER — quebra recursão de RLS)
-- ---------------------------------------------------------------------------
create or replace function public.chat_is_member(p_thread_id uuid)
 returns boolean
 language sql
 stable
 security definer
 set search_path = public
as $$
  select exists (
    select 1
      from public.chat_participants p
     where p.thread_id = p_thread_id
       and p.user_id = auth.uid()
  );
$$;
comment on function public.chat_is_member(uuid) is
  'True se o caller participa da conversa. SECURITY DEFINER p/ evitar recursão de RLS.';
revoke all on function public.chat_is_member(uuid) from public;
grant execute on function public.chat_is_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3) RLS
-- ---------------------------------------------------------------------------
alter table public.chat_threads      enable row level security;
alter table public.chat_participants enable row level security;
alter table public.chat_messages     enable row level security;

-- Defense-in-depth: nenhum fluxo público. anon nunca lê/escreve chat.
revoke all on public.chat_threads      from anon;
revoke all on public.chat_participants from anon;
revoke all on public.chat_messages     from anon;

-- chat_threads: lê quem participa. Sem INSERT/UPDATE/DELETE direto
-- (threads nascem só pela RPC SECURITY DEFINER).
drop policy if exists chat_threads_select on public.chat_threads;
create policy chat_threads_select on public.chat_threads
  for select to authenticated
  using (public.chat_is_member(id));

-- chat_participants: lê quem participa da mesma thread (enxerga o co-membro).
-- UPDATE só na própria linha (marcar lido). Sem INSERT/DELETE direto.
drop policy if exists chat_participants_select on public.chat_participants;
create policy chat_participants_select on public.chat_participants
  for select to authenticated
  using (public.chat_is_member(thread_id));

drop policy if exists chat_participants_update_own on public.chat_participants;
create policy chat_participants_update_own on public.chat_participants
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- chat_messages: lê quem participa; insere quem participa, é seller/admin e
-- assina como si mesmo. Append-only (sem UPDATE/DELETE).
drop policy if exists chat_messages_select on public.chat_messages;
create policy chat_messages_select on public.chat_messages
  for select to authenticated
  using (public.chat_is_member(thread_id));

drop policy if exists chat_messages_insert on public.chat_messages;
create policy chat_messages_insert on public.chat_messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.auth_is_seller_or_admin()
    and public.chat_is_member(thread_id)
  );

-- ---------------------------------------------------------------------------
-- 4) RPC: cria (ou reaproveita) a DM 1:1 entre o caller e outro usuário
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER: insere thread+participants sem depender de policy de
-- INSERT. Valida que AMBOS são usuários do painel (seller/admin) e que não é
-- conversa consigo mesmo. Idempotente: devolve a thread existente se já houver
-- uma DM com exatamente esses 2 participantes.
create or replace function public.chat_get_or_create_dm(p_other_user uuid)
 returns uuid
 language plpgsql
 security definer
 set search_path = public
as $$
declare
  v_me        uuid := auth.uid();
  v_thread_id uuid;
begin
  if v_me is null then
    raise exception 'chat: sem sessão' using errcode = '42501';
  end if;
  if p_other_user is null or p_other_user = v_me then
    raise exception 'chat: destinatário inválido' using errcode = '22023';
  end if;

  -- Só usuários do painel (Admin Master/Admin/Vendedor) podem conversar.
  if not public.auth_is_seller_or_admin() then
    raise exception 'chat: apenas usuários do painel' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.users u
     where u.id = p_other_user
       and (u.profile_type in ('Admin Master'::profile_types, 'Admin'::profile_types, 'Vendedor'::profile_types)
            or u.is_admin = true)
       and coalesce(u.is_deleted, false) = false
  ) then
    raise exception 'chat: destinatário não é usuário do painel' using errcode = '42501';
  end if;

  -- Já existe uma DM com exatamente esses 2 participantes?
  select p1.thread_id into v_thread_id
    from public.chat_participants p1
    join public.chat_participants p2
      on p2.thread_id = p1.thread_id
   where p1.user_id = v_me
     and p2.user_id = p_other_user
     and (select count(*) from public.chat_participants p3
           where p3.thread_id = p1.thread_id) = 2
   limit 1;

  if v_thread_id is not null then
    return v_thread_id;
  end if;

  insert into public.chat_threads (created_by) values (v_me)
    returning id into v_thread_id;
  insert into public.chat_participants (thread_id, user_id)
    values (v_thread_id, v_me), (v_thread_id, p_other_user);

  return v_thread_id;
end;
$$;
comment on function public.chat_get_or_create_dm(uuid) is
  'Cria ou reaproveita a DM 1:1 entre o caller e p_other_user (ambos do painel).';
revoke all on function public.chat_get_or_create_dm(uuid) from public;
grant execute on function public.chat_get_or_create_dm(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5) Trigger: bump last_message_at na thread a cada mensagem nova
-- ---------------------------------------------------------------------------
create or replace function public.tg_chat_bump_thread()
 returns trigger
 language plpgsql
 security definer
 set search_path = public
as $$
begin
  update public.chat_threads
     set last_message_at = NEW.created_at
   where id = NEW.thread_id;
  return NEW;
end;
$$;

revoke all on function public.tg_chat_bump_thread() from public;

drop trigger if exists chat_bump_thread on public.chat_messages;
create trigger chat_bump_thread
  after insert on public.chat_messages
  for each row execute function public.tg_chat_bump_thread();

-- ---------------------------------------------------------------------------
-- 6) View: conversas do caller com o "outro" participante e prévia
-- ---------------------------------------------------------------------------
-- security_invoker: roda com a RLS do caller (só enxerga as próprias threads).
create or replace view public.vw_chat_my_threads
  with (security_invoker = on)
as
  select
    t.id                                  as thread_id,
    t.last_message_at                     as last_message_at,
    other.user_id                         as other_user_id,
    ou.name                               as other_name,
    ou.lastname                           as other_lastname,
    ou.profile_type                       as other_profile_type,
    me.last_read_at                       as my_last_read_at,
    (select m.body from public.chat_messages m
       where m.thread_id = t.id order by m.created_at desc limit 1) as last_body,
    (select m.attachment_kind from public.chat_messages m
       where m.thread_id = t.id order by m.created_at desc limit 1) as last_attachment_kind,
    (select count(*) from public.chat_messages m
       where m.thread_id = t.id
         and m.created_at > me.last_read_at
         and m.sender_id <> auth.uid())   as unread_count
  from public.chat_threads t
  join public.chat_participants me
    on me.thread_id = t.id and me.user_id = auth.uid()
  join public.chat_participants other
    on other.thread_id = t.id and other.user_id <> auth.uid()
  join public.users ou on ou.id = other.user_id;

comment on view public.vw_chat_my_threads is
  'Conversas do caller (DM 1:1) com o outro participante, prévia e não-lidas. security_invoker.';
revoke all on public.vw_chat_my_threads from anon;
grant select on public.vw_chat_my_threads to authenticated;

-- ---------------------------------------------------------------------------
-- 7) Realtime
-- ---------------------------------------------------------------------------
-- Mensagens e marcação de leitura precisam chegar ao vivo.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.chat_messages;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.chat_participants;
    exception when duplicate_object then null;
    end;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 8) Bucket privado de anexos + policies de storage por membership
-- ---------------------------------------------------------------------------
-- Caminho do objeto: '<thread_id>/<uuid>.<ext>'  → foldername[1] = thread_id.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-attachments', 'chat-attachments', false, 20971520,  -- 20 MB
  array['image/jpeg','image/png','image/gif','image/webp','image/heic','application/pdf']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Leitura (signed URL): só membros da thread (pasta = thread_id) que sejam painel.
drop policy if exists chat_attachments_select on storage.objects;
create policy chat_attachments_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'chat-attachments'
    and public.auth_is_seller_or_admin()
    and public.chat_is_member(((storage.foldername(name))[1])::uuid)
  );

-- Upload: idem (membro + painel).
drop policy if exists chat_attachments_insert on storage.objects;
create policy chat_attachments_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and public.auth_is_seller_or_admin()
    and public.chat_is_member(((storage.foldername(name))[1])::uuid)
  );
