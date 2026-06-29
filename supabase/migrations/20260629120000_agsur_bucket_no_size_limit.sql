-- ============================================================================
-- Bucket AGSur — remover limite de tamanho por arquivo
--
-- Contexto: manuais de aeronave (OEM/AFM/IPC) em PDF estouravam o teto de 50 MB
-- do bucket (e o teto client-side de 10 MB, já removido em storage.dart).
-- Decisão do dono: sem limite de tamanho para esses uploads.
--
-- file_size_limit = NULL  → bucket sem teto próprio; passa a valer apenas o
-- teto GLOBAL de upload do projeto (Studio → Storage → Settings → "Upload file
-- size limit"). Esse global NÃO é configurável por SQL/migration: precisa ser
-- elevado manualmente no dashboard, senão arquivos acima dele continuam sendo
-- rejeitados pelo servidor mesmo com o bucket sem limite. Ver DASHBOARD_TIER2_TODO.md.
--
-- A whitelist de MIME types (allowed_mime_types) é mantida — controle de tipo,
-- não de tamanho.
-- ============================================================================

UPDATE storage.buckets
SET file_size_limit = NULL
WHERE id = 'AGSur';
