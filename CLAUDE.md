# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Este repo tem dois projetos Flutter + uma pasta de schema versionado, todos
compartilhando o mesmo backend Supabase (projeto `bkzybtmxxzpxtztesdye`):

- `agsur-app/` (Flutter, package `a_g_sur_client_app`). Cliente final (mobile + web): pilotos/clientes, certificados, garantias, cotação de peças, acompanhamento de aeronave.
- `agsur-painel/` (Flutter, package `a_g_sur_back_office`). Painel administrativo (web, deploy Vercel em `painel-agsur.vercel.app`): leads, vendedores, propostas, contratos, oficina, esteira de importação ("tracking"), funcionários, taxas de financiamento.
- `supabase/` — fonte da verdade do schema. Migrations em `supabase/migrations/` (15+ aplicadas em 2026-05-08 endurecendo RLS/triggers/audit). Status atual em `supabase/README.md`. Pendências do dashboard em `supabase/DASHBOARD_TIER2_TODO.md`.
- `RUNBOOK.md` — procedimentos de incidente (rotação de chave, restore de backup, escalation suspeita, drift de policy, LGPD).
- `.github/workflows/` — CI: `flutter-analyze`, `supabase-db-check` (db push --dry-run), `rls-smoke` (diário, valida que anon não lê dados sensíveis).

> **Nota:** anteriormente havia um `agsur-painel-react/` (Next.js) — reescrita
> em curso do painel. O diretório foi removido do filesystem em 2026-05-08
> antes do endurecimento de segurança ser aplicado lá. Se voltar, replicar
> os fixes documentados na memória `agsur_security_hardening_2026_05_08.md`.

Cada projeto Flutter tem seu próprio manifesto (`pubspec.yaml`), build, testes e ciclo de vida. Não há monorepo nem pacote compartilhado — código que existe nos dois Flutters (ex.: `lib/backend/supabase/database/`, `lib/auth/supabase_auth/`) é **duplicado**, não importado. Mudanças que precisam afetar ambos os Flutters devem ser replicadas manualmente.

**Os dois projetos Flutter estão em estágios diferentes da mesma origem FlutterFlow:**

- **`agsur-painel/` ainda é FlutterFlow.** Tem `lib/flutter_flow/`, `FFAppState`, `FlutterFlowTheme`, `createRouter`. Tratar `lib/flutter_flow/` e `lib/backend/supabase/database/` como código gerado: uma regeneração pelo FlutterFlow sobrescreve edições manuais. **Atenção** — o `login_widget.dart` foi endurecido manualmente (gate via RPC `check_app_access`, MFA enforcement, `setSentryUser`). Uma regen do FlutterFlow vai apagar esses ganchos; revalidar antes de subir.
- **`agsur-app/` está sendo migrado para Flutter nativo.** Não tem `lib/flutter_flow/`. Substituições já feitas: roteamento em `lib/core/router/app_router.dart` (`createAppRouter`) com tabela de acesso em `route_access.dart`; tema em `lib/core/theme/` (`AppTheme`, `app_colors.dart`, `app_spacing.dart`, `app_typography.dart`); estado de auth em `lib/core/auth/` (`AppStateNotifier.instance` + `CurrentUser.instance`). O wrapper de baixo nível do Supabase auth (`lib/auth/supabase_auth/`) e o backend gerado (`lib/backend/supabase/database/`, `lib/backend/schema/`) foram **mantidos** da era FlutterFlow — `main.dart` importa de ambos os lados. Reusar telas existentes do painel quando aplicável (ver memória `project_agsur_app_refactor.md`).

## Comandos comuns

Os comandos rodam **dentro de cada subprojeto**, não da raiz.

### Projetos Flutter (`agsur-app/`, `agsur-painel/`)

```powershell
# Setup
flutter pub get

# Análise estática (lints definidos em analysis_options.yaml -> flutter_lints)
flutter analyze

# Testes
flutter test
flutter test test/widget_test.dart            # arquivo único
flutter test --plain-name "nome do teste"     # teste único

# Run em desenvolvimento
flutter run -d chrome                         # web (padrão para o painel)
flutter run -d <deviceId>                     # mobile

# Build web (painel é deployado em /build/web via vercel.json)
flutter build web --release

# Splash screen (apenas painel — usa flutter_native_splash.yaml na raiz)
dart run flutter_native_splash:create
```

Painel: `vercel.json` aponta `outputDirectory: build/web` com fallback SPA (`/(.*) → /index.html`). O `buildCommand` é `null`, então o build do Flutter precisa ser executado **antes** do deploy (manualmente ou via script externo) — Vercel apenas serve o resultado.

