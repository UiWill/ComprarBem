-- =====================================================
-- LIMPAR DOCUMENTOS DUPLICADOS DO PROCESSO
-- =====================================================

-- 1. Ver documentos duplicados antes da limpeza
SELECT 
    processo_id,
    tipo_documento,
    nome_documento,
    COUNT(*) as quantidade,
    array_agg(id) as ids_duplicados
FROM documentos_processo 
GROUP BY processo_id, tipo_documento, nome_documento
HAVING COUNT(*) > 1
ORDER BY quantidade DESC;

-- 2. Remover duplicatas mantendo apenas o mais recente de cada tipo por processo
WITH documentos_ranqueados AS (
    SELECT 
        id,
        processo_id,
        tipo_documento,
        nome_documento,
        criado_em,
        ROW_NUMBER() OVER (
            PARTITION BY processo_id, tipo_documento 
            ORDER BY criado_em DESC
        ) as rn
    FROM documentos_processo
),
documentos_para_remover AS (
    SELECT id 
    FROM documentos_ranqueados 
    WHERE rn > 1
)
DELETE FROM documentos_processo 
WHERE id IN (SELECT id FROM documentos_para_remover);

-- 3. Ver resultado após limpeza
SELECT 
    processo_id,
    tipo_documento,
    nome_documento,
    COUNT(*) as quantidade_final
FROM documentos_processo 
GROUP BY processo_id, tipo_documento, nome_documento
ORDER BY processo_id, tipo_documento;

-- 4. Fazer o mesmo para a tabela dfd_processo
WITH dfd_ranqueados AS (
    SELECT 
        id,
        processo_id,
        criado_em,
        ROW_NUMBER() OVER (
            PARTITION BY processo_id 
            ORDER BY criado_em DESC
        ) as rn
    FROM dfd_processo
),
dfd_para_remover AS (
    SELECT id 
    FROM dfd_ranqueados 
    WHERE rn > 1
)
DELETE FROM dfd_processo 
WHERE id IN (SELECT id FROM dfd_para_remover);

SELECT 'Limpeza concluída! ✅' as status;