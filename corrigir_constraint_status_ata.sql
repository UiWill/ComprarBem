-- Verificar constraint atual do status_ata
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'atas_julgamento'::regclass
AND conname LIKE '%status%';

-- Remover constraint existente
ALTER TABLE atas_julgamento DROP CONSTRAINT IF EXISTS status_ata_valido;
ALTER TABLE atas_julgamento DROP CONSTRAINT IF EXISTS atas_julgamento_status_ata_check;

-- Recriar constraint com valores corretos
ALTER TABLE atas_julgamento 
ADD CONSTRAINT status_ata_valido 
CHECK (status_ata IN ('EM PRAZO', 'ELABORACAO', 'PUBLICADA', 'HOMOLOGADA', 'CANCELADA', 'VENCIDA'));

-- Verificar se foi aplicado
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'atas_julgamento'::regclass
AND conname LIKE '%status%';