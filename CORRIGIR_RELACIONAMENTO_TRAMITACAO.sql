-- =====================================================
-- CORRIGIR RELACIONAMENTO COM TRAMITACAO_PROCESSO
-- =====================================================

-- 1. Verificar tramitações órfãs
SELECT 'TRAMITAÇÕES ÓRFÃS ENCONTRADAS:' as status;
SELECT 
    tp.id, 
    tp.processo_id, 
    tp.status_anterior,
    tp.status_novo
FROM tramitacao_processo tp
LEFT JOIN processos_administrativos pa ON tp.processo_id = pa.id
WHERE pa.id IS NULL
ORDER BY tp.id DESC;

-- 2. Limpar tramitações órfãs
DELETE FROM tramitacao_processo 
WHERE id IN (
    SELECT tp.id
    FROM tramitacao_processo tp
    LEFT JOIN processos_administrativos pa ON tp.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- 3. Criar foreign key para tramitacao_processo
ALTER TABLE tramitacao_processo 
ADD CONSTRAINT fk_tramitacao_processo_processo_id 
FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;

-- 4. Criar índice
CREATE INDEX IF NOT EXISTS idx_tramitacao_processo_processo_id ON tramitacao_processo(processo_id);

-- 5. Verificação final
SELECT 'Verificação final - Tramitações restantes:' as status;
SELECT 
    COUNT(*) as total_tramitacoes,
    COUNT(DISTINCT processo_id) as processos_com_tramitacao
FROM tramitacao_processo;

SELECT 'RELACIONAMENTO COM TRAMITAÇÃO CORRIGIDO! ✅' as resultado;