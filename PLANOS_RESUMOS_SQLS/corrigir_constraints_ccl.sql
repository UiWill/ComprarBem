-- ===================================================
-- Script para corrigir constraints das colunas CCL
-- Ajustar valores permitidos conforme o código frontend
-- ===================================================

-- 1. Remover constraints existentes que estão conflitando
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_adequacao_tecnica_check;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_conformidade_documental_check;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_conformidade_normativa_check;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_ccl_status_check;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_requisitos_minimos_check;
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_conformidade_legal_check;

-- 2. Recriar constraints com os valores corretos do frontend

-- Adequação Técnica (conforme frontend)
ALTER TABLE produtos 
ADD CONSTRAINT produtos_adequacao_tecnica_check 
CHECK (adequacao_tecnica IN ('plenamente_adequado', 'adequado_ressalvas', 'inadequado'));

-- Conformidade Documental
ALTER TABLE produtos 
ADD CONSTRAINT produtos_conformidade_documental_check 
CHECK (conformidade_documental IN ('conforme', 'nao_conforme', 'pendente'));

-- Conformidade Normativa
ALTER TABLE produtos 
ADD CONSTRAINT produtos_conformidade_normativa_check 
CHECK (conformidade_normativa IN ('conforme', 'nao_conforme', 'pendente'));

-- Requisitos Mínimos (conforme frontend)
ALTER TABLE produtos 
ADD CONSTRAINT produtos_requisitos_minimos_check 
CHECK (requisitos_minimos IN ('atende_plenamente', 'atende_parcialmente', 'nao_atende'));

-- Conformidade Legal (conforme frontend)
ALTER TABLE produtos 
ADD CONSTRAINT produtos_conformidade_legal_check 
CHECK (conformidade_legal IN ('conforme', 'nao_conforme', 'pendente'));

-- CCL Status
ALTER TABLE produtos 
ADD CONSTRAINT produtos_ccl_status_check 
CHECK (ccl_status IN ('pendente_julgamento', 'aprovado', 'reprovado', 'aprovado_com_ressalvas', 'em_recurso', 'homologado'));

-- 3. Atualizar comentários com os valores corretos
COMMENT ON COLUMN produtos.adequacao_tecnica IS 
'Adequação às especificações técnicas: plenamente_adequado, adequado_ressalvas, inadequado';

COMMENT ON COLUMN produtos.requisitos_minimos IS 
'Atendimento aos requisitos mínimos: atende_plenamente, atende_parcialmente, nao_atende';

COMMENT ON COLUMN produtos.conformidade_legal IS 
'Conformidade com dispositivos legais: conforme, nao_conforme, pendente';

-- 4. Verificar se os constraints foram aplicados corretamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'produtos'::regclass
AND conname LIKE '%check%'
AND conname LIKE '%adequacao%'
OR conname LIKE '%requisitos%'
OR conname LIKE '%conformidade%';

-- 5. Confirmar sucesso
SELECT '✅ Constraints CCL corrigidos com sucesso!' as resultado;