# Runbook — Agsur (operações e incidentes)

Procedimentos operacionais para o produto Agsur (painel + app + Supabase
`bkzybtmxxzpxtztesdye`). Todos os comandos assumem **Windows + PowerShell**
ou **bash** com Supabase CLI instalado (`npx supabase@latest ...`).

> Antes de qualquer ação destrutiva, abra um terminal de logs em outra aba
> (`supabase logs --project-ref bkzybtmxxzpxtztesdye`) e mantenha a memória
> `supabase_cli_token` à mão.

---

## 0. Contatos e canais

| Função | Quem | Como contatar |
|---|---|---|
| On-call | _preencher_ | _preencher_ |
| Owner do produto | _preencher_ | _preencher_ |
| Supabase support (Pro) | suporte | https://supabase.com/dashboard/support/new |

---

## 1. Anon key vazada / suspeita de comprometimento

**Sintoma:** chave aparece em log público, repo público, Sentry. Volume
anormal de requests para `/rest/v1/*` no Supabase.

**Procedimento:**

1. Studio → **Project Settings → API → Reset anon key**.
2. Copiar a nova anon key.
3. Atualizar `.env.local` em dev e o secret `SUPABASE_ANON_KEY` no GitHub
   (Settings → Secrets → Actions).
4. Rebuild + redeploy do painel:
   ```powershell
   cd agsur-painel
   flutter build web --release `
     --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
     --dart-define=APP_ENV=production `
     --dart-define=APP_RELEASE=agsur-painel@<sha>
   vercel --prod
   ```
5. Rebuild + redeploy do app (TestFlight/Play Console):
   ```powershell
   cd agsur-app
   flutter build apk --release `
     --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
   ```
6. **Importante:** versões antigas do app continuam usando a chave antiga
   até serem atualizadas. A trigger de defesa em camadas no banco continua
   funcionando, mas cada minuto de delay é janela. Force-update via
   `version` mínima no app store helper.

**RTO esperado:** ≤ 30 min.

---

## 2. Usuário comprometido / suspeita de invasão de conta

### 2.1. Bloquear acesso imediato (sem deletar)

```sql
-- Marca como bloqueado: o gate em CurrentUser/login-widget impede entrada.
UPDATE public.users
SET is_active = false, status = 'blocked'
WHERE id = '<uuid_do_usuario>';

