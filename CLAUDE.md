# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este repo

**`agsur` — painel administrativo Agsur** (Flutter web, deploy Vercel;
produção em **`painel.agsurbrasil.app`**, com `painel-agsur.vercel.app` como
endereço alternativo). Gerencia leads, vendedores, propostas, contratos,
oficina, esteira de importação ("tracking"), funcionários, taxas de
financiamento.

**Desde 2026-08-12 o mesmo código também é publicado como app de loja**
(Android + iOS, `com.agsur.painel`) — ver "Build mobile / lojas". **Web é a
produção viva; mobile é alvo adicional do mesmo `lib/`.** Toda mudança precisa
compilar nos dois.

Este repo também contém:

- `supabase/` — schema versionado (migrations, RPCs, RLS) **compartilhado
  com o agsur-app** (cliente final). DDL é fonte da verdade pra ambos.
- `.github/workflows/` — CI: `flutter-analyze`, `supabase-db-check`, `rls-smoke`
  e `deploy-vercel` (o único caminho de deploy do painel — ver o aviso em
  "Build de produção").
- `RUNBOOK.md`, `SECURITY.md`, `supabase/DASHBOARD_TIER2_TODO.md` — operação.
- `STORE_LISTING.md` — textos, Segurança de dados e conta de revisão das lojas.

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

# Igual ao CI (flutter-analyze.yml). `flutter analyze` puro cospe milhares de
# info/warning de código gerado pelo FlutterFlow — só ERROR é regressão real.
flutter analyze --no-fatal-infos --no-fatal-warnings

flutter test                                 # todos (o CI roda isto também)
flutter test test/jwt_utils_test.dart        # arquivo único
flutter test --plain-name "recompra"         # um caso por nome

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
> Já derrubou o painel 4 vezes.
>
> A guarda é `"git": {"deploymentEnabled": false}` no `vercel.json` (versionada,
> sobrevive a mexida no dashboard). **Não remova.** Ela não afeta o
> `vercel deploy --prebuilt` do CI, só o auto-deploy por push.
>
> Diagnóstico e conserto do 404: `RUNBOOK.md` §12.1.

### Build mobile / lojas (desde 2026-08-12)

O mesmo `lib/` vira app Android e iOS, **`com.agsur.painel`** nas duas lojas.
Textos, Segurança de dados e conta de revisão: `STORE_LISTING.md`.

```bash
flutter build appbundle --release --dart-define=APP_ENV=production  # Play (.aab)
flutter build ios --release --no-codesign                            # só compilar

# archive assinado (o time PRECISA vir na linha de comando: o pbxproj não tem
# DEVELOPMENT_TEAM, e o CODE_SIGN_IDENTITY dele venceria um xcconfig)
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath "$PWD/build/Runner.xcarchive" archive \
  DEVELOPMENT_TEAM=XYYV8DTFFV CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates
```

> ⚠️ **Nunca importe `package:web` (nem `dart:html`/`dart:js`) direto em
> `lib/`.** É web-only e quebra o build mobile lá no kernel snapshot, com um
> erro que não menciona a plataforma (`The getter 'toJS' isn't defined for the
> type 'String'`, apontando para dentro do pacote). Foi exatamente o que
> impediu o primeiro build de loja. O padrão é o de
> `abrir_pdf_gerado.dart`: API neutra no arquivo principal + import condicional
> `import 'x_io.dart' if (dart.library.js_interop) 'x_web.dart';`, com o stub
> io compilando fora do navegador. **Web continua sendo a produção viva** —
> mudou algo aqui, rode `flutter build web --release` também.

**Nome do app mora em 4 lugares e o FlutterFlow reverte 3 deles.** O nome é
**`Agsur Painel`** em todos; o valor original gerado (`AGSur - BackOffice`)
aparecia sob o ícone e não batia com a ficha das lojas:

- `ios/Runner/Info.plist` → `CFBundleDisplayName` **e** `CFBundleName`
- `android/app/src/main/AndroidManifest.xml` → `android:label`
- ficha do Play e do App Store (essas duas só mudam pelo console)

Depois de uma regen, confira os três do código antes de gerar release.

**Ícone: o iOS estava com o logo do Flutter.** Os 15 arquivos do
`AppIcon.appiconset` eram o padrão do FlutterFlow — inclusive o de 1024, que é
o que a Apple mostra na ficha (reprovação garantida). O Android já tinha a
marca nos mipmaps; só o iOS ficou para trás. Regenerados em 2026-08-12 a partir
de **`web/icons/Icon-512.png`**, que é a única arte quadrada da marca no
projeto. Duas consequências para quem mexer nisso:

- **A fonte tem 512px e o iOS precisa de 1024** — o atual é upscale 2× (LANCZOS)
  e fica visivelmente macio de perto. Se aparecer o original em vetor ou 1024+,
  vale regerar.
- **iOS não aceita alpha**: achate sobre `rgb(27,27,26)`, que é a cor do canto
  interno da arte, senão a silhueta arredondada aparece contra o fundo.

