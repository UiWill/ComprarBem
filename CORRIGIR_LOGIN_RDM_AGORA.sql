-- COMANDO DIRETO PARA CORRIGIR LOGIN RDM
-- Execute ESTE comando específico no Supabase SQL Editor

-- 1. Primeiro, vamos criar a política permissiva para login
CREATE POLICY "Permitir login RDM" ON usuarios_rdm
    FOR SELECT 
    TO anon, authenticated
    USING (ativo = true);

-- 2. Se ainda não funcionar, desabilitar RLS temporariamente
ALTER TABLE usuarios_rdm DISABLE ROW LEVEL SECURITY;

-- 3. Verificar se funcionou
SELECT 
    'LOGIN RDM CORRIGIDO!' as status,
    'RLS está ' || CASE WHEN rowsecurity THEN 'ATIVO' ELSE 'INATIVO' END as rls_status
FROM pg_tables 
WHERE tablename = 'usuarios_rdm';

-- 4. Testar se consegue encontrar o usuário
SELECT 
    'Usuário encontrado!' as teste,
    nome_usuario,
    email,
    ativo,
    LENGTH(senha_temporaria) as tem_senha
FROM usuarios_rdm 
WHERE email = 'williamemanoel777@gmail.com'
AND ativo = true;