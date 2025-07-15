-- ================================================================================================
-- 🔧 CRIAR TABELA PARA MÓDULO DE COMPARATIVO TÉCNICO - CPM
-- ================================================================================================
-- Script para criar a estrutura de dados do módulo de Comparativo
-- ================================================================================================

-- Verificar se as tabelas já existem
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('comparativos', 'comparativos_itens')
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- Criar tabela principal de comparativos
CREATE TABLE IF NOT EXISTS comparativos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- Dados básicos do comparativo
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100),
    
    -- Metadados de controle
    status VARCHAR(50) DEFAULT 'em_andamento', -- em_andamento, finalizado, cancelado
    tipo_comparativo VARCHAR(50) DEFAULT 'tecnico', -- tecnico, preco, completo
    
    -- Configurações do comparativo
    criterios_avaliacao JSONB, -- critérios personalizados de avaliação
    pesos_criterios JSONB, -- pesos para cada critério
    metodologia VARCHAR(100) DEFAULT 'matriz_decisao', -- matriz_decisao, ranking, pontuacao
    
    -- Datas e controle
    data_inicio DATE DEFAULT CURRENT_DATE,
    data_conclusao DATE,
    prazo_resposta DATE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

-- Criar tabela de itens do comparativo (produtos/cotações sendo comparados)
CREATE TABLE IF NOT EXISTS comparativos_itens (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comparativo_id UUID NOT NULL REFERENCES comparativos(id) ON DELETE CASCADE,
    
    -- Referência aos dados originais
    cotacao_id UUID, -- referência à tabela cotacoes se aplicável
    fonte_dados VARCHAR(50) DEFAULT 'manual', -- manual, cotacao, catalogo
    
    -- Dados do produto
    produto_nome VARCHAR(500) NOT NULL,
    produto_descricao TEXT,
    especificacoes_tecnicas JSONB, -- especificações em formato flexível
    
    -- Dados do fornecedor
    fornecedor_nome VARCHAR(255) NOT NULL,
    fornecedor_cnpj VARCHAR(18),
    fornecedor_porte VARCHAR(50), -- micro, pequena, media, grande
    
    -- Dados comerciais
    preco_unitario DECIMAL(15,2),
    quantidade DECIMAL(10,2),
    preco_total DECIMAL(15,2),
    moeda VARCHAR(3) DEFAULT 'BRL',
    
    -- Condições comerciais
    prazo_entrega INTEGER, -- em dias
    condicoes_pagamento TEXT,
    garantia_produto INTEGER, -- em meses
    assistencia_tecnica TEXT,
    
    -- Avaliação e pontuação
    pontuacao_tecnica DECIMAL(5,2), -- 0-100
    pontuacao_comercial DECIMAL(5,2), -- 0-100
    pontuacao_fornecedor DECIMAL(5,2), -- 0-100
    pontuacao_final DECIMAL(5,2), -- 0-100
    posicao_ranking INTEGER,
    
    -- Observações
    vantagens TEXT,
    desvantagens TEXT,
    observacoes TEXT,
    recomendado BOOLEAN DEFAULT FALSE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de critérios de avaliação
CREATE TABLE IF NOT EXISTS comparativos_criterios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comparativo_id UUID NOT NULL REFERENCES comparativos(id) ON DELETE CASCADE,
    
    -- Dados do critério
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100), -- tecnico, comercial, fornecedor, sustentabilidade
    tipo_avaliacao VARCHAR(50) DEFAULT 'nota', -- nota, sim_nao, escala, texto
    
    -- Configuração de pontuação
    peso DECIMAL(5,2) DEFAULT 1.0, -- peso do critério (0-100)
    valor_minimo DECIMAL(10,2),
    valor_maximo DECIMAL(10,2),
    unidade VARCHAR(50),
    
    -- Controle
    obrigatorio BOOLEAN DEFAULT FALSE,
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT TRUE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de avaliações por critério
CREATE TABLE IF NOT EXISTS comparativos_avaliacoes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comparativo_id UUID NOT NULL REFERENCES comparativos(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES comparativos_itens(id) ON DELETE CASCADE,
    criterio_id UUID NOT NULL REFERENCES comparativos_criterios(id) ON DELETE CASCADE,
    
    -- Dados da avaliação
    valor_informado VARCHAR(500), -- valor original informado
    valor_numerico DECIMAL(15,4), -- valor convertido para cálculo
    pontuacao DECIMAL(5,2), -- pontuação calculada (0-100)
    
    -- Contexto da avaliação
    observacoes TEXT,
    fonte_informacao VARCHAR(100), -- manual, documento, site, etc
    confiabilidade VARCHAR(20) DEFAULT 'media', -- alta, media, baixa
    
    -- Metadados
    avaliado_por UUID,
    data_avaliacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de anexos/evidências
CREATE TABLE IF NOT EXISTS comparativos_anexos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comparativo_id UUID NOT NULL REFERENCES comparativos(id) ON DELETE CASCADE,
    item_id UUID REFERENCES comparativos_itens(id) ON DELETE CASCADE,
    
    -- Dados do arquivo
    nome_arquivo VARCHAR(255) NOT NULL,
    tipo_arquivo VARCHAR(100),
    tamanho_arquivo BIGINT,
    url_arquivo TEXT,
    
    -- Classificação
    categoria VARCHAR(100), -- especificacao, cotacao, certificado, manual, foto
    descricao TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_comparativos_tenant_id ON comparativos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_status ON comparativos(status);
CREATE INDEX IF NOT EXISTS idx_comparativos_data_inicio ON comparativos(data_inicio);

CREATE INDEX IF NOT EXISTS idx_comparativos_itens_comparativo_id ON comparativos_itens(comparativo_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_itens_cotacao_id ON comparativos_itens(cotacao_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_itens_fornecedor_cnpj ON comparativos_itens(fornecedor_cnpj);

CREATE INDEX IF NOT EXISTS idx_comparativos_criterios_comparativo_id ON comparativos_criterios(comparativo_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_criterios_categoria ON comparativos_criterios(categoria);

CREATE INDEX IF NOT EXISTS idx_comparativos_avaliacoes_comparativo_id ON comparativos_avaliacoes(comparativo_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_avaliacoes_item_id ON comparativos_avaliacoes(item_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_avaliacoes_criterio_id ON comparativos_avaliacoes(criterio_id);

CREATE INDEX IF NOT EXISTS idx_comparativos_anexos_comparativo_id ON comparativos_anexos(comparativo_id);
CREATE INDEX IF NOT EXISTS idx_comparativos_anexos_item_id ON comparativos_anexos(item_id);

-- Habilitar RLS para todas as tabelas
ALTER TABLE comparativos DISABLE ROW LEVEL SECURITY;
ALTER TABLE comparativos_itens DISABLE ROW LEVEL SECURITY;
ALTER TABLE comparativos_criterios DISABLE ROW LEVEL SECURITY;
ALTER TABLE comparativos_avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE comparativos_anexos DISABLE ROW LEVEL SECURITY;

-- Funções auxiliares

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_comparativos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_comparativos_updated_at 
    BEFORE UPDATE ON comparativos 
    FOR EACH ROW EXECUTE FUNCTION update_comparativos_updated_at();

CREATE TRIGGER update_comparativos_itens_updated_at 
    BEFORE UPDATE ON comparativos_itens 
    FOR EACH ROW EXECUTE FUNCTION update_comparativos_updated_at();

-- Função para calcular pontuação final automaticamente
CREATE OR REPLACE FUNCTION calcular_pontuacao_final()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular média ponderada das pontuações
    IF NEW.pontuacao_tecnica IS NOT NULL AND NEW.pontuacao_comercial IS NOT NULL AND NEW.pontuacao_fornecedor IS NOT NULL THEN
        NEW.pontuacao_final = (NEW.pontuacao_tecnica * 0.4 + NEW.pontuacao_comercial * 0.4 + NEW.pontuacao_fornecedor * 0.2);
    END IF;
    
    -- Calcular preço total se não informado
    IF NEW.preco_total IS NULL AND NEW.preco_unitario IS NOT NULL AND NEW.quantidade IS NOT NULL THEN
        NEW.preco_total = NEW.preco_unitario * NEW.quantidade;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para calcular pontuação final
CREATE TRIGGER calcular_pontuacao_final_trigger
    BEFORE INSERT OR UPDATE ON comparativos_itens 
    FOR EACH ROW EXECUTE FUNCTION calcular_pontuacao_final();

-- Inserir critérios padrão de exemplo
INSERT INTO comparativos_criterios (
    comparativo_id,
    nome,
    descricao,
    categoria,
    peso,
    ordem_exibicao
) VALUES 
(
    '00000000-0000-0000-0000-000000000001', -- Será substituído por comparativo real
    'Qualidade Técnica',
    'Avaliação das especificações técnicas e qualidade do produto',
    'tecnico',
    30.0,
    1
),
(
    '00000000-0000-0000-0000-000000000001',
    'Preço Competitivo',
    'Análise da competitividade do preço oferecido',
    'comercial',
    25.0,
    2
),
(
    '00000000-0000-0000-0000-000000000001',
    'Prazo de Entrega',
    'Adequação do prazo de entrega às necessidades',
    'comercial',
    15.0,
    3
),
(
    '00000000-0000-0000-0000-000000000001',
    'Reputação do Fornecedor',
    'Histórico e confiabilidade do fornecedor',
    'fornecedor',
    20.0,
    4
),
(
    '00000000-0000-0000-0000-000000000001',
    'Suporte Pós-Venda',
    'Qualidade do suporte técnico e garantia oferecida',
    'fornecedor',
    10.0,
    5
) ON CONFLICT DO NOTHING;

-- Verificar estrutura criada
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('comparativos', 'comparativos_itens', 'comparativos_criterios', 'comparativos_avaliacoes', 'comparativos_anexos')
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;