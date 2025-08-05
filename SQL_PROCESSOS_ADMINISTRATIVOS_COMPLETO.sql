-- =====================================================
-- SISTEMA DE PROCESSOS ADMINISTRATIVOS COMPLETO
-- Baseado na Lei 14.133/2021 e documentos fornecidos
-- =====================================================

-- 1. TABELA PRINCIPAL DE PROCESSOS ADMINISTRATIVOS
CREATE TABLE IF NOT EXISTS processos_administrativos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  numero_processo VARCHAR(50) UNIQUE NOT NULL, -- Formato: número/ano
  ano INTEGER NOT NULL,
  tipo_processo VARCHAR(20) NOT NULL CHECK (tipo_processo IN ('padronizacao', 'despadronizacao')),
  status VARCHAR(30) NOT NULL DEFAULT 'iniciado' CHECK (status IN (
    'iniciado', 'aguardando_aprovacao', 'analise_cppm', 'aguardando_edital',
    'edital_publicado', 'recebendo_propostas', 'analise_tecnica', 
    'julgamento_ccl', 'prazo_recursal', 'com_recursos', 'homologado',
    'finalizado', 'cancelado'
  )),
  objeto TEXT NOT NULL, -- Descrição do objeto do processo
  nome_orgao VARCHAR(200) NOT NULL,
  unidade_interessada VARCHAR(200) NOT NULL,
  data_autuacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_finalizacao TIMESTAMP WITH TIME ZONE,
  observacoes TEXT,
  tenant_id UUID NOT NULL REFERENCES auth.users(id),
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  criado_por UUID REFERENCES auth.users(id),
  atualizado_por UUID REFERENCES auth.users(id)
);

-- 2. TABELA DE DOCUMENTOS DO PROCESSO (NUMERAÇÃO SEQUENCIAL)
CREATE TABLE IF NOT EXISTS documentos_processo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
  numero_folha INTEGER NOT NULL, -- Fl. 001, Fl. 002, etc.
  tipo_documento VARCHAR(50) NOT NULL CHECK (tipo_documento IN (
    'folha_rosto', 'dfd', 'edital', 'aviso_publicacao', 'esclarecimento',
    'impugnacao', 'parecer_juridico', 'memorando', 'despacho', 
    'requerimento_prequalificacao', 'laudo_tecnico', 'relatorio_final',
    'ata_julgamento', 'recurso', 'dcb', 'outros'
  )),
  titulo VARCHAR(300) NOT NULL,
  descricao TEXT,
  conteudo_html TEXT, -- Para documentos gerados automaticamente
  arquivo_url VARCHAR(500), -- URL do arquivo PDF
  nome_arquivo VARCHAR(255),
  tamanho_arquivo BIGINT,
  data_autuacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  assinado BOOLEAN DEFAULT FALSE,
  data_assinatura TIMESTAMP WITH TIME ZONE,
  assinado_por UUID REFERENCES auth.users(id),
  cargo_assinante VARCHAR(100),
  tenant_id UUID NOT NULL REFERENCES auth.users(id),
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  criado_por UUID REFERENCES auth.users(id)
);

-- 3. TABELA DE ASSINATURAS ELETRÔNICAS
CREATE TABLE IF NOT EXISTS assinaturas_processo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  documento_id UUID NOT NULL REFERENCES documentos_processo(id) ON DELETE CASCADE,
  usuario_id UUID NOT NULL REFERENCES auth.users(id),
  nome_completo VARCHAR(200) NOT NULL,
  cargo VARCHAR(100) NOT NULL,
  tipo_assinatura VARCHAR(20) NOT NULL CHECK (tipo_assinatura IN ('digital', 'eletronica')),
  hash_documento TEXT NOT NULL, -- Hash do documento no momento da assinatura
  data_assinatura TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_assinatura INET,
  observacoes TEXT,
  tenant_id UUID NOT NULL REFERENCES auth.users(id)
);

