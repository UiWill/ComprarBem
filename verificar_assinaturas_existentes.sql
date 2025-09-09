-- =====================================================
-- VERIFICAR O QUE JÁ EXISTE RELACIONADO A ASSINATURAS
-- =====================================================

-- 1. Verificar se a tabela já existe
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_name = 'assinaturas_processo';

-- 2. Verificar colunas se a tabela existir
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'assinaturas_processo'
ORDER BY ordinal_position;

-- 3. Verificar políticas RLS relacionadas
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'assinaturas_processo';

-- 4. Verificar functions relacionadas
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%assinaturas%';

-- 5. Verificar triggers relacionados
SELECT trigger_name, table_name, action_statement
FROM information_schema.triggers 
WHERE table_name = 'assinaturas_processo';

-- 6. Verificar se existe alguma referência a processo_id em constraints
SELECT constraint_name, table_name, constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'assinaturas_processo';