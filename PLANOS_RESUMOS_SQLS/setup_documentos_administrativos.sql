-- ===================================================
-- Script de criação da tabela documentos_administrativos
-- Sistema Comprar Bem - Módulo de Processos Administrativos
-- ===================================================

-- Criar tabela para documentos administrativos
CREATE TABLE IF NOT EXISTS documentos_administrativos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    
    -- Informações básicas do documento
    titulo TEXT NOT NULL,
    descricao TEXT,
    categoria TEXT NOT NULL CHECK (categoria IN (
        'manual', 'template', 'instrucao', 'normativa', 'formulario'
    )),
    
    -- Metadados do arquivo
    nome_arquivo TEXT NOT NULL,
    tamanho_arquivo BIGINT,
    tipo_mime TEXT,
    url_arquivo TEXT, -- URL no Supabase Storage
    
    -- Controle de acesso
    visibilidade TEXT DEFAULT 'privado' CHECK (visibilidade IN (
        'publico', 'privado', 'restrito'
    )),
    
    -- Status e controle
    status TEXT DEFAULT 'ativo' CHECK (status IN (
        'ativo', 'inativo', 'arquivado'
    )),
    
    -- Metadados adicionais
    tags TEXT[], -- Array de tags para facilitar busca
    metadados JSONB, -- Campos extras específicos por categoria
    
    -- Timestamps padrão
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===================================================
-- Índices para performance
-- ===================================================

CREATE INDEX IF NOT EXISTS idx_docs_admin_tenant 
    ON documentos_administrativos(tenant_id);

CREATE INDEX IF NOT EXISTS idx_docs_admin_usuario 
    ON documentos_administrativos(usuario_id);

CREATE INDEX IF NOT EXISTS idx_docs_admin_categoria 
    ON documentos_administrativos(categoria);

CREATE INDEX IF NOT EXISTS idx_docs_admin_status 
    ON documentos_administrativos(status);

CREATE INDEX IF NOT EXISTS idx_docs_admin_visibilidade 
    ON documentos_administrativos(visibilidade);

CREATE INDEX IF NOT EXISTS idx_docs_admin_titulo 
    ON documentos_administrativos USING gin(to_tsvector('portuguese', titulo));

CREATE INDEX IF NOT EXISTS idx_docs_admin_tags 
    ON documentos_administrativos USING gin(tags);

CREATE INDEX IF NOT EXISTS idx_docs_admin_criado 
    ON documentos_administrativos(criado_em DESC);

-- ===================================================
-- Row Level Security (RLS)
-- ===================================================

ALTER TABLE documentos_administrativos ENABLE ROW LEVEL SECURITY;

-- Política para isolamento por tenant
CREATE POLICY "tenant_isolation_docs_admin" ON documentos_administrativos
    FOR ALL TO public 
    USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

-- Política adicional para documentos públicos (se necessário)
CREATE POLICY "public_docs_access" ON documentos_administrativos
    FOR SELECT TO public 
    USING (visibilidade = 'publico');

-- ===================================================
-- Triggers e Funções
-- ===================================================

-- Função para atualizar timestamp (se não existir)
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualização automática de timestamp
CREATE TRIGGER update_docs_admin_timestamp 
    BEFORE UPDATE ON documentos_administrativos 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ===================================================
-- Inserção de dados exemplo (opcional)
-- ===================================================

-- Dados de exemplo para teste (remover em produção)
/*
INSERT INTO documentos_administrativos (
    tenant_id, usuario_id, titulo, descricao, categoria, 
    nome_arquivo, tamanho_arquivo, tipo_mime, tags
) VALUES 
(
    'uuid-do-tenant-exemplo', 
    'uuid-do-usuario-exemplo',
    'Manual de Licitações 2024',
    'Manual completo para processos de licitação conforme nova legislação',
    'manual',
    'manual_licitacoes_2024.pdf',
    2048576, -- 2MB
    'application/pdf',
    ARRAY['licitacao', 'manual', '2024', 'legislacao']
),
(
    'uuid-do-tenant-exemplo', 
    'uuid-do-usuario-exemplo',
    'Template - Termo de Referência',
    'Template padrão para elaboração de termos de referência',
    'template',
    'template_termo_referencia.docx',
    512000, -- 500KB
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ARRAY['template', 'termo', 'referencia']
);
*/

-- ===================================================
-- Grants e Permissões (ajustar conforme necessário)
-- ===================================================

-- Garantir acesso para usuários autenticados
GRANT ALL ON documentos_administrativos TO authenticated;
GRANT ALL ON documentos_administrativos TO service_role;

-- ===================================================
-- Comentários nas colunas para documentação
-- ===================================================

COMMENT ON TABLE documentos_administrativos IS 
'Tabela para armazenar documentos administrativos do sistema de processos';

COMMENT ON COLUMN documentos_administrativos.titulo IS 
'Título/nome do documento';

COMMENT ON COLUMN documentos_administrativos.categoria IS 
'Categoria do documento: manual, template, instrucao, normativa, formulario';

COMMENT ON COLUMN documentos_administrativos.visibilidade IS 
'Controle de acesso: publico, privado, restrito';

COMMENT ON COLUMN documentos_administrativos.tags IS 
'Array de tags para facilitar busca e categorização';

COMMENT ON COLUMN documentos_administrativos.metadados IS 
'Campos adicionais específicos por categoria em formato JSON';

-- ===================================================
-- Verificação final
-- ===================================================

-- Verificar se a tabela foi criada corretamente
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'documentos_administrativos'
ORDER BY ordinal_position;

-- Verificar índices criados
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'documentos_administrativos';

-- Verificar políticas RLS
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'documentos_administrativos';

-- ===================================================
-- Script finalizado
-- ===================================================