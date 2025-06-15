-- ================================================================================================
-- 🚀 SQL PARA COMPLETAR BANCO DE DADOS - SISTEMA COMPRAR BEM
-- ================================================================================================
-- Baseado na análise da estrutura atual do banco
-- Execute estes comandos em sequência no Supabase SQL Editor
-- ================================================================================================

-- ================================================================================================
-- 🚨 PARTE 1: CORREÇÃO CRÍTICA - ADICIONAR RLS FALTANDO (EXECUTAR PRIMEIRO!)
-- ================================================================================================

-- 🔒 PRODUTOS - Adicionar RLS (CRÍTICO!)
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_isolation_produtos" ON produtos
FOR ALL TO public 
USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

-- 🔒 GRUPOS - Leitura pública (dados compartilhados)
ALTER TABLE grupos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_grupos" ON grupos 
FOR SELECT TO public 
USING (true);

-- 🔒 CLASSES - Leitura pública (dados compartilhados) 
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_classes" ON classes 
FOR SELECT TO public 
USING (true);


-- ================================================================================================
-- 🔧 PARTE 2: ADICIONAR CAMPOS ESSENCIAIS NAS TABELAS EXISTENTES
-- ================================================================================================

-- 📋 PRODUTOS - Campos para controle completo do DCB
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS validade_dcb DATE;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS numero_dcb TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS data_aprovacao TIMESTAMP WITH TIME ZONE;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS aprovado_por UUID REFERENCES usuarios(id);
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS preco_referencia DECIMAL(10,2);
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS unidade_medida TEXT DEFAULT 'UN';
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS especificacoes_tecnicas JSONB;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS observacoes_internas TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS data_vencimento_registro DATE; -- ANVISA/INMETRO
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS numero_processo TEXT; -- Processo administrativo

-- 📊 ANALISES - Campos para workflow completo
ALTER TABLE analises ADD COLUMN IF NOT EXISTS tipo_analise TEXT DEFAULT 'tecnica';
ALTER TABLE analises ADD COLUMN IF NOT EXISTS prazo_analise DATE;
ALTER TABLE analises ADD COLUMN IF NOT EXISTS documentos_solicitados TEXT[];
ALTER TABLE analises ADD COLUMN IF NOT EXISTS etapa_atual TEXT DEFAULT 'inicial';
ALTER TABLE analises ADD COLUMN IF NOT EXISTS prioridade TEXT DEFAULT 'normal';
ALTER TABLE analises ADD COLUMN IF NOT EXISTS tempo_gasto_minutos INTEGER DEFAULT 0;

-- 👤 USUARIOS - Campos adicionais para controle
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS ultimo_login TIMESTAMP WITH TIME ZONE;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS cargo TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS setor TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS telefone TEXT;

-- 🏢 TENANTS - Informações adicionais do órgão
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS cnpj TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS endereco TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS telefone TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS email_contato TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS responsavel_legal TEXT;


-- ================================================================================================
-- 🆕 PARTE 3: CRIAR NOVAS TABELAS ESSENCIAIS
-- ================================================================================================

-- 📋 DCB CERTIFICADOS - Controle completo dos certificados emitidos
CREATE TABLE IF NOT EXISTS dcb_certificados (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    numero_dcb TEXT NOT NULL,
    data_emissao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_validade DATE NOT NULL,
    status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'vencido', 'revogado', 'suspenso')),
    assinado_por UUID REFERENCES usuarios(id),
    arquivo_pdf_url TEXT,
    hash_documento TEXT, -- Para integridade
    observacoes TEXT,
    revogado_em TIMESTAMP WITH TIME ZONE,
    revogado_por UUID REFERENCES usuarios(id),
    motivo_revogacao TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_dcb_tenant ON dcb_certificados(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dcb_produto ON dcb_certificados(produto_id);
CREATE INDEX IF NOT EXISTS idx_dcb_numero ON dcb_certificados(numero_dcb);
CREATE INDEX IF NOT EXISTS idx_dcb_validade ON dcb_certificados(data_validade);

-- RLS para DCB
ALTER TABLE dcb_certificados ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation_dcb" ON dcb_certificados
FOR ALL TO public USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);


-- 📨 NOTIFICAÇÕES - Sistema completo de alertas
CREATE TABLE IF NOT EXISTS notificacoes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN (
        'prazo_vencendo', 'dcb_vencido', 'nova_analise', 'dcb_emitido', 
        'produto_aprovado', 'produto_reprovado', 'diligencia', 'sistema'
    )),
    titulo TEXT NOT NULL,
    mensagem TEXT NOT NULL,
    lida BOOLEAN DEFAULT FALSE,
    data_leitura TIMESTAMP WITH TIME ZONE,
    prioridade TEXT DEFAULT 'normal' CHECK (prioridade IN ('baixa', 'normal', 'alta', 'critica')),
    produto_id UUID REFERENCES produtos(id),
    analise_id UUID REFERENCES analises(id),
    data_envio TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_expiracao TIMESTAMP WITH TIME ZONE,
    acao_url TEXT, -- Link para ação específica
    metadados JSONB -- Dados extras da notificação
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_notif_tenant ON notificacoes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notif_usuario ON notificacoes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notif_tipo ON notificacoes(tipo);
CREATE INDEX IF NOT EXISTS idx_notif_lida ON notificacoes(lida);

