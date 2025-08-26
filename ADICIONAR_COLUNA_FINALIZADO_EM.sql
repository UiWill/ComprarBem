-- ============================================
-- ADICIONAR COLUNA finalizado_em NA TABELA processos_administrativos
-- ============================================

-- Esta coluna armazenará a data/hora quando o processo foi finalizado

-- Verificar se a coluna já existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'processos_administrativos' 
        AND column_name = 'finalizado_em'
    ) THEN
        -- Adicionar a coluna finalizado_em
        ALTER TABLE processos_administrativos 
        ADD COLUMN finalizado_em timestamptz NULL;
        
        RAISE NOTICE '✅ Coluna finalizado_em adicionada com sucesso na tabela processos_administrativos';
    ELSE
        RAISE NOTICE '⚠️ Coluna finalizado_em já existe na tabela processos_administrativos';
    END IF;
END $$;

-- Verificar o resultado
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name = 'finalizado_em';

-- Comentário explicativo sobre a coluna
COMMENT ON COLUMN processos_administrativos.finalizado_em IS 
'Data/hora em que o processo foi finalizado após inclusão das marcas no catálogo';

-- Mensagem final
DO $$
BEGIN
    RAISE NOTICE '🎉 Script executado com sucesso! A coluna finalizado_em está pronta para uso.';
END $$;