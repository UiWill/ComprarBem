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
WHERE processo_id = (SELECT id FROM processos_administrativos WHERE numero_processo = '003' LIMIT 1);