**Assinatura iOS.** `DEVELOPMENT_TEAM=XYYV8DTFFV` e `CODE_SIGN_STYLE=Automatic`
ficam em `ios/Flutter/Debug.xcconfig` e `Release.xcconfig` — sem isso o build
para device físico falha pedindo time. O `pbxproj` não tem `DEVELOPMENT_TEAM`,
então o xcconfig vale; mas ele **tem** `CODE_SIGN_IDENTITY`, que vence xcconfig
— por isso o archive passa o time pela linha de comando também.

⚠️ **`MinimumOSVersion 14.0`**: o upload de 2026-08-12 passou com aviso — a
partir da primavera de 2027 a Apple exige 15.0. É trocar `IPHONEOS_DEPLOYMENT_TARGET`
e o `platform :ios` do Podfile.

**Assinatura Android.** `android/key.properties` + `android/app/key.jks` (alias
`upload`, os dois fora do git e com `chmod 600`). O `build.gradle` usa a chave
de release quando o `key.properties` existe e cai na de **debug** quando não —
isso deixa `flutter run --release` funcionando em clone novo/CI, mas **um .aab
assim é recusado no upload**. Confira antes de subir:

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab META-INF/UPLOAD.RSA | keytool -printcert
# esperado: CN=Agsur Painel  ·  SHA1 DB:B9:C8:1A:18:66:46:40:DC:78:1C:94:50:2C:A9:93:78:8A:75:1C
```

Perder o `key.jks` impede atualizar o app — o Play App Signing reduz o estrago,
não elimina. Backup fora da máquina.

**Identidades (não confundir com as vizinhas na mesma conta):**

| | Onde | Detalhe |
|---|---|---|
| Play | conta `Vinicius Moreira` (`6549776849384192904`) | app `4972837200360954328`; é a mesma conta do `com.agsur.clientapp` (AEROTG) |
| Apple | time **`XYYV8DTFFV`** (vicente el khatib roriz) | App ID e app do ASC criados lá; o AEROTG também mora nesse time |

⚠️ O Apple ID usado tem 4 times (Busca Moto Brasil, Rinovva, TN Vet e o
individual). **O portal e o App Store Connect voltam sozinhos para outro time**
— o ASC chega a avisar "sua sessão foi encerrada em X e iniciada em Y", e abrir
uma segunda aba do ASC basta para virar o time da sessão inteira. Confira o
cabeçalho **imediatamente antes** de criar qualquer coisa.

⚠️ **O Xcode 26 migrou o projeto iOS para o ciclo de vida UIScene** no primeiro
build (mexeu em `ios/Runner/AppDelegate.swift`, `Info.plist` e
`Runner.xcscheme`). Uma regen do FlutterFlow pode desfazer isso e voltar a
quebrar o build iOS.

**Screenshots: o mesmo arquivo NÃO serve para as duas lojas.** As capturas do
simulador saem em **1320×2868**, que é exatamente a especificação de 6,9" da
Apple — mas dá proporção 1:2,17, e o **Play recusa acima de 9:16** (1:1,78).
Para o Google é preciso completar a largura para 1614×2868 (barras na cor de
fundo do app), senão o upload é rejeitado.

**Data safety do Play: use o CSV, não o formulário.** A tela tem
`Export to CSV` / `Import from CSV`, e o importador **valida antes de aplicar**
(foi ele que apontou os erros de dependência entre perguntas). Clicar no
formulário é onde se erra: os grupos de rádio ficam duplicados no DOM e é fácil
desmarcar a pergunta principal sem ver — duas vezes cheguei a uma prévia
dizendo "este app não coleta dados do usuário", que é falso e motivo de remoção.
O CSV preenchido de 2026-08-12 está versionado em
`store/play-data-safety.csv`; na próxima mudança de coleta, edite e reimporte.
**Sempre confira o Preview antes de salvar.** (Em `store/` também mora o
`play-icon-512.png` já sangrado para o Play.)

> ⚠️ **Existe conta e dado fictício EM PRODUÇÃO por causa das lojas.**
> `revisao.loja@agsurbrasil.app` (uid `a4d4a9a8-…b546`) foi criada em
> 2026-08-12 como credencial para os revisores da Apple e do Google, e está
> com perfil **Admin Master** — o Play exige declarar que a credencial dá
> acesso total, e Vendedor não dava. Junto vieram 4 leads, 3 propostas, 3
> financiamentos e 3 empresas fictícios (CPF `111.111.111-11`, e-mails
> `@exemplo.com.br`), porque as telas vazias não rendiam screenshot nem
> revisão. **Não é dado de cliente e não deve ser tratado como tal.** Depois da
> aprovação, decidir: rebaixar/excluir a conta (`admin_delete_app_user`) e
> marcar o dado como `is_deleted`, ou manter como ambiente de demonstração.

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

### Onde mora cada tela — layout do `lib/`

Não é um layout único: as telas estão divididas em dois lugares por motivo
histórico, e o nome da pasta do design system quase colide com o do `agsur-app`.

- **Funil / CRM → `lib/<feature>/`, na raiz do `lib`.** `leads/`, `clients/`,
  `proposal/`, `contract/`, `sellers/`, `rates/`, `employees/`, `oficina/`.
  Padrão de cada uma: `<feature>/` (listagem) + `view_edit_<feature>/`
  (detalhe/edição) — ex. `lib/leads/leads/` e `lib/leads/view_edit_lead/`. O
  `contract/` foge um pouco (`contracts/`, `view_contract/`,
  `create_contract_terms/`, `view_edit_contract_terms/`).
- **Telas herdadas do FlutterFlow → `lib/pages/`.** `aircrafts`, `tracking`,
  `users/pilot`, `chat`, `guarantes` (sic), `profile`, `items`, `parts_quote`,
  `service_offering`, `authentication`, `home/home_page` (o **dashboard**) e 4
  `modal_*` de raiz (`modal_create_available_aircraft`, `modal_edit_company`,
  `modal_register_company`, `modal_tracking`). Procurar uma tela do funil aqui
  não acha nada.
- **⚠️ `lib/pages/shared/` é onde mora quase tudo que este doc cita pelo nome.**
  Antes de sair procurando um `modal_*` na raiz de `pages/`, olhe aqui: `menu/`
  (o menu por perfil), os diálogos (`confirm_delete_dialog`,
  `cancel_contract_dialog`, `edit_email_dialog`, `alert_dialog`,
  `custom_snac_bar`), os cadastros (`modal_create_client`,
  `modal_register_pilot/seller/collab/lead/note/address`, `register_oficina`,
  `modal_certificate*`, `modal_services_offering`), os seletores
  (`client_multi_select`, `aircraft_multi_select`, `linked_clients_section`) e
  os empty states.
- **Design system: `lib/core_ui/`** — ⚠️ **no `agsur-app` é `lib/core/ui/`.**
  São projetos e pastas diferentes; ao pular de um app para o outro é fácil
  importar/procurar no caminho errado. Aqui ficam `AppModal`,
  `AppListScaffold`, `AppDetailsScaffold`, `ResponsiveRow`, `app_shell.dart`
  (`kSidebarBreakpoint`), `app_responsive.dart` (`kStackBreakpoint`) e o
  `query_cache.dart` (ver "FutureBuilder" em Convenções).
- **`lib/security/` guarda mais do que o nome sugere** — além de
  `access_control.dart`, `jwt_utils.dart` e `password_utils.dart`, mora ali o
  cross-cutting de UX/fluxo: `action_feedback.dart` (padrão de feedback de
  escrita), `credentials_email.dart` (chamada da Edge Function) e
  `stuck_email.dart` (autocura do 422). Antes de escrever helper novo desse
  tipo, olhe aqui.
- **Gerado/intocável:** `lib/flutter_flow/`, `lib/backend/supabase/database/` e
  `lib/backend/schema/` (structs/enums/util do FlutterFlow) — ver "Stack".
  `lib/custom_code/actions/` são as actions custom do FlutterFlow — é onde vive
  o `abrir_pdf_gerado.dart`. `lib/components/` tem só o widget de notificações.

### Backend Supabase

Toda persistência e auth vão direto ao Supabase via `supabase_flutter`. Não há
camada de API própria além de algumas chamadas REST diretas em
`lib/backend/api_requests/api_calls.dart` (ex.: `signup` chamando `/auth/v1/signup`
para criar usuários sem deslogar o admin; `ViaCepCall` para autofill de CEP).

**E-mail preso no auth — o fluxo é auto-curativo, não reimplemente.** Quando o
signup recusa um e-mail e não há cadastro ativo para reusar,
`lib/security/stuck_email.dart` chama a RPC `admin_release_stuck_email`
(`20260722201000`, libera SÓ conta excluída ou órfã — ativa retorna `'ativo'` e
não é tocada) e repete o signup **uma vez**. Já ligado na conversão
(`view_edit_proposal`) e na criação manual (`modal_create_client`); fluxo novo
que crie usuário deve passar por ele. O `catch` da conversão faz rollback
best-effort com `admin_purge_orphan_auth_user` para não deixar órfã nova.
Diagnóstico quando ainda assim falhar: `RUNBOOK.md` §13.

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

**E-mail editável no funil (2026-07-17/18).** Decisão de UX do cliente: **UMA
forma de editar por tela** — sem lápis avulso ao lado do texto; o e-mail vive
dentro do formulário/modal que a tela já tem.

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
  `sendCredentialsEmail`. **Cliente já existente = reuso COM regras
  (2026-07-29):** o lookup é case-insensitive (`ilike` + `is_deleted=false`),
  `createUserPublic` é zerado a cada conversão (senão um resíduo do model
  roubava o `user_Id` do contrato), e se o signup recusar por conta já
  existente (422 ou 200 "ofuscado"), re-busca o users. O que acontece com o
  cliente encontrado é decidido por `decideClientReuse`
  (`lib/backend/client_reuse.dart`, pura, testada em
  `test/client_reuse_test.dart`) e aplicado por `_applyClientReuseDecision`
  nos DOIS pontos de reuso: **mesmo lead** → recompra, segue como sempre;
  **cliente sem lead vinculado** → reusa e grava `users.lead_id` (sem isso o
  lead nunca sai do funil — se a RLS bloquear o UPDATE, que hoje é só de
  master, a conversão segue com aviso em vez de abortar); **cliente de OUTRO
  lead** → **bloqueia** com o nome do cliente (o contrato sairia no cadastro
  de outra pessoa — caso real "Maria Silva", bug reportado pelo dono em
  27/07); **e-mail de quem não é Cliente** (perfil de painel/piloto/oficina)
  → bloqueia. Reuso silencioso não existe mais.
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
  desync silencioso com o auth. O campo de e-mail do lead é digitável direto
  (era `readOnly` com fill claro `0x72FFFFFF` + texto `primaryText` preto —
  nesta tela cinza claro = travado; ao destravar um campo, troque fill para o
  padrão e texto para `secondaryBackground`).
- **Oficina e Piloto NÃO têm troca de e-mail.** A RPC atômica
  `admin_update_client_email` **recusa perfil que não seja Cliente**, e gravar
  só em `public.users` desligaria a pessoa do próprio login. Por isso o campo é
  somente leitura em `oficina_details` — não o destrave sem antes estender a
  RPC; campo editável prometeria o que o save não pode cumprir.
- **Dados cadastrais do cliente (2026-07-18, `view_edit_client`):** Nome,
  Sobrenome, CPF e Empresa também editáveis para `canEditFunil` (cinza
  travado para os demais — fill/cor condicionais no padrão do e-mail). O
  "Atualizar dados" grava no lead E espelha em `users`
  (name/lastname/cpf/fullname/phone) para listas e PDFs continuarem
  consistentes. Cada campo lê o SEU controller (city/state já leram
  Empresa/Cargo por engano — cuidado ao mexer).

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

DDL agora vive **versionado no git** em `supabase/migrations/` (**60 arquivos**,
último `20260728123000`). Em 2026-07-14 o histórico
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
  ⚠️ As policies `all_access` permissivas ficaram para trás nesse batch e só
  saíram em `20260728122000` — ver o lote de 2026-07-28 abaixo.

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
- **Achados da auditoria de 2026-07-28 (4 migrations).** Vale ler os cabeçalhos:
  cada uma traz o rollback comentado e o roteiro de validação.
  - `20260728120000` (baixo risco): **`chat_participants.thread_id` virou
    imutável** — a policy de UPDATE só validava `user_id = auth.uid()` e, como a
    PK é `(thread_id, user_id)`, dava para mover a própria participação para a
    DM alheia. **RLS não expressa "coluna imutável"** → a correção é *grant por
    coluna* (só `last_read_at` é atualizável). Também: revoke de `anon` em 6
    funções esquecidas, `get_proposal_details` recuperando
    `SECURITY`/`search_path` perdidos num `CREATE OR REPLACE`, e
    `security_barrier` nas 5 views definer de autorização.
  - `20260728121000` (**muda autorização**): armou o UPDATE da
    `tg_users_block_privilege_escalation` — ver RBAC abaixo.
  - `20260728122000`: derrubou as **5 policies `all_access` residuais** de
    `storage.objects`. Uma delas era `SELECT TO public` com `USING (true)`, o
    que tornava `chat-attachments` e `pdfs` (ambos `public=false`) baixáveis
    **sem login** com a anon key — policy permissiva se combina por OR, então
    bucket privado não fechava nada enquanto ela existisse.
  - `20260728123000`: as 2 funções que o revoke de `...120000` não pegou — ver
    "as DUAS metades do revoke" logo abaixo.

Status atual completo + smoke tests em `supabase/README.md`. Pendências
manuais do dashboard em `supabase/DASHBOARD_TIER2_TODO.md`.

### Grants de função: as DUAS metades do revoke (2026-07-28)

Armadilha que já mordeu duas vezes, em direções opostas. Um grant não substitui
o outro, e `has_function_privilege('anon', ...)` é a única conferência confiável:

- **`REVOKE ... FROM public` NÃO remove o grant direto a `anon`.** O
  `alter default privileges` do Supabase concede EXECUTE a `anon` em toda função
  nova de `public`. Foi o que `20260722202000` corrigiu nas 5 RPCs admin.
- **`REVOKE ... FROM anon` NÃO remove o grant herdado de `PUBLIC`.** Função que
  nunca recebeu o grant direto aparece com ACL `=X/postgres` (grantee vazio =
  PUBLIC) e o `anon` executa por herança. Descoberto em `20260728123000`, ao
  conferir o resultado de `20260728120000`: 2 das 7 funções seguiam abertas.

Receita para fechar de verdade uma função nova:

```sql
REVOKE ALL ON FUNCTION public.<f>(<args>) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.<f>(<args>) TO authenticated, service_role;
```

E confira **no banco**, não no diff (`false` nas duas colunas é o esperado):

```sql
select p.proname, has_function_privilege('anon', p.oid, 'EXECUTE') as anon,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as painel
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = '<f>';
```

⚠️ **Assinatura errada quebra o `db push`.** `purge_security_audit_log` é
`(retention_days int DEFAULT 365)`, não `()` — um `REVOKE ... ON FUNCTION f()`
falha com "function does not exist". Confira a assinatura na migration de origem
antes de revogar.

### Endurecimento de 2026-06-22 — o que ainda condiciona código novo

O registro vivo (o que foi aplicado, o que falta validar em cada app, rollback
de cada view) é o **`SECURITY_AUDIT.md`** — leia lá antes de mexer em view,
policy ou bucket. O que precisa estar na cabeça ao escrever código:

- **Buckets:** as leituras dos 2 apps já passam por `app_storage.dart`
  (signed URL, fallback-safe) — use-o em ponto de leitura novo. **NÃO** privar
  `AGSur`/`service-letters` até a versão mobile com signed URLs estar adotada
  (quebra cliente antigo). Isso é a flag `storage.buckets.public`; a camada de
  **policy** de `storage.objects` é outra coisa e já foi fechada por
  `20260728122000` — quem protege `chat-attachments`/`pdfs` são as policies.
- **MFA:** descartado por decisão de produto; a infra server-side
  (`custom_access_token_hook` + `ENFORCE_MFA_ADMIN_MASTER`) segue **OFF**.
- **Reauditar:** skills `agsur-security-audit` / `db-migration-security-review`
  e agentes `supabase-security-auditor` / `flutter-client-security-reviewer` /
  `security-remediation-engineer` em `.claude/` (rodar de dentro de
  `agsur-main/`).

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
documentacao/funil`, `tg_block_edit_when_soft_deleted`).

