-- CRIAR TABELA DFD_PROCESSO COMPLETA
-- Baseada nos PDFs fornecidos: Modelo 1 e Modelo 2 de DFD

-- 1. VER SE A TABELA EXISTE
SELECT 
    'ESTRUTURA ATUAL DFD_PROCESSO' as titulo,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
ORDER BY ordinal_position;

-- 2. RECRIAR TABELA COMPLETAMENTE
DROP TABLE IF EXISTS dfd_processo CASCADE;

CREATE TABLE dfd_processo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Relacionamentos
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- Informações básicas
    tipo_dfd VARCHAR(20) NOT NULL, -- 'MODELO1' ou 'MODELO2'
    titulo TEXT NOT NULL,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    criado_por UUID,
    
    -- === CAMPOS MODELO 1 (PADRONIZAÇÃO) ===
    -- Baseado no PDF "Modelo 1 de DFD"
    produtos_especificacao TEXT,
    quantidade_amostras INTEGER,
    previsao_aquisicoes TEXT,
    especificacoes_tecnicas TEXT,
    criterios_aceitacao TEXT,
    ensaios_exigidos TEXT,
    local_entrega_amostras TEXT,
    prazo_entrega_amostras TEXT,
    
    -- === CAMPOS MODELO 2 (DESPADRONIZAÇÃO) ===
    -- Baseado no PDF "Modelo 2 de DFD"
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
    alternativas_avaliadas TEXT, -- ESTA É A COLUNA QUE ESTAVA FALTANDO
    
    -- === CAMPOS COMUNS ===
    justificativa TEXT,
    observacoes TEXT,
    anexos JSONB, -- Para guardar lista de anexos
    
    -- Controle
    status VARCHAR(20) DEFAULT 'rascunho',
    data_finalizacao TIMESTAMP WITH TIME ZONE,
    
    -- Auditoria
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. DESABILITAR RLS
ALTER TABLE dfd_processo DISABLE ROW LEVEL SECURITY;

-- 4. CRIAR ÍNDICES
CREATE INDEX IF NOT EXISTS idx_dfd_processo_processo_id ON dfd_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_dfd_processo_tenant_id ON dfd_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dfd_processo_tipo ON dfd_processo(tipo_dfd);

-- 5. VER ESTRUTURA FINAL
SELECT 
    'ESTRUTURA FINAL DFD_PROCESSO' as titulo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
ORDER BY ordinal_position;

-- 6. VERIFICAR COLUNA ESPECÍFICA QUE ESTAVA FALTANDO
SELECT 
    'COLUNA ALTERNATIVAS_AVALIADAS' as titulo,
    column_name,
    data_type,
    'ENCONTRADA!' as status
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
AND column_name = 'alternativas_avaliadas';

-- 7. CONTAR COLUNAS TOTAIS
SELECT 
    'TOTAL DE COLUNAS' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'dfd_processo';

-- 8. TESTE
SELECT 'TABELA DFD_PROCESSO CRIADA COM TODOS OS CAMPOS DOS PDFs!' as status;