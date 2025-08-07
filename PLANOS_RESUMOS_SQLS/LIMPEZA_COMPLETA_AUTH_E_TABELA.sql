-- LIMPEZA COMPLETA - Auth E Tabela
-- Execute este comando para limpar completamente o sistema

-- 1. VER O QUE TEM ATUALMENTE
SELECT 'ANTES_LIMPEZA' as momento, 'usuarios' as tabela, email, id FROM usuarios
UNION ALL  
SELECT 'ANTES_LIMPEZA' as momento, 'tenants' as tabela, nome as email, id FROM tenants;

-- 2. REMOVER TODOS OS USUÁRIOS DA TABELA
DELETE FROM usuarios WHERE email LIKE '%@%';

-- 3. REMOVER TODOS OS TENANTS 
DELETE FROM tenants WHERE nome IS NOT NULL;

-- 4. VERIFICAR SE ESTÁ LIMPO
SELECT 'DEPOIS_LIMPEZA' as momento, COUNT(*) as usuarios_restantes FROM usuarios
UNION ALL
SELECT 'DEPOIS_LIMPEZA' as momento, COUNT(*) as tenants_restantes FROM tenants;

-- 5. RESETAR SEQUÊNCIAS (se houver)
-- SELECT setval(pg_get_serial_sequence('usuarios', 'id'), 1, false);
-- SELECT setval(pg_get_serial_sequence('tenants', 'id'), 1, false);

SELECT 'SISTEMA_LIMPO' as status, 'Pronto para novos registros' as mensagem;