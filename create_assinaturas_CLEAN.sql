-- =====================================================
-- LIMPEZA E CRIAÇÃO DA TABELA DE ASSINATURAS DIGITAIS
-- =====================================================

-- Primeiro, vamos limpar qualquer coisa que possa estar causando conflito
DROP TABLE IF EXISTS assinaturas_processo CASCADE;

-- Remover qualquer função relacionada que possa existir
DROP FUNCTION IF EXISTS update_updated_at_assinaturas_processo() CASCADE;

-- Agora criar a tabela do zero
CREATE TABLE assinaturas_processo (
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

-- Verificar se foi criada
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'assinaturas_processo'
ORDER BY ordinal_position;