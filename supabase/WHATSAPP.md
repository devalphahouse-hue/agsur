# WhatsApp oficial — Sprint 1

## Estado verificado em 16/10/2026

- Código local: notas + lembretes atômicos, equipe habilitada por Admin Master, autorização por destinatário, opt-out do cliente, fila com tentativas, cancelamento, reenvio, histórico global e contextual, e webhook assinado.
- Confirmado na interface da Meta e pela Graph API oficial em 16/10: `agsur_lembrete_atendimento`, `pt_BR`, **APPROVED**, categoria **UTILITY**, corpo com uma variável numérica. Número de origem conectado: +55 11 93292-3004, Phone Number ID `1336445749554196`.
- Preflight remoto sem dados de clientes: `public.whatsapp_reminders` e `public.note_reminders` não existem (HTTP 404 / 42P01). `whatsapp-reminders` e `whatsapp-webhook` também retornam 404. Portanto, a aprovação na Meta ainda não ativou o recurso no sistema.
- A CLI local do Supabase ainda não tem sessão (`AccessTokenRequiredError`). Após confirmação explícita do usuário, o token da Meta foi gerado e salvo em `/private/tmp/agsur-whatsapp-private/whatsapp.env` (pasta 0700, arquivo 0600, fora do projeto). O App Secret ainda precisa ser recuperado/configurado. Nenhum segredo foi gravado no repositório. O login da CLI do Supabase continua pendente. O teste solicitado pela interface do próprio sistema também aguarda login no painel Agsur, aberto no Opera.
- Número pessoal autorizado pelo usuário para homologação: final **3545**, DDD **12**. Uma única mensagem de teste foi aceita pela Meta em 16/10/2026 às **14:48:56 (America/Sao_Paulo)**, status `accepted`, usando o template aprovado e o parâmetro “Teste de integração do sistema Agsur, autorizado por você”. Resultado privado em `/private/tmp/agsur-whatsapp-private/test-send-result.json`. Este envio direto comprova token/template; **não comprova a fila do Supabase nem o webhook**, que ainda não foi publicado. O usuário confirmou o recebimento da mensagem no WhatsApp em 16/10. Não reenviar automaticamente nem disparar para demais clientes.

## Fluxo interno

1. Abra **Funil de vendas → Lembretes WhatsApp**. Admin Master habilita somente os membros autorizados em **Gerenciar equipe**.
2. No lead/cliente, **Adicionar nota → Lembrete por WhatsApp**. Escolha cliente, vendedor responsável ou membros habilitados da equipe, assunto, data/hora e confirme autorização.
3. A prévia mostra a mensagem exata: o assunto e a nota são normalizados para uma linha, com limite de 860 pontos de código Unicode para manter o corpo completo abaixo de 1024. A nota original permanece íntegra na timeline.
4. A RPC `create_lead_note` grava nota, intenção e destinatários na mesma transação; telefone inválido ou ausência de autorização desfaz tudo. O request ID da modal evita repetir o agendamento se a resposta se perder e o usuário tentar salvar novamente.
5. `note_reminders` representa o lembrete; `whatsapp_reminders` continua sendo a unidade física de envio para preservar o schema da primeira implementação. Há um índice único por lembrete/telefone e uma trilha separada por tentativa em `whatsapp_dispatch_attempts` (escrita apenas por RPCs de serviço). A view `vw_reminder_dispatches` usa `security_invoker`.
6. **Cancelar lembrete** cancela todos os destinos ainda pendentes/falhos daquela intenção. Um envio já em andamento exige aguardar seu resultado. **Reenviar** agenda somente o destinatário com falha, mantendo as tentativas anteriores.
7. O histórico tem filtros/busca/paginação no servidor, atualização a cada 30 segundos, detalhe de tentativas e aviso de fila atrasada há mais de 10 minutos. A preferência do cliente permite suspender/reativar mensagens; a suspensão é revalidada antes de reclamar o envio.

## Alertas dentro do painel (solicitados em 16/10)

O sino do Dashboard reúne pendências de aeronaves e lembretes de notas.
A migration `20261016130000_whatsapp_panel_notifications.sql` libera a caixa
pessoal via RPC: aparecem intenções vencidas para o autor e para usuários do
painel que sejam destinatários internos. Outros vendedores não veem esses alertas.
A lista contém até 50 itens, com não lidos primeiro; o contador é calculado no
banco sobre todos os itens e atualizado a cada 30 segundos. Cada pessoa marca
sua própria leitura, de forma idempotente, sem alterar a leitura de colegas.

