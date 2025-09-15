-- SQL para verificar o DFD específico que aparece nos logs
-- Execute este comando no Supabase SQL Editor ou cliente SQL

-- 1. Buscar o DFD específico com todos os campos
SELECT
    id,
    processo_id,
    tenant_id,
    -- Campos principais
    justificativa,
    necessidade_descricao,
    criterios_aceitacao,
    observacoes_especiais,

    -- Dados do demandante
    nome_presidente,
    matricula_presidente,
    email_presidente,
    telefone_presidente,

    -- Campos do modelo 1 (padronização)
    produtos_especificacao,
    quantidade_amostras,
    previsao_aquisicoes,
    especificacoes_tecnicas,
    ensaios_exigidos,
    local_entrega_amostras,
    prazo_entrega_amostras,

    -- Campos do modelo 2 (despadronização)
    produtos_despadronizar,
    fonte_rdm,
    fonte_reclamacoes_usuarios,
    fonte_sistema_comprar_bem,
    fonte_analise_tecnica,
    fonte_outros,
    outras_fontes,
    problemas_identificados,

    -- Metadados
    modelo_usado,
    conteudo_html,
    created_at,
    updated_at
FROM dfd_processo
WHERE id = 'f3b0006a-41f6-4552-abf5-3b16f41164f4';

-- 2. Verificar tamanhos dos campos principais
SELECT
    id,
    LENGTH(justificativa) as justificativa_chars,
    LENGTH(necessidade_descricao) as necessidade_descricao_chars,
    LENGTH(criterios_aceitacao) as criterios_aceitacao_chars,
    LENGTH(observacoes_especiais) as observacoes_especiais_chars,
    LENGTH(conteudo_html) as conteudo_html_chars,
    modelo_usado
FROM dfd_processo
WHERE id = 'f3b0006a-41f6-4552-abf5-3b16f41164f4';

-- 3. Ver preview dos campos de texto
SELECT
    id,
    SUBSTRING(justificativa, 1, 100) as justificativa_preview,
    SUBSTRING(necessidade_descricao, 1, 100) as necessidade_descricao_preview,
    SUBSTRING(criterios_aceitacao, 1, 100) as criterios_aceitacao_preview,
    SUBSTRING(observacoes_especiais, 1, 100) as observacoes_especiais_preview,
    SUBSTRING(conteudo_html, 1, 200) as conteudo_html_preview
FROM dfd_processo
WHERE id = 'f3b0006a-41f6-4552-abf5-3b16f41164f4';

-- 4. Verificar se há campos com NULL ou vazios
SELECT
    id,
    CASE
        WHEN justificativa IS NULL THEN 'NULL'
        WHEN justificativa = '' THEN 'VAZIO'
        WHEN LENGTH(TRIM(justificativa)) = 0 THEN 'APENAS_ESPACOS'
        ELSE 'PREENCHIDO'
    END as status_justificativa,

    CASE
        WHEN necessidade_descricao IS NULL THEN 'NULL'
        WHEN necessidade_descricao = '' THEN 'VAZIO'
        WHEN LENGTH(TRIM(necessidade_descricao)) = 0 THEN 'APENAS_ESPACOS'
        ELSE 'PREENCHIDO'
    END as status_necessidade_descricao,

    CASE
        WHEN conteudo_html IS NULL THEN 'NULL'
        WHEN conteudo_html = '' THEN 'VAZIO'
        WHEN LENGTH(TRIM(conteudo_html)) = 0 THEN 'APENAS_ESPACOS'
        ELSE 'PREENCHIDO'
    END as status_conteudo_html
FROM dfd_processo
WHERE id = 'f3b0006a-41f6-4552-abf5-3b16f41164f4';

-- 5. Buscar todos os DFDs do processo para comparação
SELECT
    id,
    LENGTH(justificativa) as justificativa_chars,
    LENGTH(necessidade_descricao) as necessidade_descricao_chars,
    LENGTH(conteudo_html) as conteudo_html_chars,
    modelo_usado,
    created_at
FROM dfd_processo
WHERE processo_id = 'c5bdccaf-c9fe-4d6c-8b96-f801c6561a40'
ORDER BY created_at DESC;