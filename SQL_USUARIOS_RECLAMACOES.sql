-- ============================================
-- SQL PARA CRIAR TABELAS DE USUÁRIOS E RECLAMAÇÕES
-- Sistema Comprar Bem - Novas Funcionalidades
-- ============================================

-- 1. TABELA USUARIOS_RDM
-- Para cadastro de usuários autorizados a emitir RDMs
DROP TABLE IF EXISTS usuarios_rdm CASCADE;
CREATE TABLE usuarios_rdm (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES auth.users(id),
    nome_usuario TEXT NOT NULL,
    unidade_setor TEXT NOT NULL,
    nome_coordenador TEXT NOT NULL,
    telefone TEXT NOT NULL,
    email TEXT NOT NULL,
    materiais JSONB DEFAULT '[]'::jsonb,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABELA RECLAMACOES_USUARIOS  
-- Para gestão de reclamações e sugestões sobre materiais
DROP TABLE IF EXISTS reclamacoes_usuarios CASCADE;
CREATE TABLE reclamacoes_usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES auth.users(id),
    nome_reclamante TEXT NOT NULL,
    telefone TEXT NOT NULL,
    email TEXT NOT NULL,
    unidade_setor TEXT NOT NULL,
    nome_material TEXT NOT NULL,
    codigo_material TEXT NOT NULL,
    marca_modelo TEXT NOT NULL,
    registro_reclamacao TEXT NOT NULL,
    sugestoes TEXT,
    status TEXT DEFAULT 'ABERTA' CHECK (status IN ('ABERTA', 'EM_ANALISE', 'RESOLVIDA', 'REJEITADA')),
    providencias_cpm TEXT,
    data_reclamacao DATE DEFAULT CURRENT_DATE,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    data_atualizacao TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CONFIGURAR RLS (ROW LEVEL SECURITY)
-- ============================================

-- Habilitar RLS nas tabelas
ALTER TABLE usuarios_rdm ENABLE ROW LEVEL SECURITY;
ALTER TABLE reclamacoes_usuarios ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS RLS PARA USUARIOS_RDM
-- ============================================

-- Política SELECT: usuários podem ver apenas dados do seu tenant
CREATE POLICY "usuarios_rdm_select_policy" ON usuarios_rdm
    FOR SELECT USING (tenant_id = auth.uid());

-- Política INSERT: usuários podem inserir apenas com seu tenant_id
CREATE POLICY "usuarios_rdm_insert_policy" ON usuarios_rdm
    FOR INSERT WITH CHECK (tenant_id = auth.uid());

-- Política UPDATE: usuários podem atualizar apenas dados do seu tenant
CREATE POLICY "usuarios_rdm_update_policy" ON usuarios_rdm
    FOR UPDATE USING (tenant_id = auth.uid())
    WITH CHECK (tenant_id = auth.uid());

-- Política DELETE: usuários podem deletar apenas dados do seu tenant
CREATE POLICY "usuarios_rdm_delete_policy" ON usuarios_rdm
    FOR DELETE USING (tenant_id = auth.uid());

-- ============================================
-- POLÍTICAS RLS PARA RECLAMACOES_USUARIOS
-- ============================================

-- Política SELECT: usuários podem ver apenas dados do seu tenant
CREATE POLICY "reclamacoes_usuarios_select_policy" ON reclamacoes_usuarios
    FOR SELECT USING (tenant_id = auth.uid());

-- Política INSERT: usuários podem inserir apenas com seu tenant_id
CREATE POLICY "reclamacoes_usuarios_insert_policy" ON reclamacoes_usuarios
    FOR INSERT WITH CHECK (tenant_id = auth.uid());

-- Política UPDATE: usuários podem atualizar apenas dados do seu tenant
CREATE POLICY "reclamacoes_usuarios_update_policy" ON reclamacoes_usuarios
    FOR UPDATE USING (tenant_id = auth.uid())
    WITH CHECK (tenant_id = auth.uid());

-- Política DELETE: usuários podem deletar apenas dados do seu tenant
CREATE POLICY "reclamacoes_usuarios_delete_policy" ON reclamacoes_usuarios
    FOR DELETE USING (tenant_id = auth.uid());

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

-- Índices para usuarios_rdm
CREATE INDEX idx_usuarios_rdm_tenant_id ON usuarios_rdm(tenant_id);
CREATE INDEX idx_usuarios_rdm_nome_usuario ON usuarios_rdm(nome_usuario);
CREATE INDEX idx_usuarios_rdm_unidade_setor ON usuarios_rdm(unidade_setor);
CREATE INDEX idx_usuarios_rdm_email ON usuarios_rdm(email);

-- Índices para reclamacoes_usuarios
CREATE INDEX idx_reclamacoes_usuarios_tenant_id ON reclamacoes_usuarios(tenant_id);
CREATE INDEX idx_reclamacoes_usuarios_status ON reclamacoes_usuarios(status);
CREATE INDEX idx_reclamacoes_usuarios_data_reclamacao ON reclamacoes_usuarios(data_reclamacao);
CREATE INDEX idx_reclamacoes_usuarios_nome_reclamante ON reclamacoes_usuarios(nome_reclamante);

-- ============================================
-- TRIGGERS PARA ATUALIZAR data_atualizacao
-- ============================================

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para usuarios_rdm
CREATE TRIGGER update_usuarios_rdm_updated_at 
    BEFORE UPDATE ON usuarios_rdm 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para reclamacoes_usuarios (usando data_atualizacao)
CREATE OR REPLACE FUNCTION update_data_atualizacao_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.data_atualizacao = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_reclamacoes_usuarios_data_atualizacao 
    BEFORE UPDATE ON reclamacoes_usuarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_data_atualizacao_column();

-- ============================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- ============================================

-- Inserir alguns usuários de exemplo
-- IMPORTANTE: Substitua 'SEU_TENANT_ID' pelo ID real do tenant

/*
INSERT INTO usuarios_rdm (tenant_id, nome_usuario, unidade_setor, nome_coordenador, telefone, email, materiais) VALUES
('SEU_TENANT_ID', 'Departamento de Compras', 'Secretaria da Administração', 'João Silva Santos', '(11) 99999-1111', 'joao.silva@prefeitura.gov.br', '[
    {"nome": "Papel A4", "codigo": "MAT001", "periodicidade_rdm": "mensal"},
    {"nome": "Canetas Esferográficas", "codigo": "MAT002", "periodicidade_rdm": "bimestral"}
]'::jsonb),
('SEU_TENANT_ID', 'Setor de Enfermagem', 'Secretaria da Saúde', 'Maria Fernanda Costa', '(11) 99999-2222', 'maria.fernanda@saude.gov.br', '[
    {"nome": "Seringas Descartáveis", "codigo": "MED001", "periodicidade_rdm": "mensal"},
    {"nome": "Luvas Cirúrgicas", "codigo": "MED002", "periodicidade_rdm": "mensal"},
    {"nome": "Álcool 70%", "codigo": "MED003", "periodicidade_rdm": "quinzenal"}
]'::jsonb);

-- Inserir algumas reclamações de exemplo
INSERT INTO reclamacoes_usuarios (tenant_id, nome_reclamante, telefone, email, unidade_setor, nome_material, codigo_material, marca_modelo, registro_reclamacao, sugestoes, status) VALUES
('SEU_TENANT_ID', 'Ana Paula Rodrigues', '(11) 99999-3333', 'ana.paula@enfermagem.gov.br', 'Departamento de Enfermagem', 'Luvas Cirúrgicas', 'MED002', 'MedSupply - Modelo Premium', 'As luvas estão rasgando com facilidade durante procedimentos simples. Já tivemos 3 casos esta semana onde as luvas se romperam durante o atendimento, causando risco de contaminação.', 'Sugiro avaliar fornecedores alternativos com produtos de maior resistência.', 'ABERTA'),
('SEU_TENANT_ID', 'Carlos Eduardo Lima', '(11) 99999-4444', 'carlos.lima@manutencao.gov.br', 'Setor de Manutenção', 'Parafusos Inox', 'MANT015', 'FixTech - M6x20mm', 'Os parafusos estão apresentando oxidação mesmo sendo vendidos como inoxidáveis. Após 2 meses de uso em ambiente externo, já mostram sinais de ferrugem.', 'Verificar a qualidade do material e exigir certificação de composição química.', 'EM_ANALISE');
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
AND table_name IN ('usuarios_rdm', 'reclamacoes_usuarios');

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
WHERE tablename IN ('usuarios_rdm', 'reclamacoes_usuarios');

COMMENT ON TABLE usuarios_rdm IS 'Cadastro de usuários autorizados a emitir RDMs - Sistema Comprar Bem';
COMMENT ON TABLE reclamacoes_usuarios IS 'Gestão de reclamações e sugestões sobre materiais - Sistema Comprar Bem';

-- ============================================
-- FIM DO SCRIPT
-- ============================================ 