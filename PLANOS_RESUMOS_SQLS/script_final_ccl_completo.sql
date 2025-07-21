-- ===================================================
-- SCRIPT DEFINITIVO - Todas as colunas CCL necessárias
-- Sistema Comprar Bem - Funcionalidade CCL
-- ===================================================

-- Primeiro executar o script de análise para verificar o estado atual:
-- EXECUTE ANTES: analisar_estrutura_produtos.sql

-- Remover views que podem estar causando conflito
DROP VIEW IF EXISTS view_produtos_ccl;

-- ===================================================
-- ADICIONAR TODAS AS COLUNAS NECESSÁRIAS
-- ===================================================
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS adequacao_tecnica TEXT CHECK (adequacao_tecnica IN ('adequado', 'inadequado', 'adequado_com_ressalvas')),
ADD COLUMN IF NOT EXISTS conformidade_documental TEXT CHECK (conformidade_documental IN ('conforme', 'nao_conforme', 'pendente')),
ADD COLUMN IF NOT EXISTS conformidade_normativa TEXT CHECK (conformidade_normativa IN ('conforme', 'nao_conforme', 'pendente')),
ADD COLUMN IF NOT EXISTS justificativa_julgamento TEXT,
ADD COLUMN IF NOT EXISTS ccl_julgado_por UUID REFERENCES usuarios(id),
ADD COLUMN IF NOT EXISTS ccl_data_julgamento TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS ccl_numero_ata TEXT,
ADD COLUMN IF NOT EXISTS ccl_status TEXT DEFAULT 'pendente_julgamento' CHECK (ccl_status IN ('pendente_julgamento', 'aprovado', 'reprovado', 'aprovado_com_ressalvas', 'em_recurso', 'homologado')),
ADD COLUMN IF NOT EXISTS recurso_interposto BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS recurso_data TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS recurso_motivo TEXT,
ADD COLUMN IF NOT EXISTS recurso_julgado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS recurso_resultado TEXT,
ADD COLUMN IF NOT EXISTS homologado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS homologado_por UUID REFERENCES usuarios(id),
ADD COLUMN IF NOT EXISTS homologado_em TIMESTAMP WITH TIME ZONE,
-- Campos adicionais identificados no código
ADD COLUMN IF NOT EXISTS observacoes_ccl TEXT,
ADD COLUMN IF NOT EXISTS base_legal TEXT,
ADD COLUMN IF NOT EXISTS requisitos_minimos TEXT CHECK (requisitos_minimos IN ('atende', 'nao_atende', 'atende_parcialmente')),
ADD COLUMN IF NOT EXISTS conformidade_legal TEXT CHECK (conformidade_legal IN ('conforme', 'nao_conforme', 'pendente')),
ADD COLUMN IF NOT EXISTS observacoes_ccl_adicional TEXT,
-- Campos que estavam faltando e causando erro
ADD COLUMN IF NOT EXISTS julgado_em TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- ===================================================
-- ATUALIZAR COLUNAS EXISTENTES SE NECESSÁRIO
-- ===================================================

-- Verificar se updated_at existe, se não, usar atualizado_em
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'produtos' AND column_name = 'updated_at'
    ) THEN
        -- Se updated_at não existe, vamos garantir que atualizado_em seja atualizado automaticamente
        ALTER TABLE produtos ALTER COLUMN atualizado_em SET DEFAULT NOW();
        
        -- Criar trigger para atualizar automaticamente
        CREATE OR REPLACE FUNCTION update_atualizado_em_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.atualizado_em = NOW();
            RETURN NEW;
        END;
        $$ language 'plpgsql';

        DROP TRIGGER IF EXISTS update_produtos_atualizado_em ON produtos;
        CREATE TRIGGER update_produtos_atualizado_em 
            BEFORE UPDATE ON produtos 
            FOR EACH ROW EXECUTE FUNCTION update_atualizado_em_column();
    END IF;
END
$$;

-- ===================================================
-- ÍNDICES PARA PERFORMANCE
-- ===================================================

CREATE INDEX IF NOT EXISTS idx_produtos_ccl_status 
    ON produtos(tenant_id, ccl_status) 
    WHERE ccl_status IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_produtos_pendente_julgamento 
    ON produtos(tenant_id, status) 
    WHERE status = 'aprovado' AND ccl_status = 'pendente_julgamento';

CREATE INDEX IF NOT EXISTS idx_produtos_recurso 
    ON produtos(tenant_id, recurso_interposto, recurso_julgado) 
    WHERE recurso_interposto = TRUE;

CREATE INDEX IF NOT EXISTS idx_produtos_homologado 
    ON produtos(tenant_id, homologado, homologado_em);

