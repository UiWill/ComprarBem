-- TESTAR SE NOVOS EMAILS ESTÃO LIVRES PARA REGISTRO

-- Substitua pelos emails que você vai usar no novo registro
-- Por exemplo, se vai testar um novo órgão:

SELECT 
    'TESTE_DISPONIBILIDADE' as tipo,
    'novocpm@orgao.gov.br' as email_teste,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'novocpm@orgao.gov.br') 
        THEN '❌ JÁ EXISTE'
        ELSE '✅ DISPONÍVEL'
    END as status
UNION ALL
SELECT 
    'TESTE_DISPONIBILIDADE' as tipo,
    'novoccl@orgao.gov.br' as email_teste,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'novoccl@orgao.gov.br') 
        THEN '❌ JÁ EXISTE'
        ELSE '✅ DISPONÍVEL'
    END as status
UNION ALL
SELECT 
    'TESTE_DISPONIBILIDADE' as tipo,
    'novoadmin@orgao.gov.br' as email_teste,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'novoadmin@orgao.gov.br') 
        THEN '❌ JÁ EXISTE'
        ELSE '✅ DISPONÍVEL'
    END as status
UNION ALL
SELECT 
    'TESTE_DISPONIBILIDADE' as tipo,
    'novojuridico@orgao.gov.br' as email_teste,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = 'novojuridico@orgao.gov.br') 
        THEN '❌ JÁ EXISTE'
        ELSE '✅ DISPONÍVEL'
    END as status;

-- Ver emails existentes para evitar conflito
SELECT 
    'EMAILS_EXISTENTES' as tipo,
    email
FROM usuarios 
ORDER BY email;