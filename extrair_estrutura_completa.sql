-- ===========================================================
-- COMANDO PARA EXTRAIR ESTRUTURA COMPLETA DO BANCO
-- Execute este comando no SQL Editor do Supabase
-- ===========================================================

-- 1. LISTAR TODAS AS TABELAS COM SUAS COLUNAS DETALHADAS
SELECT 
    t.table_name AS tabela,
    c.column_name AS coluna,
    c.data_type AS tipo_dados,
    c.character_maximum_length AS tamanho_maximo,
    c.is_nullable AS permite_null,
    c.column_default AS valor_padrao,
    c.ordinal_position AS posicao,
    
    -- Informações sobre chaves
    CASE 
        WHEN tc.constraint_type = 'PRIMARY KEY' THEN 'PRIMARY KEY'
        WHEN tc.constraint_type = 'FOREIGN KEY' THEN 'FOREIGN KEY'
        WHEN tc.constraint_type = 'UNIQUE' THEN 'UNIQUE'
        ELSE NULL
    END AS tipo_chave,
    
    -- Informações sobre referências (FK)
    CASE 
        WHEN tc.constraint_type = 'FOREIGN KEY' THEN 
            rc.unique_constraint_name || ' -> ' || kcu2.table_name || '(' || kcu2.column_name || ')'
        ELSE NULL
    END AS referencia_fk

FROM information_schema.tables t
LEFT JOIN information_schema.columns c ON t.table_name = c.table_name
LEFT JOIN information_schema.key_column_usage kcu ON c.table_name = kcu.table_name AND c.column_name = kcu.column_name
LEFT JOIN information_schema.table_constraints tc ON kcu.constraint_name = tc.constraint_name
LEFT JOIN information_schema.referential_constraints rc ON tc.constraint_name = rc.constraint_name
LEFT JOIN information_schema.key_column_usage kcu2 ON rc.unique_constraint_name = kcu2.constraint_name

WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'
AND c.table_schema = 'public'

ORDER BY t.table_name, c.ordinal_position;

-- ===========================================================
-- 2. INFORMAÇÕES RESUMIDAS POR TABELA
-- ===========================================================

SELECT 
    table_name AS tabela,
    COUNT(*) AS total_colunas,
    STRING_AGG(column_name, ', ' ORDER BY ordinal_position) AS colunas
FROM information_schema.columns
WHERE table_schema = 'public'
GROUP BY table_name
ORDER BY table_name;

-- ===========================================================
-- 3. CHAVES PRIMÁRIAS E ESTRANGEIRAS
-- ===========================================================

-- Chaves Primárias
SELECT 
    tc.table_name AS tabela,
    tc.constraint_name AS nome_constraint,
    tc.constraint_type AS tipo,
    STRING_AGG(kcu.column_name, ', ') AS colunas
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
AND tc.table_schema = 'public'
GROUP BY tc.table_name, tc.constraint_name, tc.constraint_type
ORDER BY tc.table_name;

-- Chaves Estrangeiras
SELECT 
    tc.table_name AS tabela_origem,
    kcu.column_name AS coluna_origem,
    ccu.table_name AS tabela_destino,
    ccu.column_name AS coluna_destino,
    tc.constraint_name AS nome_constraint
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ===========================================================
-- 4. ÍNDICES EXISTENTES
-- ===========================================================

SELECT 
    schemaname AS schema,
    tablename AS tabela,
    indexname AS indice,
    indexdef AS definicao
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ===========================================================
-- 5. FUNÇÕES EXISTENTES
-- ===========================================================

SELECT 
    routine_name AS nome_funcao,
    routine_type AS tipo,
    data_type AS tipo_retorno,
    routine_definition AS definicao
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- ===========================================================
-- 6. VIEWS EXISTENTES
-- ===========================================================

SELECT 
    table_name AS nome_view,
    view_definition AS definicao
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- ===========================================================
-- 7. TRIGGERS EXISTENTES
-- ===========================================================

SELECT 
    trigger_name AS nome_trigger,
    event_manipulation AS evento,
    event_object_table AS tabela,
    action_statement AS acao
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;