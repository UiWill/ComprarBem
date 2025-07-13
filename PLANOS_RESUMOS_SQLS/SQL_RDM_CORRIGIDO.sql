-- ============================================
-- SQL SISTEMA RDM COMPLETO - VERSÃO CORRIGIDA
-- Sistema Comprar Bem - Expansão Fase 1
-- ============================================

-- 0. CRIAR FUNÇÃO DE TIMESTAMP SE NÃO EXISTIR
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. VERIFICAR E MODIFICAR TABELA usuarios (se existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'usuarios') THEN
        -- Adicionar coluna tipo_usuario se não existir
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios' AND column_name = 'tipo_usuario') THEN
            ALTER TABLE usuarios ADD COLUMN tipo_usuario TEXT DEFAULT 'cpm';
            COMMENT ON COLUMN usuarios.tipo_usuario IS 'Tipos: cpm, rdm, viewer';
        END IF;
    ELSE
        RAISE NOTICE 'ATENÇÃO: Tabela usuarios não encontrada. Criando tabela básica...';
        CREATE TABLE usuarios (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email TEXT UNIQUE NOT NULL,
            nome TEXT,
            tipo_usuario TEXT DEFAULT 'cpm',
            tenant_id UUID,
            criado_em TIMESTAMPTZ DEFAULT NOW(),
            atualizado_em TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
END
$$;

-- 2. VERIFICAR E MODIFICAR TABELA usuarios_rdm (se existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'usuarios_rdm') THEN
        -- Adicionar colunas se não existirem
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios_rdm' AND column_name = 'user_id') THEN
            ALTER TABLE usuarios_rdm ADD COLUMN user_id UUID;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios_rdm' AND column_name = 'ativo') THEN
            ALTER TABLE usuarios_rdm ADD COLUMN ativo BOOLEAN DEFAULT true;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios_rdm' AND column_name = 'convite_enviado') THEN
            ALTER TABLE usuarios_rdm ADD COLUMN convite_enviado BOOLEAN DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios_rdm' AND column_name = 'convite_aceito') THEN
            ALTER TABLE usuarios_rdm ADD COLUMN convite_aceito BOOLEAN DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios_rdm' AND column_name = 'senha_temporaria') THEN
            ALTER TABLE usuarios_rdm ADD COLUMN senha_temporaria TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'usuarios_rdm' AND column_name = 'data_convite') THEN
            ALTER TABLE usuarios_rdm ADD COLUMN data_convite TIMESTAMPTZ;
        END IF;
        
    ELSE
        RAISE NOTICE 'ATENÇÃO: Execute primeiro SQL_USUARIOS_RECLAMACOES.sql';
    END IF;
END
$$;

-- 3. TABELA PARA RDMs EMITIDOS ONLINE
DROP TABLE IF EXISTS rdms_online CASCADE;
CREATE TABLE rdms_online (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    usuario_rdm_id UUID NOT NULL,
    material_nome TEXT NOT NULL,
    material_codigo TEXT NOT NULL,
    quantidade INTEGER NOT NULL,
    unidade_medida TEXT DEFAULT 'UN',
    justificativa TEXT NOT NULL,
    urgencia TEXT DEFAULT 'NORMAL' CHECK (urgencia IN ('BAIXA', 'NORMAL', 'ALTA', 'URGENTE')),
    status TEXT DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE', 'APROVADO', 'REJEITADO', 'EM_ANALISE')),
    observacoes_cpm TEXT,
    aprovado_por UUID,
    data_aprovacao TIMESTAMPTZ,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA PARA NOTIFICAÇÕES
DROP TABLE IF EXISTS notificacoes CASCADE;
CREATE TABLE notificacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    usuario_destino UUID NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('RDM_PENDENTE', 'RDM_APROVADO', 'RDM_REJEITADO', 'RECLAMACAO_NOVA', 'SISTEMA')),
    titulo TEXT NOT NULL,
    mensagem TEXT NOT NULL,
    link_acao TEXT,
    lida BOOLEAN DEFAULT false,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABELA PARA LOG DE ATIVIDADES
DROP TABLE IF EXISTS log_atividades CASCADE;
CREATE TABLE log_atividades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    usuario_id UUID NOT NULL,
    acao TEXT NOT NULL,
    detalhes JSONB,
    ip_address INET,
    user_agent TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CONFIGURAR RLS (Row Level Security)
-- ============================================

-- RLS para rdms_online
ALTER TABLE rdms_online ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rdms_online_tenant_policy" ON rdms_online
    FOR ALL USING (
        tenant_id = (SELECT auth.uid())
        OR usuario_rdm_id IN (
            SELECT id FROM usuarios_rdm 
            WHERE user_id = (SELECT auth.uid())
        )
    );

-- RLS para notificacoes
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notificacoes_user_policy" ON notificacoes
    FOR ALL USING (
        usuario_destino = (SELECT auth.uid())
        OR tenant_id = (SELECT auth.uid())
    );

-- RLS para log_atividades
ALTER TABLE log_atividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "log_atividades_tenant_policy" ON log_atividades
    FOR ALL USING (tenant_id = (SELECT auth.uid()));

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_rdms_online_tenant_id ON rdms_online(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rdms_online_usuario_rdm_id ON rdms_online(usuario_rdm_id);
CREATE INDEX IF NOT EXISTS idx_rdms_online_status ON rdms_online(status);
CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario_destino ON notificacoes(usuario_destino);
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_user_id ON usuarios_rdm(user_id);

-- ============================================
-- TRIGGERS
-- ============================================

DROP TRIGGER IF EXISTS update_rdms_online_updated_at ON rdms_online;
CREATE TRIGGER update_rdms_online_updated_at 
    BEFORE UPDATE ON rdms_online 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

CREATE OR REPLACE FUNCTION gerar_senha_temporaria()
RETURNS TEXT AS $$
BEGIN
    RETURN 'CB' || LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0') || '!';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION criar_notificacao(
    p_tenant_id UUID,
    p_usuario_destino UUID,
    p_tipo TEXT,
    p_titulo TEXT,
    p_mensagem TEXT,
    p_link_acao TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    notificacao_id UUID;
BEGIN
    INSERT INTO notificacoes (tenant_id, usuario_destino, tipo, titulo, mensagem, link_acao)
    VALUES (p_tenant_id, p_usuario_destino, p_tipo, p_titulo, p_mensagem, p_link_acao)
    RETURNING id INTO notificacao_id;
    
    RETURN notificacao_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS PARA CONSULTAS
-- ============================================

CREATE OR REPLACE VIEW v_rdms_completos AS
SELECT 
    r.*,
    u.nome_usuario,
    u.unidade_setor,
    u.email,
    u.telefone
FROM rdms_online r
JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id;

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

SELECT 
    'TABELA CRIADA: ' || table_name as resultado
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('rdms_online', 'notificacoes', 'log_atividades');

-- ============================================
-- COMENTÁRIOS
-- ============================================

COMMENT ON TABLE rdms_online IS 'RDMs emitidos online pelos usuários';
COMMENT ON TABLE notificacoes IS 'Sistema de notificações em tempo real';
COMMENT ON TABLE log_atividades IS 'Log de atividades do sistema';

-- FIM DO SCRIPT 