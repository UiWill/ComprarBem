-- ===================================================
-- Script para adicionar campos de julgamento CCL
-- Sistema Comprar Bem - Funcionalidade CCL
-- ===================================================

-- Adicionar campos necessários para julgamento CCL na tabela produtos
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
-- Campos adicionais usados pelo código CCL
ADD COLUMN IF NOT EXISTS observacoes_ccl TEXT,
ADD COLUMN IF NOT EXISTS base_legal TEXT,
ADD COLUMN IF NOT EXISTS requisitos_minimos TEXT CHECK (requisitos_minimos IN ('atende', 'nao_atende', 'atende_parcialmente')),
ADD COLUMN IF NOT EXISTS conformidade_legal TEXT CHECK (conformidade_legal IN ('conforme', 'nao_conforme', 'pendente')),
ADD COLUMN IF NOT EXISTS observacoes_ccl_adicional TEXT;

-- ===================================================
-- Índices para performance das consultas CCL
-- ===================================================

-- Índice para busca por status CCL
CREATE INDEX IF NOT EXISTS idx_produtos_ccl_status 
    ON produtos(tenant_id, ccl_status) 
    WHERE ccl_status IS NOT NULL;

-- Índice para processos pendentes de julgamento
CREATE INDEX IF NOT EXISTS idx_produtos_pendente_julgamento 
    ON produtos(tenant_id, status) 
    WHERE status = 'aprovado' AND ccl_status = 'pendente_julgamento';

-- Índice para recursos
CREATE INDEX IF NOT EXISTS idx_produtos_recurso 
    ON produtos(tenant_id, recurso_interposto, recurso_julgado) 
    WHERE recurso_interposto = TRUE;

-- Índice para homologações
CREATE INDEX IF NOT EXISTS idx_produtos_homologado 
    ON produtos(tenant_id, homologado, homologado_em);

-- ===================================================
-- Função para registrar julgamento CCL
-- ===================================================

CREATE OR REPLACE FUNCTION registrar_julgamento_ccl(
    produto_uuid UUID,
    usuario_uuid UUID,
    adequacao_tecnica_param TEXT,
    conformidade_documental_param TEXT,
    conformidade_normativa_param TEXT,
    justificativa_param TEXT,
    numero_ata_param TEXT
)
RETURNS VOID AS $$
DECLARE
    status_resultado TEXT;
BEGIN
    -- Determinar status baseado nos parâmetros
    IF adequacao_tecnica_param = 'inadequado' OR 
       conformidade_documental_param = 'nao_conforme' OR 
       conformidade_normativa_param = 'nao_conforme' THEN
        status_resultado := 'reprovado';
    ELSIF adequacao_tecnica_param = 'adequado_com_ressalvas' THEN
        status_resultado := 'aprovado_com_ressalvas';
    ELSE
        status_resultado := 'aprovado';
    END IF;

    -- Atualizar o produto com os dados do julgamento
    UPDATE produtos SET
        adequacao_tecnica = adequacao_tecnica_param,
        conformidade_documental = conformidade_documental_param,
        conformidade_normativa = conformidade_normativa_param,
        justificativa_julgamento = justificativa_param,
        ccl_julgado_por = usuario_uuid,
        ccl_data_julgamento = NOW(),
        ccl_numero_ata = numero_ata_param,
        ccl_status = status_resultado,
        updated_at = NOW()
    WHERE id = produto_uuid;

    -- Verificar se a atualização foi bem-sucedida
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado', produto_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- Função para registrar recurso
-- ===================================================

