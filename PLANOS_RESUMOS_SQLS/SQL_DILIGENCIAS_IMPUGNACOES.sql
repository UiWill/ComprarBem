-- =============================================
-- TABELAS PARA DILIGÊNCIAS E IMPUGNAÇÕES
-- Sistema Comprar Bem
-- =============================================

-- Tabela para controlar diligências nos produtos
CREATE TABLE IF NOT EXISTS diligencias (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN (
        'DOCUMENTACAO_FALTANTE',
        'AMOSTRA_INADEQUADA', 
        'ESPECIFICACAO_INCOMPLETA',
        'CERTIFICACAO_PENDENTE',
        'ESCLARECIMENTO_TECNICO'
    )),
    descricao TEXT NOT NULL,
    prazo_dias INTEGER NOT NULL DEFAULT 5,
    data_limite TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE', 'ATENDIDA', 'VENCIDA')),
    solicitado_por VARCHAR(100),
    resposta_fornecedor TEXT,
    data_resposta TIMESTAMP WITH TIME ZONE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela para gerenciar editais (necessária para impugnações)
CREATE TABLE IF NOT EXISTS editais (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    numero VARCHAR(50) NOT NULL,
    descricao TEXT NOT NULL,
    conteudo TEXT,
    data_publicacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_limite_impugnacao TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL DEFAULT 'RASCUNHO' CHECK (status IN ('RASCUNHO', 'PUBLICADO', 'CANCELADO')),
    url_documento VARCHAR(500),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela para controlar impugnações aos editais
CREATE TABLE IF NOT EXISTS impugnacoes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    edital_id UUID REFERENCES editais(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE SET NULL,
    tenant_id UUID NOT NULL,
    impugnante VARCHAR(200) NOT NULL,
    documento_impugnante VARCHAR(20) NOT NULL, -- CPF ou CNPJ
    email_impugnante VARCHAR(200) NOT NULL,
    telefone_impugnante VARCHAR(20),
    motivo TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'EM_ANALISE' CHECK (status IN (
        'EM_ANALISE', 
        'DEFERIDA', 
        'INDEFERIDA', 
        'PARCIALMENTE_DEFERIDA'
    )),
    data_impugnacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    prazo_final TIMESTAMP WITH TIME ZONE NOT NULL,
    justificativa_decisao TEXT,
    data_decisao TIMESTAMP WITH TIME ZONE,
    analisado_por VARCHAR(100),
    url_documento VARCHAR(500), -- URL do documento da impugnação
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para otimização
CREATE INDEX IF NOT EXISTS idx_diligencias_produto_id ON diligencias(produto_id);
CREATE INDEX IF NOT EXISTS idx_diligencias_tenant_id ON diligencias(tenant_id);
CREATE INDEX IF NOT EXISTS idx_diligencias_status ON diligencias(status);

CREATE INDEX IF NOT EXISTS idx_editais_tenant_id ON editais(tenant_id);
CREATE INDEX IF NOT EXISTS idx_editais_status ON editais(status);

CREATE INDEX IF NOT EXISTS idx_impugnacoes_edital_id ON impugnacoes(edital_id);
CREATE INDEX IF NOT EXISTS idx_impugnacoes_tenant_id ON impugnacoes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_impugnacoes_status ON impugnacoes(status);

-- Triggers para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_diligencias_updated_at BEFORE UPDATE ON diligencias 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_editais_updated_at BEFORE UPDATE ON editais 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_impugnacoes_updated_at BEFORE UPDATE ON impugnacoes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) para multi-tenancy
ALTER TABLE diligencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE editais ENABLE ROW LEVEL SECURITY;
ALTER TABLE impugnacoes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Diligências apenas do próprio tenant" ON diligencias
    USING (tenant_id = (current_setting('app.current_tenant_id', true))::uuid);

CREATE POLICY "Editais apenas do próprio tenant" ON editais
    USING (tenant_id = (current_setting('app.current_tenant_id', true))::uuid);

CREATE POLICY "Impugnações apenas do próprio tenant" ON impugnacoes
    USING (tenant_id = (current_setting('app.current_tenant_id', true))::uuid);

-- Inserir dados de exemplo para teste
INSERT INTO editais (tenant_id, numero, descricao, status, data_publicacao) VALUES 
(uuid_generate_v4(), '001/2024', 'Pré-qualificação de Equipamentos Médicos', 'PUBLICADO', NOW() - INTERVAL '10 days'),
(uuid_generate_v4(), '002/2024', 'Pré-qualificação de Material de Consumo', 'PUBLICADO', NOW() - INTERVAL '5 days')
ON CONFLICT DO NOTHING; 