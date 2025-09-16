-- 1. Verificar estrutura da tabela documentos_processo
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;