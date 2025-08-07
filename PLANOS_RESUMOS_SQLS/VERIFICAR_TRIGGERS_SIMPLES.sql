-- VERIFICAR TRIGGERS NA TABELA USUARIOS
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'usuarios';

-- VERIFICAR CONSTRAINTS
SELECT 
    conname,
    contype,
    pg_get_constraintdef(oid)
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass;

-- VERIFICAR POLICIES RLS
SELECT 
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'usuarios';