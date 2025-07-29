-- Script para adicionar colunas que estão faltando na tabela recursos

-- 1. Primeiro, verificar estrutura atual
SELECT 
    'ESTRUTURA ATUAL' as status,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'recursos'
ORDER BY ordinal_position;

-- 2. Adicionar colunas que estão faltando
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS responsavel_decisao TEXT;
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS data_decisao TIMESTAMP WITH TIME ZONE;

-- 3. Verificar se as colunas foram adicionadas
SELECT 
    'ESTRUTURA APÓS ALTERAÇÕES' as status,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'recursos'
ORDER BY ordinal_position;

-- 4. Teste simples de update (sem erro)
DO $$
DECLARE
    recurso_id UUID;
BEGIN
    -- Pegar o primeiro recurso
    SELECT id INTO recurso_id FROM recursos LIMIT 1;
    
    IF recurso_id IS NOT NULL THEN
        -- Testar update com as novas colunas
        UPDATE recursos 
        SET 
            responsavel_decisao = 'Teste Sistema',
            data_decisao = NOW(),
            atualizado_em = NOW()
        WHERE id = recurso_id;
        
        RAISE NOTICE 'Update teste realizado com sucesso no recurso: %', recurso_id;
        
    ELSE
        RAISE NOTICE 'Nenhum recurso encontrado para teste';
    END IF;
END $$;

-- 5. Verificar recursos com as novas colunas
SELECT 
    'RECURSOS COM NOVAS COLUNAS' as status,
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