Splash: só o painel tem `flutter_native_splash.yaml`. Regenerar com `dart run flutter_native_splash:create` quando o asset/cor de splash mudar; rodar antes do `flutter build web`.

App cliente: tem `web/`, `android/`, `ios/`. Painel: idem, mais é primariamente alvo web.

### Build de produção (com Sentry e env vars)

```powershell
# .env.local (não commitar)
$env:SENTRY_DSN = "https://...@sentry.io/..."
$env:APP_ENV = "production"
$env:APP_RELEASE = "agsur-painel@$(git rev-parse --short HEAD)"

# Build do painel (web → Vercel)
cd agsur-painel
flutter build web --release `
  --dart-define=SENTRY_DSN=$env:SENTRY_DSN `
  --dart-define=APP_ENV=$env:APP_ENV `
  --dart-define=APP_RELEASE=$env:APP_RELEASE

# Build do app (mobile)
cd agsur-app
flutter build apk --release `
  --dart-define=SENTRY_DSN=$env:SENTRY_DSN `
  --dart-define=APP_ENV=production
```

`SUPABASE_URL` e `SUPABASE_ANON_KEY` também aceitam `--dart-define` para
apontar para projeto staging/preview sem alterar código (fallback hardcoded
em `lib/backend/supabase/supabase.dart` quando vazias).

### Workflow de schema (Supabase)

```powershell
# Setup uma vez
$env:SUPABASE_ACCESS_TOKEN = "<token de https://supabase.com/dashboard/account/tokens>"
npx -y supabase@latest link --project-ref bkzybtmxxzpxtztesdye

# Criar nova migration
npx supabase migration new <slug>
# editar supabase/migrations/YYYYMMDDHHMMSS_<slug>.sql

# Validar antes de aplicar
npx supabase db push --dry-run

# Aplicar
npx supabase db push
```

**Toda mudança de schema/RLS/policy/trigger deve passar por PR.** O CI
valida em `supabase-db-check.yml` (dry-run) e `rls-smoke.yml` (testa que
anon não lê dados sensíveis). DDL fora do PR vira drift e o smoke diário
detecta.

## Arquitetura

### Backend e dados — Supabase como única fonte

Toda persistência e auth vão direto ao Supabase via `supabase_flutter`. Não há camada de API própria além de algumas chamadas REST diretas usadas pelo painel Flutter (`agsur-painel/lib/backend/api_requests/api_calls.dart`, ex.: `signup` chamando `/auth/v1/signup` para criar usuários sem deslogar o admin).

- `lib/backend/supabase/supabase.dart` — singleton `SupaFlow` com URL e anon key embarcadas como fallback. Em build de produção, valores são sobrescritos via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`. Anon key é pública por design Supabase; segurança real depende de RLS.
- `lib/backend/supabase/database/tables/*.dart` — uma classe `SupabaseTable<Row>` por tabela/view, gerada pelo FlutterFlow. Estende `SupabaseTable` (definido em `database/table.dart`) com helpers `queryRows / querySingleRow / insert / update / delete` sobre `PostgrestFilterBuilder`.
- Tabelas `vw_*` são views Postgres (read-only) — usar para leituras agregadas (ex.: `vw_homepage_dashboard`, `vw_proposal_data`, `vw_get_clients`); as tabelas base (`leads`, `proposal`, `contract`, `tracking`, `aircrafts`, `users`, etc.) para escrita.
- `lib/backend/schema/structs/` — DTOs em Dart correspondentes a tipos de retorno de RPCs/funções Supabase (ex.: `get_proposal_details_struct.dart`). `lib/backend/schema/enums/enums.dart` espelha enums do banco.

Quando precisar adicionar uma tabela/coluna nova: o caminho FlutterFlow é regenerar; em edição manual, replicar o padrão dos arquivos `tables/*.dart` existentes (subclasse de `SupabaseTable` + `SupabaseDataRow` com getters tipados sobre `data['campo']`).

### Schema versionado em `supabase/migrations/`

DDL agora vive **versionado no git** em `supabase/migrations/`. 15+ migrations
aplicadas em 2026-05-08 cobrem:

- **Defesa em camadas (triggers BEFORE):** 32 tabelas com triggers que
  rejeitam writes não autorizados independente de RLS. Não confiar só em
  policy, sempre adicionar trigger correspondente quando a regra envolve
  campos privilegiados.
- **Auth/RLS helpers SECURITY DEFINER:** `auth_is_admin_master()`,
  `auth_is_admin()`, `auth_is_seller_or_admin()`, `auth_is_service_role()`,
  `auth_user_email()`, `auth_owns_proposal(uuid)`,
  `auth_owns_user_aircraft(uuid)`, `auth_owns_contract(uuid)`,
  `auth_is_linked_to_client(uuid)`. Use estes nas suas policies em vez de
  reescrever joins.
