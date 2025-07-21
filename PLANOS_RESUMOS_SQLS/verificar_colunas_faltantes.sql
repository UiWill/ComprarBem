-- ===================================================
-- Verificação rápida das colunas que ainda faltam
-- ===================================================

-- Verificar se colunas específicas do CCL existem
SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'adequacao_tecnica'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as adequacao_tecnica,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'base_legal'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as base_legal,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'julgado_em'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as julgado_em,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'atualizado_em'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as atualizado_em,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'observacoes_ccl'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as observacoes_ccl,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'requisitos_minimos'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as requisitos_minimos,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'conformidade_legal'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as conformidade_legal,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'observacoes_ccl_adicional'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as observacoes_ccl_adicional;