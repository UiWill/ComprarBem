-- Verificar se coluna ata_julgamento_id existe na tabela produtos
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos' 
AND column_name = 'ata_julgamento_id';

-- Verificar constraint do status_ata (atual vs esperado)
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'atas_julgamento'::regclass
AND conname LIKE '%status%';

-- Atualizar constraint do status_ata se necessário
ALTER TABLE atas_julgamento DROP CONSTRAINT IF EXISTS atas_julgamento_status_ata_check;
ALTER TABLE atas_julgamento 
ADD CONSTRAINT atas_julgamento_status_ata_check 
CHECK (status_ata IN ('ELABORACAO', 'EM PRAZO', 'PUBLICADA', 'HOMOLOGADA', 'CANCELADA'));

-- Verificar produtos julgados disponíveis para atas
SELECT 
    COUNT(*) as total_produtos_julgados,
    COUNT(CASE WHEN ata_julgamento_id IS NULL THEN 1 END) as produtos_sem_ata,
    COUNT(CASE WHEN ata_julgamento_id IS NOT NULL THEN 1 END) as produtos_com_ata
FROM produtos 
WHERE status IN ('julgado_aprovado', 'julgado_reprovado')
AND julgado_em IS NOT NULL;