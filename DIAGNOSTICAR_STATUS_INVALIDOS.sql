-- Diagnosticar status inválidos antes de aplicar a nova constraint

-- 1. Ver todos os status únicos que existem atualmente
SELECT DISTINCT status, COUNT(*) as quantidade
FROM processos_administrativos 
GROUP BY status
ORDER BY quantidade DESC;

-- 2. Identificar quais status NÃO estão na nova lista permitida
SELECT DISTINCT status, COUNT(*) as quantidade
FROM processos_administrativos 
WHERE status NOT IN (
    'rascunho', 
    'submetido', 
    'em_analise', 
    'pendente_correcao', 
    'aprovado', 
    'rejeitado',
    'tramitando_ccl',
    'julgado_ccl',
    'ata_julgamento_ccl_homologacao',
    'ata_julgamento_ccl_indeferimento', 
    'ata_julgamento_ccl_aprovacao',
    'ata_julgamento_ccl_rejeicao',
    'diligencia_ccl',
    'homologado_autoridade',
    'indeferido_autoridade',
    'diligencia_autoridade'
)
GROUP BY status
ORDER BY quantidade DESC;

-- 3. Ver alguns exemplos dos registros com status inválidos
SELECT id, numero_processo, status, criado_em
FROM processos_administrativos 
WHERE status NOT IN (
    'rascunho', 
    'submetido', 
    'em_analise', 
    'pendente_correcao', 
    'aprovado', 
    'rejeitado',
    'tramitando_ccl',
    'julgado_ccl',
    'ata_julgamento_ccl_homologacao',
    'ata_julgamento_ccl_indeferimento', 
    'ata_julgamento_ccl_aprovacao',
    'ata_julgamento_ccl_rejeicao',
    'diligencia_ccl',
    'homologado_autoridade',
    'indeferido_autoridade',
    'diligencia_autoridade'
)
ORDER BY criado_em DESC
LIMIT 10;