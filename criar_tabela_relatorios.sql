-- ================================================================================================
-- 🔧 CRIAR TABELA PARA MÓDULO DE RELATÓRIOS - CPM
-- ================================================================================================
-- Script para criar a estrutura de dados do módulo de Relatórios
-- ================================================================================================

-- Criar tabela principal de relatórios
CREATE TABLE IF NOT EXISTS relatorios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- Dados básicos do relatório
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100), -- pesquisa_mercado, cotacoes, comparativos, analise_precos, executivo
    
    -- Tipo e configuração
    tipo_relatorio VARCHAR(50) NOT NULL, -- consolidado, analise_tecnica, comparativo_precos, executivo, custom
    subtipo VARCHAR(50), -- detalhado, resumido, grafico, tabular
    formato_saida VARCHAR(20) DEFAULT 'pdf', -- pdf, xlsx, docx, csv, html
    template_usado VARCHAR(100),
    
    -- Fonte dos dados
    fonte_principal VARCHAR(50), -- cotacoes, comparativos, analises, manual, multiplas
    periodo_dados_inicio DATE,
    periodo_dados_fim DATE,
    filtros_aplicados JSONB, -- critérios de filtragem
    
    -- Dados utilizados
    cotacoes_incluidas JSONB, -- IDs das cotações
    comparativos_incluidos JSONB, -- IDs dos comparativos
    analises_incluidas JSONB, -- IDs das análises
    produtos_incluidos JSONB, -- lista de produtos
    fornecedores_incluidos JSONB, -- lista de fornecedores
    
    -- Configurações de geração
    configuracoes_geracao JSONB, -- parâmetros específicos
    incluir_graficos BOOLEAN DEFAULT TRUE,
    incluir_tabelas BOOLEAN DEFAULT TRUE,
    incluir_anexos BOOLEAN DEFAULT FALSE,
    incluir_assinaturas BOOLEAN DEFAULT TRUE,
    
    -- Conteúdo e resultados
    conteudo_estruturado JSONB, -- dados estruturados do relatório
    resumo_executivo TEXT,
    principais_achados JSONB, -- insights principais
    recomendacoes TEXT,
    
    -- Status e controle
    status VARCHAR(50) DEFAULT 'pendente', -- pendente, gerando, concluido, erro, cancelado
    progresso INTEGER DEFAULT 0, -- 0-100%
    erro_detalhes TEXT,
    tentativas_geracao INTEGER DEFAULT 0,
    
    -- Arquivos gerados
    url_arquivo_principal TEXT,
    urls_arquivos_auxiliares JSONB, -- anexos, gráficos separados, etc
    tamanho_arquivo_bytes BIGINT,
    hash_arquivo VARCHAR(255), -- para verificação de integridade
    
    -- Metadados
    gerado_em TIMESTAMP WITH TIME ZONE,
    expira_em TIMESTAMP WITH TIME ZONE, -- para limpeza automática
    visualizacoes INTEGER DEFAULT 0,
    downloads INTEGER DEFAULT 0,
    compartilhado BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

-- Criar tabela de seções do relatório
CREATE TABLE IF NOT EXISTS relatorios_secoes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relatorio_id UUID NOT NULL REFERENCES relatorios(id) ON DELETE CASCADE,
    
    -- Configuração da seção
    nome_secao VARCHAR(255) NOT NULL,
    tipo_secao VARCHAR(50) NOT NULL, -- cabecalho, resumo, dados, graficos, conclusoes, anexos
    ordem_exibicao INTEGER NOT NULL,
    incluir_secao BOOLEAN DEFAULT TRUE,
    
    -- Conteúdo
    titulo_secao VARCHAR(255),
    conteudo_texto TEXT,
    conteudo_estruturado JSONB, -- tabelas, gráficos, etc
    
    -- Configurações de formatação
    configuracoes_formatacao JSONB,
    quebra_pagina_antes BOOLEAN DEFAULT FALSE,
    quebra_pagina_depois BOOLEAN DEFAULT FALSE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de templates de relatórios
