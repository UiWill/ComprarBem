-- ===================================================
-- Script para corrigir constraint do campo status
-- Adicionar novos status que o CCL utiliza
-- ===================================================

-- 1. Verificar constraint atual
SELECT 
    'CONSTRAINT ATUAL:' as info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'produtos'::regclass
AND conname LIKE '%status%';

-- 2. Remover constraint de status existente
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_status_check;

-- 3. Recriar constraint com TODOS os status necessários
ALTER TABLE produtos 
ADD CONSTRAINT produtos_status_check 
CHECK (status IN (
    -- Status originais da CPM
    'pendente',
    'em_analise', 
    'aprovado',
    'reprovado',
    'diligencia',
    'pendencia_documentacao',
    -- Status do CCL (novos)
    'julgado_aprovado',
    'julgado_reprovado', 
    'julgamento_pendente',
    -- Status adicionais que podem ser usados
    'homologado',
    'cancelado',
    'arquivado'
));

-- 4. Atualizar comentário do campo
COMMENT ON COLUMN produtos.status IS 
'Status do produto no fluxo: pendente, em_analise, aprovado, reprovado, diligencia, pendencia_documentacao, julgado_aprovado, julgado_reprovado, julgamento_pendente, homologado, cancelado, arquivado';

-- 5. Verificar se foi aplicado corretamente
SELECT 
    'NOVO CONSTRAINT:' as info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'produtos'::regclass
AND conname LIKE '%status%';

-- 6. Confirmar sucesso
SELECT '✅ Constraint de status corrigido com sucesso!' as resultado;