-- 🚨 CORREÇÃO URGENTE - PERMITIR TIPOS PERSONALIZADOS EM DILIGÊNCIAS
-- Execute este código no Supabase SQL Editor

-- 1. Verificar constraint atual
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'diligencias' 
AND n.nspname = 'public'
AND contype = 'c'
AND conname LIKE '%tipo%';

-- 2. Remover constraint restritiva do campo tipo
ALTER TABLE diligencias DROP CONSTRAINT IF EXISTS diligencias_tipo_check;
ALTER TABLE diligencias DROP CONSTRAINT IF EXISTS check_tipo;

-- 3. Adicionar nova constraint mais flexível (apenas verificar se não está vazio)
ALTER TABLE diligencias ADD CONSTRAINT diligencias_tipo_check 
CHECK (tipo IS NOT NULL AND LENGTH(TRIM(tipo)) >= 3);

-- 4. Verificar se a constraint foi criada corretamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'diligencias' 
AND n.nspname = 'public'
AND contype = 'c'
AND conname = 'diligencias_tipo_check';

-- 5. Testar inserção com tipo personalizado
INSERT INTO diligencias (
    produto_id, 
    tenant_id, 
    tipo, 
    descricao, 
    prazo_dias, 
    data_limite, 
    status, 
    solicitado_por
) VALUES (
    (SELECT id FROM produtos LIMIT 1), -- Pega um produto existente
    (SELECT tenant_id FROM produtos LIMIT 1), -- Pega o tenant_id do produto
    'TESTE_TIPO_PERSONALIZADO', -- TIPO PERSONALIZADO
    'Teste de diligência com tipo personalizado para verificar se funciona',
    30,
    NOW() + INTERVAL '30 days',
    'PENDENTE',
    'CPM'
) ON CONFLICT DO NOTHING;

-- 6. Verificar se o teste funcionou
SELECT 
    id, 
    tipo, 
    descricao, 
    status,
    criado_em
FROM diligencias 
WHERE tipo = 'TESTE_TIPO_PERSONALIZADO'
ORDER BY criado_em DESC 
LIMIT 1;

-- 7. Remover o teste (opcional)
DELETE FROM diligencias WHERE tipo = 'TESTE_TIPO_PERSONALIZADO';

-- ✅ PRONTO! Agora tipos personalizados são aceitos na tabela diligencias 