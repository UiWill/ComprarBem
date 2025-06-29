-- ============================================
-- VERIFICAR COLUNAS DA TABELA rdms_online
-- Sistema Comprar Bem - Estrutura
-- ============================================

-- 1. VERIFICAR ESTRUTURA DA TABELA rdms_online
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'rdms_online'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. VERIFICAR ESTRUTURA DA TABELA usuarios_rdm
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'usuarios_rdm'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. VERIFICAR SE JÁ EXISTE rdm_feedbacks
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'rdm_feedbacks'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. MOSTRAR ALGUMAS LINHAS DE EXEMPLO DE rdms_online (se existir)
SELECT * FROM rdms_online LIMIT 3; 