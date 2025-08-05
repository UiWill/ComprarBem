-- TESTAR EMAILS ESPECÍFICOS QUE ESTÃO DANDO ERRO
-- Substitua pelos emails que você está tentando cadastrar

-- 1. Verificar emails específicos na tabela usuarios
SELECT 
    'VERIFICACAO_EMAILS' as tipo,
    email,
    id,
    nome,
    tipo,
    perfil_usuario,
    tenant_id,
    ativo,
    criado_em
FROM usuarios 
WHERE email IN (
    'cpm@teste.com',
    'ccl@teste.com', 
    'admin@teste.com',
    'juridico@teste.com'
    -- Substitua pelos emails que você está usando
)
ORDER BY email;

-- 2. Se não encontrou nada, verificar padrões similares
SELECT 
    'EMAILS_SIMILARES' as tipo,
    email,
    id,
    nome
FROM usuarios 
WHERE email ILIKE '%teste%'
   OR email ILIKE '%cpm%'
   OR email ILIKE '%ccl%'
   OR email ILIKE '%admin%'
   OR email ILIKE '%juridico%'
ORDER BY email;

-- 3. Verificar TODOS os emails cadastrados
SELECT 
    'TODOS_EMAILS' as tipo,
    email,
    nome,
    tipo,
    tenant_id,
    criado_em
FROM usuarios 
ORDER BY criado_em DESC;

-- 4. Contar total de registros
SELECT 
    'TOTAL_USUARIOS' as metrica,
    COUNT(*) as quantidade
FROM usuarios
UNION ALL
SELECT 
    'TOTAL_TENANTS' as metrica,
    COUNT(*) as quantidade
FROM tenants;

-- 5. Verificar se há problemas de índice
REINDEX TABLE usuarios;

-- 6. Analisar constraints
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass
  AND contype = 'u'; -- unique constraints