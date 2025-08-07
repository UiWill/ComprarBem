-- =====================================================
-- CORRIGIR RELACIONAMENTO COM PRODUTOS_PREQUALIFICACAO
-- =====================================================

-- 1. Verificar produtos órfãos
SELECT 'PRODUTOS ÓRFÃOS ENCONTRADOS:' as status;
SELECT 
    pp.id, 
    pp.processo_id, 
    pp.nome_produto,
    pp.criado_em
FROM produtos_prequalificacao pp
LEFT JOIN processos_administrativos pa ON pp.processo_id = pa.id
WHERE pa.id IS NULL
ORDER BY pp.criado_em DESC;

-- 2. Limpar produtos órfãos
DELETE FROM produtos_prequalificacao 
WHERE id IN (
    SELECT pp.id
    FROM produtos_prequalificacao pp
    LEFT JOIN processos_administrativos pa ON pp.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- 3. Criar foreign key para produtos_prequalificacao
ALTER TABLE produtos_prequalificacao 
ADD CONSTRAINT fk_produtos_prequalificacao_processo_id 
FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;

-- 4. Criar índice
CREATE INDEX IF NOT EXISTS idx_produtos_prequalificacao_processo_id ON produtos_prequalificacao(processo_id);

-- 5. Verificação final
SELECT 'Verificação final - Produtos restantes:' as status;
SELECT 
    COUNT(*) as total_produtos,
    COUNT(DISTINCT processo_id) as processos_com_produtos
FROM produtos_prequalificacao;

SELECT 'RELACIONAMENTO COM PRODUTOS CORRIGIDO! ✅' as resultado;