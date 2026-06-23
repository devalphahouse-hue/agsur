# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este repo

**`agsur` — painel administrativo Agsur** (Flutter web, deploy Vercel em
`painel-agsur.vercel.app`). Gerencia leads, vendedores, propostas, contratos,
oficina, esteira de importação ("tracking"), funcionários, taxas de
financiamento.

Este repo também contém:

- `supabase/` — schema versionado (migrations, RPCs, RLS) **compartilhado
  com o agsur-app** (cliente final). DDL é fonte da verdade pra ambos.
- `.github/workflows/` — CI: `flutter-analyze`, `supabase-db-check`, `rls-smoke`.
- `RUNBOOK.md`, `SECURITY.md`, `supabase/DASHBOARD_TIER2_TODO.md` — operação.

**`agsur-app` mora em repo separado:** `https://github.com/devalphahouse-hue/agsur-app`.

## Stack

Flutter + FlutterFlow gerado. Tem `lib/flutter_flow/`, `FFAppState`, `FlutterFlowTheme`,
`createRouter`. Tratar `lib/flutter_flow/` e `lib/backend/supabase/database/` como
código gerado: uma regeneração pelo FlutterFlow sobrescreve edições manuais.

**Atenção:** `lib/pages/authentication/login/login_widget.dart` foi endurecido
manualmente (gate via RPC `check_app_access`, MFA enforcement opt-in,
`setSentryUser`). Uma regen do FlutterFlow vai apagar esses ganchos. Revalidar
antes de subir.

## Comandos comuns

```powershell
flutter pub get
flutter analyze
flutter test                                 # todos
flutter test test/jwt_utils_test.dart        # arquivo único

flutter run -d chrome                        # web
flutter build web --release                  # antes de deploy Vercel
```

### Build de produção (com Sentry e env vars)

```powershell
$env:SENTRY_DSN = "https://...@sentry.io/..."
$env:SUPABASE_URL = "https://bkzybtmxxzpxtztesdye.supabase.co"
$env:SUPABASE_ANON_KEY = "eyJ..."

flutter build web --release `
  --dart-define=SENTRY_DSN=$env:SENTRY_DSN `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
  --dart-define=APP_ENV=production `
  --dart-define=APP_RELEASE=agsur-painel@$(git rev-parse --short HEAD)

# Para forçar MFA em Admin Master (depois que TODOS cadastrarem TOTP):
#   --dart-define=ENFORCE_MFA_ADMIN_MASTER=true
```

`vercel.json` aponta `outputDirectory: build/web` com fallback SPA. O
`buildCommand` é `null`, então o `flutter build web` precisa rodar **antes**
do deploy (manualmente ou via script). Vercel apenas serve o resultado.

### Workflow de schema (Supabase)

```powershell
$env:SUPABASE_ACCESS_TOKEN = "<token de https://supabase.com/dashboard/account/tokens>"
npx -y supabase@latest link --project-ref bkzybtmxxzpxtztesdye

npx supabase migration new <slug>
# editar supabase/migrations/YYYYMMDDHHMMSS_<slug>.sql

