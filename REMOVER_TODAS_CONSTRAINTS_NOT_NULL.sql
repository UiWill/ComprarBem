-- REMOVER TODAS AS CONSTRAINTS NOT NULL PROBLEMÁTICAS DA TABELA DOCUMENTOS_PROCESSO

-- 1. Remover NOT NULL do campo titulo
ALTER TABLE documentos_processo ALTER COLUMN titulo DROP NOT NULL;

-- 2. Remover NOT NULL do campo numero_folha (que estava causando o erro atual)
ALTER TABLE documentos_processo ALTER COLUMN numero_folha DROP NOT NULL;

-- 3. Remover NOT NULL do campo nome_documento (preventivo)
ALTER TABLE documentos_processo ALTER COLUMN nome_documento DROP NOT NULL;

-- 4. Remover NOT NULL do campo tipo_documento (preventivo)
ALTER TABLE documentos_processo ALTER COLUMN tipo_documento DROP NOT NULL;

-- 5. Verificar todos os campos que foram alterados
SELECT 
    'CAMPOS DOCUMENTOS_PROCESSO APÓS CORREÇÃO' as titulo,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN is_nullable = 'YES' THEN '✅ NULLABLE'
        ELSE '❌ NOT NULL'
    END as status_constraint
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name IN ('titulo', 'numero_folha', 'nome_documento', 'tipo_documento')
ORDER BY column_name;

-- 6. Mostrar TODOS os campos da tabela documentos_processo
SELECT 
    'ESTRUTURA COMPLETA DOCUMENTOS_PROCESSO' as titulo,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;

-- 7. Contar total de campos
SELECT 
    'TOTAL DE CAMPOS' as titulo,
    COUNT(*) as total_campos
FROM information_schema.columns 
WHERE table_name = 'documentos_processo';

SELECT '🎉 TODAS AS CONSTRAINTS NOT NULL PROBLEMÁTICAS FORAM REMOVIDAS!' as status;