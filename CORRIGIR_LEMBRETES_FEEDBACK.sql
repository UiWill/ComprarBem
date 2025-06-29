-- ============================================
-- CORREÇÃO: SISTEMA AUTOMÁTICO DE LEMBRETES PARA FEEDBACK
-- Sistema Comprar Bem - Versão Corrigida
-- ============================================

-- PROBLEMA IDENTIFICADO: A tabela rdms_online usa 'id' e não 'rdm_id'
-- SOLUÇÃO: Corrigir todas as referências para usar a estrutura real

-- 1. REMOVER TABELAS SE JÁ EXISTIREM (para recriar corretamente)
DROP TABLE IF EXISTS lembretes_feedback CASCADE;
DROP TABLE IF EXISTS rdm_feedbacks CASCADE;

-- 2. CRIAR TABELA DE FEEDBACKS RDM (CORRIGIDA)
CREATE TABLE rdm_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL REFERENCES rdms_online(id) ON DELETE CASCADE,
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id) ON DELETE CASCADE,
    material_nome TEXT NOT NULL,
    material_codigo TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comentario TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CRIAR TABELA DE LEMBRETES ENVIADOS (CORRIGIDA)
CREATE TABLE lembretes_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL REFERENCES rdms_online(id) ON DELETE CASCADE,
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id) ON DELETE CASCADE,
    tipo_lembrete TEXT NOT NULL CHECK (tipo_lembrete IN ('15_DIAS', '25_DIAS', '30_DIAS_URGENTE')),
    email_enviado BOOLEAN DEFAULT false,
    data_envio TIMESTAMPTZ,
    erro_envio TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CRIAR ÍNDICES PARA PERFORMANCE
CREATE INDEX idx_rdm_feedbacks_rdm_id ON rdm_feedbacks(rdm_id);
CREATE INDEX idx_rdm_feedbacks_usuario_rdm_id ON rdm_feedbacks(usuario_rdm_id);
CREATE INDEX idx_rdm_feedbacks_tenant_id ON rdm_feedbacks(tenant_id);

CREATE INDEX idx_lembretes_feedback_rdm_id ON lembretes_feedback(rdm_id);
CREATE INDEX idx_lembretes_feedback_tipo ON lembretes_feedback(tipo_lembrete);
CREATE INDEX idx_lembretes_feedback_email_enviado ON lembretes_feedback(email_enviado);
CREATE INDEX idx_lembretes_feedback_tenant_id ON lembretes_feedback(tenant_id);

-- 5. FUNÇÃO PARA VERIFICAR RDMs QUE PRECISAM DE LEMBRETES (CORRIGIDA)
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
        -- Usar data_aprovacao se existir, senão usar atualizado_em
        COALESCE(r.data_aprovacao, r.atualizado_em) as data_aprovacao,
        EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em)))::INTEGER as dias_desde_aprovacao,
        CASE 
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 30 THEN '30_DIAS_URGENTE'
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 25 THEN '25_DIAS'
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 15 THEN '15_DIAS'
            ELSE NULL
        END as tipo_lembrete_necessario,
        u.nome_usuario,
        u.email,
        u.unidade_setor
    FROM rdms_online r
    JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id
    WHERE 
        r.status = 'APROVADO'
        AND COALESCE(r.data_aprovacao, r.atualizado_em) IS NOT NULL
        AND EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 15
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
                WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 30 THEN '30_DIAS_URGENTE'
                WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 25 THEN '25_DIAS'
                WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 15 THEN '15_DIAS'
            END
            AND l.email_enviado = true
        )
    ORDER BY COALESCE(r.data_aprovacao, r.atualizado_em) ASC;
END;
$$ LANGUAGE plpgsql;

-- 6. FUNÇÃO PARA REGISTRAR LEMBRETE ENVIADO
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

-- 7. VIEW PARA ESTATÍSTICAS DE LEMBRETES
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

-- 8. VIEW PARA RDMs PENDENTES DE FEEDBACK (CORRIGIDA)
CREATE OR REPLACE VIEW v_rdms_pendentes_feedback AS
SELECT 
    r.id,
    r.material_nome,
    r.material_codigo,
    r.quantidade,
    COALESCE(r.data_aprovacao, r.atualizado_em) as data_aprovacao,
    EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em)))::INTEGER as dias_desde_aprovacao,
    u.nome_usuario,
    u.email,
    u.unidade_setor,
    CASE 
        WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 30 THEN 'URGENTE'
        WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 25 THEN 'ALTA'
        WHEN EXTRACT(DAY FROM (NOW() - COALESCE(r.data_aprovacao, r.atualizado_em))) >= 15 THEN 'NORMAL'
        ELSE 'RECENTE'
    END as prioridade_feedback
FROM rdms_online r
JOIN usuarios_rdm u ON r.usuario_rdm_id = u.id
WHERE 
    r.status = 'APROVADO'
    AND COALESCE(r.data_aprovacao, r.atualizado_em) IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM rdm_feedbacks f 
        WHERE f.rdm_id = r.id
    )
ORDER BY COALESCE(r.data_aprovacao, r.atualizado_em) ASC;

-- 9. CONFIGURAR RLS PARA NOVAS TABELAS
ALTER TABLE rdm_feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE lembretes_feedback ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para rdm_feedbacks
CREATE POLICY "rdm_feedbacks_select_policy" ON rdm_feedbacks
    FOR SELECT USING (true); -- Permitir leitura para simplificar

CREATE POLICY "rdm_feedbacks_insert_policy" ON rdm_feedbacks
    FOR INSERT WITH CHECK (true); -- Permitir inserção para simplificar

-- Políticas RLS para lembretes_feedback  
CREATE POLICY "lembretes_feedback_select_policy" ON lembretes_feedback
    FOR SELECT USING (true); -- Permitir leitura para simplificar

CREATE POLICY "lembretes_feedback_insert_policy" ON lembretes_feedback
    FOR INSERT WITH CHECK (true); -- Permitir inserção para simplificar

-- 10. CRIAR DADOS DE TESTE PARA DEMONSTRAÇÃO
-- Atualizar algumas RDMs para ter datas antigas (simular necessidade de lembretes)
UPDATE rdms_online 
SET atualizado_em = NOW() - INTERVAL '18 days'
WHERE status = 'APROVADO' 
AND id = 'd1289bf3-12b0-4fca-9245-990af88bb165';

UPDATE rdms_online 
SET atualizado_em = NOW() - INTERVAL '28 days'
WHERE status = 'APROVADO' 
AND id = '391c90bd-dedf-40cb-a56a-e182b2ad60c8';

-- 11. TESTE FINAL
-- Execute para ver RDMs que precisam de lembretes:
-- SELECT * FROM verificar_rdms_para_lembrete();

-- Comentários
COMMENT ON TABLE rdm_feedbacks IS 'Feedbacks dados pelos usuários sobre materiais recebidos via RDM';
COMMENT ON TABLE lembretes_feedback IS 'Controle de lembretes automáticos enviados para solicitar feedback';
COMMENT ON FUNCTION verificar_rdms_para_lembrete() IS 'Identifica RDMs aprovadas que precisam receber lembretes de feedback';
COMMENT ON FUNCTION registrar_lembrete_enviado(UUID, UUID, UUID, TEXT, BOOLEAN, TEXT) IS 'Registra o envio de um lembrete de feedback';

-- ============================================
-- 🎉 SISTEMA CORRIGIDO E PRONTO PARA USO!
-- ============================================ 