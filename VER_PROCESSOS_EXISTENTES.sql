-- 3. Verificar alguns processos existentes
SELECT 
    id,
    status,
    tenant_id,
    criado_em
FROM processos_administrativos 
WHERE tenant_id = '8329e25e-8a01-4fc6-ab15-7a83dd874bde'
LIMIT 5;