-- ================================================================================================
-- 🔧 CRIAR TABELA PARA MÓDULO DE ANÁLISE DE PREÇOS - CPM
-- ================================================================================================
-- Script para criar a estrutura de dados do módulo de Análise de Preços
-- ================================================================================================

-- Criar tabela principal de análises de preços
CREATE TABLE IF NOT EXISTS analises_precos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- Dados básicos da análise
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100),
    
    -- Configuração da análise
    tipo_analise VARCHAR(50) DEFAULT 'temporal', -- temporal, comparativa, estatistica, tendencia
    periodo_inicio DATE NOT NULL,
    periodo_fim DATE NOT NULL,
    granularidade VARCHAR(20) DEFAULT 'mensal', -- diaria, semanal, mensal, trimestral, anual
    
    -- Filtros aplicados
    filtros_aplicados JSONB, -- critérios de filtragem usados
    produtos_incluidos JSONB, -- lista de produtos analisados
    fornecedores_incluidos JSONB, -- lista de fornecedores
    
    -- Resultados da análise
    resultados_estatisticos JSONB, -- médias, desvios, min, max, etc
    tendencias_identificadas JSONB, -- tendências de alta/baixa
    outliers_detectados JSONB, -- preços discrepantes
    
    -- Métricas calculadas
    variacao_percentual DECIMAL(8,4), -- variação % no período
    preco_medio DECIMAL(15,2),
    preco_minimo DECIMAL(15,2),
    preco_maximo DECIMAL(15,2),
    desvio_padrao DECIMAL(15,4),
    coeficiente_variacao DECIMAL(8,4),
    
    -- Status e controle
    status VARCHAR(50) DEFAULT 'processando', -- processando, concluida, erro
    progresso INTEGER DEFAULT 0, -- 0-100%
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    concluida_em TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID
);

