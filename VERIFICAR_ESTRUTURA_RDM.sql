-- ============================================
-- VERIFICAR ESTRUTURA DAS TABELAS RDM
-- Sistema Comprar Bem - Diagnóstico
-- ============================================

-- 1. VERIFICAR SE TABELA rdms_online EXISTE
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'rdms_online'
ORDER BY ordinal_position;

-- 2. VERIFICAR TODAS AS TABELAS QUE CONTÊM 'rdm' NO NOME
SELECT table_name
FROM information_schema.tables
WHERE table_name ILIKE '%rdm%'
AND table_schema = 'public';

-- 3. VERIFICAR TABELAS QUE CONTÊM 'usuario' NO NOME
SELECT table_name
FROM information_schema.tables
WHERE table_name ILIKE '%usuario%'
AND table_schema = 'public';

-- 4. SE rdms_online NÃO EXISTIR, VERIFICAR usuarios_rdm
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'usuarios_rdm'
ORDER BY ordinal_position;

-- 5. LISTAR TODAS AS TABELAS DISPONÍVEIS
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name; 