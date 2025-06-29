-- =============================================================================
-- ADICIONAR COLUNAS NORMAS - SISTEMA COMPRAR BEM
-- =============================================================================
-- Descrição: Adiciona as colunas norma_abnt e norma_regulamentadora na tabela produtos
-- Data: Janeiro 2025
-- Requisição: Item 3.3 dos apontamentos do cliente
-- =============================================================================

-- 1. Adicionar coluna norma_abnt
ALTER TABLE produtos ADD COLUMN norma_abnt TEXT;

-- 2. Adicionar coluna norma_regulamentadora  
ALTER TABLE produtos ADD COLUMN norma_regulamentadora TEXT;

-- 3. Comentários nas colunas para documentação
COMMENT ON COLUMN produtos.norma_abnt IS 'Número da norma ABNT aplicável ao produto';
COMMENT ON COLUMN produtos.norma_regulamentadora IS 'Número da norma regulamentadora aplicável ao produto';

-- 4. Verificar se as colunas foram criadas com sucesso
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos' 
AND column_name IN ('norma_abnt', 'norma_regulamentadora')
ORDER BY column_name;

-- 5. Verificar estrutura completa da tabela produtos (opcional)
-- SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'produtos' ORDER BY ordinal_position; 