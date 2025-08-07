-- =====================================================
-- SISTEMA DE PERFIS DE USUÁRIO
-- =====================================================
-- Implementa controle de acesso baseado em perfis
-- 4 Perfis: CPM, CCL, Órgão Administrativo, Assessoria Jurídica
-- Todos com mesmo tenant_id mas acessos distintos

-- 1. CRIAR ENUM PARA PERFIS DE USUÁRIO
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'perfil_usuario_enum') THEN
        CREATE TYPE perfil_usuario_enum AS ENUM (
            'cpm',
            'ccl', 
            'orgao_administrativo',
            'assessoria_juridica'
        );
    END IF;
END
$$;

-- 2. ADICIONAR COLUNA PERFIL À TABELA DE USUÁRIOS (se não existir)
DO $$
BEGIN
    -- Verificar se a coluna já existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'usuarios' 
        AND column_name = 'perfil_usuario'
    ) THEN
        -- Adicionar coluna perfil_usuario
        ALTER TABLE usuarios ADD COLUMN perfil_usuario perfil_usuario_enum DEFAULT 'cpm';
        
        -- Adicionar índice para performance
        CREATE INDEX idx_usuarios_perfil ON usuarios(perfil_usuario);
        
        -- Comentário explicativo
        COMMENT ON COLUMN usuarios.perfil_usuario IS 'Perfil de acesso do usuário: cpm (acesso completo exceto CCL), ccl (somente painel CCL), orgao_administrativo (processos para assinatura), assessoria_juridica (processos para análise jurídica)';
    END IF;
END
$$;

-- 3. CRIAR TABELA DE CONFIGURAÇÃO DE PERFIS
CREATE TABLE IF NOT EXISTS configuracao_perfis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil perfil_usuario_enum NOT NULL,
    nome_perfil VARCHAR(100) NOT NULL,
    descricao TEXT,
    modulos_acesso JSONB NOT NULL DEFAULT '[]',
    permissoes JSONB NOT NULL DEFAULT '{}',
    ativo BOOLEAN DEFAULT true,
    tenant_id UUID NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT fk_configuracao_perfis_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_configuracao_perfis_tenant ON configuracao_perfis(tenant_id);
CREATE INDEX IF NOT EXISTS idx_configuracao_perfis_perfil ON configuracao_perfis(perfil);

-- 4. INSERIR CONFIGURAÇÕES PADRÃO DOS PERFIS
INSERT INTO configuracao_perfis (perfil, nome_perfil, descricao, modulos_acesso, permissoes, tenant_id)
SELECT 
    'cpm'::perfil_usuario_enum,
    'CPM - Comissão Permanente de Padronização de Materiais',
    'Acesso completo ao sistema, exceto Painel CCL. Pode criar processos, gerenciar produtos, DCB, RDM e enviar processos para tramitação.',
    '["dashboard", "cadastro_produtos", "catalogo_marcas", "classificacao", "dcb", "rdm", "processos_administrativos", "feedback"]'::jsonb,
    '{
        "processos": {
            "criar": true,
            "editar": true,
            "visualizar": true,
            "assinar": true,
            "tramitar": true,
            "finalizar": true
        },
        "produtos": {
            "criar": true,
            "editar": true,
            "visualizar": true,
            "aprovar": true
        },
        "documentos": {
            "criar": true,
            "editar": true,
            "visualizar": true,
            "assinar": true
        }
    }'::jsonb,
    t.id
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM configuracao_perfis cp 
    WHERE cp.perfil = 'cpm' AND cp.tenant_id = t.id
);

INSERT INTO configuracao_perfis (perfil, nome_perfil, descricao, modulos_acesso, permissoes, tenant_id)
SELECT 
    'ccl'::perfil_usuario_enum,
    'CCL - Comissão de Contratação e Licitação',
    'Acesso exclusivo ao Painel CCL. Recebe processos finalizados pela CPM para julgamento e emite atas.',
    '["painel_ccl"]'::jsonb,
    '{
        "processos": {
            "visualizar": true,
            "julgar": true,
            "assinar_ata": true,
            "tramitar_homologacao": true,
            "receber_finalizados": true
        },
        "atas": {
            "criar": true,
            "editar": true,
            "assinar": true
        }
    }'::jsonb,
    t.id
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM configuracao_perfis cp 
    WHERE cp.perfil = 'ccl' AND cp.tenant_id = t.id
);

INSERT INTO configuracao_perfis (perfil, nome_perfil, descricao, modulos_acesso, permissoes, tenant_id)
SELECT 
    'orgao_administrativo'::perfil_usuario_enum,
    'Órgão Administrativo',
    'Acesso aos Processos Administrativos para assinatura digital, solicitar ajustes e homologação de julgamentos.',
    '["processos_administrativos_admin"]'::jsonb,
    '{
        "processos": {
            "visualizar_pendentes": true,
            "assinar_digital": true,
            "solicitar_ajustes": true,
            "homologar": true,
            "devolver_pendencias": true
        }
    }'::jsonb,
    t.id
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM configuracao_perfis cp 
    WHERE cp.perfil = 'orgao_administrativo' AND cp.tenant_id = t.id
);

