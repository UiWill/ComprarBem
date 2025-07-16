-- CRIAÇÃO DAS TABELAS PARA WORKFLOW DE TRAMITAÇÃO CPM ↔ CCL
-- Execute cada comando separadamente no Supabase SQL Editor

-- 1. TABELA DE LOTES DE TRAMITAÇÃO (controla o envio organizado de produtos)
CREATE TABLE tramitacao_lotes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    numero_lote VARCHAR(20) NOT NULL UNIQUE, -- Formato: LT001/2024
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    status_lote VARCHAR(20) NOT NULL DEFAULT 'PREPARACAO', -- PREPARACAO, ENVIADO, RECEBIDO, EM_JULGAMENTO, JULGADO, HOMOLOGADO
    setor_origem VARCHAR(10) NOT NULL DEFAULT 'CPM', -- CPM, CCL
    setor_destino VARCHAR(10) NOT NULL DEFAULT 'CCL', -- CPM, CCL
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_envio TIMESTAMP WITH TIME ZONE,
    data_recebimento TIMESTAMP WITH TIME ZONE,
    data_conclusao TIMESTAMP WITH TIME ZONE,
    prazo_julgamento TIMESTAMP WITH TIME ZONE, -- 10 dias úteis após envio
    responsavel_envio UUID, -- ID do usuário que enviou
    responsavel_recebimento UUID, -- ID do usuário que recebeu
    observacoes TEXT,
    urgente BOOLEAN DEFAULT FALSE,
    quantidade_produtos INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABELA DE PRODUTOS NO LOTE (relaciona produtos aos lotes)
CREATE TABLE tramitacao_produtos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    lote_id UUID NOT NULL REFERENCES tramitacao_lotes(id) ON DELETE CASCADE,
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    ordem_no_lote INTEGER NOT NULL, -- Ordem do produto dentro do lote
    status_produto VARCHAR(20) NOT NULL DEFAULT 'INCLUIDO', -- INCLUIDO, REMOVIDO, JULGADO, APROVADO, REPROVADO
    parecer_cpm TEXT, -- Parecer da CPM sobre o produto
    parecer_ccl TEXT, -- Parecer da CCL sobre o produto
    resultado_julgamento VARCHAR(20), -- APROVADO, REPROVADO, DILIGENCIA
    data_inclusao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_julgamento TIMESTAMP WITH TIME ZONE,
    observacoes_produto TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(lote_id, produto_id) -- Um produto só pode estar uma vez no mesmo lote
);

-- 3. TABELA DE HISTÓRICO DE TRAMITAÇÃO (rastreabilidade completa)
CREATE TABLE tramitacao_historico (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    lote_id UUID NOT NULL REFERENCES tramitacao_lotes(id) ON DELETE CASCADE,
    acao VARCHAR(50) NOT NULL, -- CRIADO, PRODUTO_ADICIONADO, PRODUTO_REMOVIDO, ENVIADO, RECEBIDO, JULGADO, etc.
    status_anterior VARCHAR(20),
    status_novo VARCHAR(20),
    usuario_id UUID, -- Quem fez a ação
    usuario_nome VARCHAR(255),
    setor VARCHAR(10), -- CPM, CCL
    descricao TEXT NOT NULL,
    data_acao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    dados_extras JSONB, -- Dados adicionais da ação
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CONFIGURAR RLS (Row Level Security)
ALTER TABLE tramitacao_lotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tramitacao_produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE tramitacao_historico ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS RLS PARA TRAMITACAO_LOTES
CREATE POLICY "Usuários podem ver lotes do seu tenant" ON tramitacao_lotes
    FOR SELECT USING (tenant_id = auth.jwt() ->> 'tenant_id'::text);

CREATE POLICY "Usuários podem inserir lotes do seu tenant" ON tramitacao_lotes
    FOR INSERT WITH CHECK (tenant_id = auth.jwt() ->> 'tenant_id'::text);

CREATE POLICY "Usuários podem atualizar lotes do seu tenant" ON tramitacao_lotes
    FOR UPDATE USING (tenant_id = auth.jwt() ->> 'tenant_id'::text);

-- POLÍTICAS RLS PARA TRAMITACAO_PRODUTOS
CREATE POLICY "Usuários podem ver produtos de lotes do seu tenant" ON tramitacao_produtos
    FOR SELECT USING (tenant_id = auth.jwt() ->> 'tenant_id'::text);

CREATE POLICY "Usuários podem inserir produtos em lotes do seu tenant" ON tramitacao_produtos
    FOR INSERT WITH CHECK (tenant_id = auth.jwt() ->> 'tenant_id'::text);

CREATE POLICY "Usuários podem atualizar produtos de lotes do seu tenant" ON tramitacao_produtos
    FOR UPDATE USING (tenant_id = auth.jwt() ->> 'tenant_id'::text);

-- POLÍTICAS RLS PARA TRAMITACAO_HISTORICO
CREATE POLICY "Usuários podem ver histórico de lotes do seu tenant" ON tramitacao_historico
    FOR SELECT USING (tenant_id = auth.jwt() ->> 'tenant_id'::text);

CREATE POLICY "Usuários podem inserir histórico de lotes do seu tenant" ON tramitacao_historico
    FOR INSERT WITH CHECK (tenant_id = auth.jwt() ->> 'tenant_id'::text);

-- FUNÇÃO PARA ATUALIZAR UPDATED_AT AUTOMATICAMENTE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- TRIGGERS PARA ATUALIZAR UPDATED_AT
CREATE TRIGGER update_tramitacao_lotes_updated_at 
    BEFORE UPDATE ON tramitacao_lotes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tramitacao_produtos_updated_at 
    BEFORE UPDATE ON tramitacao_produtos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- FUNÇÃO PARA GERAR NÚMERO DE LOTE AUTOMATICAMENTE
CREATE OR REPLACE FUNCTION gerar_numero_lote(tenant_uuid UUID)
RETURNS VARCHAR(20) AS $$
DECLARE
    contador INTEGER;
    ano_atual INTEGER;
    numero_lote VARCHAR(20);
BEGIN
    ano_atual := EXTRACT(YEAR FROM NOW());
    
    -- Buscar o último número do ano para este tenant
    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_lote FROM 3 FOR 3) AS INTEGER)), 0) + 1
    INTO contador
    FROM tramitacao_lotes 
    WHERE tenant_id = tenant_uuid 
    AND numero_lote LIKE '%/' || ano_atual::text;
    
    -- Formatar como LT001/2024
    numero_lote := 'LT' || LPAD(contador::text, 3, '0') || '/' || ano_atual::text;
    
    RETURN numero_lote;
