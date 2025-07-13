-- ============================================
-- SQL PARA VERIFICAR SENHAS RDM
-- Sistema Comprar Bem - Verificação de Credenciais
-- ============================================

-- 1. VERIFICAR TODOS OS USUARIOS RDM E SUAS SENHAS
SELECT 
    nome_usuario,
    email,
    unidade_setor,
    senha_temporaria,
    convite_aceito,
    convite_enviado,
    ativo,
    data_convite,
    user_id,
    criado_em,
    atualizado_em
FROM usuarios_rdm 
ORDER BY criado_em DESC;

-- 2. VERIFICAR ESPECIFICAMENTE O USUÁRIO William (devwilliamemanoel7@gmail.com)
SELECT 
    nome_usuario,
    email,
    senha_temporaria,
    convite_aceito,
    convite_enviado,
    ativo,
    data_convite
FROM usuarios_rdm 
WHERE email = 'devwilliamemanoel7@gmail.com';

-- 3. GERAR NOVA SENHA TEMPORÁRIA PARA WILLIAM (se necessário)
-- DESCOMENTE ESTA LINHA APENAS SE QUISER RESETAR A SENHA:
-- UPDATE usuarios_rdm 
-- SET senha_temporaria = 'CB2024' || LPAD(FLOOR(RANDOM() * 1000)::text, 3, '0'),
--     convite_aceito = false,
--     data_convite = NOW()
-- WHERE email = 'devwilliamemanoel7@gmail.com';

-- 4. FUNÇÃO PARA GERAR SENHA TEMPORÁRIA ALEATÓRIA
CREATE OR REPLACE FUNCTION gerar_nova_senha_temporaria()
RETURNS TEXT AS $$
BEGIN
    RETURN 'CB' || TO_CHAR(CURRENT_DATE, 'YYYY') || LPAD(FLOOR(RANDOM() * 10000)::text, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- 5. EXEMPLO DE USO DA FUNÇÃO
SELECT gerar_nova_senha_temporaria() as nova_senha_exemplo;

-- ============================================
-- INSTRUÇÕES:
-- ============================================
-- 1. Execute a query 1 ou 2 para ver os usuários e senhas
-- 2. Se quiser resetar a senha do William, descomente a query 3
-- 3. A senha temporária gerada será algo como: CB20241234
-- 4. O usuário deve usar esta senha no primeiro login
-- 5. Após primeiro login, ele pode definir uma senha definitiva
-- ============================================ 