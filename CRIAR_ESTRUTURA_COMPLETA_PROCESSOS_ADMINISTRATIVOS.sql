-- ================================================================
-- ESTRUTURA COMPLETA PARA PROCESSOS ADMINISTRATIVOS
-- Baseada na análise completa de:
-- - AssistenteProcesso.vue 
-- - ProcessosAdministrativosComponent.vue
-- - ProcessosAdministrativosService.js
-- - FormularioDFD.vue
-- ================================================================

-- DESABILITAR RLS EM TODAS AS TABELAS
ALTER TABLE IF EXISTS processos_administrativos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS dfd_processo DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS documentos_processo DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS produtos_prequalificacao DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assinaturas_processo DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tramitacao_processo DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS recursos_processo DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS dcb_emitidas DISABLE ROW LEVEL SECURITY;

-- ================================================================
-- 1. TABELA PRINCIPAL DE PROCESSOS ADMINISTRATIVOS
-- ================================================================

DROP TABLE IF EXISTS processos_administrativos CASCADE;

CREATE TABLE processos_administrativos (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- === CAMPOS BÁSICOS ===
    numero_processo VARCHAR(100),
    tipo_processo VARCHAR(50) NOT NULL, -- 'padronizacao', 'despadronizacao'
    status VARCHAR(50) DEFAULT 'RASCUNHO', -- Status do workflow
    objeto TEXT,
    
    -- === DADOS DO ÓRGÃO ===
    nome_orgao TEXT NOT NULL,
    unidade_interessada TEXT NOT NULL,
    observacoes TEXT,
    
    -- === CAMPOS DE AUDITORIA ===
    criado_por UUID,
    atualizado_por UUID,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_autuacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_finalizacao TIMESTAMP WITH TIME ZONE,
    
    -- === CAMPOS EXTRAS PARA COMPATIBILIDADE ===
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_id UUID,
    updated_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- === CAMPOS DE CONTROLE ===
    ativo BOOLEAN DEFAULT TRUE
);

-- ================================================================
-- 2. TABELA DFD (DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA) - COMPLETA
-- ================================================================

DROP TABLE IF EXISTS dfd_processo CASCADE;

