-- =====================================================
-- CORRIGIR ESTRUTURA DA TABELA ASSINATURAS_PROCESSO
-- =====================================================

-- Renomear e adicionar colunas para ficar compatível com o sistema
ALTER TABLE assinaturas_processo 
RENAME COLUMN documento_id TO processo_id;

ALTER TABLE assinaturas_processo 
RENAME COLUMN nome_completo TO nome_signatario;

ALTER TABLE assinaturas_processo 
RENAME COLUMN cargo TO cargo_signatario;

ALTER TABLE assinaturas_processo 
RENAME COLUMN hash_documento TO hash_validacao;

-- Adicionar updated_at se não existir
ALTER TABLE assinaturas_processo 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Verificar a estrutura corrigida
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'assinaturas_processo'
AND table_schema = 'public'
ORDER BY ordinal_position;