CREATE TABLE IF NOT EXISTS relatorios_templates (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID,
    
    -- Dados do template
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100),
    tipo_relatorio VARCHAR(50),
    
    -- Configuração do template
    estrutura_secoes JSONB NOT NULL, -- definição das seções
    configuracoes_padrao JSONB, -- configurações padrão
    variaveis_disponiveis JSONB, -- variáveis que podem ser usadas
    
    -- Arquivos do template
    arquivo_template_path TEXT, -- caminho para arquivo de template
    css_customizado TEXT,
    javascript_customizado TEXT,
    
    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    publico BOOLEAN DEFAULT FALSE, -- disponível para todos os tenants
    versao VARCHAR(20) DEFAULT '1.0',
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar tabela de histórico de geração
CREATE TABLE IF NOT EXISTS relatorios_historico (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relatorio_id UUID NOT NULL REFERENCES relatorios(id) ON DELETE CASCADE,
    
    -- Dados da tentativa
    tentativa_numero INTEGER NOT NULL,
    status_anterior VARCHAR(50),
    status_novo VARCHAR(50),
    
    -- Detalhes da execução
    inicio_processamento TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fim_processamento TIMESTAMP WITH TIME ZONE,
    tempo_processamento_segundos INTEGER,
    
    -- Resultados
    sucesso BOOLEAN DEFAULT FALSE,
    erro_codigo VARCHAR(50),
    erro_mensagem TEXT,
    warning_mensagens JSONB,
    
    -- Recursos utilizados
    memoria_utilizada_mb INTEGER,
    dados_processados_count INTEGER,
    
    -- Metadados
    processado_por UUID,
    ip_origem INET,
    user_agent TEXT
);

