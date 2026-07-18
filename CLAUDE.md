# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este repo

**`agsur` — painel administrativo Agsur** (Flutter web, deploy Vercel;
produção em **`painel.agsurbrasil.app`**, com `painel-agsur.vercel.app` como
endereço alternativo). Gerencia leads, vendedores, propostas, contratos,
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

```bash
flutter pub get
flutter analyze
flutter test                                 # todos
flutter test test/jwt_utils_test.dart        # arquivo único

flutter run -d chrome                        # web
flutter build web --release                  # antes de deploy Vercel
```

### Build de produção (com Sentry e env vars)

```bash
export SENTRY_DSN="https://...@sentry.io/..."
export SUPABASE_URL="https://bkzybtmxxzpxtztesdye.supabase.co"
export SUPABASE_ANON_KEY="eyJ..."

flutter build web --release \
  --dart-define=SENTRY_DSN="$SENTRY_DSN" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=APP_ENV=production \
  --dart-define=APP_RELEASE=agsur-painel@$(git rev-parse --short HEAD)

# Para forçar MFA em Admin Master (depois que TODOS cadastrarem TOTP):
#   --dart-define=ENFORCE_MFA_ADMIN_MASTER=true
```

`vercel.json` aponta `outputDirectory: build/web` com fallback SPA. O
`buildCommand` é `null`, então o `flutter build web` precisa rodar **antes**
do deploy (manualmente ou via script). Vercel apenas serve o resultado.

> 🚨 **Deploy SÓ via CI. Nunca conecte a integração Git nativa do Vercel neste
> projeto.** Como o Vercel não builda Flutter (`buildCommand: null`), um deploy
> disparado pelo push sai **vazio** (sem `index.html`) e mesmo assim **rouba o
> alias de produção** → `painel.agsurbrasil.app` inteiro vira `404 NOT_FOUND`.
>
> Isso já aconteceu **duas vezes** (2026-06-25 e 2026-07-15). Na segunda, a
> integração estava ligada desde 02/07 e ficava escondida: o deploy do CI rodava
> logo depois de cada push e re-aliasava por cima. Um commit **só de `.md`** —
> que o `deploy-vercel.yml` pula via `paths-ignore` — deixou o deployment vazio
> sozinho e derrubou o painel.
>
> A guarda hoje é `"git": {"deploymentEnabled": false}` no `vercel.json`
> (versionada, sobrevive a mexida no dashboard). **Não remova.** Ela não afeta o
> `vercel deploy --prebuilt` do CI, só o auto-deploy por push.
>
> **Sintoma → diagnóstico:** 404 com `x-vercel-error: NOT_FOUND` (e *não*
> `DEPLOYMENT_NOT_FOUND`) = o deployment existe mas está vazio. Confirme com
> `vercel inspect https://painel.agsurbrasil.app`: se o deployment servindo prod
> tiver `"source": "git"`, é isso. Conserto: `vercel promote <dpl_ do último CI
> verde>` restaura em segundos.

### Workflow de schema (Supabase)

```bash
export SUPABASE_ACCESS_TOKEN="<token de https://supabase.com/dashboard/account/tokens>"
npx -y supabase@latest link --project-ref bkzybtmxxzpxtztesdye

npx supabase migration new <slug>
# editar supabase/migrations/YYYYMMDDHHMMSS_<slug>.sql

npx supabase db push --dry-run   # validar
npx supabase db push             # aplicar
```

**Toda mudança de schema/RLS via PR.** CI valida com `supabase-db-check.yml`
(dry-run) e `rls-smoke.yml` (smoke daily anon). DDL fora do PR vira drift e
o smoke detecta.

**SQL ad-hoc (leitura e correção pontual de dados) sem Studio:** com o projeto
linkado, `npx supabase db query --linked "<sql>"` (ou `-f arquivo.sql`) roda via
Management API usando a auth já configurada da CLI — **não precisa colar token
no chat** (o padrão recorrente de vazamento; ver `RUNBOOK.md`/memória). Roda como
`postgres`, então **ignora RLS e as triggers de guarda** (session_user = postgres):
ótimo para inspecionar/consertar, péssimo para testar autorização — para validar
RLS/triggers use JWT real via PostgREST. Use para **DDL** só o fluxo de migration
acima (via PR); `db query` é para leitura e limpeza de dado pontual. Regra de
ouro: SELECT de conferência antes de todo UPDATE/DELETE, e prefira soft-delete.

