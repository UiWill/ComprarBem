-- ADICIONAR TODOS OS CAMPOS FALTANTES À TABELA DOCUMENTOS_PROCESSO

-- Adicionar data_criacao
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'data_criacao'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Campo data_criacao adicionado!';
    END IF;
END $$;

-- Adicionar numero_sequencial (caso não tenha sido adicionado ainda)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'numero_sequencial'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN numero_sequencial INTEGER;
        RAISE NOTICE 'Campo numero_sequencial adicionado!';
    END IF;
END $$;

-- Adicionar nome_documento (usado no service)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'nome_documento'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN nome_documento TEXT;
        RAISE NOTICE 'Campo nome_documento adicionado!';
    END IF;
END $$;

-- Adicionar user_id (para compatibilidade)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN user_id UUID;
        RAISE NOTICE 'Campo user_id adicionado!';
    END IF;
END $$;

-- Adicionar documento_id (para relacionamentos)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'documento_id'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN documento_id UUID;
        RAISE NOTICE 'Campo documento_id adicionado!';
    END IF;
END $$;

-- Adicionar status (para controle de estado)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'status'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN status VARCHAR(50) DEFAULT 'ativo';
        RAISE NOTICE 'Campo status adicionado!';
    END IF;
END $$;

-- Adicionar versao (para controle de versões)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'versao'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN versao INTEGER DEFAULT 1;
        RAISE NOTICE 'Campo versao adicionado!';
    END IF;
END $$;

-- Adicionar metadata (para dados adicionais)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' AND column_name = 'metadata'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN metadata JSONB;
        RAISE NOTICE 'Campo metadata adicionado!';
    END IF;
END $$;

-- Verificar todos os campos críticos
SELECT 
    'CAMPOS CRÍTICOS DOCUMENTOS_PROCESSO' as titulo,
    column_name,
    data_type,
    'EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name IN (
    'data_criacao', 'numero_sequencial', 'nome_documento', 
    'user_id', 'documento_id', 'status', 'versao', 'metadata'
)
ORDER BY column_name;

-- Contar total de colunas
SELECT 
    'TOTAL DE COLUNAS DOCUMENTOS_PROCESSO' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'documentos_processo';

SELECT 'TODOS OS CAMPOS FALTANTES ADICIONADOS À DOCUMENTOS_PROCESSO!' as status;