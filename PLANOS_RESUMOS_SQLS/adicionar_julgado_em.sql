-- ===================================================
-- Script para adicionar apenas a coluna faltante: julgado_em
-- ===================================================

-- Adicionar a coluna que ainda está faltando
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS julgado_em TIMESTAMP WITH TIME ZONE;

-- Comentário na coluna
COMMENT ON COLUMN produtos.julgado_em IS 
'Data e hora quando o produto foi julgado pela CCL';

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_produtos_julgado_em 
    ON produtos(tenant_id, julgado_em) 
    WHERE julgado_em IS NOT NULL;

-- Verificar se foi criada
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'produtos' 
AND column_name = 'julgado_em';

-- Confirmar sucesso
SELECT '✅ Coluna julgado_em criada com sucesso!' as resultado;