**Soft-delete x o que a tela filtra (aprendido em limpezas de dado de teste):**
esconder um registro da UI depende do filtro da view, que varia:
- **Contratos/Propostas** (`vw_contract_data`) filtra `active=true AND
  is_deleted=false AND is_contract=...` → basta `update proposal set
  is_deleted=true` (reversível) para sumir da lista.
- **Rastreio** (`vw_all_tracking`) **NÃO filtra** `deleted`/`is_deleted` — mostra
  toda linha de `tracking`. Esconder um rastreio exige **apagar** as linhas de
  `tracking` (+ `tracking_details`) daquele `user_aircraft` (as 21 etapas são
  regeneráveis pelo template). Marcar `user_aircraft.deleted=true` não adianta.
- **Usuário do app** nunca por UPDATE/DELETE direto: sempre a RPC
  `admin_delete_app_user` (soft-delete + ban + libera e-mail).

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

**E-mail de credenciais (Resend, 2026-07-15).** Todo fluxo de criação de
usuário (colaborador, vendedor, piloto, oficina, cliente manual e cliente via
conversão proposta→contrato) dispara um e-mail pt-BR com e-mail+senha pela Edge
Function **`send-credentials-email`** (`supabase/functions/`; Resend, domínio
verificado `painel.agsurbrasil.app`, remetente `acesso@`). No Dart, use
`lib/security/credentials_email.dart` (`sendCredentialsEmail` — a falha de
e-mail NUNCA aborta o cadastro; em erro, `showCredentialsEmailWarning` avisa o
admin para repassar a senha manualmente e o evento vai ao Sentry sem a senha).
A função exige JWT de perfil do painel (Admin Master/Admin/Vendedor/Admin2) —
sessão de app cliente leva 403. Secret `RESEND_API_KEY` via
`npx supabase secrets set` (nunca no código). Deploy:
`npx supabase functions deploy send-credentials-email --project-ref bkzybtmxxzpxtztesdye --use-api`.
A conversão proposta→contrato **não usa mais** `resetPasswordForEmail` (o
e-mail nativo do Supabase, limitado a 2/hora, ficou só para "esqueci a senha").

**E-mail editável no funil (2026-07-17).** Decisão de UX do cliente: **UMA
forma de editar por tela** — sem lápis avulso ao lado do texto; o e-mail vive
dentro do formulário/modal que a tela já tem:

- **Proposta (antes da conversão):** as modais de empresa
  (`modal_register_company`/`modal_edit_company`) ganharam o campo "E-mail do
  cliente" via params opcionais `emailInitial`/`onSaveEmail` (o campo só
  aparece quando `onSaveEmail` é passado). Em `create_proposal`/
  `view_edit_proposal`, o handler grava `leads.email` (guardWrite) e sincroniza
  `FFAppState` (`asGetLeadProposal` + `asGetProposalDetails`). O e-mail é salvo
  ANTES do btnActions — falhou, a modal fica aberta. O cadastro de empresa
  também nasce pré-preenchido com empresa/telefone/CPF/e-mail do lead.
- **Na conversão (`view_edit_proposal`):** o botão "Converter em contrato" abre
  primeiro "Confirmar e-mail do cliente" (diálogo compartilhado
  `lib/pages/shared/edit_email_dialog/edit_email_dialog.dart`, pré-preenchido e
  editável); o e-mail confirmado alimenta lookup, signup, insert e
  `sendCredentialsEmail`. **Cliente já existente = reuso:** o lookup é
  case-insensitive (`ilike` + `is_deleted=false`), `createUserPublic` é zerado
  a cada conversão (senão um resíduo do model roubava o `user_Id` do
  contrato), e se o signup recusar por conta já existente (422 ou 200
  "ofuscado"), re-busca o users e segue com o cliente existente — contrato
  novo para o mesmo cliente, sem abortar e sem duplicar.
