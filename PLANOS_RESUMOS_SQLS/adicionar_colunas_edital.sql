-- ================================================================================================
-- 🔗 ADICIONAR COLUNAS PARA VINCULAÇÃO DE EDITAIS
-- ================================================================================================
-- Execute este comando no Supabase SQL Editor para adicionar as colunas necessárias
-- para vincular produtos aos editais de pré-qualificação
-- ================================================================================================

-- Adicionar colunas para vinculação de editais na tabela produtos
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS edital_prequalificacao TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS edital_id UUID REFERENCES editais(id);

-- Adicionar colunas para processo de despadronização 
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS processo_cancelamento TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS motivo_despadronizacao TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS data_despadronizacao DATE;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS documento_despadronizacao TEXT;

-- Adicionar coluna para timestamp de atualização (se não existir)
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_produtos_edital_id ON produtos(edital_id);
CREATE INDEX IF NOT EXISTS idx_produtos_edital_prequalificacao ON produtos(edital_prequalificacao);

-- Comentários para documentação
COMMENT ON COLUMN produtos.edital_prequalificacao IS 'Texto descritivo do edital de pré-qualificação vinculado';
COMMENT ON COLUMN produtos.edital_id IS 'ID do edital de pré-qualificação vinculado';
COMMENT ON COLUMN produtos.processo_cancelamento IS 'Número do processo de cancelamento/despadronização';
COMMENT ON COLUMN produtos.motivo_despadronizacao IS 'Motivo detalhado da despadronização';
COMMENT ON COLUMN produtos.data_despadronizacao IS 'Data de vigência da despadronização';
COMMENT ON COLUMN produtos.documento_despadronizacao IS 'URL do documento comprobatório da despadronização';