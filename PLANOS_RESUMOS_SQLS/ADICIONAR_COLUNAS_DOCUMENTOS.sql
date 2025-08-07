-- Adicionar colunas que estão faltando na tabela documentos_processo

-- 1. Adicionar coluna conteudo
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS conteudo JSONB;

-- 2. Adicionar outras colunas essenciais
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS conteudo_html TEXT;
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS nome_documento TEXT;
ALTER TABLE documentos_processo ADD COLUMN IF NOT EXISTS descricao TEXT;

-- 3. Verificar se as colunas foram adicionadas
SELECT 
    'COLUNAS ADICIONADAS' as titulo,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
AND column_name IN ('conteudo', 'conteudo_html', 'nome_documento', 'descricao')
ORDER BY column_name;

-- 4. Ver estrutura completa atual
SELECT 
    'ESTRUTURA ATUAL' as titulo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'documentos_processo'
ORDER BY ordinal_position;

-- 5. Teste
SELECT 'COLUNAS CORRIGIDAS!' as status;