- **Depois da conversão:** o e-mail é o login do app E a chave de RLS
  (`leads.email = auth_user_email()`), então a troca passa pela RPC
  **`admin_update_client_email`** (migration `20260717120000` — troca
  `public.users` + `auth.users` + `auth.identities` + `leads` na MESMA
  transação e revoga as sessões; Admin Master ou Admin documentação). Entradas:
  a modal "Editar empresa" do `view_contract` (campo de e-mail com handler via
  RPC) e o campo E-mail de `view_edit_client` (editável para
  `AccessControl.canEditFunil`, persistido pelo "Atualizar dados" via
  `_saveClientEmailIfChanged` antes dos demais updates).
- **Reenviar senha (`view_edit_client`):** botão ao lado de "Atualizar dados"
  chama a RPC **`admin_reset_client_password`** (migration `20260717130000` —
  gera senha hex forte server-side, grava hash bcrypt em `auth.users`, revoga
  sessões e devolve a senha) e reenvia via `sendCredentialsEmail`. Para quando
  o e-mail de credenciais da criação não chegou.
- **Guarda em `view_edit_lead`:** se o lead já tem cliente vinculado, o save
  NÃO altera o e-mail (aviso manda usar o cadastro do cliente) — evita o
  desync silencioso com o auth.

- `lib/backend/supabase/supabase.dart` — `SupaFlow` com URL/anon key embarcadas
  como fallback. Em build de produção, valores são sobrescritos via
  `--dart-define`. Anon key é pública por design Supabase; segurança real
  depende de RLS.
- `lib/backend/supabase/database/tables/*.dart` — uma classe `SupabaseTable<Row>`
  por tabela/view, gerada pelo FlutterFlow. Helpers `queryRows / querySingleRow /
  insert / update / delete`.
- Tabelas `vw_*` são views Postgres (read-only) — usar para leituras agregadas.
- **RPCs com placeholder de texto (armadilha de UUID).** Algumas RPCs lidas pelo
  painel — ex.: `get_proposal_details` (chamada em `api_calls.dart`; versionada
  desde `20260714130000`, que também passou a filtrar os itens de série pelo
  avião da proposta via `aircraft_item_links`) — devolvem
  `"Não cadastrado"` no lugar de campos ausentes, **inclusive `aircraft_id`**.
  Esse texto não é UUID: filtrar `aircrafts`/`aircraft_items` por ele dá
  **Postgres 22P02** e deixa a tela em branco (já aconteceu em
  `view_contract` / `view_edit_proposal`). Antes de consultar por id, valide com
  regex de UUID e caia no fallback se inválido. **Pendência:** a mesma RPC tem um
  `42804` (coluna 10 declarada `uuid` mas retornando `text` por causa do
  `COALESCE(..., 'Não cadastrado')`) — corrigir na origem (manter `aircraft_id`
  `uuid`/`NULL`; o rótulo é problema de apresentação) via migration versionada.

### Schema versionado em `supabase/migrations/`

DDL agora vive **versionado no git** em `supabase/migrations/` (47 arquivos em
2026-07-15; todos aplicados em produção e registrados no histórico do Supabase,
exceto o enforcement da Fase 7 — ver RBAC abaixo). Em 2026-07-14 o histórico
foi **reparado** via `migration repair` (4 migrations tinham sido aplicadas por
fora sem registro); desde então `db push --dry-run` reflete a realidade e o
CLI recusa aplicar a Fase 7 fora de ordem sem `--include-all`. O batch de
endurecimento (2026-05-08 a 2026-05-26) cobre:

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
- **Write de `company` = funil (2026-07-14, `20260714120000`):** as policies e a
  trigger que exigiam Admin Master foram trocadas por documentação + vendedor +
  master (`company` é a empresa DO LEAD, escrita durante o funil — a policy de
  2026-05-08 a tratava como cadastro institucional). Corrigiu o bug de
  Admin/documentação e Vendedor "salvarem" Dados Empresariais sem persistir
  nada (bloqueio silencioso de RLS; ver seção write_guard). Matriz dos 7 perfis
  validada em produção por personificação.
