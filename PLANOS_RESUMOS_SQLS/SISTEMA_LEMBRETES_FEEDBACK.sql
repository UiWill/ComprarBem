-- ============================================
-- SISTEMA AUTOMÁTICO DE LEMBRETES PARA FEEDBACK
-- Sistema Comprar Bem - Lembretes por Email
-- ============================================

-- 1. CRIAR TABELA DE FEEDBACKS RDM (se não existir)
CREATE TABLE IF NOT EXISTS rdm_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL REFERENCES rdms_online(id),
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id),
    material_nome TEXT NOT NULL,
    material_codigo TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comentario TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 2. CRIAR TABELA DE LEMBRETES ENVIADOS
CREATE TABLE IF NOT EXISTS lembretes_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL REFERENCES rdms_online(id),
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id),
    tipo_lembrete TEXT NOT NULL CHECK (tipo_lembrete IN ('15_DIAS', '25_DIAS', '30_DIAS_URGENTE')),
    email_enviado BOOLEAN DEFAULT false,
    data_envio TIMESTAMPTZ,
    erro_envio TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_rdm_feedbacks_rdm_id ON rdm_feedbacks(rdm_id);
CREATE INDEX IF NOT EXISTS idx_rdm_feedbacks_usuario_rdm_id ON rdm_feedbacks(usuario_rdm_id);
CREATE INDEX IF NOT EXISTS idx_lembretes_feedback_rdm_id ON lembretes_feedback(rdm_id);
CREATE INDEX IF NOT EXISTS idx_lembretes_feedback_tipo ON lembretes_feedback(tipo_lembrete);
CREATE INDEX IF NOT EXISTS idx_lembretes_feedback_email_enviado ON lembretes_feedback(email_enviado);

