-- Script para adicionar a coluna conteudo_html na tabela dfd_processo
-- Execute este comando no Supabase SQL Editor

-- Verificar se a coluna já existe
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'dfd_processo'
  AND column_name = 'conteudo_html';

-- Adicionar a coluna conteudo_html se não existir
ALTER TABLE dfd_processo
ADD COLUMN IF NOT EXISTS conteudo_html TEXT;

-- Verificar se a coluna foi adicionada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'dfd_processo'
ORDER BY ordinal_position;