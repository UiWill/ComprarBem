-- Script para corrigir datas existentes e adicionar constraint de validação
-- Primeiro corrige os dados existentes, depois adiciona a constraint

-- 1. Identificar registros problemáticos
SELECT 
    id, 
    numero, 
    data_publicacao, 
    data_limite_impugnacao,
    CASE 
        WHEN data_limite_impugnacao <= data_publicacao THEN 'PROBLEMA'
        ELSE 'OK'
    END as status_datas
FROM editais 
WHERE data_limite_impugnacao IS NOT NULL 
AND data_publicacao IS NOT NULL;

-- 2. Corrigir registros problemáticos
-- Adiciona 7 dias à data de publicação para criar um prazo válido
UPDATE editais 
SET data_limite_impugnacao = data_publicacao + INTERVAL '7 days'
WHERE data_limite_impugnacao <= data_publicacao;

-- 3. Verificar se a correção funcionou
SELECT 
    id, 
    numero, 
    data_publicacao, 
    data_limite_impugnacao,
    CASE 
        WHEN data_limite_impugnacao <= data_publicacao THEN 'AINDA COM PROBLEMA'
        ELSE 'CORRIGIDO'
    END as status_datas
FROM editais 
WHERE data_limite_impugnacao IS NOT NULL 
AND data_publicacao IS NOT NULL;

-- 4. Agora adicionar a constraint (só vai funcionar se não houver mais problemas)
ALTER TABLE editais 
ADD CONSTRAINT check_data_limite_impugnacao 
CHECK (data_limite_impugnacao > data_publicacao);

-- 5. Comentário explicativo
COMMENT ON CONSTRAINT check_data_limite_impugnacao ON editais IS 
'Garante que o prazo para impugnações seja sempre posterior à data de publicação do edital'; 