-- Script para inserir o Manual do Sistema como documento padrão
-- Este manual será visível para todos os tenants

-- Primeiro, verificar se a tabela documentos_administrativos existe
-- Se não existir, criar a estrutura básica

DO $$
BEGIN
    -- Verificar se a tabela existe
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'documentos_administrativos') THEN
        
        -- Criar tabela documentos_administrativos
        CREATE TABLE documentos_administrativos (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            tenant_id UUID REFERENCES auth.users(id),
            usuario_id UUID REFERENCES auth.users(id),
            titulo TEXT NOT NULL,
            descricao TEXT,
            categoria TEXT NOT NULL CHECK (categoria IN ('manual', 'template', 'instrucao', 'normativa', 'formulario')),
            nome_arquivo TEXT,
            tamanho_arquivo BIGINT,
            tipo_mime TEXT,
            url_arquivo TEXT,
            visibilidade TEXT DEFAULT 'publico' CHECK (visibilidade IN ('publico', 'privado', 'restrito')),
            status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'arquivado', 'rascunho')),
            tags TEXT[],
            metadata JSONB DEFAULT '{}',
            criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        -- Criar índices
        CREATE INDEX idx_documentos_administrativos_tenant ON documentos_administrativos(tenant_id);
        CREATE INDEX idx_documentos_administrativos_categoria ON documentos_administrativos(categoria);
        CREATE INDEX idx_documentos_administrativos_status ON documentos_administrativos(status);
        CREATE INDEX idx_documentos_administrativos_criado_em ON documentos_administrativos(criado_em DESC);

        -- Trigger para atualizar updated_at
        CREATE OR REPLACE FUNCTION update_documentos_administrativos_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.atualizado_em = NOW();
            RETURN NEW;
        END;
        $$ language 'plpgsql';

        CREATE TRIGGER update_documentos_administrativos_updated_at
            BEFORE UPDATE ON documentos_administrativos
            FOR EACH ROW
            EXECUTE FUNCTION update_documentos_administrativos_updated_at();

        -- Políticas RLS
        ALTER TABLE documentos_administrativos ENABLE ROW LEVEL SECURITY;

        -- Política para leitura (usuários podem ver documentos públicos e seus próprios)
        CREATE POLICY "Users can view public documents and own documents" ON documentos_administrativos
            FOR SELECT USING (
                visibilidade = 'publico' OR 
                (auth.uid() IS NOT NULL AND tenant_id = auth.uid()) OR
                (auth.uid() IS NOT NULL AND usuario_id = auth.uid())
            );

        -- Política para inserção (usuários autenticados podem inserir)
        CREATE POLICY "Authenticated users can insert documents" ON documentos_administrativos
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

        -- Política para atualização (apenas proprietários)
        CREATE POLICY "Users can update own documents" ON documentos_administrativos
            FOR UPDATE USING (auth.uid() = usuario_id);

        -- Política para exclusão (apenas proprietários)
        CREATE POLICY "Users can delete own documents" ON documentos_administrativos
            FOR DELETE USING (auth.uid() = usuario_id);

    END IF;
END $$;

-- Inserir o Manual do Sistema como documento global
-- Este documento será visível para todos os tenants (visibilidade = 'publico')

INSERT INTO documentos_administrativos (
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    metadata
) VALUES (
    NULL, -- tenant_id NULL para documento global
    NULL, -- usuario_id NULL para documento do sistema
    '📖 Manual do Sistema Comprar Bem',
    'Manual completo de utilização do sistema Comprar Bem - Pré-qualificação de bens para compras públicas. Inclui instruções detalhadas sobre todos os módulos: CPM, CCL, DCB, RDM, Catálogo e Classificação de Bens.',
    'manual',
    'manual_sistema_comprar_bem.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['manual', 'tutorial', 'sistema', 'comprar-bem', 'cpm', 'ccl', 'dcb', 'rdm'],
    '{
        "autor": "Sistema Comprar Bem",
        "versao": "1.0",
        "data_atualizacao": "2025-01-25",
        "modulos_cobertos": ["Dashboard CPM", "Dashboard CCL", "Cadastro de Produtos", "Análise Técnica", "Julgamento", "DCB", "RDM", "Catálogo", "Classificação"],
        "tipo_conteudo": "manual_sistema",
        "nivel_acesso": "todos_usuarios"
    }'::jsonb
) ON CONFLICT DO NOTHING;

