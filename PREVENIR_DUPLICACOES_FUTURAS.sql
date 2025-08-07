-- =====================================================
-- PREVENIR DUPLICAÇÕES FUTURAS
-- =====================================================

-- 1. Adicionar constraint única em documentos_processo
-- Para prevenir documentos do mesmo tipo no mesmo processo
ALTER TABLE documentos_processo 
ADD CONSTRAINT unique_documento_por_processo_tipo 
UNIQUE (processo_id, tipo_documento);

-- 2. Adicionar constraint única em dfd_processo
-- Para prevenir múltiplos DFDs no mesmo processo
ALTER TABLE dfd_processo 
ADD CONSTRAINT unique_dfd_por_processo 
UNIQUE (processo_id);

-- 3. Verificar constraints criadas
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname IN ('unique_documento_por_processo_tipo', 'unique_dfd_por_processo');

SELECT 'Constraints de unicidade adicionadas! ✅' as status;