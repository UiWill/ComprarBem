-- 🚨 CORREÇÃO URGENTE - ADICIONAR STATUS 'diligencia' NA TABELA PRODUTOS
-- Execute este código no Supabase SQL Editor

-- 1. Primeiro, vamos verificar a constraint atual
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'produtos' 
AND n.nspname = 'public'
AND contype = 'c';

-- 2. Remover constraint antiga de status (se existir)
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_status_check;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS check_status;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_status_check1;

-- 3. Adicionar nova constraint com todos os status necessários
ALTER TABLE produtos ADD CONSTRAINT produtos_status_check 
CHECK (status IN ('pendente', 'aprovado', 'reprovado', 'diligencia', 'em_analise'));

-- 4. Verificar se a constraint foi criada corretamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'produtos' 
AND n.nspname = 'public'
AND contype = 'c'
AND conname = 'produtos_status_check';

-- ✅ PRONTO! Agora o status 'diligencia' é aceito na tabela produtos 