-- Criar tabela de pontos de dados históricos
CREATE TABLE IF NOT EXISTS analises_precos_dados (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    analise_id UUID NOT NULL REFERENCES analises_precos(id) ON DELETE CASCADE,
    
    -- Identificação do produto/item
    produto_nome VARCHAR(500) NOT NULL,
    produto_categoria VARCHAR(100),
    produto_especificacao TEXT,
    
    -- Dados do fornecedor
    fornecedor_nome VARCHAR(255),
    fornecedor_cnpj VARCHAR(18),
    fornecedor_porte VARCHAR(50),
    
    -- Dados do preço
    preco DECIMAL(15,2) NOT NULL,
    moeda VARCHAR(3) DEFAULT 'BRL',
    quantidade DECIMAL(10,2),
    unidade_medida VARCHAR(50),
    
    -- Contexto temporal
    data_referencia DATE NOT NULL,
    mes_referencia INTEGER, -- 1-12
    ano_referencia INTEGER,
    trimestre INTEGER, -- 1-4
    
    -- Fonte dos dados
    fonte_dados VARCHAR(100), -- cotacao, comparativo, manual, importacao
    fonte_id UUID, -- ID da cotação/comparativo origem
    confiabilidade VARCHAR(20) DEFAULT 'media', -- alta, media, baixa
    
    -- Classificação
    eh_outlier BOOLEAN DEFAULT FALSE,
    motivo_outlier TEXT,
    incluido_calculo BOOLEAN DEFAULT TRUE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de tendências identificadas
CREATE TABLE IF NOT EXISTS analises_precos_tendencias (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    analise_id UUID NOT NULL REFERENCES analises_precos(id) ON DELETE CASCADE,
    
    -- Dados da tendência
    produto_nome VARCHAR(500),
    categoria VARCHAR(100),
    
    -- Tipo de tendência
    tipo_tendencia VARCHAR(50) NOT NULL, -- alta, baixa, estavel, volatil, sazonal
    intensidade VARCHAR(20), -- fraca, moderada, forte
    confianca DECIMAL(5,2), -- 0-100% de confiança estatística
    
    -- Período da tendência
    inicio_tendencia DATE,
    fim_tendencia DATE,
    duracao_dias INTEGER,
    
    -- Métricas da tendência
    variacao_percentual DECIMAL(8,4),
    preco_inicial DECIMAL(15,2),
    preco_final DECIMAL(15,2),
    maior_preco DECIMAL(15,2),
    menor_preco DECIMAL(15,2),
    
    -- Análise
    descricao TEXT,
    fatores_influencia JSONB, -- possíveis causas
    recomendacoes TEXT,
    
    -- Metadados
    detectada_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de alertas de preços
CREATE TABLE IF NOT EXISTS analises_precos_alertas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    analise_id UUID NOT NULL REFERENCES analises_precos(id) ON DELETE CASCADE,
    
    -- Tipo de alerta
    tipo_alerta VARCHAR(50) NOT NULL, -- preco_alto, preco_baixo, volatilidade, tendencia
    severidade VARCHAR(20) DEFAULT 'media', -- baixa, media, alta, critica
    
    -- Dados do produto
    produto_nome VARCHAR(500) NOT NULL,
    fornecedor_nome VARCHAR(255),
    
    -- Detalhes do alerta
    valor_atual DECIMAL(15,2),
    valor_referencia DECIMAL(15,2),
    percentual_variacao DECIMAL(8,4),
    
    -- Contexto
    descricao TEXT NOT NULL,
    recomendacao TEXT,
    data_deteccao DATE DEFAULT CURRENT_DATE,
    
    -- Status
    status VARCHAR(30) DEFAULT 'ativo', -- ativo, resolvido, ignorado
    resolvido_em TIMESTAMP WITH TIME ZONE,
    resolvido_por UUID,
    observacoes_resolucao TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de relatórios de análise
CREATE TABLE IF NOT EXISTS analises_precos_relatorios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    analise_id UUID NOT NULL REFERENCES analises_precos(id) ON DELETE CASCADE,
    
    -- Dados do relatório
    nome VARCHAR(255) NOT NULL,
    tipo_relatorio VARCHAR(50), -- estatistico, grafico, comparativo, executivo
    formato VARCHAR(20) DEFAULT 'pdf', -- pdf, xlsx, csv, json
    
    -- Conteúdo
    conteudo_json JSONB, -- dados estruturados do relatório
    url_arquivo TEXT, -- URL do arquivo gerado
    tamanho_arquivo BIGINT,
    
    -- Configurações
    parametros_geracao JSONB,
    template_usado VARCHAR(100),
    
    -- Status
    status VARCHAR(30) DEFAULT 'pendente', -- pendente, gerando, concluido, erro
    erro_detalhes TEXT,
    
    -- Metadados
    gerado_em TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_analises_precos_tenant_id ON analises_precos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_analises_precos_status ON analises_precos(status);
CREATE INDEX IF NOT EXISTS idx_analises_precos_periodo ON analises_precos(periodo_inicio, periodo_fim);
CREATE INDEX IF NOT EXISTS idx_analises_precos_tipo ON analises_precos(tipo_analise);

CREATE INDEX IF NOT EXISTS idx_analises_precos_dados_analise_id ON analises_precos_dados(analise_id);
CREATE INDEX IF NOT EXISTS idx_analises_precos_dados_produto ON analises_precos_dados(produto_nome);
CREATE INDEX IF NOT EXISTS idx_analises_precos_dados_data ON analises_precos_dados(data_referencia);
CREATE INDEX IF NOT EXISTS idx_analises_precos_dados_fornecedor ON analises_precos_dados(fornecedor_cnpj);
CREATE INDEX IF NOT EXISTS idx_analises_precos_dados_temporal ON analises_precos_dados(ano_referencia, mes_referencia);

CREATE INDEX IF NOT EXISTS idx_analises_precos_tendencias_analise_id ON analises_precos_tendencias(analise_id);
CREATE INDEX IF NOT EXISTS idx_analises_precos_tendencias_tipo ON analises_precos_tendencias(tipo_tendencia);
CREATE INDEX IF NOT EXISTS idx_analises_precos_tendencias_produto ON analises_precos_tendencias(produto_nome);

CREATE INDEX IF NOT EXISTS idx_analises_precos_alertas_analise_id ON analises_precos_alertas(analise_id);
CREATE INDEX IF NOT EXISTS idx_analises_precos_alertas_tipo ON analises_precos_alertas(tipo_alerta);
CREATE INDEX IF NOT EXISTS idx_analises_precos_alertas_status ON analises_precos_alertas(status);
CREATE INDEX IF NOT EXISTS idx_analises_precos_alertas_data ON analises_precos_alertas(data_deteccao);

CREATE INDEX IF NOT EXISTS idx_analises_precos_relatorios_analise_id ON analises_precos_relatorios(analise_id);
CREATE INDEX IF NOT EXISTS idx_analises_precos_relatorios_status ON analises_precos_relatorios(status);

-- Desabilitar RLS para todas as tabelas (para funcionamento imediato)
ALTER TABLE analises_precos DISABLE ROW LEVEL SECURITY;
ALTER TABLE analises_precos_dados DISABLE ROW LEVEL SECURITY;
ALTER TABLE analises_precos_tendencias DISABLE ROW LEVEL SECURITY;
ALTER TABLE analises_precos_alertas DISABLE ROW LEVEL SECURITY;
ALTER TABLE analises_precos_relatorios DISABLE ROW LEVEL SECURITY;

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_analises_precos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at
CREATE TRIGGER update_analises_precos_updated_at 
    BEFORE UPDATE ON analises_precos 
    FOR EACH ROW EXECUTE FUNCTION update_analises_precos_updated_at();

-- Função para calcular métricas automaticamente
CREATE OR REPLACE FUNCTION calcular_metricas_analise()
RETURNS TRIGGER AS $$
DECLARE
    v_count INTEGER;
    v_soma DECIMAL;
    v_media DECIMAL;
    v_min DECIMAL;
    v_max DECIMAL;
    v_variancia DECIMAL;
    v_desvio DECIMAL;
BEGIN
    -- Calcular estatísticas básicas dos dados da análise
    SELECT 
        COUNT(*),
        SUM(preco),
        AVG(preco),
        MIN(preco),
        MAX(preco)
    INTO v_count, v_soma, v_media, v_min, v_max
    FROM analises_precos_dados 
    WHERE analise_id = NEW.id 
    AND incluido_calculo = TRUE;
    
    -- Atualizar campos calculados
    IF v_count > 0 THEN
        NEW.preco_medio = v_media;
        NEW.preco_minimo = v_min;
        NEW.preco_maximo = v_max;
        
        -- Calcular variação percentual
        IF v_min > 0 THEN
            NEW.variacao_percentual = ((v_max - v_min) / v_min) * 100;
        END IF;
        
        -- Calcular desvio padrão se houver dados suficientes
        IF v_count > 1 THEN
            SELECT SQRT(AVG(POWER(preco - v_media, 2)))
            INTO v_desvio
            FROM analises_precos_dados 
            WHERE analise_id = NEW.id 
            AND incluido_calculo = TRUE;
            
            NEW.desvio_padrao = v_desvio;
            
            -- Coeficiente de variação
            IF v_media > 0 THEN
                NEW.coeficiente_variacao = (v_desvio / v_media) * 100;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para calcular métricas automaticamente
CREATE TRIGGER calcular_metricas_analise_trigger
    BEFORE UPDATE ON analises_precos 
    FOR EACH ROW 
    WHEN (NEW.status = 'concluida')
    EXECUTE FUNCTION calcular_metricas_analise();

-- Função para detectar outliers
CREATE OR REPLACE FUNCTION detectar_outliers()
RETURNS TRIGGER AS $$
DECLARE
    v_media DECIMAL;
    v_desvio DECIMAL;
    v_limite_superior DECIMAL;
    v_limite_inferior DECIMAL;
BEGIN
    -- Calcular média e desvio padrão dos preços similares
    SELECT AVG(preco), STDDEV(preco)
    INTO v_media, v_desvio
    FROM analises_precos_dados 
    WHERE analise_id = NEW.analise_id
    AND produto_nome = NEW.produto_nome
    AND id != NEW.id;
    
    -- Definir limites (2 desvios padrão)
    IF v_desvio IS NOT NULL AND v_desvio > 0 THEN
        v_limite_superior = v_media + (2 * v_desvio);
        v_limite_inferior = v_media - (2 * v_desvio);
        
        -- Verificar se é outlier
        IF NEW.preco > v_limite_superior OR NEW.preco < v_limite_inferior THEN
            NEW.eh_outlier = TRUE;
            NEW.motivo_outlier = 'Preço fora do intervalo de 2 desvios padrão';
        END IF;
    END IF;
    
    -- Extrair mês e ano da data
    NEW.mes_referencia = EXTRACT(MONTH FROM NEW.data_referencia);
    NEW.ano_referencia = EXTRACT(YEAR FROM NEW.data_referencia);
    NEW.trimestre = EXTRACT(QUARTER FROM NEW.data_referencia);
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para detectar outliers automaticamente
CREATE TRIGGER detectar_outliers_trigger
    BEFORE INSERT OR UPDATE ON analises_precos_dados 
    FOR EACH ROW EXECUTE FUNCTION detectar_outliers();

-- Verificar estrutura criada
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('analises_precos', 'analises_precos_dados', 'analises_precos_tendencias', 'analises_precos_alertas', 'analises_precos_relatorios')
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;