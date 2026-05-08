# Supabase — Migrations versionadas (Agsur)

Antes deste setup, o DDL do projeto Supabase `bkzybtmxxzpxtztesdye` vivia
exclusivamente no Studio remoto (sem histórico, sem code review, sem
rollback). A pasta `supabase/migrations/` passa a ser a **fonte da verdade
para mudanças de schema, RLS, triggers e RPCs**.

## Setup local

```powershell
# Token de acesso (memória do Claude OU pessoal). Não commitar.
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."

# CLI (já instalado via npx)
npx -y supabase@latest link --project-ref bkzybtmxxzpxtztesdye
```

`config.toml` está com `major_version = 15` para bater com a versão remota
do Postgres (15.8).

## Workflow

### Aplicar migrations

```powershell
# Dry-run vs remoto
npx -y supabase@latest db push --dry-run

# Aplicar
npx -y supabase@latest db push
```

> **Atenção:** sem Docker local não é possível usar `supabase db diff` ou
> shadow database. Para esses fluxos, instale o Docker Desktop.

### Criar nova migration

```powershell
npx -y supabase@latest migration new <slug>
# edita o arquivo gerado em supabase/migrations/
```

Convenção de nomes: timestamp YYYYMMDDHHMMSS + slug em snake_case.

## Histórico (08/05/2026 — endurecimento de segurança)

| Versão | Migration | O que faz |
|---|---|---|
| 20260508120000 | `security_helpers` | Helpers SECURITY DEFINER: `auth_is_admin_master`, `auth_is_admin`, `auth_is_seller_or_admin`, `auth_is_service_role` |
| 20260508120100 | `users_table_hardening` | Trigger BEFORE INSERT/UPDATE/DELETE em `public.users`: bloqueia escalation de `profile_type`/`is_admin` por não-Admin Master |
| 20260508120200 | `operational_tables_hardening` | Triggers em 13 tabelas operacionais (proposal, contract, tracking, financial, sales, etc.) — só Vendedor/Admin escreve |
| 20260508120300 | `more_admin_tables` | Mais 5 tabelas administrativas + bloqueio total de writes em `internal_logs` exceto service_role |
| 20260508120400 | `ownership_tables_hardening` | Regras por dono: `address.created_by`, `guarantee.user_id`, `pilot_certificates.user_id`, `order_parts.user_id`, `requested_parts.order_id` |
| 20260508120500 | `storage_hardening` | `file_size_limit` + `allowed_mime_types` em `AGSur` e `pdfs` |
| 20260508120600 | `drop_all_access_phase1` | Drop `all_access` em `users`, `financial`, `financing_rates`, `sales`, `company` + policies específicas |
| 20260508120700 | `fix_escalated_user` | Reset `is_admin=false` em Cliente que tinha escalation passada |
| 20260508120800 | `phase3_helpers` | Helpers SECURITY DEFINER de ownership: `auth_user_email`, `auth_owns_user_aircraft`, `auth_owns_proposal`, `auth_owns_contract`, `auth_is_linked_to_client` |
| 20260508120900 | `drop_all_access_phase3` | Drop `all_access` nas 19 tabelas operacionais restantes; SELECT por ownership chain quando aplicável |
| 20260508121000 | `pdfs_bucket_private` | Bucket `pdfs` virou privado (não está em uso pelo código) |
| 20260508121100 | `security_audit_log` | Tabela append-only `security_audit_log` + triggers AFTER em `users` (campos privilegiados), `financial`, `financing_rates`, `sales`, `company`. Read = Admin Master only |
| 20260508121200 | `soft_delete_protection` | Trigger BEFORE UPDATE bloqueando edição de rows com `is_deleted=true` (exceto Admin Master) em `certificates`, `leads`, `pilot_certificates`, `proposal`, `service_letter`, `services_offering` |
| 20260508121300 | `rls_perf_indexes` | 14 índices em FKs usadas pelos helpers de ownership (proposal.lead_id, user_aircraft.proposal_id, tracking.user_aircraft, leads(lower(email)), etc.) |
| 20260508121400 | `mfa_enforcement_hook` | Função `public.custom_access_token_hook(jsonb)` que rejeita JWT para Admin Master sem `aal2`. Ativar em **Auth → Hooks** (ver `DASHBOARD_TIER2_TODO.md`) |

### Smoke test (08/05/2026)

Após FASE 3, anon GETs em `users`, `proposal`, `financial`, `tracking`, `aircrafts`,
`company` → todos retornam `[]` (RLS bloqueia). INSERT em `users` com `profile_type=Admin Master`
→ retorna `42501: new row violates row-level security policy for table "users"`. RPC
`check_app_access` (SECURITY DEFINER) continua funcionando para anon, como esperado.

### Estado pendente

- **Auth config (manual via dashboard)** — token CLI continua sem permissão de
  escrita em `/v1/projects/{ref}/config/auth` (HTTP 403 confirmado em 2026-05-08).
  Os valores abaixo já estão versionados em `config.toml` + `templates/recovery.html`
  mas precisam ser **copiados manualmente** no Studio. Quando um token com permissão
  de auth admin estiver disponível, basta `npx supabase config push`.

  **Authentication → URL Configuration:**
  - Site URL: `https://painel-agsur.vercel.app`
  - Redirect URLs (allow list): `https://painel-agsur.vercel.app/**`,
    `agsurclientapp://agsurclientapp.com/**`

  **Authentication → Email Templates → Reset Password:**
  - Subject: `Redefinir sua senha · Agsur`
  - Message body: cole o conteúdo de `supabase/templates/recovery.html`.

  **Outras mudanças recomendadas (não bloqueantes):**
  - `security_update_password_require_reauthentication = true`

  > Sem aplicar essas mudanças, o link do email continua caindo em
  > `http://localhost:3000` (site_url default) — quebrado em produção. As edições
  > Dart já passam `redirectTo` explícito, mas Supabase rejeita o `redirect_to` se a
  > URL não estiver no allow list e cai pro `site_url`, então a etapa manual é o que
  > destrava o fluxo.

- **Página "definir nova senha" não existe ainda** — após clicar no link, Supabase
  redireciona pro `redirectTo` com hash `#access_token=...&type=recovery`. Hoje, no
  painel, a rota `/resetPassword` é só o formulário pra **solicitar** o reset; ela
  não consome o token. Próximo passo (não incluído neste setup): adicionar listener
  em `onAuthStateChange` pra evento `AuthChangeEvent.passwordRecovery` e renderizar
  UI de "nova senha" no mesmo widget. Idem para o agsur-app.

- **Auditoria de PRs futuros** — a tabela `tracking_details` é grande (90+ colunas).
  Confirmar com o time se cliente realmente lê tracking_details direto pelo agsur-app
  ou se sempre vai via view `vw_my_aircraft_details` (que filtra no SQL). Se sempre via
  view, a policy atual está correta; se há SELECT direto, a EXISTS-via-tracking pode
  custar caro com volume.

## Notas de segurança

- `triggers` BEFORE rodam **independente de RLS**. Mesmo que uma policy
  permissiva libere a operação, a trigger ainda pode rejeitar.
- Helpers (`auth_is_*`) são SECURITY DEFINER e bypass RLS quando consultam
  `public.users`. Não chame essas funções com input do usuário sem validar.
- `key.properties` (Android) e `SUPABASE_ACCESS_TOKEN` (CLI) **nunca** vão
  pro git. Estão em `.gitignore` / memória do Claude respectivamente.
