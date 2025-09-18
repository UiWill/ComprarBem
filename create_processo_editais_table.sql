-- =====================================================
-- CRIAÇÃO DA TABELA DE VINCULAÇÃO PROCESSO-EDITAIS
-- =====================================================
--
-- Esta tabela armazena a relação entre processos administrativos
-- e editais de pré-qualificação vinculados a eles
--

CREATE TABLE IF NOT EXISTS processo_editais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identificação do processo e edital
    processo_id UUID NOT NULL, -- Referencia processos_administrativos.id
    edital_id UUID NOT NULL,   -- Referencia editais.id
    tenant_id UUID NOT NULL,   -- Isolamento multi-tenant

    -- Dados da vinculação
    data_vinculacao TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    observacoes TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraint para evitar vinculações duplicadas
    UNIQUE(processo_id, edital_id, tenant_id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_processo_editais_processo_id ON processo_editais(processo_id);
CREATE INDEX IF NOT EXISTS idx_processo_editais_edital_id ON processo_editais(edital_id);
CREATE INDEX IF NOT EXISTS idx_processo_editais_tenant_id ON processo_editais(tenant_id);
CREATE INDEX IF NOT EXISTS idx_processo_editais_data ON processo_editais(data_vinculacao);

-- RLS (Row Level Security) para isolamento por tenant
ALTER TABLE processo_editais ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes se houver (evita erro de duplicata)
DROP POLICY IF EXISTS "Usuarios_podem_ver_vinculacoes_do_seu_tenant" ON processo_editais;
DROP POLICY IF EXISTS "Usuarios_podem_inserir_vinculacoes_no_seu_tenant" ON processo_editais;
DROP POLICY IF EXISTS "Usuarios_podem_deletar_vinculacoes_do_seu_tenant" ON processo_editais;

-- Política para permitir que usuários vejam apenas vinculações do seu tenant
CREATE POLICY "Usuarios_podem_ver_vinculacoes_do_seu_tenant"
    ON processo_editais FOR SELECT
    USING (tenant_id = (
        SELECT (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
    ));

-- Política para permitir que usuários insiram vinculações apenas no seu tenant
CREATE POLICY "Usuarios_podem_inserir_vinculacoes_no_seu_tenant"
    ON processo_editais FOR INSERT
    WITH CHECK (
        tenant_id = (
            SELECT (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
        )
    );

-- Política para permitir que usuários deletem vinculações do seu tenant
CREATE POLICY "Usuarios_podem_deletar_vinculacoes_do_seu_tenant"
    ON processo_editais FOR DELETE
    USING (tenant_id = (
        SELECT (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::UUID
    ));

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_processo_editais()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_processo_editais_updated_at ON processo_editais;
CREATE TRIGGER update_processo_editais_updated_at
    BEFORE UPDATE ON processo_editais
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_processo_editais();

-- Comentários das colunas
COMMENT ON TABLE processo_editais IS 'Armazena a vinculação entre processos administrativos e editais de pré-qualificação';
COMMENT ON COLUMN processo_editais.processo_id IS 'ID do processo administrativo (referencia processos_administrativos.id)';
COMMENT ON COLUMN processo_editais.edital_id IS 'ID do edital de pré-qualificação (referencia editais.id)';
COMMENT ON COLUMN processo_editais.tenant_id IS 'ID do tenant (isolamento multi-inquilino)';
COMMENT ON COLUMN processo_editais.data_vinculacao IS 'Data e hora da vinculação do edital ao processo';
COMMENT ON COLUMN processo_editais.observacoes IS 'Observações sobre a vinculação';

-- =====================================================
-- TESTE DA TABELA
-- =====================================================

-- Verificar se a tabela foi criada corretamente
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'processo_editais'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- INSTRUÇÕES DE USO
-- =====================================================
--
-- 1. Execute este script no seu banco Supabase
-- 2. A tabela será criada com RLS habilitado
-- 3. As vinculações serão isoladas por tenant automaticamente
-- 4. O sistema permitirá múltiplos editais por processo
--
-- Para testar após criar a tabela:
-- SELECT * FROM processo_editais;
--