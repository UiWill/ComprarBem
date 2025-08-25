-- Verificar estrutura das tabelas para corrigir a função
SELECT 'ESTRUTURA DA TABELA usuarios_rdm' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'usuarios_rdm' 
ORDER BY ordinal_position;

SELECT 'ESTRUTURA DA TABELA produtos' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'produtos' 
ORDER BY ordinal_position;

SELECT 'ESTRUTURA DA TABELA lembretes_enviados' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'lembretes_enviados' 
ORDER BY ordinal_position;