console.log('🔍 Verificando estrutura da tabela produtos...')

// Simulação da consulta que deveria ser feita no Supabase
console.log(`
-- SQL para ver a estrutura da tabela produtos
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'produtos' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar se existem campos de data
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'produtos' 
  AND (column_name LIKE '%data%' OR 
       column_name LIKE '%created%' OR 
       column_name LIKE '%criado%' OR
       column_name LIKE '%aprovado%');

-- Verificar se existe tabela de DCBs
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%dcb%';
`)

console.log('\n💡 Execute essas consultas no Supabase para ver a estrutura real da tabela')