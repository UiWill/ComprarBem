-- Verificar os dados completos do processo julgado
SELECT 
    id,
    numero_processo,
    status,
    ata_emitida_ccl_em,
    ata_julgamento_ccl,
    recomendacao_ccl,
    fundamentacao_legal_ccl,
    consideracoes_adicionais_ccl,
    observacoes_ccl
FROM processos_administrativos 
WHERE id = '68fb9d36-ee6e-437e-98b6-4489a6b469f1';