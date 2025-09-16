-- Debug dos documentos anexados ao processo 003 (CORRIGIDO)
-- Execute este script para ver todos os documentos anexados

-- 1. Buscar TODOS os documentos do processo 003
SELECT
    id,
    processo_id,
    nome_documento,
    tipo_documento,
    arquivo_url,
    created_at,
    updated_at
FROM documentos_processo
WHERE processo_id = (
    SELECT id FROM processos_administrativos
    WHERE numero_processo = '003'
    LIMIT 1
)
ORDER BY created_at DESC;

-- 2. Verificar tipos únicos de documentos
SELECT DISTINCT tipo_documento, COUNT(*) as quantidade
FROM documentos_processo
WHERE processo_id = (
    SELECT id FROM processos_administrativos
    WHERE numero_processo = '003'
    LIMIT 1
)
GROUP BY tipo_documento;

-- 3. Buscar documentos que devem aparecer no PDF
SELECT
    id,
    nome_documento,
    tipo_documento,
    arquivo_url,
    created_at
FROM documentos_processo
WHERE processo_id = (
    SELECT id FROM processos_administrativos
    WHERE numero_processo = '003'
    LIMIT 1
)
AND tipo_documento NOT IN ('DFD', 'dfd', 'FOLHA_ROSTO', 'folha_rosto', 'EDITAL', 'edital')
ORDER BY created_at DESC;