-- RLS para notificações
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation_notif" ON notificacoes
FOR ALL TO public USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);


-- 📊 WORKFLOW HISTÓRICO - Auditoria completa
CREATE TABLE IF NOT EXISTS workflow_historico (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    acao TEXT NOT NULL CHECK (acao IN (
        'criado', 'editado', 'analisado', 'aprovado', 'reprovado', 
        'diligencia', 'dcb_emitido', 'dcb_revogado', 'reativado'
    )),
    etapa_anterior TEXT,
    etapa_atual TEXT,
    observacoes TEXT,
    dados_alterados JSONB, -- LOG das alterações
    ip_usuario INET,
    user_agent TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para auditoria
CREATE INDEX IF NOT EXISTS idx_hist_tenant ON workflow_historico(tenant_id);
CREATE INDEX IF NOT EXISTS idx_hist_produto ON workflow_historico(produto_id);
CREATE INDEX IF NOT EXISTS idx_hist_usuario ON workflow_historico(usuario_id);
CREATE INDEX IF NOT EXISTS idx_hist_data ON workflow_historico(criado_em);

-- RLS para histórico
ALTER TABLE workflow_historico ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation_hist" ON workflow_historico
FOR ALL TO public USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);


-- ⚙️ CONFIGURAÇÕES SISTEMA - Parametrização por tenant
CREATE TABLE IF NOT EXISTS configuracoes_sistema (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    chave TEXT NOT NULL,
    valor TEXT NOT NULL,
    descricao TEXT,
    tipo TEXT DEFAULT 'text' CHECK (tipo IN ('text', 'number', 'boolean', 'json', 'date')),
    categoria TEXT DEFAULT 'geral', -- geral, dcb, notificacao, workflow
    editavel BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, chave)
);

-- RLS para configurações
ALTER TABLE configuracoes_sistema ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation_config" ON configuracoes_sistema
FOR ALL TO public USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);


-- 📋 TEMPLATES DOCUMENTOS - Templates para DCB e relatórios
CREATE TABLE IF NOT EXISTS templates_documentos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('dcb', 'relatorio', 'notificacao', 'email')),
    conteudo TEXT NOT NULL, -- HTML template
    variaveis_disponiveis TEXT[], -- Lista de variáveis substituíveis
    ativo BOOLEAN DEFAULT TRUE,
    versao INTEGER DEFAULT 1,
    criado_por UUID REFERENCES usuarios(id),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS para templates
ALTER TABLE templates_documentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation_templates" ON templates_documentos
FOR ALL TO public USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);


-- ================================================================================================
-- 🔧 PARTE 4: FUNÇÕES E TRIGGERS ÚTEIS
-- ================================================================================================

-- 🔄 Função para atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em tabelas que precisam
CREATE TRIGGER update_produtos_timestamp 
    BEFORE UPDATE ON produtos 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_analises_timestamp 
    BEFORE UPDATE ON analises 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_dcb_timestamp 
    BEFORE UPDATE ON dcb_certificados 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_config_timestamp 
    BEFORE UPDATE ON configuracoes_sistema 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();


