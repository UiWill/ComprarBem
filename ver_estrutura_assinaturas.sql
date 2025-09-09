-- Ver a estrutura da tabela que já existe
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'assinaturas_processo'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Testar se conseguimos inserir uma assinatura
-- SELECT COUNT(*) as total_assinaturas FROM assinaturas_processo;