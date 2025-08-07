-- LIMPEZA SEGURA DE TENANT ÓRFÃO
-- Manter usuários válidos e remover apenas tenants sem usuários

-- 1. PRIMEIRO: Ver qual tenant está órfão
SELECT 
    'TENANT_ORFAO' as tipo,
    t.id,
    t.nome,
    t.descricao,
    CASE 
        WHEN u.tenant_id IS NULL THEN 'ÓRFÃO - SEM USUÁRIOS'
        ELSE 'TEM USUÁRIOS'
    END as status
FROM tenants t
LEFT JOIN usuarios u ON t.id = u.tenant_id
WHERE u.tenant_id IS NULL;

-- 2. VER TODOS OS TENANTS COM STATUS
SELECT 
    'STATUS_TENANTS' as tipo,
    t.id,
    t.nome,
    COUNT(u.id) as quantidade_usuarios
FROM tenants t
LEFT JOIN usuarios u ON t.id = u.tenant_id
GROUP BY t.id, t.nome
ORDER BY quantidade_usuarios DESC;

-- 3. REMOVER APENAS TENANTS ÓRFÃOS (sem usuários)
DELETE FROM tenants 
WHERE id NOT IN (
    SELECT DISTINCT tenant_id 
    FROM usuarios 
    WHERE tenant_id IS NOT NULL
);

-- 4. VERIFICAR RESULTADO FINAL
SELECT 'VERIFICACAO_FINAL' as tipo, 'Tenants restantes' as info, COUNT(*) as quantidade FROM tenants
UNION ALL
SELECT 'VERIFICACAO_FINAL' as tipo, 'Usuarios restantes' as info, COUNT(*) as quantidade FROM usuarios;