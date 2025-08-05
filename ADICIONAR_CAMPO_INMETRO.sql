-- Adicionar campo INMETRO na tabela produtos
-- Conforme solicitação do relatório de revisão

-- Adicionar coluna registro_inmetro
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS registro_inmetro VARCHAR(255);

-- Adicionar comentário explicativo na coluna
COMMENT ON COLUMN produtos.registro_inmetro IS 'Número do registro ou certificação INMETRO, quando aplicável';

-- Verificar se a coluna foi criada com sucesso
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'produtos' 
  AND column_name = 'registro_inmetro';