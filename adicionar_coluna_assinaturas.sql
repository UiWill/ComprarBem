-- =====================================================
-- ADICIONAR COLUNA DE ASSINATURAS NA TABELA DE PROCESSOS
-- =====================================================

-- Adicionar coluna para armazenar assinaturas como JSON
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS assinaturas JSONB DEFAULT '[]'::jsonb;

-- Adicionar índice para performance
CREATE INDEX IF NOT EXISTS idx_processos_assinaturas ON processos_administrativos USING GIN (assinaturas);

-- Verificar se foi adicionada
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name = 'assinaturas';