- **Audit log:** `public.security_audit_log` (append-only, read = Admin
  Master) registra mudanças em campos privilegiados de `users` (profile_type,
  is_admin, email, cpf) e qualquer write em `financial`, `financing_rates`,
  `sales`, `company`. Função `purge_security_audit_log(retention_days)`
  para retenção (precisa pg_cron habilitado, ou rodar via cron externo).
- **Soft-delete protection:** trigger bloqueia UPDATE em rows com
  `is_deleted=true` (exceto Admin Master) em `certificates`, `leads`,
  `proposal`, `service_letter`, etc.
- **MFA hook:** `public.custom_access_token_hook(jsonb)` rejeita JWT issue
  para Admin Master sem `aal=aal2`. **Pendente ativação no Studio**
  (Auth → Hooks). Defesa em camadas client-side já no painel.
- **Storage hardening:** buckets `AGSur` (50MB + whitelist MIME),
  `service-letters` (20MB + só PDF), `pdfs` (privado).

Status atual completo + smoke tests em `supabase/README.md`. Pendências
manuais do dashboard (que precisam ser feitas no Studio porque o token
CLI não tem permissão) em `supabase/DASHBOARD_TIER2_TODO.md`.

**Convenção:** toda mudança de schema/RLS via PR. CI valida com
`supabase-db-check.yml` (dry-run) e `rls-smoke.yml` (smoke daily anon).

### Auth

`lib/auth/supabase_auth/` envolve `gotrue` em torno de um `BaseAuthUser` (compartilhado entre os dois projetos). Um `AppStateNotifier` escuta o stream do usuário e o `GoRouter` rebuilda em mudanças, redirecionando para login quando uma rota protegida é acessada deslogada.

- **Painel Flutter:** `AppStateNotifier` vive em `lib/flutter_flow/nav/nav.dart`; rotas marcadas com `requireAuth: true` no `FFRoute`.
- **App:** `AppStateNotifier.instance` em `lib/core/auth/app_state_notifier.dart` + `CurrentUser.instance` em `current_user.dart`; controle de acesso de rotas em `lib/core/router/route_access.dart`.

Observação específica do painel Flutter: criar outro usuário sem deslogar o admin é feito via REST direto (`CreateAccountAnotherUserCall` em `lib/backend/api_requests/api_calls.dart`) em vez do client SDK, justamente para preservar a sessão atual.

**Gate de perfil no login.** O login do painel (`agsur-painel/lib/pages/authentication/login/login_widget.dart`) faz pré-check via RPC `check_app_access(p_email)` **antes** de `signInWithPassword` — falha-fechada (qualquer erro de RPC bloqueia, sem deixar sessão flutuando). Lista permitida: `Admin Master`, `Admin`, `Vendedor`, `Admin2`. Mesmo gate no `agsur-app` mas com lista invertida (`Cliente`, `Piloto`, `Oficina`). Atenção ao mapping `Admin Master` (com espaço, formato Postgres do enum `profile_types`) — ver memória `agsur_profile_types_enum_mismatch`.

**MFA enforcement.** O painel também valida o `aal` do JWT após login. Se for Admin Master e `aal != 'aal2'`, faz signOut + mensagem. Defesa em camadas — o hook `custom_access_token_hook` no banco também rejeita server-side quando ativado no Studio (ver `supabase/DASHBOARD_TIER2_TODO.md`).

### Navegação

Cada projeto tem seu próprio roteador, montado de forma diferente:

- **Painel Flutter (FlutterFlow):** `createRouter(AppStateNotifier)` em `lib/flutter_flow/nav/nav.dart`. Cada tela é um `FFRoute` com `routeName`, `routePath` e parâmetros tipados via `params.getParam('x', ParamType.String)`. Ao adicionar uma página: criar widget + `routeName`/`routePath` estáticos, registrar no `createRouter`, exportar em `lib/index.dart`.
- **App (nativo):** `createAppRouter(AppStateNotifier)` em `lib/core/router/app_router.dart`. Não usa `FFRoute`/`params.getParam`; é um `GoRouter` padrão com `route_access.dart` para gating. Query params validados via `parseUuid`/`sanitizeQueryText` em `lib/core/security/sanitizers.dart` (cobertos por `test/sanitizers_test.dart`).

### Estado

- **Painel Flutter:** `FFAppState` (`lib/app_state.dart`, ChangeNotifier registrado no `runApp`) — estado global persistido com `shared_preferences`/`hive`. Telas seguem o padrão FlutterFlow `*_widget.dart` + `*_model.dart` (model carrega controllers, request managers, lifecycle).
- **App:** sem `FFAppState`. Estado de usuário lido via `CurrentUser.instance` (singleton com refresh manual no stream de auth do `main.dart`); `AppStateNotifier.instance` controla auth + splash + redirecionamento. Telas novas devem seguir Flutter idiomático, não o par FlutterFlow `*_widget.dart` + `*_model.dart`.

