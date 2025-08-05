-- Script para testar update na tabela recursos
-- Execute este script para verificar se o update funciona

-- 1. Verificar se existem recursos na tabela
SELECT 'RECURSOS EXISTENTES' as status, count(*) as total FROM recursos;

-- 2. Mostrar estrutura da tabela recursos
SELECT 
    'ESTRUTURA DA TABELA' as status,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'recursos'
ORDER BY ordinal_position;

-- 3. Mostrar últimos recursos para teste
SELECT 
    'ÚLTIMOS RECURSOS' as status,
    id,
    recorrente,
    produto_nome,
    status,
    decisao,
    responsavel_decisao,
    data_decisao
FROM recursos 
ORDER BY criado_em DESC 
LIMIT 3;

-- 4. Teste de update em um recurso específico (se existir)
DO $$
DECLARE
    recurso_id UUID;
BEGIN
    -- Pegar o primeiro recurso em análise
    SELECT id INTO recurso_id FROM recursos WHERE status = 'EM ANÁLISE' LIMIT 1;
    
    IF recurso_id IS NOT NULL THEN
        -- Testar update
        UPDATE recursos 
        SET 
            decisao = 'TESTE',
            fundamentacao_decisao = 'Teste de funcionamento do update',
            responsavel_decisao = 'Sistema de Teste',
            data_decisao = NOW(),
            status = 'TESTE',
            atualizado_em = NOW()
        WHERE id = recurso_id;
        
        RAISE NOTICE 'Update realizado com sucesso no recurso: %', recurso_id;
        
        -- Mostrar resultado
        PERFORM pg_notify('update_test', 'Update funcionou!');
        
        -- Reverter o teste
        UPDATE recursos 
        SET 
            decisao = NULL,
            fundamentacao_decisao = NULL,
            responsavel_decisao = NULL,
            data_decisao = NULL,
            status = 'EM ANÁLISE',
            atualizado_em = NOW()
        WHERE id = recurso_id;
        
        RAISE NOTICE 'Teste concluído e revertido para o recurso: %', recurso_id;
    ELSE
        RAISE NOTICE 'Nenhum recurso em análise encontrado para teste';
    END IF;
END $$;

-- 5. Verificar se o teste funcionou
SELECT 'TESTE CONCLUÍDO' as status, NOW() as timestamp;