-- Adicionar colunas para decisões da Autoridade Competente
-- Este script adiciona as colunas necessárias para o novo fluxo de homologação

-- 1. Adicionar colunas de decisão da autoridade
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS decisao_autoridade VARCHAR(50),
ADD COLUMN IF NOT EXISTS fundamentacao_autoridade TEXT,
ADD COLUMN IF NOT EXISTS data_decisao_autoridade TIMESTAMP WITH TIME ZONE;

-- 2. Atualizar a constraint de status para incluir os novos status de autoridade
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
    'rascunho', 
    'submetido', 
    'em_analise', 
    'pendente_correcao', 
    'aprovado', 
    'rejeitado',
    'tramitando_ccl',
    'julgado_ccl',
    'ata_julgamento_ccl_homologacao',
    'ata_julgamento_ccl_indeferimento', 
    'ata_julgamento_ccl_aprovacao',
    'ata_julgamento_ccl_rejeicao',
    'diligencia_ccl',
    'homologado_autoridade',
    'indeferido_autoridade',
    'diligencia_autoridade'
));

-- 3. Verificar se as colunas foram criadas corretamente
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name IN ('decisao_autoridade', 'fundamentacao_autoridade', 'data_decisao_autoridade')
ORDER BY column_name;

-- 4. Comentários nas colunas para documentação
COMMENT ON COLUMN processos_administrativos.decisao_autoridade IS 'Decisão da Autoridade Competente sobre a recomendação da CCL (homologar, indeferir, diligencia)';
COMMENT ON COLUMN processos_administrativos.fundamentacao_autoridade IS 'Fundamentação jurídica da decisão da Autoridade Competente';
COMMENT ON COLUMN processos_administrativos.data_decisao_autoridade IS 'Data e hora da decisão da Autoridade Competente';