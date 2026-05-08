# CI workflows

| Workflow | Trigger | Função |
|---|---|---|
| `flutter-analyze.yml` | PR / push em `main` quando muda código Flutter | `flutter analyze` (não-fatal info/warning, código gerado) + `flutter test` |
| `supabase-db-check.yml` | PR / push quando muda `supabase/migrations/**` | Lint dos `.sql` + `supabase db push --dry-run` |
| `rls-smoke.yml` | PR em migrations + diário 06:00 UTC | Testa que anon não consegue ler `users/proposal/financial/etc.` |
| `deploy-vercel.yml` | push em `main` (não-docs) + manual | Builda `flutter web --release` e deploya no Vercel (`painel-agsur.vercel.app`) |

## Secrets necessários (GitHub → Settings → Secrets and variables → Actions → New repository secret)

### Supabase / RLS

| Secret | Para que | Onde achar |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | `db push --dry-run` | https://supabase.com/dashboard/account/tokens |
| `SUPABASE_DB_PASSWORD` | linkar projeto via CLI | Studio → Project Settings → Database |
| `SUPABASE_ANON_KEY` | smoke test do RLS + build do painel | Studio → Project Settings → API → `anon public` |

### Vercel deploy (obrigatórios para `deploy-vercel.yml`)

| Secret | Para que | Onde achar |
|---|---|---|
| `VERCEL_TOKEN` | autenticar CLI | https://vercel.com/account/tokens (criar token com escopo `Full account`) |
| `VERCEL_ORG_ID` | identificar conta/team | `vercel link` local + abrir `.vercel/project.json` (`orgId`); ou Vercel dashboard → Settings → ID |
| `VERCEL_PROJECT_ID` | identificar projeto | `vercel link` local + abrir `.vercel/project.json` (`projectId`); ou Project → Settings → General → Project ID |

### Build do painel (opcionais — sem eles o workflow usa fallback embarcado)

| Secret | Para que |
|---|---|
| `SENTRY_DSN` | reporta erros prod no Sentry; sem DSN, vira no-op |
| `SUPABASE_URL` | sobrescreve URL hardcoded no `lib/backend/supabase/supabase.dart` (útil para staging) |

> **Como obter `VERCEL_ORG_ID` e `VERCEL_PROJECT_ID` rapidamente:**
> ```powershell
> npm i -g vercel@latest
> cd <repo>
> vercel link            # escolhe o projeto painel-agsur na conta certa
> cat .vercel/project.json   # contém os 2 IDs
> ```
> O `.vercel/` é gitignored — não commitar.

## Drift detection

`rls-smoke.yml` roda diariamente para pegar drift (alguém mexendo em policies pelo Studio sem PR). Se uma policy permissiva voltar, o smoke falha e dispara notificação no GitHub.

## Como disparar deploy manual

Action → "Deploy painel to Vercel" → "Run workflow" → branch `main` → Run.

Cada push em `main` que toca `lib/`, `web/`, `pubspec.yaml`, `vercel.json` ou similar dispara automaticamente. Mudanças só de docs (`*.md`, `.github/**`, `supabase/**`) **não** disparam (paths-ignore).
