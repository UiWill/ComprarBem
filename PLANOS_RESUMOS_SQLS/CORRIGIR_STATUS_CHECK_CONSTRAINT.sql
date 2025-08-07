-- Corrigir problema de check constraint no status de processos_administrativos

-- 1. Verificar a constraint de status
SELECT 
    'CHECK CONSTRAINTS' as titulo,
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'processos_administrativos'
AND tc.constraint_type = 'CHECK';

-- 2. Ver estrutura da coluna status
SELECT 
    'ESTRUTURA COLUNA STATUS' as titulo,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name = 'status';

-- 3. SOLUÇÃO: Remover a constraint de status (temporariamente)
ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- 4. OU ALTERNATIVA: Modificar a constraint para aceitar mais valores
-- ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;
-- ALTER TABLE processos_administrativos ADD CONSTRAINT processos_administrativos_status_check 
-- CHECK (status IN ('rascunho', 'RASCUNHO', 'em_andamento', 'EM_ANDAMENTO', 'concluido', 'CONCLUIDO', 'cancelado', 'CANCELADO'));

-- 5. Verificar se a constraint foi removida
SELECT 
    'APÓS CORREÇÃO' as titulo,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_name = 'processos_administrativos'
AND tc.constraint_type = 'CHECK';

-- 6. Testar valores de status existentes (se houver)
SELECT 
    'STATUS EXISTENTES' as titulo,
    status,
    COUNT(*) as quantidade
FROM processos_administrativos 
GROUP BY status;

-- 7. Ver estrutura completa da tabela
SELECT 
    'ESTRUTURA COMPLETA' as titulo,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos'
ORDER BY ordinal_position;