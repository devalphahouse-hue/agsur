# Sprint 1 — Automação de Mensageria & Vínculo de Aeronaves

> Plano de execução. Levantamento feito em 2026-09-08 sobre esta cópia de
> trabalho. Início previsto: **quinta-feira, 2026-09-10**.
> Duração: 1 mês · Parcela 1 (R$ 2.300,00).

---

## ⚡ Quinta-feira — arranque (nesta ordem)

O objetivo do dia 1 é **destravar o prazo externo** e **eliminar o maior risco
não quantificado**, antes de escrever qualquer código de feature.

### 1. Meta / WhatsApp — fazer PRIMEIRO, é o caminho crítico

- [ ] Confirmar se a Agsur já tem **Business Manager verificado**. Se não tiver,
      iniciar a verificação hoje — ela demora mais que a aprovação do template.
- [ ] Criar/anexar o número à WABA.
- [ ] Gerar token de **System User** (⚠️ token de usuário comum expira em 24h e
      quebra o dispatcher um dia depois do go-live).
- [ ] Submeter o template `agsur_lembrete_v1` (UTILITY, pt_BR):

      Olá, {{1}}!
      Lembrete Agsur sobre {{2}}:

      {{3}}

      Em {{4}}. Equipe Agsur.

### 2. Preflight no banco (só leitura)

`npx supabase db query --linked "<sql>"` — sem colar token no chat.

```sql
-- (a) notes.id tem PK? A FK de note_reminders precisa de uma.
select conname, contype, pg_get_constraintdef(oid)
  from pg_constraint where conrelid = 'public.notes'::regclass;

-- (b) vocabulário REAL do estoque -> define o CHECK e os UPDATEs de normalização
select status, count(*) from public.available_aircrafts group by 1 order by 2 desc;

-- (c) capturar as duas funções NÃO versionadas ANTES de encostar nelas
select pg_get_functiondef('public.fn_available_aircrafts'::regproc);
select pg_get_functiondef('public.get_aircraft_details_by_proposal'::regproc);

-- (d) número de viabilidade de 1.1: quantos telefones NÃO viram E.164
select count(*) filter (where length(regexp_replace(phone,'\D','','g')) = 11) as celular,
       count(*) filter (where length(regexp_replace(phone,'\D','','g')) = 10) as fixo,
       count(*) filter (where length(regexp_replace(phone,'\D','','g')) not in (10,11,12,13)) as lixo
  from public.leads;   -- repetir para public.users
```

### 3. Migration de captura (30 min, elimina o maior risco)

- [ ] `…00_capture_unversioned_rpcs.sql` — `create or replace` com o corpo
      dumpado em (c), verbatim. Idempotente, não muda nada, e transforma uma
      edição cega em diff.

### 4. Código que não depende de nada

- [ ] `lib/backend/phone.dart` + `test/phone_test.dart`.

### 5. Antes de confiar no CI

- [ ] `gh secret list --repo devalphahouse-hue/agsur` — enquanto
      `SUPABASE_ACCESS_TOKEN` e `SUPABASE_DB_PASSWORD` não estiverem lá, o
      `db push --dry-run` local é a única validação real.

> ⚠️ **Esta cópia não é git.** Nada aqui vira PR ou deploy — migrations e código
> precisam ir para um clone de verdade.

---

## Contexto

- **1.1 — Mensageria:** greenfield inteiro. Não existe agendamento, fila,
  histórico de envio nem integração de WhatsApp. Nota hoje é só texto num
  `FutureBuilder`.
- **1.2 — Estoque × contrato:** meio construído. O vínculo contrato↔unidade já
  existe (`20260722130000`). Falta destaque, filtro, vínculo na proposta e —
  o mais relevante — **os dados da unidade nunca chegam ao PDF do contrato**.

### Decisões tomadas com o cliente

