-- Add ALL missing columns to atas_julgamento table
-- This includes import functionality AND tramitacao functionality

-- Columns for file import functionality
ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS arquivo_ata_url TEXT;

ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS arquivo_ata_nome TEXT;

ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS ata_importada_em TIMESTAMPTZ;

-- Columns for tramitacao (status change) functionality
ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS tramitada_em TIMESTAMPTZ;

ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS tramitada_por UUID;

ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS observacoes_tramitacao TEXT;

-- Add comments to document the column purposes
COMMENT ON COLUMN atas_julgamento.arquivo_ata_url IS 'URL do arquivo da ata importada no storage';
COMMENT ON COLUMN atas_julgamento.arquivo_ata_nome IS 'Nome original do arquivo da ata importada';
COMMENT ON COLUMN atas_julgamento.ata_importada_em IS 'Data e hora quando a ata foi importada';
COMMENT ON COLUMN atas_julgamento.tramitada_em IS 'Data e hora da última tramitação de status';
COMMENT ON COLUMN atas_julgamento.tramitada_por IS 'ID do usuário que fez a tramitação';
COMMENT ON COLUMN atas_julgamento.observacoes_tramitacao IS 'Observações sobre a tramitação';