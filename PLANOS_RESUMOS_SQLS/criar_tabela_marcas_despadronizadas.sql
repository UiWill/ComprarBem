-- ================================================================================================
-- 🔧 CRIAR TABELA PARA MÓDULO DE MARCAS DESPADRONIZADAS - CPM
-- ================================================================================================
-- Script para criar a estrutura de dados do módulo de Marcas Despadronizadas
-- ================================================================================================

-- Criar tabela principal de marcas despadronizadas
CREATE TABLE IF NOT EXISTS marcas_despadronizadas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- Dados da marca/produto
    produto_id UUID, -- referência ao produto se existir
    marca VARCHAR(255) NOT NULL,
    modelo VARCHAR(255),
    codigo_produto VARCHAR(100),
    categoria VARCHAR(100), -- categoria do produto
    fabricante VARCHAR(255),
    fornecedor_anterior VARCHAR(255),
    
    -- Dados da despadronização
    numero_processo VARCHAR(100), -- número do processo administrativo
    data_despadronizacao DATE NOT NULL,
    tipo_despadronizacao VARCHAR(50) NOT NULL, -- total, parcial, temporaria, definitiva
    status_atual VARCHAR(50) DEFAULT 'ativa', -- ativa, revogada, expirada, suspensa
    
    -- Motivos e justificativas
    motivo_principal VARCHAR(100) NOT NULL, -- qualidade, custo, descontinuacao, seguranca, etc
    motivos_detalhados JSONB, -- lista de motivos específicos
    justificativa TEXT NOT NULL, -- justificativa detalhada
    evidencias_tecnicas TEXT, -- evidências técnicas que embasaram a decisão
    parecer_tecnico TEXT, -- parecer da área técnica
    
    -- Impacto e restrições
    nivel_criticidade VARCHAR(20) DEFAULT 'medio', -- baixo, medio, alto, critico
    impacto_estimado TEXT, -- impacto esperado da despadronização
    restricoes_uso TEXT, -- restrições específicas de uso
    alternativas_recomendadas TEXT, -- produtos/marcas alternativas
    prazo_transicao INTEGER, -- prazo em dias para transição
    
    -- Abrangência da despadronização
    setores_afetados JSONB, -- lista de setores/departamentos afetados
    contratos_afetados JSONB, -- contratos que serão impactados
    quantidade_estoque_atual INTEGER, -- estoque atual do produto
    valor_estoque_atual DECIMAL(12,2), -- valor do estoque atual
    
    -- Responsáveis e aprovações
    solicitante_nome VARCHAR(255), -- quem solicitou a despadronização
    solicitante_cargo VARCHAR(255),
    solicitante_setor VARCHAR(255),
    responsavel_tecnico_nome VARCHAR(255), -- responsável técnico pela análise
    responsavel_tecnico_cargo VARCHAR(255),
    aprovador_nome VARCHAR(255), -- quem aprovou a despadronização
    aprovador_cargo VARCHAR(255),
    data_aprovacao TIMESTAMP WITH TIME ZONE,
    
    -- Prazos e vigência
    data_inicio_vigencia DATE, -- quando a despadronização entra em vigor
    data_fim_vigencia DATE, -- quando expira (se temporária)
    prazo_revisao INTEGER, -- prazo em meses para revisão
    proxima_revisao DATE, -- data da próxima revisão obrigatória
    
    -- Comunicações e notificações
    notificacoes_enviadas JSONB, -- registro de notificações enviadas
    setores_notificados JSONB, -- setores que foram notificados
    data_publicacao_interna DATE, -- data de publicação interna
    numero_comunicado VARCHAR(100), -- número do comunicado oficial
    
    -- Órgãos de controle
    notificado_tcu BOOLEAN DEFAULT FALSE, -- notificado ao TCU
    data_notificacao_tcu DATE,
    numero_oficio_tcu VARCHAR(100),
    notificado_mp BOOLEAN DEFAULT FALSE, -- notificado ao Ministério Público
    data_notificacao_mp DATE,
    numero_oficio_mp VARCHAR(100),
    notificado_outros JSONB, -- outros órgãos notificados
    
    -- Acompanhamento e revisão
    status_acompanhamento VARCHAR(50) DEFAULT 'aguardando', -- aguardando, em_analise, finalizado
    observacoes_acompanhamento TEXT,
    necessita_revisao BOOLEAN DEFAULT FALSE,
    revisao_programada BOOLEAN DEFAULT FALSE,
    
    -- Resultado e efetividade
    economia_gerada DECIMAL(12,2), -- economia gerada pela despadronização
    problemas_identificados TEXT, -- problemas identificados após despadronização
    medidas_corretivas TEXT, -- medidas corretivas aplicadas
    avaliacao_efetividade TEXT, -- avaliação da efetividade
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Documentos e anexos
    documentos_anexos JSONB, -- lista de documentos anexados
    ata_reuniao_url TEXT, -- URL da ata da reunião de decisão
    parecer_juridico_url TEXT, -- URL do parecer jurídico
    laudo_tecnico_url TEXT -- URL do laudo técnico
);