-- Invalida todas as sessões ativas (force logout):
DELETE FROM auth.refresh_tokens WHERE user_id = '<uuid>';
DELETE FROM auth.sessions WHERE user_id = '<uuid>';
```

### 2.2. Auditar atividade do usuário

```sql
SELECT occurred_at, table_name, operation, row_id, changed_fields, before, after
FROM public.security_audit_log
WHERE actor_id = '<uuid>'
ORDER BY occurred_at DESC
LIMIT 200;
```

### 2.3. Rotacionar senha forçada

Studio → Authentication → Users → buscar email → **Send password recovery**.

### 2.4. Reverter mudanças maliciosas

Pegue `before`/`after` do audit_log e faça UPDATE manual. Nas tabelas
financeiras (`financial`, `financing_rates`, `sales`), preferível usar
backup parcial (item 4).

---

## 3. Privilege escalation detectada

**Sintoma:** alerta do `rls-smoke.yml` falhando, ou usuário Cliente com
`is_admin=true`, ou pessoa não-Admin Master conseguindo trocar
`profile_type`.

**Procedimento:**

1. Investigar audit log:
   ```sql
   SELECT * FROM public.security_audit_log
   WHERE table_name = 'users'
     AND 'profile_type' = ANY(changed_fields)
     OR 'is_admin' = ANY(changed_fields)
   ORDER BY occurred_at DESC LIMIT 50;
   ```
2. Se a mudança não estava prevista, reverter:
   ```sql
   UPDATE public.users
   SET profile_type = '<valor_anterior>'::profile_types,
       is_admin = false
   WHERE id = '<uuid>';
   ```
   (Como Admin Master via Studio SQL editor — só Admin Master passa pela
   trigger.)
3. Verificar quem fez (`actor_id`/`actor_email` no audit log).
4. Se o `actor_id` é um Admin/Admin Master legítimo: comprometimento de
   conta. Pular para item 2.
5. Se o `actor_id` é nulo (anônimo) **e** a mudança foi aplicada — a trigger
   `users_block_privilege_escalation` falhou. **Bug grave.** Abrir incidente,
   pausar promoções e investigar.

---

## 4. Restore de backup

### 4.1. Ver backups disponíveis

```bash
curl -s "https://api.supabase.com/v1/projects/bkzybtmxxzpxtztesdye/database/backups" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" | jq '.backups[] | {id, inserted_at, status}'
```

Atualmente: 8 backups físicos diários (WAL-G), retenção do plano Pro.

### 4.2. Restore total via dashboard

> **Destrutivo. Substitui o banco inteiro.**

1. Studio → Database → Backups
2. Selecionar backup pelo timestamp
3. Confirmar com input do nome do projeto
4. Aguardar (~5–15 min dependendo do tamanho)
5. Reaplicar migrations posteriores ao backup, se houver:
   ```bash
   npx supabase db push
   ```

### 4.3. Restore parcial (recuperar só uma tabela)

> **Quando preferir restore parcial:** corrupção lógica em uma tabela
> específica (ex.: alguém limpou `financial` por engano).

1. Criar projeto Supabase **temporário** (free tier basta)
2. Restaurar o backup completo lá
3. Conectar via `psql` e fazer dump da tabela:
   ```bash
   pg_dump -h <temp-host> -U postgres -t public.financial --data-only > /tmp/financial.sql
   ```
4. Aplicar no projeto de produção dentro de transação:
   ```bash
   psql -h db.bkzybtmxxzpxtztesdye.supabase.co -U postgres -1 -f /tmp/financial.sql
   ```
5. Verificar contagem; se ok, fechar o projeto temporário.

**Ensaiar este procedimento antes do go-live é obrigatório.** Sem ensaio,
o restore real numa emergência vai dobrar o tempo de downtime.

---

## 5. Drift de policy / RLS

**Sintoma:** `rls-smoke.yml` (workflow diário) falha. Ou um Admin reclama
que as queries antigas dele pararam de funcionar.

**Procedimento:**

1. Comparar policies atuais com a baseline em git:
   ```bash
   curl -s -X POST "https://api.supabase.com/v1/projects/bkzybtmxxzpxtztesdye/database/query" \
     -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"query":"SELECT tablename, policyname, cmd, qual, with_check FROM pg_policies WHERE schemaname='\''public'\'' ORDER BY tablename, policyname"}' \
     > /tmp/policies-current.json
   ```
2. Diferença com a última versão checada → identificar quem mudou
3. Se mudança foi via Studio sem PR: reverter aplicando a migration mais
   recente do git (`npx supabase db push` puxa estado da pasta `migrations/`).
4. Estabelecer (no time) que mudanças de policy só vão via PR.

---

## 6. Rollback de migration

**Cenário:** uma migration recém-aplicada quebrou prod.

### Política

- Sempre criar uma **migration nova de reversão**, nunca rodar `db reset`.
- Nomear `YYYYMMDDHHMMSS_revert_<original>.sql`.
- Aplicar via `db push`.

### Quando o estrago é maior que o reversível

Se a migration corromperu dados (não só schema), e os dados não estão em
audit_log, ir para **item 4** (restore).

---

## 7. Rotação do `SUPABASE_ACCESS_TOKEN` do CLI

O token atual expira em **2026-05-13**. Procedimento:

1. https://supabase.com/dashboard/account/tokens → **Generate new token**
2. Atualizar:
   - GitHub Secret `SUPABASE_ACCESS_TOKEN`
   - Variável local em quem usa CLI
   - Memória do Claude (`supabase_cli_token.md`) — mas **não** commit
3. Revogar o token antigo no dashboard

---

## 8. Crash em produção (Sentry)

Quando o Sentry alertar:

1. Abrir https://sentry.io/agsur (ou o slug correto)
2. Filtrar por `environment:production` + última semana
3. Issue tem stack trace + breadcrumbs de Supabase calls + user.id (uuid)
4. Cruzar com `security_audit_log` se a stack passa por escrita
5. Se for crash antigo só agora visível: reabrir; CHANGELOG do release no
   Sentry mostra o commit que introduziu

### Sentry no-op

Se o Sentry parou de receber eventos:
- Verificar `--dart-define=SENTRY_DSN=...` está sendo passado no build
- `flutter run --dart-define=SENTRY_DSN=$DSN` localmente para reproduzir
- DSN pode ter sido revogado pelo time de Sentry

---

## 9. Subir nova migration em prod

Sempre por PR + CI:

1. Criar arquivo em `supabase/migrations/YYYYMMDDHHMMSS_<slug>.sql`
2. PR — `supabase-db-check.yml` faz `db push --dry-run`
3. Merge → push para main
4. Aplicar manualmente:
   ```bash
   $env:SUPABASE_ACCESS_TOKEN = "<token>"
   npx supabase db push
   ```
5. Confirmar registrado:
   ```sql
   SELECT version, name FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 5;
   ```
6. Validar fluxos críticos com smoke manual + `rls-smoke.yml` no GitHub

---

## 10. LGPD / direito de apagar dados

Solicitação do tipo "apague minha conta":

1. Pedido por email/canal oficial → ticket no sistema interno
2. Confirmar identidade do solicitante
3. Executar (Studio SQL editor como Admin Master):
   ```sql
   -- Soft delete primeiro (preserva audit log + integridade referencial)
   UPDATE public.users SET is_active = false, is_deleted = true WHERE id = '<uuid>';

   -- Hard delete depois de 30 dias (após processamento de cobranças/garantias):
   DELETE FROM auth.users WHERE id = '<uuid>';  -- cascateia em public.users via FK
   ```
4. Registrar no audit log manualmente (operação humana):
   ```sql
   INSERT INTO public.security_audit_log
     (actor_id, actor_email, table_name, operation, row_id, changed_fields)
   VALUES
     (auth.uid(), '<seu_email>', 'users', 'GDPR_DELETE', '<uuid>', ARRAY['lgpd_request']);
   ```
5. Confirmar com o cliente por escrito.

**Atenção:** dados em backups daily continuam por até 7 dias mesmo após
delete. Documentar no aviso de privacidade.

---

## 11. Ensaio mensal recomendado

Marcar no calendário:

- [ ] **Mensal:** rodar `rls-smoke.yml` manualmente (workflow_dispatch) e
      conferir resultado.
- [ ] **Trimestral:** ensaiar restore de backup em projeto temporário (item 4.3).
      Cronometrar e atualizar este runbook se o tempo subir.
- [ ] **Trimestral:** rotacionar `SUPABASE_ACCESS_TOKEN` (item 7).
- [ ] **Anual:** revisar lista de Admins/Admin Master ativos. Remover quem
      não trabalha mais com Agsur.
