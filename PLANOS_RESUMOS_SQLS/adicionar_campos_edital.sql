-- ===================================================
-- Script para adicionar campos de edital aos produtos
-- Sistema Comprar Bem - Funcionalidade de Editais
-- ===================================================

-- Adicionar campos na tabela produtos
ALTER TABLE produtos 
ADD COLUMN numero_edital TEXT,
ADD COLUMN ano_edital INTEGER,
ADD COLUMN tem_edital BOOLEAN DEFAULT FALSE;

-- ===================================================
-- Índices para performance
-- ===================================================

-- Índice para busca por edital
CREATE INDEX IF NOT EXISTS idx_produtos_edital 
    ON produtos(tenant_id, numero_edital, ano_edital) 
    WHERE tem_edital = TRUE;

-- Índice para filtrar produtos com edital
CREATE INDEX IF NOT EXISTS idx_produtos_tem_edital 
    ON produtos(tenant_id, tem_edital);

-- ===================================================
-- Função para gerar sugestão de número de edital
-- ===================================================

CREATE OR REPLACE FUNCTION gerar_sugestao_edital(tenant_uuid UUID, ano_desejado INTEGER DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    ano_atual INTEGER := COALESCE(ano_desejado, EXTRACT(YEAR FROM NOW()));
    proximo_numero INTEGER;
BEGIN
    -- Buscar próximo número sequencial para o ano e tenant
    SELECT COALESCE(MAX(
        CASE 
            WHEN numero_edital ~ '^\d{3}/\d{4}$' 
            AND ano_edital = ano_atual
            THEN CAST(split_part(numero_edital, '/', 1) AS INTEGER)
            ELSE 0
        END
    ), 0) + 1
    INTO proximo_numero
    FROM produtos 
    WHERE tenant_id = tenant_uuid 
    AND tem_edital = TRUE;
    
    -- Retornar número formatado
    RETURN LPAD(proximo_numero::TEXT, 3, '0') || '/' || ano_atual::TEXT;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- Função para verificar se número já existe
-- ===================================================

CREATE OR REPLACE FUNCTION verificar_edital_existente(
    tenant_uuid UUID, 
    numero_edital_param TEXT, 
    ano_edital_param INTEGER,
    produto_id_excluir UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    existe BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM produtos 
        WHERE tenant_id = tenant_uuid 
        AND numero_edital = numero_edital_param 
        AND ano_edital = ano_edital_param
        AND tem_edital = TRUE
        AND (produto_id_excluir IS NULL OR id != produto_id_excluir)
    ) INTO existe;
    
    RETURN existe;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- Comentários nas colunas
-- ===================================================

COMMENT ON COLUMN produtos.numero_edital IS 
'Número do edital de pré-qualificação (formato: 001/2024)';

COMMENT ON COLUMN produtos.ano_edital IS 
'Ano do edital de pré-qualificação';

COMMENT ON COLUMN produtos.tem_edital IS 
'Indica se o produto está vinculado a um edital';

-- ===================================================
-- Exemplos de uso das funções
-- ===================================================

/*
-- Gerar sugestão para o ano atual
SELECT gerar_sugestao_edital('uuid-do-tenant');

-- Gerar sugestão para ano específico
SELECT gerar_sugestao_edital('uuid-do-tenant', 2024);

-- Verificar se edital já existe
SELECT verificar_edital_existente('uuid-do-tenant', '001/2024', 2024);
*/

-- ===================================================
-- Verificação final
-- ===================================================

-- Verificar se as colunas foram criadas
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos' 
AND column_name IN ('numero_edital', 'ano_edital', 'tem_edital')
ORDER BY ordinal_position;

-- Verificar se as funções foram criadas
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name IN ('gerar_sugestao_edital', 'verificar_edital_existente')
AND routine_schema = 'public';

-- ===================================================
-- Script finalizado
-- ===================================================