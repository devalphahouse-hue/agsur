<!--
Use este template para qualquer PR que toque banco, auth ou hosting.
Para PRs cosméticos (textos, cor, etc.) você pode apagar as seções
não aplicáveis.
-->

## O que muda

<!-- 1–3 linhas explicando *por que* essa mudança existe. Não basta o "o quê",
o reviewer já vê pelo diff. -->

## Como testei

- [ ] `flutter analyze` passa nos dois projetos (ou nada de error novo)
- [ ] `flutter test` passa
- [ ] Rodei localmente (`flutter run -d web-server --web-port=8080/8081`)
- [ ] Fluxo manual: <descrever passos>

## Checklist de segurança (obrigatório se tocar nas pastas abaixo)

### Banco / RLS — `supabase/migrations/`
- [ ] Migration tem timestamp único e nome descritivo
- [ ] Drop/Create de policy é idempotente (`DROP POLICY IF EXISTS …`)
- [ ] Triggers BEFORE são `SECURITY DEFINER` quando consultam `users`
- [ ] Toda nova tabela com dados sensíveis tem RLS habilitada
- [ ] Toda nova tabela tem trigger de hardening (não confiar só em policy)
- [ ] Rodei `npx supabase db push --dry-run` localmente
- [ ] Atualizei `supabase/README.md` se a mudança é estrutural

### Auth / login — `lib/auth/`, `lib/pages/authentication/`, `lib/core/auth/`
- [ ] Pré-check via `check_app_access` continua falha-fechada
- [ ] Mensagens de erro genéricas (sem vazar se email existe)
- [ ] Profile gate continua bloqueando perfis indevidos
- [ ] MFA enforcement (Admin Master) preservado

### Sanitização / deep links — `lib/core/security/`, `lib/security/`
- [ ] Inputs externos passam por `parseUuid` ou `sanitizeQueryText`
- [ ] Adicionei teste em `test/sanitizers_test.dart` ou `test/jwt_utils_test.dart` se introduzi helper

### Vercel / hosting — `agsur-painel/vercel.json`
- [ ] CSP continua restrita (não adicionei `'unsafe-eval'` ou `*` em nenhuma diretiva sem justificativa)
- [ ] HSTS, X-Frame-Options, X-Content-Type-Options continuam definidos

## Logs / observabilidade

- [ ] Não logo PII (email, CPF, senhas) em produção
- [ ] Erros relevantes capturados pelo Sentry (sem `try { } catch (_) {}` silencioso)

## Pós-merge

- [ ] Migration vai precisar ser aplicada manualmente (`npx supabase db push`)? Se sim, marca data/hora de execução.
- [ ] Precisa de mudança no Supabase Studio (config de auth, hooks)? Atualizar `supabase/DASHBOARD_TIER2_TODO.md` com o quê e quando aplicar.
- [ ] Atualizei `RUNBOOK.md` se a mudança altera procedimento operacional.

## Riscos

<!-- Pelo menos uma frase. Se não consegue identificar risco, isso é um sinal
de que o PR não foi pensado o suficiente. "Trivial typo" é resposta válida. -->
