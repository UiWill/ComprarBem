-- INVESTIGAR SE O PROBLEMA É O ID OU EMAIL

-- 1. Ver se existe algum usuário com o ID que está sendo criado
SELECT 'VERIFICAR_ID_DUPLICADO' as tipo, id, email FROM usuarios 
WHERE id = '09e276c1-b632-4812-be2e-9d35f2c528c4' -- ID do log de erro
   OR id = 'f9b8d901-3092-44cc-a91a-09c3a328e6bb'; -- Outro ID do log

-- 2. Ver se existe constraint única no ID (além da PRIMARY KEY)
SELECT 
    'CONSTRAINTS_ID' as tipo,
    conname,
    pg_get_constraintdef(oid)
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass
  AND (pg_get_constraintdef(oid) ILIKE '%id%' OR contype = 'p');

-- 3. Ver constraint específica que está dando erro
SELECT 
    'CONSTRAINT_EMAIL' as tipo,
    conname,
    pg_get_constraintdef(oid)
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass
  AND conname = 'usuarios_email_key';

-- 4. Tentar inserir um registro de teste para ver onde falha
-- CUIDADO: Só execute se quiser testar
/*
INSERT INTO usuarios (
    id, 
    email, 
    nome, 
    tipo, 
    perfil_usuario, 
    tenant_id, 
    ativo
) VALUES (
    gen_random_uuid(),
    'teste.manual@fake.com',
    'Teste Manual',
    'admin',
    'cpm',
    (SELECT id FROM tenants LIMIT 1),
    true
) RETURNING id, email;
*/