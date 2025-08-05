-- RECRIAR TABELA DOCUMENTOS_PROCESSO COMPLETA

-- 1. VER ESTRUTURA ATUAL ANTES DE RECRIAR
SELECT 
    'ESTRUTURA ANTES' as titulo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;

-- 2. RECRIAR TABELA COMPLETAMENTE
DROP TABLE IF EXISTS documentos_processo CASCADE;

CREATE TABLE documentos_processo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Relacionamentos
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- Numeração sequencial
    numero_sequencial INTEGER NOT NULL,
    folha_numero VARCHAR(20) NOT NULL, -- Ex: "Fl. 001", "Fl. 002"
    
    -- Informações do documento
    tipo_documento VARCHAR(50) NOT NULL DEFAULT 'DOCUMENTO', -- DFD, EDITAL, ATA, PARECER, ANEXO, etc.
    nome_documento TEXT NOT NULL DEFAULT 'Documento',
    descricao TEXT,
    
    -- Conteúdo
    conteudo JSONB, -- Conteúdo estruturado do documento
    conteudo_html TEXT, -- Versão HTML para visualização
    arquivo_url TEXT, -- URL do arquivo (se uploadado)
    
    -- Metadados
    tamanho_arquivo BIGINT, -- Tamanho em bytes
    tipo_mime VARCHAR(100),
    hash_arquivo VARCHAR(64), -- Para verificar integridade
    
    -- Controle de estado
    status VARCHAR(20) DEFAULT 'ativo',
    
    -- Auditoria
    criado_por UUID,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_remocao TIMESTAMP WITH TIME ZONE,
    
    -- Versionamento
    versao INTEGER DEFAULT 1,
    documento_pai UUID, -- Para controle de versões
    
    -- Observações
    observacoes TEXT,
    
    -- Campos adicionais que podem ser necessários
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. DESABILITAR RLS
ALTER TABLE documentos_processo DISABLE ROW LEVEL SECURITY;

-- 4. CRIAR ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_documentos_processo_processo_id ON documentos_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_documentos_processo_tenant_id ON documentos_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documentos_processo_numero_seq ON documentos_processo(processo_id, numero_sequencial);

-- 5. CRIAR FUNÇÕES NECESSÁRIAS
CREATE OR REPLACE FUNCTION obter_proximo_numero_sequencial(processo_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    proximo_numero INTEGER;
BEGIN
    SELECT COALESCE(MAX(numero_sequencial), 0) + 1
    INTO proximo_numero
    FROM documentos_processo
    WHERE processo_id = processo_uuid AND status = 'ativo';
    
    RETURN proximo_numero;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION formatar_folha_numero(numero INTEGER)
RETURNS VARCHAR(20) AS $$
BEGIN
    RETURN 'Fl. ' || LPAD(numero::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql;

-- 6. VER ESTRUTURA FINAL
SELECT 
    'ESTRUTURA FINAL' as titulo,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;

-- 7. CONTAR COLUNAS
SELECT 
    'TOTAL DE COLUNAS' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'documentos_processo';

-- 8. TESTE FINAL
SELECT 'TABELA DOCUMENTOS_PROCESSO RECRIADA COMPLETAMENTE!' as status;