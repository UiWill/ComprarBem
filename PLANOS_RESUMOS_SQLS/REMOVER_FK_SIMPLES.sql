-- Comando simples para remover a constraint problemática

-- 1. Remover a constraint que está causando o erro
ALTER TABLE configuracao_numeracao DROP CONSTRAINT IF EXISTS configuracao_numeracao_tenant_id_fkey;

-- 2. Verificar se funcionou
SELECT 
    tc.constraint_name,
    tc.table_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_name = 'configuracao_numeracao' 
AND tc.constraint_type = 'FOREIGN KEY';

-- 3. Se ainda houver constraints, listar todas para identificar
SELECT 
    'TODAS AS CONSTRAINTS' as titulo,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_name = 'configuracao_numeracao';

-- 4. Testar se consegue inserir agora
SELECT 'TESTE PRONTO' as status;