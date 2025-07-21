-- Verificar o constraint atual do campo status
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'produtos'::regclass
AND conname LIKE '%status%';