| Tema | Decisão |
|---|---|
| Provedor | **Meta Cloud API** oficial |
| Acoplamento | Adapter por env `WA_PROVIDER`; fila/histórico/UI não mudam ao trocar |
| Template | **Um** genérico `agsur_lembrete_v1` (UTILITY, pt_BR), 4 variáveis |
| Agendador | **pg_cron + pg_net**, tick de 1 min, segredo no Vault |
| Escopo 1.2 | Completar o spec: proposta + destaque + status + filtro + PDF |
| Prefixo | Nova coluna `registration_prefix` em `available_aircrafts` |
| Destinatário | Cliente (`leads.phone`) · Vendedor (`users.phone` do dono) · Equipe (opt-in) |
| Histórico | Tela própria no menu **+** seção na tela do lead/cliente |
| Quem agenda | Mesma régua da nota: `auth_is_seller_or_admin()` — Vendedor inclusive |

---

## Sete achados que mudam o escopo

1. **⚠️ Meta não aceita texto livre em mensagem ativa.** Só template aprovado
   fora da janela de 24h. Pior: `notes.note` é multi-linha e a Meta **rejeita**
   newline, tab e 4+ espaços seguidos (erro 131009), com corpo limitado a 1024
   chars. O que o cliente recebe **não é** o que a timeline mostra — daí o
   `wa_param()` sanitizador e o preview obrigatório na modal.

2. **⚠️ Telefone não serve para a API.** `leads.phone`/`users.phone` guardam o
   texto mascarado sem DDI (`(11) 9 8888.7777`). Existem **três** máscaras
   (`.`, `-`, e `'(##) #####.####'` em `modal_register_company`) — mas isso é
   **cosmético**: normalizar tira tudo que não é dígito. O problema real é a
   ausência de DDI e o fixo de 10 dígitos.

3. **⚠️ `notes_logs` é tabela fantasma** (tipada só no app, sem DDL, sem call
   site). A real é `public.notes`, e ela só se liga a **lead**.

4. **⚠️ Vocabulário de status quebrado hoje.** Listagem filtra
   `['Todos','Disponível','Vendido','Reservado']`
   (`available_aircrafts_widget.dart:37`); a modal grava
   `['Disponível','Em negociação','Entregue','Vendido']`
   (`modal_create_available_aircraft_widget.dart:59-64`). `Reservado` é
   filtrável e nunca gravável. Consertar é pré-requisito do filtro.

5. **⚠️ Duas RPCs de produção não estão versionadas** — `fn_available_aircrafts`
   e `get_aircraft_details_by_proposal` só existem no banco vivo. É o maior
   risco não quantificado da sprint e custa 30 min para eliminar (§Quinta-feira).
   `get_proposal_details`, ao contrário, **está** versionada
   (`20260714130000:113-260`).

6. **⚠️ O vínculo na proposta reverte uma decisão de 2026-07-21.** O header de
   `contract_aircraft_unit_section.dart:19-21` diz: *"o vínculo é da VENDA, não
   da proposta"*. O spec pede o contrário. É mudança deliberada de regra —
   confirmar com o cliente.

7. **⚠️ Não existe registro de consentimento.** Disparar para lead que nunca
   optou é exposição LGPD e risco de *quality rating* na Meta (bloqueios
   suficientes restringem a WABA e matam a feature para todos). Mitigação barata
   agora: `leads.wa_opt_out boolean not null default false`, respeitado no
   fan-out. Retrofit depois da primeira reclamação sai caro.

### Restrições técnicas

- `lib/backend/schema/structs/` e `lib/backend/supabase/database/` são **código
  gerado** (`CLAUDE.md:309`). Toda edição à mão ali precisa entrar na lista de
  frágeis-a-regen do `CLAUDE.md`.
- **Nenhuma tabela de 1.2 é compartilhada com o `agsur-app`**
  (`available_aircrafts`, `proposal`, `contract`, `notes` → o app não tipa
  nenhuma). Por isso o plano **não** adiciona coluna de telefone em
  `leads`/`users`, que **são** compartilhadas.
- Sem pacote de timezone: `timestamptz` + `America/Sao_Paulo` no `to_char`.
  `showDatePicker` do Material já é usado em 4 telas.

---

## Item 1.1 — Lembretes por WhatsApp

### M1 · `…01_phone_normalization.sql`

