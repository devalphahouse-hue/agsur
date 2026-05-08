-- ============================================================================
-- Defesa em camadas — storage buckets
--
-- Buckets atuais:
--   AGSur            público, sem limite, sem mime — uso geral (fotos perfil/aeronave/tracking)
--   pdfs             público, sem limite, sem mime — não referenciado no código
--   service-letters  público, 20MB, application/pdf — bem configurado
--
-- Mudanças:
--   1. AGSur: limite 50MB e whitelist de mime types (imagens + docs)
--   2. pdfs:  limite 20MB e whitelist application/pdf
--   3. policies all_access permissivas: deixadas no lugar (writes já são
--      protegidos pelas triggers nas tabelas de metadados; mexer aqui sem
--      conhecer todos os fluxos arrisca quebrar a aplicação)
-- ============================================================================

UPDATE storage.buckets
SET
  file_size_limit = 52428800,  -- 50 MB
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/csv',
    'text/plain'
  ]
WHERE id = 'AGSur';

UPDATE storage.buckets
SET
  file_size_limit = 20971520,  -- 20 MB
  allowed_mime_types = ARRAY['application/pdf']
WHERE id = 'pdfs';
