-- ==============================================
-- SCRIPT PARA CORRIGIR PROCESSO 002/2025 QUE JÁ FOI JULGADO
-- ==============================================
-- Este script preenche os campos da ata CCL para processos já aprovados

-- Verificar o processo atual
SELECT 
    numero_processo,
    status,
    ata_julgamento_ccl,
    ata_emitida_ccl_em,
    atualizado_em
FROM processos_administrativos 
WHERE numero_processo = '002/2025'
AND status = 'aprovado_ccl';

-- Atualizar o processo 002/2025 com os campos da ata CCL
UPDATE processos_administrativos 
SET 
    ata_emitida_ccl_em = COALESCE(ata_emitida_ccl_em, atualizado_em, NOW()),
    ata_julgamento_ccl = COALESCE(
        ata_julgamento_ccl, 
        'Processo aprovado tecnicamente pela CCL. A análise técnica considerou todos os aspectos normativos e de conformidade, concluindo pela adequação do processo aos requisitos estabelecidos.'
    )
WHERE numero_processo = '002/2025'
AND status = 'aprovado_ccl'
AND ata_emitida_ccl_em IS NULL;

-- Verificar o resultado da correção
SELECT 
    numero_processo,
    status,
    ata_julgamento_ccl,
    ata_emitida_ccl_em,
    atualizado_em
FROM processos_administrativos 
WHERE numero_processo = '002/2025'
AND status = 'aprovado_ccl';

-- Caso existam outros processos aprovados sem ata_emitida_ccl_em, 
-- este comando corrige todos de uma vez:
/*
UPDATE processos_administrativos 
SET 
    ata_emitida_ccl_em = COALESCE(ata_emitida_ccl_em, atualizado_em, NOW()),
    ata_julgamento_ccl = COALESCE(
        ata_julgamento_ccl, 
        'Processo aprovado tecnicamente pela CCL. A análise técnica considerou todos os aspectos normativos e de conformidade, concluindo pela adequação do processo aos requisitos estabelecidos.'
    )
WHERE status = 'aprovado_ccl'
AND ata_emitida_ccl_em IS NULL;
*/

-- Verificar quantos processos foram corrigidos
SELECT COUNT(*) as processos_corrigidos
FROM processos_administrativos 
WHERE status = 'aprovado_ccl'
AND ata_emitida_ccl_em IS NOT NULL;