`public.phone_to_e164(text)` — `IMMUTABLE`, **fonte da verdade** do envio:
tira não-dígitos e zero de operadora; rejeita dígitos todos iguais; 12/13 com
`55` → `+`; 10/11 com DDD ≥ 11 → `+55`; resto → `NULL`.

`public.wa_param(text, int)` — colapsa whitespace e trunca com `…`. É o que
torna `template_params` **exatamente** o que sai.

Espelho de UI em **`lib/backend/phone.dart`** (puro, sem Flutter — mesma pasta de
`commission.dart`/`client_reuse.dart`): `toE164Br`, `isLikelyWhatsApp`,
`formatBrDisplay`. Testes em `test/phone_test.dart` com a **mesma tabela de
fixtures** da validação SQL (~14 casos: três máscaras, fixo, já-com-DDI, lixo).

**Sem coluna nova e sem backfill.** O E.164 é congelado no disparo. Backfill em
`leads`/`users` exigiria o dance de desarmar trigger em tabela compartilhada,
com zero ganho na sprint.

### M2 · `…02_note_reminders.sql` — duas tabelas, não uma

Uma tabela não funciona: `recipient_kind='equipe'` **espalha para N telefones a
partir de um lembrete**. Fundir fan-out e status forçaria N lembretes (quebra
"cancelar este lembrete") ou um jsonb (quebra o índice parcial do cron).

- **`note_reminders`** — a intenção: `note_id`, `lead_id`, `scheduled_at`,
  `recipient_kind` (`cliente|vendedor|equipe`), `recipient_user_id` (override),
  `subject`, `status` (`agendado|enviado|falha|cancelado` — o roll-up que o spec
  pede).
- **`reminder_dispatches`** — a unidade de envio: `phone_e164` **congelado**
  (com `CHECK ~ '^\+[1-9][0-9]{7,14}$'`), `status`
  (`pendente|enviando|enviado|falha|cancelado`), `attempt_count`,
  `next_attempt_at`, `claimed_at`/`claimed_by`, `provider`,
  `provider_message_id`, `last_error_code`/`last_error`, `template_name/lang/params`,
  e `delivery_status`/`delivered_at` nascendo NULL (reservado para o webhook).
- **`reminder_team_members`** — opt-in explícito de quem é "equipe", gerido por
  Admin Master. "Todo mundo com perfil de painel" seriam ~20 conversas pagas por
  lembrete.

Índices que importam:

```sql
-- o que o cron bate a cada minuto
create index idx_reminder_dispatches_due on public.reminder_dispatches (next_attempt_at)
  where status in ('pendente','enviando');
-- idempotência do fan-out
create unique index uq_reminder_dispatch_recipient
  on public.reminder_dispatches (reminder_id, phone_e164);
```

**RLS.** Leitura = mesma régua de `notes` (`auth_is_seller_or_admin()`).
`reminder_dispatches` **não tem policy de escrita nenhuma** — só as RPCs definer
escrevem (padrão de `chat_threads` em `20260628120000`). `note_reminders` não tem
policy de UPDATE/DELETE: sem isso um vendedor daria `PATCH status='enviado'` e
sumiria com a evidência; cancelar é RPC. Fechar **as duas metades** do revoke
(`revoke all … from anon, authenticated` + grants explícitos) e pendurar
`tg_require_seller_or_admin` / `tg_require_admin`.

View `vw_reminder_dispatches` com **`security_invoker = on`** — é exatamente a
classe de IDOR que `20260622140000` fechou para `vw_notes_details`.

### M3 · `…03_reminder_dispatch_engine.sql`

- **`create_lead_note(lead_id, note, reminder jsonb)`** — grava nota **e**
  lembrete na mesma transação, e é também o conserto do insert cru. Se o fan-out
  resolver 0 destinatários, `raise exception` em pt-BR ("Corrija o telefone…") e
  a transação inteira volta — melhor que gravar lembrete natimorto.
- **`fan_out_reminder(uuid)`** — resolve kind → telefones, aplica
  `phone_to_e164` + `wa_param`, monta `{{1}}..{{4}}`. **Eager, na criação**:
  valida o telefone enquanto o usuário ainda está na tela e congela o número
  para auditoria. Resolver no envio falha silenciosamente às 3h.
