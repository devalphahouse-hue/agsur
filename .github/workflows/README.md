# CI workflows

| Workflow | Trigger | Função |
|---|---|---|
| `flutter-analyze.yml` | PR / push em `main` quando muda código Flutter | Roda `flutter analyze` em `agsur-app` e `agsur-painel` |
| `supabase-db-check.yml` | PR / push quando muda `supabase/migrations/**` | Lint dos `.sql` + `supabase db push --dry-run` |
| `rls-smoke.yml` | PR em migrations + diário 06:00 UTC | Testa que anon não consegue ler `users/proposal/financial/etc.` e não consegue fazer escalation |

## Secrets necessários (GitHub → Settings → Secrets → Actions)

| Secret | Para que | Onde achar |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | `db push --dry-run` | https://supabase.com/dashboard/account/tokens |
| `SUPABASE_DB_PASSWORD` | linkar projeto via CLI | Studio → Project Settings → Database |
| `SUPABASE_ANON_KEY` | smoke test do RLS | Studio → Project Settings → API → `anon public` |

Sem secrets configurados, os jobs entram no path "warning + exit 0" (não quebram PRs, só não validam). Configure assim que possível.

## Drift detection

`rls-smoke.yml` roda diariamente para pegar drift (alguém mexendo em policies pelo Studio sem PR). Se uma policy permissiva voltar, o smoke falha e dispara notificação no GitHub.