**`tg_users_block_privilege_escalation`: UPDATE armado em `20260728121000`.**
Enquanto ela ficou neutralizada, nada guardava as colunas de privilégio: a
policy `user_security_update` libera a própria linha sem restrição de coluna,
então um Cliente/Piloto/Oficina logado no app fazia
`PATCH /rest/v1/users?id=eq.<próprio> {"profile_type":"Admin Master"}` e virava
master na requisição seguinte (precedente real: `20260508120700`). Hoje a
função usa `auth_is_service_request()` no ramo de UPDATE — auto-edição não muda
nenhum campo de privilégio, editar terceiro exige papel de painel e só master
mexe em `profile_type`/`is_admin`/`access_level`. **O bypass antigo continua de
propósito em INSERT/DELETE** (fluxos de criação ainda não reconciliados), assim
como nas `tg_*_ownership`; `tg_require_service_role` (gate do audit log)
precisa do bypass por `current_user`. ⚠️ Personificação via Management
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
  siga.
- **Cobertura:** as 26 escritas das telas do funil (2026-07-14) e as 22 telas de
  escrita varridas em 2026-07-28 estão cobertas — 4 delas por `checkWrite` em
  vez do `guardWrite`. Tela nova de escrita entra nessa conta.

### Feedback ao usuário — `action_feedback` (2026-07-20)

