---
name: db-migration-security-review
description: >-
  Gate de segurança para migrations novas do Supabase (Agsur). Use ANTES de
  aplicar/abrir PR de qualquer arquivo novo em supabase/migrations/ — ou ao criar
  tabela, view, função ou bucket. Garante que a mudança não abra exposição a
  `anon`, IDOR por view definer, escalonamento por search_path, ou tabela sem RLS.
---

# Revisão de segurança de migration (pré-merge)

As brechas de exposição do Agsur entraram por **defaults inseguros** de objetos
novos (view sem `security_invoker`, grants herdados para `anon`, função
SECURITY DEFINER sem `search_path`). Este gate impede a reincidência.

Aplique a cada migration nova (diff em `supabase/migrations/`):

## Checklist obrigatório

1. **Tabela nova → RLS + revogar `anon`.**
   - `alter table <t> enable row level security;` + policies explícitas.
   - `revoke all on <t> from anon;` (a menos que haja fluxo público deliberado e documentado).
   - Confirme que há policy de cada operação que o app realmente usa (sem `using(true)` largo).

2. **View nova → `security_invoker` + grants mínimos.**
   - `alter view <v> set (security_invoker = on);` para a view respeitar a RLS das
     tabelas-base (evita IDOR). Se precisar rodar como definer por algum motivo,
     justifique e garanta filtro de dono interno.
   - `revoke all on <v> from anon;` e conceda **só** `select` a `authenticated`
     (nunca INSERT/UPDATE/DELETE/TRUNCATE numa view de leitura).

3. **Função SECURITY DEFINER → `search_path` fixo + checagem de perfil + grants.**
   - `... security definer set search_path = public, auth` (sempre).
   - Cheque o perfil do chamador no corpo (`auth_is_admin_master()` etc.).
   - `revoke all on function ... from public;` e `grant execute ... to authenticated;`
     (ou role específico). Não deixe `public`/`anon` executar função privilegiada.
   - Valide input do usuário; nunca interpole em SQL dinâmico sem necessidade.

4. **Bucket de Storage novo → privado por padrão.**
   - `public = false` salvo se for asset realmente público. Dado sensível
     (documentos, PII) → privado + signed URLs no app. Defina `file_size_limit`
     e `allowed_mime_types`.

5. **Mudança em campo privilegiado** (`users.profile_type/is_admin`, `financial`,
   `financing_rates`, `sales`, `company`) → confirme que continua coberta por
   trigger BEFORE + audit log.

6. **Idempotência e reversibilidade.** Prefira `create or replace` / `if not exists`;
   descreva como reverter. Rode `npx supabase db push --dry-run`.

## Saída

Para cada item: ✅ ok / ⚠️ ajustar (com o SQL exato a adicionar) / ➖ n/a.
Bloqueie o merge enquanto houver item de exposição a `anon`, view definer sem
justificativa, ou função definer sem `search_path`. Toda DDL vai por PR/CI
(`supabase-db-check`, `rls-smoke`).
