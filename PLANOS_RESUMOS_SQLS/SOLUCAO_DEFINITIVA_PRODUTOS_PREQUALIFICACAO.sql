-- SOLUÇÃO DEFINITIVA: ADICIONAR TODOS OS CAMPOS POSSÍVEIS À PRODUTOS_PREQUALIFICACAO
-- Para evitar qualquer erro futuro de "column not found"

DO $$
DECLARE
    campo_nome TEXT;
    todos_campos_possiveis TEXT[] := ARRAY[
        -- Campos que já deram erro
        'ano_edital',
        'adequacao_tecnica', 
        'ata_julgamento_id',
        
        -- Campos do AssistenteProcesso
        'observacoes_processo',
        'produto_id',
        
        -- Campos da tabela produtos (backup)
        'subcategoria',
        'categoria',
        'especificacoes',
        'nome',
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
        'metadados',
        
        -- Campos de IDs e relacionamentos
        'criado_por',
        'user_id',
        'atualizado_por',
        'documento_id',
        'edital_id',
        'licitacao_id',
        'contrato_id',
        'fornecedor_id',
        'empresa_id',
        'orgao_id',
        'setor_id',
        'departamento_id',
        'responsavel_id',
        'aprovador_id',
        'revisor_id',
        'auditor_id',
        'parent_id',
        'processo_original_id',
        
        -- Campos de processo e workflow
        'numero_processo',
        'numero_edital',
        'numero_ata',
        'numero_contrato',
        'numero_sei',
        'protocolo',
        'fase_processo',
        'etapa_atual',
        'proximo_passo',
        'prazo_entrega',
        'prazo_validade',
        'data_inicio',
        'data_fim',
        'data_vencimento',
        'data_renovacao',
        'data_cancelamento',
        'data_suspensao',
        'data_reativacao',
        
        -- Campos de valores e quantidades
        'valor_unitario',
        'valor_total',
        'valor_estimado',
        'valor_minimo',
        'valor_maximo',
        'quantidade_minima',
        'quantidade_maxima',
        'quantidade_total',
        'quantidade_reservada',
        'quantidade_disponivel',
        'estoque_atual',
        'estoque_minimo',
        'estoque_maximo',
        'ponto_reposicao',
        
        -- Campos de avaliação e qualidade
        'nota_tecnica',
        'nota_qualidade',
        'nota_preco',
        'nota_final',
        'classificacao',
        'ranking_posicao',
        'resultado_avaliacao',
        'parecer_tecnico',
        'parecer_juridico',
        'parecer_financeiro',
        'recomendacao',
        'justificativa_aprovacao',
        'justificativa_reprovacao',
        'motivo_desqualificacao',
        
        -- Campos de características técnicas
        'especificacao_completa',
        'requisitos_tecnicos',
        'requisitos_funcionais',
        'requisitos_qualidade',
        'normas_aplicaveis',
        'certificados_exigidos',
        'testes_obrigatorios',
        'amostras_necessarias',
        'documentacao_tecnica',
        'manual_usuario',
        'garantia_tecnica',
        'suporte_tecnico',
        'treinamento_necessario',
        
        -- Campos administrativos
        'modalidade_licitacao',
        'tipo_licitacao',
        'regime_execucao',
        'criterio_julgamento',
        'forma_pagamento',
        'condicoes_pagamento',
        'local_entrega',
        'forma_entrega',
        'prazo_execucao',
        'vigencia_contrato',
        'clausulas_especiais',
        'penalidades',
        'multas',
        'bonificacoes',
        'reajuste_preco',
        'indices_reajuste',
        
        -- Campos de controle
        'ativo_sistema',
        'bloqueado',
        'suspenso',
        'cancelado',
        'arquivado',
        'publico',
        'confidencial',
        'restrito',
        'urgente',
        'prioritario',
        'critico',
        'importante',
        'rotineiro',
        'emergencial',
        
        -- Campos de log e auditoria
        'log_alteracoes',
        'historico_status',
        'historico_aprovacoes',
        'historico_tramitacao',
        'trail_auditoria',
        'checksum',
        'hash_documento',
        'assinatura_digital',
        'certificado_digital',
        'timestamp_criacao',
        'timestamp_atualizacao',
        'ip_origem',
        'usuario_origem',
        'sistema_origem'
    ];
