-- Verificar a ata que foi criada
SELECT 
    id,
    numero,
    status_ata,
    data_publicacao,
    data_inicio_elaboracao,
    progresso_elaboracao,
    tenant_id
FROM atas_julgamento 
WHERE tenant_id = '8329e25e-8a01-4fc6-ab15-7a83dd874bde'
ORDER BY criado_em DESC
LIMIT 3;