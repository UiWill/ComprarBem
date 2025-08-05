-- Script para verificar todos os status dos produtos no banco de dados
-- Execute este comando diretamente no Supabase SQL Editor ou em outro cliente PostgreSQL

SELECT 
    status, 
    COUNT(*) as quantidade,
    STRING_AGG(DISTINCT nome, ', ') as exemplos_produtos
FROM produtos 
GROUP BY status
ORDER BY quantidade DESC;

-- Também verificar produtos julgados especificamente
SELECT 
    id,
    nome,
    marca,
    status,
    julgado_em,
    adequacao_tecnica,
    observacoes_ccl
FROM produtos 
WHERE julgado_em IS NOT NULL 
   OR status LIKE '%julgado%'
ORDER BY julgado_em DESC
LIMIT 10;