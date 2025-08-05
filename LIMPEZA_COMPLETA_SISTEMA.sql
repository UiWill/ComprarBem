-- LIMPEZA COMPLETA DO SISTEMA DE USUÁRIOS E TENANTS
-- CUIDADO: Este script remove TODOS os dados de usuários e tenants
-- Use apenas para teste ou quando tiver certeza

-- 1. DESABILITAR RLS TEMPORARIAMENTE (se necessário)
-- ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE tenants DISABLE ROW LEVEL SECURITY;

-- 2. REMOVER TODOS OS USUÁRIOS
DELETE FROM usuarios WHERE email LIKE '%@%';

-- 3. REMOVER TODOS OS TENANTS
DELETE FROM tenants WHERE nome IS NOT NULL;

-- 4. RESETAR SEQUENCES (se existirem)
-- SELECT setval('usuarios_id_seq', 1, false);
-- SELECT setval('tenants_id_seq', 1, false);

-- 5. REABILITAR RLS (se foi desabilitado)
-- ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- 6. VERIFICAR SE ESTÁ LIMPO
SELECT 'USUARIOS_RESTANTES' as tabela, COUNT(*) as total FROM usuarios
UNION ALL
SELECT 'TENANTS_RESTANTES' as tabela, COUNT(*) as total FROM tenants;

-- 7. MOSTRAR ESTRUTURA ATUAL
SELECT 'ESTRUTURA_PRONTA' as status, 'Sistema limpo e pronto para novos registros' as mensagem;