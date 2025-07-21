-- ===================================================
-- Script para analisar estrutura atual da tabela produtos
-- E identificar todas as colunas necessárias para CCL
-- ===================================================

-- 1. Listar TODAS as colunas atuais da tabela produtos
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'produtos' 
ORDER BY ordinal_position;

-- 2. Verificar se colunas específicas do CCL existem
SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'adequacao_tecnica'
    ) THEN 'EXISTS' ELSE 'MISSING' END as adequacao_tecnica,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'conformidade_documental'
    ) THEN 'EXISTS' ELSE 'MISSING' END as conformidade_documental,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'conformidade_normativa'
    ) THEN 'EXISTS' ELSE 'MISSING' END as conformidade_normativa,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'justificativa_julgamento'
    ) THEN 'EXISTS' ELSE 'MISSING' END as justificativa_julgamento,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'ccl_julgado_por'
    ) THEN 'EXISTS' ELSE 'MISSING' END as ccl_julgado_por,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'ccl_data_julgamento'
    ) THEN 'EXISTS' ELSE 'MISSING' END as ccl_data_julgamento,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'ccl_numero_ata'
    ) THEN 'EXISTS' ELSE 'MISSING' END as ccl_numero_ata,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'ccl_status'
    ) THEN 'EXISTS' ELSE 'MISSING' END as ccl_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'recurso_interposto'
    ) THEN 'EXISTS' ELSE 'MISSING' END as recurso_interposto,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'recurso_data'
    ) THEN 'EXISTS' ELSE 'MISSING' END as recurso_data,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'recurso_motivo'
    ) THEN 'EXISTS' ELSE 'MISSING' END as recurso_motivo,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'recurso_julgado'
    ) THEN 'EXISTS' ELSE 'MISSING' END as recurso_julgado,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'recurso_resultado'
    ) THEN 'EXISTS' ELSE 'MISSING' END as recurso_resultado,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'homologado'
    ) THEN 'EXISTS' ELSE 'MISSING' END as homologado,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'homologado_por'
    ) THEN 'EXISTS' ELSE 'MISSING' END as homologado_por,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'homologado_em'
    ) THEN 'EXISTS' ELSE 'MISSING' END as homologado_em,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'observacoes_ccl'
    ) THEN 'EXISTS' ELSE 'MISSING' END as observacoes_ccl,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'base_legal'
    ) THEN 'EXISTS' ELSE 'MISSING' END as base_legal,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'requisitos_minimos'
    ) THEN 'EXISTS' ELSE 'MISSING' END as requisitos_minimos,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'conformidade_legal'
    ) THEN 'EXISTS' ELSE 'MISSING' END as conformidade_legal,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'observacoes_ccl_adicional'
    ) THEN 'EXISTS' ELSE 'MISSING' END as observacoes_ccl_adicional,
    
    -- Verificar a nova coluna que está faltando
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'julgado_em'
    ) THEN 'EXISTS' ELSE 'MISSING' END as julgado_em;

-- 3. Verificar se existem views dependentes
SELECT 
    schemaname, 
    viewname, 
    viewowner
FROM pg_views 
WHERE definition LIKE '%produtos%';

-- 4. Verificar constraints existentes
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'produtos'::regclass;

-- 5. Verificar índices na tabela produtos
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'produtos';