### Observabilidade

Sentry está integrado em ambos via `lib/observability/sentry.dart`:

- DSN injetado em build-time via `--dart-define=SENTRY_DSN=...` (sem DSN, vira no-op em dev).
- `runWithSentry(builder)` envolve o `runApp` no `main.dart`.
- `setSentryUser(uid)` é chamado pós-login (no `auth_manager` do painel, em `CurrentUser.refresh()` no app) e `setSentryUser(null)` no logout.
- `beforeSend` filtra `Authorization`/`apikey`/`Cookie` dos headers reportados.
- `tracesSampleRate`: 10% em produção, 100% em dev.

Nunca enviar PII para Sentry. Se for adicionar `setUser` com email/nome, garantir que isso só acontece em ambientes não-produção.

### Domínio do painel — fluxo de importação de aeronave

`agsur-painel/lib/app_constants.dart` define `FFAppConstants.TrackingDescription`: 21 etapas fixas do processo de importação (Cadastro Inicial → Personalização → Proforma → Reserva → Pagamentos → RAB → Seguro → Apólices → Despachante → Desembaraço → Liberação para Voo). A esteira de tracking (`tracking`, `tracking_details`, `vw_all_tracking`) é indexada por essa lista; manter sincronia se etapas forem renomeadas.

Fluxo de venda principal: `leads` → `proposal` (+ `proposal_item`, `proposal_financing`) → `contract` (+ `contract_terms`) → `sales` → `tracking` por aeronave (`user_aircraft`). Geração de PDFs de proposta e contrato no painel Flutter em `lib/custom_code/actions/generate_*_pdf.dart` (libs `pdf` + `printing`).

### Locale e i18n

Os Flutters são **somente pt-BR** (`supportedLocales: [Locale('pt')]` no `MaterialApp.router`). `FFLocalizationsDelegate` está configurado mas as strings ficam inline em pt — não há arquivos `.arb`.

## Convenções práticas

### Flutter

- **Tema/widgets:** no painel Flutter, seguir o par `*_widget.dart` + `*_model.dart` e usar `FlutterFlowTheme.of(context)`; alterações de tema vão em `lib/flutter_flow/flutter_flow_theme.dart`, não hardcoded. No app, usar `AppTheme` e os tokens em `lib/core/theme/` (`app_colors.dart`, `app_spacing.dart`, `app_typography.dart`); não recriar `FlutterFlowTheme`.
- Lints usam `package:flutter_lints/flutter.yaml` com `unnecessary_string_escapes: false` (necessário porque o FlutterFlow gera bodies de API com escapes manuais; ver `api_calls.dart`).
- Rodar `flutter analyze` antes de propor mudanças não-triviais — alguns arquivos gerados têm warnings tolerados, mas erros novos devem ser corrigidos.
- **Versões de dependência são pinadas no painel.** O `pubspec.yaml` do painel Flutter lista a maioria dos pacotes com versão exata (ex.: `supabase_flutter: 2.9.0`, `go_router: 12.1.3`, `gotrue: 2.12.0`), sem `^`. Isso é padrão FlutterFlow e é deliberado: bumpar manualmente arrisca quebrar a próxima regeneração e introduzir incompatibilidades entre `supabase` / `gotrue` / `postgrest` / `realtime_client` / `storage_client` / `functions_client` (todas pinadas em conjunto). Só mexa em versões com motivo claro e teste o fluxo de auth + queries depois. O app também pina (mesmas versões de Supabase, `go_router: 12.1.3`) para manter compatibilidade com o backend duplicado, mas não está mais sob risco de regeneração — só não desincronize as versões de Supabase entre os dois.

### Operação e produção

- Antes de subir uma migration nova, sempre fazer `npx supabase db push --dry-run` localmente. CI também faz, mas pegar erro local é mais barato.
- Buscar problemas de RLS via smoke test: `gh workflow run rls-smoke.yml` (ou esperar o cron diário).
- Para qualquer incidente real (escalation suspeita, vazamento de chave, conta comprometida, restore), seguir `RUNBOOK.md` na raiz do repo. Atualize o runbook depois de cada incidente real — runbook desatualizado é pior que nenhum.
- Configurações de auth que precisam do Supabase Studio (não acessíveis via CLI) estão em `supabase/DASHBOARD_TIER2_TODO.md`. Verificar todos os checkboxes lá antes de declarar produção pronta.
