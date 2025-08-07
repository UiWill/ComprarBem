-- CONFIRMAR EMAILS AUTOMATICAMENTE 
-- Execute para confirmar todos os emails pendentes

-- 1. Ver usuários não confirmados no Auth
SELECT 
    'USUARIOS_NAO_CONFIRMADOS' as tipo,
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- 2. CONFIRMAR AUTOMATICAMENTE TODOS OS EMAILS PENDENTES
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 3. Verificar resultado
SELECT 
    'CONFIRMACAO_RESULTADO' as tipo,
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmados,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as pendentes
FROM auth.users;

-- 4. Ver usuários confirmados
SELECT 
    'USUARIOS_CONFIRMADOS' as tipo,
    email,
    email_confirmed_at
FROM auth.users 
WHERE email_confirmed_at IS NOT NULL
ORDER BY email_confirmed_at DESC;