-- Criar tabela de histórico de alterações
CREATE TABLE IF NOT EXISTS marcas_despadronizadas_historico (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    marca_despadronizada_id UUID NOT NULL REFERENCES marcas_despadronizadas(id) ON DELETE CASCADE,
    
    -- Dados da alteração
    tipo_alteracao VARCHAR(50) NOT NULL, -- criacao, edicao, status_change, revisao, revogacao
    campo_alterado VARCHAR(100), -- campo específico que foi alterado
    valor_anterior TEXT, -- valor anterior do campo
    valor_novo TEXT, -- novo valor do campo
    
    -- Motivo da alteração
    motivo_alteracao VARCHAR(100),
    justificativa_alteracao TEXT,
    
    -- Responsável pela alteração
    alterado_por UUID,
    alterado_por_nome VARCHAR(255),
    alterado_por_cargo VARCHAR(255),
    
    -- Aprovação da alteração (se necessária)
    requer_aprovacao BOOLEAN DEFAULT FALSE,
    aprovado BOOLEAN DEFAULT TRUE,
    aprovado_por UUID,
    aprovado_por_nome VARCHAR(255),
    data_aprovacao TIMESTAMP WITH TIME ZONE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_origem INET,
    user_agent TEXT
);

-- Criar tabela de notificações enviadas
CREATE TABLE IF NOT EXISTS marcas_despadronizadas_notificacoes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    marca_despadronizada_id UUID NOT NULL REFERENCES marcas_despadronizadas(id) ON DELETE CASCADE,
    
    -- Dados da notificação
    tipo_notificacao VARCHAR(50) NOT NULL, -- email, oficio, comunicado, alerta
    destinatario_tipo VARCHAR(50), -- setor, pessoa, orgao_externo
    destinatario_nome VARCHAR(255),
    destinatario_email VARCHAR(255),
    destinatario_cargo VARCHAR(255),
    destinatario_setor VARCHAR(255),
    
    -- Conteúdo da notificação
    assunto VARCHAR(500),
    mensagem TEXT,
    template_usado VARCHAR(100),
    anexos JSONB, -- lista de anexos enviados
    
    -- Status da notificação
    status VARCHAR(50) DEFAULT 'pendente', -- pendente, enviada, entregue, lida, erro
    tentativas_envio INTEGER DEFAULT 0,
    data_envio TIMESTAMP WITH TIME ZONE,
    data_entrega TIMESTAMP WITH TIME ZONE,
    data_leitura TIMESTAMP WITH TIME ZONE,
    erro_detalhes TEXT,
    
    -- Respostas e confirmações
    confirmacao_recebimento BOOLEAN DEFAULT FALSE,
    data_confirmacao TIMESTAMP WITH TIME ZONE,
    resposta_recebida BOOLEAN DEFAULT FALSE,
    resposta_conteudo TEXT,
    data_resposta TIMESTAMP WITH TIME ZONE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar tabela de impactos por setor
