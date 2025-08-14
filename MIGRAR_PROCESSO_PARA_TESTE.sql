-- Script para migrar processo existente para testar homologação

-- 1. Ver processos atuais com status CCL
SELECT id, numero_processo, status, criado_em
FROM processos_administrativos 
WHERE status LIKE '%ccl%'
ORDER BY criado_em DESC;

-- 2. Mudar status para aparecer em "Atas CCL Aguardando Decisão da Autoridade"
UPDATE processos_administrativos 
SET status = 'julgado_ccl'
WHERE status = 'ata_julgamento_ccl_homologacao'
AND numero_processo = '001/2025'; -- Substitua pelo número do processo que quer testar

-- 3. Verificar se mudou
SELECT id, numero_processo, status, criado_em
FROM processos_administrativos 
WHERE numero_processo = '001/2025'; -- Substitua pelo número do processo

-- 4. Para voltar depois (se precisar)
-- UPDATE processos_administrativos 
-- SET status = 'ata_julgamento_ccl_homologacao'
-- WHERE numero_processo = '001/2025';