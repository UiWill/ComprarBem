-- Script para testar o fluxo correto da CCL

-- 1. Ver processos atuais
SELECT id, numero_processo, status, criado_em
FROM processos_administrativos 
WHERE status IN ('julgado_ccl', 'julgamento_ccl', 'assinado_admin')
ORDER BY criado_em DESC;

-- 2. Mudar status para "julgamento_ccl" (aguardando julgamento da CCL)
UPDATE processos_administrativos 
SET status = 'julgamento_ccl'
WHERE numero_processo = '003/2025';  -- Substitua pelo número do processo que quer testar

-- 3. Verificar se mudou
SELECT id, numero_processo, status, objeto
FROM processos_administrativos 
WHERE numero_processo = '003/2025';

-- FLUXO ESPERADO AGORA:
-- 1. Processo com status "julgamento_ccl" aparece para CCL julgar
-- 2. CCL julga → TramitacaoProcessosService muda para "aprovado_ccl" 
-- 3. Processo vai automaticamente para Assessoria Jurídica
-- 4. Jurídico analisa → muda para "aprovado_juridico"
-- 5. Edital publicado → "edital_publicado"  
-- 6. Homologação final → "homologado"