-- Corrigir problema de Foreign Key na tabela configuracao_numeracao

-- 1. Verificar a constraint que está causando problema
SELECT 
    'CONSTRAINTS PROBLEMÁTICAS' as titulo,
    constraint_name,
    table_name,
    column_name,
    foreign_table_name,
    foreign_column_name
FROM information_schema.key_column_usage kcu
JOIN information_schema.table_constraints tc ON kcu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc ON kcu.constraint_name = rc.constraint_name
JOIN information_schema.key_column_usage fkcu ON rc.unique_constraint_name = fkcu.constraint_name
WHERE kcu.table_name = 'configuracao_numeracao'
AND tc.constraint_type = 'FOREIGN KEY';

-- 2. SOLUÇÃO A: Remover a constraint problemática (RECOMENDADO)
ALTER TABLE configuracao_numeracao DROP CONSTRAINT IF EXISTS configuracao_numeracao_tenant_id_fkey;

-- 3. Verificar se a constraint foi removida
SELECT 
    'APÓS REMOÇÃO' as status,
    constraint_name,
    table_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'configuracao_numeracao' 
AND constraint_type = 'FOREIGN KEY';

-- 4. ALTERNATIVA: Se a constraint for necessária, verificar se o tenant existe na tabela users
SELECT 
    'VERIFICAR TENANT NA TABELA USERS' as titulo,
    id,
    email,
    created_at
FROM auth.users 
WHERE id = 'd2b01426-7045-4e3f-874f-5d63522e15a4';

-- 5. Se não existir, inserir o tenant na tabela users (CUIDADO!)
-- INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at)
-- VALUES (
--     'd2b01426-7045-4e3f-874f-5d63522e15a4',
--     'sistema@comprarbem.gov.br',
--     NOW(),
--     NOW(),
--     NOW()
-- );

-- 6. Verificar estrutura da tabela configuracao_numeracao
SELECT 
    'ESTRUTURA CONFIGURACAO_NUMERACAO' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'configuracao_numeracao'
ORDER BY ordinal_position;

-- 7. Testar inserção simples (comentado para não inserir dados desnecessários)
-- INSERT INTO configuracao_numeracao (tenant_id, tipo_processo, ultimo_numero, ano_atual)
-- VALUES ('d2b01426-7045-4e3f-874f-5d63522e15a4', 'PADRONIZACAO', 0, 2024);

-- 8. Ver registros existentes
SELECT 
    'REGISTROS EXISTENTES' as titulo,
    *
FROM configuracao_numeracao
LIMIT 5;