END;
$$ LANGUAGE plpgsql;

-- FUNÇÃO PARA REGISTRAR HISTÓRICO AUTOMATICAMENTE
CREATE OR REPLACE FUNCTION registrar_historico_tramitacao()
RETURNS TRIGGER AS $$
BEGIN
    -- Para INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO tramitacao_historico (
            tenant_id, 
            lote_id, 
            acao, 
            status_novo, 
            descricao,
            data_acao
        ) VALUES (
            NEW.tenant_id,
            NEW.id,
            'LOTE_CRIADO',
            NEW.status_lote,
            'Lote ' || NEW.numero_lote || ' criado: ' || NEW.titulo,
            NOW()
        );
        RETURN NEW;
    END IF;
    
    -- Para UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Só registrar se o status mudou
        IF OLD.status_lote != NEW.status_lote THEN
            INSERT INTO tramitacao_historico (
                tenant_id, 
                lote_id, 
                acao, 
                status_anterior,
                status_novo, 
                descricao,
                data_acao
            ) VALUES (
                NEW.tenant_id,
                NEW.id,
                'STATUS_ALTERADO',
                OLD.status_lote,
                NEW.status_lote,
                'Status do lote ' || NEW.numero_lote || ' alterado de ' || OLD.status_lote || ' para ' || NEW.status_lote,
                NOW()
            );
        END IF;
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER PARA HISTÓRICO AUTOMÁTICO
CREATE TRIGGER trigger_historico_tramitacao_lotes
    AFTER INSERT OR UPDATE ON tramitacao_lotes
    FOR EACH ROW EXECUTE FUNCTION registrar_historico_tramitacao();

-- ÍNDICES PARA PERFORMANCE
CREATE INDEX idx_tramitacao_lotes_tenant ON tramitacao_lotes(tenant_id);
CREATE INDEX idx_tramitacao_lotes_status ON tramitacao_lotes(status_lote);
CREATE INDEX idx_tramitacao_lotes_data_criacao ON tramitacao_lotes(data_criacao);
CREATE INDEX idx_tramitacao_produtos_lote ON tramitacao_produtos(lote_id);
CREATE INDEX idx_tramitacao_produtos_tenant ON tramitacao_produtos(tenant_id);
CREATE INDEX idx_tramitacao_historico_lote ON tramitacao_historico(lote_id);
CREATE INDEX idx_tramitacao_historico_tenant ON tramitacao_historico(tenant_id);

-- COMENTÁRIOS NAS TABELAS
COMMENT ON TABLE tramitacao_lotes IS 'Controla os lotes de tramitação entre CPM e CCL';
COMMENT ON TABLE tramitacao_produtos IS 'Produtos incluídos em cada lote de tramitação';
COMMENT ON TABLE tramitacao_historico IS 'Histórico completo de ações nos lotes para auditoria';

-- INSERIR DADOS DE EXEMPLO (OPCIONAL - DESCOMENTE SE QUISER TESTAR)
/*
-- Exemplo de lote para teste
INSERT INTO tramitacao_lotes (
    tenant_id,
    numero_lote,
    titulo,
    descricao,
    status_lote
) VALUES (
    'SEU_TENANT_ID_AQUI'::UUID,
    'LT001/2024',
    'Primeiro lote de medicamentos para análise',
    'Lote contendo medicamentos básicos para pré-qualificação urgente',
    'PREPARACAO'
);
*/