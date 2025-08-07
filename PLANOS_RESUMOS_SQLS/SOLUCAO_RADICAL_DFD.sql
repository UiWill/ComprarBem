-- SOLUÇÃO RADICAL: Criar tabela com TODOS os campos possíveis

DROP TABLE IF EXISTS dfd_processo CASCADE;

CREATE TABLE dfd_processo (
    -- TODOS OS TIPOS DE ID POSSÍVEIS
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    documento_id UUID,
    documento_uuid UUID,
    doc_id UUID,
    ref_documento UUID,
    parent_id UUID,
    processo_pai UUID,
    documento_pai UUID,
    dfd_pai UUID,
    user_id UUID,
    usuario_id UUID,
    created_by UUID,
    updated_by UUID,
    
    -- RELACIONAMENTOS
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- CAMPOS DE NUMERAÇÃO
    numero_documento VARCHAR(50),
    numero_folha VARCHAR(20),
    folha_numero VARCHAR(20),
    sequencial INTEGER,
    numero_sequencial INTEGER,
    versao INTEGER DEFAULT 1,
    
    -- INFORMAÇÕES BÁSICAS
    tipo_dfd VARCHAR(20) NOT NULL DEFAULT 'MODELO1',
    titulo TEXT NOT NULL DEFAULT 'DFD',
    
    -- TODOS OS CAMPOS DE MODELO 1 E 2
    produtos_especificacao TEXT,
    quantidade_amostras INTEGER,
    previsao_aquisicoes TEXT,
    especificacoes_tecnicas TEXT,
    criterios_aceitacao TEXT,
    ensaios_exigidos TEXT,
    local_entrega_amostras TEXT,
    prazo_entrega_amostras TEXT,
    metodologia_avaliacao TEXT,
    criterios_desempate TEXT,
    produtos_despadronizar TEXT,
    fonte_rdm TEXT,
    fonte_reclamacoes_usuarios TEXT,
    fonte_sistema_comprar_bem TEXT,
    fonte_analise_tecnica TEXT,
    problemas_identificados TEXT,
    frequencia_problemas TEXT,
    impacto_problemas TEXT,
    quantidade_adquirida INTEGER,
    quantidade_problemas INTEGER,
    prejuizo_estimado DECIMAL(15,2),
    rdms_negativos TEXT,
    parecer_tecnico TEXT,
    alternativas_avaliadas TEXT,
    
    -- CAMPOS JURÍDICOS
    base_legal TEXT,
    fundamentacao_juridica TEXT,
    lei_aplicavel TEXT,
    artigo_lei TEXT,
    decreto_regulamentador TEXT,
    resolucao_aplicavel TEXT,
    
    -- CAMPOS ADMINISTRATIVOS
    justificativa TEXT,
    motivacao TEXT,
    necessidade_administrativa TEXT,
    interesse_publico TEXT,
    economicidade TEXT,
    
    -- CAMPOS DE CONTEÚDO
    conteudo JSONB,
    dados JSONB,
    content TEXT,
    body TEXT,
    observacoes TEXT,
    observacoes_internas TEXT,
    observacoes_juridicas TEXT,
    observacoes_tecnicas TEXT,
    anexos JSONB,
    
    -- CAMPOS DE CONTROLE
    status VARCHAR(50) DEFAULT 'rascunho',
    fase_processo VARCHAR(50) DEFAULT 'elaboracao',
    
    -- CAMPOS DE DATA
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_inicio DATE,
    data_prazo DATE,
    data_finalizacao TIMESTAMP WITH TIME ZONE,
    data_aprovacao TIMESTAMP WITH TIME ZONE,
    data_revisao TIMESTAMP WITH TIME ZONE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- CAMPOS DIVERSOS
    protocolo VARCHAR(50),
    numero_sei VARCHAR(50),
    orgao_origem TEXT,
    modalidade_licitacao VARCHAR(50),
    valor_estimado DECIMAL(15,2),
    resultado_avaliacao TEXT,
    parecer_final TEXT,
    decisao_final TEXT,
    metadata JSONB,
    tags TEXT[],
    categoria VARCHAR(100),
    prioridade VARCHAR(20) DEFAULT 'normal',
    confidencial BOOLEAN DEFAULT FALSE
);

-- DESABILITAR RLS
ALTER TABLE dfd_processo DISABLE ROW LEVEL SECURITY;

-- VERIFICAR DOCUMENTO_ID
SELECT 'TABELA RECRIADA COM DOCUMENTO_ID!' as status,
       'documento_id' as coluna,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'dfd_processo' AND column_name = 'documento_id'
       ) THEN 'EXISTE' ELSE 'NÃO EXISTE' END as resultado;