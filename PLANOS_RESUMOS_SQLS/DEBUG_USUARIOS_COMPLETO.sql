-- DIAGNÓSTICO COMPLETO DOS USUÁRIOS
-- Execute este SQL para ver a situação atual do sistema

-- 1. VER TODOS OS EMAILS NA TABELA USUARIOS
SELECT 'TABELA USUARIOS' as origem, id, email, nome, tipo, perfil_usuario, tenant_id, ativo, criado_em
FROM usuarios 
ORDER BY criado_em DESC;

-- 2. VER ESTRUTURA E CONSTRAINTS DA TABELA USUARIOS
SELECT 
    'CONSTRAINT' as tipo,
    conname as nome,
    pg_get_constraintdef(oid) as definicao
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass
UNION ALL
SELECT 
    'COLUNA' as tipo,
    column_name as nome,
    data_type || ' | ' || 
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END || ' | ' ||
    COALESCE(column_default, 'SEM DEFAULT') as definicao
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
ORDER BY tipo, nome;

-- 3. VER TODOS OS TENANTS
SELECT 'TENANTS' as origem, id, nome, descricao, ativo, criado_em
FROM tenants 
ORDER BY criado_em DESC;

-- 4. VERIFICAR EMAILS ESPECÍFICOS QUE ESTÃO DANDO ERRO
-- Substitua pelos emails que estão dando problema
SELECT 
    'VERIFICACAO_EMAIL' as tipo,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'cpm@teste.com') THEN 'EXISTE NA TABELA'
        ELSE 'NÃO EXISTE NA TABELA'
    END as status_cpm,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'ccl@teste.com') THEN 'EXISTE NA TABELA'
        ELSE 'NÃO EXISTE NA TABELA'
    END as status_ccl,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'admin@teste.com') THEN 'EXISTE NA TABELA'
        ELSE 'NÃO EXISTE NA TABELA'
    END as status_admin,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'juridico@teste.com') THEN 'EXISTE NA TABELA'
        ELSE 'NÃO EXISTE NA TABELA'
    END as status_juridico;

-- 5. VER ÍNDICES NA TABELA USUARIOS
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'usuarios';

-- 6. VERIFICAR SE HÁ TRIGGERS NA TABELA
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'usuarios';

-- 7. CONTAR REGISTROS POR STATUS
SELECT 
    'TOTAL_USUARIOS' as metrica,
    COUNT(*) as valor
FROM usuarios
UNION ALL
SELECT 
    'TOTAL_TENANTS' as metrica,
    COUNT(*) as valor
FROM tenants
UNION ALL
SELECT 
    'USUARIOS_ATIVOS' as metrica,
    COUNT(*) as valor
FROM usuarios 
WHERE ativo = true
UNION ALL
SELECT 
    'TENANTS_ATIVOS' as metrica,
    COUNT(*) as valor
FROM tenants 
WHERE ativo = true;