INSERT INTO configuracao_perfis (perfil, nome_perfil, descricao, modulos_acesso, permissoes, tenant_id)
SELECT 
    'assessoria_juridica'::perfil_usuario_enum,
    'Assessoria Jurídica',
    'Acesso aos Processos Administrativos para análise de minutas, editais e emissão de pareceres jurídicos.',
    '["processos_administrativos_juridico"]'::jsonb,
    '{
        "processos": {
            "visualizar_finalizados": true,
            "analisar_minutas": true,
            "emitir_parecer": true,
            "aprovar_editais": true,
            "devolver_diligencias": true
        }
    }'::jsonb,
    t.id
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM configuracao_perfis cp 
    WHERE cp.perfil = 'assessoria_juridica' AND cp.tenant_id = t.id
);

-- 5. CRIAR FUNÇÃO PARA VERIFICAR PERMISSÕES
CREATE OR REPLACE FUNCTION verificar_permissao_usuario(
    p_user_id UUID,
    p_modulo VARCHAR,
    p_acao VARCHAR DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_perfil perfil_usuario_enum;
    v_modulos_acesso JSONB;
    v_permissoes JSONB;
    v_tenant_id UUID;
BEGIN
    -- Buscar perfil e tenant do usuário
    SELECT u.perfil_usuario, u.tenant_id
    INTO v_perfil, v_tenant_id
    FROM usuarios u
    WHERE u.id = p_user_id;
    
    IF v_perfil IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Buscar configurações do perfil
    SELECT cp.modulos_acesso, cp.permissoes
    INTO v_modulos_acesso, v_permissoes
    FROM configuracao_perfis cp
    WHERE cp.perfil = v_perfil 
    AND cp.tenant_id = v_tenant_id
    AND cp.ativo = true;
    
    -- Verificar se tem acesso ao módulo
    IF NOT (v_modulos_acesso ? p_modulo) THEN
        RETURN FALSE;
    END IF;
    
    -- Se não especificou ação, retorna true (tem acesso ao módulo)
    IF p_acao IS NULL THEN
        RETURN TRUE;
    END IF;
    
    -- Verificar permissão específica
    RETURN COALESCE((v_permissoes #>> ('{' || p_modulo || ',' || p_acao || '}'))::BOOLEAN, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRIAR VIEW PARA USUÁRIOS COM PERFIS
CREATE OR REPLACE VIEW vw_usuarios_perfis AS
SELECT 
    u.id,
    u.email,
    u.nome_completo,
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

-- 7. CRIAR FUNÇÃO PARA OBTER MÓDULOS PERMITIDOS PARA UM USUÁRIO
CREATE OR REPLACE FUNCTION obter_modulos_usuario(p_user_id UUID) 
RETURNS JSONB AS $$
DECLARE
    v_modulos JSONB;
BEGIN
    SELECT cp.modulos_acesso
    INTO v_modulos
    FROM usuarios u
    JOIN configuracao_perfis cp ON cp.perfil = u.perfil_usuario AND cp.tenant_id = u.tenant_id
    WHERE u.id = p_user_id AND u.ativo = true AND cp.ativo = true;
    
    RETURN COALESCE(v_modulos, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. CRIAR FUNÇÃO PARA ATUALIZAR PERFIL DE USUÁRIO
CREATE OR REPLACE FUNCTION atualizar_perfil_usuario(
    p_user_id UUID,
    p_novo_perfil perfil_usuario_enum
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE usuarios 
    SET perfil_usuario = p_novo_perfil,
        atualizado_em = NOW()
    WHERE id = p_user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. TRIGGER PARA ATUALIZAR TIMESTAMP
CREATE OR REPLACE FUNCTION trigger_atualizar_timestamp_configuracao_perfis()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_configuracao_perfis_timestamp ON configuracao_perfis;
CREATE TRIGGER trigger_configuracao_perfis_timestamp
    BEFORE UPDATE ON configuracao_perfis
    FOR EACH ROW
    EXECUTE FUNCTION trigger_atualizar_timestamp_configuracao_perfis();

-- 10. RLS (Row Level Security) para configuracao_perfis
ALTER TABLE configuracao_perfis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "configuracao_perfis_tenant_isolation" ON configuracao_perfis;
CREATE POLICY "configuracao_perfis_tenant_isolation" ON configuracao_perfis
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- 11. COMENTÁRIOS EXPLICATIVOS
COMMENT ON TABLE configuracao_perfis IS 'Configurações de perfis de usuário com módulos de acesso e permissões específicas';
COMMENT ON COLUMN configuracao_perfis.modulos_acesso IS 'Array JSON com os módulos que o perfil pode acessar';
COMMENT ON COLUMN configuracao_perfis.permissoes IS 'Objeto JSON com permissões específicas por módulo e ação';

COMMENT ON FUNCTION verificar_permissao_usuario(UUID, VARCHAR, VARCHAR) IS 'Verifica se um usuário tem permissão para acessar um módulo/ação específica';
COMMENT ON FUNCTION obter_modulos_usuario(UUID) IS 'Retorna os módulos que um usuário pode acessar baseado em seu perfil';
COMMENT ON FUNCTION atualizar_perfil_usuario(UUID, perfil_usuario_enum) IS 'Atualiza o perfil de um usuário';

-- =====================================================
-- CONCLUSÃO
-- =====================================================
-- Sistema de perfis implementado com:
-- ✅ 4 Perfis: CPM, CCL, Órgão Administrativo, Assessoria Jurídica
-- ✅ Controle de módulos por perfil
-- ✅ Permissões granulares por ação
-- ✅ Funções de verificação de acesso
-- ✅ RLS para isolamento por tenant
-- ✅ Views e triggers para auditoria
-- ✅ Configuração automática por tenant