Complemento do `write_guard`: aquele pega o bloqueio **silencioso** da RLS
(2xx com 0 linhas); este pega a exceção que **ninguém pegava**.

Os `confirmBtnAction`/`onPressed` eram `() async {}` sem try/catch. Uma exceção
subia pelo callback assíncrono, o `Navigator.pop` nunca rodava e o diálogo
ficava aberto com o botão girando, sem mensagem — o sintoma que o usuário
descrevia como "não sai daí". Aconteceu na exclusão de vendedor/oficina/
piloto/cliente (a RPC `admin_delete_app_user` LANÇA para quem não é Admin
Master), na criação de proposta e na conversão.

- `runAction(context, action:, success:, failure:, dialogContext:, contexto:)`
  de `lib/security/action_feedback.dart` garante: o diálogo fecha nos DOIS
  caminhos, aparece mensagem em pt-BR nos dois, e o erro técnico vai para o
  Sentry (com tag `acao`) em vez da tela. `runActionWithResult<T>` para quando
  a ação produz algo (ex.: preview de impacto antes de excluir).
- `mensagemDeErro(e, fallback:)` traduz os códigos do Postgres — `42501`,
  `23505`, `23503`, `23502`, `22P02`, `PGRST116` — mais rede caída e
  "Null check operator". **Mensagem nova de erro entra aqui**, não na tela:
  todas as ações herdam de uma vez.
