-- ================================================================================================
-- 🔧 VERIFICAR E CRIAR COLUNAS DE CLASSIFICAÇÃO - SCRIPT DE DIAGNÓSTICO
-- ================================================================================================
-- Execute este script para verificar se as colunas existem e criá-las se necessário
-- ================================================================================================

-- 1. VERIFICAR SE AS TABELAS E COLUNAS EXISTEM
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('grupos', 'classes', 'itens_materiais')
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- 2. FORÇAR CRIAÇÃO DAS COLUNAS (SEM IF NOT EXISTS para garantir execução)
ALTER TABLE grupos ADD COLUMN codigo VARCHAR(20);
ALTER TABLE classes ADD COLUMN codigo VARCHAR(20);

-- 3. CRIAR TABELA ITENS_MATERIAIS
CREATE TABLE itens_materiais (
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

-- 4. CRIAR ÍNDICES
CREATE INDEX idx_grupos_codigo ON grupos(codigo);
CREATE INDEX idx_classes_codigo ON classes(codigo);
CREATE INDEX idx_itens_materiais_codigo ON itens_materiais(codigo);
CREATE INDEX idx_itens_materiais_grupo_id ON itens_materiais(grupo_id);
CREATE INDEX idx_itens_materiais_classe_id ON itens_materiais(classe_id);

-- 5. VERIFICAR NOVAMENTE APÓS CRIAÇÃO
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('grupos', 'classes', 'itens_materiais')
    AND table_schema = 'public'
    AND column_name = 'codigo'
ORDER BY table_name;

-- 6. TESTAR INSERÇÃO DE DADOS
-- Teste inserir um grupo com código
INSERT INTO grupos (nome, descricao, codigo) 
VALUES ('Teste Grupo', 'Grupo de teste', 'GRP001')
ON CONFLICT DO NOTHING;

-- Verificar se foi inserido
SELECT id, nome, codigo FROM grupos WHERE codigo = 'GRP001';