npx supabase db push --dry-run   # validar
npx supabase db push             # aplicar
```

**Toda mudança de schema/RLS via PR.** CI valida com `supabase-db-check.yml`
(dry-run) e `rls-smoke.yml` (smoke daily anon). DDL fora do PR vira drift e
o smoke detecta.

## Arquitetura

### Backend Supabase

Toda persistência e auth vão direto ao Supabase via `supabase_flutter`. Não há
camada de API própria além de algumas chamadas REST diretas em
`lib/backend/api_requests/api_calls.dart` (ex.: `signup` chamando `/auth/v1/signup`
para criar usuários sem deslogar o admin; `ViaCepCall` para autofill de CEP).

**Criar/excluir usuário (armadilhas).** O signup (`/auth/v1/signup`, anon) cria a
conta no auth e o painel insere a linha em `public.users` em seguida. Para
**e-mail duplicado**, o GoTrue responde de duas formas — **422
`user_already_exists`** OU um **200 "ofuscado" com `identities` vazio**
(anti-enumeração quando a confirmação de e-mail está ligada); os dois significam
"já existe" e inserir mesmo assim cria **conta órfã / fake access**. Trate ambos
ANTES de inserir e só insira com `user.id` válido (ver `modal_create_client`). Se
o insert local falhar após o auth criar, faça rollback via RPC
`admin_purge_orphan_auth_user`. **Exclusão** de usuário do app deve ir SEMPRE pela
RPC `admin_delete_app_user` (nunca UPDATE direto em `users`): ela faz soft-delete
+ ban + **libera o e-mail** para recadastro.

**Senha de novos usuários (política do servidor).** Desde o endurecimento de
2026-06-22 o GoTrue exige senha forte: **mínimo 8 caracteres + checagem HIBP
("pwned")**. O `pwned` só é verificável no servidor, então senha vazada (mesmo
com 8+) volta **422 `weak_password`** no signup. Para os formulários de criação
de usuário **nunca** validar com regra própria (`length < 6/8` espalhado) —
usar sempre `lib/security/password_utils.dart`: `strongPasswordValidator`
(8+ com letra e número, casa com a regra do servidor), `generateStrongPassword`
(16 chars `Random.secure`, nunca cai no `pwned`), `isWeakPasswordError(body)` e
`evaluatePasswordStrength`. A UI mostra `kPasswordRuleHint` como helper e o
medidor `PasswordStrengthMeter` (de `core_ui`) ao vivo. Padrão já aplicado em
`modal_register_pilot/seller/collab`, `modal_create_client`, `register_oficina`.
Ao tratar o erro do signup, mostre mensagem específica de senha fraca e **não
feche a modal** (preserva os campos) — ver `pages/users/pilot/pilots`.

- `lib/backend/supabase/supabase.dart` — `SupaFlow` com URL/anon key embarcadas
  como fallback. Em build de produção, valores são sobrescritos via
  `--dart-define`. Anon key é pública por design Supabase; segurança real
  depende de RLS.
- `lib/backend/supabase/database/tables/*.dart` — uma classe `SupabaseTable<Row>`
  por tabela/view, gerada pelo FlutterFlow. Helpers `queryRows / querySingleRow /
  insert / update / delete`.
- Tabelas `vw_*` são views Postgres (read-only) — usar para leituras agregadas.
- **RPCs com placeholder de texto (armadilha de UUID).** Algumas RPCs lidas pelo
  painel — ex.: `get_proposal_details` (chamada em `api_calls.dart`, **não
  versionada** em `supabase/migrations/`, criada via Studio = drift) — devolvem
  `"Não cadastrado"` no lugar de campos ausentes, **inclusive `aircraft_id`**.
  Esse texto não é UUID: filtrar `aircrafts`/`aircraft_items` por ele dá
  **Postgres 22P02** e deixa a tela em branco (já aconteceu em
  `view_contract` / `view_edit_proposal`). Antes de consultar por id, valide com
  regex de UUID e caia no fallback se inválido. **Pendência:** a mesma RPC tem um
  `42804` (coluna 10 declarada `uuid` mas retornando `text` por causa do
  `COALESCE(..., 'Não cadastrado')`) — corrigir na origem (manter `aircraft_id`
  `uuid`/`NULL`; o rótulo é problema de apresentação) via migration versionada.

### Schema versionado em `supabase/migrations/`

DDL agora vive **versionado no git** em `supabase/migrations/`. 35 migrations
aplicadas. O batch de endurecimento (2026-05-08 a 2026-05-26) cobre:

- **Defesa em camadas (triggers BEFORE):** 32 tabelas com triggers que
  rejeitam writes não autorizados independente de RLS.
- **Auth/RLS helpers SECURITY DEFINER:** `auth_is_admin_master()`,
  `auth_is_admin()`, `auth_is_seller_or_admin()`, `auth_is_service_role()`,
  `auth_user_email()`, `auth_owns_proposal(uuid)`, `auth_owns_user_aircraft(uuid)`,
  `auth_owns_contract(uuid)`, `auth_is_linked_to_client(uuid)`.
- **Audit log:** `public.security_audit_log` (append-only, read = Admin Master)
  registra mudanças em campos privilegiados de `users` + writes em `financial`,
  `financing_rates`, `sales`, `company`. Função `purge_security_audit_log()`
  para retenção.
- **Soft-delete protection:** trigger bloqueia UPDATE em rows com
  `is_deleted=true` (exceto Admin Master) em 6 tabelas.
- **MFA hook:** `public.custom_access_token_hook(jsonb)` rejeita JWT issue
  para Admin Master sem `aal=aal2`. **Pendente ativação no Studio**
  (Auth → Hooks). Defesa em camadas client-side já no painel.
- **Storage hardening:** buckets com `file_size_limit` + `allowed_mime_types`.

Lotes posteriores (fora do batch inicial):

- **RLS de leitura no app cliente (2026-06-10):** SELECT por dono em
  `pilot_certificates`/`certificates`, `guarantee` e `tracking` (o app cliente
  não enxergava esses dados).
- **Ciclo de vida de usuário (2026-06-17 e 06-22):** RPC
  `admin_delete_app_user(uuid)` (Admin Master) — soft-delete + ban no auth +
  **liberação do e-mail** (renomeia para tombstone
  `deleted+<id>@deleted.agsur.local` em `users`/`auth.users`/`auth.identities`),
  preservando contratos/propostas; cobre Cliente/Piloto/Oficina/Vendedor/Colaborador.
  RPC `admin_purge_orphan_auth_user(text)` — rollback de conta de auth órfã (sem
  linha em `public.users`). Também `app_login_precheck` e `users` em realtime.
- **Endurecimento de exposição (2026-06-22):** fechou leitura de dados **sem
  login** e **IDOR autenticado**. `revoke` de `anon` em todas as views;
  `security_invoker=on` nas views do painel + dashboard; predicado de autorização
  nas `vw_my_aircraft*` (definer, lidas pelo app cliente); `company` SELECT
  restrito a seller/admin; `is_adm` com `search_path`. Detalhe + o que validar:
  `SECURITY_AUDIT.md`.

Status atual completo + smoke tests em `supabase/README.md`. Pendências
manuais do dashboard em `supabase/DASHBOARD_TIER2_TODO.md`.

### ⚠️ Endurecimento de segurança 2026-06-22 — handoff (VALIDAR)

Várias mudanças foram aplicadas **direto em produção** via Management API (e
versionadas em `supabase/migrations/`). Registro vivo: `SECURITY_AUDIT.md`. Se
algo aparecer quebrado, comece por aqui.

- **Validar no painel** (logar como **Admin** e como **Vendedor**): listas de
  clientes, pilotos, contratos, tracking, notas e o dashboard carregam normal?
  (flips de `security_invoker`). Rollback de qualquer view:
  `alter view public.<v> set (security_invoker = off);`
- **Validar no app cliente** (**Cliente / Piloto / Oficina**): "minhas aeronaves"
  e os detalhes carregam? (predicado de authz nas `vw_my_aircraft*` —
  migration `..._my_aircraft_views_authz_predicate`). Se vier vazio, reverter
  removendo o predicado do `WHERE` das duas views.
- **Buckets / signed URLs:** leituras dos 2 apps já convertidas para
  `app_storage.dart` (fallback-safe). **NÃO** privar os buckets até a versão
  mobile com signed URLs estar **adotada** (quebra clientes antigos). Flip
  (reversível): `update storage.buckets set public=false where id in ('AGSur','service-letters');`.
- **Política de senha:** servidor com `password_min_length=8` +
  `password_hibp_enabled=true` (bloqueia senha vazada); validadores do painel já
  em 8. **Pendente do dono:** trocar a senha fraca do Admin Master
  (`vicenteroriz003`) e **rotacionar** o `SUPABASE_ACCESS_TOKEN` exposto em chat.
- **MFA:** descartado por decisão de produto (implementação revertida); infra
  server-side (`custom_access_token_hook` + flag `ENFORCE_MFA_ADMIN_MASTER`)
  segue **OFF**.
- **Reauditar:** skills `agsur-security-audit` / `db-migration-security-review` e
  agentes `supabase-security-auditor` / `flutter-client-security-reviewer` /
  `security-remediation-engineer` em `.claude/` (rodar de dentro de `agsur-main/`).

### Auth

`lib/auth/supabase_auth/` envolve `gotrue` em torno de um `BaseAuthUser`. Um
`AppStateNotifier` escuta o stream do usuário e o `GoRouter` rebuilda em
mudanças, redirecionando para login quando uma rota protegida é acessada
deslogada.

- `AppStateNotifier` em `lib/flutter_flow/nav/nav.dart`
- Rotas marcadas com `requireAuth: true` no `FFRoute`

**Gate de perfil no login.** `lib/pages/authentication/login/login_widget.dart`
faz pré-check via RPC `check_app_access(p_email)` **antes** de
`signInWithPassword` — falha-fechada (qualquer erro de RPC bloqueia, sem deixar
sessão flutuando). Lista permitida: `Admin Master`, `Admin`, `Vendedor`, `Admin2`.

**MFA enforcement.** O painel também valida o `aal` do JWT após login. Se for
Admin Master e `aal != 'aal2'`, faz signOut. Default OFF (`ENFORCE_MFA_ADMIN_MASTER=false`)
até todos os Admin Masters cadastrarem TOTP. Quando estiverem cadastrados:
build com `--dart-define=ENFORCE_MFA_ADMIN_MASTER=true` e ativar o hook
`custom_access_token_hook` no Studio (defesa em camadas server-side).

### Observabilidade

Sentry está integrado em `lib/observability/sentry.dart`:

- DSN injetado em build-time via `--dart-define=SENTRY_DSN=...` (sem DSN, no-op).
- `runWithSentry(builder)` envolve o `runApp` no `main.dart`.
- `setSentryUser(uid)` chamado pós-login no `auth_manager`; `setSentryUser(null)` no logout.
- `beforeSend` filtra `Authorization`/`apikey`/`Cookie` dos headers reportados.
- `tracesSampleRate`: 10% em produção, 100% em dev.

Nunca enviar PII para Sentry.

### Domínio — fluxo de importação de aeronave

`lib/app_constants.dart` define `FFAppConstants.TrackingDescription`: 21 etapas
fixas do processo de importação (Cadastro Inicial → Personalização → Proforma →
Reserva → Pagamentos → RAB → Seguro → Apólices → Despachante → Desembaraço →
Liberação para Voo). A esteira de tracking (`tracking`, `tracking_details`,
`vw_all_tracking`) é indexada por essa lista.

Fluxo de venda: `leads` → `proposal` (+ `proposal_item`, `proposal_financing`)
→ `contract` (+ `contract_terms`) → `sales` → `tracking` por aeronave
(`user_aircraft`). PDFs em `lib/custom_code/actions/generate_*_pdf.dart`
(libs `pdf` + `printing`).

## Convenções

### Flutter

- **Tema/widgets:** seguir o par `*_widget.dart` + `*_model.dart` e usar
  `FlutterFlowTheme.of(context)`; alterações de tema vão em
  `lib/flutter_flow/flutter_flow_theme.dart`, não hardcoded.
- Lints usam `package:flutter_lints/flutter.yaml` com `unnecessary_string_escapes: false`.
- Rodar `flutter analyze` antes de propor mudanças não-triviais — alguns
  arquivos gerados têm warnings tolerados, mas erros novos devem ser corrigidos.
- **Versões de dependência são pinadas.** Bumpar manualmente arrisca quebrar a
  próxima regeneração FlutterFlow. Só mexa com motivo claro e teste auth +
  queries depois.
- **`FutureBuilder` com `future:` inline refaz a query a cada rebuild.** Padrão
  do FlutterFlow `FutureBuilder(future: Tabela().queryRows(...))` dentro do
  `build` dispara a consulta em todo `setState` — e se estiver dentro de um
  `ListView`, uma vez por item, gerando dezenas de chamadas repetidas (já
  aconteceu com `aircraft_items` em `view_contract`/`view_edit_proposal`/
  `create_proposal`). Memoize o future no model (`_model.algumFuture ??= ...`,
  ou `Map` por chave) e limpe no `dispose`. Os helpers `FutureRequestManager`
  (`propostaFinanceiro`, `aircraft`) já fazem isso para as RPCs do topo.

### Flutter web — armadilhas conhecidas

Este build web (CanvasKit) acumulou bugs não-óbvios; cada item abaixo já
quebrou produção:

- **Versão do Flutter pinada em `3.41.9`** nos workflows (`flutter-analyze.yml`
  e `deploy-vercel.yml`, `channel: stable`). O canal stable subiu pra 3.44.0 e
  quebrou o build — não despinar sem rodar `flutter build web --release` inteiro.
- **`Image.asset` não renderiza neste build.** Logos/imagens de asset carregam
  via `rootBundle.load` + `Image.memory` (ver login). `Image.asset` direto sai
  em branco; `cacheWidth`/`cacheHeight` também quebram o render.
- **CSP em `vercel.json` precisa de `blob:`.** Upload de foto/PDF usa URLs
  `blob:` — `connect-src`/`img-src`/`worker-src`/`child-src` já liberam. Remover
  quebra uploads **silenciosamente**. Domínio externo novo (API, CDN) tem que
  entrar no `connect-src`.
- **Fontes de ícone precisam de `<link rel="preload">` em `web/index.html`.** Sem
  isso o CanvasKit pinta antes da fonte carregar e ícones (MaterialIcons /
  FontAwesome) somem de forma intermitente.
- **Cache do `main.dart.js`:** ao testar mudança no web local, hard-refresh
  (Cmd+Shift+R) — senão você vê o bundle antigo.

### Responsividade (mobile / tablet)

O painel é usado em desktop, tablet e celular. O design system em `lib/core_ui/`
já trata a casca; ao mexer em telas/conteúdo, mantenha o padrão:

- **Dois breakpoints.** Sidebar fixa → Drawer em **1024px** (`kSidebarBreakpoint`
  em `app_shell.dart`). Conteúdo lado a lado → empilhado em **768px**
  (`kStackBreakpoint` em `app_responsive.dart`; helpers `isStacked` /
  `context.isStacked`). Use esses, não números mágicos novos.
- **Linhas de campos lado a lado:** use `ResponsiveRow` (de `core_ui`) no lugar
  de `Row`. É drop-in — idêntico a `Row` em tela larga; abaixo de 768px
  desempacota `Expanded`/`Flexible` e empilha em coluna. Telas de cadastro
  (`view_edit_*`, `oficina_details`) e de proposta/contrato já usam.
- **Nunca largura fixa maior que ~300px** num filho não-flexível. Imagem/box que
  precisa de teto: `ConstrainedBox(maxWidth: N)` + `width: double.infinity`
  (preenche o disponível, limitado pela tela). Largura fixa **só** quando há um
  `Expanded` irmão absorvendo o resto (ex.: campo "Número"/"UF" ao lado de
  `Expanded`) — aí não estoura.
- **Barra/elemento proporcional à largura:** derive de `LayoutBuilder`
  (`constraints.maxWidth`), nunca de `MediaQuery.sizeOf(context).width` (ignora
  sidebar + padding e estoura/erra a proporção).
- Listagens, modais (`AppModal`), `AppListScaffold`/`AppDetailsScaffold` e o
  dashboard já são responsivos — reaproveite em vez de recriar layout.

### Operação e produção

- Antes de subir uma migration nova, sempre fazer `npx supabase db push --dry-run`.
- Buscar problemas de RLS via smoke test: `gh workflow run rls-smoke.yml`.
- Para qualquer incidente real (escalation, vazamento de chave, conta
  comprometida, restore), seguir `RUNBOOK.md`. Atualizar o runbook depois de
  cada incidente real.
- Configurações de auth que precisam do Supabase Studio estão em
  `supabase/DASHBOARD_TIER2_TODO.md`. Verificar antes de declarar produção pronta.

## Locale

Somente pt-BR (`supportedLocales: [Locale('pt')]`). `FFLocalizationsDelegate`
configurado mas strings ficam inline em pt — não há arquivos `.arb`.
