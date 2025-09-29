-- Add missing columns to atas_julgamento table for file import functionality
-- These columns support the ata import feature in the CCL dashboard

-- Add column for storing the URL of the imported ata file
ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS arquivo_ata_url TEXT;

-- Add column for storing the original filename of the imported ata
ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS arquivo_ata_nome TEXT;

-- Add column for storing the timestamp when the ata was imported
ALTER TABLE atas_julgamento
ADD COLUMN IF NOT EXISTS ata_importada_em TIMESTAMPTZ;

-- Add comments to document the column purposes
COMMENT ON COLUMN atas_julgamento.arquivo_ata_url IS 'URL do arquivo da ata importada no storage';
COMMENT ON COLUMN atas_julgamento.arquivo_ata_nome IS 'Nome original do arquivo da ata importada';
COMMENT ON COLUMN atas_julgamento.ata_importada_em IS 'Data e hora quando a ata foi importada';