CREATE TABLE IF NOT EXISTS marcas_despadronizadas_impactos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    marca_despadronizada_id UUID NOT NULL REFERENCES marcas_despadronizadas(id) ON DELETE CASCADE,
    
    -- Setor afetado
    setor_nome VARCHAR(255) NOT NULL,
    setor_responsavel VARCHAR(255),
    setor_email VARCHAR(255),
    
    -- Tipo e grau do impacto
    tipo_impacto VARCHAR(100) NOT NULL, -- operacional, financeiro, tecnico, logistico
    grau_impacto VARCHAR(20) NOT NULL, -- baixo, medio, alto, critico
    
    -- Detalhes do impacto
    descricao_impacto TEXT NOT NULL,
    quantidade_afetada INTEGER, -- quantidade de itens/equipamentos afetados
    valor_estimado DECIMAL(12,2), -- valor estimado do impacto
    prazo_adequacao INTEGER, -- prazo em dias para adequação
    
    -- Medidas mitigadoras
    medidas_mitigadoras TEXT,
    alternativas_disponiveis TEXT,
    cronograma_transicao TEXT,
    recursos_necessarios TEXT,
    
    -- Acompanhamento
    status_adequacao VARCHAR(50) DEFAULT 'pendente', -- pendente, em_andamento, concluida
    data_inicio_adequacao DATE,
    data_conclusao_adequacao DATE,
    percentual_conclusao INTEGER DEFAULT 0,
    
    -- Avaliação pós-implementação
    resultado_adequacao TEXT,
    dificuldades_encontradas TEXT,
    licoes_aprendidas TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar tabela de revisões programadas
CREATE TABLE IF NOT EXISTS marcas_despadronizadas_revisoes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    marca_despadronizada_id UUID NOT NULL REFERENCES marcas_despadronizadas(id) ON DELETE CASCADE,
    
    -- Dados da revisão
    numero_revisao INTEGER NOT NULL, -- 1ª revisão, 2ª revisão, etc
    tipo_revisao VARCHAR(50) NOT NULL, -- periodica, extraordinaria, por_solicitacao
    data_programada DATE NOT NULL,
    data_realizada DATE,
    
    -- Motivo e escopo da revisão
    motivo_revisao VARCHAR(100),
    escopo_revisao TEXT, -- o que será analisado na revisão
    criterios_avaliacao TEXT, -- critérios para avaliação
    
    -- Responsáveis pela revisão
    equipe_revisao JSONB, -- equipe responsável pela revisão
    coordenador_nome VARCHAR(255),
    coordenador_cargo VARCHAR(255),
    
    -- Status da revisão
    status VARCHAR(50) DEFAULT 'programada', -- programada, em_andamento, concluida, cancelada
    data_inicio DATE,
    data_conclusao DATE,
    progresso_percentual INTEGER DEFAULT 0,
    
    -- Resultados da revisão
    resultado VARCHAR(50), -- manter, alterar, revogar, prorrogar
    recomendacoes TEXT,
    alteracoes_sugeridas TEXT,
    justificativa_resultado TEXT,
    
    -- Documentação da revisão
    ata_revisao_url TEXT,
    relatorio_revisao_url TEXT,
    documentos_consultados JSONB,
    
    -- Próximos passos
    proxima_revisao_programada DATE,
    acoes_decorrentes TEXT,
    responsaveis_acoes JSONB,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_tenant_id ON marcas_despadronizadas(tenant_id);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_marca ON marcas_despadronizadas(marca);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_status ON marcas_despadronizadas(status_atual);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_tipo ON marcas_despadronizadas(tipo_despadronizacao);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_motivo ON marcas_despadronizadas(motivo_principal);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_categoria ON marcas_despadronizadas(categoria);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_data_despad ON marcas_despadronizadas(data_despadronizacao);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_vigencia ON marcas_despadronizadas(data_fim_vigencia);
