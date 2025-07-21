-- ===========================================================
-- COMANDO SIMPLES PARA EXTRAIR ESTRUTURA
-- Execute este comando no SQL Editor do Supabase
-- ===========================================================

-- ESTRUTURA COMPLETA EM FORMATO MARKDOWN
SELECT 
    '## Tabela: ' || t.table_name || chr(10) ||
    '| Coluna | Tipo | Null | Padrão | Chave |' || chr(10) ||
    '|--------|------|------|---------|-------|' || chr(10) ||
    STRING_AGG(
        '| ' || c.column_name || 
        ' | ' || c.data_type || 
        CASE WHEN c.character_maximum_length IS NOT NULL THEN '(' || c.character_maximum_length || ')' ELSE '' END ||
        ' | ' || c.is_nullable || 
        ' | ' || COALESCE(c.column_default, 'NULL') || 
        ' | ' || COALESCE(
            CASE 
                WHEN tc.constraint_type = 'PRIMARY KEY' THEN 'PK'
                WHEN tc.constraint_type = 'FOREIGN KEY' THEN 'FK'
                WHEN tc.constraint_type = 'UNIQUE' THEN 'UK'
                ELSE ''
            END, ''
        ) || ' |',
        chr(10)
        ORDER BY c.ordinal_position
    ) || chr(10) || chr(10) AS estrutura_markdown

FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
LEFT JOIN information_schema.key_column_usage kcu ON c.table_name = kcu.table_name AND c.column_name = kcu.column_name
LEFT JOIN information_schema.table_constraints tc ON kcu.constraint_name = tc.constraint_name

WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'
AND c.table_schema = 'public'

GROUP BY t.table_name
ORDER BY t.table_name;