-- Inserir outros documentos úteis para processos administrativos

-- Template de DCB
INSERT INTO documentos_administrativos (
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    metadata
) VALUES (
    NULL,
    NULL,
    '📄 Template - Declaração de Conformidade de Bem (DCB)',
    'Template padrão para emissão de DCB conforme as normas vigentes. Inclui todos os campos obrigatórios e formatação adequada.',
    'template',
    'template_dcb.docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'publico',
    'ativo',
    ARRAY['dcb', 'template', 'declaracao', 'conformidade'],
    '{
        "tipo_documento": "dcb",
        "versao_template": "2.0",
        "campos_obrigatorios": ["produto", "especificacoes", "fornecedor", "certificacoes"],
        "formato": "docx"
    }'::jsonb
) ON CONFLICT DO NOTHING;

-- Instruções para CPM
INSERT INTO documentos_administrativos (
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    metadata
) VALUES (
    NULL,
    NULL,
    '📋 Instruções para Análise CPM',
    'Guia completo para membros da CPM realizarem análise técnica de produtos. Inclui critérios de avaliação, documentação necessária e fluxo de aprovação.',
    'instrucao',
    'instrucoes_analise_cpm.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['cpm', 'analise', 'tecnica', 'instrucoes', 'avaliacao'],
    '{
        "publico_alvo": "membros_cpm",
        "processo": "analise_tecnica",
        "etapas": ["recebimento", "analise_documental", "avaliacao_tecnica", "emissao_parecer"]
    }'::jsonb
) ON CONFLICT DO NOTHING;

-- Instruções para CCL
INSERT INTO documentos_administrativos (
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    metadata
) VALUES (
    NULL,
    NULL,
    '📋 Instruções para Julgamento CCL',
    'Manual para membros da CCL sobre o processo de julgamento, análise de recursos e homologação de produtos pré-qualificados.',
    'instrucao',
    'instrucoes_julgamento_ccl.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['ccl', 'julgamento', 'recursos', 'homologacao', 'instrucoes'],
    '{
        "publico_alvo": "membros_ccl",
        "processo": "julgamento",
        "etapas": ["analise_parecer_cpm", "julgamento", "analise_recursos", "homologacao"]
    }'::jsonb
) ON CONFLICT DO NOTHING;

-- Normativas e Legislação
INSERT INTO documentos_administrativos (
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    metadata
) VALUES (
    NULL,
    NULL,
    '⚖️ Lei 14.133/2021 - Nova Lei de Licitações',
    'Texto completo da Lei Federal 14.133/2021 que estabelece normas gerais de licitação e contratação para as administrações públicas.',
    'normativa',
    'lei_14133_2021.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['lei', 'licitacao', '14133', 'normativa', 'legislacao'],
    '{
        "tipo_normativa": "lei_federal",
        "numero": "14.133",
        "ano": "2021",
        "assunto": "licitacoes_contratos_publicos"
    }'::jsonb
) ON CONFLICT DO NOTHING;

-- Formulário de RDM
INSERT INTO documentos_administrativos (
    tenant_id,
    usuario_id,
    titulo,
    descricao,
    categoria,
    nome_arquivo,
    tipo_mime,
    visibilidade,
    status,
    tags,
    metadata
) VALUES (
    NULL,
    NULL,
    '📝 Formulário RDM - Relatório de Desempenho de Material',
    'Formulário padrão para avaliação de desempenho de materiais adquiridos. Utilizado para feedback pós-compra e melhoria contínua.',
    'formulario',
    'formulario_rdm.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'publico',
    'ativo',
    ARRAY['rdm', 'formulario', 'avaliacao', 'desempenho', 'material'],
    '{
        "tipo_formulario": "rdm",
        "campos": ["identificacao_produto", "avaliacao_qualidade", "avaliacao_entrega", "observacoes"],
        "formato": "xlsx"
    }'::jsonb
) ON CONFLICT DO NOTHING;

-- Verificar se os documentos foram inseridos
SELECT 
    titulo,
    categoria,
    visibilidade,
    status,
    criado_em
FROM documentos_administrativos 
WHERE usuario_id IS NULL 
AND tenant_id IS NULL
ORDER BY criado_em DESC;