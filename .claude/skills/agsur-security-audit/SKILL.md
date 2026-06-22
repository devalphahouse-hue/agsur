---
name: agsur-security-audit
description: >-
  Roda uma auditoria de segurança completa do Agsur (backend Supabase + cliente
  Flutter) e produz um relatório priorizado. Use quando o usuário pedir revisão de
  segurança, "auditar segurança", checar exposição de dados/PII, ou antes de
  declarar produção pronta. Combina checagens ao vivo do banco com revisão do
  código cliente.
---

# Auditoria de segurança do Agsur

Objetivo: medir o nível de segurança e apontar **exposição de dados, IDOR,
escalonamento de privilégio e vazamento de segredo**, com correções acionáveis.

## Passo 0 — Pré-requisitos

- Para checagens ao vivo do banco, peça ao usuário para exportar o token do CLI
  na sessão: sugira digitar `! export SUPABASE_ACCESS_TOKEN=sbp_...`.
  Sem token, faça a parte estática (migrations + código) e marque o que ficou
  sem verificação ao vivo. **Nunca** escreva o token em arquivo nem o ecoe.
- Project ref: `bkzybtmxxzpxtztesdye`.

## Passo 1 — Despache os dois auditores (em paralelo)

- `supabase-security-auditor` → backend (RLS, grants `anon`, views definer,
  funções sem `search_path`, Storage público, grants de RPC).
- `flutter-client-security-reviewer` → cliente (segredos, gate de login, signup
  órfão, exclusão via RPC, PII em Sentry, CSP, armadilha FlutterFlow).

## Passo 2 — Checagens ao vivo de alto valor (se houver token)

Rode e interprete (queries completas estão na definição do
`supabase-security-auditor`):
1. Tabelas sem RLS → deve ser vazio.
2. Grants para `anon` → **qualquer SELECT/DML em tabela/view é exposição sem login**.
3. Views sem `security_invoker=on` → IDOR (bypassam RLS).
4. Funções SECURITY DEFINER sem `search_path` fixo.
5. `storage.buckets.public = true` com dado sensível → expor por URL.

## Passo 3 — Consolide

Produza um relatório único:
- Resumo executivo + nota de postura (o que está forte vs frágil).
- Tabela por severidade (Crítico → Baixo): Achado | Evidência | Impacto | Correção (SQL/diff).
- "O que precisa ser protegido/não exposto": segredos (service_role, access token,
  signing key), PII (CPF/CNPJ/e-mail/telefone/endereço), financeiro, documentos no
  Storage. Lembre: **controle de acesso (RLS/grants/bucket privado/signed URL)
  protege PII melhor que criptografia de coluna**; criptografia de coluna
  (pgcrypto/Supabase Vault) é passo posterior e pontual.
- Roadmap priorizado (o que corrigir já vs depois).

## Passo 4 — Remediação (só com OK do usuário)

Mudanças de segurança em produção são sensíveis. Para cada correção, gere uma
**migration** em `supabase/migrations/` (idempotente quando possível) e use o skill
`db-migration-security-review` antes de aplicar. Toda DDL vai por PR/CI; aplicar
direto só com autorização explícita. Cuidado: revogar grants de `authenticated`
pode quebrar o painel — revogar de `anon` costuma ser seguro (tudo exige login).