O alerta aparece mesmo com falha no envio de WhatsApp. Cancelamentos o retiram
da caixa; simulações são identificadas como “Simulação (não enviado)”. Não há
push do navegador/telefone: é um alerta persistente no sino dentro do painel.
Essa alteração está **local**, aguardando publicação de schema e build pelo CI.
O teste solicitado pelo próprio sistema ainda depende de acesso ao painel, que
foi aberto no Opera. O login de Admin Master foi confirmado posteriormente; o preflight da produção ainda retornou 404 para tabelas e funções de WhatsApp, impedindo agendar um envio real. Nenhuma nota de teste foi criada.

## Provedor e estados

Somente a **Meta Cloud API oficial**, diretamente em `graph.facebook.com`, é usada para envios reais. `WHATSAPP_DRY_RUN=true` é um modo de teste do servidor: não acessa a Meta, não envia mensagens, e o histórico mostra explicitamente **Simulação (não enviado)**.

O worker autentica Cron com `x-agsur-cron-secret` (ou o Bearer do job antigo), comparando os hashes SHA-256 sem saída antecipada. Invocações manuais com JWT precisam de usuário ativo e perfil de painel. O endpoint não permite JWT de Cliente/Piloto/Oficina. O agendamento e a gestão continuam sujeitos aos guards do banco.

Estados: Agendado → Processando → Enviado/Falha; Cancelado termina a intenção pendente. Enviado pela Meta inicialmente significa **aceito**, e o webhook detalha enviado/entregue/lido. Simulações não têm confirmação de entrega.

Falhas temporárias (429, 5xx e código 130429) têm backoff de 2, 10 e 60 minutos, até quatro tentativas automáticas. Erros de credenciais, pagamento, template e parâmetro exigem correção. O código 131042 (pagamento) não é repetido automaticamente.

Timeout/resposta de aceitação ilegível/crash após envio geram `dispatch_outcome_unknown`; claims abandonadas são finalizadas após 10 minutos. **Não são reenviados automaticamente**: a Meta não oferece idempotência em `/messages`, e o destinatário pode já ter recebido. Um callback tardio concilia o resultado; antes de criar outro lembrete, confira a Meta. Esta é uma diferença deliberada em relação ao reenvio de claims expiradas sugerido no plano original.

Eventos de uma tentativa antiga não sobrescrevem um reenvio novo; entregue/lido não regridem com callbacks atrasados. O telefone e os parâmetros são snapshots do agendamento. Destinatários que saíram da equipe, foram desativados ou optaram por não receber são descartados antes do disparo.

## Ativação do Supabase (pendente)

Fazer login na CLI oficial e vincular o projeto:

```bash
supabase login
supabase link --project-ref bkzybtmxxzpxtztesdye
supabase db push --dry-run
```

Conferir todas as migrations listadas, pois esta cópia de trabalho não tem `.git` nem histórico remoto de migrations disponível localmente. Aplicar em staging antes de produção. Manter o Cron sem os dois secrets do Vault durante a primeira configuração.

```bash
supabase secrets set WHATSAPP_DRY_RUN=true
supabase functions deploy whatsapp-reminders
supabase functions deploy whatsapp-webhook
supabase db push
supabase migration list
```

As migrations de 13/10 criam a base; `20261016120000_whatsapp_internal_workflow` completa o fluxo; `20261016121000_whatsapp_cron_observability` atualiza o job. Confirmar que `notes.id`, `leads.id` e `users.id` são UUIDs antes de aplicar. `pg_cron`, `pg_net` e Vault devem estar disponíveis; se necessário, habilitar extensões pelo Studio.

Guardar apenas nos Secrets das Edge Functions (ou usar `supabase secrets set --env-file /caminho/privado/whatsapp.env`, arquivo fora do repositório):

```dotenv
WHATSAPP_ACCESS_TOKEN=<token de System User com whatsapp_business_messaging>
WHATSAPP_PHONE_NUMBER_ID=1336445749554196
WHATSAPP_GRAPH_VERSION=v25.0
WHATSAPP_APP_SECRET=<App Secret>
WHATSAPP_WEBHOOK_VERIFY_TOKEN=<segredo exclusivo de verificação>
WHATSAPP_DISPATCH_SECRET=<segredo exclusivo do agendador>
WHATSAPP_DRY_RUN=true
```

Nome e idioma ficam congelados no agendamento: `agsur_lembrete_atendimento` e `pt_BR`. Se outro template for aprovado, ajustar o default de futuras linhas em migration e atualizar a prévia do Flutter; nunca trocar silenciosamente o corpo de itens já agendados. O template atual é:

> Olá! Este é um lembrete da Agsur sobre seu atendimento ou compromisso agendado: {{1}}. Se precisar de ajuda ou reagendar, responda a esta mensagem.

`SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` são disponibilizados pelo Supabase na função; não entram no Flutter. `verify_jwt=false` já está no config: cada endpoint faz sua própria autenticação.

