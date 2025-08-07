-- =====================================================
-- CORRIGIR TODOS OS RELACIONAMENTOS - SCRIPT CONSOLIDADO
-- =====================================================

-- 1. RECURSOS_PROCESSO
SELECT '🔧 CORRIGINDO RECURSOS_PROCESSO...' as status;

-- Verificar recursos órfãos
SELECT COUNT(*) as recursos_orfaos FROM recursos_processo rp
LEFT JOIN processos_administrativos pa ON rp.processo_id = pa.id
WHERE pa.id IS NULL;

-- Limpar recursos órfãos
DELETE FROM recursos_processo WHERE id IN (
    SELECT rp.id FROM recursos_processo rp
    LEFT JOIN processos_administrativos pa ON rp.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- Criar foreign key
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_recursos_processo_processo_id'
        AND table_name = 'recursos_processo'
    ) THEN
        ALTER TABLE recursos_processo 
        ADD CONSTRAINT fk_recursos_processo_processo_id 
        FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_recursos_processo_processo_id ON recursos_processo(processo_id);

-- 2. TRAMITACAO_PROCESSO  
SELECT '🔧 CORRIGINDO TRAMITACAO_PROCESSO...' as status;

-- Verificar tramitações órfãs
SELECT COUNT(*) as tramitacoes_orfaas FROM tramitacao_processo tp
LEFT JOIN processos_administrativos pa ON tp.processo_id = pa.id
WHERE pa.id IS NULL;

-- Limpar tramitações órfãs
DELETE FROM tramitacao_processo WHERE id IN (
    SELECT tp.id FROM tramitacao_processo tp
    LEFT JOIN processos_administrativos pa ON tp.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- Criar foreign key
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_tramitacao_processo_processo_id'
        AND table_name = 'tramitacao_processo'
    ) THEN
        ALTER TABLE tramitacao_processo 
        ADD CONSTRAINT fk_tramitacao_processo_processo_id 
        FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tramitacao_processo_processo_id ON tramitacao_processo(processo_id);

-- 3. VERIFICAR OUTROS POSSÍVEIS RELACIONAMENTOS
SELECT '🔍 VERIFICANDO OUTROS RELACIONAMENTOS...' as status;

-- Listar todas as tabelas que referenciam processos_administrativos
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'processos_administrativos'
ORDER BY tc.table_name;

-- 4. RESULTADOS FINAIS
SELECT '✅ CORREÇÃO CONCLUÍDA!' as status;

SELECT 'Recursos restantes:' as tabela, COUNT(*) as total FROM recursos_processo
UNION ALL
SELECT 'Tramitações restantes:' as tabela, COUNT(*) as total FROM tramitacao_processo
UNION ALL  
SELECT 'Processos total:' as tabela, COUNT(*) as total FROM processos_administrativos;

SELECT 'TODOS OS RELACIONAMENTOS CORRIGIDOS! 🎉' as resultado;