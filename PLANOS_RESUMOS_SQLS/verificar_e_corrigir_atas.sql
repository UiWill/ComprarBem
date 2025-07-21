-- Verificar estrutura atual da tabela atas_julgamento
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'atas_julgamento'
ORDER BY ordinal_position;

-- Adicionar coluna descricao se não existe
ALTER TABLE atas_julgamento 
ADD COLUMN IF NOT EXISTS descricao TEXT;

-- Verificar se a coluna foi criada
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'atas_julgamento' 
AND column_name = 'descricao';