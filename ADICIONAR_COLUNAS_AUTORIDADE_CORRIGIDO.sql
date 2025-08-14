-- Script corrigido - Adicionar colunas para decisões da Autoridade Competente
-- Este script adiciona as colunas SEM quebrar constraint existente

-- PARTE 1: Adicionar apenas as novas colunas (isso deve funcionar)
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS decisao_autoridade VARCHAR(50),
ADD COLUMN IF NOT EXISTS fundamentacao_autoridade TEXT,
ADD COLUMN IF NOT EXISTS data_decisao_autoridade TIMESTAMP WITH TIME ZONE;

-- PARTE 2: Verificar se as colunas foram criadas
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name IN ('decisao_autoridade', 'fundamentacao_autoridade', 'data_decisao_autoridade')
ORDER BY column_name;

-- PARTE 3: Adicionar comentários
COMMENT ON COLUMN processos_administrativos.decisao_autoridade IS 'Decisão da Autoridade Competente sobre a recomendação da CCL (homologar, indeferir, diligencia)';
COMMENT ON COLUMN processos_administrativos.fundamentacao_autoridade IS 'Fundamentação jurídica da decisão da Autoridade Competente';
COMMENT ON COLUMN processos_administrativos.data_decisao_autoridade IS 'Data e hora da decisão da Autoridade Competente';

-- PARTE 4: Ver constraint atual (para não quebrar)
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c';

-- PARTE 5: Ver todos os status únicos existentes
SELECT DISTINCT status, COUNT(*) as quantidade
FROM processos_administrativos 
GROUP BY status
ORDER BY quantidade DESC;