CREATE TABLE dfd_processo (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    processo_id UUID NOT NULL,
    documento_id UUID,
    tenant_id UUID NOT NULL,
    
    -- === INFORMAÇÕES BÁSICAS ===
    tipo_dfd VARCHAR(20) NOT NULL DEFAULT 'MODELO1', -- 'MODELO1', 'MODELO2'
    modelo_usado VARCHAR(20) NOT NULL DEFAULT 'MODELO1',
    titulo TEXT NOT NULL DEFAULT 'DFD',
    
    -- === CAMPOS OBRIGATÓRIOS BÁSICOS ===
    justificativa TEXT, -- v-model="dadosDFD.justificativa"
    necessidade_descricao TEXT, -- v-model="dadosDFD.necessidade_descricao"
    
    -- === CAMPOS MODELO 1 (PADRONIZAÇÃO) ===
    produtos_especificacao TEXT, -- v-model="dadosDFD.produtos_especificacao"
    quantidade_amostras INTEGER, -- v-model.number="dadosDFD.quantidade_amostras"
    previsao_aquisicoes TEXT, -- v-model="dadosDFD.previsao_aquisicoes"
    especificacoes_tecnicas TEXT, -- v-model="dadosDFD.especificacoes_tecnicas"
    criterios_aceitacao TEXT, -- v-model="dadosDFD.criterios_aceitacao"
    ensaios_exigidos TEXT, -- v-model="dadosDFD.ensaios_exigidos"
    local_entrega_amostras TEXT, -- v-model="dadosDFD.local_entrega_amostras"
    prazo_entrega_amostras TEXT, -- v-model="dadosDFD.prazo_entrega_amostras"
    metodologia_avaliacao TEXT, -- v-model="dadosDFD.metodologia_avaliacao"
    criterios_desempate TEXT, -- v-model="dadosDFD.criterios_desempate"
    
    -- === CAMPOS MODELO 2 (DESPADRONIZAÇÃO) ===
    produtos_despadronizar TEXT, -- v-model="dadosDFD.produtos_despadronizar"
    
    -- === FONTES DE INFORMAÇÃO (CHECKBOXES E TEXTOS) ===
    fonte_rdm BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_rdm"
    fonte_reclamacoes_usuarios BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_reclamacoes_usuarios"
    fonte_sistema_comprar_bem BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_sistema_comprar_bem"
    fonte_analise_tecnica BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_analise_tecnica"
    fonte_outros BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_outros" ← ESTE ESTAVA FALTANDO!
    outras_fontes TEXT, -- v-model="dadosDFD.outras_fontes"
    
    -- CAMPOS DE TEXTO PARA AS FONTES (para compatibilidade com service)
    fonte_rdm_texto TEXT,
    fonte_reclamacoes_usuarios_texto TEXT,
    fonte_sistema_comprar_bem_texto TEXT,
    fonte_analise_tecnica_texto TEXT,
    
    -- === PROBLEMAS E MOTIVAÇÕES ===
    problemas_identificados TEXT, -- v-model="dadosDFD.problemas_identificados"
    descricao_problemas TEXT, -- usado no service
    frequencia_problemas VARCHAR(50), -- v-model="dadosDFD.frequencia_problemas"
    impacto_problemas TEXT, -- v-model="dadosDFD.impacto_problemas"
    
    -- === DADOS QUANTITATIVOS ===
    quantidade_adquirida INTEGER, -- v-model.number="dadosDFD.quantidade_adquirida"
    quantidade_problemas INTEGER,
    quantidade_estimada TEXT, -- usado no service
    prejuizo_estimado DECIMAL(15,2),
    
    -- === ANÁLISES E PARECERES ===
    parecer_tecnico TEXT, -- v-model="dadosDFD.parecer_tecnico"
    alternativas_avaliadas TEXT, -- v-model="dadosDFD.alternativas_avaliadas"
    rdms_negativos TEXT,
    
    -- === CAMPOS GERAIS ===
    base_legal TEXT, -- v-model="dadosDFD.base_legal"
    fundamentacao_juridica TEXT,
    lei_aplicavel TEXT,
    artigo_lei TEXT,
    decreto_regulamentador TEXT,
    resolucao_aplicavel TEXT,
    
    -- === CAMPOS ADMINISTRATIVOS ===
    motivacao TEXT,
    necessidade_administrativa TEXT,
    interesse_publico TEXT,
    economicidade TEXT,
    
    -- === IMPACTOS E RISCOS ===
    impacto_esperado TEXT, -- v-model="dadosDFD.impacto_esperado"
    riscos_identificados TEXT, -- v-model="dadosDFD.riscos_identificados"
    medidas_mitigadoras TEXT, -- v-model="dadosDFD.medidas_mitigadoras"
    
    -- === PRAZOS E REVISÕES ===
    prazo_entrega TEXT,
    local_entrega TEXT,
    prazo_vigencia INTEGER, -- em meses
    periodicidade_revisao VARCHAR(50), -- v-model="dadosDFD.periodicidade_revisao"
    
    -- === FONTES DE RECLAMAÇÕES ===
    fonte_reclamacoes TEXT,
    
    -- === OBSERVAÇÕES ===
    observacoes_especiais TEXT, -- v-model="dadosDFD.observacoes_especiais"
    observacoes TEXT,
    observacoes_internas TEXT,
    observacoes_juridicas TEXT,
    observacoes_tecnicas TEXT,
    
    -- === CAMPOS DE SISTEMA ===
    anexos JSONB,
    conteudo JSONB,
    dados JSONB,
    content TEXT,
    body TEXT,
    metadata JSONB,
    status VARCHAR(50) DEFAULT 'rascunho',
    fase_processo VARCHAR(50) DEFAULT 'elaboracao',
    tags TEXT[],
    categoria VARCHAR(100),
    prioridade VARCHAR(20) DEFAULT 'normal',
    confidencial BOOLEAN DEFAULT FALSE,
    
    -- === CAMPOS DE AUDITORIA ===
    criado_por UUID, -- usado no service
    usuario_id UUID,
    user_id UUID,
    created_by UUID,
    updated_by UUID,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- === CAMPOS DE NUMERAÇÃO ===
    folha_numero VARCHAR(20), -- usado no service
    numero_folha VARCHAR(20),
    numero_sequencial INTEGER,
    sequencial INTEGER,
    versao INTEGER DEFAULT 1,
    
    -- === CAMPOS DIVERSOS ===
    protocolo VARCHAR(50),
    numero_sei VARCHAR(50),
    orgao_origem TEXT,
    modalidade_licitacao VARCHAR(50),
    valor_estimado DECIMAL(15,2),
    resultado_avaliacao TEXT,
    parecer_final TEXT,
    decisao_final TEXT,
    
    -- === CAMPOS DE DATA ADICCIONAIS ===
    data_inicio DATE,
    data_prazo DATE,
    data_finalizacao TIMESTAMP WITH TIME ZONE,
    data_aprovacao TIMESTAMP WITH TIME ZONE,
    data_revisao TIMESTAMP WITH TIME ZONE,
    
    -- === RELACIONAMENTOS EXTRAS ===
    documento_uuid UUID,
    doc_id UUID,
    ref_documento UUID,
    parent_id UUID,
    processo_pai UUID,
    documento_pai UUID,
    dfd_pai UUID
);

