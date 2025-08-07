-- ADICIONAR TODOS OS CAMPOS POSSÍVEIS À TABELA PRODUTOS_PREQUALIFICACAO
-- Baseado na estrutura da tabela produtos para evitar erros futuros

-- Lista de campos que podem ser copiados da tabela produtos
DO $$
DECLARE
    campo_nome TEXT;
    campos_para_adicionar TEXT[] := ARRAY[
        'ano_edital',
        'adequacao_tecnica', 
        'observacoes_processo',
        'subcategoria',
        'categoria',
        'especificacoes',
        'nome',
        'produto_id',
        'criado_por',
        'user_id',
        'descricao',
        'preco_referencia',
        'unidade_medida',
        'codigo_produto',
        'ativo',
        'aprovado_em',
        'aprovado_por',
        'observacoes',
        'imagem_url',
        'documentos',
        'certificacoes',
        'fornecedores',
        'historico_precos',
        'data_cadastro',
        'data_aprovacao',
        'ultima_atualizacao',
        'versao',
        'tags',
        'origem',
        'destino',
        'peso',
        'dimensoes',
        'cor',
        'material',
        'garantia',
        'vida_util',
        'sustentabilidade',
        'normas_tecnicas',
        'certificados_qualidade',
        'metadados'
    ];
BEGIN
    FOREACH campo_nome IN ARRAY campos_para_adicionar
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'produtos_prequalificacao' AND column_name = campo_nome
        ) THEN
            CASE 
                WHEN campo_nome IN ('preco_referencia', 'peso') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I DECIMAL(15,2)', campo_nome);
                WHEN campo_nome IN ('ativo', 'sustentabilidade') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I BOOLEAN DEFAULT FALSE', campo_nome);
                WHEN campo_nome IN ('produto_id', 'criado_por', 'user_id', 'aprovado_por') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I UUID', campo_nome);
                WHEN campo_nome IN ('aprovado_em', 'data_cadastro', 'data_aprovacao', 'ultima_atualizacao') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TIMESTAMP WITH TIME ZONE', campo_nome);
                WHEN campo_nome IN ('versao', 'ano_edital') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I INTEGER', campo_nome);
                WHEN campo_nome IN ('documentos', 'certificacoes', 'fornecedores', 'historico_precos', 'tags', 'dimensoes', 'metadados') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I JSONB', campo_nome);
                WHEN campo_nome IN ('tags') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT[]', campo_nome);
                ELSE
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT', campo_nome);
            END CASE;
            
            RAISE NOTICE 'Campo % adicionado!', campo_nome;
        END IF;
    END LOOP;
END $$;

-- Verificar campos críticos que foram adicionados
SELECT 
    'CAMPOS CRÍTICOS ADICIONADOS' as titulo,
    column_name,
    data_type,
    'EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name IN (
    'ano_edital', 'adequacao_tecnica', 'observacoes_processo', 'subcategoria', 
    'categoria', 'especificacoes', 'nome', 'produto_id', 'descricao',
    'preco_referencia', 'unidade_medida', 'codigo_produto'
)
ORDER BY column_name;

-- Contar total final de colunas
SELECT 
    'TOTAL FINAL DE COLUNAS' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao';

-- Mostrar estrutura completa da tabela
SELECT 
    'ESTRUTURA COMPLETA PRODUTOS_PREQUALIFICACAO' as titulo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
ORDER BY ordinal_position;

SELECT '🎉 TABELA PRODUTOS_PREQUALIFICACAO COMPLETAMENTE ATUALIZADA!' as status;