# Clicksign oficial

Provedor definido em 28/10/2026. Integração de Envelope API v3, sem intermediário.

## Configuração privada no Supabase

Configure somente nos Secrets das Edge Functions:

- `CLICKSIGN_ENVIRONMENT`: `sandbox` para homologação; `production` somente com aceite.
- `CLICKSIGN_ACCESS_TOKEN`: token do ambiente escolhido.
- `CLICKSIGN_WEBHOOK_SECRET`: HMAC SHA256 Secret gerado no cadastro do webhook.
- `CLICKSIGN_ENABLED`: `true` somente após conferir ambiente, conta e destinatários.
- `SIGNATURE_DISPATCH_SECRET`: gerado pelo workflow de publicação e guardado
  também no Vault. Não usar o token da Clicksign como chave do Cron.

Callback: `https://bkzybtmxxzpxtztesdye.supabase.co/functions/v1/clicksign-webhook`.
Cadastrar `sign`, `signature_started`, `refusal`, `auto_close`, `close`,
`document_closed`, `cancel` e `deadline`. A assinatura é verificada com o
`Content-Hmac` oficial, antes de ler o JSON. Eventos desconhecidos são ignorados.

Os tokens, ambientes e contas de sandbox e produção são diferentes. O sandbox
não gera contratos com validade jurídica. O token nunca passa pelo Flutter.

## Fluxo

1. Documentação ou Master prepara o PDF e revisa os signatários; aprovação
   comercial coloca o envelope na fila.
2. O Cron chama `contract-signatures` a cada minuto, com segredo privado. Sem
   configuração válida e habilitação explícita, nenhum documento é reclamado.
3. O worker verifica contrato e hash do PDF privado. Cria o envelope e salva o
   identificador antes de subir documento, adicionar signatários/requisitos,
   ativar e enviar a notificação por e-mail.
4. A autenticação de cada signatário usa token de e-mail. Não há assinatura
   automática nem aceite em nome de qualquer parte.
5. Webhooks autenticados são gravados em inbox durável antes da resposta 202.
   O processamento é idempotente, com claim e nova tentativa de arquivamento.
6. Um `sign` registra apenas a assinatura daquela pessoa. O contrato só muda
   para Assinado após todos os signatários esperados, fechamento, consulta à
   API e armazenamento do PDF final privado. Fechamentos parciais não bastam.
7. A API é consultada em resposta ao fechamento recebido, sem polling periódico
   de documentos. O arquivo é baixado apenas de host oficial permitido, sem
   repassar Authorization ao storage externo nem seguir redirects.

Uma falha após criar o envelope preserva seu ID e vira Conferência necessária.
Não há reenvio automático de criação incerta. Confira o envelope chamado
`Agsur <UUID interno>` na Clicksign antes de qualquer nova preparação.

## Publicação e aceite

PR com migrations revisadas, CI de banco e testes obrigatórios. Após merge,
`Publish sprint backend` aplica migrations, configura segredo do agendador e
publica as quatro funções de WhatsApp/assinatura; o frontend usa o workflow
Vercel existente. O workflow não inventa token/secret nem habilita a Clicksign.

Homologar com contrato fictício no sandbox e destinatários autorizados:
preparação, aprovação, e-mail, assinatura individual, fechamento, PDF privado,
recusa, evento duplicado e acesso negado a outro cliente/vendedor. Depois repetir
um envio real explicitamente autorizado no ambiente de produção. Sem esses
resultados, manter a Sprint 2 em andamento.

## Fontes oficiais consultadas

- https://developers.clicksign.com/docs/ambientes-autenticacao-e-formato
- https://developers.clicksign.com/docs/guia-de-criacao-o-passo-a-passo-padrao
- https://developers.clicksign.com/docs/seguranca-de-webhooks
- https://developers.clicksign.com/docs/eventos
- https://developers.clicksign.com/reference/api-upload-documentos
- https://developers.clicksign.com/reference/detalhes-do-documento