-- ================================================================
-- 3. TABELA DE DOCUMENTOS DO PROCESSO
-- ================================================================

DROP TABLE IF EXISTS documentos_processo CASCADE;

CREATE TABLE documentos_processo (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- === INFORMAÇÕES DO DOCUMENTO ===
    tipo_documento VARCHAR(50) NOT NULL, -- 'folha_rosto', 'dfd', 'edital', 'ata', 'dcb', etc.
    nome_documento TEXT,
    titulo TEXT NOT NULL,
    descricao TEXT,
    
    -- === CONTEÚDO ===
    conteudo JSONB,
    conteudo_html TEXT,
    content TEXT,
    body TEXT,
    
    -- === NUMERAÇÃO ===
    numero_folha INTEGER NOT NULL,
    folha_numero VARCHAR(20), -- "Fl. 001", "Fl. 002", etc.
    numero_sequencial INTEGER, -- usado pelo NumeracaoDocumentosService
    
    -- === ASSINATURA ===
    assinado BOOLEAN DEFAULT FALSE,
    data_assinatura TIMESTAMP WITH TIME ZONE,
    assinado_por UUID,
    cargo_assinante TEXT,
    
    -- === CAMPOS DE AUDITORIA ===
    criado_por UUID,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- === CAMPOS EXTRAS ===
    numero_dcb VARCHAR(50), -- para documentos DCB
    data_autuacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- 4. TABELA DE PRODUTOS EM PRÉ-QUALIFICAÇÃO
-- ================================================================

DROP TABLE IF EXISTS produtos_prequalificacao CASCADE;

CREATE TABLE produtos_prequalificacao (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- === INFORMAÇÕES DO PRODUTO ===
    nome_produto TEXT NOT NULL, -- usado no AssistenteProcesso
    marca TEXT, -- usado no AssistenteProcesso
    modelo TEXT, -- usado no AssistenteProcesso
    fabricante TEXT, -- usado no service
    categoria_produto VARCHAR(100), -- usado no AssistenteProcesso
    
    -- === ESPECIFICAÇÕES ===
    especificacoes_tecnicas TEXT, -- usado no AssistenteProcesso
    
    -- === QUANTIDADES E VALORES ===
    quantidade_amostras INTEGER, -- usado no AssistenteProcesso
    valor_estimado DECIMAL(15,2), -- usado no AssistenteProcesso
    
    -- === CAMPOS EXTRAS ===
    categoria TEXT,
    subcategoria TEXT,
    status VARCHAR(50) DEFAULT 'pendente',
    observacoes TEXT,
    
    -- === CAMPOS DE AUDITORIA ===
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- 5. TABELA DE ASSINATURAS DO PROCESSO
-- ================================================================

DROP TABLE IF EXISTS assinaturas_processo CASCADE;

CREATE TABLE assinaturas_processo (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    documento_id UUID NOT NULL,
    usuario_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- === DADOS DA ASSINATURA ===
    nome_completo TEXT NOT NULL,
    cargo TEXT NOT NULL,
    tipo_assinatura VARCHAR(20) DEFAULT 'eletronica',
    hash_documento TEXT,
    ip_assinatura INET,
    observacoes TEXT,
    
    -- === CAMPOS DE AUDITORIA ===
    data_assinatura TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- 6. TABELA DE TRAMITAÇÃO DO PROCESSO
-- ================================================================

DROP TABLE IF EXISTS tramitacao_processo CASCADE;

CREATE TABLE tramitacao_processo (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- === DADOS DA TRAMITAÇÃO ===
    status_anterior VARCHAR(50),
    status_novo VARCHAR(50) NOT NULL,
    responsavel UUID,
    perfil_responsavel VARCHAR(50), -- 'cpm', 'ccl', 'orgao_administrativo', 'assessoria_juridica'
    observacoes TEXT,
    
    -- === CAMPOS DE AUDITORIA ===
    data_tramitacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- 7. TABELA DE RECURSOS ADMINISTRATIVOS
-- ================================================================

DROP TABLE IF EXISTS recursos_processo CASCADE;

CREATE TABLE recursos_processo (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- === DADOS DO RECURSO ===
    tipo_recurso VARCHAR(50), -- 'recurso_administrativo', 'pedido_reconsideracao', etc.
    requerente TEXT,
    motivo TEXT,
    fundamentacao TEXT,
    decisao TEXT,
    status VARCHAR(50) DEFAULT 'pendente',
    
    -- === CAMPOS DE AUDITORIA ===
    data_interposicao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_decisao TIMESTAMP WITH TIME ZONE,
    decidido_por UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- 8. TABELA DE DCB EMITIDAS
-- ================================================================

DROP TABLE IF EXISTS dcb_emitidas CASCADE;

CREATE TABLE dcb_emitidas (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    processo_id UUID NOT NULL,
    documento_id UUID,
    tenant_id UUID NOT NULL,
    
    -- === DADOS DA DCB ===
    numero_dcb VARCHAR(50) NOT NULL,
    produtos_incluidos INTEGER DEFAULT 0,
    data_emissao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_validade DATE,
    
    -- === CAMPOS DE AUDITORIA ===
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- ÍNDICES PARA PERFORMANCE
-- ================================================================

-- Processos Administrativos
CREATE INDEX IF NOT EXISTS idx_processos_tenant_id ON processos_administrativos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_processos_status ON processos_administrativos(status);
CREATE INDEX IF NOT EXISTS idx_processos_tipo ON processos_administrativos(tipo_processo);
CREATE INDEX IF NOT EXISTS idx_processos_data_autuacao ON processos_administrativos(data_autuacao);

-- DFD Processo
CREATE INDEX IF NOT EXISTS idx_dfd_processo_processo_id ON dfd_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_dfd_processo_tenant_id ON dfd_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dfd_documento_id ON dfd_processo(documento_id);

-- Documentos Processo
CREATE INDEX IF NOT EXISTS idx_documentos_processo_id ON documentos_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_documentos_tenant_id ON documentos_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documentos_numero_folha ON documentos_processo(numero_folha);

-- Produtos Pré-qualificação
CREATE INDEX IF NOT EXISTS idx_produtos_processo_id ON produtos_prequalificacao(processo_id);
CREATE INDEX IF NOT EXISTS idx_produtos_tenant_id ON produtos_prequalificacao(tenant_id);

-- Tramitação
CREATE INDEX IF NOT EXISTS idx_tramitacao_processo_id ON tramitacao_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_tramitacao_data ON tramitacao_processo(data_tramitacao);

-- Recursos
CREATE INDEX IF NOT EXISTS idx_recursos_processo_id ON recursos_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_recursos_status ON recursos_processo(status);

-- DCB
CREATE INDEX IF NOT EXISTS idx_dcb_processo_id ON dcb_emitidas(processo_id);
CREATE INDEX IF NOT EXISTS idx_dcb_numero ON dcb_emitidas(numero_dcb);

-- ================================================================
-- VIEWS PARA FACILITAR CONSULTAS
-- ================================================================

-- View de resumo de processos
CREATE OR REPLACE VIEW vw_processos_resumo AS
SELECT 
    p.id,
    p.tenant_id,
    p.numero_processo,
    p.tipo_processo,
    p.status,
    p.objeto,
    p.nome_orgao,
    p.unidade_interessada,
    p.observacoes,
    p.data_autuacao,
    p.data_finalizacao,
    p.criado_em,
    p.atualizado_em,
    COUNT(DISTINCT d.id) as total_documentos,
    COUNT(DISTINCT pr.id) as total_produtos
FROM processos_administrativos p
LEFT JOIN documentos_processo d ON p.id = d.processo_id
LEFT JOIN produtos_prequalificacao pr ON p.id = pr.processo_id
GROUP BY p.id, p.tenant_id, p.numero_processo, p.tipo_processo, p.status, p.objeto, 
         p.nome_orgao, p.unidade_interessada, p.observacoes, p.data_autuacao, 
         p.data_finalizacao, p.criado_em, p.atualizado_em;

-- View de documentos completos
CREATE OR REPLACE VIEW vw_documentos_completos AS
SELECT 
    d.*,
    p.numero_processo,
    p.tipo_processo,
    u.nome as criado_por_nome
FROM documentos_processo d
JOIN processos_administrativos p ON d.processo_id = p.id
LEFT JOIN usuarios u ON d.criado_por = u.id;

-- ================================================================
-- VERIFICAÇÃO FINAL
-- ================================================================

-- Verificar se todas as tabelas foram criadas
SELECT 
    'VERIFICAÇÃO FINAL' as titulo,
    schemaname,
    tablename,
    'CRIADA COM SUCESSO' as status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'processos_administrativos',
    'dfd_processo', 
    'documentos_processo',
    'produtos_prequalificacao',
    'assinaturas_processo',
    'tramitacao_processo',
    'recursos_processo',
    'dcb_emitidas'
)
ORDER BY tablename;

-- Verificar campos críticos no DFD
SELECT 
    'CAMPOS CRÍTICOS DFD' as titulo,
    column_name,
    data_type,
    'EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
AND column_name IN (
    'fonte_outros', 'alternativas_avaliadas', 'base_legal', 
    'documento_id', 'justificativa', 'necessidade_descricao',
    'produtos_especificacao', 'modelo_usado'
)
ORDER BY column_name;

-- Contar total de colunas criadas
SELECT 
    table_name,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name IN (
    'processos_administrativos',
    'dfd_processo', 
    'documentos_processo',
    'produtos_prequalificacao',
    'assinaturas_processo',
    'tramitacao_processo',
    'recursos_processo',
    'dcb_emitidas'
)
GROUP BY table_name
ORDER BY table_name;

SELECT 'ESTRUTURA COMPLETA DE PROCESSOS ADMINISTRATIVOS CRIADA COM SUCESSO!' as status;