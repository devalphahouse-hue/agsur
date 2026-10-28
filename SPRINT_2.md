# Sprint 2 — Gestão Comercial, Comissões e Assinatura Digital

## Atualização de 28/10/2026 — Clicksign escolhida

- Provedor definido pelo usuário: **Clicksign**, API oficial de Envelope v3.
- Adaptador, envio, notificação, webhook HMAC `Content-Hmac`, inbox persistente,
  retries de arquivamento e agendamento implementados. Identificadores remotos
  são persistidos antes das próximas operações; resultado desconhecido nunca
  cria outro envelope automaticamente.
- Callbacks individuais não concluem o contrato. A confirmação exige todas as
  assinaturas esperadas, evento de fechamento, confirmação na API e PDF privado.
- A tela consulta a configuração do backend e informa sandbox/produção/ativação
  pendente. Preservada a aprovação comercial antes de enviar.
- **Pendente operacional:** acesso à conta sandbox, token e secret HMAC,
  publicação pelo PR/CI e homologação real. Testes isolados não significam
  conclusão da Sprint 2 em produção.

O registro de 19/10 abaixo descreve a etapa anterior, antes da escolha do provedor.


## Implementação autorizada em 19/10/2026

O usuário autorizou expressamente iniciar esta implementação. Isso substitui a
condição anterior de aguardar a homologação do WhatsApp. O aceite operacional do
WhatsApp continua independente; iniciar esta sprint não declara aquele aceite.

### Implementado no código

- Regras versionadas por vigência futura; percentual, valor fixo e faixas por
  preço/meta mensal da empresa (mês UTC). Persistência e cálculo em PostgreSQL
  `numeric`, com arredondamento de centavos no banco.
- Trigger congela a regra em novas vendas, incluindo repasse de indicação. O
  cliente antigo continua compatível: os valores enviados por ele são
  substituídos pelo cálculo autoritativo do banco depois da migration.
- Vendas históricas preservam os valores armazenados. Não se reconstrói uma
  indicação histórica sem prova; esse saldo fica zero e a tela informa isso.
- Rateio explícito por beneficiário interno/externo e origem. O criador da
  proposta nunca recebe automaticamente o bolo. Travas de linha e limites de
  saldo impedem sobrealocação; cada beneficiário recebe um rateio por origem.
- Deduções com motivo, extratos com período/situação/beneficiário, totais sobre
  todo o filtro (não só a página), acesso de vendedor apenas ao próprio extrato.
- Liquidação integral idempotente por rateio, referência e auditoria. É um
  registro contábil de pagamento efetuado; nenhuma transferência é executada.
- Preparação de assinatura pelo PDF gerado na tela do contrato, ou seleção de
  contrato e upload de PDF. PDF, signatários e dados comerciais congelados.
- Aprovação comercial, fila com claim exclusivo, eventos deduplicados e estados
  protegidos contra regressão, correção por descarte antes do início do envio.
- PDFs em bucket privado, acesso vinculado ao contrato e URLs de 120 segundos.
  Um contrato só fica Assinado depois que existe o PDF assinado arquivado.
- Testes isolados de banco e workflow de CI em `commercial-check.yml`.

### Pendente para concluir e homologar

- O usuário ainda precisa escolher Clicksign, ZapSign ou DocuSign (pergunta
  enviada em 19/10). **Adaptador HTTP do provedor, Edge worker, webhook
  autenticado e agendamento do worker ainda não estão implementados**: isso
  depende da plataforma escolhida. Os RPCs de fila/evento já estão preparados
  e restritos a `service_role`; não há endpoint público sem autenticação.
- Configurar a conta sandbox e credenciais do provedor no backend, conectar os
  RPCs ao adaptador e validar envio, eventos por signatário e arquivamento real.
- Publicar migrations via PR e executar dry-run/autorização no projeto correto;
  os testes locais usam um PostgreSQL isolado e não alteram produção.
- Publicar frontend pelo CI existente e homologar com perfis reais. Nada neste
  documento declara a Sprint 2 100% implantada.

Detalhes de ativação e critérios de teste em `supabase/COMMERCIAL.md`.

## 2.1 — Comissões e regras comerciais

Baseline encontrado no código:

- `lib/backend/commission.dart`: retenção AGSur de 2%; comissão-base de US$ 7.500;
  com indicação, US$ 4.500 para a comissão da venda e diferença de US$ 3.000.
- A regra foi definida pelo dono em 17/08/2026. O valor de US$ 7.800 no PDF é
  apresentado como exemplo; não substituir silenciosamente o valor acordado.
- `sales.seller_commission` é o bolo da venda; o rateio entre vendedores ainda é
  externo. É necessário modelar beneficiários e repasses antes de extratos
  individuais.

Entregas previstas:

1. Regras versionadas por vigência (percentual, nominal, faixas/metas), com
   defaults preservando o comportamento atual e edição restrita por RBAC.
2. Congelar o cálculo aplicado em cada venda; alterações futuras não reescrevem
   comissões históricas nem pagamentos já liquidados.
3. Beneficiários e indicação externa com deduções/repasses explícitos, moeda e
   precisão monetária no banco; testes de limites e arredondamento.
4. Painel de provisionado/a liquidar/pago e extrato individual, filtrado no
   servidor por vendedor, período e status; conferência do total líquido.
5. Liquidação idempotente com trilha de auditoria e acesso limitado; distinguir
   registro de pagamento no sistema de uma transferência bancária real.

## 2.2 — Assinatura digital de contratos

Para completar a API real, definir a plataforma usada pela Agsur entre
DocuSign, Clicksign ou ZapSign e obter acesso ao ambiente de testes. O PDF lista
alternativas, não escolhe uma. Não contratar serviço, aceitar termos nem enviar
contratos reais em nome do cliente sem instrução explícita.

Entregas previstas:

1. Adaptador do provedor, contrato/partes/aeronave e versão do PDF congelados no
   envio; idempotência para não criar envelopes duplicados.
2. Fluxo de aprovação comercial antes do envio; nenhuma assinatura automática
   em nome das partes.
3. Webhook autenticado, deduplicado e tolerante a eventos fora de ordem; estados
   Enviado/Visualizado/Assinado/Recusado e detalhe por signatário.
4. Download e arquivamento do PDF assinado em storage privado, com verificação
   de vínculo ao contrato e acesso por URL assinada.
5. Homologação completa no sandbox e depois aceite de um envio real autorizado.

A sprint não inclui fluxo de caixa/parcelas/Google Places (Sprint 3) nem IA/RAG
(Sprint 4).

## Ajuste de apresentação autorizado em 28/10/2026

- Histórico interno unificado na linha do tempo de cada lead/cliente, com autor,
  data/hora, notas e acompanhamento dos envios vinculados a cada registro.
- Retirados o menu “Lembretes WhatsApp” e os atalhos de histórico separados.
  A rota antiga permanece para compatibilidade; não é mais uma entrada do menu.
- O registro interno continua funcionando sem notificação. O envio por WhatsApp
  permanece opcional no formulário de adicionar registro; a fila não mudou.
- Notas paginadas no servidor; consultas de envio limitadas ao cadastro e às
  notas da página. Falha no histórico de envios não esconde as notas internas.
- Este ajuste é no código local; não declara publicação nem conclusão da Sprint 2.
