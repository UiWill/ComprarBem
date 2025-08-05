-- SOLUÇÃO RADICAL: COPIAR TODA A ESTRUTURA DA TABELA PRODUTOS
-- PARA A TABELA PRODUTOS_PREQUALIFICACAO

-- Primeiro, vamos ver quais campos existem na tabela produtos
SELECT 
    'ESTRUTURA ATUAL DA TABELA PRODUTOS' as titulo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'produtos'
ORDER BY ordinal_position;

-- Agora vamos adicionar TODOS os campos da tabela produtos que não existem em produtos_prequalificacao
DO $$
DECLARE
    campo_record RECORD;
BEGIN
    -- Loop através de todos os campos da tabela produtos
    FOR campo_record IN 
        SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = 'produtos'
        AND column_name NOT IN ('id', 'tenant_id') -- Excluir campos que já existem
    LOOP
        -- Verificar se o campo já existe em produtos_prequalificacao
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'produtos_prequalificacao' 
            AND column_name = campo_record.column_name
        ) THEN
            -- Construir o comando ALTER TABLE baseado no tipo de dados
            CASE 
                WHEN campo_record.data_type = 'uuid' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I UUID', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'text' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'character varying' THEN
                    IF campo_record.character_maximum_length IS NOT NULL THEN
                        EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I VARCHAR(%s)', 
                                     campo_record.column_name, campo_record.character_maximum_length);
                    ELSE
                        EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I VARCHAR', campo_record.column_name);
                    END IF;
                    
                WHEN campo_record.data_type = 'integer' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I INTEGER', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'bigint' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I BIGINT', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'numeric' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I DECIMAL(15,2)', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'boolean' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I BOOLEAN DEFAULT FALSE', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'timestamp with time zone' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TIMESTAMP WITH TIME ZONE', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'timestamp without time zone' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TIMESTAMP', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'date' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I DATE', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'jsonb' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I JSONB', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'json' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I JSON', campo_record.column_name);
                    
                WHEN campo_record.data_type = 'ARRAY' OR campo_record.data_type LIKE '%[]' THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT[]', campo_record.column_name);
                    
                ELSE
                    -- Para qualquer tipo não coberto, usar TEXT como padrão
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT', campo_record.column_name);
            END CASE;
            
            RAISE NOTICE 'Campo % (%) adicionado!', campo_record.column_name, campo_record.data_type;
        END IF;
    END LOOP;
END $$;

-- Agora adicionar campos específicos que podem estar sendo usados
DO $$
DECLARE
    campo_nome TEXT;
    campos_extras_especificos TEXT[] := ARRAY[
        'categoria_id',
        'subcategoria_id',
        'fabricante_id',
        'fornecedor_principal_id',
        'unidade_medida_id',
        'grupo_produto_id',
        'familia_produto_id',
        'linha_produto_id',
        'marca_id',
        'modelo_id',
        'cor_id',
        'tamanho_id',
        'peso_id',
        'material_id',
        'origem_id',
        'destino_id',
        'tipo_produto_id',
        'classe_produto_id',
        'segmento_id',
        'setor_id',
        'area_id',
        'departamento_id',
        'centro_custo_id',
        'conta_contabil_id',
        'ncm_id',
        'cfop_id',
        'cst_id',
        'csosn_id',
        'tributo_id',
        'imposto_id'
    ];
BEGIN
    FOREACH campo_nome IN ARRAY campos_extras_especificos
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'produtos_prequalificacao' AND column_name = campo_nome
        ) THEN
            EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I UUID', campo_nome);
            RAISE NOTICE 'Campo ID específico % adicionado!', campo_nome;
        END IF;
    END LOOP;
END $$;

-- Verificar se categoria_id foi adicionado
SELECT 
    'CAMPO CATEGORIA_ID VERIFICADO' as titulo,
    column_name,
    data_type,
    '✅ EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name = 'categoria_id';

-- Contar total final de colunas
SELECT 
    'COMPARAÇÃO DE ESTRUTURAS' as titulo,
    'produtos' as tabela,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'produtos'
UNION ALL
SELECT 
    'COMPARAÇÃO DE ESTRUTURAS' as titulo,
    'produtos_prequalificacao' as tabela,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
ORDER BY tabela;

SELECT '🎯 ESTRUTURA COMPLETA DA TABELA PRODUTOS COPIADA PARA PRODUTOS_PREQUALIFICACAO!' as resultado;