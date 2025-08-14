-- 1. Verificar TODAS as colunas da tabela processos_administrativos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
ORDER BY ordinal_position;