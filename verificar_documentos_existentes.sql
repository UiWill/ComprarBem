-- Script para verificar documentos administrativos existentes
-- Execute este script e me envie o resultado para eu atualizar o inserir_manual_sistema.sql

-- 1. Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'documentos_administrativos'
ORDER BY ordinal_position;

-- 2. Verificar se existem índices
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'documentos_administrativos';

-- 3. Verificar políticas RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'documentos_administrativos';

-- 4. Verificar documentos existentes (todos)
SELECT 
    id,
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    criado_em,
    atualizado_em
FROM documentos_administrativos
ORDER BY criado_em DESC;

-- 5. Verificar documentos globais/públicos (que apareceriam para todos)
SELECT 
    titulo,
    categoria,
    visibilidade,
    status,
    tags,
    criado_em
FROM documentos_administrativos
WHERE (tenant_id IS NULL OR visibilidade = 'publico')
AND status = 'ativo'
ORDER BY categoria, titulo;

-- 6. Contar documentos por categoria
SELECT 
    categoria,
    COUNT(*) as total,
    COUNT(CASE WHEN visibilidade = 'publico' THEN 1 END) as publicos,
    COUNT(CASE WHEN tenant_id IS NULL THEN 1 END) as globais
FROM documentos_administrativos
WHERE status = 'ativo'
GROUP BY categoria
ORDER BY categoria;

-- 7. Verificar se existe trigger de updated_at
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'documentos_administrativos';

-- 8. Verificar constraints da tabela
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'documentos_administrativos'
ORDER BY tc.constraint_type;