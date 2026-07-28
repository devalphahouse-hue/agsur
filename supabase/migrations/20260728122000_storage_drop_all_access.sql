-- ============================================================================
-- F7 — CONFIRMADO EM PRODUÇÃO: policies `all_access` residuais em
--      storage.objects expõem TODOS os buckets, inclusive os privados.
-- ============================================================================
-- 20260508120500_storage_hardening registrou "policies all_access permissivas:
-- deixadas no lugar" e nenhuma migration posterior as removeu. Consulta a
-- pg_policies em 2026-07-28 confirmou as 5:
--
--   all_access            ALL     {authenticated}   USING true
--   all_access 111r2i_0   SELECT  {public}          USING true   ← inclui anon
--   all_access 111r2i_1   INSERT  {authenticated}
--   all_access 111r2i_2   UPDATE  {authenticated}
--   all_access 111r2i_3   DELETE  {authenticated}
--
-- Policies de RLS são PERMISSIVAS e se combinam com OR: enquanto qualquer uma
-- delas disser `true` sem filtrar bucket, as policies cuidadosas do chat
-- (chat_attachments_select exige auth_is_seller_or_admin() E chat_is_member())
-- não restringem NADA.
--
-- Impacto real: `chat-attachments` e `pdfs` estão marcados public=false, mas o
-- SELECT de {public} — role que inclui `anon` — libera leitura de qualquer
-- objeto de qualquer bucket para quem tem a anon key, que é pública e vai no
-- bundle do app. Ou seja: anexos de conversas internas do painel seriam
-- baixáveis SEM LOGIN por quem souber/enumerar o caminho. Marcar o bucket como
-- privado não fecha nada enquanto a policy permissiva existir.
--
-- DIMENSIONAMENTO (medido em 2026-07-28, select count(*) group by bucket_id):
--   AGSur            531 objetos   (public=true de qualquer forma)
--   chat-attachments   0 objetos
--   pdfs               0 objetos
--   service-letters    0 objetos
-- Ou seja: hoje NÃO há dado sensível exposto — os buckets privados estão
-- vazios. Isto é um buraco LATENTE, não um vazamento em curso: o primeiro
-- anexo enviado no chat interno nasceria público. É o momento barato de
-- fechar, antes de o recurso entrar em uso.
--
-- ⚠️ POR QUE NÃO BASTA DAR DROP NAS 5
-- ------------------------------------
-- As policies específicas existentes cobrem só 2 dos 4 buckets:
--   chat-attachments → chat_attachments_select/insert          ✓
--   service-letters  → service_letters_read/write/update/delete ✓
--   AGSur            → NENHUMA policy própria                   ✗
--   pdfs             → NENHUMA policy própria                   ✗
--
-- `AGSur` é o bucket de foto de perfil (app, profile_edit) e de foto/documento
-- de aeronave (painel, create_aircraft/aircraft_details). Dropar as all_access
-- sem repor deixaria esses uploads sem policy nenhuma = deny-by-default = a
-- troca de foto quebra nos DOIS apps. Por isso este arquivo REPÕE antes de
-- remover, preservando o comportamento atual do AGSur e apenas confinando-o ao
-- seu próprio bucket.
-- ============================================================================


-- ── 1. Policies próprias do bucket AGSur (repõem o que a all_access fazia) ──
-- O bucket é public=true, então a leitura pela URL de CDN nem passa por RLS;
-- a policy de SELECT cobre o caminho autenticado da API. Escrita segue com
-- `authenticated` — é o comportamento de hoje, e restringir a papel de painel
-- quebraria a troca de foto de perfil de Cliente/Piloto/Oficina no app.
-- O ganho aqui é o `bucket_id = 'AGSur'`: deixa de valer para os outros.

DROP POLICY IF EXISTS agsur_bucket_read ON storage.objects;
CREATE POLICY agsur_bucket_read ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'AGSur');

DROP POLICY IF EXISTS agsur_bucket_insert ON storage.objects;
CREATE POLICY agsur_bucket_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'AGSur');

DROP POLICY IF EXISTS agsur_bucket_update ON storage.objects;
CREATE POLICY agsur_bucket_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'AGSur')
  WITH CHECK (bucket_id = 'AGSur');

DROP POLICY IF EXISTS agsur_bucket_delete ON storage.objects;
CREATE POLICY agsur_bucket_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'AGSur');


-- ── 2. Remove as permissivas ────────────────────────────────────────────────
-- A partir daqui cada bucket vale pela sua própria policy.
DROP POLICY IF EXISTS "all_access"          ON storage.objects;
DROP POLICY IF EXISTS "all_access 111r2i_0" ON storage.objects;
DROP POLICY IF EXISTS "all_access 111r2i_1" ON storage.objects;
DROP POLICY IF EXISTS "all_access 111r2i_2" ON storage.objects;
DROP POLICY IF EXISTS "all_access 111r2i_3" ON storage.objects;


-- ── 3. `pdfs` fica sem policy = fechado (deny-by-default) ───────────────────
-- Proposital. O bucket é private e NÃO é referenciado por nenhum código dos
-- dois apps (grep por 'pdfs' em agsur-app/lib e agsur-main/lib: nada — os PDFs
-- de proposta/contrato são gerados em memória e abertos pelo
-- abrirPdfGerado, sem passar por storage). Se algum fluxo fora do código dos
-- apps escrever nele (função server-side, automação, upload manual pelo
-- Studio), ele passa a receber 403 e é preciso criar a policy própria:
--
--   CREATE POLICY pdfs_read ON storage.objects
--     FOR SELECT TO authenticated
--     USING (bucket_id = 'pdfs' AND public.auth_is_seller_or_admin());
--
-- Conferir o bucket antes de aplicar:
--   select count(*) from storage.objects where bucket_id = 'pdfs';


-- ============================================================================
-- Validação pós-aplicação
-- ============================================================================
--  DEVE FALHAR:
--   1. Com a anon key, SEM login: baixar objeto de `chat-attachments`
--      (GET /storage/v1/object/chat-attachments/<thread>/<arquivo>) → 403/404.
--   2. Usuário do app cliente (Cliente/Piloto/Oficina) lendo `chat-attachments`
--      → 403 (a policy do chat exige auth_is_seller_or_admin + chat_is_member).
--
--  DEVE PASSAR:
--   3. App: Editar perfil → trocar foto (upload no AGSur).
--   4. Painel: cadastrar aeronave com foto e anexar documento (AGSur).
--   5. App e painel: exibir foto de perfil e de aeronave já existentes.
--   6. Painel: enviar e baixar anexo no chat interno (membro da conversa).
--   7. App: abrir carta de serviço (service-letters).
--
-- Rollback (restaura a exposição — usar só se algo quebrar em produção):
--   CREATE POLICY "all_access" ON storage.objects FOR ALL TO authenticated
--     USING (true) WITH CHECK (true);
--   CREATE POLICY "all_access 111r2i_0" ON storage.objects FOR SELECT TO public
--     USING (true);
--   -- (idem 111r2i_1 INSERT / _2 UPDATE / _3 DELETE, para authenticated)
-- ============================================================================
