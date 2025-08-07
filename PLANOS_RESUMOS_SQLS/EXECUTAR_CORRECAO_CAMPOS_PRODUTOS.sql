-- CORREÇÃO DEFINITIVA: ADICIONAR TODOS OS CAMPOS FALTANTES
-- Execute este arquivo no Supabase SQL Editor

-- Adicionar campos que estão causando erros
DO $$
DECLARE
    campo_nome TEXT;
    campos_necessarios TEXT[] := ARRAY[
        'adequacao_tecnica',
        'ano_edital', 
        'ata_julgamento_id',
        'observacoes_processo',
        'produto_id',
        'subcategoria',
        'categoria',
        'especificacoes',
        'nome',
        'descricao',
        'preco_referencia',
        'unidade_medida',
        'codigo_produto',
        'base_legal',
        'fundamentacao_juridica',
        'motivacao',
        'impacto_esperado',
        'riscos_identificados',
        'medidas_mitigadoras',
        'prazo_entrega',
        'local_entrega',
        'observacoes',
        'anexos',
        'metadados',
        'status',
        'ativo',
        'aprovado_em',
        'aprovado_por',
        'data_cadastro',
        'data_aprovacao',
        'ultima_atualizacao',
        'criado_por',
        'user_id'
    ];
BEGIN
    FOREACH campo_nome IN ARRAY campos_necessarios
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'produtos_prequalificacao' AND column_name = campo_nome
        ) THEN
            CASE 
                -- IDs como UUID
                WHEN campo_nome IN ('ata_julgamento_id', 'produto_id', 'aprovado_por', 'criado_por', 'user_id') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I UUID', campo_nome);
                    
                -- Valores decimais
                WHEN campo_nome IN ('preco_referencia') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I DECIMAL(15,2)', campo_nome);
                    
                -- Inteiros
                WHEN campo_nome IN ('ano_edital') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I INTEGER', campo_nome);
                    
                -- Booleanos
                WHEN campo_nome IN ('ativo') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I BOOLEAN DEFAULT FALSE', campo_nome);
                    
                -- Timestamps
                WHEN campo_nome IN ('aprovado_em', 'data_cadastro', 'data_aprovacao', 'ultima_atualizacao') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TIMESTAMP WITH TIME ZONE', campo_nome);
                    
                -- JSONB para dados estruturados
                WHEN campo_nome IN ('anexos', 'metadados') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I JSONB', campo_nome);
                    
                -- Texto padrão
                ELSE
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT', campo_nome);
            END CASE;
            
            RAISE NOTICE 'Campo % adicionado com sucesso!', campo_nome;
        ELSE
            RAISE NOTICE 'Campo % já existe', campo_nome;
        END IF;
    END LOOP;
END $$;

-- Verificar se os campos críticos foram adicionados
SELECT 
    'VERIFICAÇÃO FINAL' as titulo,
    column_name,
    data_type,
    'EXISTE ✅' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name IN (
    'adequacao_tecnica', 'ano_edital', 'ata_julgamento_id', 
    'base_legal', 'produto_id', 'observacoes_processo'
)
ORDER BY column_name;

-- Contar total de colunas
SELECT 
    'TOTAL DE COLUNAS NA TABELA' as info,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao';

SELECT '🎉 CORREÇÃO CONCLUÍDA! Todos os campos necessários foram adicionados.' as resultado;