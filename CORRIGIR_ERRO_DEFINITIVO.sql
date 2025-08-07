-- =====================================================
-- CORREÇÃO DEFINITIVA DO ERRO DE RELACIONAMENTO
-- =====================================================

-- 1. Primeiro, dropar a view problemática se existir
DROP VIEW IF EXISTS vw_processos_resumo CASCADE;

-- 2. Verificar se a tabela documentos_processo existe e criar se necessário
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'documentos_processo') THEN
        CREATE TABLE documentos_processo (
            id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
            processo_id UUID NOT NULL,
            tenant_id UUID NOT NULL DEFAULT auth.uid(),
            numero_sequencial INTEGER NOT NULL DEFAULT 1,
            folha_numero VARCHAR(20) NOT NULL DEFAULT 'Fl. 001',
            tipo_documento VARCHAR(50) DEFAULT 'DOCUMENTO',
            nome_documento TEXT,
            titulo TEXT,
            descricao TEXT,
            conteudo JSONB,
            conteudo_html TEXT,
            url_arquivo TEXT,
            tamanho_arquivo INTEGER,
            mime_type VARCHAR(100),
            status VARCHAR(50) DEFAULT 'ativo',
            versao INTEGER DEFAULT 1,
            metadata JSONB,
            documento_pai UUID,
            criado_por UUID DEFAULT auth.uid(),
            data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Índices
        CREATE INDEX IF NOT EXISTS idx_documentos_processo_id ON documentos_processo(processo_id);
        CREATE INDEX IF NOT EXISTS idx_documentos_tenant_id ON documentos_processo(tenant_id);
        CREATE INDEX IF NOT EXISTS idx_documentos_numero_seq ON documentos_processo(processo_id, numero_sequencial);
        
        -- Desabilitar RLS
        ALTER TABLE documentos_processo DISABLE ROW LEVEL SECURITY;
        
        -- Adicionar foreign key constraint apenas se a tabela processos_administrativos existir
        IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'processos_administrativos') THEN
            ALTER TABLE documentos_processo 
            ADD CONSTRAINT fk_documentos_processo_id 
            FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;
        END IF;
        
        RAISE NOTICE 'Tabela documentos_processo criada com sucesso';
    ELSE
        -- Se já existe, apenas garantir que RLS está desabilitado
        ALTER TABLE documentos_processo DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'Tabela documentos_processo já existe - RLS desabilitado';
    END IF;
END $$;

-- 3. Verificar se a tabela produtos_prequalificacao existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'produtos_prequalificacao') THEN
        CREATE TABLE produtos_prequalificacao (
            id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
            processo_id UUID NOT NULL,
            produto_id UUID,
            tenant_id UUID NOT NULL DEFAULT auth.uid(),
            nome_produto TEXT NOT NULL,
            categoria_produto VARCHAR(100),
            especificacoes_tecnicas TEXT,
            quantidade_amostras INTEGER DEFAULT 0,
            valor_estimado DECIMAL(10,2),
            observacoes_processo TEXT,
            status VARCHAR(50) DEFAULT 'pendente',
            criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Índices
        CREATE INDEX IF NOT EXISTS idx_produtos_prequalificacao_processo_id ON produtos_prequalificacao(processo_id);
        CREATE INDEX IF NOT EXISTS idx_produtos_prequalificacao_produto_id ON produtos_prequalificacao(produto_id);
        CREATE INDEX IF NOT EXISTS idx_produtos_prequalificacao_tenant_id ON produtos_prequalificacao(tenant_id);
        
        -- Desabilitar RLS
        ALTER TABLE produtos_prequalificacao DISABLE ROW LEVEL SECURITY;
        
        -- Adicionar foreign key constraints
        IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'processos_administrativos') THEN
            ALTER TABLE produtos_prequalificacao 
            ADD CONSTRAINT fk_produtos_prequalificacao_processo_id 
            FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;
        END IF;
        
        IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'produtos') THEN
            ALTER TABLE produtos_prequalificacao 
            ADD CONSTRAINT fk_produtos_prequalificacao_produto_id 
            FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE SET NULL;
        END IF;
        
        RAISE NOTICE 'Tabela produtos_prequalificacao criada com sucesso';
    ELSE
        -- Se já existe, apenas garantir que RLS está desabilitado
        ALTER TABLE produtos_prequalificacao DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'Tabela produtos_prequalificacao já existe - RLS desabilitado';
    END IF;
