-- =====================================================
-- CORRIGIR NUMERAÇÃO DE FOLHAS DOS DOCUMENTOS
-- =====================================================

-- 1. Verificar documentos sem número de folha
SELECT 'DOCUMENTOS SEM NUMERAÇÃO:' as status;
SELECT 
    dp.id, 
    dp.processo_id, 
    dp.nome_documento,
    dp.tipo_documento,
    dp.numero_folha,
    dp.data_autuacao
FROM documentos_processo dp
WHERE dp.numero_folha IS NULL
ORDER BY dp.processo_id, dp.data_autuacao;

-- 2. Atualizar numeração de folhas automaticamente
SELECT 'CORRIGINDO NUMERAÇÃO...' as status;

-- Para cada processo, numerar os documentos sequencialmente baseado na data de autuação
WITH documentos_numerados AS (
    SELECT 
        id,
        processo_id,
        ROW_NUMBER() OVER (
            PARTITION BY processo_id 
            ORDER BY 
                CASE 
                    WHEN tipo_documento = 'FOLHA_ROSTO' THEN 1
                    WHEN tipo_documento = 'DFD' THEN 2
                    ELSE 3
                END,
                data_autuacao,
                id
        ) as novo_numero_folha
    FROM documentos_processo
    WHERE numero_folha IS NULL
)
UPDATE documentos_processo 
SET numero_folha = dn.novo_numero_folha
FROM documentos_numerados dn
WHERE documentos_processo.id = dn.id;

-- 3. Verificar se ainda existem documentos sem numeração
SELECT 'VERIFICAÇÃO FINAL:' as status;
SELECT COUNT(*) as documentos_sem_numeracao 
FROM documentos_processo 
WHERE numero_folha IS NULL;

-- 4. Mostrar documentos por processo ordenados
SELECT 'DOCUMENTOS POR PROCESSO:' as status;
SELECT 
    dp.processo_id,
    pa.numero_processo,
    dp.numero_folha,
    dp.nome_documento || COALESCE(' - ' || dp.tipo_documento, '') as documento,
    dp.data_autuacao
FROM documentos_processo dp
LEFT JOIN processos_administrativos pa ON dp.processo_id = pa.id
ORDER BY dp.processo_id, dp.numero_folha;

SELECT 'NUMERAÇÃO DE FOLHAS CORRIGIDA! ✅' as resultado;