CREATE INDEX IF NOT EXISTS idx_produtos_julgado_em 
    ON produtos(tenant_id, julgado_em) 
    WHERE julgado_em IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_produtos_atualizado_em 
    ON produtos(atualizado_em);

-- ===================================================
-- FUNÇÕES AUXILIARES
-- ===================================================

CREATE OR REPLACE FUNCTION registrar_julgamento_ccl_completo(
    produto_uuid UUID,
    usuario_uuid UUID,
    dados_julgamento JSONB
)
RETURNS VOID AS $$
DECLARE
    status_resultado TEXT;
BEGIN
    -- Determinar status baseado nos dados
    IF (dados_julgamento->>'adequacao_tecnica') = 'inadequado' OR 
       (dados_julgamento->>'conformidade_documental') = 'nao_conforme' OR 
       (dados_julgamento->>'conformidade_legal') = 'nao_conforme' THEN
        status_resultado := 'reprovado';
    ELSIF (dados_julgamento->>'adequacao_tecnica') = 'adequado_com_ressalvas' OR
          (dados_julgamento->>'requisitos_minimos') = 'atende_parcialmente' THEN
        status_resultado := 'aprovado_com_ressalvas';
    ELSE
        status_resultado := 'aprovado';
    END IF;

    -- Atualizar o produto com TODOS os dados do julgamento
    UPDATE produtos SET
        -- Campos de avaliação
        adequacao_tecnica = dados_julgamento->>'adequacao_tecnica',
        conformidade_documental = COALESCE(dados_julgamento->>'conformidade_documental', 'pendente'),
        conformidade_normativa = COALESCE(dados_julgamento->>'conformidade_normativa', 'pendente'),
        requisitos_minimos = dados_julgamento->>'requisitos_minimos',
        conformidade_legal = dados_julgamento->>'conformidade_legal',
        
        -- Campos de justificativa e base legal
        justificativa_julgamento = dados_julgamento->>'justificativa_julgamento',
        base_legal = dados_julgamento->>'base_legal',
        observacoes_ccl = dados_julgamento->>'observacoes_ccl',
        observacoes_ccl_adicional = dados_julgamento->>'observacoes_ccl_adicional',
        
        -- Campos de controle CCL
        ccl_julgado_por = usuario_uuid,
        ccl_data_julgamento = NOW(),
        ccl_numero_ata = dados_julgamento->>'ccl_numero_ata',
        ccl_status = status_resultado,
        
        -- Campos de timestamp
        julgado_em = NOW(),
        atualizado_em = NOW()
    WHERE id = produto_uuid;

    -- Verificar se a atualização foi bem-sucedida
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado', produto_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- RECRIAR VIEW OTIMIZADA
-- ===================================================

CREATE OR REPLACE VIEW view_produtos_ccl AS
SELECT 
    p.*,
    u_julgador.nome as nome_julgador,
    u_homologador.nome as nome_homologador,
    c.nome as categoria_nome,
    CASE 
        WHEN p.ccl_status = 'pendente_julgamento' THEN 'Pendente de Julgamento'
        WHEN p.ccl_status = 'aprovado' THEN 'Aprovado'
        WHEN p.ccl_status = 'reprovado' THEN 'Reprovado'
        WHEN p.ccl_status = 'aprovado_com_ressalvas' THEN 'Aprovado com Ressalvas'
        WHEN p.ccl_status = 'em_recurso' THEN 'Em Recurso'
        WHEN p.ccl_status = 'homologado' THEN 'Homologado'
        ELSE 'Status não definido'
    END as status_ccl_descricao,
    CASE 
        WHEN p.recurso_interposto AND NOT p.recurso_julgado THEN 
            EXTRACT(days FROM (NOW() - p.recurso_data))
        ELSE NULL
    END as dias_recurso_pendente,
    -- Campos de auditoria
    COALESCE(p.atualizado_em, p.updated_at, p.created_at) as ultima_atualizacao
FROM produtos p
LEFT JOIN usuarios u_julgador ON p.ccl_julgado_por = u_julgador.id
LEFT JOIN usuarios u_homologador ON p.homologado_por = u_homologador.id
LEFT JOIN categorias c ON p.categoria_id = c.id
WHERE p.status = 'aprovado'; -- Só produtos aprovados pela CPM chegam na CCL

-- ===================================================
-- COMENTÁRIOS NAS COLUNAS
-- ===================================================

