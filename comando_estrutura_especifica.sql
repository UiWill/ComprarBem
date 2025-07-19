-- ===========================================================
-- COMANDO ESPECÍFICO PARA ANÁLISE DE NOTIFICAÇÕES
-- Execute este comando no SQL Editor do Supabase
-- ===========================================================

-- ESTRUTURA DAS TABELAS PRINCIPAIS PARA NOTIFICAÇÕES
SELECT 
    'TABELA: ' || t.table_name || chr(10) ||
    STRING_AGG(
        '  ' || c.column_name || 
        ' | ' || c.data_type || 
        CASE WHEN c.character_maximum_length IS NOT NULL THEN '(' || c.character_maximum_length || ')' ELSE '' END ||
        ' | ' || CASE WHEN c.is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END ||
        ' | ' || COALESCE(c.column_default, 'sem padrão') ||
        CASE 
            WHEN tc.constraint_type = 'PRIMARY KEY' THEN ' [PK]'
            WHEN tc.constraint_type = 'FOREIGN KEY' THEN ' [FK]'
            WHEN tc.constraint_type = 'UNIQUE' THEN ' [UK]'
            ELSE ''
        END,
        chr(10)
        ORDER BY c.ordinal_position
    ) || chr(10) || chr(10) AS estrutura_tabela

FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
LEFT JOIN information_schema.key_column_usage kcu ON c.table_name = kcu.table_name AND c.column_name = kcu.column_name
LEFT JOIN information_schema.table_constraints tc ON kcu.constraint_name = tc.constraint_name

WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'
AND c.table_schema = 'public'
AND t.table_name IN (
    'usuarios_rdm',
    'produtos', 
    'tenants',
    'emails_enviados',
    'rdm_feedbacks',
    'material_feedbacks',
    'configuracoes_sistema',
    'usuarios_rdm_produtos',
    'lembretes_enviados'
)

GROUP BY t.table_name
ORDER BY 
    CASE t.table_name
        WHEN 'tenants' THEN 1
        WHEN 'usuarios_rdm' THEN 2
        WHEN 'produtos' THEN 3
        WHEN 'emails_enviados' THEN 4
        WHEN 'rdm_feedbacks' THEN 5
        WHEN 'material_feedbacks' THEN 6
        WHEN 'configuracoes_sistema' THEN 7
        WHEN 'usuarios_rdm_produtos' THEN 8
        WHEN 'lembretes_enviados' THEN 9
        ELSE 10
    END;