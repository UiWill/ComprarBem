-- Verificar estrutura da tabela participantes_editais
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'participantes_editais'
ORDER BY ordinal_position;

-- Verificar se há dados na tabela
SELECT COUNT(*) as total_participantes FROM participantes_editais;

-- Verificar editais disponíveis
SELECT id, numero, descricao, status, tenant_id 
FROM editais 
WHERE status = 'PUBLICADO'
ORDER BY data_publicacao DESC; 