COMMENT ON COLUMN produtos.adequacao_tecnica IS 'Avaliação técnica CCL (adequado/inadequado/adequado_com_ressalvas)';
COMMENT ON COLUMN produtos.conformidade_documental IS 'Conformidade documentação (conforme/nao_conforme/pendente)';
COMMENT ON COLUMN produtos.conformidade_normativa IS 'Conformidade normas técnicas (conforme/nao_conforme/pendente)';
COMMENT ON COLUMN produtos.justificativa_julgamento IS 'Justificativa detalhada do julgamento CCL';
COMMENT ON COLUMN produtos.ccl_julgado_por IS 'Usuário responsável pelo julgamento CCL';
COMMENT ON COLUMN produtos.ccl_data_julgamento IS 'Data e hora do julgamento CCL';
COMMENT ON COLUMN produtos.ccl_numero_ata IS 'Número da ata de julgamento CCL';
COMMENT ON COLUMN produtos.ccl_status IS 'Status atual no processo CCL';
COMMENT ON COLUMN produtos.recurso_interposto IS 'Indica se foi interposto recurso';
COMMENT ON COLUMN produtos.recurso_data IS 'Data de interposição do recurso';
COMMENT ON COLUMN produtos.recurso_motivo IS 'Motivo alegado no recurso';
COMMENT ON COLUMN produtos.recurso_julgado IS 'Indica se o recurso foi julgado';
COMMENT ON COLUMN produtos.recurso_resultado IS 'Resultado do julgamento do recurso';
COMMENT ON COLUMN produtos.homologado IS 'Indica se foi homologado pela autoridade competente';
COMMENT ON COLUMN produtos.homologado_por IS 'Usuário que homologou o processo';
COMMENT ON COLUMN produtos.homologado_em IS 'Data e hora da homologação';
COMMENT ON COLUMN produtos.observacoes_ccl IS 'Observações gerais da CCL';
COMMENT ON COLUMN produtos.base_legal IS 'Base legal do julgamento (Lei 14.133/2021, ABNT, etc.)';
COMMENT ON COLUMN produtos.requisitos_minimos IS 'Avaliação requisitos mínimos (atende/nao_atende/atende_parcialmente)';
COMMENT ON COLUMN produtos.conformidade_legal IS 'Conformidade dispositivos legais (conforme/nao_conforme/pendente)';
COMMENT ON COLUMN produtos.observacoes_ccl_adicional IS 'Observações complementares CCL';
COMMENT ON COLUMN produtos.julgado_em IS 'Data e hora quando produto foi julgado';
COMMENT ON COLUMN produtos.atualizado_em IS 'Data e hora da última atualização do registro';

-- ===================================================
-- VERIFICAÇÃO FINAL COMPLETA
-- ===================================================

-- 1. Verificar TODAS as colunas CCL
SELECT 
    'COLUNAS CCL CRIADAS' as verificacao,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'produtos' 
AND column_name IN (
    'adequacao_tecnica', 
    'conformidade_documental', 
    'conformidade_normativa',
    'justificativa_julgamento',
    'ccl_julgado_por',
    'ccl_data_julgamento',
    'ccl_numero_ata',
    'ccl_status',
    'recurso_interposto',
    'recurso_data',
    'recurso_motivo',
    'recurso_julgado',
    'recurso_resultado',
    'homologado',
    'homologado_por',
    'homologado_em',
    'observacoes_ccl',
    'base_legal',
    'requisitos_minimos',
    'conformidade_legal',
    'observacoes_ccl_adicional',
    'julgado_em',
    'atualizado_em'
)
ORDER BY ordinal_position;

-- 2. Verificar funções criadas
SELECT 
    'FUNCOES CRIADAS' as verificacao,
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_name LIKE '%ccl%'
AND routine_schema = 'public';

-- 3. Verificar view recriada
SELECT 
    'VIEW RECRIADA' as verificacao,
    schemaname, 
    viewname, 
    LENGTH(definition) as tamanho_definicao
FROM pg_views 
WHERE viewname = 'view_produtos_ccl';

-- 4. Verificar índices criados
SELECT 
    'INDICES CRIADOS' as verificacao,
    indexname,
    tablename
FROM pg_indexes 
WHERE tablename = 'produtos' 
AND indexname LIKE '%ccl%';

-- ===================================================
-- TESTE DE FUNCIONALIDADE
-- ===================================================

-- Verificar se podemos inserir dados de teste sem erro
/*
-- DESCOMENTE PARA TESTAR (substitua pelos IDs reais):
SELECT registrar_julgamento_ccl_completo(
    'UUID_PRODUTO_TESTE'::UUID,
    'UUID_USUARIO_TESTE'::UUID,
    '{"adequacao_tecnica": "adequado", "base_legal": "Lei 14.133/2021", "requisitos_minimos": "atende", "conformidade_legal": "conforme"}'::JSONB
);
*/

-- ===================================================
-- SCRIPT FINALIZADO COM SUCESSO
-- ===================================================
SELECT 'SCRIPT EXECUTADO COM SUCESSO! Todas as colunas CCL foram criadas.' as resultado;