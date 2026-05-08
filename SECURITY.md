# Política de segurança — Agsur

## Como reportar uma vulnerabilidade

Encontrou um problema? Não abra issue público no GitHub.

**Reporte por email:** `_PREENCHER_EMAIL_DO_TIME_` (ex.: `security@agsur.com.br`)

Ao reportar, inclua se possível:

- Descrição da vulnerabilidade
- Passos para reproduzir
- Impacto (vazamento de dados, escalation, takeover)
- Sua prova de conceito (não publique, anexe ao email)

Confirmamos recebimento em até 2 dias úteis. Não estamos rodando bug bounty
formal, mas reconhecemos pesquisadores responsáveis publicamente após o
patch estar live (com sua autorização).

## Escopo coberto

- Aplicativos: `agsur-painel.vercel.app` e o agsur-app (Android/iOS/web)
- Backend: Supabase project `bkzybtmxxzpxtztesdye`
- Supply chain: dependências pinadas em `agsur-painel/pubspec.yaml` e `agsur-app/pubspec.yaml`

## Fora de escopo

- Spam, phishing genérico, sender spoofing de email transacional sem
  exploit técnico
- DoS volumétrico (rate limit é responsabilidade do CDN/Supabase)
- Vulnerabilidades em projetos pessoais de funcionários
- Engenharia social, força bruta sem novidade técnica

## Defesas em camadas (visão de alto nível)

A arquitetura está documentada em `supabase/README.md` e `RUNBOOK.md`.
Pontos relevantes para quem está testando:

- **RLS estrita.** 0 policies abertas para `public` (anon). Tentar ler
  `users`/`proposal`/`financial`/etc. com a anon key retorna `[]`.
- **Triggers BEFORE.** Mesmo que uma policy permissiva seja recriada por
  engano, triggers em 32 tabelas bloqueiam writes não-autorizados.
- **Audit log append-only.** Mudanças em campos privilegiados de `users` e
  qualquer write em `financial`/`sales`/`financing_rates`/`company` ficam
  registradas em `public.security_audit_log`.
- **MFA enforcement** para Admin Master via `custom_access_token_hook`.
- **Defesa em profundidade no client:** `check_app_access` antes do
  `signInWithPassword`, `setSentryUser` por scope, sanitização de query
  params (UUID + texto).
- **CI smoke diário** valida que o estado RLS continua o esperado.

## Política de patch

| Severidade | SLA de mitigação |
|---|---|
| Critical (acesso a dados massivos / takeover) | 24h |
| High (privilege escalation, vazamento parcial) | 7 dias |
| Medium (auth bypass parcial, info disclosure limitado) | 30 dias |
| Low (config hardening, defense-in-depth) | 90 dias |