-- Criar tabela de compartilhamentos
CREATE TABLE IF NOT EXISTS relatorios_compartilhamentos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relatorio_id UUID NOT NULL REFERENCES relatorios(id) ON DELETE CASCADE,
    
    -- Dados do compartilhamento
    token_acesso VARCHAR(255) UNIQUE NOT NULL,
    senha_acesso VARCHAR(255), -- hash da senha se protegido
    
    -- Configurações de acesso
    publico BOOLEAN DEFAULT FALSE,
    requer_senha BOOLEAN DEFAULT FALSE,
    permite_download BOOLEAN DEFAULT TRUE,
    permite_visualizacao BOOLEAN DEFAULT TRUE,
    
    -- Controle de tempo
    data_expiracao TIMESTAMP WITH TIME ZONE,
    max_visualizacoes INTEGER,
    max_downloads INTEGER,
    
    -- Contadores
    visualizacoes_realizadas INTEGER DEFAULT 0,
    downloads_realizados INTEGER DEFAULT 0,
    
    -- Log de acessos
    ultimo_acesso TIMESTAMP WITH TIME ZONE,
    ips_acessos JSONB, -- log dos IPs que acessaram
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_relatorios_tenant_id ON relatorios(tenant_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_categoria ON relatorios(categoria);
CREATE INDEX IF NOT EXISTS idx_relatorios_tipo ON relatorios(tipo_relatorio);
CREATE INDEX IF NOT EXISTS idx_relatorios_status ON relatorios(status);
CREATE INDEX IF NOT EXISTS idx_relatorios_created_at ON relatorios(created_at);
CREATE INDEX IF NOT EXISTS idx_relatorios_gerado_em ON relatorios(gerado_em);

CREATE INDEX IF NOT EXISTS idx_relatorios_secoes_relatorio_id ON relatorios_secoes(relatorio_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_secoes_ordem ON relatorios_secoes(relatorio_id, ordem_exibicao);

CREATE INDEX IF NOT EXISTS idx_relatorios_templates_tenant_id ON relatorios_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_templates_categoria ON relatorios_templates(categoria);
CREATE INDEX IF NOT EXISTS idx_relatorios_templates_ativo ON relatorios_templates(ativo);

CREATE INDEX IF NOT EXISTS idx_relatorios_historico_relatorio_id ON relatorios_historico(relatorio_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_historico_status ON relatorios_historico(status_novo);
CREATE INDEX IF NOT EXISTS idx_relatorios_historico_data ON relatorios_historico(inicio_processamento);

CREATE INDEX IF NOT EXISTS idx_relatorios_compartilhamentos_relatorio_id ON relatorios_compartilhamentos(relatorio_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_compartilhamentos_token ON relatorios_compartilhamentos(token_acesso);
CREATE INDEX IF NOT EXISTS idx_relatorios_compartilhamentos_expiracao ON relatorios_compartilhamentos(data_expiracao);

-- Desabilitar RLS para todas as tabelas (para funcionamento imediato)
ALTER TABLE relatorios DISABLE ROW LEVEL SECURITY;
ALTER TABLE relatorios_secoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE relatorios_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE relatorios_historico DISABLE ROW LEVEL SECURITY;
ALTER TABLE relatorios_compartilhamentos DISABLE ROW LEVEL SECURITY;

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_relatorios_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_relatorios_updated_at 
    BEFORE UPDATE ON relatorios 
    FOR EACH ROW EXECUTE FUNCTION update_relatorios_updated_at();

CREATE TRIGGER update_relatorios_templates_updated_at 
    BEFORE UPDATE ON relatorios_templates 
    FOR EACH ROW EXECUTE FUNCTION update_relatorios_updated_at();

-- Função para gerar token de compartilhamento
CREATE OR REPLACE FUNCTION gerar_token_compartilhamento()
RETURNS TRIGGER AS $$
BEGIN
    -- Gerar token único de 32 caracteres
    NEW.token_acesso = encode(gen_random_bytes(24), 'base64');
    -- Remover caracteres problemáticos do token
    NEW.token_acesso = replace(replace(replace(NEW.token_acesso, '+', ''), '/', ''), '=', '');
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para gerar token automaticamente
CREATE TRIGGER gerar_token_compartilhamento_trigger
    BEFORE INSERT ON relatorios_compartilhamentos 
    FOR EACH ROW EXECUTE FUNCTION gerar_token_compartilhamento();

-- Função para limpar relatórios expirados
CREATE OR REPLACE FUNCTION limpar_relatorios_expirados()
RETURNS INTEGER AS $$
DECLARE
    relatorios_removidos INTEGER := 0;
BEGIN
    -- Remover relatórios expirados
    DELETE FROM relatorios 
    WHERE expira_em IS NOT NULL 
    AND expira_em < NOW();
    
    GET DIAGNOSTICS relatorios_removidos = ROW_COUNT;
    
    -- Limpar compartilhamentos expirados
    DELETE FROM relatorios_compartilhamentos 
    WHERE data_expiracao IS NOT NULL 
    AND data_expiracao < NOW();
    
    RETURN relatorios_removidos;
END;
$$ language 'plpgsql';

-- Inserir templates padrão
INSERT INTO relatorios_templates (
    nome,
    descricao,
    categoria,
    tipo_relatorio,
    estrutura_secoes,
    configuracoes_padrao,
    publico,
    ativo
) VALUES 
(
    'Relatório de Pesquisa de Mercado - Padrão',
    'Template padrão para relatórios de pesquisa de mercado com análise técnica e de preços',
    'pesquisa_mercado',
    'consolidado',
    '{"secoes": [
        {"nome": "capa", "tipo": "cabecalho", "obrigatoria": true},
        {"nome": "resumo_executivo", "tipo": "resumo", "obrigatoria": true},
        {"nome": "metodologia", "tipo": "dados", "obrigatoria": false},
        {"nome": "analise_tecnica", "tipo": "dados", "obrigatoria": true},
        {"nome": "analise_precos", "tipo": "dados", "obrigatoria": true},
        {"nome": "graficos", "tipo": "graficos", "obrigatoria": false},
        {"nome": "conclusoes", "tipo": "conclusoes", "obrigatoria": true},
        {"nome": "recomendacoes", "tipo": "conclusoes", "obrigatoria": true}
    ]}',
    '{"formato": "pdf", "incluir_graficos": true, "incluir_assinaturas": true}',
    true,
    true
),
(
    'Relatório de Cotações - Comparativo',
    'Template para relatórios comparativos de cotações de fornecedores',
    'cotacoes',
    'comparativo_precos',
    '{"secoes": [
        {"nome": "capa", "tipo": "cabecalho", "obrigatoria": true},
        {"nome": "resumo", "tipo": "resumo", "obrigatoria": true},
        {"nome": "criterios", "tipo": "dados", "obrigatoria": true},
        {"nome": "comparativo_precos", "tipo": "dados", "obrigatoria": true},
        {"nome": "ranking_fornecedores", "tipo": "dados", "obrigatoria": true},
        {"nome": "recomendacao", "tipo": "conclusoes", "obrigatoria": true}
    ]}',
    '{"formato": "pdf", "incluir_tabelas": true}',
    true,
    true
),
(
    'Relatório Executivo - Resumido',
    'Template para relatórios executivos com informações condensadas',
    'executivo',
    'executivo',
    '{"secoes": [
        {"nome": "capa", "tipo": "cabecalho", "obrigatoria": true},
        {"nome": "resumo_executivo", "tipo": "resumo", "obrigatoria": true},
        {"nome": "principais_achados", "tipo": "dados", "obrigatoria": true},
        {"nome": "recomendacoes_estrategicas", "tipo": "conclusoes", "obrigatoria": true}
    ]}',
    '{"formato": "pdf", "incluir_graficos": true, "paginas_maximas": 10}',
    true,
    true
) ON CONFLICT DO NOTHING;

-- Verificar estrutura criada
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('relatorios', 'relatorios_secoes', 'relatorios_templates', 'relatorios_historico', 'relatorios_compartilhamentos')
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;