-- VERIFICAÇÃO COMPLETA DE TRIGGERS E FUNÇÕES AUTOMÁTICAS
-- Execute este SQL para ver todos os triggers que podem estar causando o problema

-- 1. VER TODOS OS TRIGGERS NA TABELA USUARIOS
SELECT 
    'TRIGGER_USUARIOS' as tipo,
    trigger_name,
    event_manipulation as evento,
    action_timing as quando,
    action_statement as acao
FROM information_schema.triggers 
WHERE event_object_table = 'usuarios'
ORDER BY trigger_name;

-- 2. VER TRIGGERS EM OUTRAS TABELAS RELACIONADAS
SELECT 
    'TRIGGERS_OUTRAS_TABELAS' as tipo,
    event_object_table as tabela,
    trigger_name,
    event_manipulation as evento,
    action_timing as quando
FROM information_schema.triggers 
WHERE event_object_table IN ('auth', 'profiles', 'user_profiles', 'accounts')
ORDER BY event_object_table, trigger_name;

-- 3. VER FUNÇÕES QUE PODEM SER CHAMADAS POR TRIGGERS
SELECT 
    'FUNCOES_SISTEMA' as tipo,
    routine_name as nome_funcao,
    routine_type as tipo_funcao,
    routine_definition as definicao
FROM information_schema.routines 
WHERE routine_name ILIKE '%user%' 
   OR routine_name ILIKE '%auth%'
   OR routine_name ILIKE '%profile%'
ORDER BY routine_name;

-- 4. VER POLICIES RLS QUE PODEM AFETAR
SELECT 
    'POLICIES_RLS' as tipo,
    tablename,
    policyname as nome_policy,
    permissive,
    roles,
    cmd as comando,
    qual as condicao
FROM pg_policies 
WHERE tablename = 'usuarios'
ORDER BY policyname;

-- 5. VER CONSTRAINTS E ÍNDICES
SELECT 
    'CONSTRAINTS' as tipo,
    conname as nome,
    contype as tipo_constraint,
    pg_get_constraintdef(oid) as definicao
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass
ORDER BY contype, conname;

-- 6. VER ÍNDICES
SELECT 
    'INDICES' as tipo,
    indexname as nome_indice,
    indexdef as definicao
FROM pg_indexes 
WHERE tablename = 'usuarios'
ORDER BY indexname;

-- 7. VER ESQUEMA COMPLETO DA TABELA USUARIOS
SELECT 
    'COLUNAS_USUARIOS' as tipo,
    column_name as coluna,
    data_type as tipo,
    is_nullable as permite_null,
    column_default as valor_padrao,
    character_maximum_length as tamanho_max
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
ORDER BY ordinal_position;

-- 8. VERIFICAR SE HÁ TABELA AUTH.USERS (Supabase nativo)
SELECT 
    'TABELA_AUTH_USERS' as tipo,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'auth' AND table_name = 'users'
        ) THEN 'EXISTE - Pode ter triggers automáticos'
        ELSE 'NÃO EXISTE'
    END as status;

-- 9. VERIFICAR EXTENSÕES ATIVAS (que podem ter triggers)
SELECT 
    'EXTENSOES' as tipo,
    extname as nome_extensao,
    extversion as versao
FROM pg_extension 
WHERE extname IN ('supabase_auth', 'pgjwt', 'uuid-ossp', 'pgcrypto')
ORDER BY extname;