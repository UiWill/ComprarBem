-- =====================================================
-- VERIFICAÇÃO SIMPLES E SEGURA
-- =====================================================

-- 1. Verificar se a tabela assinaturas_processo já existe
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_name = 'assinaturas_processo'
) as tabela_existe;

-- 2. Se existir, mostrar as colunas
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'assinaturas_processo'
ORDER BY ordinal_position;

-- 3. Verificar se há erros relacionados a processo_id em outras tabelas
-- (vamos tentar criar uma tabela teste para ver onde está o problema)
CREATE TEMP TABLE teste_processo_id (
    id UUID DEFAULT gen_random_uuid(),
    processo_id UUID
);

-- Se chegou até aqui, o problema não é com processo_id em geral
DROP TABLE teste_processo_id;

SELECT 'Teste processo_id: OK' as resultado;