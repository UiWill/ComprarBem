-- ADICIONAR TODOS OS CAMPOS FALTANTES À TABELA PRODUTOS_PREQUALIFICACAO

-- Adicionar adequacao_tecnica
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'adequacao_tecnica'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN adequacao_tecnica TEXT;
        RAISE NOTICE 'Campo adequacao_tecnica adicionado!';
    END IF;
END $$;

-- Adicionar outros campos que podem ser necessários
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'observacoes_processo'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN observacoes_processo TEXT;
        RAISE NOTICE 'Campo observacoes_processo adicionado!';
    END IF;
END $$;

-- Adicionar subcategoria (usado no ProcessosAdministrativosService)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'subcategoria'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN subcategoria TEXT;
        RAISE NOTICE 'Campo subcategoria adicionado!';
    END IF;
END $$;

-- Adicionar categoria (backup para categoria_produto)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'categoria'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN categoria TEXT;
        RAISE NOTICE 'Campo categoria adicionado!';
    END IF;
END $$;

-- Adicionar especificacoes (backup para especificacoes_tecnicas)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'especificacoes'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN especificacoes TEXT;
        RAISE NOTICE 'Campo especificacoes adicionado!';
    END IF;
END $$;

-- Adicionar nome (backup para nome_produto)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'nome'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN nome TEXT;
        RAISE NOTICE 'Campo nome adicionado!';
    END IF;
END $$;

-- Adicionar produto_id (relacionamento com produtos originais)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'produto_id'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN produto_id UUID;
        RAISE NOTICE 'Campo produto_id adicionado!';
    END IF;
END $$;

-- Adicionar campos de auditoria extras
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'criado_por'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN criado_por UUID;
        RAISE NOTICE 'Campo criado_por adicionado!';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos_prequalificacao' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE produtos_prequalificacao ADD COLUMN user_id UUID;
        RAISE NOTICE 'Campo user_id adicionado!';
    END IF;
END $$;

-- Verificar todos os campos críticos
SELECT 
    'CAMPOS CRÍTICOS PRODUTOS_PREQUALIFICACAO' as titulo,
    column_name,
    data_type,
    'EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name IN (
    'adequacao_tecnica', 'observacoes_processo', 'subcategoria', 
    'categoria', 'especificacoes', 'nome', 'produto_id', 
    'criado_por', 'user_id'
)
ORDER BY column_name;

-- Contar total de colunas
SELECT 
    'TOTAL DE COLUNAS PRODUTOS_PREQUALIFICACAO' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao';

SELECT 'TODOS OS CAMPOS FALTANTES ADICIONADOS À PRODUTOS_PREQUALIFICACAO!' as status;