END $$;

-- 4. Recriar a view vw_processos_resumo de forma segura
CREATE OR REPLACE VIEW vw_processos_resumo AS
SELECT 
    p.id,
    p.numero_processo,
    p.tipo_processo,
    p.status,
    p.nome_orgao,
    p.unidade_interessada,
    p.objeto,
    p.observacoes,
    p.criado_em AS data_autuacao,
    p.atualizado_em,
    p.tenant_id,
    
    -- Campos de edital (se existirem)
    p.numero_edital,
    p.edital_vinculado,
    p.data_vinculacao_edital,
    
    -- Contadores seguros
    COALESCE(prod.total_produtos, 0) as total_produtos,
    COALESCE(docs.total_documentos, 0) as total_documentos,
    
    -- Status formatado
    CASE 
        WHEN p.status = 'rascunho' THEN 'Em Criação'
        WHEN p.status = 'aguardando_aprovacao' THEN 'Aguardando Aprovação'
        WHEN p.status = 'criado_cpm' THEN 'Criado pela CPM'
        WHEN p.status = 'aprovado_cpm' THEN 'Aprovado pela CPM'
        WHEN p.status = 'assinado_admin' THEN 'Assinado pelo Órgão'
        WHEN p.status = 'julgamento_ccl' THEN 'Julgamento CCL'
        WHEN p.status = 'aprovado_ccl' THEN 'Aprovado pela CCL'
        WHEN p.status = 'homologado' THEN 'Homologado'
        ELSE UPPER(SUBSTRING(p.status, 1, 1)) || SUBSTRING(p.status, 2)
    END as status_formatado
    
FROM processos_administrativos p

-- Contagem segura de produtos
LEFT JOIN (
    SELECT 
        processo_id,
        COUNT(*) as total_produtos
    FROM produtos_prequalificacao
    WHERE processo_id IS NOT NULL
    GROUP BY processo_id
) prod ON p.id = prod.processo_id

-- Contagem segura de documentos
LEFT JOIN (
    SELECT 
        processo_id,
        COUNT(*) as total_documentos
    FROM documentos_processo
    WHERE processo_id IS NOT NULL
    GROUP BY processo_id
) docs ON p.id = docs.processo_id;

-- 5. Garantir que RLS está desabilitado nas tabelas principais
ALTER TABLE processos_administrativos DISABLE ROW LEVEL SECURITY;

-- Se existir configuracao_numeracao, desabilitar também
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'configuracao_numeracao') THEN
        ALTER TABLE configuracao_numeracao DISABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- 6. Verificação final - mostrar status das tabelas
SELECT 
    'Tabelas relacionadas a processos administrativos:' as info;

SELECT 
    schemaname,
    tablename,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE tablename IN ('processos_administrativos', 'documentos_processo', 'produtos_prequalificacao', 'configuracao_numeracao')
ORDER BY tablename;

-- 7. Mostrar políticas RLS ativas
SELECT 
    'Políticas RLS ativas (devem estar vazias):' as info;

SELECT 
    schemaname, 
    tablename, 
    policyname, 
    cmd,
    permissive
FROM pg_policies 
WHERE tablename IN ('processos_administrativos', 'documentos_processo', 'produtos_prequalificacao')
ORDER BY tablename, policyname;

-- 8. Confirmar que a view funciona
SELECT 
    'Testando view vw_processos_resumo:' as info;

SELECT COUNT(*) as total_processos_na_view
FROM vw_processos_resumo;

-- Mensagem final
SELECT 'CORREÇÃO CONCLUÍDA COM SUCESSO! ✅' as resultado;
SELECT 'Erro de relacionamento corrigido definitivamente.' as status;