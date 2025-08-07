-- =====================================================
-- ADICIONAR COLUNA DATA_REMOCAO EM DOCUMENTOS_PROCESSO
-- =====================================================

-- Adicionar coluna data_remocao
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS data_remocao TIMESTAMP WITH TIME ZONE;

-- Adicionar comentário explicativo
COMMENT ON COLUMN documentos_processo.data_remocao IS 'Data/hora de remoção do documento (para soft delete)';

-- Verificação
SELECT 'Coluna data_remocao adicionada com sucesso!' as resultado;

-- Mostrar estrutura atualizada
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'documentos_processo' 
AND column_name = 'data_remocao';

SELECT 'PRONTO! Agora a tabela documentos_processo tem a coluna data_remocao ✅' as status;