- **`claim_reminder_dispatches(limit, run_id)`** — o anti-duplo-envio:

```sql
with due as (
  select id from public.reminder_dispatches
   where next_attempt_at <= now()
     and (status = 'pendente'
          or (status = 'enviando' and claimed_at < now() - interval '5 minutes'))
   order by next_attempt_at limit p_limit
   for update skip locked
)
update public.reminder_dispatches d
   set status='enviando', claimed_at=now(), claimed_by=v_run,
       attempt_count=d.attempt_count+1, last_attempt_at=now()
  from due where d.id = due.id returning d.*;
```

  `SKIP LOCKED` protege o instante; a proteção durável é **o flip para
  `enviando` na mesma instrução** — o tick N+1 não vê a linha como candidata.
  Janela residual: "Meta aceitou → função morreu → 5 min". Mitigada por gravar o
  resultado imediatamente e por 5 min ser 15× o timeout de 20 s. Documentar e
  aceitar: lembrete duplicado é chateação, lembrete perdido é venda perdida.
  Não tentar resolver com chave de idempotência — o `/messages` da Meta não tem.
- **`complete_reminder_dispatch(...)`** — grava o resultado, aplica backoff
  (2 min → 10 min → 60 min, máx 4 tentativas) **só quando `retriable`**, e faz o
  roll-up do `note_reminders.status`. Erro de template/parâmetro nunca é
  retriável: 4× o mesmo 132000 só queima quota.
- **`cancel_note_reminder(uuid)`** — seller/admin.

**Gate de serviço:** usar **`auth_is_service_request()`**, não
`auth_is_service_role()` — dentro de definer a segunda devolve `true` para
qualquer chamador (`20260715120000`). A primeira cobre os dois chamadores: o
`pg_cron` (`session_user = postgres`) e a Edge Function (claim
`role=service_role`).

Depois: conferir `has_function_privilege('anon', …, 'EXECUTE') = false` nas
**oito** funções novas — a armadilha das duas metades do revoke já mordeu este
repo nos dois sentidos.

### Edge Function `dispatch-whatsapp-reminders`

```
supabase/functions/dispatch-whatsapp-reminders/
  index.ts                 # claim → loop → adapter → complete
  providers/types.ts       # interface WhatsAppProvider
  providers/meta.ts        # Graph API v21.0
  providers/dryrun.ts      # ⭐ escrever PRIMEIRO, não por último
  providers/index.ts       # getProvider() por WA_PROVIDER
```

Adapters **dentro da pasta da função** — o repo não tem `_shared/` nem
`deno.json`, e criar um adiciona pergunta de bundling no `--use-api` para um
único consumidor.

`SendResult` carrega `retriable`: o **provider** classifica o próprio erro e a
fila nunca conhece código da Meta. Trocar `WA_PROVIDER` mexe só em `providers/`.
Classificação: 5xx/429/`130429`/`131042` → retriável; `132000/132001/132005/132007`
(template/param), `131009`, `131026` (não é WhatsApp — o caso do fixo) e `190`
(token morto) → **não** retriável.

**Autenticação dupla**, seguindo a anatomia de `send-credentials-email/index.ts`:
1. **cron** → header `x-agsur-cron-secret` conferido em **tempo constante**
   (`a === b` num segredo é oráculo de timing);
2. **painel** ("Reenviar") → Bearer JWT + o mesmo gate `PANEL_PROFILES` das
   linhas 112-133 daquele arquivo.

⚠️ **`config.toml` precisa de `[functions.dispatch-whatsapp-reminders]
verify_jwt = false`** — o cron não manda JWT e o gateway o rejeitaria antes do
nosso código. **É a mudança de maior risco da sprint**: o endpoint fica
publicamente alcançável e o único anteparo entre a internet e a quota de
WhatsApp é aquele bloco. A verificação (§Verificação, item 4) vem **antes** de
`WA_META_TOKEN` existir.

Nunca logar `phone_e164` nem `template_params` (PII → Sentry).

