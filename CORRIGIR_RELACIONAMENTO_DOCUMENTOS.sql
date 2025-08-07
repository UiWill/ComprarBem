-- =====================================================
-- CORRIGIR RELACIONAMENTO ENTRE PROCESSOS E DOCUMENTOS
-- =====================================================

-- 1. Verificar se existe foreign key entre as tabelas
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'documentos_processo'::regclass
AND contype = 'f';

-- 2. Criar foreign key se não existir
DO $$
BEGIN
    -- Verificar se a constraint já existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_documentos_processo_processo_id'
        AND table_name = 'documentos_processo'
    ) THEN
        -- Adicionar foreign key
        ALTER TABLE documentos_processo 
        ADD CONSTRAINT fk_documentos_processo_processo_id 
        FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Foreign key já existe';
    END IF;
END $$;

-- 3. Verificar estrutura das tabelas
SELECT 'Estrutura de processos_administrativos:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name = 'id';

SELECT 'Estrutura de documentos_processo:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'documentos_processo' 
AND column_name = 'processo_id';

-- 4. Verificar se há documentos órfãos
SELECT 'Documentos órfãos (sem processo correspondente):' as info;
SELECT dp.id, dp.processo_id, dp.nome_documento
FROM documentos_processo dp
LEFT JOIN processos_administrativos pa ON dp.processo_id = pa.id
WHERE pa.id IS NULL;

-- 5. Criar índice para melhor performance
CREATE INDEX IF NOT EXISTS idx_documentos_processo_processo_id ON documentos_processo(processo_id);

SELECT 'Relacionamento corrigido! ✅' as status;