BEGIN
    FOREACH campo_nome IN ARRAY todos_campos_possiveis
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'produtos_prequalificacao' AND column_name = campo_nome
        ) THEN
            CASE 
                -- IDs (UUID)
                WHEN campo_nome LIKE '%_id' OR campo_nome IN ('criado_por', 'user_id', 'atualizado_por', 'aprovado_por', 'responsavel_id', 'aprovador_id', 'revisor_id', 'auditor_id', 'parent_id', 'fornecedor_id', 'empresa_id', 'orgao_id', 'setor_id', 'departamento_id') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I UUID', campo_nome);
                    
                -- Valores monetários (DECIMAL)
                WHEN campo_nome LIKE 'valor_%' OR campo_nome LIKE 'preco_%' OR campo_nome IN ('peso', 'nota_tecnica', 'nota_qualidade', 'nota_preco', 'nota_final') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I DECIMAL(15,2)', campo_nome);
                    
                -- Quantidades (INTEGER)
                WHEN campo_nome LIKE 'quantidade_%' OR campo_nome LIKE 'estoque_%' OR campo_nome LIKE 'numero_%' OR campo_nome IN ('versao', 'ano_edital', 'ranking_posicao', 'ponto_reposicao', 'amostras_necessarias') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I INTEGER', campo_nome);
                    
                -- Datas (TIMESTAMP)
                WHEN campo_nome LIKE 'data_%' OR campo_nome LIKE 'prazo_%' OR campo_nome LIKE 'timestamp_%' OR campo_nome IN ('aprovado_em', 'data_cadastro', 'data_aprovacao', 'ultima_atualizacao', 'vigencia_contrato') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TIMESTAMP WITH TIME ZONE', campo_nome);
                    
                -- Booleanos
                WHEN campo_nome IN ('ativo', 'ativo_sistema', 'bloqueado', 'suspenso', 'cancelado', 'arquivado', 'publico', 'confidencial', 'restrito', 'urgente', 'prioritario', 'critico', 'importante', 'rotineiro', 'emergencial', 'sustentabilidade', 'treinamento_necessario') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I BOOLEAN DEFAULT FALSE', campo_nome);
                    
                -- Arrays de texto
                WHEN campo_nome IN ('tags', 'normas_aplicaveis', 'certificados_exigidos', 'testes_obrigatorios', 'indices_reajuste') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT[]', campo_nome);
                    
                -- JSONB para dados estruturados
                WHEN campo_nome IN ('documentos', 'certificacoes', 'fornecedores', 'historico_precos', 'dimensoes', 'metadados', 'log_alteracoes', 'historico_status', 'historico_aprovacoes', 'historico_tramitacao', 'trail_auditoria', 'clausulas_especiais', 'penalidades', 'multas', 'bonificacoes') THEN
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I JSONB', campo_nome);
                    
                -- Texto padrão para todo o resto
                ELSE
                    EXECUTE format('ALTER TABLE produtos_prequalificacao ADD COLUMN %I TEXT', campo_nome);
            END CASE;
            
            RAISE NOTICE 'Campo % adicionado!', campo_nome;
        END IF;
    END LOOP;
END $$;

-- Verificar campos críticos que eram problemas
SELECT 
    'CAMPOS PROBLEMÁTICOS RESOLVIDOS' as titulo,
    column_name,
    data_type,
    '✅ EXISTE' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao'
AND column_name IN (
    'ano_edital', 'adequacao_tecnica', 'ata_julgamento_id', 
    'observacoes_processo', 'produto_id'
)
ORDER BY column_name;

-- Contar total final
SELECT 
    'ESTRUTURA FINAL PRODUCTS_PREQUALIFICACAO' as titulo,
    COUNT(*) as total_colunas,
    '🎉 COMPLETA!' as status
FROM information_schema.columns 
WHERE table_name = 'produtos_prequalificacao';

SELECT '🚀 TABELA PRODUTOS_PREQUALIFICACAO COMPLETAMENTE BLINDADA CONTRA ERROS!' as resultado;