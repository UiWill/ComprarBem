-- =====================================================
-- CRIAÇÃO DA TABELA DE ASSINATURAS DIGITAIS - VERSÃO SUPER SIMPLES
-- =====================================================

-- Criar a tabela básica sem qualquer foreign key ou constraint complexa
CREATE TABLE IF NOT EXISTS assinaturas_processo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    usuario_id UUID NOT NULL,
    nome_signatario VARCHAR(255) NOT NULL,
    cargo_signatario VARCHAR(255) NOT NULL,
    observacoes TEXT,
    data_assinatura TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    hash_validacao VARCHAR(255) NOT NULL,
    ip_assinatura INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices básicos
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_id ON assinaturas_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_tenant ON assinaturas_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_usuario ON assinaturas_processo(usuario_id);

-- Testar se foi criada
SELECT 'Tabela assinaturas_processo criada com sucesso!' as resultado;