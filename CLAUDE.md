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
para criar usuários sem deslogar o admin).

- `lib/backend/supabase/supabase.dart` — `SupaFlow` com URL/anon key embarcadas
  como fallback. Em build de produção, valores são sobrescritos via
  `--dart-define`. Anon key é pública por design Supabase; segurança real
  depende de RLS.
- `lib/backend/supabase/database/tables/*.dart` — uma classe `SupabaseTable<Row>`
  por tabela/view, gerada pelo FlutterFlow. Helpers `queryRows / querySingleRow /
  insert / update / delete`.
- Tabelas `vw_*` são views Postgres (read-only) — usar para leituras agregadas.

### Schema versionado em `supabase/migrations/`

DDL agora vive **versionado no git** em `supabase/migrations/`. 16+ migrations
aplicadas em 2026-05-08 cobrem:

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

Status atual completo + smoke tests em `supabase/README.md`. Pendências
manuais do dashboard em `supabase/DASHBOARD_TIER2_TODO.md`.

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
