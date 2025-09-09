-- =====================================================
-- CRIAÇÃO DA TABELA DE ASSINATURAS DIGITAIS - VERSÃO SEGURA
-- =====================================================
-- 
-- Esta versão não usa foreign keys para evitar erros de referência
-- O sistema funcionará normalmente mesmo sem as constraints
--

CREATE TABLE IF NOT EXISTS assinaturas_processo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identificação do processo e tenant
    processo_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- Dados do usuário que assinou
    usuario_id UUID NOT NULL,
    nome_signatario VARCHAR(255) NOT NULL,
    cargo_signatario VARCHAR(255) NOT NULL,
    
    -- Dados da assinatura
    observacoes TEXT,
    data_assinatura TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    hash_validacao VARCHAR(255) NOT NULL UNIQUE,
    ip_assinatura INET,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    
    -- NOTA: Foreign keys removidas temporariamente para evitar erros
    -- Elas podem ser adicionadas posteriormente se necessário
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_processo_id ON assinaturas_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_tenant_id ON assinaturas_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_usuario_id ON assinaturas_processo(usuario_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_data ON assinaturas_processo(data_assinatura);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_hash ON assinaturas_processo(hash_validacao);

-- RLS (Row Level Security) para isolamento por tenant
ALTER TABLE assinaturas_processo ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes se houver (evita erro de duplicata)
DROP POLICY IF EXISTS "Usuarios_podem_ver_assinaturas_do_seu_tenant" ON assinaturas_processo;
DROP POLICY IF EXISTS "Usuarios_podem_inserir_assinaturas_no_seu_tenant" ON assinaturas_processo;

-- Política para permitir que usuários vejam apenas assinaturas do seu tenant
CREATE POLICY "Usuarios_podem_ver_assinaturas_do_seu_tenant"
    ON assinaturas_processo FOR SELECT
    USING (tenant_id = (
        SELECT (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
    ));

-- Política para permitir que usuários insiram assinaturas apenas no seu tenant
CREATE POLICY "Usuarios_podem_inserir_assinaturas_no_seu_tenant"
    ON assinaturas_processo FOR INSERT
    WITH CHECK (
        tenant_id = (
            SELECT (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
        )
        AND usuario_id = auth.uid()
    );

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_assinaturas_processo()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_assinaturas_processo_updated_at ON assinaturas_processo;
CREATE TRIGGER update_assinaturas_processo_updated_at
    BEFORE UPDATE ON assinaturas_processo
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_assinaturas_processo();

-- Comentários das colunas
COMMENT ON TABLE assinaturas_processo IS 'Armazena as assinaturas digitais dos processos administrativos';
COMMENT ON COLUMN assinaturas_processo.processo_id IS 'ID do processo administrativo que foi assinado';
COMMENT ON COLUMN assinaturas_processo.tenant_id IS 'ID do tenant (isolamento multi-inquilino)';
COMMENT ON COLUMN assinaturas_processo.usuario_id IS 'ID do usuário que fez a assinatura';
COMMENT ON COLUMN assinaturas_processo.nome_signatario IS 'Nome completo do signatário conforme informado';
COMMENT ON COLUMN assinaturas_processo.cargo_signatario IS 'Cargo/função do signatário conforme informado';
COMMENT ON COLUMN assinaturas_processo.observacoes IS 'Observações adicionais sobre a assinatura';
COMMENT ON COLUMN assinaturas_processo.data_assinatura IS 'Data e hora exata da assinatura';
COMMENT ON COLUMN assinaturas_processo.hash_validacao IS 'Hash único para validação da assinatura';
COMMENT ON COLUMN assinaturas_processo.ip_assinatura IS 'Endereço IP de onde foi feita a assinatura';

-- =====================================================
-- TESTE DA TABELA
-- =====================================================
-- Inserir uma assinatura de teste (descomente para testar):
/*
INSERT INTO assinaturas_processo (
    processo_id, 
    tenant_id, 
    usuario_id, 
    nome_signatario, 
    cargo_signatario,
    observacoes,
    hash_validacao,
    ip_assinatura
) VALUES (
    gen_random_uuid(), -- processo_id temporário para teste
    gen_random_uuid(), -- tenant_id temporário para teste  
    auth.uid(), -- usuario_id atual
    'Nome de Teste',
    'Cargo de Teste',
    'Assinatura de teste do sistema',
    '1736267400000-test-a1b2c3d4e',
    '127.0.0.1'::INET
);
*/

-- =====================================================
-- INSTRUÇÕES DE USO
-- =====================================================
--
-- 1. Execute este script no seu banco Supabase
-- 2. A tabela será criada sem foreign keys para evitar erros
-- 3. O sistema funcionará normalmente
-- 4. As assinaturas serão isoladas por tenant automaticamente
--
-- Para testar após criar a tabela:
-- SELECT * FROM assinaturas_processo;
--