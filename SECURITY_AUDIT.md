# Auditoria de Segurança — Agsur (2026-06-22)

Auditoria do backend Supabase + cliente Flutter. Backend verificado **ao vivo**
via Management API (read-only). Tooling para reauditar: skill `agsur-security-audit`
e agentes `supabase-security-auditor` / `flutter-client-security-reviewer`.

> Reauditar após qualquer mudança de schema. Atualizar este arquivo a cada rodada.

## Postura geral

Base sólida de defesa em profundidade (RLS em 100% das tabelas, triggers BEFORE,
audit log, gate de login fail-closed, MFA hook, CSP fechada, sem `service_role` no
client). **Porém** há **exposição crítica de dados** por defaults inseguros em
**views** e **Storage**: parte do PII/financeiro é legível **sem login** com a
anon key pública. Prioridade máxima: fechar esses vetores.

## Remediação aplicada (2026-06-22)

Migration `20260622130000_revoke_anon_views_and_fix_is_adm` (aplicada e verificada):
- ✅ **#1 (caminho não autenticado) FECHADO** — revogado todo privilégio de `anon`
  em todas as views (`anon` em views: 0). PII/financeiro não é mais legível sem
  login. *Pendente:* IDOR para usuário **autenticado** (views ainda definer).
- ✅ **#4 RESOLVIDO** — `is_adm` agora com `search_path=public`.
- Verificado: tabelas-base mantêm 231 grants a `anon`, porém **inertes** — toda
  policy se auto-bloqueia por `auth.uid()` (NULL p/ anon). Higiene: migrar essas
  policies para `TO authenticated`.

Migration `20260622140000_views_security_invoker_panel` (aplicada e verificada):
- ✅ **#2 (IDOR autenticado) FECHADO nas views do painel** — `security_invoker=on`
  em `vw_get_clients`, `vw_get_pilots`, `vw_contract_data`, `vw_notes_details`,
  `vw_all_tracking` (validado por RLS: Admin/Vendedor leem via
  `auth_is_seller_or_admin()`; Cliente/Piloto só o próprio). `vw_proposal_data` já
  estava com invoker.
- ⚠️ **Validar no painel** (Admin **e** Vendedor): listas de clientes, pilotos,
  contratos, tracking e notas devem carregar normalmente. Rollback imediato:
  `alter view public.<v> set (security_invoker = off);`

Migration `20260622150000_dashboard_security_invoker` (aplicada e verificada):
- ✅ **`vw_homepage_dashboard` FECHADA** — `security_invoker=on`. Seguro: getters
  do Row são nullable e a UI gateia financeiro por `isAdminMaster`. Admin vê tudo;
  Vendedor recebe null em financial/sales (UI esconde); Cliente/Piloto filtrados.
  *Validar:* dashboard do Admin Master com números completos; Vendedor sem quebrar.

Migration `20260622160000_company_select_restrict` (aplicada e verificada):
- ✅ **Leak de `company` FECHADO** — SELECT era `true` (qualquer autenticado lia
  todas as empresas: nome, cnpj/cpf, telefone, e-mail). Restrito a
  `auth_is_seller_or_admin()`. Seguro: app cliente não usa `CompanyTable`,
  `vw_my_aircraft*` não junta company, e as views de painel são lidas por Admin/Vendedor.

## Pendente — exige teste nos apps ou ação do dono

Não aplicado headless de propósito (quebraria app/produção sem validação):

### A. Buckets privados + signed URLs (🟠 Alto) — CONVERSÃO FEITA, FALTA O FLIP
- ✅ **Helper** `app_storage.dart` nos dois apps (`agsur-main/lib/core_ui/`,
  `agsur-app/lib/core/ui/`) — `signedUrlFor`/`SignedNetworkImage`/`openStorageDoc`,
  fallback-safe.
- ✅ **Leituras convertidas**: agsur-main (24 pontos) e agsur-app (10). Nada muda
  hoje (URL assinada funciona com bucket público).