- **Vínculo item↔aeronave (2026-07-14, `20260714130000`):** tabela
  `aircraft_item_links` (N:N), view `vw_aircraft_items_by_aircraft`
  (`security_invoker`) e a `get_proposal_details` versionada pela primeira vez,
  com os itens de série filtrados pelo avião da proposta (antes o JOIN era
  `ON item_type='series'` — todo item entraria em toda proposta).

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

### RBAC por perfil (menu / rotas / edição)

**Fonte da verdade única: `lib/security/access_control.dart`.** Define
`PanelRole` (`adminMaster`, `adminRecepcao`, `adminDocumentacao`, `vendedor`,
`none`) e o mapeamento a partir de `users`:

- `profile_type = 'Admin Master'` → `adminMaster` (vê/edita tudo).
- `profile_type = 'Vendedor'` → `vendedor` (funil de vendas + rastreio view-only).
- `profile_type = 'Admin'` + `access_level = 'documentacao'` → `adminDocumentacao`;
  qualquer outro `access_level` (inclusive **NULL**) → `adminRecepcao`.

Consumido por: `menu_widget` (itens do menu por papel), `nav.dart` (rotas
permitidas via `AccessControl.canView`), e telas com edição condicional — ex.
`view_tracking` usa `AccessControl.canEditTracking` (só master/documentação
editam/checam etapas; vendedor visualiza; recepção nem vê a tela). Ao mexer em
menu/rotas/edição, passe por esta camada — não hardcode perfil.

**Estado atual (2026-07-15): Fase 7 APLICADA em produção** (rls-smoke verde
antes e depois), junto com um fix crítico descoberto na validação: **as
triggers de guarda eram no-op desde 2026-05-08** — dentro de função SECURITY
DEFINER, `current_user` é o dono (postgres) e `auth_is_service_role()`
retornava true para qualquer chamador; só a RLS segurava as escritas. O fix
(`20260715120000_fix_trigger_service_role_bypass`) cria
`auth_is_service_request()` (usa `session_user`, imune a definer) e troca a
checagem nas 5 funções de guarda (`tg_require_admin/seller_or_admin/
documentacao/funil`, `tg_block_edit_when_soft_deleted`). **Seguem
deliberadamente neutralizadas** (bypass antigo; RLS é o guarda):
`tg_users_block_privilege_escalation` e as `tg_*_ownership` — armar exige
reconciliar as regras com os fluxos reais (vendedor cria cliente na conversão;
recepção cadastra piloto/oficina); `tg_require_service_role` (gate do audit
log) precisa do bypass por current_user. ⚠️ Personificação via Management
API/psql NÃO testa as triggers (session_user = postgres → bypass): valide com
JWT real via PostgREST. No client-side, `AccessControl.canEditFunil`
(master+documentação) decide o `typeAccess=edit` das listagens de
proposta/contrato (lápis + converter em contrato).

### Escritas do painel — bloqueio silencioso de RLS (`write_guard`)

**Num UPDATE/DELETE, a RLS não levanta erro:** ela filtra as linhas ANTES das
triggers BEFORE, a operação "sucede" afetando 0 linhas e o PostgREST devolve
2xx — o painel mostrava "salvo com sucesso" sem persistir nada (foi assim que o
bug do `company` passou meses invisível). Regras ao escrever no banco:

- Use `lib/security/write_guard.dart`: `guardWrite(context, op)` para
  UPDATE/DELETE (**o op TEM que passar `returnRows: true`** — sem isso,
  `SupabaseTable.update/delete` devolvem `[]` SEMPRE e o guard acusaria
  bloqueio em toda escrita), `checkWrite(context, rows)` quando envolver num
  lambda exigiria reindentar um `data:{}` gigante, e `guardInsert` para INSERT
  (que usa `.single()` e LANÇA em vez de devolver vazio).
