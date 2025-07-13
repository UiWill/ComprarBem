-- =======================
-- TABELAS PARA SISTEMA DCB
-- =======================

-- Tabela para Certificados DCB
CREATE TABLE IF NOT EXISTS dcb_certificados (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL,
    produto_id INTEGER NOT NULL,
    numero_dcb VARCHAR(20) NOT NULL UNIQUE,
    data_emissao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_validade TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'vencido', 'revogado')),
    revogado_em TIMESTAMP NULL,
    motivo_revogacao TEXT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Índices e constraints
    CONSTRAINT fk_dcb_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT fk_dcb_produto FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_dcb_tenant_id ON dcb_certificados(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dcb_produto_id ON dcb_certificados(produto_id);
CREATE INDEX IF NOT EXISTS idx_dcb_numero ON dcb_certificados(numero_dcb);
CREATE INDEX IF NOT EXISTS idx_dcb_status ON dcb_certificados(status);
CREATE INDEX IF NOT EXISTS idx_dcb_validade ON dcb_certificados(data_validade);

-- Trigger para atualizar timestamp
CREATE OR REPLACE FUNCTION update_dcb_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_dcb_timestamp
    BEFORE UPDATE ON dcb_certificados
    FOR EACH ROW
    EXECUTE FUNCTION update_dcb_timestamp();

-- Adicionar campos DCB na tabela produtos (se não existirem)
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS numero_dcb VARCHAR(20) NULL,
ADD COLUMN IF NOT EXISTS validade_dcb TIMESTAMP NULL;

-- Índice para busca rápida de produtos com DCB
CREATE INDEX IF NOT EXISTS idx_produtos_dcb ON produtos(numero_dcb) WHERE numero_dcb IS NOT NULL;

-- Comentários para documentação
COMMENT ON TABLE dcb_certificados IS 'Certificados DCB (Declaração de Conformidade de Bem) emitidos';
COMMENT ON COLUMN dcb_certificados.numero_dcb IS 'Número sequencial do DCB (ex: 001/2024)';
COMMENT ON COLUMN dcb_certificados.status IS 'Status do DCB: ativo, vencido, revogado';
COMMENT ON COLUMN dcb_certificados.data_validade IS 'Data de validade do DCB (normalmente 1 ano)';
COMMENT ON COLUMN dcb_certificados.motivo_revogacao IS 'Motivo da revogação quando aplicável';

-- Função para verificar DCBs vencidos automaticamente
CREATE OR REPLACE FUNCTION verificar_dcb_vencidos()
RETURNS void AS $$
BEGIN
    UPDATE dcb_certificados 
    SET status = 'vencido'
    WHERE status = 'ativo' 
    AND data_validade < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Dados de exemplo para teste (opcional)
-- INSERT INTO dcb_certificados (tenant_id, produto_id, numero_dcb, data_emissao, data_validade, status)
-- VALUES 
-- (1, 1, '001/2024', '2024-01-15', '2025-01-15', 'ativo'),
-- (1, 2, '002/2024', '2024-02-20', '2025-02-20', 'ativo');

-- Verificar se tudo foi criado corretamente
SELECT 
    'Tabela dcb_certificados criada' as status,
    count(*) as registros
FROM dcb_certificados
UNION ALL
SELECT 
    'Campos DCB adicionados em produtos' as status,
    count(*) as produtos_com_dcb
FROM produtos 
WHERE numero_dcb IS NOT NULL; 