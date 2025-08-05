-- VER OS REGISTROS EXISTENTES EM DETALHES

-- 1. VER TODOS OS USUÁRIOS COM DETALHES
SELECT 
    'USUARIO' as tipo,
    id,
    email,
    nome,
    tipo,
    perfil_usuario,
    tenant_id,
    ativo,
    criado_em
FROM usuarios 
ORDER BY criado_em DESC;

-- 2. VER TODOS OS TENANTS
SELECT 
    'TENANT' as tipo,
    id,
    nome,
    descricao,
    ativo,
    criado_em
FROM tenants 
ORDER BY criado_em DESC;

-- 3. VER RELAÇÃO ENTRE USUÁRIOS E TENANTS
SELECT 
    'RELACAO' as tipo,
    u.email,
    u.nome as nome_usuario,
    u.tipo as tipo_usuario,
    u.perfil_usuario,
    t.nome as nome_tenant,
    t.id as tenant_id
FROM usuarios u
LEFT JOIN tenants t ON u.tenant_id = t.id
ORDER BY u.criado_em DESC;