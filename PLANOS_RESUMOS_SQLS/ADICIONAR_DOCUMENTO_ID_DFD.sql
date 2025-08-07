-- ADICIONAR TODAS AS COLUNAS QUE PODEM ESTAR FALTANDO

-- 1. Adicionar documento_id e outras colunas essenciais
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS documento_id UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS documento_uuid UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS doc_id UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS ref_documento UUID;

-- 2. Adicionar outras colunas que podem ser necessárias
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS numero_folha VARCHAR(20);
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS folha_numero VARCHAR(20);
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS sequencial INTEGER;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS numero_sequencial INTEGER;

-- 3. Adicionar campos de relacionamento adicionais
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS parent_id UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS processo_pai UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS documento_pai UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS dfd_pai UUID;

-- 4. Adicionar campos de sistema
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- 5. Adicionar campos de usuário
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS usuario_id UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS updated_by UUID;

-- 6. Adicionar campos de conteúdo
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS conteudo JSONB;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS dados JSONB;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS body TEXT;

-- 7. Verificar se documento_id foi adicionado
SELECT 
    'VERIFICAÇÃO DOCUMENTO_ID' as titulo,
    column_name,
    data_type,
    'ADICIONADO!' as status
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
AND column_name LIKE '%documento%';

-- 8. Listar todas as colunas relacionadas a ID
SELECT 
    'COLUNAS DE ID' as titulo,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'dfd_processo'
AND column_name LIKE '%id%'
ORDER BY column_name;

-- 9. Contar total final de colunas
SELECT 
    'TOTAL FINAL DE COLUNAS' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'dfd_processo';

-- 10. STATUS
SELECT 'TODAS AS COLUNAS DE ID ADICIONADAS!' as status;