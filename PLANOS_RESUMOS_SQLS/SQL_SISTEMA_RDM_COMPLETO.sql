-- ============================================
-- SQL PARA SISTEMA RDM COMPLETO COM LOGINS
-- Sistema Comprar Bem - Expansão Fase 1
-- ============================================

-- 1. MODIFICAR TABELA usuarios EXISTENTE (adicionar tipo_usuario)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS tipo_usuario TEXT DEFAULT 'cpm';
COMMENT ON COLUMN usuarios.tipo_usuario IS 'Tipos: cpm, rdm, viewer';

-- 2. MODIFICAR TABELA usuarios_rdm (adicionar referência ao login)
ALTER TABLE usuarios_rdm ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE usuarios_rdm ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT true;
ALTER TABLE usuarios_rdm ADD COLUMN IF NOT EXISTS convite_enviado BOOLEAN DEFAULT false;
ALTER TABLE usuarios_rdm ADD COLUMN IF NOT EXISTS convite_aceito BOOLEAN DEFAULT false;
ALTER TABLE usuarios_rdm ADD COLUMN IF NOT EXISTS senha_temporaria TEXT;

-- 3. TABELA PARA RDMs EMITIDOS ONLINE
DROP TABLE IF EXISTS rdms_online CASCADE;
CREATE TABLE rdms_online (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES auth.users(id),
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id),
    material_nome TEXT NOT NULL,
    material_codigo TEXT NOT NULL,
    quantidade INTEGER NOT NULL,
    unidade_medida TEXT DEFAULT 'UN',
    justificativa TEXT NOT NULL,
    urgencia TEXT DEFAULT 'NORMAL' CHECK (urgencia IN ('BAIXA', 'NORMAL', 'ALTA', 'URGENTE')),
    status TEXT DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE', 'APROVADO', 'REJEITADO', 'EM_ANALISE')),
    observacoes_cpm TEXT,
    aprovado_por UUID REFERENCES auth.users(id),
    data_aprovacao TIMESTAMPTZ,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA PARA NOTIFICAÇÕES DO SISTEMA
DROP TABLE IF EXISTS notificacoes CASCADE;
CREATE TABLE notificacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES auth.users(id),
    usuario_destino UUID NOT NULL REFERENCES auth.users(id),
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
    tenant_id UUID NOT NULL REFERENCES auth.users(id),
    usuario_id UUID NOT NULL REFERENCES auth.users(id),
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
    FOR SELECT USING (tenant_id = auth.uid() OR usuario_rdm_id IN (
        SELECT id FROM usuarios_rdm WHERE user_id = auth.uid()
    ));

CREATE POLICY "rdms_online_insert_policy" ON rdms_online
    FOR INSERT WITH CHECK (usuario_rdm_id IN (
        SELECT id FROM usuarios_rdm WHERE user_id = auth.uid()
    ));

CREATE POLICY "rdms_online_update_policy" ON rdms_online
    FOR UPDATE USING (tenant_id = auth.uid())
    WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "rdms_online_delete_policy" ON rdms_online
    FOR DELETE USING (tenant_id = auth.uid());

-- RLS para notificacoes
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notificacoes_select_policy" ON notificacoes
    FOR SELECT USING (usuario_destino = auth.uid() OR tenant_id = auth.uid());

CREATE POLICY "notificacoes_insert_policy" ON notificacoes
    FOR INSERT WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "notificacoes_update_policy" ON notificacoes
    FOR UPDATE USING (usuario_destino = auth.uid())
    WITH CHECK (usuario_destino = auth.uid());

-- RLS para log_atividades
ALTER TABLE log_atividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "log_atividades_select_policy" ON log_atividades
    FOR SELECT USING (tenant_id = auth.uid());

CREATE POLICY "log_atividades_insert_policy" ON log_atividades
    FOR INSERT WITH CHECK (usuario_id = auth.uid());

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

-- Índices para rdms_online
CREATE INDEX idx_rdms_online_tenant_id ON rdms_online(tenant_id);
CREATE INDEX idx_rdms_online_usuario_rdm_id ON rdms_online(usuario_rdm_id);
CREATE INDEX idx_rdms_online_status ON rdms_online(status);
CREATE INDEX idx_rdms_online_criado_em ON rdms_online(criado_em);

-- Índices para notificacoes
CREATE INDEX idx_notificacoes_usuario_destino ON notificacoes(usuario_destino);
CREATE INDEX idx_notificacoes_lida ON notificacoes(lida);
CREATE INDEX idx_notificacoes_criado_em ON notificacoes(criado_em);

-- Índices para log_atividades
CREATE INDEX idx_log_atividades_tenant_id ON log_atividades(tenant_id);
CREATE INDEX idx_log_atividades_usuario_id ON log_atividades(usuario_id);
CREATE INDEX idx_log_atividades_criado_em ON log_atividades(criado_em);

-- Índices adicionais para usuarios_rdm
CREATE INDEX idx_usuarios_rdm_user_id ON usuarios_rdm(user_id);
CREATE INDEX idx_usuarios_rdm_ativo ON usuarios_rdm(ativo);

-- ============================================
-- TRIGGERS PARA TIMESTAMPS
-- ============================================

-- Trigger para rdms_online
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
    u.telefone,
    cpm.email as cpm_email
FROM rdms_online r
JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id
JOIN auth.users cpm ON r.tenant_id = cpm.id;

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
-- DADOS DE EXEMPLO (OPCIONAL)
-- ============================================

/*
-- Inserir RDM de exemplo
INSERT INTO rdms_online (tenant_id, usuario_rdm_id, material_nome, material_codigo, quantidade, justificativa, urgencia) 
VALUES (
    'SEU_TENANT_ID',
    (SELECT id FROM usuarios_rdm LIMIT 1),
    'Seringas Descartáveis 10ml',
    'MED001',
    1000,
    'Estoque baixo no setor de enfermagem. Previsão de acabar em 3 dias.',
    'ALTA'
);
*/

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se as tabelas foram criadas
SELECT 
    table_name, 
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('rdms_online', 'notificacoes', 'log_atividades');

-- Verificar políticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('rdms_online', 'notificacoes', 'log_atividades');

COMMENT ON TABLE rdms_online IS 'RDMs emitidos online pelos usuários - Sistema Comprar Bem';
COMMENT ON TABLE notificacoes IS 'Sistema de notificações em tempo real - Sistema Comprar Bem';
COMMENT ON TABLE log_atividades IS 'Log de todas as atividades do sistema - Sistema Comprar Bem';

-- ============================================
-- FIM DO SCRIPT
-- ============================================ 