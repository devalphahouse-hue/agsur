# Listing das lojas — Agsur Painel

Textos e dados para a ficha do app nas duas lojas. Mantido aqui para não
reescrever a cada atualização de release.

- **Bundle/package:** `com.agsur.painel` (idêntico nas duas lojas)
- **Play Console:** conta `Vinicius Moreira` (ID `6549776849384192904`),
  app ID `4972837200360954328` — a mesma conta do app cliente
  `com.agsur.clientapp` (AEROTG).
- **Apple:** App ID registrado no time `XYYV8DTFFV` (vicente el khatib roriz).
- **Idioma base:** pt-BR nas duas.

---

## ⚠️ Status na App Store: reprovado 3.2, indo para Unlisted (2026-08-20)

### Atualização 2026-09-18: 2ª reprovação e os 4 passos finalmente feitos

O build **1.0.0 (2)** foi reenviado em 2026-09-01 **sem** nenhum dos passos
abaixo (sem resposta, Notas vazias, sem formulário) e a Apple reprovou de novo
na 3.2 em 2026-09-02 ("The issues we previously identified still need your
attention"). Em 2026-09-18 foram feitos, nesta ordem:

1. Notas de Revisão preenchidas (em inglês, com a frase de unlisted).
2. Resposta enviada à Apple (texto da seção "Resposta para colar").
3. **Formulário unlisted enviado pelo Apple ID do Vicente** — o do Renan não
   lista o time `XYYV8DTFFV` na caixa Organization. Enquadramento: 1
   organização, só funcionários (Internally / Full-time employees), ~5
   pessoas, aparelhos unmanaged, Brasil, categoria Business operations.
4. Mesmo build 1.0.0 (2) reenviado → **Aguardando revisão**. O formulário
   **não** recusou o app em estado `rejected` (a nota abaixo estava errada
   nisso).

⚠️ **Pendente:** o login de revisão no ASC ainda é uma conta pessoal com senha
trivial, não `revisao.loja@agsurbrasil.app`. Trocar (e trocar a senha da conta
exposta).

**A submissão pública morreu.** Submission ID `5db83924-3a36-41e1-b991-fddac5518e83`,
versão 1.0 (1), reprovada em **Guideline 3.2 - Business**: app de uso interno de
uma empresa não pode ir por distribuição pública.

**A avaliação da Apple está correta e não se contesta.** Nós mesmos declaramos o
enquadramento em três lugares — a descrição da ficha ("destinado à equipe da
Agsur Brasil... Não há cadastro público"), as notas de revisão ("aplicativo de
uso interno") e a própria tela de login (`login_widget.dart`: "Acesso restrito a
Admin, Vendedor ou Funcionário"). O código confirma: só existem as telas `login`
e `reset_password`, sem cadastro, e `check_app_access` só admite
`Admin Master`, `Admin`, `Vendedor` e `Admin2`. Responder "é público" seria
mentira e queima ciclo de revisão.

**Decisão: Unlisted App Distribution.** Mantém o time `XYYV8DTFFV`, o App ID e o
registro do ASC (`6800787699`); não exige ABM, D-U-N-S nem MDM; e cobre
`Vendedor` — que o Apple Developer Enterprise Program proibiria por não ser
funcionário.

### Ordem das etapas (a ordem importa)

O formulário de Unlisted **recusa app em estado `rejected` ou `pending`** — que é
exatamente o estado de hoje. Então não adianta preencher o formulário primeiro:

1. **Responder a reprovação no ASC** com o texto da seção abaixo.
2. **Editar as Notas de Revisão** acrescentando, em inglês:
   `This app is intended for unlisted distribution.`
3. **Reenviar para revisão.** Tecnicamente o binário 1.0 (1) já serviria — a
   reprovação não foi técnica. Optamos por subir **1.0.0+2** (ver
   "Correções de 2026-09-01" abaixo); como o ASC recusa reenvio do mesmo build
   number, o bump é obrigatório para qualquer upload novo.
   ⚠️ A receita de build do `CLAUDE.md` embute
   `APP_RELEASE=agsur-painel@$(git rev-parse --short HEAD)`, que **falha nesta
   cópia** por não haver `.git` — use valor fixo (foi usado
   `agsur-painel@1.0.0+2`).
4. **Enviar o formulário** em <https://developer.apple.com/contact/request/unlisted-app/>
   (exige login Apple ID — confira que o time selecionado é `XYYV8DTFFV`, porque
   o portal volta sozinho para outro time).

Depois de aprovado: o app sai de busca, categorias, charts e recomendações, fica
acessível só por link direto, e o modo passa a valer para **todas as versões
futuras** (Pricing and Availability → "Unlisted App").

⚠️ **A Apple avisa que o link de app unlisted é público para quem o tiver** — a
proteção real tem que estar no app. No nosso caso está: `check_app_access` roda
no servidor e barra qualquer perfil fora da allowlist. Vale citar isso na
resposta (já está no texto abaixo).

### ⚠️ Antes de reenviar: conferir o perfil da conta de revisão

**Os dois documentos se contradizem sobre `revisao.loja@agsurbrasil.app`:**
mais abaixo neste arquivo (§"Conta de revisão") ela está como perfil
**`Vendedor`**; no `CLAUDE.md` ela está como **`Admin Master`**, trocada porque
"o Play exige declarar que a credencial dá acesso total, e Vendedor não dava".
**Confirme no banco qual é o valor real antes de reenviar** e acerte o
documento que estiver errado.

Isso não é detalhe burocrático: se ela for **Admin Master**, existe um caminho
que tranca o revisor fora e reprova o app de novo —

- `login_widget.dart` desloga Admin Master sem TOTP, com a mensagem "Admin
  Master requer autenticação em dois fatores". O gate é
  `_kEnforceMfaAdminMaster`, hoje **`false` por padrão** — o revisor entra.
- Mas ele liga com `--dart-define=ENFORCE_MFA_ADMIN_MASTER=true`, e o
  `CLAUDE.md` já planeja ligar. Buildar a release da loja com essa flag, sem
  TOTP cadastrado na conta de revisão, **derruba o revisor na tela de login**.
- O hook server-side `custom_access_token_hook` tem o mesmo efeito e **independe
  da flag**: ativado no Studio, o JWT volta rejeitado.

Regra prática: **a conta de revisão não pode ser Admin Master no dia em que
qualquer um dos dois gates for ligado.** Ou ela fica `Vendedor`/`Admin`, ou
cadastre TOTP nela — e aí a senha estática deixa de bastar para o revisor, o que
inviabiliza a conta. A saída limpa é ela **não** ser Admin Master.


### Correções de 2026-09-01 (build 1.0.0+2)

Nenhuma delas é exigência da Apple — a 3.2 não se resolve em código. São o
mínimo para poder subir um binário novo sem carregar uma armadilha conhecida:

1. **`pubspec.yaml`: `1.0.0+1` → `1.0.0+2`.** Obrigatório: o build 1 já foi
   consumido pela submissão reprovada e o ASC recusa duplicado.
2. **`login_widget.dart`: comentário do gate de MFA reescrito.** O texto antigo
   mandava ligar `ENFORCE_MFA_ADMIN_MASTER=true` "depois que todos cadastrarem
   TOTP no Studio" — instrução que **tranca todo Admin Master fora do painel**,
   porque não existe tela de desafio TOTP no `lib/` e o `aal2` é inalcançável
   (cadastrar fator não sobe o AAL da sessão). Só o comentário mudou; o
   comportamento é idêntico.

**O build da loja NÃO passa `ENFORCE_MFA_ADMIN_MASTER`** — deliberado. Com a
flag off e o hook `custom_access_token_hook` desativado no Studio, o revisor
entra normalmente, inclusive se a conta de revisão for Admin Master.

Baseline de verificação após as correções: `flutter analyze` 0 erros /
261 warnings / 3588 issues, `flutter test` 27 casos verdes — idêntico ao
anterior.

**Upload feito em 2026-09-01 11:29** (Organizer → Distribute App → App Store
Connect). `Prepared archive for uploading` 11:27, `Uploaded with warnings`
11:29. O build **1.0.0 (2)** está no ASC.

Único aviso, já esperado e não bloqueante:

> **MinimumOSVersion too low.** This app has a MinimumOSVersion of 14.0.0.
> Starting in Spring 2027, all iOS apps must have a MinimumOSVersion of 15.0 or
> later in order to be uploaded to App Store Connect or submitted for
> distribution.

Ou seja: aceito agora, com prazo até a primavera de 2027. O conserto (quando
for a hora) é `IPHONEOS_DEPLOYMENT_TARGET` nos 3 pontos do `project.pbxproj`
mais `platform :ios` do `Podfile` — hoje ambos em `14.0.0`. Não vale queimar um
build number por isso agora.

### Resposta para colar no App Store Connect

Em inglês de propósito — a carta permite outro idioma, mas inglês evita rodada de
tradução. As 5 perguntas na ordem em que a Apple fez:

```
Thank you for the review and for the guidance on distribution options.

We agree with your assessment. Agsur Painel is an internal business tool, not a
consumer app, and public App Store distribution was the wrong choice on our
part. We are requesting Unlisted App Distribution for this app.

Answers to your questions:

1. Is the app restricted to users who are part of a single company or
   organization?
   Yes. The app is used exclusively by Agsur Brasil, a single company, and by
   its own staff and contracted sales representatives. There is no other
   audience.

2. Is the app designed for use by a limited or specific group of companies or
   organizations? Can any company become a client?
   It is used by exactly one organization: Agsur Brasil. No other company or
   organization can register for, subscribe to, or use this app. We do not sell
   or license it to third parties, and it is not offered as a SaaS product.

3. What features in the app are intended for use by the general public?
   None. The app contains no publicly accessible feature or content. It is a
   back-office tool for managing our own sales pipeline, contracts and aircraft
   import workflow. A user who is not an Agsur Brasil employee or contracted
   representative cannot see or do anything in the app.

4. How do users obtain an account?
   Accounts are created only by Agsur Brasil administrators from inside the
   panel, and credentials are sent to the person by email. There is no
   self-registration anywhere in the app; the only unauthenticated screens are
   the login screen and the password reset screen. Access is additionally
   enforced server-side: a database function (check_app_access) validates the
   account profile at sign-in and rejects any profile outside our internal
   allowlist, so possession of the app or of a distribution link alone grants
   no access.

5. Is there any paid content in the app, and if so, who pays for it?
   No. There is no paid content, no in-app purchase, no subscription and no
   advertising. The app is an internal cost of the company; users never pay for
   an account or for any feature.

We have added a note to the Review Notes indicating our intent to distribute
this app unlisted, and we are submitting the unlisted app distribution request
form. Please let us know if you need any further information.
```

---

## Google Play

**Nome do app** (máx. 30)

```
Agsur Painel
```

**Descrição curta** (máx. 80)

```
Gestão de leads, propostas, contratos e importação de aeronaves.
```

**Descrição completa** (máx. 4000)

```
O Agsur Painel é a ferramenta de trabalho da equipe Agsur Brasil para conduzir
a venda e a importação de aeronaves de ponta a ponta.

FUNIL COMERCIAL
• Cadastro e acompanhamento de leads
• Propostas com itens de série e opcionais por modelo de aeronave
• Planos de financiamento com cálculo de parcelas, entrada e depósitos
• Geração de PDF da proposta e do contrato
• Conversão de proposta em contrato, com abertura de acesso para o cliente

CONTRATOS E VENDAS
• Contratos vinculados à unidade da aeronave em estoque
• Cancelamento com motivo e histórico preservado
• Termos de contrato preenchidos a partir de template

ESTEIRA DE IMPORTAÇÃO
• Acompanhamento das 21 etapas do processo, do cadastro inicial à liberação
  para voo: proforma, reserva, pagamentos, RAB, seguro, apólices, despachante
  e desembaraço
• Checklists de documentos por etapa
• Situação de cada etapa visível em um relance

CADASTROS E OPERAÇÃO
• Clientes, vendedores, pilotos, oficinas e colaboradores
• Estoque de unidades disponíveis
• Taxas de financiamento
• Oficina e cotação de peças
• Chat interno entre a equipe

ACESSO RESTRITO
O aplicativo é destinado à equipe da Agsur Brasil e exige credenciais
fornecidas pela empresa. Não há cadastro público: contas são criadas pelos
administradores do sistema. Clientes finais acompanham a própria aeronave pelo
aplicativo AEROTG, que é separado deste.
```

**Categoria:** Empresarial (Business)
**Tags sugeridas:** gestão, CRM, aviação, contratos
**E-mail de contato:** _(preencher — aparece público na ficha)_
**Política de privacidade:** `https://painel.agsurbrasil.app/privacidade`

---

## App Store

**Nome** (máx. 30)

```
Agsur Painel
```

**Subtítulo** (máx. 30)

```
Gestão comercial e importação
```

**Texto promocional** (máx. 170)

```
Conduza o funil comercial e a esteira de importação de aeronaves: leads,
propostas, contratos, PDFs e as 21 etapas do processo, tudo em um lugar.
```

**Palavras-chave** (máx. 100, separadas por vírgula, sem espaços)

```
agsur,aeronave,aviacao,gestao,crm,proposta,contrato,importacao,leads,frota
```

**Descrição:** usar a mesma descrição completa do Google Play (acima).

**Categoria primária:** Negócios · **Secundária:** Produtividade

---

## Classificação etária / conteúdo

Sem conteúdo sensível: não há violência, conteúdo sexual, jogos de azar,
compras no app, publicidade nem conteúdo gerado por usuário exposto
publicamente. O chat interno é 1:1 e restrito a funcionários da empresa
(declarar como comunicação entre usuários com acesso restrito).

Esperado: **Livre / 4+**.

---

## O que já foi declarado na Apple (2026-08-12)

App Store Connect, app `6800787699`. **Ainda NÃO publicado** — o botão
"Publicar" da Privacidade do app está habilitado e aguardando revisão humana.

Os 11 tipos declarados, todos com finalidade **Funcionalidade do app**,
**vinculados à identidade** do usuário e **não usados para rastreamento**:

`Nome`, `Endereço de e-mail`, `Número de telefone`, `Endereço físico`,
`Outras informações financeiras`, `Fotos ou vídeos`, `Outros conteúdos de
usuário`, `ID de usuário`, `Dados de falhas`*, `Dados de desempenho`*,
`Outros tipos de dados`.

\* Dados de falhas e de desempenho (Sentry) levam também a finalidade
**Análise**.

**Duas decisões de enquadramento que merecem sua confirmação:**

1. **`Outras informações financeiras`** — marcada porque o app guarda plano de
   financiamento, parcelas e valor de contrato de pessoas identificáveis. É
   dado do *cliente*, digitado pela equipe, não do usuário logado. Optei por
   declarar (subdeclarar é o erro que derruba app; sobredeclarar só deixa o
   rótulo mais severo). Se o jurídico discordar, é desmarcar.
2. **CPF/CNPJ → `Outros tipos de dados`**, não `Informações confidenciais`. A
   definição da Apple de "sensível" cobre raça, orientação sexual, saúde,
   biometria e afins — documento de identificação não entra.

Classificação etária: **4+**, com `messagingAndChat = SIM` (o chat interno) e
todo o resto NÃO/NONE. `Conteúdo gerado por usuários` ficou NÃO porque a
definição da Apple exige "ampla distribuição", o que não é o caso de registros
de equipe fechada.

## Segurança de dados (Play) e Privacidade (Apple)

O app coleta e transmite, sempre por HTTPS, para o backend Supabase:

| Dado | Por quê | Vinculado ao usuário |
|---|---|---|
| Nome, sobrenome | Cadastro de clientes/equipe | Sim |
| E-mail | Login e comunicação | Sim |
| Telefone | Contato comercial | Sim |
| CPF / CNPJ | Contrato e documentação de importação | Sim |
| Endereço | Contrato e emissão de documentos | Sim |
| Fotos e documentos | Foto de perfil, fotos de aeronave, anexos e certificados | Sim |
| Mensagens do chat | Comunicação interna da equipe | Sim |

- **Criptografia em trânsito:** sim (TLS).
- **Exclusão de dados:** sim — pela própria empresa, via RPC
  `admin_delete_app_user`; o procedimento LGPD está no `RUNBOOK.md` §10.
- **Compartilhamento com terceiros:** não há venda nem compartilhamento para
  publicidade. Processadores: Supabase (banco e autenticação), Resend (e-mail
  transacional de credenciais) e Sentry (telemetria de erro, sem PII —
  `beforeSend` remove `Authorization`/`apikey`/`Cookie`).
- **Publicidade / rastreamento:** nenhum. Não há SDK de anúncio nem IDFA.

---

## Conta de revisão (obrigatória nas duas lojas)

O login é fechado pela RPC `check_app_access`, que só aceita os perfis
`Admin Master`, `Admin`, `Vendedor` e `Admin2`. **Sem credenciais válidas o
revisor não passa da tela de login e o app é reprovado.**

✅ **Criada em 2026-08-12:** `revisao.loja@agsurbrasil.app`, perfil `Vendedor`,
uid `a4d4a9a8-ea82-4bad-93f0-bf749681b546`. Validada de ponta a ponta —
`check_app_access` devolve `Vendedor` e o login emite token. **A senha não fica
neste arquivo** (ele vai para o git): está no gerenciador do dono; se perder,
gere outra pela RPC `admin_reset_client_password`.

Texto para o campo de notas de revisão das duas lojas:

```
Este é um aplicativo de uso interno da Agsur Brasil. O acesso exige
credenciais fornecidas pela empresa; não há cadastro público.

Conta de teste:
  usuário: revisao.loja@agsurbrasil.app
  senha:   (preencher)
```

**Dados de demonstração** semeados junto, para o revisor não encontrar telas
vazias: 4 leads, 3 propostas (2 com financiamento) e 3 empresas, todos
fictícios (CPF `111.111.111-11` e afins, e-mails `@exemplo.com.br`). Decidir
depois da aprovação se ficam ou viram `is_deleted`.

⚠️ Não usar conta real de funcionário: a senha fica registrada em texto no
painel de revisão da loja.

---

## Ativos

- [x] **Screenshots — 6 prontos**, capturados no simulador iPhone 17 Pro Max em
      **1320×2868** (especificação de 6,9" da App Store; o Play aceita o mesmo
      arquivo). Ficam em `~/Documents/Agsur - Prints Loja/`:
      `01-login`, `02-dashboard`, `03-leads`, `04-propostas`, `05-estoque`,
      `06-proposta`. Todos já com o `SafeArea` corrigido — prints anteriores a
      2026-08-12 têm o título escrito por cima do relógio, não reaproveitar.
- [ ] Ícone 512×512 (Play). No **iOS não é upload**: a Apple extrai do binário,
      e o `AppIcon.appiconset` já tem o 1024.
- [ ] Feature graphic 1024×500 (só Play)
- [ ] E-mail, telefone e site de contato público da ficha (aparecem na loja)
