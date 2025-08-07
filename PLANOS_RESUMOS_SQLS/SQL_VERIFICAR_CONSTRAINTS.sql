-- Verificar constraints da tabela usuarios
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass 
AND contype = 'c';

-- Verificar estrutura da tabela usuarios
\d usuarios;