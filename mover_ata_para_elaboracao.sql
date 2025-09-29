-- Script para mover ata de "Publicadas" para "Em Elaboração"
-- Substitua 'NUMERO_DA_ATA' pelo número real da ata que você quer mover

-- Opção 1: Mover por número da ata
UPDATE atas_julgamento
SET status_ata = 'ELABORACAO'
WHERE numero = 'ATA-CCL-001-2025'  -- SUBSTITUA pelo número da sua ata
  AND tenant_id = 'seu_tenant_id';  -- SUBSTITUA pelo seu tenant_id

-- Opção 2: Mover por ID da ata (se souber o ID)
-- UPDATE atas_julgamento
-- SET status_ata = 'ELABORACAO'
-- WHERE id = 123  -- SUBSTITUA pelo ID da sua ata
--   AND tenant_id = 'seu_tenant_id';  -- SUBSTITUA pelo seu tenant_id

-- Para verificar as atas disponíveis e seus status:
-- SELECT id, numero, status_ata, data_publicacao
-- FROM atas_julgamento
-- WHERE tenant_id = 'seu_tenant_id'
-- ORDER BY id DESC;