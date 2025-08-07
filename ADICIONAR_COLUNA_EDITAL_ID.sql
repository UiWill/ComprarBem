-- =====================================================
-- ADICIONAR COLUNA EDITAL_ID EM PROCESSOS_ADMINISTRATIVOS
-- =====================================================

-- Adicionar coluna edital_id para referência ao edital vinculado
ALTER TABLE processos_administrativos ADD COLUMN IF NOT EXISTS edital_id UUID;

-- Adicionar comentário explicativo
COMMENT ON COLUMN processos_administrativos.edital_id IS 'ID do edital vinculado ao processo administrativo';

-- Adicionar foreign key constraint se a tabela editais existir
DO $$
BEGIN
    -- Verificar se a tabela editais existe
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'editais') THEN
        -- Verificar se a constraint já existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_processos_administrativos_edital_id'
        ) THEN
            ALTER TABLE processos_administrativos 
            ADD CONSTRAINT fk_processos_administrativos_edital_id 
            FOREIGN KEY (edital_id) REFERENCES editais(id) ON DELETE SET NULL;
        END IF;
    END IF;
END $$;

-- Adicionar índice para performance
CREATE INDEX IF NOT EXISTS idx_processos_administrativos_edital_id ON processos_administrativos(edital_id);

-- Verificação
SELECT 'Coluna edital_id adicionada com sucesso!' as resultado;

-- Mostrar estrutura atualizada
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name = 'edital_id';

SELECT 'PRONTO! Agora a tabela processos_administrativos tem a coluna edital_id ✅' as status;