- ⏳ **Flip pendente — bloqueado por adoção mobile.** O `agsur-app` é nativo: tornar
  `AGSur`/`service-letters` privados **quebra clientes que ainda não atualizaram**
  (leem por URL pública). Só flipar depois que a versão com signed URLs estiver
  amplamente adotada (App Store/Play). Comando do flip (reversível na hora com
  `public=true`):
  `update storage.buckets set public=false where id in ('AGSur','service-letters');`
  Antes do flip: validar exibição de foto/documento no painel e no app.
1. Helper de signed URL no client + trocar os pontos de leitura/preview/download
   (catálogo, detalhes, "Visualizar", certificados) nos **dois apps** — funciona
   com o bucket ainda público.
2. Testar exibição nos dois apps.
3. Só então `update storage.buckets set public=false where id in ('AGSur','service-letters');`
   (e migrar objetos sensíveis se preciso). Avaliar manter fotos de catálogo
   públicas e privar só documentos (ex.: mover docs para o bucket `pdfs`, já privado).

### B. IDOR autenticado em `vw_my_aircrafts_home` / `vw_my_aircraft_details` (🟠 Médio)
São lidas pelo **app cliente** e juntam `user_aircraft → contract → proposal →
aircrafts (+ aircraft_manuals/aircraft_items)`. Ligar `security_invoker` exige que
**Cliente e Piloto/Oficina vinculados** passem na RLS de todas essas tabelas. Hoje
faltam: caminho "vinculado" em `user_aircraft` (só owner/seller) e SELECT do
dono/vinculado em `aircraft_manuals` (admin-only) → flipar quebraria piloto/oficina
e sumiria os manuais. **Plano:** adicionar policies aditivas (linked) em
`user_aircraft`, `contract`, `proposal`, `aircraft_manuals` cobrindo
owner+vinculado, **depois** `set (security_invoker=on)` nas 2 views, e **testar no
app mobile** (Cliente, Piloto, Oficina). Rollback: `set (security_invoker=off)`.

### C. Ações do dono (não automatizáveis com segurança)
- ⚪ **MFA**: **despriorizado por decisão de produto (2026-06-22)** — o fluxo de
  cadastro/step-up chegou a ser implementado e foi **revertido** (commit
  `48e0b45`); continua no histórico do git se quiser retomar. A infra server-side
  segue pronta (função `custom_access_token_hook` + flag `ENFORCE_MFA_ADMIN_MASTER`,
  ambas OFF). **Risco residual aceito:** contas admin ficam protegidas só por
  senha + gate de login (`check_app_access`, fail-closed). TOTP está habilitado no
  projeto, então dá pra retomar a qualquer momento.
- 🟡 **Rotacionar** o `SUPABASE_ACCESS_TOKEN` (exposto em chat).
- 🟢 Higiene opcional: policies com `anon`/`public` → `TO authenticated` (hoje já
  inertes por se auto-bloquearem em `auth.uid()`).

## Achados