- `silent: true` para escritas de segundo plano (ex.: sync de `fullprice` no
  load de `view_contract`/`view_edit_proposal`): bloqueio vai pro Sentry em vez
  de alertar quem não clicou em nada. Escrita por clique fica ruidosa.
- Nem todo bloqueio deve abortar: se a escrita anterior JÁ persistiu (delete de
  item + sync de total), early-return deixaria a tela inconsistente — reporte e
  siga. Todos os 26 update/delete das telas do funil estão cobertos
  (2026-07-14).

### Itens de série/opcionais — vínculo com aeronave (2026-07-14)

Um item (`aircraft_items`) vincula a N aeronaves via `aircraft_item_links`;
**item sem vínculo não aparece em proposta nenhuma**. O painel consulta pela
view `vw_aircraft_items_by_aircraft` (uma linha por par item↔avião; classe Dart
escrita à mão). Mapa do fluxo:

- **Cadastro:** menu Aeronaves → Categorias (`create_category`, tela core_ui):
  abas Série/Opcionais (filtram a lista E definem o tipo criado) + botão
  "Adicionar" que abre modal composto (categoria + itens + aeronaves numa
  tacada). Clicar numa categoria navega para a tela de itens do tipo
  (`create_items_standard`/`create_items_options`) com ela pré-selecionada —
  **essas telas eram rotas órfãs** (nenhuma navegação chegava nelas) até
  2026-07-14; lá há criação por modal, edição (nome/qtd/preço/vínculos) e a
  listagem com os modelos vinculados.
- **Proposta (`create_proposal`/`view_edit_proposal`):** seção "Itens de série"
  do avião selecionado + opcionais filtrados pelo avião (via view). Trocar o
  avião invalida os caches (`optionalItemsByCategory`, `seriesItemsFuture`).
  No `view_edit_proposal`, o filtro valida o `aircraftId` com regex de UUID
  (armadilha do placeholder "Não cadastrado").
- **PDFs (proposta E contrato):** itens de série saem sob a aeronave com
  "Incluso" no preço (não somam no total). No contrato, Custo Bancário
  (US$ 2.500) e Pagamento Caução (US$ 10.000, nota de reembolso) são linhas
  separadas e informativas — fora de qualquer soma.
- **Armadilha corrigida (e a caçar em outras telas):** um único
  `requestCompleter` compartilhado entre categorias fazia toda categoria
  mostrar os itens da primeira que renderizasse — o cache tem que ser POR
  chave (`itemsByCategory`), como em `create_proposal`.
- `qty` e `created_by` de `aircraft_items` são NOT NULL **sem default** —
  inserts novos têm que mandá-los (`active`/`deleted` têm default).

### Contrato (`view_contract`) — preenchimento e exibição

- **Termos de Contrato:** os rótulos vêm do template (`contract_terms.terms`) e
  são FIXOS na UI (`_TermsFillIn`) — o usuário só preenche o valor de cada
  linha; `_composeTerms()` remonta "rótulo: valor" na hora do Gerar PDF (nada é
  gravado no banco, como antes). Linha nova no template vira campo novo
  sozinha.
- **Data do contrato:** a RPC devolve timestamp ISO cru; exibir via
  `_formatContractDate` (`dd/MM/yyyy 'às' HH:mm`, local, `tryParse` contra
  placeholder).

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

**Cards da esteira (`view_tracking`).** Cada card mostra os dados **preenchidos**
daquela etapa (campos de `tracking_details` + `user_aircraft` — cor/filtro/painel
da etapa 1), carregados de uma vez e memoizados no model (`extrasFuture`, sem
`FutureBuilder` por card) e renderizados 2 por linha. **Cor do card (regra de
2026-07-15, vale para toda etapa com campos e SOBREPÕE o selo "Concluído"):**
neutro = nunca preenchido; **vermelho** = começou e falta algo; **verde** = tudo
preenchido. A conta é do getter `_completion` (`_TrackingCard`): texto conta
preenchido quando não-vazio; booleano-**tarefa** (pagou/assinou/enviou) conta
feito só com `true` (`false` = respondido "Não" = começado e pendente; `null` =
nunca respondido); booleano-**resposta** (tem radar? benefício?) conta
preenchido com qualquer resposta. A etapa 10 (order 9) é condicional: a
documentação `fin_*` só entra na conta quando `payment_method='financiamento'`.
Checklists de documentos (order 16 = 18 itens, order 18 = 11 itens) seguem a
mesma regra via `_checklist`; etapas sem campos (links/entrega) ficam verdes
quando `isCheck`. `order` é 0-indexed (`TrackingDescription[order]`); a UI
mostra `Etapa order+1`.

