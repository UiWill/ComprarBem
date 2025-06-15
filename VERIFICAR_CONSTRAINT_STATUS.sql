-- VERIFICAR CONSTRAINT DE STATUS DA TABELA PRODUTOS
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'produtos' 
AND n.nspname = 'public'
AND contype = 'c'
AND conname LIKE '%status%';

-- Se não encontrar constraint específica, verificar todas as constraints
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'produtos' 
AND n.nspname = 'public'
AND contype = 'c'; 