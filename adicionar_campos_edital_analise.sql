-- Script para adicionar campos do edital na tabela analises
-- Execução dos apontamentos do cliente: campos para identificação do edital

-- Verificar se as colunas já existem antes de adicionar
DO $$
BEGIN
    -- Adicionar coluna edital_numero se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'analises' AND column_name = 'edital_numero'
    ) THEN
        ALTER TABLE analises ADD COLUMN edital_numero VARCHAR(20);
        COMMENT ON COLUMN analises.edital_numero IS 'Número do edital de pré-qualificação (ex: 001)';
    END IF;

    -- Adicionar coluna edital_ano se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'analises' AND column_name = 'edital_ano'
    ) THEN
        ALTER TABLE analises ADD COLUMN edital_ano VARCHAR(4);
        COMMENT ON COLUMN analises.edital_ano IS 'Ano do edital de pré-qualificação (ex: 2024)';
    END IF;
END $$;

-- Criar índice para facilitar consultas por edital
CREATE INDEX IF NOT EXISTS idx_analises_edital ON analises(edital_numero, edital_ano);

-- Atualizar registros existentes com ano atual (opcional)
-- Descomente as linhas abaixo se quiser preencher registros antigos
-- UPDATE analises 
-- SET edital_ano = EXTRACT(YEAR FROM criado_em)::VARCHAR 
-- WHERE edital_ano IS NULL;

-- Verificar se as colunas foram criadas
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'analises' 
AND column_name IN ('edital_numero', 'edital_ano')
ORDER BY column_name;