Secrets: `REMINDER_DISPATCH_SECRET`, `WA_PROVIDER`, `WA_DRY_RUN`,
`WA_META_TOKEN` (System User!), `WA_META_PHONE_NUMBER_ID`,
`WA_META_GRAPH_VERSION`, `WA_TEMPLATE_NAME`, `WA_TEMPLATE_LANG`.
Deploy manual — não há step de CI para functions.

### M4 · `…04_reminder_cron.sql` — **aplica por último**

Cron agendado antes da função existir faz POST num 404 a cada 60 s para sempre.

```sql
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

select cron.schedule('wa-reminders-tick', '* * * * *', $cron$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='reminder_dispatch_url'),
    headers := jsonb_build_object('Content-Type','application/json',
                 'x-agsur-cron-secret',
                 (select decrypted_secret from vault.decrypted_secrets where name='reminder_dispatch_secret')),
    body := jsonb_build_object('source','pg_cron'),
    timeout_milliseconds := 20000);
$cron$);
```

Segredos criados **uma vez** via `vault.create_secret(...)`, fora do git e fora
do chat. **Não** autenticar o cron com a service-role key: ela ficaria em
`cron.job` e nos logs de `net._http_response`.

Mais duas faxinas obrigatórias: `net._http_response` cresce 1440 linhas/dia e
**não se limpa sozinho** (vira o maior objeto do banco); `cron.job_run_details`
idem.

⚠️ `CREATE EXTENSION` pode falhar se o login role da CLI não for superuser.
Fallback pronto: habilitar no Studio uma vez e registrar em
`supabase/DASHBOARD_TIER2_TODO.md`; o `if not exists` vira no-op.

⚠️ **`net.http_post` é fire-and-forget** — o cron fica verde mesmo com a função
em 500. O monitoramento tem que sair do **dado**: dispatch em `pendente` com
`next_attempt_at < now() - 10 min` = dispatcher caído. Banner de aviso na tela de
histórico (barato) em vez de alerting.

### UI de 1.1

**Modal de nota** (`lib/pages/shared/modal_register_note/`, 95 linhas, já
`core_ui`): trocar `btnAction(String)` por `onSubmit(NoteDraft)` — **sem manter
os dois**, já que ambos os call sites são reescritos de qualquer jeito. Novos
props: `allowReminder = true`, `leadDisplayName`. `_submit()` mantém a forma
atual (só popa se não lançar) — é esse contrato que faz o `guardInsert`
funcionar ponta a ponta.

Campos, todos `core_ui`: switch "Criar lembrete" (desligado = modal idêntica à
de hoje) → dropdown de destinatário → assunto (`{{2}}`) → data+hora → **preview
da mensagem** → **aviso de telefone**. Dois detalhes que economizam retrabalho:

- Reaproveitar o `_pickDate` com override de `Theme` de
  `modal_create_available_aircraft_widget.dart:92-121` — sem ele o picker
  renderiza branco-no-branco sobre `#2A2A2A`.
- O preview é o único lugar onde o usuário vê que a nota de 3 parágrafos vira
  uma linha truncada. Sem ele, o `wa_param()` é uma surpresa entregue ao cliente.

**Os dois inserts crus** (`view_edit_lead_widget.dart:3764-3779` e
`view_edit_client_widget.dart:3858-3873`) passam a chamar
`createLeadNote(context, …)` de um novo `lib/backend/notes.dart`, que embrulha a
RPC em `guardInsert`. Cada call site cai para ~6 linhas (o bloco de `SnackBar`
inline vira `showActionSuccess`), o que também alivia a indentação de nível 30 do
código FF.

**Histórico, nos dois lugares:**
- **Seção contextual** — novo `lib/leads/view_edit_lead/lead_reminders_section.dart`,
  à mão fora do código FF, montada logo após `LeadReferralSection`
  (`view_edit_lead_widget.dart:3582-3590`) e no ponto equivalente do cliente.
  Padrão idêntico ao de `lead_referral_section.dart`. Ações Cancelar/Reenviar.
- **Tela global** — `lib/pages/reminders/reminder_history/`, rota
  `ReminderHistory`, `AppListScaffold` + `queryPage`/`orIlike` + `AppPagination`
  + `_FilterChips` de status. **Todos os filtros no `queryFn`** (regra de
  `paged_query.dart:46-49`); copiar `contracts_widget.dart:43-56`.

