-- ================================================================================================
-- 🏷️ ADICIONAR COLUNAS DE CÓDIGO PARA CLASSIFICAÇÃO DE MATERIAIS
-- ================================================================================================
-- Execute este comando no Supabase SQL Editor para adicionar as colunas de código
-- nas tabelas de grupos, classes e criar a tabela de itens de materiais
-- ================================================================================================

-- Adicionar coluna 'codigo' na tabela grupos
ALTER TABLE grupos ADD COLUMN IF NOT EXISTS codigo VARCHAR(20);

-- Adicionar coluna 'codigo' na tabela classes  
ALTER TABLE classes ADD COLUMN IF NOT EXISTS codigo VARCHAR(20);

-- Criar tabela itens_materiais se não existir
CREATE TABLE IF NOT EXISTS itens_materiais (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE,
    classe_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    codigo VARCHAR(20),
    nome VARCHAR(255) NOT NULL,
    marca_modelo_referencia VARCHAR(500),
    descricao TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_grupos_codigo ON grupos(codigo);
CREATE INDEX IF NOT EXISTS idx_classes_codigo ON classes(codigo);
CREATE INDEX IF NOT EXISTS idx_itens_materiais_codigo ON itens_materiais(codigo);
CREATE INDEX IF NOT EXISTS idx_itens_materiais_grupo_id ON itens_materiais(grupo_id);
CREATE INDEX IF NOT EXISTS idx_itens_materiais_classe_id ON itens_materiais(classe_id);

-- Adicionar constraints de unicidade para os códigos (opcional)
-- ALTER TABLE grupos ADD CONSTRAINT grupos_codigo_unique UNIQUE (codigo);
-- ALTER TABLE classes ADD CONSTRAINT classes_codigo_unique UNIQUE (codigo);
-- ALTER TABLE itens_materiais ADD CONSTRAINT itens_materiais_codigo_unique UNIQUE (codigo);

-- Trigger para atualizar timestamp na tabela itens_materiais
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_itens_materiais_updated_at 
    BEFORE UPDATE ON itens_materiais 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários para documentação
COMMENT ON COLUMN grupos.codigo IS 'Código único do grupo (ex: GRP001)';
COMMENT ON COLUMN classes.codigo IS 'Código único da classe (ex: CLS001)';
COMMENT ON COLUMN itens_materiais.codigo IS 'Código único do item (ex: ITM001)';
COMMENT ON COLUMN itens_materiais.marca_modelo_referencia IS 'Marca e modelo de referência do item';

-- Atualizar grupos existentes com códigos automáticos (opcional)
-- Descomente as linhas abaixo se quiser gerar códigos para registros existentes

/*
DO $$
DECLARE
    grupo_record RECORD;
    contador INTEGER := 1;
BEGIN
    FOR grupo_record IN SELECT id FROM grupos WHERE codigo IS NULL ORDER BY created_at
    LOOP
        UPDATE grupos 
        SET codigo = 'GRP' || LPAD(contador::text, 3, '0')
        WHERE id = grupo_record.id;
        contador := contador + 1;
    END LOOP;
END $$;
*/

/*
DO $$
DECLARE
    classe_record RECORD;
    contador INTEGER := 1;
BEGIN
    FOR classe_record IN SELECT id FROM classes WHERE codigo IS NULL ORDER BY created_at
    LOOP
        UPDATE classes 
        SET codigo = 'CLS' || LPAD(contador::text, 3, '0')
        WHERE id = classe_record.id;
        contador := contador + 1;
    END LOOP;
END $$;
*/

-- ================================================================================================
-- 📋 INSTRUÇÕES DE USO:
-- ================================================================================================
-- 1. Copie todo este script
-- 2. Vá para o Supabase Dashboard > SQL Editor
-- 3. Cole o script e execute
-- 4. As colunas 'codigo' serão adicionadas nas tabelas grupos e classes
-- 5. A tabela itens_materiais será criada com todas as colunas necessárias
-- 6. Se quiser gerar códigos para registros existentes, descomente e execute os blocos DO $$ no final
-- ================================================================================================