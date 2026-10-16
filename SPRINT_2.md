# Sprint 2 — Gestão Comercial, Comissões e Assinatura Digital

## Ordem solicitada em 16/10/2026

A implementação desta sprint começa **após a homologação do WhatsApp no sistema**.
Esta é a preparação do escopo, não uma declaração de início/conclusão da sprint.
O teste interno simulado não substitui envio e retorno de entrega reais.

Entrada: checklist `supabase/WHATSAPP.md`, tabela e funções publicadas,
nota agendada para o destinatário autorizado e entrega confirmada pelo webhook.
Em 16/10, o preflight remoto encontrou tabelas/functions WhatsApp ausentes e a
CLI estava sem sessão. Não iniciar mudanças de comissionamento nem disparos de
contratos enquanto esse aceite estiver pendente.

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

Antes de implementar API real, definir a plataforma usada pela Agsur entre
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
