-- ALTERNATIVA: USAR EMAILS COMPLETAMENTE NOVOS
-- Se não quiser deletar dados existentes

-- 1. Ver emails atualmente em uso
SELECT 'EMAILS_OCUPADOS' as status, email FROM usuarios ORDER BY email;

-- 2. Sugestões de emails novos para teste
SELECT 'EMAILS_SUGERIDOS' as status, email_sugerido FROM (
    VALUES 
    ('diretor.cpm@prefeitura-teste.gov.br'),
    ('presidente.ccl@prefeitura-teste.gov.br'),
    ('autoridade.admin@prefeitura-teste.gov.br'),
    ('assessor.juridico@prefeitura-teste.gov.br')
) AS sugestoes(email_sugerido);

-- 3. Verificar se estes emails estão livres
SELECT 
    'DISPONIBILIDADE' as status,
    email_teste,
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE email = email_teste) 
        THEN '❌ OCUPADO'
        ELSE '✅ LIVRE'
    END as disponivel
FROM (
    VALUES 
    ('diretor.cpm@prefeitura-teste.gov.br'),
    ('presidente.ccl@prefeitura-teste.gov.br'),
    ('autoridade.admin@prefeitura-teste.gov.br'),
    ('assessor.juridico@prefeitura-teste.gov.br'),
    ('novo.cpm@orgao.teste.br'),
    ('novo.ccl@orgao.teste.br'),
    ('novo.admin@orgao.teste.br'),
    ('novo.juridico@orgao.teste.br')
) AS testes(email_teste);