Wiring: `'ReminderHistory'` entra no conjunto **`_funil`** já existente de
`access_control.dart` (diff mínimo — pega Vendedor, documentação e Master, e
propaga para `_all` sozinho); `FFRoute` em `nav.dart`; `_MenuItem` no grupo
"Funil de vendas" de `menu_widget.dart`; export em `index.dart`;
`lib/security/whatsapp_reminders.dart` como cópia quase literal de
`credentials_email.dart:18-47`. A classe Dart de `vw_reminder_dispatches` é
escrita à mão (precedente: `vw_aircraft_items_by_aircraft`) → **entra na lista
de frágeis-a-regen do `CLAUDE.md`**.

---

## Item 1.2 — Estoque & vínculo contratual

Sem dependência nenhuma com 1.1 — pode correr em paralelo desde o dia 1.

### M5 · `…05_stock_unit_and_status.sql`

```sql
alter table public.available_aircrafts
  add column if not exists registration_prefix text,          -- sem CHECK de formato:
  add column if not exists is_featured boolean not null default false;
--   unidade importada chega com N-number (N123AB) e um CHECK de PP-XXX barraria
--   o cadastro real. Normalização (upper/trim) fica na modal.

create index if not exists idx_available_aircrafts_featured
  on public.available_aircrafts (is_featured) where is_featured;

-- SEM índice único: várias propostas podem mirar a mesma unidade (ofertas
-- concorrentes) — é o ponto do pré-contrato. A exclusividade continua sendo do
-- CONTRATO (uq_contract_available_aircraft_active, 20260722130000).
alter table public.proposal
  add column if not exists available_aircraft_id uuid
    references public.available_aircrafts(id) on delete set null;
```

**Status — o vocabulário único é a UNIÃO dos dois de hoje:** `Disponível`,
`Reservado`, `Em negociação`, `Vendido`, `Entregue`. Assim as duas listas
existentes viram subconjuntos estritos e **nenhum valor gravado fica ilegal**.
Ordem obrigatória: preflight (b) → `UPDATE`s de normalização → só então o
`CHECK`. O DML precisa **desarmar `hardening_require_documentacao`** (o login
role da CLI não passa em `auth_is_service_request`) e rearmar — padrão de
`20260817140000`. Se (b) revelar algo genuinamente novo, o CHECK falha e a
migration inteira volta — que é o comportamento desejado.

Fonte única no Dart: novo `lib/backend/aircraft_status.dart` com
`kAircraftUnitStatuses` e `toneForAircraftStatus` (tolerante a legado por
substring). As **duas** cópias do mapa de tom morrem
(`available_aircrafts_widget.dart:362-368` e
`contract_aircraft_unit_section.dart:324-333`).

### Generalizar a seção de unidade

Novo `lib/pages/shared/aircraft_unit_section/aircraft_unit_section.dart` com
`enum UnitLinkTarget { proposal, contract }` e três métodos por alvo
(`readLinkedUnitId` / `writeLink` / `blockedUnitIds`).

**A diferença de comportamento que justifica não clonar:** para **contrato**,
unidade já em contrato ativo é **inselecionável** (o banco devolve 23505 e a
seção já traduz). Para **proposta**, unidade ofertada em outra proposta continua
**selecionável** — é oferta concorrente; mostrar "já ofertada em 2 propostas"
esmaecido, mas clicável. Bloquear seria errado.

`contract_aircraft_unit_section.dart` vira um wrapper de ~20 linhas, então
`view_contract_widget.dart:4676-4682` **não é tocado** — manter o diff fora do
widget de 6k linhas vale o arquivo extra. A variante de proposta é montada em
`view_edit_proposal_widget.dart`, **não** em `create_proposal` (ainda não existe
`proposal.id`) — nota de escopo para o cliente.

### Filtro rápido

`fn_available_aircrafts` **tem que mudar** de qualquer forma (a lista não
renderiza destaque nem prefixo sem eles virem da RPC). Versionar a partir do dump
do preflight e, já que se está lá: devolver `is_featured`/`registration_prefix`,
aceitar `p_featured boolean default null` (param com default mantém o body atual
válido) e pôr **`is_featured desc` como primeira chave do `ORDER BY`** — é o que
"em destaque" significa operacionalmente.

