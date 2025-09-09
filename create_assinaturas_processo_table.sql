-- =====================================================
-- CRIAÇÃO DA TABELA DE ASSINATURAS DIGITAIS
-- =====================================================
-- 
-- Esta tabela armazena as assinaturas digitais dos processos administrativos
-- Cada assinatura é validada por senha e possui um hash único de verificação
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Chaves estrangeiras
    FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_processo_id ON assinaturas_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_tenant_id ON assinaturas_processo(tenant_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_usuario_id ON assinaturas_processo(usuario_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_data ON assinaturas_processo(data_assinatura);
CREATE INDEX IF NOT EXISTS idx_assinaturas_processo_hash ON assinaturas_processo(hash_validacao);

-- RLS (Row Level Security) para isolamento por tenant
ALTER TABLE assinaturas_processo ENABLE ROW LEVEL SECURITY;

-- Política para permitir que usuários vejam apenas assinaturas do seu tenant
CREATE POLICY IF NOT EXISTS "Usuários podem ver assinaturas do seu tenant"
    ON assinaturas_processo FOR SELECT
    USING (tenant_id = (
        SELECT (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
    ));

-- Política para permitir que usuários insiram assinaturas apenas no seu tenant
CREATE POLICY IF NOT EXISTS "Usuários podem inserir assinaturas no seu tenant"
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

-- View para facilitar consultas com dados de usuário
CREATE OR REPLACE VIEW vw_assinaturas_processo AS
SELECT 
    ap.*,
    pa.numero_processo,
    pa.nome_orgao,
    pa.status as status_processo,
    CASE 
        WHEN au.raw_user_meta_data ->> 'nome_completo' IS NOT NULL 
        THEN au.raw_user_meta_data ->> 'nome_completo'
        WHEN au.raw_user_meta_data ->> 'nome' IS NOT NULL 
        THEN au.raw_user_meta_data ->> 'nome'
        ELSE au.email
    END as nome_usuario_sistema,
    au.email as email_usuario
FROM assinaturas_processo ap
LEFT JOIN processos_administrativos pa ON pa.id = ap.processo_id
LEFT JOIN auth.users au ON au.id = ap.usuario_id;

COMMENT ON VIEW vw_assinaturas_processo IS 'View com informações completas das assinaturas incluindo dados do processo e usuário';

-- Inserir dados de exemplo (opcional - remover em produção)
-- INSERT INTO assinaturas_processo (
--     processo_id, 
--     tenant_id, 
--     usuario_id, 
--     nome_signatario, 
--     cargo_signatario,
--     observacoes,
--     hash_validacao,
--     ip_assinatura
-- ) VALUES (
--     '00000000-0000-0000-0000-000000000001'::UUID, -- Substitua por um processo_id real
--     '00000000-0000-0000-0000-000000000001'::UUID, -- Substitua por um tenant_id real
--     '00000000-0000-0000-0000-000000000001'::UUID, -- Substitua por um usuario_id real
--     'João da Silva',
--     'Procurador do Estado',
--     'Assinatura de exemplo para teste do sistema',
--     '1736267400000-user123-a1b2c3d4e',
--     '192.168.1.100'::INET
-- );

-- =====================================================
-- INSTRUÇÕES DE USO
-- =====================================================
--
-- 1. Execute este script no seu banco Supabase
-- 2. A tabela será criada com todas as políticas RLS
-- 3. As assinaturas serão automaticamente isoladas por tenant
-- 4. Cada assinatura deve ter um hash único para validação
-- 5. O sistema registrará automaticamente IP e timestamp
--
-- Para testar:
-- SELECT * FROM vw_assinaturas_processo WHERE processo_id = 'seu_processo_id';
--