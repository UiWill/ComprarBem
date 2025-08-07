-- =====================================================
-- CORRIGIR RELACIONAMENTO COM RECURSOS_PROCESSO
-- =====================================================

-- 1. Verificar recursos órfãos
SELECT 'RECURSOS ÓRFÃOS ENCONTRADOS:' as status;
SELECT 
    rp.id, 
    rp.processo_id, 
    rp.tipo_recurso
FROM recursos_processo rp
LEFT JOIN processos_administrativos pa ON rp.processo_id = pa.id
WHERE pa.id IS NULL
ORDER BY rp.id DESC;

-- 2. Limpar recursos órfãos
DELETE FROM recursos_processo 
WHERE id IN (
    SELECT rp.id
    FROM recursos_processo rp
    LEFT JOIN processos_administrativos pa ON rp.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- 3. Criar foreign key para recursos_processo
ALTER TABLE recursos_processo 
ADD CONSTRAINT fk_recursos_processo_processo_id 
FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;

-- 4. Criar índice
CREATE INDEX IF NOT EXISTS idx_recursos_processo_processo_id ON recursos_processo(processo_id);

-- 5. Verificação final
SELECT 'Verificação final - Recursos restantes:' as status;
SELECT 
    COUNT(*) as total_recursos,
    COUNT(DISTINCT processo_id) as processos_com_recursos
FROM recursos_processo;

SELECT 'RELACIONAMENTO COM RECURSOS CORRIGIDO! ✅' as resultado;