Configurar na Meta callback `https://bkzybtmxxzpxtztesdye.supabase.co/functions/v1/whatsapp-webhook`, mesmo verify token, campo `messages` e app associado à WABA `2051978938788535`. O App Secret verifica HMAC SHA-256. O painel da Meta também precisa permitir webhooks de produção (na consulta anterior, o app não estava publicado).

Criar no **Vault** (separado dos Secrets de Edge Functions), somente depois dos testes de autenticação:

- `whatsapp_functions_url` = `https://bkzybtmxxzpxtztesdye.supabase.co/functions/v1`
- `whatsapp_dispatch_secret` = mesmo `WHATSAPP_DISPATCH_SECRET`.

O job `agsur-whatsapp-reminders` roda a cada minuto, até 20 envios por execução. O job de retenção remove somente logs desses jobs com mais de sete dias. Não há exclusão de respostas de outras integrações de `pg_net`.

Publicar o painel pelo processo atual do projeto com Flutter **3.41.9**. Esta cópia não é um clone Git: não houve push, PR ou deploy Vercel automático.

## Aceite antes da Sprint 2

- [ ] Migration e funções presentes em staging/produção, schema e grants conferidos.
- [ ] Sem credencial de Cron/JWT válido → rejeitado; JWT Cliente → rejeitado; painel autorizado → aceito.
- [ ] Nota sem lembrete continua funcionando.
- [ ] No painel real, agendar nota para o número autorizado; conferir sino no horário, contador e marcar como lido. Confirmar que outro vendedor não vê o alerta.
- [ ] Agendamentos para cliente, vendedor e equipe chegam ao histórico; telefone inválido não deixa nota parcial.
- [ ] Cancelamento e opt-out impedem disparo; duas execuções não reclamam o mesmo envio.
- [ ] Simulação identifica-se como simulação e não chama Meta.
- [ ] Desligar `WHATSAPP_DRY_RUN` somente com template aprovado, token ativo e fila de homologação revisada.
- [ ] Agendar **nova** nota de teste para o número autorizado pelo usuário; não reaproveitar simulação como envio real.
- [ ] Confirmar mensagem recebida e status de entrega pelo webhook. A precisão é de aproximadamente um minuto mais latência, sem promessa de entrega no segundo exato.
- [ ] Só então iniciar a implementação da Sprint 2: comissões parametrizáveis, extratos e assinatura digital.

## Testes locais

```bash
node --test supabase/tests/whatsapp.test.mjs
PGLITE_MODULE=/tmp/agsur-wa-validation/node_modules/@electric-sql/pglite/dist/index.js node --test supabase/tests/whatsapp_database.test.mjs supabase/tests/whatsapp_internal.test.mjs
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Node 24+, `@electric-sql/pglite@0.5.9` para o PostgreSQL isolado. O teste de fluxo interno executa a RPC de agendamento, o banco PostgreSQL e o worker real em dry-run, verifica a intenção/histórico e proíbe tráfego para a Meta. Cron/pg_net são simulados; sua disponibilidade e o webhook real dependem do deploy.


Validação local em 16/10/2026, com Flutter 3.41.9/Dart 3.11.5:

- Suíte Flutter completa: **73 testes aprovados**, incluindo nota simples, prévia,
  autorização, seleção de data/hora e persistência UTC pelo formulário real.
- Worker, webhook e PostgreSQL isolado: **17 testes aprovados**.
- TypeScript: `tsc --noEmit` aprovado; análise estática dos arquivos de feature
  sem erros. O navegador, o Cron e a entrega real ainda não foram homologados.
- Uma mensagem real de teste foi aceita pela Meta após autorização explícita. O acesso à aba específica da Meta no Opera funcionou; captura global foi evitada. O usuário confirmou o recebimento no WhatsApp; a homologação da fila e a confirmação automática pelo webhook ainda estão pendentes.

Atualização do aceite solicitado pelo usuário: realizar o teste pela nota do painel real e verificar WhatsApp + sino interno. Nenhuma nota real foi criada nesta sessão, pois o painel estava sem sessão autenticada naquele momento. A publicação de backend e frontend continua pendente.

Validação dos alertas no painel: 73 testes Flutter aprovados, 17 testes backend aprovados, novos arquivos sem problemas de análise e build web release concluído (`build/web`). O build é apenas local; não houve publicação pelo CI nem teste autenticado na produção.

Teste pela interface em 16/10: sessão Admin Master confirmada em `/homePage`. A navegação até `/leads` foi tentada, mas o preflight remoto novamente confirmou ausência de `whatsapp_reminders`, `note_reminders`, `whatsapp-reminders` e `whatsapp-webhook` (404). Login no painel confirmado; publicação e homologação ponta a ponta continuam pendentes.
