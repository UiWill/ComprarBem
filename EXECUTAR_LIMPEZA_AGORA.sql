-- LIMPEZA FINAL - Execute este comando

-- 1. Ver o tenant órfão antes de remover
SELECT 
    'ANTES_LIMPEZA' as momento,
    t.id,
    t.nome,
    'ÓRFÃO' as status
FROM tenants t
LEFT JOIN usuarios u ON t.id = u.tenant_id
WHERE u.tenant_id IS NULL;

-- 2. REMOVER TENANT ÓRFÃO
DELETE FROM tenants 
WHERE id NOT IN (
    SELECT DISTINCT tenant_id 
    FROM usuarios 
    WHERE tenant_id IS NOT NULL
);

-- 3. Verificar resultado
SELECT 'DEPOIS_LIMPEZA' as momento, COUNT(*) as tenants_restantes FROM tenants
UNION ALL
SELECT 'DEPOIS_LIMPEZA' as momento, COUNT(*) as usuarios_restantes FROM usuarios;