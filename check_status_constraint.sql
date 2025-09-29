-- Verificar constraint de status_ata da tabela atas_julgamento
SELECT
    conname as constraint_name,
    consrc as constraint_definition
FROM pg_constraint
WHERE conname = 'status_ata_valido';

-- Alternativa: verificar todos os constraints da tabela
SELECT
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'atas_julgamento'
    AND tc.constraint_type = 'CHECK';

-- Ver estrutura da tabela
\d atas_julgamento;