-- 🔄 Função para gerar número DCB sequencial
CREATE OR REPLACE FUNCTION gerar_numero_dcb(tenant_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    ano_atual TEXT := EXTRACT(YEAR FROM NOW())::TEXT;
    contador INTEGER;
    numero_dcb TEXT;
BEGIN
    -- Buscar último número do ano atual
    SELECT COALESCE(MAX(
        CAST(SPLIT_PART(numero_dcb, '/', 1) AS INTEGER)
    ), 0) + 1
    INTO contador
    FROM dcb_certificados 
    WHERE tenant_id = tenant_uuid 
    AND numero_dcb LIKE '%/' || ano_atual;
    
    -- Gerar número formato: 001/2024
    numero_dcb := LPAD(contador::TEXT, 3, '0') || '/' || ano_atual;
    
    RETURN numero_dcb;
END;
$$ LANGUAGE plpgsql;


-- ================================================================================================
-- 🎯 PARTE 5: DADOS INICIAIS ESSENCIAIS
-- ================================================================================================

-- Inserir configurações padrão (executar apenas uma vez por tenant)
-- Esta função pode ser chamada quando um novo tenant é criado
CREATE OR REPLACE FUNCTION inserir_configuracoes_padrao(tenant_uuid UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO configuracoes_sistema (tenant_id, chave, valor, descricao, categoria) VALUES
    (tenant_uuid, 'dcb_validade_dias', '365', 'Validade padrão do DCB em dias', 'dcb'),
    (tenant_uuid, 'prazo_analise_dias', '15', 'Prazo padrão para análise técnica em dias', 'workflow'),
    (tenant_uuid, 'alerta_vencimento_dias', '30', 'Alertar X dias antes do vencimento', 'notificacao'),
    (tenant_uuid, 'orgao_nome', 'Prefeitura Municipal', 'Nome do órgão para documentos', 'geral'),
    (tenant_uuid, 'responsavel_cpm', 'Não definido', 'Responsável pela CPM', 'geral'),
    (tenant_uuid, 'responsavel_ccl', 'Não definido', 'Responsável pela CCL', 'geral'),
    (tenant_uuid, 'email_notificacoes', 'admin@prefeitura.gov.br', 'Email para notificações do sistema', 'notificacao')
    ON CONFLICT (tenant_id, chave) DO NOTHING;
END;
$$ LANGUAGE plpgsql;


-- ================================================================================================
-- 🚀 PARTE 6: VIEWS ÚTEIS PARA RELATÓRIOS
-- ================================================================================================

-- 📊 View: Produtos com status detalhado
CREATE OR REPLACE VIEW v_produtos_completo AS
SELECT 
    p.id,
    p.tenant_id,
    p.nome,
    p.marca,
    p.modelo,
    p.fabricante,
    p.status,
    p.criado_em,
    p.validade_dcb,
    p.numero_dcb,
    p.data_aprovacao,
    u_aprovador.nome as aprovado_por_nome,
    u_fornecedor.nome as fornecedor_nome,
    u_fornecedor.email as fornecedor_email,
    c.nome as categoria_nome,
    g.nome as grupo_nome,
    cl.nome as classe_nome,
    dcb.status as dcb_status,
    dcb.data_validade as dcb_data_validade,
    CASE 
        WHEN dcb.data_validade < CURRENT_DATE THEN 'vencido'
        WHEN dcb.data_validade <= CURRENT_DATE + INTERVAL '30 days' THEN 'vencendo'
        ELSE 'ok'
    END as alerta_dcb
FROM produtos p
LEFT JOIN usuarios u_aprovador ON p.aprovado_por = u_aprovador.id
LEFT JOIN usuarios u_fornecedor ON p.fornecedor_id = u_fornecedor.id
LEFT JOIN categorias c ON p.categoria_id = c.id
LEFT JOIN grupos g ON p.grupo_id = g.id
LEFT JOIN classes cl ON p.classe_id = cl.id
LEFT JOIN dcb_certificados dcb ON p.id = dcb.produto_id AND dcb.status = 'ativo';


-- 📊 View: Dashboard CPM
CREATE OR REPLACE VIEW v_dashboard_cpm AS
SELECT 
    tenant_id,
    COUNT(*) as total_produtos,
    COUNT(*) FILTER (WHERE status = 'pendente') as pendentes,
    COUNT(*) FILTER (WHERE status = 'aprovado') as aprovados,
    COUNT(*) FILTER (WHERE status = 'reprovado') as reprovados,
    COUNT(*) FILTER (WHERE validade_dcb < CURRENT_DATE) as dcb_vencidos,
    COUNT(*) FILTER (WHERE validade_dcb <= CURRENT_DATE + INTERVAL '30 days' AND validade_dcb >= CURRENT_DATE) as dcb_vencendo
FROM produtos
GROUP BY tenant_id;


-- ================================================================================================
-- ✅ FINALIZAÇÃO - MENSAGEM DE SUCESSO
-- ================================================================================================

-- Se chegou até aqui, banco foi completado com sucesso!
-- Próximos passos:
-- 1. Testar RLS está funcionando
-- 2. Inserir dados de teste
-- 3. Implementar na aplicação Vue.js

DO $$
BEGIN
    RAISE NOTICE '🚀 BANCO DE DADOS COMPLETADO COM SUCESSO!';
    RAISE NOTICE '✅ RLS configurado em todas as tabelas';
    RAISE NOTICE '✅ Novas tabelas criadas: dcb_certificados, notificacoes, workflow_historico, configuracoes_sistema, templates_documentos';
    RAISE NOTICE '✅ Campos essenciais adicionados nas tabelas existentes';
    RAISE NOTICE '✅ Funções e triggers implementados';
    RAISE NOTICE '✅ Views para relatórios criadas';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Próximos passos:';
    RAISE NOTICE '1. Execute: SELECT inserir_configuracoes_padrao(''seu-tenant-id'');';
    RAISE NOTICE '2. Teste as políticas RLS';
    RAISE NOTICE '3. Integre com o frontend Vue.js';
END $$; 