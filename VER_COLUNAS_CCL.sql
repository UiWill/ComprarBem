-- 2. Verificar se as colunas CCL foram criadas
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name LIKE '%ccl%'
ORDER BY column_name;