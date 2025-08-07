-- =====================================================
-- ADICIONAR CAMPOS PARA VINCULAÇÃO DE EDITAL EM PROCESSOS ADMINISTRATIVOS
-- VERSÃO CORRIGIDA - SEM ERROS
-- =====================================================

-- 1. Adicionar colunas para gestão de editais no processo
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS numero_edital VARCHAR(20),
ADD COLUMN IF NOT EXISTS ano_edital INTEGER,
ADD COLUMN IF NOT EXISTS edital_pdf_url TEXT,
ADD COLUMN IF NOT EXISTS edital_vinculado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS data_vinculacao_edital TIMESTAMP;

-- 2. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_processos_numero_edital ON processos_administrativos(numero_edital, ano_edital);
CREATE INDEX IF NOT EXISTS idx_processos_edital_vinculado ON processos_administrativos(edital_vinculado);

-- 3. Criar tabela para arquivos de produtos (documentação PDF)
CREATE TABLE IF NOT EXISTS arquivos_produto (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    nome_arquivo VARCHAR(255) NOT NULL,
    tipo_arquivo VARCHAR(50) NOT NULL DEFAULT 'application/pdf',
    tamanho INTEGER NOT NULL,
    url_arquivo TEXT NOT NULL,
    data_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tenant_id UUID NOT NULL DEFAULT auth.uid(),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Habilitar RLS na nova tabela
ALTER TABLE arquivos_produto ENABLE ROW LEVEL SECURITY;

-- 5. Criar política RLS simples e funcional
CREATE POLICY "Enable all for authenticated users based on tenant_id" ON arquivos_produto
    FOR ALL USING (tenant_id = auth.uid());

-- 6. Atualizar view de processos (se existir)
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
    
    -- Campos de edital (NOVOS)
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

-- 7. Adicionar comentários para documentação
COMMENT ON COLUMN processos_administrativos.numero_edital IS 'Número do edital vinculado (formato XXX/YYYY)';
COMMENT ON COLUMN processos_administrativos.ano_edital IS 'Ano do edital vinculado';
COMMENT ON COLUMN processos_administrativos.edital_pdf_url IS 'URL do arquivo PDF do edital no Supabase Storage';
COMMENT ON COLUMN processos_administrativos.edital_vinculado IS 'Indica se há edital PDF vinculado ao processo';
COMMENT ON COLUMN processos_administrativos.data_vinculacao_edital IS 'Data/hora em que o edital foi vinculado';

COMMENT ON TABLE arquivos_produto IS 'Armazena documentos PDF anexados aos produtos';
COMMENT ON COLUMN arquivos_produto.produto_id IS 'Referência ao produto (FK para produtos.id)';
COMMENT ON COLUMN arquivos_produto.nome_arquivo IS 'Nome original do arquivo enviado';
COMMENT ON COLUMN arquivos_produto.tipo_arquivo IS 'Tipo MIME do arquivo (padrão: application/pdf)';
COMMENT ON COLUMN arquivos_produto.tamanho IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN arquivos_produto.url_arquivo IS 'URL pública do arquivo no Supabase Storage';

-- 8. Verificação final - mostrar estrutura criada
SELECT 'Colunas adicionadas em processos_administrativos:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name IN ('numero_edital', 'ano_edital', 'edital_pdf_url', 'edital_vinculado', 'data_vinculacao_edital')
ORDER BY ordinal_position;

SELECT 'Tabela arquivos_produto criada:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'arquivos_produto' 
ORDER BY ordinal_position;

-- FIM DO SCRIPT
SELECT 'Script executado com sucesso! ✅' as resultado;
SELECT 'Agora você pode usar as funcionalidades de edital e documentação.' as proximo_passo;