- Ao escrever uma ação nova: se for UPDATE/DELETE, use `guardWrite` DENTRO do
  `action`. Os dois se complementam e nenhum substitui o outro.

⚠️ **Ordem importa em handler que escreve mais de uma coisa.** Validar TUDO
antes do primeiro insert. A criação de proposta inseria a proposta e só depois
fazia `int.parse(dPDLengthValue!)` do financiamento: sem prazo selecionado, o
`!` estourava e cada tentativa deixava uma proposta órfã (17 acumuladas em
2026-07-20, limpas por soft-delete). A conversão tem 7 escritas encadeadas —
falha no meio deixa contrato sem venda ou aeronave sem esteira.

### Exclusão em cascata no funil (2026-07-20)

**Não existe `ON DELETE CASCADE` que resolva** — das tabelas do funil, só
`leads.is_deleted`, `proposal.is_deleted` e `user_aircraft.deleted` têm
soft-delete. `contract`, `sales`, `financial`, `tracking`, `company` e `notes`
**não têm**. A "exclusão" é uma combinação de marcações:

- `proposal.is_deleted = true` some com a proposta **E com o contrato** de
  graça, porque a `vw_contract_data` filtra por essa coluna. É por isso que
  "excluir contrato" só pode significar marcar a proposta.
- **`tracking` é a exceção:** a `vw_all_tracking` NÃO filtra nada, então a
  esteira só some **apagando** as linhas (`tracking` + `tracking_details`).
  Irreversível — mas as 21 etapas são regeneráveis pelo template.

