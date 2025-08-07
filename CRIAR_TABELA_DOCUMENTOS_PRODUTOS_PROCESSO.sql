-- =====================================================
-- CRIAR TABELA PARA DOCUMENTOS DOS PRODUTOS NO PROCESSO
-- =====================================================

-- 1. Criar tabela para relacionar documentos dos produtos com processos
CREATE TABLE IF NOT EXISTS documentos_produtos_processo (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    processo_id UUID NOT NULL,
    produto_id UUID NOT NULL,
    documento_id UUID NOT NULL,
    tenant_id UUID NOT NULL DEFAULT auth.uid(),
    nome_documento TEXT NOT NULL,
    tipo_documento VARCHAR(100),
    url_documento TEXT,
    numero_sequencial INTEGER,
    folha_numero VARCHAR(20),
    adicionado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    criado_por UUID DEFAULT auth.uid(),
    
    -- Garantir que não haja duplicatas
    UNIQUE(processo_id, documento_id)
);

-- 2. Adicionar índices para performance
CREATE INDEX IF NOT EXISTS idx_doc_prod_proc_processo_id ON documentos_produtos_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_doc_prod_proc_produto_id ON documentos_produtos_processo(produto_id);
CREATE INDEX IF NOT EXISTS idx_doc_prod_proc_documento_id ON documentos_produtos_processo(documento_id);
CREATE INDEX IF NOT EXISTS idx_doc_prod_proc_tenant_id ON documentos_produtos_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_doc_prod_proc_sequencial ON documentos_produtos_processo(processo_id, numero_sequencial);

-- 3. Adicionar foreign key constraints se as tabelas existirem
DO $$
BEGIN
    -- FK para processos_administrativos
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'processos_administrativos') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_doc_prod_proc_processo_id'
        ) THEN
            ALTER TABLE documentos_produtos_processo 
            ADD CONSTRAINT fk_doc_prod_proc_processo_id 
            FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;
        END IF;
    END IF;
    
    -- FK para produtos
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'produtos') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_doc_prod_proc_produto_id'
        ) THEN
            ALTER TABLE documentos_produtos_processo 
            ADD CONSTRAINT fk_doc_prod_proc_produto_id 
            FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE;
        END IF;
    END IF;
    
    -- FK para documentos
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'documentos') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_doc_prod_proc_documento_id'
        ) THEN
            ALTER TABLE documentos_produtos_processo 
            ADD CONSTRAINT fk_doc_prod_proc_documento_id 
            FOREIGN KEY (documento_id) REFERENCES documentos(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- 4. Desabilitar RLS para evitar problemas
ALTER TABLE documentos_produtos_processo DISABLE ROW LEVEL SECURITY;

-- 5. Adicionar coluna na tabela produtos_prequalificacao para armazenar lista de documentos
ALTER TABLE produtos_prequalificacao ADD COLUMN IF NOT EXISTS documentos_adicionados JSONB DEFAULT '[]'::jsonb;

-- Adicionar comentário explicativo
COMMENT ON COLUMN produtos_prequalificacao.documentos_adicionados IS 'Array JSON com IDs dos documentos adicionados ao processo: ["doc-id-1", "doc-id-2"]';

-- 6. Criar função para obter documentos de um produto no processo
CREATE OR REPLACE FUNCTION obter_documentos_produto_processo(
    p_processo_id UUID,
    p_produto_id UUID
)
RETURNS TABLE (
    id UUID,
    nome_documento TEXT,
    tipo_documento VARCHAR,
    url_documento TEXT,
    numero_sequencial INTEGER,
    folha_numero VARCHAR,
    adicionado_em TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dpp.id,
        dpp.nome_documento,
        dpp.tipo_documento,
        dpp.url_documento,
        dpp.numero_sequencial,
        dpp.folha_numero,
        dpp.adicionado_em
    FROM documentos_produtos_processo dpp
    WHERE dpp.processo_id = p_processo_id 
    AND dpp.produto_id = p_produto_id
    ORDER BY dpp.numero_sequencial;
END;
$$ LANGUAGE plpgsql;

-- 7. Criar função para adicionar documento de produto ao processo
CREATE OR REPLACE FUNCTION adicionar_documento_produto_processo(
    p_processo_id UUID,
    p_produto_id UUID,
    p_documento_id UUID,
    p_nome_documento TEXT,
    p_tipo_documento VARCHAR DEFAULT 'Documento do Produto',
    p_url_documento TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
    v_proximo_sequencial INTEGER;
    v_tenant_id UUID;
BEGIN
    -- Obter tenant_id
    SELECT auth.uid() INTO v_tenant_id;
    
    -- Obter próximo número sequencial para o processo
    SELECT COALESCE(MAX(numero_sequencial), 0) + 1 
    INTO v_proximo_sequencial
    FROM documentos_produtos_processo 
    WHERE processo_id = p_processo_id;
    
    -- Inserir documento
    INSERT INTO documentos_produtos_processo (
        processo_id,
        produto_id,
        documento_id,
        tenant_id,
        nome_documento,
        tipo_documento,
        url_documento,
        numero_sequencial,
        folha_numero
    ) VALUES (
        p_processo_id,
        p_produto_id,
        p_documento_id,
        v_tenant_id,
        p_nome_documento,
        p_tipo_documento,
        p_url_documento,
        v_proximo_sequencial,
        'Fl. ' || LPAD(v_proximo_sequencial::TEXT, 3, '0')
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Verificações finais
SELECT 'Tabela documentos_produtos_processo criada com sucesso!' as resultado;

-- Mostrar estrutura da tabela
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'documentos_produtos_processo' 
ORDER BY ordinal_position;

-- Mostrar função criada
SELECT 'Funções criadas:' as info;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%documento%produto%processo%'
ORDER BY routine_name;

-- Verificar se coluna foi adicionada
SELECT 'Coluna documentos_adicionados adicionada em produtos_prequalificacao:' as info;
SELECT 
    column_name,
    data_type,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao' 
AND column_name = 'documentos_adicionados';

SELECT 'SCRIPT EXECUTADO COM SUCESSO! ✅' as final_status;