-- 4. TABELA DE TRAMITAÇÃO (HISTÓRICO DO PROCESSO)
CREATE TABLE IF NOT EXISTS tramitacao_processo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
  status_anterior VARCHAR(30),
  status_novo VARCHAR(30) NOT NULL,
  responsavel UUID NOT NULL REFERENCES auth.users(id),
  cargo_responsavel VARCHAR(100),
  acao_executada VARCHAR(100) NOT NULL, -- 'documento_autuado', 'assinatura_realizada', etc.
  observacoes TEXT,
  data_tramitacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  tenant_id UUID NOT NULL REFERENCES auth.users(id)
);

-- 5. TABELA DE RECURSOS ADMINISTRATIVOS
CREATE TABLE IF NOT EXISTS recursos_processo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
  documento_recurso_id UUID REFERENCES documentos_processo(id),
  tipo_recurso VARCHAR(30) NOT NULL CHECK (tipo_recurso IN ('impugnacao', 'recurso_administrativo')),
  requerente VARCHAR(200) NOT NULL,
  email_requerente VARCHAR(100),
  telefone_requerente VARCHAR(20),
  motivo TEXT NOT NULL,
  data_interposicao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  prazo_resposta DATE,
  status_recurso VARCHAR(20) DEFAULT 'aguardando_analise' CHECK (status_recurso IN (
    'aguardando_analise', 'em_analise', 'deferido', 'indeferido', 'parcialmente_deferido'
  )),
  parecer_cppm TEXT,
  parecer_juridico TEXT,
  decisao_final TEXT,
  data_decisao TIMESTAMP WITH TIME ZONE,
  decidido_por UUID REFERENCES auth.users(id),
  tenant_id UUID NOT NULL REFERENCES auth.users(id)
);

