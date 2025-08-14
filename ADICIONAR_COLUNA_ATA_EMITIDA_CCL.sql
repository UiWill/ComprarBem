-- ==============================================
-- SCRIPT PARA ADICIONAR COLUNAS CCL FALTANTES
-- ==============================================
-- Este script adiciona todas as colunas CCL faltantes à tabela processos_administrativos

-- 1. Verificar quais colunas CCL já existem
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name LIKE '%ccl%'
ORDER BY column_name;

-- 2. Adicionar todas as colunas CCL se não existirem
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS ata_emitida_ccl_em TIMESTAMPTZ;

ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS ata_julgamento_ccl TEXT;

ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS recomendacao_ccl TEXT;

ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS fundamentacao_legal_ccl TEXT;

ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS consideracoes_adicionais_ccl TEXT;

ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS observacoes_ccl TEXT;

-- 3. Adicionar comentários para documentar as colunas
COMMENT ON COLUMN processos_administrativos.ata_emitida_ccl_em IS 'Data e hora em que a ata foi emitida pela CCL';
COMMENT ON COLUMN processos_administrativos.ata_julgamento_ccl IS 'Texto da ata de julgamento da CCL';
COMMENT ON COLUMN processos_administrativos.recomendacao_ccl IS 'Recomendação da CCL (aprovar/rejeitar/diligência)';
COMMENT ON COLUMN processos_administrativos.fundamentacao_legal_ccl IS 'Fundamentação legal da decisão da CCL';
COMMENT ON COLUMN processos_administrativos.consideracoes_adicionais_ccl IS 'Considerações adicionais da CCL';
COMMENT ON COLUMN processos_administrativos.observacoes_ccl IS 'Observações gerais da CCL';

-- 4. Verificar se todas as colunas foram criadas corretamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name LIKE '%ccl%'
ORDER BY column_name;

-- 5. Atualizar a constraint de status para incluir os novos status CCL
-- Primeiro, remover a constraint antiga
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- Criar nova constraint com todos os status necessários, incluindo os novos status CCL
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
    -- Status originais do fluxo de padronização
    'rascunho',
    'criado_cpm',
    'aguardando_aprovacao',
    'aguardando_assinatura_orgao',
    'assinado_admin',
    'julgamento_ccl',
    'aprovado_ccl',
    'aprovado_juridico',
    'edital_publicado',
    'homologado',
    'finalizado',
    
    -- Status de despadronização
    'criado_cpm_desp',
    'aguardando_assinatura_orgao_desp',
    'abertura_autorizada_desp',
    'aviso_publicado',
    'com_recurso_desp',
    'homologado_desp',
    'excluindo_marcas',
    
    -- Status de rejeição
    'rejeitado_cpm',
    'rejeitado_admin',
    'rejeitado_ccl',
    'rejeitado_juridico',
    'rejeitado_final',
    
    -- Status de devolução
    'devolvido_pelo_orgao',
    'devolvido_pela_ccl',
    'devolvido_pelo_juridico',
    
    -- NOVOS STATUS CCL DE JULGAMENTO
    'ata_julgamento_ccl_homologacao',
    'ata_julgamento_ccl_indeferimento',
    'ata_julgamento_ccl_aprovacao',
    'ata_julgamento_ccl_rejeicao',
    'diligencia_ccl',
    'tramitando_ccl',
    'julgado_ccl'
));

-- 6. Verificar se a constraint foi criada corretamente
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND conname = 'processos_administrativos_status_check';

-- 7. Habilitar RLS para as novas colunas (se necessário)
-- As colunas herdam automaticamente as políticas RLS da tabela

-- ✅ EXECUÇÃO CONCLUÍDA
-- Todas as colunas CCL e status foram adicionados à tabela processos_administrativos