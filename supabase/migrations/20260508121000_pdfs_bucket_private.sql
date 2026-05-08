-- ============================================================================
-- Bucket pdfs privado.
-- Não há referência ao bucket no código; deixá-lo público é apenas exposição
-- gratuita. Se o bucket voltar a ser usado, gerar URLs assinadas
-- (signed URLs) em vez de URLs públicas.
-- ============================================================================

UPDATE storage.buckets
SET public = false
WHERE id = 'pdfs';
