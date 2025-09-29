-- Verificar todos os constraints CHECK da tabela atas_julgamento
SELECT
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'atas_julgamento'
    AND tc.constraint_type = 'CHECK';

-- Ver colunas da tabela
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'atas_julgamento'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar valores únicos existentes na coluna status_ata
SELECT DISTINCT status_ata, COUNT(*) as quantidade
FROM atas_julgamento
GROUP BY status_ata
ORDER BY status_ata;