`lib/backend/cascade_delete.dart` levanta o impacto antes (`previewLeadDeletion`
/ `previewProposalDeletion`) e executa (`executeCascadeDelete`); a modal
`confirm_delete_dialog` mostra o que será atingido. Ela avisa também quando o
lead já virou cliente — aí a exclusão tira do cliente o acompanhamento no app.

### Cancelamento de contrato (2026-07-20)

**Contrato não se exclui — se cancela.** Exclusão apagaria a venda do
histórico; o cancelamento preserva o registro e acrescenta motivo, autor e
data. O contrato continua na listagem com o selo "Cancelado".

- Migration `20260720120000`: `contract` ganha `cancelled_at`, `cancelled_by`,
  `cancellation_reason`, `cancellation_note` + CHECK dos motivos fechados +
  CHECK de coerência (ou cancelado com data E motivo, ou nada).
- As colunas vão em `contract` (quem é cancelado é o contrato; a proposta segue
  válida). Como a `vw_contract_data` é construída sobre `proposal`, ela passa a
  fazer `LEFT JOIN contract` — **colunas só acrescentadas no fim**, senão o
  `create or replace view` recusa. O `security_invoker=on` é reafirmado.
- Motivos são conjunto fechado para render relatório. O enum
  `MotivoCancelamento` (Dart) espelha o CHECK — **mexeu num, mexa no outro**.
- Os getters de cancelamento em `vw_contract_data.dart` foram escritos à mão:
  uma regen do FlutterFlow os apaga e o selo some da listagem.
- **Não há tela para descancelar.** A modal de confirmação diz isso.

### Listagens do funil — tabela e paginação (2026-07-20)

Leads, Propostas, Contratos e Clientes usam `AppDataTable` (colunas, seleção
múltipla, exclusão em lote) + `AppPagination`, com paginação **no servidor**
(`queryPage` em `lib/backend/paged_query.dart`: `range` + `count=exact`).

- `queryPage` mora em `lib/backend/` e **não** em
  `lib/backend/supabase/database/table.dart` de propósito: aquele arquivo é
  gerado pelo FlutterFlow e uma regen apagaria o método.
- ⚠️ **Com paginação no servidor, todo filtro tem que ir no `queryFn`.**
  Filtrar em Dart depois filtra só a página corrente — a busca "não acha"
  registros das páginas seguintes e o total mente. Vale para a busca
  (`orIlike` monta o `or=(col.ilike.*q*,…)`), para o `is_contract` de Contratos
  e para a exclusão dos leads já convertidos.
- Trocar de página **limpa a seleção**: ela guarda ids da página anterior, e a
  exclusão em lote apagaria o que não está na tela.
- Exclusão em lote passa linha a linha pelo `guardWrite` (ou pela RPC, em
  Clientes) e reporta o resultado honesto — "3 excluído(s), 2 sem permissão"
  em vez de sucesso falso.

### Lead vira cliente (2026-07-20)

Quando a proposta vira contrato, o lead passa a ser cliente e **sai da lista de
Leads** — mas o registro em `leads` NÃO é apagado nem marcado. Ele é a chave de
autorização do app cliente: `auth_owns_proposal` e `auth_owns_user_aircraft`
(SECURITY DEFINER) fazem `JOIN leads ON lead_id` comparando
`lower(l.email) = lower(auth_user_email())`. Sumir com ele tira do cliente o
acesso à própria aeronave.

A classificação é derivada de `users.lead_id` em `lib/backend/lead_conversion.dart`
(nada é gravado no lead) e o cache é invalidado na conversão. É também o que
viabiliza a **recompra**: o seletor de "Cadastrar proposta" lista Leads E
Clientes com etiqueta; escolher um cliente resolve para o `lead_id` dele, então
a proposta nasce ligada à mesma pessoa e a conversão reaproveita a conta.

⚠️ **Todo caminho que cria/reusa cliente TEM que garantir o `users.lead_id`**
— é o único vínculo que tira o lead do funil. Já falhou de dois jeitos
(descobertos 2026-07-29, vídeo do dono): o `modal_create_client` inseria o
cliente **sem** `lead_id` (corrigido — hoje grava e invalida o cache), e o
reuso na conversão pulava a gravação (corrigido via `client_reuse.dart` — ver
"Na conversão" acima). Cliente novo por outro fluxo? Grave o `lead_id` e chame
`LeadConversion.invalidate()`.

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
  sozinha. Desde 2026-07-22 os termos **não saem mais no PDF do contrato**
  (vão para a CPI, pendente) — mas o fluxo de preenchimento continua.
