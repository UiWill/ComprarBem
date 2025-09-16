-- Verificar estrutura da tabela processos_administrativos
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'processos_administrativos'
ORDER BY ordinal_position;

-- Verificar dados do processo 003
SELECT
    id,
    numero_processo,
    objeto,
    objeto_customizado,
    tipo_processo,
    status
FROM processos_administrativos
WHERE numero_processo = '003' OR id = 3;

-- Verificar DFDs do processo 003
SELECT
    id,
    processo_id,
    justificativa,
    necessidade_descricao,
    modelo_usado,
    created_at
FROM dfd_processo
WHERE processo_id = 3;