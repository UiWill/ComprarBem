-- ============================================
-- SCRIPT PARA CORRIGIR ATA CCL-001-teste (V2)
-- ============================================

-- 1. ATUALIZAR ATA PARA VINCULAR AO PROCESSO 002/2025
UPDATE atas_julgamento 
SET 
    processo_id = '88c296eb-f296-4176-9f2e-5b58cf184995',
    numero_processo = '002/2025',
    tipo_processo = 'padronizacao',
    orgao_responsavel = 'Comprar bem teste tramitação',
    objeto_processo = 'CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS',
    decisao_ccl = 'APROVADO',
    fundamentacao_ccl = 'Processo aprovado tecnicamente pela CCL. A análise técnica considerou todos os aspectos normativos e de conformidade, concluindo pela adequação do processo aos requisitos estabelecidos.',
    atualizado_em = NOW()
WHERE numero = 'ATA-CCL-001-teste';

-- 2. VINCULAR PRODUTO À ATA (SEM ADEQUACAO_TECNICA problemática)
UPDATE produtos 
SET 
    ata_julgamento_id = 'f950e299-1dfe-41f4-9ad2-4e67f5a20a05',
    status = 'aprovado',
    julgado_em = NOW(),
    observacoes_ccl = 'Produto aprovado tecnicamente pela CCL',
    ccl_status = 'aprovado',
    ccl_data_julgamento = NOW(),
    ccl_numero_ata = 'ATA-CCL-001-teste'
WHERE id = '72f49bb1-787e-4abe-babe-2df8b9efbd06';

-- 3. VERIFICAR CORREÇÕES
SELECT 'ATA CORRIGIDA:' as info;
SELECT id, numero, processo_id, numero_processo, decisao_ccl
FROM atas_julgamento 
WHERE numero = 'ATA-CCL-001-teste';

SELECT 'PRODUTO VINCULADO:' as info;
SELECT id, nome, marca, modelo, status, ata_julgamento_id
FROM produtos 
WHERE ata_julgamento_id = 'f950e299-1dfe-41f4-9ad2-4e67f5a20a05';