Fluxo de venda: `leads` → `proposal` (+ `proposal_item`, `proposal_financing`)
→ `contract` (+ `contract_terms`) → `sales` → `tracking` por aeronave
(`user_aircraft`). PDFs em `lib/custom_code/actions/generate_*_pdf.dart`
(libs `pdf` + `printing`).

**PDFs — regras de dinheiro (cliente, 2026-07-15).** TODO valor monetário dos
PDFs (proposta e contrato) arredonda **sempre para cima na unidade inteira**
($ 1.138.684,91 → $ 1.138.685,00). A regra vive nos formatadores
(`formatCurrency`/`_formatCurrency*`) e no `roundUp` de cada arquivo — valor
novo no PDF deve passar por eles, nunca por `NumberFormat` inline (dois
escaparam no contrato e foram corrigidos). Na tabela CONDIÇÕES DE PAGAMENTO
da proposta: SALDO = bem − entradas; RISCO PAIS = prêmio; TOTAL FINANCIADO =
saldo + risco país (crédito total) — os três já estiveram rodiziados entre os
rótulos; DEPOSITO TOTAL = entrada + depósito saldo (% dinâmico no rótulo).

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
- **Cache do `main.dart.js`:** ao testar mudança no web **local**, hard-refresh
  (Cmd+Shift+R) — senão você vê o bundle antigo. (Em dev/`flutter run` o service
  worker nem é registrado; o cache aqui é o do navegador.)
- **Service worker se auto-atualiza pós-deploy (não precisa hard-refresh em
  produção).** O SW gerado pelo Flutter, por padrão, fica "waiting" até **todas**
  as abas fecharem — então um deploy novo só aparecia após hard-refresh manual, e
  já causou falsos "o Vercel está na versão antiga" (o servidor estava certo; o
  navegador é que servia o SW velho). Resolvido em duas pontas: o
  `deploy-vercel.yml` **injeta `self.skipWaiting()` + `clients.claim()` no
  `build/web/flutter_service_worker.js`** (passo "Service worker assume na hora",
  só anexa listeners — não mexe no mapa `RESOURCES`/hashes), e o `web/index.html`
  **recarrega a página uma vez no `controllerchange`** (com guarda contra a
  primeira instalação e contra loop). Resultado: deploy novo aparece sozinho no
  próximo carregamento. **Não remova** nenhuma das duas pontas — sem o
  `skipWaiting` o `controllerchange` não dispara; sem o reload do `index.html` o
  SW troca mas a aba aberta segue com o bundle antigo. Pra saber qual commit está
  no ar, o build injeta o short-SHA (`__AGSUR_BUILD_ID__`) no `index.html`
  publicado — `curl -s painel-agsur.vercel.app/index.html | grep -o '<short-sha>'`.

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

- **Domínio `painel.agsurbrasil.app`:** DNS no GoDaddy (nameservers
  `domaincontrol.com`), CNAME `painel` → `52bd46848322ad47.vercel-dns-017.com`
  (projeto Vercel `painel-agsur`). O MESMO domínio tem os registros de e-mail
  do Resend (`send.painel...`, `resend._domainkey.painel...`) — ao mexer num
  conjunto, não tocar no outro. Incidente 2026-07-15: na configuração do
  Resend o CNAME do site foi removido sem querer no GoDaddy e o painel saiu
  do ar (diagnóstico: `dig painel.agsurbrasil.app A/CNAME` vazio + serial SOA
  do dia). E-mail transacional sai pela Edge Function `send-credentials-email`
  (remetente `acesso@painel.agsurbrasil.app`).
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
