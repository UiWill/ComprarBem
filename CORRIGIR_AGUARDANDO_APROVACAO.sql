-- ==============================================
-- SCRIPT PARA CORRIGIR STATUS AGUARDANDO_APROVACAO
-- ==============================================
-- Este script atualiza processos com status 'aguardando_aprovacao' para 'criado_cpm'

-- 1. Verificar se existem processos com status 'aguardando_aprovacao'
SELECT 
    id,
    numero_processo,
    status,
    tipo_processo,
    nome_orgao,
    criado_em
FROM processos_administrativos 
WHERE status = 'aguardando_aprovacao';

-- 2. Atualizar processos de 'aguardando_aprovacao' para 'criado_cpm'
UPDATE processos_administrativos 
SET 
    status = 'criado_cpm',
    data_ultima_tramitacao = NOW()
WHERE status = 'aguardando_aprovacao';

-- 3. Verificar se a atualização foi feita corretamente
SELECT 
    'Processos atualizados de aguardando_aprovacao para criado_cpm' as resultado,
    COUNT(*) as quantidade_atualizada
FROM processos_administrativos 
WHERE status = 'criado_cpm' 
AND data_ultima_tramitacao >= NOW() - INTERVAL '1 minute';

-- ✅ EXECUÇÃO CONCLUÍDA
-- Processos com status 'aguardando_aprovacao' foram atualizados para 'criado_cpm'