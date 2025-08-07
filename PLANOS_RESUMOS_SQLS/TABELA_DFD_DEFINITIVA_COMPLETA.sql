-- TABELA DFD_PROCESSO DEFINITIVA COM TODOS OS CAMPOS DO CÓDIGO
-- Baseada na análise completa do FormularioDFD.vue

DROP TABLE IF EXISTS dfd_processo CASCADE;

CREATE TABLE dfd_processo (
    -- === IDs E RELACIONAMENTOS ===
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    documento_id UUID,
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- === INFORMAÇÕES BÁSICAS ===
    tipo_dfd VARCHAR(20) NOT NULL DEFAULT 'MODELO1',
    titulo TEXT NOT NULL DEFAULT 'DFD',
    
    -- === CAMPOS OBRIGATÓRIOS BÁSICOS ===
    justificativa TEXT, -- v-model="dadosDFD.justificativa"
    necessidade_descricao TEXT, -- v-model="dadosDFD.necessidade_descricao"
    
    -- === CAMPOS MODELO 1 (PADRONIZAÇÃO) ===
    produtos_especificacao TEXT, -- v-model="dadosDFD.produtos_especificacao"
    especificacoes_tecnicas TEXT, -- v-model="dadosDFD.especificacoes_tecnicas"
    criterios_aceitacao TEXT, -- v-model="dadosDFD.criterios_aceitacao"
    ensaios_exigidos TEXT, -- v-model="dadosDFD.ensaios_exigidos"
    local_entrega_amostras TEXT, -- v-model="dadosDFD.local_entrega_amostras"
    prazo_entrega_amostras TEXT, -- v-model="dadosDFD.prazo_entrega_amostras"
    
    -- === CAMPOS MODELO 2 (DESPADRONIZAÇÃO) ===
    produtos_despadronizar TEXT, -- v-model="dadosDFD.produtos_despadronizar"
    
    -- FONTES DE INFORMAÇÃO (checkboxes)
    fonte_rdm BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_rdm"
    fonte_reclamacoes_usuarios BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_reclamacoes_usuarios"
    fonte_sistema_comprar_bem BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_sistema_comprar_bem"
    fonte_analise_tecnica BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_analise_tecnica"
    fonte_outros BOOLEAN DEFAULT FALSE, -- v-model="dadosDFD.fonte_outros" ← ESTA ESTAVA FALTANDO!
    outras_fontes TEXT, -- v-model="dadosDFD.outras_fontes"
    
    -- PROBLEMAS E MOTIVAÇÕES
    problemas_identificados TEXT, -- v-model="dadosDFD.problemas_identificados"
    frequencia_problemas VARCHAR(50), -- v-model="dadosDFD.frequencia_problemas"
    impacto_problemas TEXT, -- v-model="dadosDFD.impacto_problemas"
    
    -- DADOS QUANTITATIVOS
    quantidade_adquirida INTEGER, -- v-model.number="dadosDFD.quantidade_adquirida"
    quantidade_problemas INTEGER,
    prejuizo_estimado DECIMAL(15,2),
    
    -- ANÁLISES E PARECERES
    parecer_tecnico TEXT, -- v-model="dadosDFD.parecer_tecnico"
    alternativas_avaliadas TEXT, -- v-model="dadosDFD.alternativas_avaliadas"
    
    -- === CAMPOS GERAIS ===
    base_legal TEXT, -- v-model="dadosDFD.base_legal"
    impacto_esperado TEXT, -- v-model="dadosDFD.impacto_esperado"
    riscos_identificados TEXT, -- v-model="dadosDFD.riscos_identificados"
    medidas_mitigadoras TEXT, -- v-model="dadosDFD.medidas_mitigadoras"
    periodicidade_revisao VARCHAR(50), -- v-model="dadosDFD.periodicidade_revisao"
    observacoes_especiais TEXT, -- v-model="dadosDFD.observacoes_especiais"
    
    -- === CAMPOS ADICIONAIS DE SISTEMA ===
    observacoes TEXT,
    anexos JSONB,
    status VARCHAR(50) DEFAULT 'rascunho',
    
    -- === CAMPOS DE AUDITORIA ===
    criado_por UUID,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- === CAMPOS DE NUMERAÇÃO ===
    numero_sequencial INTEGER,
    folha_numero VARCHAR(20),
    versao INTEGER DEFAULT 1,
    
    -- === CAMPOS EXTRAS PARA EVITAR ERROS FUTUROS ===
    conteudo JSONB,
    metadata JSONB,
    documento_pai UUID,
    user_id UUID,
    updated_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DESABILITAR RLS
ALTER TABLE dfd_processo DISABLE ROW LEVEL SECURITY;

-- CRIAR ÍNDICES
CREATE INDEX IF NOT EXISTS idx_dfd_processo_processo_id ON dfd_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_dfd_processo_tenant_id ON dfd_processo(tenant_id);

-- VERIFICAR CAMPOS CRÍTICOS
SELECT 
    'CAMPOS CRÍTICOS VERIFICADOS' as titulo,
    column_name,
    'EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
AND column_name IN (
    'fonte_outros', 'outras_fontes', 'justificativa', 'necessidade_descricao',
    'produtos_especificacao', 'base_legal', 'alternativas_avaliadas', 'documento_id'
)
ORDER BY column_name;

-- CONTAR TOTAL
SELECT 
    'TABELA DFD COMPLETA' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'dfd_processo';

SELECT 'TABELA DFD_PROCESSO CRIADA COM TODOS OS CAMPOS DO FORMULÁRIO!' as status;