CREATE INDEX IF NOT EXISTS idx_marcas_despadronizadas_revisao ON marcas_despadronizadas(proxima_revisao);

CREATE INDEX IF NOT EXISTS idx_marcas_historico_marca_id ON marcas_despadronizadas_historico(marca_despadronizada_id);
CREATE INDEX IF NOT EXISTS idx_marcas_historico_tipo ON marcas_despadronizadas_historico(tipo_alteracao);
CREATE INDEX IF NOT EXISTS idx_marcas_historico_data ON marcas_despadronizadas_historico(created_at);

CREATE INDEX IF NOT EXISTS idx_marcas_notificacoes_marca_id ON marcas_despadronizadas_notificacoes(marca_despadronizada_id);
CREATE INDEX IF NOT EXISTS idx_marcas_notificacoes_status ON marcas_despadronizadas_notificacoes(status);
CREATE INDEX IF NOT EXISTS idx_marcas_notificacoes_tipo ON marcas_despadronizadas_notificacoes(tipo_notificacao);

CREATE INDEX IF NOT EXISTS idx_marcas_impactos_marca_id ON marcas_despadronizadas_impactos(marca_despadronizada_id);
CREATE INDEX IF NOT EXISTS idx_marcas_impactos_setor ON marcas_despadronizadas_impactos(setor_nome);
CREATE INDEX IF NOT EXISTS idx_marcas_impactos_status ON marcas_despadronizadas_impactos(status_adequacao);

CREATE INDEX IF NOT EXISTS idx_marcas_revisoes_marca_id ON marcas_despadronizadas_revisoes(marca_despadronizada_id);
CREATE INDEX IF NOT EXISTS idx_marcas_revisoes_data_prog ON marcas_despadronizadas_revisoes(data_programada);
CREATE INDEX IF NOT EXISTS idx_marcas_revisoes_status ON marcas_despadronizadas_revisoes(status);

-- Desabilitar RLS para todas as tabelas (para funcionamento imediato)
ALTER TABLE marcas_despadronizadas DISABLE ROW LEVEL SECURITY;
ALTER TABLE marcas_despadronizadas_historico DISABLE ROW LEVEL SECURITY;
ALTER TABLE marcas_despadronizadas_notificacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE marcas_despadronizadas_impactos DISABLE ROW LEVEL SECURITY;
ALTER TABLE marcas_despadronizadas_revisoes DISABLE ROW LEVEL SECURITY;

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_marcas_despadronizadas_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_marcas_despadronizadas_updated_at 
    BEFORE UPDATE ON marcas_despadronizadas 
    FOR EACH ROW EXECUTE FUNCTION update_marcas_despadronizadas_updated_at();

CREATE TRIGGER update_marcas_impactos_updated_at 
    BEFORE UPDATE ON marcas_despadronizadas_impactos 
    FOR EACH ROW EXECUTE FUNCTION update_marcas_despadronizadas_updated_at();

CREATE TRIGGER update_marcas_revisoes_updated_at 
    BEFORE UPDATE ON marcas_despadronizadas_revisoes 
    FOR EACH ROW EXECUTE FUNCTION update_marcas_despadronizadas_updated_at();

-- Função para registrar histórico automaticamente
CREATE OR REPLACE FUNCTION registrar_historico_marca_despadronizada()
RETURNS TRIGGER AS $$
BEGIN
    -- Registrar alteração no histórico
    INSERT INTO marcas_despadronizadas_historico (
        marca_despadronizada_id,
        tipo_alteracao,
        valor_anterior,
        valor_novo,
        motivo_alteracao,
        alterado_por,
        alterado_por_nome
    ) VALUES (
        COALESCE(NEW.id, OLD.id),
        CASE 
            WHEN TG_OP = 'INSERT' THEN 'criacao'
            WHEN TG_OP = 'UPDATE' THEN 'edicao'
            WHEN TG_OP = 'DELETE' THEN 'exclusao'
        END,
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD)::text ELSE NULL END,
        CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE row_to_json(NEW)::text END,
        'Alteração automática via sistema',
        COALESCE(NEW.updated_by, OLD.updated_by),
        'Sistema Automatico'
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Trigger para registrar histórico
CREATE TRIGGER registrar_historico_marca_despadronizada_trigger
    AFTER INSERT OR UPDATE OR DELETE ON marcas_despadronizadas 
    FOR EACH ROW EXECUTE FUNCTION registrar_historico_marca_despadronizada();