-- 4. FUNÇÃO PARA VERIFICAR RDMs QUE PRECISAM DE LEMBRETES
CREATE OR REPLACE FUNCTION verificar_rdms_para_lembrete()
RETURNS TABLE(
    rdm_id UUID,
    tenant_id UUID,
    usuario_rdm_id UUID,
    material_nome TEXT,
    material_codigo TEXT,
    data_aprovacao TIMESTAMPTZ,
    dias_desde_aprovacao INTEGER,
    tipo_lembrete_necessario TEXT,
    usuario_nome TEXT,
    usuario_email TEXT,
    unidade_setor TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as rdm_id,
        r.tenant_id,
        r.usuario_rdm_id,
        r.material_nome,
        r.material_codigo,
        r.data_aprovacao,
        EXTRACT(DAY FROM (NOW() - r.data_aprovacao))::INTEGER as dias_desde_aprovacao,
        CASE 
            WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 30 THEN '30_DIAS_URGENTE'
            WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 25 THEN '25_DIAS'
            WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 15 THEN '15_DIAS'
            ELSE NULL
        END as tipo_lembrete_necessario,
        u.nome_usuario,
        u.email,
        u.unidade_setor
    FROM rdms_online r
    JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id
    WHERE 
        r.status = 'APROVADO'
        AND r.data_aprovacao IS NOT NULL
        AND EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 15
        -- Não tem feedback ainda
        AND NOT EXISTS (
            SELECT 1 FROM rdm_feedbacks f 
            WHERE f.rdm_id = r.id
        )
        -- Não enviou este tipo de lembrete ainda
        AND NOT EXISTS (
            SELECT 1 FROM lembretes_feedback l 
            WHERE l.rdm_id = r.id 
            AND l.tipo_lembrete = CASE 
                WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 30 THEN '30_DIAS_URGENTE'
                WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 25 THEN '25_DIAS'
                WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 15 THEN '15_DIAS'
            END
            AND l.email_enviado = true
        )
    ORDER BY r.data_aprovacao ASC;
END;
$$ LANGUAGE plpgsql;

-- 5. FUNÇÃO PARA REGISTRAR LEMBRETE ENVIADO
CREATE OR REPLACE FUNCTION registrar_lembrete_enviado(
    p_rdm_id UUID,
    p_tenant_id UUID,
    p_usuario_rdm_id UUID,
    p_tipo_lembrete TEXT,
    p_sucesso BOOLEAN,
    p_erro TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO lembretes_feedback (
        tenant_id,
        rdm_id,
        usuario_rdm_id,
        tipo_lembrete,
        email_enviado,
        data_envio,
        erro_envio
    ) VALUES (
        p_tenant_id,
        p_rdm_id,
        p_usuario_rdm_id,
        p_tipo_lembrete,
        p_sucesso,
        CASE WHEN p_sucesso THEN NOW() ELSE NULL END,
        p_erro
    );
END;
$$ LANGUAGE plpgsql;

-- 6. VIEW PARA ESTATÍSTICAS DE LEMBRETES
CREATE OR REPLACE VIEW v_estatisticas_lembretes AS
SELECT 
    COUNT(*) as total_lembretes_enviados,
    COUNT(CASE WHEN tipo_lembrete = '15_DIAS' THEN 1 END) as lembretes_15_dias,
    COUNT(CASE WHEN tipo_lembrete = '25_DIAS' THEN 1 END) as lembretes_25_dias,
    COUNT(CASE WHEN tipo_lembrete = '30_DIAS_URGENTE' THEN 1 END) as lembretes_30_dias_urgente,
    COUNT(CASE WHEN email_enviado = false THEN 1 END) as lembretes_com_erro,
    DATE_TRUNC('day', data_envio) as data
FROM lembretes_feedback
WHERE data_envio IS NOT NULL
GROUP BY DATE_TRUNC('day', data_envio)
ORDER BY data DESC;

-- 7. VIEW PARA RDMs PENDENTES DE FEEDBACK
CREATE OR REPLACE VIEW v_rdms_pendentes_feedback AS
SELECT 
    r.id,
    r.material_nome,
    r.material_codigo,
    r.quantidade,
    r.data_aprovacao,
    EXTRACT(DAY FROM (NOW() - r.data_aprovacao))::INTEGER as dias_desde_aprovacao,
    u.nome_usuario,
    u.email,
    u.unidade_setor,
    CASE 
        WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 30 THEN 'URGENTE'
        WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 25 THEN 'ALTA'
        WHEN EXTRACT(DAY FROM (NOW() - r.data_aprovacao)) >= 15 THEN 'NORMAL'
        ELSE 'RECENTE'
    END as prioridade_feedback
FROM rdms_online r
JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id
WHERE 
    r.status = 'APROVADO'
    AND r.data_aprovacao IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM rdm_feedbacks f 
        WHERE f.rdm_id = r.id
    )
ORDER BY r.data_aprovacao ASC;

-- 8. CONFIGURAR RLS PARA NOVAS TABELAS
ALTER TABLE rdm_feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE lembretes_feedback ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para rdm_feedbacks
CREATE POLICY "rdm_feedbacks_select_policy" ON rdm_feedbacks
    FOR SELECT USING (tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "rdm_feedbacks_insert_policy" ON rdm_feedbacks
    FOR INSERT WITH CHECK (tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Políticas RLS para lembretes_feedback
CREATE POLICY "lembretes_feedback_select_policy" ON lembretes_feedback
    FOR SELECT USING (tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "lembretes_feedback_insert_policy" ON lembretes_feedback
    FOR INSERT WITH CHECK (tenant_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- 9. TESTE DA FUNÇÃO
-- Para testar, execute:
-- SELECT * FROM verificar_rdms_para_lembrete();

-- 10. COMENTÁRIOS
COMMENT ON TABLE rdm_feedbacks IS 'Feedbacks dados pelos usuários sobre materiais recebidos';
COMMENT ON TABLE lembretes_feedback IS 'Controle de lembretes automáticos enviados para feedback';
COMMENT ON FUNCTION verificar_rdms_para_lembrete() IS 'Verifica RDMs que precisam receber lembretes de feedback';
COMMENT ON FUNCTION registrar_lembrete_enviado(UUID, UUID, UUID, TEXT, BOOLEAN, TEXT) IS 'Registra quando um lembrete foi enviado';

-- ============================================
-- INSTRUÇÕES DE USO:
-- ============================================
-- 1. Execute este SQL no Supabase
-- 2. Use a função verificar_rdms_para_lembrete() para ver quem precisa de lembrete
-- 3. Integre com o EmailJS no frontend para envio automático
-- 4. Use registrar_lembrete_enviado() após enviar cada email
-- ============================================

-- Exemplo de uso:
/*
-- Ver RDMs que precisam de lembrete:
SELECT * FROM verificar_rdms_para_lembrete();

-- Registrar que um lembrete foi enviado:
SELECT registrar_lembrete_enviado(
    'uuid-da-rdm', 
    'uuid-do-tenant', 
    'uuid-do-usuario', 
    '15_DIAS', 
    true, 
    NULL
);

-- Ver estatísticas:
SELECT * FROM v_estatisticas_lembretes;
SELECT * FROM v_rdms_pendentes_feedback;
*/ 