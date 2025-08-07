-- Criar ou corrigir tabela documentos_processo

-- 1. Verificar se a tabela existe e sua estrutura
SELECT 
    'ESTRUTURA DOCUMENTOS_PROCESSO' as titulo,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;

-- 2. Se a tabela não existir ou estiver incompleta, criar/recriar
CREATE TABLE IF NOT EXISTS documentos_processo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Relacionamentos
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- Numeração sequencial
    numero_sequencial INTEGER NOT NULL,
    folha_numero VARCHAR(20) NOT NULL, -- Ex: "Fl. 001", "Fl. 002"
    
    -- Informações do documento
    tipo_documento VARCHAR(50) NOT NULL, -- DFD, EDITAL, ATA, PARECER, ANEXO, etc.
    nome_documento TEXT NOT NULL,
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
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    data_remocao TIMESTAMP WITH TIME ZONE,
    
    -- Versionamento
    versao INTEGER DEFAULT 1,
    documento_pai UUID, -- Para controle de versões
    
    -- Observações
    observacoes TEXT
);

-- 3. Desabilitar RLS na tabela
ALTER TABLE documentos_processo DISABLE ROW LEVEL SECURITY;

-- 4. Adicionar colunas que podem estar faltando (se a tabela já existia)
DO $$
BEGIN
    -- Adicionar numero_sequencial se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'documentos_processo' AND column_name = 'numero_sequencial') THEN
        ALTER TABLE documentos_processo ADD COLUMN numero_sequencial INTEGER NOT NULL DEFAULT 1;
    END IF;
    
    -- Adicionar folha_numero se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'documentos_processo' AND column_name = 'folha_numero') THEN
        ALTER TABLE documentos_processo ADD COLUMN folha_numero VARCHAR(20) NOT NULL DEFAULT 'Fl. 001';
    END IF;
    
    -- Adicionar tipo_documento se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'documentos_processo' AND column_name = 'tipo_documento') THEN
        ALTER TABLE documentos_processo ADD COLUMN tipo_documento VARCHAR(50) NOT NULL DEFAULT 'FOLHA_ROSTO';
    END IF;
END $$;

-- 5. Criar função para obter próximo número sequencial
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

-- 6. Criar função para formatar número da folha
CREATE OR REPLACE FUNCTION formatar_folha_numero(numero INTEGER)
RETURNS VARCHAR(20) AS $$
BEGIN
    RETURN 'Fl. ' || LPAD(numero::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql;

-- 7. Verificar estrutura final
SELECT 
    'ESTRUTURA FINAL' as titulo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name IN ('numero_sequencial', 'folha_numero', 'tipo_documento', 'processo_id')
ORDER BY column_name;

-- 8. Teste
SELECT 'TABELA DOCUMENTOS_PROCESSO PRONTA!' as status;