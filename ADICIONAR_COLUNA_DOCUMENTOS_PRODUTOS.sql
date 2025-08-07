-- =====================================================
-- ADICIONAR APENAS A COLUNA QUE FALTAVA
-- =====================================================

-- Adicionar coluna na tabela produtos_prequalificacao existente
ALTER TABLE produtos_prequalificacao 
ADD COLUMN IF NOT EXISTS documentos_adicionados JSONB DEFAULT '[]'::jsonb;

-- Adicionar comentário explicativo
COMMENT ON COLUMN produtos_prequalificacao.documentos_adicionados IS 'Array JSON com IDs dos documentos adicionados ao processo: ["doc-id-1", "doc-id-2"]';

-- Verificação
SELECT 'Coluna documentos_adicionados adicionada com sucesso!' as resultado;

-- Mostrar estrutura atualizada
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao' 
AND column_name = 'documentos_adicionados';

SELECT 'PRONTO! Agora a tabela produtos_prequalificacao tem a coluna documentos_adicionados ✅' as status;