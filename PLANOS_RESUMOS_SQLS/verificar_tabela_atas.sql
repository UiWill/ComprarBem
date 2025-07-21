-- Verificar se tabela atas_julgamento existe e sua estrutura
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'atas_julgamento'
ORDER BY ordinal_position;

-- Se não existe, criar a tabela
CREATE TABLE IF NOT EXISTS atas_julgamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    numero TEXT NOT NULL,
    periodo TEXT,
    descricao TEXT,
    total_processos INTEGER DEFAULT 0,
    status_ata TEXT DEFAULT 'ELABORACAO' CHECK (status_ata IN ('ELABORACAO', 'PUBLICADA', 'HOMOLOGADA', 'CANCELADA')),
    data_inicio_elaboracao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_publicacao TIMESTAMP WITH TIME ZONE,
    data_fim_prazo_recursal TIMESTAMP WITH TIME ZONE,
    data_inicio_prazo_recursal TIMESTAMP WITH TIME ZONE,
    responsavel_elaboracao TEXT,
    progresso_elaboracao INTEGER DEFAULT 0,
    conteudo_ata TEXT,
    arquivo_pdf_url TEXT,
    qr_code_data TEXT,
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, numero)
);

-- Adicionar coluna ata_julgamento_id na tabela produtos se não existe
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS ata_julgamento_id UUID REFERENCES atas_julgamento(id);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_atas_julgamento_tenant ON atas_julgamento(tenant_id);
CREATE INDEX IF NOT EXISTS idx_atas_julgamento_status ON atas_julgamento(tenant_id, status_ata);
CREATE INDEX IF NOT EXISTS idx_produtos_ata_julgamento ON produtos(ata_julgamento_id) WHERE ata_julgamento_id IS NOT NULL;

-- Comentários
COMMENT ON TABLE atas_julgamento IS 'Atas de julgamento da CCL conforme Lei 14.133/2021';
COMMENT ON COLUMN atas_julgamento.status_ata IS 'Status da ata: ELABORACAO, PUBLICADA, HOMOLOGADA, CANCELADA';
COMMENT ON COLUMN produtos.ata_julgamento_id IS 'ID da ata de julgamento à qual o produto está vinculado';