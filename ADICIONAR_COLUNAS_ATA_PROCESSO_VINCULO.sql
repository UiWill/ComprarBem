-- ==============================================
-- SCRIPT PARA MELHORAR VINCULAÇÃO ATA-PROCESSO
-- ==============================================
-- Este script adiciona colunas para vinculação específica entre atas e processos

-- Verificar se as colunas já existem antes de adicionar
DO $$ 
BEGIN 
    -- Adicionar coluna processo_id para vinculação específica
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'processo_id') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN processo_id UUID REFERENCES processos_administrativos(id);
        
        RAISE NOTICE '✅ Coluna processo_id adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna processo_id já existe na tabela atas_julgamento';
    END IF;

    -- Adicionar coluna numero_processo para facilitar consultas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'numero_processo') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN numero_processo VARCHAR(100);
        
        RAISE NOTICE '✅ Coluna numero_processo adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna numero_processo já existe na tabela atas_julgamento';
    END IF;

    -- Adicionar coluna tipo_processo
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'tipo_processo') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN tipo_processo VARCHAR(20) CHECK (tipo_processo IN ('padronizacao', 'despadronizacao'));
        
        RAISE NOTICE '✅ Coluna tipo_processo adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna tipo_processo já existe na tabela atas_julgamento';
    END IF;

    -- Adicionar coluna orgao_responsavel
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'orgao_responsavel') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN orgao_responsavel TEXT;
        
        RAISE NOTICE '✅ Coluna orgao_responsavel adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna orgao_responsavel já existe na tabela atas_julgamento';
    END IF;

    -- Adicionar coluna objeto_processo
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'objeto_processo') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN objeto_processo TEXT;
        
        RAISE NOTICE '✅ Coluna objeto_processo adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna objeto_processo já existe na tabela atas_julgamento';
    END IF;

    -- Adicionar coluna decisao_ccl
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'decisao_ccl') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN decisao_ccl VARCHAR(20) CHECK (decisao_ccl IN ('APROVADO', 'REJEITADO', 'DEVOLVIDO'));
        
        RAISE NOTICE '✅ Coluna decisao_ccl adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna decisao_ccl já existe na tabela atas_julgamento';
    END IF;

    -- Adicionar coluna fundamentacao_ccl
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'atas_julgamento' AND column_name = 'fundamentacao_ccl') THEN
        ALTER TABLE atas_julgamento 
        ADD COLUMN fundamentacao_ccl TEXT;
        
        RAISE NOTICE '✅ Coluna fundamentacao_ccl adicionada à tabela atas_julgamento';
    ELSE
        RAISE NOTICE '⚠️ Coluna fundamentacao_ccl já existe na tabela atas_julgamento';
    END IF;

END $$;

-- Criar índice para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_atas_julgamento_processo_id 
ON atas_julgamento(processo_id);

CREATE INDEX IF NOT EXISTS idx_atas_julgamento_numero_processo 
ON atas_julgamento(numero_processo);

CREATE INDEX IF NOT EXISTS idx_atas_julgamento_tenant_processo 
ON atas_julgamento(tenant_id, processo_id);

-- Verificar estrutura da tabela após modificações
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'atas_julgamento' 
ORDER BY ordinal_position;

-- Exemplo de consulta que agora funciona com vinculação específica
/*
SELECT 
    a.numero as numero_ata,
    a.numero_processo,
    a.tipo_processo,
    a.decisao_ccl,
    p.numero_processo as processo_numero,
    p.objeto as processo_objeto
FROM atas_julgamento a
LEFT JOIN processos_administrativos p ON a.processo_id = p.id
WHERE a.tenant_id = 'seu-tenant-id'
ORDER BY a.data_publicacao DESC;
*/