- **Data do contrato:** a RPC devolve timestamp ISO cru; exibir via
  `_formatContractDate` (`dd/MM/yyyy 'às' HH:mm`, local, `tryParse` contra
  placeholder).
- **⚠️ Proposta sem `proposal_financing` NÃO pode quebrar a tela.** 21 das 48
  propostas (medido 2026-07-22) não têm financing row — o fluxo de criação
  permite pular o financiamento. Três null-checks de build deixavam a página
  inteira cinza (fix 2026-07-22): os campos degradam para 0 e o lápis de
  editar financiamento / Gerar PDF avisam com mensagem em vez de estourar.
  Código novo nesta tela deve usar `containerProposalFinancingRow?.` sempre.
- **Vínculo contrato ↔ unidade do estoque (2026-07-22):** seção "Aeronave do
  estoque" (`contract_aircraft_unit_section.dart`, widget próprio fora do
  código FF) grava `contract.available_aircraft_id` (migration
  `20260722130000`). Regras: uma unidade por contrato ATIVO (índice único
  parcial; cancelamento libera), `ON DELETE SET NULL`, botões gated por
  `typeAccess == 'edit'` (canEditFunil), status da unidade no estoque segue
  manual. Proposta sem contrato não mostra a seção. Violação 23505 é traduzida
  para "unidade já vinculada a outro contrato ativo".

### Estoque de unidades (`available_aircrafts`)

- **A coluna `aircraft_model` guarda o ID do catálogo (`aircrafts.id`), não o
  nome** — é o que o create insere e o que `fn_available_aircrafts` resolve
  para nome na listagem. Um comentário antigo no modal dizia o contrário e
  causou o bug de 2026-07-21: o dropdown de modelo abria vazio no editar e
  salvar sem re-selecionar morria em null-check. O modal agora pré-carrega da
  própria row e casa por id OU nome (tolerância a dado legado).
- Criar/editar/excluir unidade seguem o padrão `action_feedback`/`guardWrite`
  (a tela ficou fora da varredura de 2026-07-20 e foi coberta em 2026-07-22).

### Chat interno do painel (`20260628120000_panel_chat.sql`)

DM 1:1 **entre usuários do painel apenas** (`Admin Master`/`Admin`/`Vendedor`
ou `is_admin`); Cliente/Piloto/Oficina estão fora de escopo. Telas em
`lib/pages/chat/{chat,chat_detail}`, no menu para quem tem acesso.

- Tabelas: `chat_threads`, `chat_participants` (membros + `last_read_at`),
  `chat_messages` (texto e/ou anexo).
- **Thread e participante só nascem pela RPC `chat_get_or_create_dm(uuid)`**
  (definer) — não há policy de INSERT nessas duas tabelas.
- Leitura via helper `chat_is_member(thread)` (definer, evita recursão de RLS)
  combinado com `auth_is_seller_or_admin()`.