Dart: `AppToggleChip` "Só destaques" ao lado dos `_FilterChips`; `_statusOptions`
→ `kAircraftUnitStatusFilter`; estrela + prefixo em `_AircraftRow`. Extrair
`AppFilterChips`/`AppToggleChip` para `lib/core_ui/app_filter_chips.dart` e usar
**só em `available_aircrafts`** — migrar `guarantees`, `part_quote` e
`profile_analysis` é refactor puro em três telas não relacionadas, com superfície
de regressão real e zero valor de sprint. Fica como follow-up declarado.

Aproveitar para trocar `_isAdmin == 'Admin Master'`
(`available_aircrafts_widget.dart:69-70`) por `AccessControl.canEditTracking` —
o banco já permite documentação escrever aqui, e documentação é exatamente quem
vai preencher 100 prefixos. O `CLAUDE.md` proíbe hardcode de perfil fora de
`access_control.dart`.

### M6 · `…06_get_proposal_details_unit.sql` — S/N e prefixo no PDF

**Estender a RPC**, não acrescentar parâmetro: ela **já é versionada**
(`20260714130000:113-260`), o PDF já lê `asGetProposalDetails.proposalAircraft`,
e o call site em `view_contract_widget.dart:5626-5729` (com seus dois guards e o
re-fetch) fica intocado. Três edições:

```sql
LEFT JOIN public.contract ct ON ct.proposal_id = p.id AND ct.cancelled_at IS NULL
LEFT JOIN public.available_aircrafts av
       ON av.id = COALESCE(ct.available_aircraft_id, p.available_aircraft_id)
```
mais as chaves novas no fim de `proposal_aircraft` (`serial_number`,
`registration_prefix`, `available_aircraft_id`, datas), as mesmas chaves como
`null` no fallback `IF NOT FOUND` (linhas 220-230), e `av.*`/`ct.*` no `GROUP BY`
(212-218).

**As chaves novas vêm `NULL`, não `'Não cadastrado'`** — o placeholder é a
armadilha que o `CLAUDE.md` documenta duas vezes. Contrato tem que imprimir
*nada*, não a palavra "Não cadastrado".

Em `generate_contract_pdf.dart`: `aircraftTitle` (linha ~237) ganha
`' · $prefix'` quando houver; o bloco do Item 1 (432-467) ganha `S/N` e dados
técnicos, cada linha condicional a não-vazio, via um helper `_isPlaceholder`.
**Nenhum `!`** — o `CLAUDE.md` aponta o `!` isolado dentro de cadeia `?.` como o
bug característico deste arquivo. Não embutir aqui o fix conhecido de `42804`:
risco diferente, PR diferente.

---

## Ordem, paralelismo e riscos

| Onda | Entrega | Depende de |
|---|---|---|
| 0 | Preflight + captura das RPCs + `phone.dart` + **submeter template** | — |
| 1 | M1 → M2 → M3 · M5 → M6 (trilhas independentes) | preflight (a)/(b) |
| 2 | Edge Function com `WA_DRY_RUN=true` | M2/M3 locais |
| 1' | **M4 (cron) — por último** | função **deployada** |
| 3 | UI 1.1 (modal, seção, histórico) · UI 1.2 (picker, filtro, PDF) | M2/M3 · M5/M6 |

**Pessoa A** leva 1.1 inteiro; **pessoa B** leva 1.2 inteiro. Arquivos
compartilhados: só `CLAUDE.md`, `supabase/README.md` e uma linha de export em
`core_ui.dart`.

**Bloqueado na Meta: exatamente um flip de config** (`WA_DRY_RUN=false` +
credenciais). Fila, claim/lock, retry, backoff, fan-out, validação de telefone,
cron, histórico, seção, cancelar e reenviar são **todos verificáveis com
`providers/dryrun.ts`**, que grava `provider='dryrun'` e um `sent_at` real — o
histórico fica populado e demonstrável ao cliente antes da Meta aprovar
qualquer coisa. **Por isso o dry-run é o primeiro adapter, não o último.**

