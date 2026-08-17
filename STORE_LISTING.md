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