-- Função para verificar revisões pendentes
CREATE OR REPLACE FUNCTION verificar_revisoes_pendentes()
RETURNS TABLE(
    marca_id UUID,
    marca VARCHAR,
    modelo VARCHAR,
    proxima_revisao DATE,
    dias_atraso INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        md.id,
        md.marca,
        md.modelo,
        md.proxima_revisao,
        (CURRENT_DATE - md.proxima_revisao)::INTEGER as dias_atraso
    FROM marcas_despadronizadas md
    WHERE md.proxima_revisao IS NOT NULL 
    AND md.proxima_revisao <= CURRENT_DATE
    AND md.status_atual = 'ativa'
    ORDER BY md.proxima_revisao ASC;
END;
$$ language 'plpgsql';

-- Inserir dados de exemplo para testes
INSERT INTO marcas_despadronizadas (
    tenant_id,
    marca,
    modelo,
    categoria,
    fabricante,
    numero_processo,
    data_despadronizacao,
    tipo_despadronizacao,
    motivo_principal,
    justificativa,
    nivel_criticidade,
    solicitante_nome,
    solicitante_cargo,
    solicitante_setor,
    data_inicio_vigencia,
    proxima_revisao
) VALUES 
(
    '00000000-0000-0000-0000-000000000000', -- placeholder tenant
    'HP',
    'Deskjet 2050',
    'Impressoras',
    'Hewlett-Packard',
    'PROC-2024-001',
    '2024-01-15',
    'definitiva',
    'qualidade',
    'Identificados problemas recorrentes de qualidade de impressão e frequentes defeitos no mecanismo de alimentação de papel, gerando custos elevados de manutenção.',
    'medio',
    'João Silva',
    'Coordenador de TI',
    'Tecnologia da Informação',
    '2024-02-01',
    '2025-01-15'
),
(
    '00000000-0000-0000-0000-000000000000',
    'Samsung',
    'Galaxy Tab A8',
    'Tablets',
    'Samsung Electronics',
    'PROC-2024-002',
    '2024-03-10',
    'temporaria',
    'custo',
    'Identificado aumento significativo no preço de aquisição (>40%) sem justificativa técnica adequada. Análise de mercado indica opções similares com melhor custo-benefício.',
    'baixo',
    'Maria Santos',
    'Gerente de Compras',
    'Administração',
    '2024-04-01',
    '2024-12-10'
),
(
    '00000000-0000-0000-0000-000000000000',
    'Dell',
    'Optiplex 3090',
    'Computadores',
    'Dell Technologies',
    'PROC-2024-003',
    '2024-05-20',
    'parcial',
    'descontinuacao',
    'Produto descontinuado pelo fabricante. Falta de suporte técnico e dificuldade para aquisição de peças de reposição.',
    'alto',
    'Carlos Oliveira',
    'Analista de Sistemas',
    'Tecnologia da Informação',
    '2024-06-01',
    '2025-05-20'
) ON CONFLICT DO NOTHING;

-- Verificar estrutura criada
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN (
    'marcas_despadronizadas', 
    'marcas_despadronizadas_historico', 
    'marcas_despadronizadas_notificacoes',
    'marcas_despadronizadas_impactos',
    'marcas_despadronizadas_revisoes'
) AND table_schema = 'public'
ORDER BY table_name, ordinal_position;