### Riscos

- **Verificação da WABA/Business Manager** é prazo de terceiro e o caminho
  crítico real.
- **Secrets do CI ausentes.** O `CLAUDE.md` registra a janela em que
  `supabase-db-check` e `rls-smoke` ficaram verdes sem executar nada e duas
  migrations passaram três semanas sem aplicar.
- **Esta cópia não é git.** Nada aqui vira PR ou deploy.

---

## Verificação

```bash
cd agsur-main && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test
```

Régua: **0 erros**, **261 warnings** (base medida em 2026-09-08, Flutter 3.41.9,
que é o que o CI pina). Testes: **27 → ~45** (`phone_test.dart` ~14 +
`NoteReminderDraft`/`toneForAircraftStatus` ~4). Declarar o número novo no PR.
Os dois hand-edits em código gerado podem introduzir warning — conferir
especificamente. `agsur-app` não é tocado: nenhuma das tabelas envolvidas é
tipada lá.

Por migration: `db push --dry-run` antes, `migration list --linked` depois
(coluna `remote` vazia = migration que nunca rodou), skill
`db-migration-security-review` em cada uma, e uma linha na tabela de histórico de
`supabase/README.md`.

**Segurança, nesta ordem, antes de qualquer credencial da Meta existir:**

1. `rls-smoke` após M2 — anon não vê nada nas três tabelas nem na view.
2. `has_function_privilege('anon', …, 'EXECUTE')` = false nas oito funções.
3. **JWT real via PostgREST** (não `db query`, que roda como `postgres` e
   bypassa as triggers): Vendedor cria nota+lembrete; Cliente do app → 42501;
   `insert`/`update` direto em `reminder_dispatches` → 42501 para todos;
   `claim_reminder_dispatches` → 42501 para `authenticated`.
4. **Gate do endpoint, com `WA_PROVIDER=dryrun`:** sem header → 401; segredo
   errado → 401; JWT de Cliente → 403; segredo certo → 200; JWT de painel → 200.
   **Só depois** setar `WA_META_TOKEN`.
5. **Duplo envio:** um dispatch vencido, dois `curl` em paralelo → exatamente
   uma linha em `enviado`, `attempt_count = 1`.
6. **Overrun:** `p_limit` alto com provider lento (tick > 60 s) → o tick
   seguinte reclama 0.
7. Saúde do cron após M4: `cron.job_run_details` e a contagem de
   `net._http_response` na última hora.

**Smoke manual de 1.2** (M6 muda uma RPC lida por duas telas pesadas): abrir
`view_contract` e `view_edit_proposal` para (a) proposta com contrato e unidade,
(b) com contrato e **sem** unidade, (c) sem contrato, (d) **sem
`proposal_financing`** (21 de 48 não têm). Gerar o PDF de (a) e (b) e confirmar
que (b) não imprime rótulo órfão. E vincular a mesma unidade a dois contratos
ativos → 23505 traduzido.

---

## O que renegociar com o cliente

1. **"Enviado" não é "entregue".** A Meta devolve *aceito*; entrega só é
   observável por webhook. Se o critério de aceite é "o cliente recebeu", a
   sprint não atende. Ou rotular honestamente ("Enviado — aceito pela Meta") —
   recomendado, e por isso `delivery_status`/`delivered_at` já nascem no schema
   — ou orçar um segundo function `wa-status-webhook` (HMAC `X-Hub-Signature-256`),
   que tem o tamanho do dispatcher. Não é sub-tarefa do 1.1.
2. **Consentimento (achado 7).** Incluir `leads.wa_opt_out` agora.
3. **"Equipe" precisa de uma tela de gestão** que ninguém orçou. Se não couber,
   entregar `cliente` + `vendedor` e manter `'equipe'` reservado no CHECK — o
   schema já fica pronto.
4. **`registration_prefix` nasce vazio em 100% do estoque.** O PDF degrada em
   silêncio e o cliente precisa saber que o prefixo só sai em contrato novo até
   alguém preencher. Um filtro "faltando matrícula" (uma linha, reusa o
   `AppToggleChip`) transforma o backfill em tarefa finita.
