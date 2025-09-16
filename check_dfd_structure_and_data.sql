-- Verificar estrutura da tabela dfd_processo
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_name = 'dfd_processo'
ORDER BY ordinal_position;

-- Verificar todos os DFDs do processo 003
SELECT
    id,
    processo_id,
    justificativa,
    necessidade_descricao,
    criterios_aceitacao,
    observacoes_especiais,
    modelo_usado,
    created_at,
    updated_at
FROM dfd_processo
WHERE processo_id = (SELECT id FROM processos_administrativos WHERE numero_processo = '003' LIMIT 1)
ORDER BY created_at;

-- Verificar se existem outros campos que podem conter os dados
SELECT * FROM dfd_processo
WHERE processo_id = (SELECT id FROM processos_administrativos WHERE numero_processo = '003' LIMIT 1)
LIMIT 3;