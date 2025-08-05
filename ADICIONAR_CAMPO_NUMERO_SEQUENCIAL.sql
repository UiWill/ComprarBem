-- ADICIONAR CAMPO NUMERO_SEQUENCIAL À TABELA DOCUMENTOS_PROCESSO

-- Verificar se a coluna já existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'documentos_processo' 
        AND column_name = 'numero_sequencial'
    ) THEN
        ALTER TABLE documentos_processo ADD COLUMN numero_sequencial INTEGER;
        RAISE NOTICE 'Campo numero_sequencial adicionado com sucesso!';
    ELSE
        RAISE NOTICE 'Campo numero_sequencial já existe!';
    END IF;
END $$;

-- Verificar se foi adicionado
SELECT 
    'VERIFICAÇÃO CAMPO NUMERO_SEQUENCIAL' as titulo,
    column_name,
    data_type,
    'EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name = 'numero_sequencial';

SELECT 'CAMPO NUMERO_SEQUENCIAL ADICIONADO À TABELA DOCUMENTOS_PROCESSO!' as status;