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

## Histórico (10/06/2026 — RLS de leitura faltando no app cliente)

Bug reportado: certificado de piloto cadastrado no painel não aparecia em "Meus
certificados" no `agsur-app`. Causa: a view `pilot_certificates_view` é
`security_invoker=on` e o piloto não tinha policy de SELECT. Auditoria do mesmo
padrão (RLS ligado, só `adm_*`/admin, sem caminho pro dono/vínculo) encontrou
mais um caso (garantia de cliente vinculado ao **Piloto**).

| Versão | Migration | O que faz |
|---|---|---|
| 20260610120000 | `pilot_certificates_owner_select` | SELECT do dono em `pilot_certificates` (`user_id = auth.uid() AND NOT is_deleted`, ou admin) **+** SELECT do catálogo `certificates` para qualquer autenticado (a view faz JOIN em `certificates`; sem isso o JOIN zerava o resultado mesmo com a 1ª policy). Provado: leitura via view no contexto do piloto agora retorna o certificado |
| 20260610120100 | `guarantee_pilot_linked_select` | SELECT em `guarantee` via `auth_is_linked_to_client(user_id)` (cobre Oficina **e** Piloto). Antes só existia o caminho de Oficina (`oficina_clients`); Piloto vinculado via `pilot_clients` recebia 0 linhas das garantias dos clientes, igual ao `service_letter` já fazia |
| 20260610120200 | `tracking_linked_client_select` | Helper SECURITY DEFINER `auth_is_linked_to_user_aircraft(uuid)` (resolve `user_aircraft → contract."user_Id"` + `auth_is_linked_to_client`, cobre Oficina e Piloto) + SELECT em `tracking` por vínculo. Antes `tracking_select` usava só `auth_owns_user_aircraft()` (email do dono), então Oficina/Piloto abria o "Acompanhar" de cliente vinculado e via a timeline **vazia**. Provado: piloto 82332883 (vinculado ao cliente 24564eae, aeronave 2c4bec1e) ia de 0 → 21 trackings; aeronave de cliente não vinculado continua 0 |

> Aplicadas direto via Management API (token CLI) e registradas em
> `supabase_migrations.schema_migrations`. Os arquivos `.sql` estão versionados;
> commitar + abrir PR para manter o git como fonte da verdade e o
> `supabase-db-check` consistente.

### Candidatos NÃO alterados (confirmar intenção de produto antes)

- **`tracking_details` / `user_aircraft` para Oficina/Piloto vinculado.** O
  SELECT depende de `auth_owns_user_aircraft()` (email do dono), que não cobre
  cliente vinculado. **Não há bug ativo:** hoje o agsur-app lê `user_aircraft` e
  os detalhes só via views SECURITY DEFINER (`vw_my_aircraft*`, que ignoram RLS)
  e `tracking_details` não é lido direto. Se algum fluxo passar a ler essas
  tabelas direto sob RLS, aplicar o mesmo padrão de `tracking` (o helper
  `auth_is_linked_to_user_aircraft(uuid)` já existe — basta uma policy
  permissiva). A timeline em si (`tracking`) já foi corrigida em
  `20260610120200`.
- **`vw_my_aircrafts_home` e `vw_my_aircraft_details` são SECURITY DEFINER**
  (`security_invoker` desligado) → **ignoram RLS** das tabelas-base. Hoje
  funcionam só porque o app filtra `user_id` na query, mas via PostgREST qualquer
  autenticado pode consultar com `user_id` de terceiros (risco de IDOR). Mexer
  é sensível: ligar `security_invoker` quebraria a leitura de aeronaves de
  clientes vinculados (a RLS de `user_aircraft` é email-do-dono). Decisão de
  design pendente.

## Histórico (22/06/2026 — QA: liberação de e-mail na exclusão + rollback)

Aplicada via Management API (token do CLI) — **idempotente** (`create or replace`),
só redefine funções, não altera dados. Reconcilia no histórico quando o PR for
mergeado e o CI rodar `db push`.

| Versão | Migration | O que faz |
|---|---|---|
| 20260622120000 | `release_email_on_delete_and_orphan_purge` | `admin_delete_app_user` passa a **liberar o e-mail** na exclusão (renomeia para tombstone `deleted+<id>@deleted.agsur.local` em `public.users`, `auth.users` e best-effort `auth.identities`), além do soft-delete+ban já existentes; aceita também `Vendedor`/`Colaborador`. Nova função `admin_purge_orphan_auth_user(email)`: remove conta de auth **órfã** (sem linha em `public.users`) — usada como rollback no cadastro de cliente quando o signup cria a conta mas o insert local falha. |

> Front correspondente: deletes de Vendedor/Colaborador passaram a chamar a RPC
> (antes era UPDATE direto, sem ban e sem liberar e-mail). **Mudança de
> comportamento:** excluir Vendedor/Colaborador agora exige Admin Master.

## Histórico (22/06/2026 — segurança: fecha exposição sem login)

| Versão | Migration | O que faz |
|---|---|---|
| 20260622130000 | `revoke_anon_views_and_fix_is_adm` | Revoga **todo** privilégio de `anon` em todas as views de `public` (elas são SECURITY DEFINER e bypassavam RLS → PII/financeiro era legível **sem login** com a anon key). Fixa `is_adm(uuid)` com `set search_path = public`. Verificado: `anon` em views = 0. |
| 20260622140000 | `views_security_invoker_panel` | Liga `security_invoker=on` em `vw_get_clients`, `vw_get_pilots`, `vw_contract_data`, `vw_notes_details`, `vw_all_tracking` → passam a respeitar a RLS das tabelas-base (fecha IDOR autenticado; Admin/Vendedor leem via `auth_is_seller_or_admin`, Cliente/Piloto só o próprio). **Excluídas:** `vw_homepage_dashboard` (agrega financial/sales admin-only — decisão de produto) e `vw_my_aircraft*` (app cliente, RLS por e-mail). **Validar painel (Admin+Vendedor)**; rollback `set (security_invoker=off)`. Pendente: buckets privados + signed URLs. Ver `SECURITY_AUDIT.md`. |
| 20260622150000 | `dashboard_security_invoker` | Liga `security_invoker=on` em `vw_homepage_dashboard` (agregava `financial`/`sales` admin-only → vazava p/ qualquer autenticado). Seguro: getters do Row nullable + UI gateia financeiro por isAdminMaster. Validar dashboard Admin Master (completo) e Vendedor (sem quebrar). |
| 20260622160000 | `company_select_restrict` | `company` tinha SELECT `true` (qualquer autenticado lia todas as empresas: nome/cnpj/cpf/telefone/email). Restringe a `auth_is_seller_or_admin()`. Seguro: app cliente não usa company; `vw_my_aircraft*` não junta company. |

## Notas de segurança

- `triggers` BEFORE rodam **independente de RLS**. Mesmo que uma policy
  permissiva libere a operação, a trigger ainda pode rejeitar.
- Helpers (`auth_is_*`) são SECURITY DEFINER e bypass RLS quando consultam
  `public.users`. Não chame essas funções com input do usuário sem validar.
- `key.properties` (Android) e `SUPABASE_ACCESS_TOKEN` (CLI) **nunca** vão
  pro git. Estão em `.gitignore` / memória do Claude respectivamente.
