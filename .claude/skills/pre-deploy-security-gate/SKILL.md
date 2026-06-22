---
name: pre-deploy-security-gate
description: >-
  Checklist go/no-go de segurança antes de declarar produção pronta ou liberar um
  release do Agsur (painel web ou app). Use antes de um deploy importante ou quando
  o usuário perguntar "está pronto para produção?". Diferente do gate por-migration:
  este é por-release e cobre config de runtime, dashboard e segredos.
---

# Gate de segurança pré-deploy (Agsur)

Vá item a item. Marque ✅ / ❌ / ➖. **Qualquer ❌ em item de exposição é no-go.**
Onde possível, verifique ao vivo (skill `agsur-security-audit`); senão, peça
confirmação humana e marque como "não verificado".

## Exposição de dados (no-go se falhar)
- [ ] Nenhuma tabela `public` sem RLS.
- [ ] `anon` **não** tem SELECT/DML em tabelas/views com dado sensível.
- [ ] Views de leitura com `security_invoker=on` (ou filtro de dono justificado).
- [ ] Funções SECURITY DEFINER com `search_path` fixo e checagem de perfil.
- [ ] Buckets com dado sensível **privados**; app usa signed URLs.

## Auth / acesso
- [ ] Gate de login (`check_app_access`) presente e fail-closed (não foi apagado
      por regen FlutterFlow).
- [ ] MFA Admin Master: hook `custom_access_token_hook` ativo no Studio
      (Auth → Hooks) **e** build com `--dart-define=ENFORCE_MFA_ADMIN_MASTER=true`.
- [ ] RPCs admin (`admin_delete_app_user`, `admin_purge_orphan_auth_user`) só
      executáveis pelos roles certos, com checagem de perfil interna.

## Segredos / build
- [ ] Sem `service_role`/segredo no bundle (`grep service_role lib/` vazio).
- [ ] Prod buildado com `--dart-define` (SUPABASE_URL/ANON_KEY, SENTRY_DSN, APP_ENV,
      APP_RELEASE); sem chaves de staging.
- [ ] `key.properties`/tokens fora do git; nenhum segredo novo commitado.
- [ ] `SUPABASE_ACCESS_TOKEN` não exposto; rotacionado se foi.

## Web (só painel)
- [ ] CSP em `vercel.json`: `blob:` onde necessário; `frame-ancestors 'none'`,
      `object-src 'none'`, `base-uri 'self'`; domínios externos novos no `connect-src`.
- [ ] `flutter build web` rodado antes do deploy (Vercel não builda Flutter).

## Observabilidade / LGPD
- [ ] Sentry filtra `Authorization`/`apikey`/`Cookie`; nenhuma PII enviada.
- [ ] `DASHBOARD_TIER2_TODO.md` revisado (pendências manuais do Studio resolvidas).

## Saída
Relatório go/no-go com a lista marcada, os bloqueadores (❌) e o que ficou "não
verificado". Em no-go, liste a ação mínima para liberar.
