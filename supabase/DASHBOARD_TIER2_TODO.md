# Tier 2 — Pendências do Supabase Studio (precisa do dashboard)

> O token do CLI/Management API tem permissão limitada (`developer` scope) e
> retorna 403 nos endpoints `/v1/projects/{ref}/config/auth`. Esses 5 ajustes
> têm que ser feitos manualmente.

**Acesso:** https://supabase.com/dashboard/project/bkzybtmxxzpxtztesdye

---

## 1. Site URL real

**Onde:** Authentication → URL Configuration → Site URL
**Valor atual:** `http://localhost:3000`
**Trocar para:** o domain de produção (ex.: `https://painel.agsur.com.br`)
**Por quê:** magic-link, password recovery e invitations geram URLs com base
nesse valor. Com `localhost`, links saem quebrados em produção.

Se precisar suportar mais de uma URL (ex.: preview de Vercel), adicione em
**Redirect URLs** abaixo.

---

## 2. Forçar re-autenticação para troca de senha

**Onde:** Authentication → Configuration (rolar até "Security")
**Toggle:** **Enable secure password change** → ON
(corresponde a `security_update_password_require_reauthentication=true`)
**Por quê:** sem isso, atacker que pegou a sessão consegue trocar a senha
sem reautenticar.

---

## 3. Session inactivity timeout

**Onde:** Authentication → Sessions
**Valor atual:** `Inactivity timeout = 0` (sem timeout)
**Trocar para:** `3600` segundos (1 hora) — ou o que fizer sentido pro time
**Por quê:** sessão admin esquecida em uma máquina compartilhada vira janela
de ataque indefinida.

Opcional: definir também **Time-box** (ex.: `28800` = 8h, força re-login depois
do horário de trabalho).

---

## 4. Habilitar e enforçar MFA

**Onde:** Authentication → Multi-Factor (MFA)

1. Confirme que **TOTP factor** está ativado (default).
2. Authentication → Configuration → **MFA Allow Low AAL** → **OFF**
   (sem isso, JWTs aal1 continuam válidos mesmo com MFA cadastrado).

Depois de fazer isso:

**Ordem importante (evita lockout):**

3. **Cadastrar TOTP em todas as contas Admin Master primeiro.** No próprio
   painel ou via Supabase Auth. Sem isso, ativar o hook tranca todo
   mundo fora.
4. Authentication → **Hooks** → **Custom Access Token**
   - Toggle: ON
   - Type: Postgres
   - Schema: `public`
   - Function: `custom_access_token_hook`
5. Salvar.

A função `public.custom_access_token_hook(jsonb)` já está deployada (migration
`20260508121400_mfa_enforcement_hook.sql`). Ela rejeita JWT issue para
`profile_type = 'Admin Master'` sem `aal = 'aal2'`.

6. **Ativar enforcement client-side no build do painel:**
   ```powershell
   flutter build web --release `
     --dart-define=ENFORCE_MFA_ADMIN_MASTER=true `
     --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
     --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
     --dart-define=SENTRY_DSN=$env:SENTRY_DSN
   ```
   Sem essa flag, o gate fica desativado (default OFF, lockout-safe).

---

## 5. (Opcional) Disable signup público

**Onde:** Authentication → Configuration → Allow new users to sign up
**Status atual:** ON (qualquer um pode criar conta de Cliente via app)
**Considere desligar** se:
- O onboarding de Cliente passa por um humano da Agsur
- Vocês querem evitar criação massiva de contas fake

Se Cliente realmente cria conta sozinho pelo app, deixar ON.

---

## 6. Teto global de upload do Storage

**Onde:** Storage → Settings → "Upload file size limit"
**Valor atual:** padrão do projeto (50 MB)
**Por quê:** os manuais de aeronave (OEM/AFM/IPC) passaram a ser "sem limite" —
o teto client-side foi removido (`storage.dart`) e o `file_size_limit` do bucket
`AGSur` foi para `NULL` (migration `20260629120000_agsur_bucket_no_size_limit.sql`).
**Mas o teto GLOBAL do projeto continua valendo** e não é configurável por SQL.
Enquanto ele estiver em 50 MB, arquivo maior que isso volta erro do servidor
mesmo com o bucket sem limite. Suba esse valor para o máximo desejado (o limite
do plano é o teto real — uploads padrão acima de ~50 MB podem exigir upload
resumável).

---

## Checklist final

- [ ] 1. Site URL trocado
- [ ] 2. `Enable secure password change` ON
- [ ] 3. `Inactivity timeout` = 3600
- [ ] 4. `MFA Allow Low AAL` OFF + Hook `custom_access_token_hook` ativado + TOTP cadastrado em todos os Admin Masters
- [ ] 5. (decisão de produto) Disable signup público — Sim/Não
- [ ] 6. Teto global de upload do Storage elevado (senão o "sem limite" dos manuais para em 50 MB)
