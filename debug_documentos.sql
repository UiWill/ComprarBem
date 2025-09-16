-- Debug dos documentos anexados ao processo 003
-- Execute este script para ver todos os documentos anexados

-- 1. Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;

-- 2. Buscar TODOS os documentos do processo 003
SELECT
    id,
    processo_id,
    nome_documento,
    tipo_documento,
    url_documento,
    created_at,
    updated_at
FROM documentos_processo
WHERE processo_id = (
    SELECT id FROM processos_administrativos
    WHERE numero_processo = '003'
    LIMIT 1
)
ORDER BY created_at DESC;

-- 3. Verificar tipos únicos de documentos
SELECT DISTINCT tipo_documento, COUNT(*) as quantidade
FROM documentos_processo
WHERE processo_id = (
    SELECT id FROM processos_administrativos
    WHERE numero_processo = '003'
    LIMIT 1
)
GROUP BY tipo_documento;

-- 4. Buscar especificamente os tipos que estou procurando
SELECT *
FROM documentos_processo
WHERE processo_id = (
    SELECT id FROM processos_administrativos
    WHERE numero_processo = '003'
    LIMIT 1
)
AND tipo_documento IN ('DOCUMENTO_ADICIONAL', 'documento_adicional', 'ANEXO', 'anexo')
ORDER BY created_at DESC;