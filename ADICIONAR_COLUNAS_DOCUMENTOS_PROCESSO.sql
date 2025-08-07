-- =====================================================
-- ADICIONAR COLUNAS FALTANTES EM DOCUMENTOS_PROCESSO
-- =====================================================

-- Adicionar colunas necessárias para o sistema funcionar
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS arquivo_url TEXT;
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS nome_documento TEXT;
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS tipo_documento VARCHAR(100);

-- Adicionar comentários explicativos
COMMENT ON COLUMN documentos_processo.arquivo_url IS 'URL do arquivo no Supabase Storage ou link externo';
COMMENT ON COLUMN documentos_processo.nome_documento IS 'Nome do documento para exibição';
COMMENT ON COLUMN documentos_processo.tipo_documento IS 'Tipo do documento (FOLHA_ROSTO, DFD, EDITAL, etc.)';

-- Verificação
SELECT 'Colunas adicionadas com sucesso!' as resultado;

-- Mostrar estrutura atualizada
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'documentos_processo' 
AND column_name IN ('arquivo_url', 'nome_documento', 'tipo_documento');