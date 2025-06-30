-- ============================================
-- SQL PARA CRIAR TABELA DE FEEDBACKS DE MATERIAIS
-- Sistema Comprar Bem - Dashboard RDM
-- Versão específica para avaliações diretas de materiais
-- ============================================

-- CRIAR TABELA ESPECÍFICA PARA FEEDBACKS DE MATERIAIS DO DASHBOARD RDM
DROP TABLE IF EXISTS material_feedbacks CASCADE;
CREATE TABLE material_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES auth.users(id),
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id),
    produto_id UUID, -- Opcional, pode ser NULL
    material_nome TEXT NOT NULL,
    material_codigo TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comentario TEXT,
    data_feedback TIMESTAMPTZ DEFAULT NOW(),
    tipo TEXT DEFAULT 'FEEDBACK_MATERIAL',
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CONFIGURAR RLS (ROW LEVEL SECURITY)
-- ============================================

ALTER TABLE material_feedbacks ENABLE ROW LEVEL SECURITY;

-- Política SELECT: usuários podem ver apenas dados do seu tenant
CREATE POLICY "material_feedbacks_select_policy" ON material_feedbacks
    FOR SELECT USING (tenant_id = auth.uid());

-- Política INSERT: usuários podem inserir apenas com seu tenant_id
CREATE POLICY "material_feedbacks_insert_policy" ON material_feedbacks
    FOR INSERT WITH CHECK (tenant_id = auth.uid());

-- Política UPDATE: usuários podem atualizar apenas dados do seu tenant
CREATE POLICY "material_feedbacks_update_policy" ON material_feedbacks
    FOR UPDATE USING (tenant_id = auth.uid())
    WITH CHECK (tenant_id = auth.uid());

-- Política DELETE: usuários podem deletar apenas dados do seu tenant
CREATE POLICY "material_feedbacks_delete_policy" ON material_feedbacks
    FOR DELETE USING (tenant_id = auth.uid());

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX idx_material_feedbacks_tenant_id ON material_feedbacks(tenant_id);
CREATE INDEX idx_material_feedbacks_usuario_rdm_id ON material_feedbacks(usuario_rdm_id);
CREATE INDEX idx_material_feedbacks_produto_id ON material_feedbacks(produto_id);
CREATE INDEX idx_material_feedbacks_material_codigo ON material_feedbacks(material_codigo);
CREATE INDEX idx_material_feedbacks_rating ON material_feedbacks(rating);
CREATE INDEX idx_material_feedbacks_data_feedback ON material_feedbacks(data_feedback);
CREATE INDEX idx_material_feedbacks_criado_em ON material_feedbacks(criado_em);

-- ============================================
-- TRIGGER PARA ATUALIZAR atualizado_em
-- ============================================

CREATE TRIGGER update_material_feedbacks_updated_at 
    BEFORE UPDATE ON material_feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEW PARA ESTATÍSTICAS DE FEEDBACKS
-- ============================================

CREATE OR REPLACE VIEW v_material_feedbacks_stats AS
SELECT 
    tenant_id,
    COUNT(*) as total_feedbacks,
    AVG(rating) as rating_medio,
    COUNT(CASE WHEN rating = 5 THEN 1 END) as feedbacks_5_estrelas,
    COUNT(CASE WHEN rating = 4 THEN 1 END) as feedbacks_4_estrelas,
    COUNT(CASE WHEN rating = 3 THEN 1 END) as feedbacks_3_estrelas,
    COUNT(CASE WHEN rating = 2 THEN 1 END) as feedbacks_2_estrelas,
    COUNT(CASE WHEN rating = 1 THEN 1 END) as feedbacks_1_estrela,
    COUNT(CASE WHEN comentario IS NOT NULL AND LENGTH(comentario) > 0 THEN 1 END) as feedbacks_com_comentario,
    DATE_TRUNC('month', criado_em) as mes
FROM material_feedbacks
GROUP BY tenant_id, DATE_TRUNC('month', criado_em)
ORDER BY mes DESC;

-- ============================================
-- VIEW PARA RELATÓRIO DE MATERIAIS MAIS AVALIADOS
-- ============================================

CREATE OR REPLACE VIEW v_materiais_mais_avaliados AS
SELECT 
    material_nome,
    material_codigo,
    COUNT(*) as total_avaliacoes,
    AVG(rating) as rating_medio,
    COUNT(CASE WHEN rating >= 4 THEN 1 END) as avaliacoes_positivas,
    COUNT(CASE WHEN rating <= 2 THEN 1 END) as avaliacoes_negativas,
    MAX(criado_em) as ultima_avaliacao,
    tenant_id
FROM material_feedbacks
GROUP BY material_nome, material_codigo, tenant_id
HAVING COUNT(*) >= 1
ORDER BY total_avaliacoes DESC, rating_medio DESC;

-- ============================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- ============================================

/*
-- Inserir alguns feedbacks de exemplo
-- IMPORTANTE: Substitua 'SEU_TENANT_ID' pelo ID real do tenant e 'SEU_USUARIO_RDM_ID' pelo ID do usuário

INSERT INTO material_feedbacks (tenant_id, usuario_rdm_id, material_nome, material_codigo, rating, comentario) VALUES
('SEU_TENANT_ID', 'SEU_USUARIO_RDM_ID', 'Cadeira Ortopédica', 'MOBIL001', 5, 'Excelente qualidade, muito confortável para longas jornadas de trabalho.'),
('SEU_TENANT_ID', 'SEU_USUARIO_RDM_ID', 'Mesa de Escritório', 'MOBIL002', 4, 'Boa mesa, mas poderia ter mais gavetas.'),
('SEU_TENANT_ID', 'SEU_USUARIO_RDM_ID', 'Computador Desktop', 'INFO001', 3, 'Funciona bem, mas é um pouco lento para algumas tarefas.');
*/

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se a tabela foi criada
SELECT 
    table_name, 
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'material_feedbacks';

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
WHERE tablename = 'material_feedbacks';

COMMENT ON TABLE material_feedbacks IS 'Feedbacks/avaliações diretas de materiais pelos usuários do Dashboard RDM - Sistema Comprar Bem';

-- ============================================
-- INSTRUÇÕES DE USO:
-- ============================================
-- 1. Execute este SQL no Supabase
-- 2. A tabela estará pronta para receber feedbacks do Dashboard RDM
-- 3. Use as views para estatísticas e relatórios
-- 4. Integre com o frontend Vue.js para salvamento automático
-- ============================================

-- FIM DO SCRIPT 