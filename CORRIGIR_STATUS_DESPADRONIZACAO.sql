-- ==============================================
-- SCRIPT PARA CORRIGIR STATUS DE DESPADRONIZAÇÃO
-- ==============================================
-- Este script corrige processos de despadronização com status incorreto

-- 1. Verificar processos de despadronização com status incorreto
SELECT 
    id,
    numero_processo,
    status,
    tipo_processo,
    nome_orgao,
    criado_em
FROM processos_administrativos 
WHERE tipo_processo = 'despadronizacao' 
AND status = 'aguardando_aprovacao';

-- 2. Corrigir status de processos de despadronização
UPDATE processos_administrativos 
SET 
    status = 'criado_cpm_desp',
    data_ultima_tramitacao = NOW()
WHERE tipo_processo = 'despadronizacao' 
AND status = 'aguardando_aprovacao';

-- 3. Verificar se a correção foi aplicada
SELECT 
    'Processos de despadronização corrigidos' as resultado,
    COUNT(*) as quantidade_corrigida
FROM processos_administrativos 
WHERE tipo_processo = 'despadronizacao' 
AND status = 'criado_cpm_desp'
AND data_ultima_tramitacao >= NOW() - INTERVAL '1 minute';

-- 4. Verificar se ainda há processos de despadronização com status incorreto
SELECT 
    'Processos de despadronização ainda com status incorreto' as verificacao,
    COUNT(*) as quantidade_pendente
FROM processos_administrativos 
WHERE tipo_processo = 'despadronizacao' 
AND status = 'aguardando_aprovacao';

-- ✅ EXECUÇÃO CONCLUÍDA
-- Processos de despadronização com status 'aguardando_aprovacao' foram corrigidos para 'criado_cpm_desp'