-- Script atualizado para inserir manual do sistema
-- Baseado na estrutura existente da tabela documentos_administrativos

-- 1. Primeiro, permitir NULL em tenant_id e usuario_id para documentos globais
ALTER TABLE documentos_administrativos 
ALTER COLUMN tenant_id DROP NOT NULL;

ALTER TABLE documentos_administrativos 
ALTER COLUMN usuario_id DROP NOT NULL;

-- 2. Permitir nome_arquivo NULL (alguns documentos podem ser só texto interno)
ALTER TABLE documentos_administrativos 
ALTER COLUMN nome_arquivo DROP NOT NULL;

-- 3. Adicionar status 'rascunho' se não existir no constraint
DO $$
BEGIN
    -- Remover constraint antigo
    ALTER TABLE documentos_administrativos DROP CONSTRAINT IF EXISTS documentos_administrativos_status_check;
    
    -- Criar novo constraint com 'rascunho'
    ALTER TABLE documentos_administrativos ADD CONSTRAINT documentos_administrativos_status_check 
    CHECK (status = ANY (ARRAY['ativo'::text, 'inativo'::text, 'arquivado'::text, 'rascunho'::text]));
EXCEPTION 
    WHEN others THEN
        -- Se der erro, só ignora (constraint já pode ter sido alterado)
        NULL;
END $$;

-- 4. Criar índices se não existirem
CREATE INDEX IF NOT EXISTS idx_documentos_administrativos_tenant ON documentos_administrativos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documentos_administrativos_categoria ON documentos_administrativos(categoria);
CREATE INDEX IF NOT EXISTS idx_documentos_administrativos_status ON documentos_administrativos(status);
CREATE INDEX IF NOT EXISTS idx_documentos_administrativos_visibilidade ON documentos_administrativos(visibilidade);
CREATE INDEX IF NOT EXISTS idx_documentos_administrativos_criado_em ON documentos_administrativos(criado_em DESC);

-- 5. Inserir documentos globais do sistema
-- Estes documentos aparecerão para todos os tenants

-- Manual do Sistema Comprar Bem
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL, -- Global - aparece para todos
    NULL, -- Documento do sistema
    '📖 Manual do Sistema Comprar Bem',
    'Manual completo de utilização do sistema Comprar Bem para pré-qualificação de bens em compras públicas. Inclui instruções detalhadas sobre todos os módulos: Dashboard CPM, Dashboard CCL, Cadastro de Produtos, Análise Técnica, Julgamento, DCB, RDM, Catálogo e Classificação de Bens.',
    'manual',
    'manual_sistema_comprar_bem.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['manual', 'tutorial', 'sistema', 'comprar-bem', 'cpm', 'ccl', 'dcb', 'rdm'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Template de DCB
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '📄 Template - Declaração de Conformidade de Bem (DCB)',
    'Template padrão para emissão de DCB conforme as normas vigentes de compras públicas. Inclui todos os campos obrigatórios, formatação adequada e instruções de preenchimento.',
    'template',
    'template_dcb.docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'publico',
    'ativo',
    ARRAY['dcb', 'template', 'declaracao', 'conformidade', 'padrao'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Instruções para CPM
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '📋 Instruções para Análise Técnica - CPM',
    'Guia completo para membros da Comissão de Padronização de Materiais (CPM) realizarem análise técnica de produtos. Inclui critérios de avaliação, documentação necessária, fluxo de aprovação e modelos de parecer técnico.',
    'instrucao',
    'instrucoes_analise_cpm.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['cpm', 'analise', 'tecnica', 'instrucoes', 'avaliacao', 'parecer'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Instruções para CCL
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '📋 Instruções para Julgamento - CCL',
    'Manual para membros da Comissão de Contratação e Licitação (CCL) sobre o processo de julgamento, análise de recursos, homologação de produtos pré-qualificados e emissão de pareceres finais.',
    'instrucao',
    'instrucoes_julgamento_ccl.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['ccl', 'julgamento', 'recursos', 'homologacao', 'instrucoes', 'parecer'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Lei 14.133/2021
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '⚖️ Lei 14.133/2021 - Nova Lei de Licitações e Contratos',
    'Texto completo da Lei Federal 14.133/2021 que estabelece normas gerais de licitação e contratação para as administrações públicas diretas, autárquicas e fundacionais da União, Estados, Distrito Federal e Municípios.',
    'normativa',
    'lei_14133_2021_completa.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['lei', 'licitacao', '14133', '2021', 'normativa', 'legislacao', 'contratos'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Formulário RDM
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '📝 Formulário RDM - Relatório de Desempenho de Material',
    'Formulário padrão para avaliação de desempenho de materiais adquiridos através do sistema. Utilizado para feedback pós-compra, controle de qualidade e melhoria contínua dos processos de aquisição.',
    'formulario',
    'formulario_rdm_padrao.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'publico',
    'ativo',
    ARRAY['rdm', 'formulario', 'avaliacao', 'desempenho', 'material', 'feedback'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Instruções Gerais do Sistema
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '📋 Guia Rápido - Primeiros Passos no Sistema',
    'Guia de início rápido para novos usuários do sistema Comprar Bem. Inclui login, navegação básica, principais funcionalidades e dicas importantes para começar a usar o sistema eficientemente.',
    'instrucao',
    'guia_rapido_primeiros_passos.pdf',
    'application/pdf',
    'publico',
    'ativo',
    ARRAY['guia', 'inicio', 'rapido', 'tutorial', 'basico', 'primeiros-passos'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Template de Análise Técnica
INSERT INTO documentos_administrativos (
    id,
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
    criado_em,
    atualizado_em
) VALUES (
    gen_random_uuid(),
    NULL,
    NULL,
    '📄 Template - Parecer Técnico CPM',
    'Template padronizado para elaboração de pareceres técnicos pela CPM. Inclui estrutura padrão, campos obrigatórios, critérios de avaliação e modelos de conclusão técnica.',
    'template',
    'template_parecer_tecnico_cpm.docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'publico',
    'ativo',
    ARRAY['template', 'parecer', 'tecnico', 'cpm', 'analise', 'padrao'],
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Verificar se foi inserido corretamente
SELECT 
    titulo,
    categoria,
    visibilidade,
    status,
    array_length(tags, 1) as num_tags,
    criado_em
FROM documentos_administrativos 
WHERE tenant_id IS NULL 
AND usuario_id IS NULL
ORDER BY categoria, titulo;