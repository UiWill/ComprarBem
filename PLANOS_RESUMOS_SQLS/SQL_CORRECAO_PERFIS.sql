-- =====================================================
-- CORREÇÃO DO SISTEMA DE PERFIS
-- =====================================================
-- Corrige campos que não existem nas tabelas

-- 1. RECRIAR VIEW COM CAMPOS CORRETOS
DROP VIEW IF EXISTS vw_usuarios_perfis;

CREATE OR REPLACE VIEW vw_usuarios_perfis AS
SELECT 
    u.id,
    u.email,
    u.nome, -- Usar 'nome' em vez de 'nome_completo'
    u.perfil_usuario,
    u.tenant_id,
    u.ativo,
    u.criado_em,
    cp.nome_perfil,
    cp.descricao as descricao_perfil,
    cp.modulos_acesso,
    cp.permissoes,
    t.nome as nome_tenant
FROM usuarios u
LEFT JOIN configuracao_perfis cp ON cp.perfil = u.perfil_usuario AND cp.tenant_id = u.tenant_id
LEFT JOIN tenants t ON t.id = u.tenant_id
WHERE u.ativo = true AND (cp.ativo = true OR cp.ativo IS NULL);

-- 2. COMENTÁRIO EXPLICATIVO
COMMENT ON VIEW vw_usuarios_perfis IS 'View corrigida para usuários com perfis, usando o campo nome em vez de nome_completo';