CREATE OR REPLACE FUNCTION registrar_recurso(
    produto_uuid UUID,
    motivo_param TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE produtos SET
        recurso_interposto = TRUE,
        recurso_data = NOW(),
        recurso_motivo = motivo_param,
        ccl_status = 'em_recurso',
        updated_at = NOW()
    WHERE id = produto_uuid;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado', produto_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- Função para julgar recurso
-- ===================================================

CREATE OR REPLACE FUNCTION julgar_recurso(
    produto_uuid UUID,
    resultado_param TEXT,
    usuario_uuid UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE produtos SET
        recurso_julgado = TRUE,
        recurso_resultado = resultado_param,
        ccl_julgado_por = usuario_uuid,
        ccl_data_julgamento = NOW(),
        ccl_status = CASE 
            WHEN resultado_param = 'procedente' THEN 'aprovado'
            WHEN resultado_param = 'parcialmente_procedente' THEN 'aprovado_com_ressalvas'
            ELSE 'reprovado'
        END,
        updated_at = NOW()
    WHERE id = produto_uuid;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado', produto_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- Função para homologar processo
-- ===================================================

CREATE OR REPLACE FUNCTION homologar_processo(
    produto_uuid UUID,
    usuario_uuid UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE produtos SET
        homologado = TRUE,
        homologado_por = usuario_uuid,
        homologado_em = NOW(),
        updated_at = NOW()
    WHERE id = produto_uuid
    AND ccl_status IN ('aprovado', 'aprovado_com_ressalvas');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado ou não está em status válido para homologação', produto_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===================================================
-- View para facilitar consultas CCL
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
    END as dias_recurso_pendente
FROM produtos p
LEFT JOIN usuarios u_julgador ON p.ccl_julgado_por = u_julgador.id
LEFT JOIN usuarios u_homologador ON p.homologado_por = u_homologador.id
LEFT JOIN categorias c ON p.categoria_id = c.id
WHERE p.status = 'aprovado'; -- Só produtos aprovados pela CPM chegam na CCL

-- ===================================================
-- Comentários nas colunas
-- ===================================================

COMMENT ON COLUMN produtos.adequacao_tecnica IS 
'Avaliação técnica do produto pela CCL (adequado/inadequado/adequado_com_ressalvas)';

COMMENT ON COLUMN produtos.conformidade_documental IS 
'Conformidade da documentação apresentada (conforme/nao_conforme/pendente)';

COMMENT ON COLUMN produtos.conformidade_normativa IS 
'Conformidade com normas técnicas aplicáveis (conforme/nao_conforme/pendente)';

COMMENT ON COLUMN produtos.justificativa_julgamento IS 
'Justificativa detalhada do julgamento pela CCL';

COMMENT ON COLUMN produtos.ccl_julgado_por IS 
'Usuário responsável pelo julgamento na CCL';

COMMENT ON COLUMN produtos.ccl_data_julgamento IS 
'Data e hora do julgamento pela CCL';

COMMENT ON COLUMN produtos.ccl_numero_ata IS 
'Número da ata de julgamento da CCL';

COMMENT ON COLUMN produtos.ccl_status IS 
'Status atual do produto no processo CCL';

COMMENT ON COLUMN produtos.recurso_interposto IS 
'Indica se foi interposto recurso contra a decisão';

COMMENT ON COLUMN produtos.recurso_data IS 
'Data de interposição do recurso';

COMMENT ON COLUMN produtos.recurso_motivo IS 
'Motivo alegado no recurso';

COMMENT ON COLUMN produtos.recurso_julgado IS 
'Indica se o recurso já foi julgado';

COMMENT ON COLUMN produtos.recurso_resultado IS 
'Resultado do julgamento do recurso';

COMMENT ON COLUMN produtos.homologado IS 
'Indica se o processo foi homologado pela autoridade competente';

COMMENT ON COLUMN produtos.homologado_por IS 
'Usuário que homologou o processo';

COMMENT ON COLUMN produtos.homologado_em IS 
'Data e hora da homologação';

COMMENT ON COLUMN produtos.observacoes_ccl IS 
'Observações gerais da CCL sobre o produto';

COMMENT ON COLUMN produtos.base_legal IS 
'Base legal utilizada no julgamento (Lei 14.133/2021, normas ABNT, etc.)';

COMMENT ON COLUMN produtos.requisitos_minimos IS 
'Avaliação do atendimento aos requisitos mínimos (atende/nao_atende/atende_parcialmente)';

COMMENT ON COLUMN produtos.conformidade_legal IS 
'Conformidade com dispositivos legais aplicáveis (conforme/nao_conforme/pendente)';

COMMENT ON COLUMN produtos.observacoes_ccl_adicional IS 
'Observações complementares da CCL';

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
    'observacoes_ccl_adicional'
)
ORDER BY ordinal_position;

-- Verificar se as funções foram criadas
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name IN (
    'registrar_julgamento_ccl', 
    'registrar_recurso', 
    'julgar_recurso', 
    'homologar_processo'
)
AND routine_schema = 'public';

-- ===================================================
-- Script finalizado
-- ===================================================