-- Script para verificar se a tabela recursos está funcionando corretamente
-- Execute este script para diagnosticar problemas

-- 1. Verificar se a tabela existe
SELECT 
    'TABELA EXISTE' as status,
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'recursos';

-- 2. Verificar estrutura da tabela
SELECT 
    'COLUNAS DA TABELA' as status,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'recursos'
ORDER BY ordinal_position;

-- 3. Verificar constraints
SELECT 
    'CONSTRAINTS' as status,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'recursos';

-- 4. Verificar políticas RLS
SELECT 
    'POLÍTICAS RLS' as status,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'recursos';

-- 5. Verificar se RLS está habilitado
SELECT 
    'RLS STATUS' as status,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'recursos';

-- 6. Testar inserção simples (remover após teste)
-- INSERT INTO recursos (tenant_id, ata_referencia, produto_nome, recorrente, prazo_final, fundamentacao) 
-- VALUES (
--     gen_random_uuid(), 
--     'TESTE-001', 
--     'Produto Teste', 
--     'Recorrente Teste', 
--     NOW() + INTERVAL '3 days',
--     'Fundamentação teste'
-- );

-- 7. Contar registros existentes
SELECT 
    'TOTAL DE REGISTROS' as status,
    count(*) as total
FROM recursos;

-- 8. Verificar últimos registros (se houver)
SELECT 
    'ÚLTIMOS REGISTROS' as status,
    id,
    recorrente,
    produto_nome,
    status,
    criado_em
FROM recursos 
ORDER BY criado_em DESC 
LIMIT 5;