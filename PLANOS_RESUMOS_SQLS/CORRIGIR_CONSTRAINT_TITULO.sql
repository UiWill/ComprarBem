-- CORRIGIR CONSTRAINT NOT NULL DO CAMPO TITULO EM DOCUMENTOS_PROCESSO

-- Remove a constraint NOT NULL do campo titulo
ALTER TABLE documentos_processo ALTER COLUMN titulo DROP NOT NULL;

-- Verificar se a constraint foi removida
SELECT 
    'CONSTRAINT TITULO CORRIGIDA' as titulo,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN is_nullable = 'YES' THEN 'PODE SER NULL - OK!'
        ELSE 'AINDA NOT NULL - ERRO!'
    END as status
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name = 'titulo';

-- Também vamos deixar o campo nome_documento como nullable se necessário
ALTER TABLE documentos_processo ALTER COLUMN nome_documento DROP NOT NULL;

-- Verificar nome_documento também
SELECT 
    'CONSTRAINT NOME_DOCUMENTO CORRIGIDA' as titulo,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN is_nullable = 'YES' THEN 'PODE SER NULL - OK!'
        ELSE 'AINDA NOT NULL - ERRO!'
    END as status
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name = 'nome_documento';

SELECT 'CONSTRAINTS NOT NULL REMOVIDAS DOS CAMPOS TITULO E NOME_DOCUMENTO!' as status;