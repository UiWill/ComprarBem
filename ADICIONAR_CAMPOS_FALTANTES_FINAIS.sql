-- ADICIONAR CAMPOS FALTANTES FINAIS À PRODUTOS_PREQUALIFICACAO

DO $$
DECLARE
    campo_nome TEXT;
    campos_extras TEXT[] := ARRAY[
        'base_legal',
        'fundamentacao_juridica',
        'lei_aplicavel',
        'artigo_lei',
        'decreto_regulamentador',
        'resolucao_aplicavel',
        'motivacao',
        'necessidade_administrativa',
        'interesse_publico',
        'economicidade',
        'impacto_esperado',
        'riscos_identificados',
        'medidas_mitigadoras',
        'prazo_entrega',
        'local_entrega',
        'prazo_vigencia',
        'periodicidade_revisao',
        'fonte_reclamacoes',
        'observacoes_especiais',
        'observacoes_internas',
        'observacoes_juridicas',
        'observacoes_tecnicas',
        'anexos',
        'conteudo',
        'dados',
        'content',
        'body',
        'metadata',
        'status',
        'fase_processo',
        'protocolo',
        'numero_sei',
        'orgao_origem',
        'modalidade_licitacao',
        'resultado_avaliacao',
        'parecer_final',
        'decisao_final',
        'confidencial'
    ];
BEGIN
    FOREACH campo_nome IN ARRAY campos_extras
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'produtos_prequalificacao' AND column_name = campo_nome
        ) THEN
            CASE 
                WHEN campo_nome IN ('prazo_vigencia') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I INTEGER', campo_nome);
                WHEN campo_nome IN ('confidencial') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I BOOLEAN DEFAULT FALSE', campo_nome);
                WHEN campo_nome IN ('anexos', 'conteudo', 'dados', 'metadata') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I JSONB', campo_nome);
                ELSE
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT', campo_nome);
            END CASE;
            
            RAISE NOTICE 'Campo % adicionado!', campo_nome;
        END IF;
    END LOOP;
END $$;

-- Verificar se base_legal foi adicionado
SELECT 
    'CAMPO BASE_LEGAL VERIFICADO' as titulo,
    column_name,
    data_type,
    '✅ EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name = 'base_legal';

-- Verificar outros campos críticos
SELECT 
    'CAMPOS CRÍTICOS ADICIONADOS' as titulo,
    column_name,
    data_type,
    '✅ EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name IN (
    'base_legal', 'fundamentacao_juridica', 'motivacao', 
    'impacto_esperado', 'riscos_identificados', 'medidas_mitigadoras'
)
ORDER BY column_name;

-- Contar total final
SELECT 
    'TOTAL FINAL DE COLUNAS' as titulo,
    COUNT(*) as total_colunas
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao';

SELECT '🎯 CAMPO BASE_LEGAL E OUTROS ADICIONADOS COM SUCESSO!' as resultado;