-- Script para verificar e corrigir status das atas

-- 1. Verificar status atuais das atas
SELECT 
    'STATUS ATUAIS DAS ATAS' as info,
    status_ata,
    COUNT(*) as quantidade
FROM atas_julgamento 
GROUP BY status_ata
ORDER BY quantidade DESC;

-- 2. Mostrar atas com detalhes
SELECT 
    'DETALHES DAS ATAS' as info,
    numero,
    status_ata,
    data_publicacao,
    data_inicio_elaboracao,
    progresso_elaboracao
FROM atas_julgamento 
ORDER BY 
    CASE status_ata 
        WHEN 'ELABORACAO' THEN 1
        WHEN 'EM PRAZO' THEN 2  
        WHEN 'PUBLICADA' THEN 3
        ELSE 4
    END,
    criado_em DESC;

-- 3. Verificar se há atas "finalizadas" mas ainda como ELABORACAO
SELECT 
    'ATAS COM PROBLEMA DE STATUS' as info,
    numero,
    status_ata,
    progresso_elaboracao,
    data_publicacao
FROM atas_julgamento 
WHERE (progresso_elaboracao = 100 AND status_ata = 'ELABORACAO')
   OR (data_publicacao IS NOT NULL AND status_ata = 'ELABORACAO');

-- 4. Corrigir atas que foram "finalizadas" mas ficaram como ELABORACAO
UPDATE atas_julgamento 
SET 
    status_ata = 'EM PRAZO',
    data_publicacao = COALESCE(data_publicacao, NOW()),
    data_inicio_prazo_recursal = COALESCE(data_inicio_prazo_recursal, NOW()),
    data_fim_prazo_recursal = COALESCE(data_fim_prazo_recursal, NOW() + INTERVAL '3 days'),
    atualizado_em = NOW()
WHERE (progresso_elaboracao = 100 AND status_ata = 'ELABORACAO')
   OR (data_publicacao IS NOT NULL AND status_ata = 'ELABORACAO');

-- 5. Verificar resultado da correção
SELECT 
    'APÓS CORREÇÃO' as info,
    status_ata,
    COUNT(*) as quantidade
FROM atas_julgamento 
GROUP BY status_ata
ORDER BY quantidade DESC;

-- 6. Mostrar atas que devem aparecer em homologações
SELECT 
    'ATAS PARA HOMOLOGAÇÃO' as info,
    numero,
    status_ata,
    data_publicacao,
    total_processos
FROM atas_julgamento 
WHERE status_ata IN ('EM PRAZO', 'PUBLICADA', 'PUBLICADA_EM_PRAZO', 'PUBLICADA_ENCERRADA')
  AND id NOT IN (SELECT COALESCE(ata_julgamento_id, '00000000-0000-0000-0000-000000000000'::uuid) FROM homologacoes)
ORDER BY data_publicacao ASC;