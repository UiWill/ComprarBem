-- ============================================
-- SQL PARA SISTEMA RDM COMPLETO COM LOGINS
-- Sistema Comprar Bem - Expansão Fase 1 - VERSÃO CORRIGIDA
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
            -- Não adicionar REFERENCES aqui por segurança
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
        RAISE NOTICE 'ATENÇÃO: Tabela usuarios_rdm não encontrada. Execute primeiro SQL_USUARIOS_RECLAMACOES.sql';
        -- Não executar o resto se não existe a tabela base
        RETURN;
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

-- 4. TABELA PARA NOTIFICAÇÕES DO SISTEMA
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
-- CONFIGURAR RLS PARA NOVAS TABELAS
-- ============================================

-- RLS para rdms_online
ALTER TABLE rdms_online ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rdms_online_select_policy" ON rdms_online
    FOR SELECT USING (
        tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
        OR usuario_rdm_id IN (
            SELECT id FROM usuarios_rdm 
            WHERE user_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
        )
    );

CREATE POLICY "rdms_online_insert_policy" ON rdms_online
    FOR INSERT WITH CHECK (
        usuario_rdm_id IN (
            SELECT id FROM usuarios_rdm 
            WHERE user_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
        )
    );

CREATE POLICY "rdms_online_update_policy" ON rdms_online
    FOR UPDATE USING (
        tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

CREATE POLICY "rdms_online_delete_policy" ON rdms_online
    FOR DELETE USING (
        tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

-- RLS para notificacoes
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notificacoes_select_policy" ON notificacoes
    FOR SELECT USING (
        usuario_destino::text = current_setting('request.jwt.claims', true)::json->>'sub'
        OR tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

CREATE POLICY "notificacoes_insert_policy" ON notificacoes
    FOR INSERT WITH CHECK (
        tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

CREATE POLICY "notificacoes_update_policy" ON notificacoes
    FOR UPDATE USING (
        usuario_destino::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

-- RLS para log_atividades
ALTER TABLE log_atividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "log_atividades_select_policy" ON log_atividades
    FOR SELECT USING (
        tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

CREATE POLICY "log_atividades_insert_policy" ON log_atividades
    FOR INSERT WITH CHECK (
        usuario_id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    );

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

-- Índices para rdms_online
CREATE INDEX IF NOT EXISTS idx_rdms_online_tenant_id ON rdms_online(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rdms_online_usuario_rdm_id ON rdms_online(usuario_rdm_id);
CREATE INDEX IF NOT EXISTS idx_rdms_online_status ON rdms_online(status);
CREATE INDEX IF NOT EXISTS idx_rdms_online_criado_em ON rdms_online(criado_em);

-- Índices para notificacoes
CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario_destino ON notificacoes(usuario_destino);
CREATE INDEX IF NOT EXISTS idx_notificacoes_lida ON notificacoes(lida);
CREATE INDEX IF NOT EXISTS idx_notificacoes_criado_em ON notificacoes(criado_em);

-- Índices para log_atividades
CREATE INDEX IF NOT EXISTS idx_log_atividades_tenant_id ON log_atividades(tenant_id);
CREATE INDEX IF NOT EXISTS idx_log_atividades_usuario_id ON log_atividades(usuario_id);
CREATE INDEX IF NOT EXISTS idx_log_atividades_criado_em ON log_atividades(criado_em);

-- Índices adicionais para usuarios_rdm
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_user_id ON usuarios_rdm(user_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_ativo ON usuarios_rdm(ativo);

-- ============================================
-- TRIGGERS PARA TIMESTAMPS
-- ============================================

-- Trigger para rdms_online
DROP TRIGGER IF EXISTS update_rdms_online_updated_at ON rdms_online;
CREATE TRIGGER update_rdms_online_updated_at 
    BEFORE UPDATE ON rdms_online 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

-- Função para gerar senha temporária
CREATE OR REPLACE FUNCTION gerar_senha_temporaria()
RETURNS TEXT AS $$
BEGIN
    RETURN 'CB' || LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0') || '!';
END;
$$ LANGUAGE plpgsql;

-- Função para criar notificação
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

-- Função para registrar atividade
CREATE OR REPLACE FUNCTION registrar_atividade(
    p_tenant_id UUID,
    p_usuario_id UUID,
    p_acao TEXT,
    p_detalhes JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO log_atividades (tenant_id, usuario_id, acao, detalhes)
    VALUES (p_tenant_id, p_usuario_id, p_acao, p_detalhes)
    RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER PARA NOTIFICAÇÕES AUTOMÁTICAS
-- ============================================

-- Trigger para notificar quando RDM é criado
CREATE OR REPLACE FUNCTION notificar_rdm_criado()
RETURNS TRIGGER AS $$
BEGIN
    -- Notificar CPM sobre novo RDM
    PERFORM criar_notificacao(
        NEW.tenant_id,
        NEW.tenant_id, -- CPM é o tenant owner
        'RDM_PENDENTE',
        'Novo RDM Pendente',
        'RDM de ' || NEW.material_nome || ' aguarda aprovação',
        '/dashboard/cpm?tab=rdms&rdm=' || NEW.id::TEXT
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notificar_rdm_criado ON rdms_online;
CREATE TRIGGER trigger_notificar_rdm_criado
    AFTER INSERT ON rdms_online
    FOR EACH ROW
    EXECUTE FUNCTION notificar_rdm_criado();

-- Trigger para notificar quando RDM é aprovado/rejeitado
CREATE OR REPLACE FUNCTION notificar_rdm_status_alterado()
RETURNS TRIGGER AS $$
DECLARE
    usuario_rdm_user_id UUID;
    titulo_notif TEXT;
    tipo_notif TEXT;
BEGIN
    -- Buscar user_id do usuário RDM
    SELECT user_id INTO usuario_rdm_user_id 
    FROM usuarios_rdm 
    WHERE id = NEW.usuario_rdm_id;
    
    -- Só notificar se status mudou e usuário tem login
    IF OLD.status != NEW.status AND usuario_rdm_user_id IS NOT NULL THEN
        CASE NEW.status
            WHEN 'APROVADO' THEN
                titulo_notif := 'RDM Aprovado';
                tipo_notif := 'RDM_APROVADO';
            WHEN 'REJEITADO' THEN
                titulo_notif := 'RDM Rejeitado';
                tipo_notif := 'RDM_REJEITADO';
            ELSE
                RETURN NEW;
        END CASE;
        
        PERFORM criar_notificacao(
            NEW.tenant_id,
            usuario_rdm_user_id,
            tipo_notif,
            titulo_notif,
            'Seu RDM de ' || NEW.material_nome || ' foi ' || LOWER(NEW.status),
            '/dashboard/rdm?rdm=' || NEW.id::TEXT
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notificar_rdm_status_alterado ON rdms_online;
CREATE TRIGGER trigger_notificar_rdm_status_alterado
    AFTER UPDATE ON rdms_online
    FOR EACH ROW
    EXECUTE FUNCTION notificar_rdm_status_alterado();

-- ============================================
-- VIEWS PARA RELATÓRIOS
-- ============================================

-- View para RDMs com dados do usuário
CREATE OR REPLACE VIEW v_rdms_completos AS
SELECT 
    r.*,
    u.nome_usuario,
    u.unidade_setor,
    u.email,
    u.telefone
FROM rdms_online r
JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id;

-- View para estatísticas de RDMs por usuário
CREATE OR REPLACE VIEW v_estatisticas_rdm_usuario AS
SELECT 
    u.id as usuario_rdm_id,
    u.nome_usuario,
    u.unidade_setor,
    COUNT(r.id) as total_rdms,
    COUNT(CASE WHEN r.status = 'PENDENTE' THEN 1 END) as rdms_pendentes,
    COUNT(CASE WHEN r.status = 'APROVADO' THEN 1 END) as rdms_aprovados,
    COUNT(CASE WHEN r.status = 'REJEITADO' THEN 1 END) as rdms_rejeitados,
    MAX(r.criado_em) as ultimo_rdm
FROM usuarios_rdm u
LEFT JOIN rdms_online r ON u.id = r.usuario_rdm_id
GROUP BY u.id, u.nome_usuario, u.unidade_setor;

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se as tabelas foram criadas
SELECT 
    'TABELA CRIADA: ' || table_name as resultado
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('rdms_online', 'notificacoes', 'log_atividades')
UNION ALL
SELECT 'TODAS AS TABELAS FORAM CRIADAS COM SUCESSO!' as resultado;

-- Comentários nas tabelas
COMMENT ON TABLE rdms_online IS 'RDMs emitidos online pelos usuários - Sistema Comprar Bem';
COMMENT ON TABLE notificacoes IS 'Sistema de notificações em tempo real - Sistema Comprar Bem';
COMMENT ON TABLE log_atividades IS 'Log de todas as atividades do sistema - Sistema Comprar Bem';

-- ============================================
-- FIM DO SCRIPT CORRIGIDO
-- ============================================ 