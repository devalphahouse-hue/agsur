# Gestão comercial — Sprint 2

## Estado

Implementação de comissões e workflow interno de assinatura em 19/10/2026.
A API externa de assinatura depende da escolha do provedor e ainda não foi
implementada. Aprovação deixa o documento na fila; sem o worker conectado,
nenhuma mensagem/contrato é enviado. O frontend informa essa etapa pendente.

## Publicação

1. Abrir PR com as migrations `20261019120000_commercial_commissions.sql` e
   `20261019121000_contract_signatures.sql`; revisar policies/triggers/RPCs.
2. Executar o CI de banco e `supabase db push --dry-run` autenticado no projeto
   correto. Aplicar pelo fluxo de migrations após revisão. Não usar SQL ad-hoc.
3. Publicar o frontend pelo workflow existente. O módulo mostra mensagem de
   atualização pendente quando as tabelas/RPCs ainda não existem; nenhuma
   tentativa de liquidação/rateio tem fallback em writes antigos.
4. Validar em sandbox com contas Master, documentação, dois vendedores e um
   cliente. Somente Master cria regras, rateia e registra pagamentos.
   Documentação prepara/aprova assinaturas; vendedor só vê seus documentos e
   seu extrato. Cliente acessa PDFs de contratos próprios via políticas.

## Regras e dinheiro

A regra original continua 2% AGSur, US$ 7.500 no bolo vendedores e, em venda por
indicação, US$ 3.000 separados do bolo: saldo vendedores US$ 4.500. Todos os
valores desta versão são explicitamente USD. Não há conversão cambial implícita.

Percentual e fixo são aditivos. Faixas substituem esses dois componentes quando
preço mínimo e quantidade mínima mensal da empresa forem atingidos. Vence a
faixa qualificante de maior preço mínimo e depois maior meta. O mês usa UTC e
as conversões são serializadas por mês para preservar a contagem da meta. A
empresa recebe o percentual configurado, independente da indicação. Se o
repasse exceder o bolo, a conversão falha, sem criar uma comissão negativa.

Cada nova venda gera snapshot da versão efetiva. Editar preço ou cadastrar regra
nova não altera snapshot, rateio ou pagamento anterior. Os valores de vendas
históricas não são recalculados. Para essas vendas não se inventa indicação.

Rateio consome valor bruto da origem (vendedores/indicação). Dedução exige motivo
para formar o líquido; ela não reabre saldo do bolo. Beneficiário interno precisa
ser Vendedor ou Admin Master ativo; externos têm nome explícito. Um beneficiário por
origem/venda evita duplicação acidental após perda de conexão. Liquidação é
integral por rateio, com chave UUID, referência e autor. Não é integração bancária.
Tabelas não oferecem writes diretos a authenticated; RPCs verificam perfil e
travam o saldo/rateio. O audit log existente recebe regras/rateios/pagamentos.

## Conexão futura do provedor

Não colocar credenciais em Flutter, Git ou PDF. Conectar o provedor escolhido ao
contrato já definido pelos RPCs:

- `signature_prepare`: staff armazena documento privado e cria rascunho, com
  SHA-256 e signatários. Geração na tela reaproveita os bytes do PDF existente.
- `signature_approve`: aprovação comercial coloca em fila. `signature_withdraw`
  permite correção só antes do processamento; preserva PDF e auditoria.
- `signature_claim`: **somente service_role**, uma tarefa por chamada, trava
  com SKIP LOCKED. Processamento expirado vira `uncertain`, sem reenvio.
- Worker deve verificar hash/tamanho/cabeçalho do PDF e contrato não cancelado
  antes da API. Credenciais/ambiente precisam estar válidos antes do claim.
- `signature_dispatched`: grava identificador remoto ou falha conhecida.
  Timeout/resultado desconhecido exige `p_uncertain=true`; nunca criar outro
  envelope automaticamente. Persistir/reconciliar o ID antes de tratar eventos.
- Webhook deve validar a autenticação oficial do provedor antes de parsear e
  aplicar eventos. Não confiar em URLs do payload: baixar PDF apenas em host
  oficial permitido, com limites de tempo/tamanho e sem redirects livres.
- Arquivar o documento final em `<envelope UUID>/signed.pdf` neste bucket privado
  antes de `signature_receive_event(...,'signed',...,p_signed_path)`. Não gravar
  Assinado a partir de evento individual de um signatário; usar o estado final
  do envelope consultado no provedor. `signer_email` identifica os eventos
  individuais, mas não substitui a verificação do estado do documento.
- Eventos duplicados não reaplicam e estados terminais não regridem. Registrar
  sucesso apenas após confirmar persistência. Uma falha no download deve gerar
  retry do arquivamento/evento, nunca outro envio para assinatura.
- Após configurar: homologar envio, visualização, cada signatário, assinatura
  final, recusa, evento atrasado, repetição e PDF pelo cliente correto. Só depois
  agendar worker e realizar envio real explicitamente autorizado.

## Testes locais

```sh
npm install --prefix /tmp/agsur-commercial-tests @electric-sql/pglite@0.5.9
PGLITE_MODULE=/tmp/agsur-commercial-tests/node_modules/@electric-sql/pglite/dist/index.js node --test supabase/tests/commercial.test.mjs
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build web --release
```

Os fixtures reproduzem tabelas e helpers externos às novas migrations. São testes
de regressão de lógica/ACL; não substituem dry-run no schema real, testes com JWTs
reais nem homologação da API externa.

## Revisão de migrations (19/10/2026)

Gate `.claude/skills/db-migration-security-review/SKILL.md` aplicado localmente:

| Item | Resultado |
|---|---|
| Tabelas novas | RLS habilitada; anon sem grants; authenticated sem DML direto |
| Views novas | Não há; RPCs de extrato/listagem filtram o chamador internamente |
| Funções definer | search_path fixo, entradas validadas, checagem de perfil nas RPCs de usuário |
| RPCs de processamento/evento | EXECUTE revogado de PUBLIC, anon e authenticated; concedido somente a service_role |
| Storage | Bucket novo privado, 15 MB, application/pdf, leitura por vínculo ao contrato |
| Campos financeiros existentes | Triggers anteriores preservadas; nova guarda congela comissão e audit log registra os lançamentos |
| Idempotência | IDs de pedido, unicidade por beneficiário/origem e pagamento/rateio; locks; sem reenvio automático de resultado desconhecido |
| Reversibilidade | Procedimento abaixo; registros financeiros e PDFs não são apagados |
| Dry-run e smoke remoto | Pendentes; fixture isolado não confirma o schema/grants efetivos de produção |

Os testes simulam os defaults Supabase que concedem privilégios a anon e
verificam `has_function_privilege`, `has_table_privilege`, RLS e paths privados
após as migrations. Não há endpoints HTTP de assinatura expostos nesta etapa.

Rollback operacional: voltar o frontend ao release anterior pelo CI e manter
os registros e bucket privados. Não remover tabelas, histórico ou PDFs. Se for
necessário suspender operações, revogar EXECUTE das RPCs de usuário/worker em
migration de correção revisada. Não remover o congelamento de vendas que já têm
snapshot; qualquer mudança de regra futura deve ser uma nova versão.
