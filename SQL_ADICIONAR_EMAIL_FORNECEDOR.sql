-- 📧 ADICIONAR CAMPO EMAIL_FORNECEDOR NA TABELA PRODUTOS
-- Para permitir envio de diligências por email

-- Adicionar coluna email_fornecedor
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS email_fornecedor VARCHAR(255);

-- Adicionar comentário
COMMENT ON COLUMN produtos.email_fornecedor IS 'Email do fornecedor para comunicações sobre diligências';

-- Criar índice para busca por email
CREATE INDEX IF NOT EXISTS idx_produtos_email_fornecedor 
ON produtos(email_fornecedor);

-- 📝 EXEMPLO DE UPDATE PARA PRODUTOS EXISTENTES
/*
-- Caso queira atualizar produtos existentes com emails padrão
UPDATE produtos 
SET email_fornecedor = 'contato@' || LOWER(REPLACE(fabricante, ' ', '')) || '.com.br'
WHERE email_fornecedor IS NULL 
AND fabricante IS NOT NULL;
*/

-- ✅ VERIFICAR SE A COLUNA FOI ADICIONADA
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos' 
AND column_name = 'email_fornecedor';

-- 📊 CONTAR PRODUTOS COM E SEM EMAIL
SELECT 
    COUNT(*) as total_produtos,
    COUNT(email_fornecedor) as com_email,
    COUNT(*) - COUNT(email_fornecedor) as sem_email,
    ROUND(
        (COUNT(email_fornecedor) * 100.0) / COUNT(*), 2
    ) as percentual_com_email
FROM produtos; 