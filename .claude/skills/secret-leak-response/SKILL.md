---
name: secret-leak-response
description: >-
  Resposta a vazamento de segredo no Agsur (token do CLI Supabase, service_role
  key, anon key comprometida, key.properties Android, senha de conta admin). Use
  quando um segredo for exposto (commit, chat, log, print) ou uma conta admin for
  comprometida. Guia a contenção, rotação e verificação. Complementa o RUNBOOK.md.
---

# Resposta a vazamento de segredo

Aja por **classe de segredo**. Princípio: **rotacionar primeiro, investigar depois**.
Para incidente amplo (conta comprometida, escalonamento), siga também
`agsur-main/RUNBOOK.md`.

## 1. SUPABASE_ACCESS_TOKEN (token do CLI, `sbp_...`)
Dá acesso à Management API (rodar SQL, ler config) do projeto.
- **Rotacionar**: supabase.com/dashboard/account/tokens → revogar o vazado, gerar novo.
- Atualizar onde é usado: `~/.claude/.../settings.local.json` local, secrets do CI
  (`.github/workflows`). Nunca commitar (está no `.gitignore`).
- Verificar uso indevido: revisar logs do projeto / `security_audit_log` no período.

## 2. service_role key
Bypassa RLS — comprometimento é **crítico**.
- Confirmar que **não** está no client (deveria estar só em servidor/CI):
  `grep -rniE "service_role" lib/` deve ser vazio (exceto `auth_is_service_role`).
- Rotacionar via Dashboard → Settings → API (gera novas keys do projeto).
  Atenção: rotacionar **JWT secret** invalida tokens existentes (logout geral).
- Atualizar CI/funções server-side.

## 3. anon key
Pública por design (vai no bundle). Não é "vazamento" — mas se foi abusada, o
problema real é **grant/RLS**, não a key. Rode `agsur-security-audit` e feche
grants para `anon`. Rotacionar a anon key exige rebuild/redeploy do client.

## 4. key.properties (assinatura Android)
- Está no `.gitignore`. Se vazou, rotacionar a keystore/credenciais de upload da
  Play Console; revisar histórico do git (`git log --all -- '*key.properties*'`).

## 5. Senha/sessão de conta admin comprometida
- Forçar logout: revogar sessões/refresh (a RPC `admin_delete_app_user` já faz para
  exclusão; para reset, usar Dashboard → Auth → Users → revoke). Resetar senha.
- Se for Admin Master: **ativar/confirmar MFA** (hook + `ENFORCE_MFA_ADMIN_MASTER`).
- Auditar `security_audit_log` por mudanças em campos privilegiados no período.

## Pós-incidente
- Verificar o `.gitignore` cobre o segredo; se o segredo entrou no histórico do
  git, considerar reescrita de histórico / rotação obrigatória.
- Registrar o incidente e a correção no `RUNBOOK.md`.
- Reauditar com `agsur-security-audit`.