| # | Sev | Achado | Evidência | Correção |
|---|-----|--------|-----------|----------|
| 1 | 🔴 Crítico | `anon` (chave pública, embarcada no web) tem SELECT + DML em TODAS as views `vw_*` | `role_table_grants`: anon SELECT/INSERT/UPDATE/DELETE/TRUNCATE em `vw_get_clients`, `vw_contract_data`, `vw_get_pilots`, `vw_proposal_data`, `vw_homepage_dashboard`, `vw_all_tracking`, `vw_my_aircraft*`, `vw_notes_details` | `revoke all on <view> from anon;` (e revogar DML de `authenticated`, manter só `select`) |
| 2 | 🔴 Crítico | Views são SECURITY DEFINER (`security_invoker` off) → ignoram a RLS das tabelas-base; combinado com #1, leitura de dados de terceiros sem login | `pg_class.reloptions` "(sem opts)" em 8 views; só `pilot_certificates_view` e `vw_proposal_data` têm `security_invoker=on` | `alter view <v> set (security_invoker = on);` revalidando cada view (algumas leituras dependem de chain por e-mail — testar) |
| 3 | 🔴 Alto | Buckets `AGSur` e `service-letters` são **públicos** → documentos (contratos, certificados, manuais, fotos) world-readable por URL | `storage.buckets.public = true` | tornar privados + signed URLs no app; manter só assets realmente públicos |
| 4 | 🟠 Médio/Alto | `is_adm(uuid)` é SECURITY DEFINER **sem `search_path`** → escalonamento por search_path injection | `pg_proc`: `is_adm` sem `proconfig search_path` (lê `public.users`) | `alter function public.is_adm(uuid) set search_path = public;` (ou migrar p/ `auth_is_admin`) |
| 5 | 🟡 Médio | MFA não obrigatório: hook `custom_access_token_hook` **não ativado** no Studio e enforcement client-side default OFF | `DASHBOARD_TIER2_TODO.md`; `ENFORCE_MFA_ADMIN_MASTER=false` | ativar hook em Auth→Hooks + build com flag após todos os Admin Master cadastrarem TOTP |
| 6 | 🟡 Médio | `SUPABASE_ACCESS_TOKEN` (CLI) foi exposto em chat | sessão 2026-06-22 | **rotacionar** em supabase.com/dashboard/account/tokens |

### Forte (manter)
- RLS habilitado em **todas** as tabelas públicas.
- Triggers BEFORE independentes de RLS; audit log append-only; soft-delete protection.
- Gate de login via `check_app_access` (fail-closed) + helpers SECURITY DEFINER
  com `search_path` fixo (exceto `is_adm`).
- Sem `service_role`/segredo no bundle; env via `--dart-define`; `key.properties` gitignorado.
- CSP com `frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'`, `connect-src` escopado.
- Exclusão de usuário unificada na RPC `admin_delete_app_user` (ban + libera e-mail);
  signup trata e-mail duplicado e faz rollback de conta órfã.

## O que precisa ser protegido / não exposto

| Classe | Exemplos | Em trânsito | Em repouso | Controle de acesso |
|---|---|---|---|---|
| Segredos | `service_role` key, `SUPABASE_ACCESS_TOKEN`, signing `key.properties` | TLS | nunca no client/git; CI secrets / Supabase Vault | só servidor/CI |
| PII (LGPD) | nome, **CPF**, CNPJ, e-mail, telefone, endereço | TLS ✓ | disco AES-256 (Supabase) | **RLS + grants** (vetor #1/#2) |
| Financeiro | propostas, taxas, contratos, vendas | TLS ✓ | AES-256 | RLS + audit log |
| Documentos | contratos/certificados/manuais PDF, fotos | TLS ✓ | AES-256 | **bucket privado + signed URL** (vetor #3) |

**Orientação profissional:** o risco real aqui **não é falta de criptografia de
coluna** — é **controle de acesso** (grants para `anon`, views definer, buckets
públicos). Fechar isso protege PII/financeiro muito mais que cifrar campos.
Criptografia de coluna (`pgcrypto`) ou **Supabase Vault** é um passo posterior e
pontual — candidato: segredos guardados no banco e, se exigido por compliance, o
CPF (custo: quebra busca/índice e exige gestão de chave). A criptografia em
repouso do disco já é padrão do Supabase.

## Roadmap

**Imediato (fecha exposição):**
1. `revoke` de `anon` em todas as `vw_*` (e DML de `authenticated`). Baixo risco — tudo exige login.
2. `is_adm` → `set search_path = public`.
3. Tornar `AGSur`/`service-letters` privados + signed URLs no app (revisar pontos de upload/preview).

**Curto prazo:**
4. `security_invoker=on` nas views, revalidando cada leitura (chains por e-mail).
5. Ativar MFA hook no Studio + `ENFORCE_MFA_ADMIN_MASTER=true`.
6. Rotacionar o access token.

**Manutenção:** rodar o skill `db-migration-security-review` em toda migration nova
e `agsur-security-audit` periodicamente / antes de produção.
