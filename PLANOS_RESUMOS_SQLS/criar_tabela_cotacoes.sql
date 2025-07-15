-- ================================================================================================
-- 🔧 CRIAR TABELA PARA MÓDULO DE COTAÇÕES - CPM
-- ================================================================================================
-- Script para criar a estrutura de dados do módulo de Cotações
-- ================================================================================================

-- Verificar se a tabela já existe
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'cotacoes'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Criar tabela de cotações
CREATE TABLE IF NOT EXISTS cotacoes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- Dados do produto/item
    produto_nome VARCHAR(500) NOT NULL,
    produto_descricao TEXT,
    produto_especificacao TEXT,
    unidade_medida VARCHAR(50),
    quantidade DECIMAL(10,2),
    
    -- Dados do fornecedor
    fornecedor_nome VARCHAR(255) NOT NULL,
    fornecedor_cnpj VARCHAR(18),
    fornecedor_contato VARCHAR(255),
    fornecedor_telefone VARCHAR(20),
    fornecedor_email VARCHAR(255),
    
    -- Dados comerciais
    preco_unitario DECIMAL(15,2) NOT NULL,
    preco_total DECIMAL(15,2),
    moeda VARCHAR(3) DEFAULT 'BRL',
    
    -- Condições comerciais
    prazo_entrega INTEGER, -- em dias
    prazo_entrega_descricao VARCHAR(255),
    condicoes_pagamento TEXT,
    validade_cotacao INTEGER DEFAULT 30, -- em dias
    
    -- Impostos e custos adicionais
    icms DECIMAL(5,2),
    ipi DECIMAL(5,2),
    outros_impostos DECIMAL(15,2),
    frete DECIMAL(15,2),
    desconto DECIMAL(15,2),
    
    -- Status e controle
    status VARCHAR(50) DEFAULT 'ativa', -- ativa, vencida, cancelada, aceita
    origem VARCHAR(100), -- manual, importacao, sistema
    observacoes TEXT,
    
    -- Metadados
    data_cotacao DATE NOT NULL DEFAULT CURRENT_DATE,
    data_validade DATE,
    data_resposta TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_cotacoes_tenant_id ON cotacoes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cotacoes_fornecedor_cnpj ON cotacoes(fornecedor_cnpj);
CREATE INDEX IF NOT EXISTS idx_cotacoes_produto_nome ON cotacoes(produto_nome);
CREATE INDEX IF NOT EXISTS idx_cotacoes_data_cotacao ON cotacoes(data_cotacao);
CREATE INDEX IF NOT EXISTS idx_cotacoes_status ON cotacoes(status);
CREATE INDEX IF NOT EXISTS idx_cotacoes_data_validade ON cotacoes(data_validade);

-- Criar tabela de anexos para cotações
CREATE TABLE IF NOT EXISTS cotacoes_anexos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cotacao_id UUID NOT NULL REFERENCES cotacoes(id) ON DELETE CASCADE,
    nome_arquivo VARCHAR(255) NOT NULL,
    tipo_arquivo VARCHAR(100),
    tamanho_arquivo BIGINT,
    url_arquivo TEXT,
    descricao TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

CREATE INDEX IF NOT EXISTS idx_cotacoes_anexos_cotacao_id ON cotacoes_anexos(cotacao_id);

-- Criar tabela de histórico de cotações
CREATE TABLE IF NOT EXISTS cotacoes_historico (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cotacao_id UUID NOT NULL REFERENCES cotacoes(id) ON DELETE CASCADE,
    acao VARCHAR(100) NOT NULL, -- criacao, edicao, cancelamento, aceitacao
    dados_anteriores JSONB,
    dados_novos JSONB,
    observacoes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

CREATE INDEX IF NOT EXISTS idx_cotacoes_historico_cotacao_id ON cotacoes_historico(cotacao_id);
CREATE INDEX IF NOT EXISTS idx_cotacoes_historico_acao ON cotacoes_historico(acao);

-- Habilitar RLS (Row Level Security) para isolamento por tenant
ALTER TABLE cotacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cotacoes_anexos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cotacoes_historico ENABLE ROW LEVEL SECURITY;

-- Criar política RLS para cotações
CREATE POLICY "Cotações isoladas por tenant" ON cotacoes
    FOR ALL USING (tenant_id = (current_setting('app.current_tenant_id'))::uuid);

-- Criar política RLS para anexos (herda o tenant_id da cotação)
CREATE POLICY "Anexos de cotações isoladas por tenant" ON cotacoes_anexos
    FOR ALL USING (
        cotacao_id IN (
            SELECT id FROM cotacoes 
            WHERE tenant_id = (current_setting('app.current_tenant_id'))::uuid
        )
    );

-- Criar política RLS para histórico (herda o tenant_id da cotação)
CREATE POLICY "Histórico de cotações isoladas por tenant" ON cotacoes_historico
    FOR ALL USING (
        cotacao_id IN (
            SELECT id FROM cotacoes 
            WHERE tenant_id = (current_setting('app.current_tenant_id'))::uuid
        )
    );

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at na tabela cotacoes
CREATE TRIGGER update_cotacoes_updated_at 
    BEFORE UPDATE ON cotacoes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Função para calcular data de validade automaticamente
CREATE OR REPLACE FUNCTION calcular_data_validade()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_validade IS NULL AND NEW.validade_cotacao IS NOT NULL THEN
        NEW.data_validade = NEW.data_cotacao + INTERVAL '1 day' * NEW.validade_cotacao;
    END IF;
    
    IF NEW.preco_total IS NULL AND NEW.preco_unitario IS NOT NULL AND NEW.quantidade IS NOT NULL THEN
        NEW.preco_total = NEW.preco_unitario * NEW.quantidade;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para calcular campos automaticamente
CREATE TRIGGER calcular_campos_cotacao 
    BEFORE INSERT OR UPDATE ON cotacoes 
    FOR EACH ROW EXECUTE FUNCTION calcular_data_validade();

-- Verificar estrutura criada
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('cotacoes', 'cotacoes_anexos', 'cotacoes_historico')
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- Inserir dados de exemplo (opcional para testes)
INSERT INTO cotacoes (
    tenant_id,
    produto_nome,
    produto_descricao,
    fornecedor_nome,
    fornecedor_cnpj,
    preco_unitario,
    quantidade,
    unidade_medida,
    prazo_entrega,
    condicoes_pagamento,
    observacoes
) VALUES 
(
    '00000000-0000-0000-0000-000000000001', -- Substituir pelo tenant_id real
    'Notebook Dell Inspiron 15',
    'Notebook com processador Intel i5, 8GB RAM, SSD 256GB',
    'Dell Computadores do Brasil Ltda',
    '12.345.678/0001-90',
    2500.00,
    10,
    'UN',
    15,
    '30 dias após entrega',
    'Garantia de 12 meses inclusa'
) ON CONFLICT DO NOTHING;