-- 6. TABELA DE PRODUTOS EM PRÉ-QUALIFICAÇÃO
CREATE TABLE IF NOT EXISTS produtos_prequalificacao (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
  nome_produto VARCHAR(300) NOT NULL,
  marca VARCHAR(100),
  modelo VARCHAR(100),
  fabricante VARCHAR(200),
  especificacoes_tecnicas TEXT,
  categoria_produto VARCHAR(100),
  quantidade_amostras INTEGER DEFAULT 0,
  valor_estimado DECIMAL(12,2),
  status_produto VARCHAR(20) DEFAULT 'aguardando_analise' CHECK (status_produto IN (
    'aguardando_analise', 'em_analise', 'aprovado', 'reprovado', 'diligencia'
  )),
  parecer_cppm TEXT,
  observacoes_tecnicas TEXT,
  tenant_id UUID NOT NULL REFERENCES auth.users(id),
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. TABELA DE DFD (DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA)
CREATE TABLE IF NOT EXISTS dfd_processo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
  modelo_usado VARCHAR(20) NOT NULL CHECK (modelo_usado IN ('modelo_1', 'modelo_2')), -- Modelo 1 ou 2
  justificativa TEXT NOT NULL,
  necessidade_descricao TEXT NOT NULL,
  quantidade_estimada INTEGER,
  prazo_entrega VARCHAR(100),
  local_entrega TEXT,
  criterios_aceitacao TEXT,
  observacoes_especiais TEXT,
  aprovado_por UUID REFERENCES auth.users(id),
  data_aprovacao TIMESTAMP WITH TIME ZONE,
  tenant_id UUID NOT NULL REFERENCES auth.users(id),
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. TABELA DE CONFIGURAÇÃO DE NUMERAÇÃO
CREATE TABLE IF NOT EXISTS configuracao_numeracao (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES auth.users(id),
  ano INTEGER NOT NULL,
  ultimo_numero INTEGER DEFAULT 0,
  prefixo VARCHAR(10) DEFAULT 'PA', -- Processo Administrativo
  UNIQUE(tenant_id, ano)
);

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_processos_tenant_status ON processos_administrativos(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_processos_numero ON processos_administrativos(numero_processo);
CREATE INDEX IF NOT EXISTS idx_documentos_processo_numero ON documentos_processo(processo_id, numero_folha);
CREATE INDEX IF NOT EXISTS idx_tramitacao_processo ON tramitacao_processo(processo_id, data_tramitacao);
CREATE INDEX IF NOT EXISTS idx_recursos_processo_status ON recursos_processo(processo_id, status_recurso);
CREATE INDEX IF NOT EXISTS idx_produtos_processo ON produtos_prequalificacao(processo_id, status_produto);

-- =====================================================
-- TRIGGERS PARA AUDITORIA E CONTROLE
-- =====================================================

-- Trigger para atualizar campo 'atualizado_em'
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_processos_timestamp
  BEFORE UPDATE ON processos_administrativos
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Trigger para criar numeração automática de processo
CREATE OR REPLACE FUNCTION gerar_numero_processo()
RETURNS TRIGGER AS $$
DECLARE
  ano_atual INTEGER;
  proximo_numero INTEGER;
  numero_completo VARCHAR(50);
BEGIN
  ano_atual := EXTRACT(YEAR FROM NEW.data_autuacao);
  
  -- Inserir ou atualizar configuração de numeração para o tenant e ano
  INSERT INTO configuracao_numeracao (tenant_id, ano, ultimo_numero)
  VALUES (NEW.tenant_id, ano_atual, 1)
  ON CONFLICT (tenant_id, ano)
  DO UPDATE SET ultimo_numero = configuracao_numeracao.ultimo_numero + 1;
  
  -- Obter o próximo número
  SELECT ultimo_numero INTO proximo_numero
  FROM configuracao_numeracao
  WHERE tenant_id = NEW.tenant_id AND ano = ano_atual;
  
  -- Gerar número completo do processo
  numero_completo := LPAD(proximo_numero::TEXT, 4, '0') || '/' || ano_atual::TEXT;
  
  NEW.numero_processo := numero_completo;
  NEW.ano := ano_atual;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_gerar_numero_processo
  BEFORE INSERT ON processos_administrativos
  FOR EACH ROW
  WHEN (NEW.numero_processo IS NULL)
  EXECUTE FUNCTION gerar_numero_processo();

-- Trigger para registrar tramitação quando status muda
CREATE OR REPLACE FUNCTION registrar_tramitacao()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO tramitacao_processo (
      processo_id, status_anterior, status_novo, responsavel, 
      acao_executada, observacoes, tenant_id
    ) VALUES (
      NEW.id, OLD.status, NEW.status, NEW.atualizado_por,
      'mudanca_status', 'Status alterado de ' || COALESCE(OLD.status, 'nulo') || ' para ' || NEW.status,
      NEW.tenant_id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_registrar_tramitacao
  AFTER UPDATE ON processos_administrativos
  FOR EACH ROW EXECUTE FUNCTION registrar_tramitacao();

-- Trigger para numeração automática de documentos
CREATE OR REPLACE FUNCTION numerar_documento()
RETURNS TRIGGER AS $$
DECLARE
  proximo_numero INTEGER;
BEGIN
  IF NEW.numero_folha IS NULL THEN
    -- Obter o próximo número de folha para este processo
    SELECT COALESCE(MAX(numero_folha), 0) + 1 
    INTO proximo_numero
    FROM documentos_processo 
    WHERE processo_id = NEW.processo_id;
    
    NEW.numero_folha := proximo_numero;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_numerar_documento
  BEFORE INSERT ON documentos_processo
  FOR EACH ROW EXECUTE FUNCTION numerar_documento();

-- =====================================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Habilitar RLS nas tabelas principais
ALTER TABLE processos_administrativos ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos_processo ENABLE ROW LEVEL SECURITY;
ALTER TABLE assinaturas_processo ENABLE ROW LEVEL SECURITY;
ALTER TABLE tramitacao_processo ENABLE ROW LEVEL SECURITY;
ALTER TABLE recursos_processo ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos_prequalificacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE dfd_processo ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracao_numeracao ENABLE ROW LEVEL SECURITY;

-- Políticas para processos_administrativos
CREATE POLICY "Usuários podem ver processos do seu tenant" ON processos_administrativos
  FOR SELECT USING (tenant_id = auth.uid());

CREATE POLICY "Usuários podem criar processos no seu tenant" ON processos_administrativos
  FOR INSERT WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "Usuários podem atualizar processos do seu tenant" ON processos_administrativos
  FOR UPDATE USING (tenant_id = auth.uid());

-- Políticas para documentos_processo
CREATE POLICY "Usuários podem ver documentos do seu tenant" ON documentos_processo
  FOR SELECT USING (tenant_id = auth.uid());

CREATE POLICY "Usuários podem criar documentos no seu tenant" ON documentos_processo
  FOR INSERT WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "Usuários podem atualizar documentos do seu tenant" ON documentos_processo
  FOR UPDATE USING (tenant_id = auth.uid());

-- Políticas para outras tabelas (padrão similar)
CREATE POLICY "RLS assinaturas_processo" ON assinaturas_processo
  FOR ALL USING (tenant_id = auth.uid());

CREATE POLICY "RLS tramitacao_processo" ON tramitacao_processo
  FOR ALL USING (tenant_id = auth.uid());

CREATE POLICY "RLS recursos_processo" ON recursos_processo
  FOR ALL USING (tenant_id = auth.uid());

CREATE POLICY "RLS produtos_prequalificacao" ON produtos_prequalificacao
  FOR ALL USING (tenant_id = auth.uid());

CREATE POLICY "RLS dfd_processo" ON dfd_processo
  FOR ALL USING (tenant_id = auth.uid());

CREATE POLICY "RLS configuracao_numeracao" ON configuracao_numeracao
  FOR ALL USING (tenant_id = auth.uid());

-- =====================================================
-- VIEWS ÚTEIS PARA O SISTEMA
-- =====================================================

-- View de processos com informações resumidas
CREATE OR REPLACE VIEW vw_processos_resumo AS
SELECT 
  p.id,
  p.numero_processo,
  p.tipo_processo,
  p.status,
  p.objeto,
  p.nome_orgao,
  p.unidade_interessada,
  p.data_autuacao,
  p.data_finalizacao,
  COUNT(dp.id) as total_documentos,
  COUNT(CASE WHEN dp.assinado = true THEN 1 END) as documentos_assinados,
  COUNT(pp.id) as total_produtos,
  COUNT(rp.id) as total_recursos,
  p.tenant_id
FROM processos_administrativos p
LEFT JOIN documentos_processo dp ON p.id = dp.processo_id
LEFT JOIN produtos_prequalificacao pp ON p.id = pp.processo_id
LEFT JOIN recursos_processo rp ON p.id = rp.processo_id
GROUP BY p.id, p.numero_processo, p.tipo_processo, p.status, p.objeto, 
         p.nome_orgao, p.unidade_interessada, p.data_autuacao, p.data_finalizacao, p.tenant_id;

-- View de documentos com informações de assinatura
CREATE OR REPLACE VIEW vw_documentos_completos AS
SELECT 
  dp.*,
  ap.nome_completo as assinante_nome,
  ap.cargo as assinante_cargo,
  ap.data_assinatura as data_assinatura_real
FROM documentos_processo dp
LEFT JOIN assinaturas_processo ap ON dp.id = ap.documento_id;

-- =====================================================
-- DADOS INICIAIS (OPCIONAL)
-- =====================================================

-- Inserir tipos de documentos padrão se necessário
-- (Isso pode ser feito via aplicação conforme necessidade)

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON TABLE processos_administrativos IS 'Tabela principal dos processos de pré-qualificação e despadronização';
COMMENT ON TABLE documentos_processo IS 'Documentos sequenciais dos processos com numeração automática (Fl. 001, 002...)';
COMMENT ON TABLE assinaturas_processo IS 'Registro de assinaturas eletrônicas nos documentos';
COMMENT ON TABLE tramitacao_processo IS 'Histórico de tramitação e mudanças de status dos processos';
COMMENT ON TABLE recursos_processo IS 'Recursos e impugnações apresentados nos processos';
COMMENT ON TABLE produtos_prequalificacao IS 'Produtos submetidos à pré-qualificação';
COMMENT ON TABLE dfd_processo IS 'Documentos de Formalização de Demanda (DFD)';

-- FIM DO SCRIPT