- Anexos no bucket privado `chat-attachments` (image/* + PDF), com a **pasta =
  `thread_id`** e as policies de storage amarradas à participação.
- ⚠️ O UPDATE de `chat_participants` é **grant por coluna** (só `last_read_at`)
  desde `20260728120000` — ao mexer nessa tabela, não tente expressar a
  imutabilidade do `thread_id` em RLS; ela não sabe fazer isso.

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
**EXCEÇÃO (cliente, 2026-07-21): a tabela de parcelas do plano NÃO arredonda**
— crédito total (já arredondado) ÷ N e juros sobre o saldo exato, centavos
reais via `formatCurrencyExact`. Arredondar cada linha desalinharia a soma das
parcelas do crédito financiado.

**PDF da proposta — layout (colagem do cliente, 2026-07-21/22).** 3 páginas:
1 = invoice/itens; 2 = plano de financiamento **completo num único A4**
(info de crédito + detalhamento, parcelas 1–14, CONDIÇÕES DE PAGAMENTO com
depósitos 5%/10%/15%, informações bancárias, SUBTOTAL/INVOICE TOTAL + nota do
depósito) — linhas em `_densePad` e margem 18 para caber; validado com render
real; 3 = termos de pré-compra. A antiga página avulsa de "Condições de
Pagamento" e a tabela CONDIÇÕES DE FINANCIAMENTO **não existem mais** (saíam
duplicadas). "% TOTAL DE ENTRADA" deriva de sinal+depósito — o campo
`percentual_pgto_total` do banco vem 0/null, não usar. No PDF do contrato
(proforma): linha "Deposito Total - 15%" abaixo do Depósito N° 2, e a seção
"Termos do Contrato" **foi removida** — os termos vão passar a sair na CPI
(inclusão futura; `_composeTerms()` e a UI seguem intactos como insumo).

## Convenções

### Flutter

- **Tema/widgets:** seguir o par `*_widget.dart` + `*_model.dart` e usar
  `FlutterFlowTheme.of(context)`; alterações de tema vão em
  `lib/flutter_flow/flutter_flow_theme.dart`, não hardcoded.
- Lints usam `package:flutter_lints/flutter.yaml` com `unnecessary_string_escapes: false`.
- Rodar `flutter analyze` antes de propor mudanças não-triviais — alguns
  arquivos gerados têm warnings tolerados, mas erros novos devem ser corrigidos.
- **Procure `!` isolado em meio a `?.`** — é assinatura de bug nas telas e nos
  geradores de PDF. Num callback assíncrono sem `try/catch`, o null-check
  estoura e **não acontece nada** (sem PDF, sem mensagem: o sintoma "não sai
  daí"). Já mordeu duas vezes: `containerProposalFinancingRow!` no "Gerar PDF"
  de `view_edit_proposal` e `dataCredito!` em `generate_proposal_pdf` — campos
  que o resto do arquivo já tratava como nullable.
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
- **Dado que sobrevive à tela → `QueryCache`** (`lib/core_ui/query_cache.dart`):
  `QueryCache.fetch(key:, ttl:, fetcher:)` cacheia por TTL (padrão 2 min) e faz
  dedupe de requests concorrentes na mesma key. É o certo para dropdown/lista
  repetida entre telas (clientes, vendedores, categorias) — já usado por
  `contracts`, `proposals`, `home_page`, `menu`, `available_aircrafts` e
  `lead_conversion`. Memoizar no model resolve só um `build`; isto atravessa
  navegação. Ao gravar algo que muda o resultado, chame
  `QueryCache.invalidate(key)` (é o que `LeadConversion.invalidate()` faz).

### Flutter web — armadilhas conhecidas

Este build web (CanvasKit) acumulou bugs não-óbvios; cada item abaixo já
quebrou produção:

- **Versão do Flutter pinada em `3.41.9`** nos workflows (`flutter-analyze.yml`
  e `deploy-vercel.yml`, `channel: stable`). O canal stable subiu pra 3.44.0 e
  quebrou o build — não despinar sem rodar `flutter build web --release` inteiro.
- **`Image.asset` não renderiza neste build.** Logos/imagens de asset carregam
  via `rootBundle.load` + `Image.memory` (ver login). `Image.asset` direto sai
  em branco; `cacheWidth`/`cacheHeight` também quebram o render.
- **`Printing.layoutPdf` não funciona em WebKit** (Safari desktop imprime em
  branco de iframe oculto; Safari/Chrome de iOS têm o popup bloqueado após o
  await da geração). PDF novo deve sair por
  `abrirPdfGerado(bytes, nomeArquivo)`
  (`lib/custom_code/actions/abrir_pdf_gerado.dart`): detecta WebKit e baixa o
  arquivo via atributo `download`; demais navegadores mantêm o diálogo de
  impressão (fix 2026-07-22).
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

### Mobile de verdade — o que o web escondia (2026-08-12)

Rodar no simulador iOS pela primeira vez expôs dois problemas que **não
aparecem no web**, porque dependem de barra de status e de tela estreita de
celular. Ao mexer em layout, teste no device, não só no Chrome.

- ✅ **Corrigido — topo desenhava sob a barra de status.** O `body` do
  `AppShell` não tinha `SafeArea`, então o título da página saía escrito por
  cima do relógio do iOS em **todas** as telas. A correção é no `AppShell` (um
  ponto, cobre as 42 telas que usam `AppListScaffold`/`AppDetailsScaffold`) e é
  no-op no web, onde não há inset. Não replique `SafeArea` nas telas.
- ✅ **Corrigido — `AppModal` ignorava o teclado.** O `maxHeight` era
  `size.height * 0.9`, ou seja, a tela **inteira**: com o teclado aberto no
  celular o modal era dimensionado como se ele não existisse, e os campos de
  baixo ficavam atrás do teclado sem rolagem que os alcançasse. Agora desconta
  `MediaQuery.viewInsetsOf(context).bottom` da altura e soma ao padding
  inferior. Atinge os **28 usos de AppModal** (todo cadastro e edição do
  funil). No web é no-op — não há inset de teclado.
- 🔎 **`AppDataTable` no celular: funciona, mas parece quebrado no print.**
  Abaixo de `kStackBreakpoint` a tabela entra num `SingleChildScrollView`
  horizontal com `minWidth`, então as colunas além da primeira ou segunda
  ficam fora da área visível — o print sugere que a listagem está cortada. Não
  está: **a linha inteira é clicável** (`_HoverRow.onTap` → `onRowTap`, que as
  4 listagens do funil passam navegando para o detalhe) e o resto das colunas
  aparece rolando de lado. Melhoria possível (não urgente): virar cartões no
  mobile, para não depender de rolagem horizontal nem de descoberta.

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
  (projeto Vercel `painel-agsur`). ⚠️ O MESMO domínio tem os registros de
  e-mail do Resend (`send.painel...`, `resend._domainkey.painel...`) — ao mexer
  num conjunto, **não tocar no outro** (já derrubou o painel; `RUNBOOK.md`
  §12.2). E-mail transacional sai pela Edge Function `send-credentials-email`
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
