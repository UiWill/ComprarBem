-- 📧 TABELA PARA LOGS DE EMAILS ENVIADOS
-- Controla todos os emails enviados pelo sistema

CREATE TABLE IF NOT EXISTS emails_enviados (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL,
    
    -- Dados do email
    tipo VARCHAR(50) NOT NULL, -- 'diligencia', 'aprovacao', 'reprovacao', etc.
    destinatario VARCHAR(255) NOT NULL,
    remetente VARCHAR(255) DEFAULT 'cpm@suaorganizacao.com.br',
    assunto TEXT NOT NULL,
    corpo TEXT,
    
    -- Relacionamentos
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    diligencia_id UUID REFERENCES diligencias(id) ON DELETE CASCADE,
    
    -- Status do envio
    status VARCHAR(20) DEFAULT 'pendente', -- 'pendente', 'enviando', 'enviado', 'erro'
    tentativas INTEGER DEFAULT 0,
    erro_detalhes TEXT,
    
    -- Controle de data
    data_envio TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 🔐 RLS (Row Level Security)
ALTER TABLE emails_enviados ENABLE ROW LEVEL SECURITY;

-- Política para usuários verem apenas emails do seu tenant
CREATE POLICY "Usuários podem ver emails do próprio tenant" ON emails_enviados
    FOR SELECT 
    USING (tenant_id = (SELECT auth.jwt() ->> 'tenant_id')::UUID);

-- Política para inserir emails
CREATE POLICY "Usuários podem inserir emails no próprio tenant" ON emails_enviados
    FOR INSERT 
    WITH CHECK (tenant_id = (SELECT auth.jwt() ->> 'tenant_id')::UUID);

-- Política para atualizar emails
CREATE POLICY "Usuários podem atualizar emails do próprio tenant" ON emails_enviados
    FOR UPDATE 
    USING (tenant_id = (SELECT auth.jwt() ->> 'tenant_id')::UUID);

-- 📊 ÍNDICES PARA PERFORMANCE
CREATE INDEX idx_emails_enviados_tenant_id ON emails_enviados(tenant_id);
CREATE INDEX idx_emails_enviados_produto_id ON emails_enviados(produto_id);
CREATE INDEX idx_emails_enviados_diligencia_id ON emails_enviados(diligencia_id);
CREATE INDEX idx_emails_enviados_status ON emails_enviados(status);
CREATE INDEX idx_emails_enviados_tipo ON emails_enviados(tipo);
CREATE INDEX idx_emails_enviados_data_envio ON emails_enviados(data_envio);

-- ⚡ TRIGGER PARA UPDATED_AT
CREATE OR REPLACE FUNCTION update_emails_enviados_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_emails_enviados_updated_at
    BEFORE UPDATE ON emails_enviados
    FOR EACH ROW
    EXECUTE FUNCTION update_emails_enviados_updated_at();

-- 📊 COMENTÁRIOS PARA DOCUMENTAÇÃO
COMMENT ON TABLE emails_enviados IS 'Registro de todos os emails enviados pelo sistema';
COMMENT ON COLUMN emails_enviados.tipo IS 'Tipo de email: diligencia, aprovacao, reprovacao, etc.';
COMMENT ON COLUMN emails_enviados.status IS 'Status do envio: pendente, enviando, enviado, erro';
COMMENT ON COLUMN emails_enviados.tentativas IS 'Número de tentativas de envio';

-- 🔄 FUNÇÃO PARA REENVIAR EMAILS COM ERRO
CREATE OR REPLACE FUNCTION reenviar_emails_com_erro()
RETURNS INTEGER AS $$
DECLARE
    emails_reenviados INTEGER := 0;
    email_record RECORD;
BEGIN
    -- Busca emails com erro e menos de 3 tentativas
    FOR email_record IN 
        SELECT * FROM emails_enviados 
        WHERE status = 'erro' 
        AND tentativas < 3 
        AND created_at > now() - INTERVAL '7 days'
    LOOP
        -- Marca para reenvio
        UPDATE emails_enviados 
        SET status = 'pendente',
            tentativas = tentativas + 1,
            updated_at = now()
        WHERE id = email_record.id;
        
        emails_reenviados := emails_reenviados + 1;
    END LOOP;
    
    RETURN emails_reenviados;
END;
$$ LANGUAGE plpgsql;

-- 📈 VIEW PARA ESTATÍSTICAS DE EMAILS
CREATE OR REPLACE VIEW v_estatisticas_emails AS
SELECT 
    tenant_id,
    tipo,
    status,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'enviado') as enviados,
    COUNT(*) FILTER (WHERE status = 'erro') as com_erro,
    COUNT(*) FILTER (WHERE status = 'pendente') as pendentes,
    ROUND(
        (COUNT(*) FILTER (WHERE status = 'enviado') * 100.0) / 
        NULLIF(COUNT(*), 0), 2
    ) as taxa_sucesso_percent
FROM emails_enviados
WHERE created_at > now() - INTERVAL '30 days'
GROUP BY tenant_id, tipo, status
ORDER BY tenant_id, tipo;

COMMENT ON VIEW v_estatisticas_emails IS 'Estatísticas de emails enviados nos últimos 30 dias';

-- 🎯 EXEMPLO DE USO
/*
-- Inserir log de email de diligência
INSERT INTO emails_enviados (
    tenant_id, tipo, destinatario, assunto,
    produto_id, diligencia_id, status
) VALUES (
    'tenant-uuid', 'diligencia', 'fornecedor@empresa.com',
    'Diligência Solicitada - Produto em Análise',
    'produto-uuid', 'diligencia-uuid', 'enviado'
);

-- Consultar emails de um produto
SELECT * FROM emails_enviados 
WHERE produto_id = 'produto-uuid' 
ORDER BY created_at DESC;

-- Ver estatísticas
SELECT * FROM v_estatisticas_emails;
*/ 