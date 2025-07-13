-- Adicionar coluna código na tabela grupos
ALTER TABLE grupos ADD COLUMN codigo VARCHAR(20);

-- Criar índice para melhor performance
CREATE INDEX idx_grupos_codigo ON grupos(codigo);

-- Verificar se foi criada
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'grupos' 
AND column_name = 'codigo';