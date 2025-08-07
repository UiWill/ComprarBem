-- Script para resolver o problema de login RDM
-- O erro 406 está acontecendo porque as políticas RLS estão bloqueando o acesso

-- 1. Verificar se RLS está ativo na tabela usuarios_rdm
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    'RLS está ' || CASE WHEN rowsecurity THEN 'ATIVO' ELSE 'INATIVO' END as status
FROM pg_tables 
WHERE tablename = 'usuarios_rdm';

-- 2. Verificar políticas RLS existentes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'usuarios_rdm';

-- 3. Opção A: Desabilitar RLS temporariamente (CUIDADO: Remove toda proteção)
-- ALTER TABLE usuarios_rdm DISABLE ROW LEVEL SECURITY;

-- 4. Opção B: Criar política permissiva para login (RECOMENDADO)
-- Permite acesso de leitura para usuários anônimos apenas para login
CREATE POLICY "Permitir login RDM" ON usuarios_rdm
    FOR SELECT 
    TO anon, authenticated
    USING (ativo = true);

-- 5. Verificar se a política foi criada
SELECT 
    'Política de login RDM criada com sucesso!' as status,
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE tablename = 'usuarios_rdm' 
AND policyname = 'Permitir login RDM';

-- 6. ALTERNATIVA: Se as políticas estão muito restritivas, 
-- criar uma política mais permissiva temporariamente
-- DROP POLICY IF EXISTS "Permitir login RDM" ON usuarios_rdm;
-- CREATE POLICY "Acesso RDM temporário" ON usuarios_rdm
--     FOR ALL 
--     TO anon, authenticated
--     USING (true);

-- 7. Para debug: Ver todos os usuários RDM
-- SELECT 
--     id,
--     nome_usuario,
--     email,
--     ativo,
--     convite_enviado,
--     convite_aceito,
--     tenant_id
-- FROM usuarios_rdm 
-- WHERE ativo = true
-- ORDER BY criado_em DESC;