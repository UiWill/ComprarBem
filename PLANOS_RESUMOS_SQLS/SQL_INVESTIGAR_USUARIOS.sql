-- =====================================================
-- INVESTIGAR ESTRUTURA DA TABELA USUARIOS
-- =====================================================

-- 1. ESTRUTURA COMPLETA DA TABELA
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
ORDER BY ordinal_position;

-- 2. TODAS AS CONSTRAINTS DA TABELA USUARIOS
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass;

-- 3. ESPECIFICAMENTE O CHECK CONSTRAINT DO TIPO
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass 
AND conname LIKE '%tipo%';

-- 4. VALORES EXISTENTES NA COLUNA TIPO (se houver dados)
SELECT DISTINCT tipo, COUNT(*) as quantidade
FROM usuarios 
GROUP BY tipo
ORDER BY quantidade DESC;

-- 5. ÍNDICES DA TABELA
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'usuarios';

-- 6. INFORMAÇÕES DO ENUM SE EXISTIR
SELECT 
    t.typname,
    e.enumlabel,
    e.enumsortorder
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE t.typname LIKE '%tipo%' OR t.typname LIKE '%user%'
ORDER BY t.typname, e.enumsortorder;