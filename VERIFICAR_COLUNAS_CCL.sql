-- ==============================================
-- SCRIPT PARA VERIFICAR SE AS COLUNAS CCL EXISTEM
-- ==============================================

-- 1. Verificar TODAS as colunas da tabela processos_administrativos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
ORDER BY ordinal_position;

-- 2. Verificar se as colunas CCL foram criadas
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name LIKE '%ccl%'
ORDER BY column_name;

-- 3. Verificar alguns processos (sem especificar coluna numero ainda)
SELECT 
    id,
    status,
    tenant_id,
    criado_em
FROM processos_administrativos 
WHERE tenant_id = '8329e25e-8a01-4fc6-ab15-7a83dd874bde'
LIMIT 5;

-- 4. Verificar constraint de status
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND conname = 'processos_administrativos_status_check';