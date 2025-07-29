-- Debug para homologações

-- 1. Verificar se existem homologações na tabela
SELECT 'HOMOLOGAÇÕES EXISTENTES' as info, COUNT(*) as total FROM homologacoes;

-- 2. Mostrar homologações se existirem
SELECT 
    'HOMOLOGAÇÕES CADASTRADAS' as info,
    ata_julgamento_id,
    numero_ata,
    tipo_homologacao,
    data_homologacao
FROM homologacoes 
ORDER BY data_homologacao DESC;

-- 3. Query exata que a aplicação está usando (simulação)
SELECT 
    'QUERY DA APLICAÇÃO (simulação)' as info,
    id,
    numero,
    data_publicacao,
    total_processos,
    status_ata
FROM atas_julgamento
WHERE tenant_id = 'dcfe1030-27dd-4964-8e22-08a9c3fab790'  -- Usar seu tenant_id
  AND status_ata IN ('EM PRAZO', 'PUBLICADA', 'PUBLICADA_EM_PRAZO', 'PUBLICADA_ENCERRADA')
  AND id NOT IN (SELECT COALESCE(ata_julgamento_id, '00000000-0000-0000-0000-000000000000'::uuid) FROM homologacoes)
ORDER BY data_publicacao ASC;