-- Criar tabela para participantes dos editais de pré-qualificação
CREATE TABLE IF NOT EXISTS participantes_editais (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    edital_id UUID NOT NULL REFERENCES editais(id) ON DELETE CASCADE,
    razao_social TEXT NOT NULL,
    cnpj VARCHAR(18) NOT NULL,
    representante_legal TEXT NOT NULL,
    email TEXT NOT NULL,
    telefone VARCHAR(20),
    endereco TEXT,
    status VARCHAR(50) DEFAULT 'INTERESSADO' CHECK (status IN (
        'INTERESSADO',
        'DOCUMENTACAO_ENVIADA',
        'EM_AVALIACAO',
        'APROVADO',
        'REPROVADO',
        'DESISTENTE'
    )),
    data_participacao TIMESTAMP DEFAULT NOW(),
    data_envio_documentacao TIMESTAMP,
    observacoes TEXT,
    produtos_submetidos JSONB DEFAULT '[]'::jsonb,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_participantes_editais_tenant_id ON participantes_editais(tenant_id);
CREATE INDEX IF NOT EXISTS idx_participantes_editais_edital_id ON participantes_editais(edital_id);
CREATE INDEX IF NOT EXISTS idx_participantes_editais_cnpj ON participantes_editais(cnpj);
CREATE INDEX IF NOT EXISTS idx_participantes_editais_status ON participantes_editais(status);

-- Constraint única para evitar duplicação
CREATE UNIQUE INDEX IF NOT EXISTS idx_participantes_editais_unique 
ON participantes_editais(tenant_id, edital_id, cnpj);

-- Trigger para atualizar atualizado_em
CREATE OR REPLACE FUNCTION update_participantes_editais_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_participantes_editais_updated_at
    BEFORE UPDATE ON participantes_editais
    FOR EACH ROW
    EXECUTE FUNCTION update_participantes_editais_updated_at();

-- Comentários para documentação
COMMENT ON TABLE participantes_editais IS 'Participantes dos editais de pré-qualificação';
COMMENT ON COLUMN participantes_editais.status IS 'Status da participação no edital';
COMMENT ON COLUMN participantes_editais.produtos_submetidos IS 'Array JSON com produtos submetidos para avaliação'; 