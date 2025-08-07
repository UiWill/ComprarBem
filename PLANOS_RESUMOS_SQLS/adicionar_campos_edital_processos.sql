-- =====================================================
-- ADICIONAR CAMPOS PARA VINCULAÇÃO DE EDITAL EM PROCESSOS ADMINISTRATIVOS
-- =====================================================

-- Adicionar colunas para gestão de editais no processo
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS numero_edital VARCHAR(20),
ADD COLUMN IF NOT EXISTS ano_edital INTEGER,
ADD COLUMN IF NOT EXISTS edital_pdf_url TEXT,
ADD COLUMN IF NOT EXISTS edital_vinculado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS data_vinculacao_edital TIMESTAMP;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_processos_numero_edital ON processos_administrativos(numero_edital, ano_edital);
CREATE INDEX IF NOT EXISTS idx_processos_edital_vinculado ON processos_administrativos(edital_vinculado);

-- =====================================================
-- CRIAR TABELA PARA ARQUIVOS DE PRODUTOS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS arquivos_produto (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    nome_arquivo VARCHAR(255) NOT NULL,
    tipo_arquivo VARCHAR(50) NOT NULL,
    tamanho INTEGER NOT NULL,
    url_arquivo TEXT NOT NULL,
    data_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tenant_id UUID NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_arquivos_produto_tenant FOREIGN KEY (tenant_id) 
    REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Criar políticas RLS para arquivos_produto
ALTER TABLE arquivos_produto ENABLE ROW LEVEL SECURITY;

-- Política para isolamento por tenant
CREATE POLICY "Arquivos produtos isolados por tenant" ON arquivos_produto
    FOR ALL 
    USING (tenant_id = auth.uid());

-- =====================================================
-- ATUALIZAR VIEW DE PROCESSOS (se existir)
-- =====================================================

DROP VIEW IF EXISTS vw_processos_resumo CASCADE;

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
    
    -- Campos de edital
    p.numero_edital,
    p.ano_edital,
    p.edital_vinculado,
    p.data_vinculacao_edital,
    
    -- Contadores
    COALESCE(prod.total_produtos, 0) as total_produtos,
    COALESCE(docs.total_documentos, 0) as total_documentos,
    
    -- Status formatado
    CASE 
        WHEN p.status = 'rascunho' THEN 'Em Criação'
        WHEN p.status = 'criado_cpm' THEN 'Criado pela CPM'
        WHEN p.status = 'aprovado_cpm' THEN 'Aprovado pela CPM'
        WHEN p.status = 'assinado_admin' THEN 'Assinado pelo Órgão'
        WHEN p.status = 'julgamento_ccl' THEN 'Julgamento CCL'
        WHEN p.status = 'aprovado_ccl' THEN 'Aprovado pela CCL'
        WHEN p.status = 'homologado' THEN 'Homologado'
        ELSE UPPER(SUBSTRING(p.status, 1, 1)) || SUBSTRING(p.status, 2)
    END as status_formatado
    
FROM processos_administrativos p

-- Contagem de produtos
LEFT JOIN (
    SELECT 
        processo_id,
        COUNT(*) as total_produtos
    FROM produtos_prequalificacao
    GROUP BY processo_id
) prod ON p.id = prod.processo_id

-- Contagem de documentos
LEFT JOIN (
    SELECT 
        processo_id,
        COUNT(*) as total_documentos
    FROM documentos_processo
    GROUP BY processo_id
) docs ON p.id = docs.processo_id;

-- =====================================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =====================================================

COMMENT ON COLUMN processos_administrativos.numero_edital IS 'Número do edital vinculado (formato XXX/YYYY)';
COMMENT ON COLUMN processos_administrativos.ano_edital IS 'Ano do edital vinculado';
COMMENT ON COLUMN processos_administrativos.edital_pdf_url IS 'URL do arquivo PDF do edital armazenado no Supabase Storage';
COMMENT ON COLUMN processos_administrativos.edital_vinculado IS 'Indica se há edital PDF vinculado ao processo';
COMMENT ON COLUMN processos_administrativos.data_vinculacao_edital IS 'Data/hora em que o edital foi vinculado';

COMMENT ON TABLE arquivos_produto IS 'Armazena arquivos PDF e documentos anexados aos produtos';
COMMENT ON COLUMN arquivos_produto.produto_id IS 'Referência ao produto (FK para produtos.id)';
COMMENT ON COLUMN arquivos_produto.nome_arquivo IS 'Nome original do arquivo enviado';
COMMENT ON COLUMN arquivos_produto.tipo_arquivo IS 'Tipo MIME do arquivo (ex: application/pdf)';
COMMENT ON COLUMN arquivos_produto.tamanho IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN arquivos_produto.url_arquivo IS 'URL pública do arquivo no Supabase Storage';

-- =====================================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- =====================================================

-- Exemplo de como ficará um processo com edital vinculado:
/*
UPDATE processos_administrativos 
SET 
    numero_edital = '001/2024',
    ano_edital = 2024,
    edital_vinculado = TRUE,
    data_vinculacao_edital = CURRENT_TIMESTAMP
WHERE numero_processo = 'PROC001/2024';
*/

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se as colunas foram adicionadas
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name IN ('numero_edital', 'ano_edital', 'edital_pdf_url', 'edital_vinculado', 'data_vinculacao_edital')
ORDER BY ordinal_position;

-- Verificar se a tabela arquivos_produto foi criada
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'arquivos_produto' 
ORDER BY ordinal_position;

PRINT 'Campos para vinculação de edital adicionados com sucesso!';
PRINT 'Tabela arquivos_produto criada para documentação dos produtos.';
PRINT 'View vw_processos_resumo atualizada com novos campos.';