-- Script para criar/atualizar tabela de recursos administrativos
-- Sistema Comprar Bem - CCL

-- Primeiro, verificar se a tabela existe e criar se necessário
CREATE TABLE IF NOT EXISTS recursos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    ata_referencia TEXT NOT NULL,
    produto_id UUID,
    produto_nome TEXT NOT NULL,
    recorrente TEXT NOT NULL,
    documento_recorrente TEXT,
    data_recurso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    prazo_final TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'EM ANÁLISE',
    decisao TEXT,
    fundamentacao_decisao TEXT,
    responsavel_decisao TEXT,
    data_decisao TIMESTAMP WITH TIME ZONE,
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adicionar colunas que podem estar faltando
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS fundamentacao TEXT;
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS documento_recorrente TEXT;
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS documentos_anexos TEXT[];

-- Atualizar constraints se não existirem
DO $$ 
BEGIN
    -- Adicionar constraint de status se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'recursos_status_check' 
        AND table_name = 'recursos'
    ) THEN
        ALTER TABLE recursos ADD CONSTRAINT recursos_status_check 
        CHECK (status IN ('EM ANÁLISE', 'DEFERIDO', 'INDEFERIDO', 'AGUARDANDO CPM', 'CANCELADO'));
    END IF;
    
    -- Adicionar foreign keys se existir as tabelas referenciadas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tenants') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_recursos_tenant' 
            AND table_name = 'recursos'
        ) THEN
            ALTER TABLE recursos ADD CONSTRAINT fk_recursos_tenant 
            FOREIGN KEY (tenant_id) REFERENCES tenants(id);
        END IF;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'produtos') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_recursos_produto' 
            AND table_name = 'recursos'
        ) THEN
            ALTER TABLE recursos ADD CONSTRAINT fk_recursos_produto 
            FOREIGN KEY (produto_id) REFERENCES produtos(id);
        END IF;
    END IF;
END $$;

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_recursos_tenant ON recursos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_recursos_ata ON recursos(tenant_id, ata_referencia);
CREATE INDEX IF NOT EXISTS idx_recursos_status ON recursos(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_recursos_prazo ON recursos(prazo_final) WHERE status = 'EM ANÁLISE';

-- Comentários
COMMENT ON TABLE recursos IS 'Recursos administrativos contra decisões da CCL - Lei 14.133/2021 Art. 165-171';
COMMENT ON COLUMN recursos.status IS 'Status do recurso: EM ANÁLISE, DEFERIDO, INDEFERIDO, AGUARDANDO CPM, CANCELADO';
COMMENT ON COLUMN recursos.prazo_final IS 'Data limite para julgamento do recurso (3 dias úteis)';
COMMENT ON COLUMN recursos.fundamentacao IS 'Fundamentação legal e técnica apresentada pelo recorrente';
COMMENT ON COLUMN recursos.decisao IS 'Decisão da autoridade competente sobre o recurso';

-- Trigger para atualizar timestamp
CREATE OR REPLACE FUNCTION update_recursos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Remover trigger se já existir e criar novo
DROP TRIGGER IF EXISTS trigger_update_recursos_updated_at ON recursos;
CREATE TRIGGER trigger_update_recursos_updated_at
    BEFORE UPDATE ON recursos
    FOR EACH ROW
    EXECUTE FUNCTION update_recursos_updated_at();

-- RLS (Row Level Security)
ALTER TABLE recursos ENABLE ROW LEVEL SECURITY;

-- Política RLS para recursos
CREATE POLICY recursos_tenant_policy ON recursos
    FOR ALL USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Grant de permissões (ajustar conforme necessário)
-- GRANT ALL ON recursos TO authenticated;
-- GRANT ALL ON recursos TO service_role;