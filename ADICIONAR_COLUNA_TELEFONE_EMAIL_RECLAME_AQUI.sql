-- Script para adicionar coluna telefone_email na tabela reclame_aqui
-- Data: 02/09/2025
-- Descrição: Adiciona campo para telefone/e-mail de contato nas reclamações

-- 1. Adicionar a coluna telefone_email
ALTER TABLE reclame_aqui 
ADD COLUMN telefone_email TEXT;

-- 2. Adicionar comentário na coluna
COMMENT ON COLUMN reclame_aqui.telefone_email IS 'Telefone ou e-mail para contato do reclamante';

-- 3. Verificar se a coluna foi criada corretamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'reclame_aqui' 
  AND column_name = 'telefone_email';

-- 4. Ver estrutura completa atualizada da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'reclame_aqui' 
ORDER BY ordinal_position;