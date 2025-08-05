-- Verificar se o usuário foi realmente cadastrado na tabela usuarios_rdm

-- 1. Verificar se existe o usuário williamemanoel777@gmail.com
SELECT 
    'VERIFICAÇÃO DO USUÁRIO RDM' as titulo,
    id,
    nome_usuario,
    email,
    ativo,
    senha_temporaria,
    tenant_id,
    criado_em,
    convite_enviado,
    convite_aceito
FROM usuarios_rdm 
WHERE email = 'williamemanoel777@gmail.com';

-- 2. Se não encontrar, ver todos os usuários RDM
SELECT 
    'TODOS OS USUÁRIOS RDM' as titulo,
    id,
    nome_usuario,
    email,
    ativo,
    senha_temporaria,
    tenant_id,
    criado_em
FROM usuarios_rdm 
ORDER BY criado_em DESC;

-- 3. Verificar se RLS foi realmente desabilitado
SELECT 
    'STATUS RLS' as titulo,
    schemaname,
    tablename,
    rowsecurity,
    'RLS está ' || CASE WHEN rowsecurity THEN 'ATIVO' ELSE 'INATIVO' END as status
FROM pg_tables 
WHERE tablename = 'usuarios_rdm';

-- 4. Contar total de usuários RDM
SELECT 
    'TOTAL DE USUÁRIOS' as titulo,
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN ativo THEN 1 END) as usuarios_ativos,
    COUNT(CASE WHEN convite_enviado THEN 1 END) as convites_enviados
FROM usuarios_rdm;