-- ============================================
-- SQL PARA SIMPLIFICAR SISTEMA DE SENHAS RDM
-- Sistema Comprar Bem - Senhas Definitivas
-- ============================================

-- 1. RENOMEAR COLUNA SENHA_TEMPORARIA PARA SENHA (mais intuitivo)
-- ATENÇÃO: Este comando pode dar erro se já existir coluna 'senha'
-- Comente se necessário
DO $$ 
BEGIN
    -- Verificar se coluna 'senha' já existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'usuarios_rdm' AND column_name = 'senha'
    ) THEN
        -- Adicionar coluna senha
        ALTER TABLE usuarios_rdm ADD COLUMN senha TEXT;
        
        -- Copiar dados de senha_temporaria para senha
        UPDATE usuarios_rdm 
        SET senha = senha_temporaria 
        WHERE senha_temporaria IS NOT NULL;
        
        -- Remover coluna antiga (OPCIONAL - descomente se quiser)
        -- ALTER TABLE usuarios_rdm DROP COLUMN senha_temporaria;
        
        RAISE NOTICE 'Coluna senha criada e dados migrados com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna senha já existe. Pulando migração.';
    END IF;
END
$$;

-- 2. GARANTIR QUE TODOS OS USUÁRIOS TENHAM SENHAS VÁLIDAS
UPDATE usuarios_rdm 
SET senha = COALESCE(senha, senha_temporaria, 'CB631515!')
WHERE senha IS NULL OR senha = '';

-- 3. MARCAR TODOS COMO CONVITE ACEITO (simplificar sistema)
UPDATE usuarios_rdm 
SET convite_aceito = true,
    ativo = true
WHERE ativo = true;

-- 4. DEFINIR SENHA PADRÃO PARA NOVOS USUÁRIOS
-- Função para gerar senha simples e definitiva
CREATE OR REPLACE FUNCTION gerar_senha_definitiva()
RETURNS TEXT AS $$
BEGIN
    RETURN 'CB' || TO_CHAR(CURRENT_DATE, 'YYYY') || LPAD(FLOOR(RANDOM() * 10000)::text, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- 5. VERIFICAR USUÁRIOS E SUAS SENHAS FINAIS
SELECT 
    nome_usuario,
    email,
    unidade_setor,
    COALESCE(senha, senha_temporaria) as senha_ativa,
    convite_aceito,
    ativo,
    criado_em
FROM usuarios_rdm 
ORDER BY criado_em DESC;

-- 6. ATUALIZAR ESPECIFICAMENTE O WILLIAM PARA SENHA FIXA
UPDATE usuarios_rdm 
SET senha = 'CB631515!',
    senha_temporaria = 'CB631515!', -- manter ambas por segurança
    convite_aceito = true,
    ativo = true
WHERE email = 'devwilliamemanoel7@gmail.com';

-- 7. VERIFICAR WILLIAM APÓS ATUALIZAÇÃO
SELECT 
    nome_usuario,
    email,
    senha,
    senha_temporaria,
    convite_aceito,
    ativo
FROM usuarios_rdm 
WHERE email = 'devwilliamemanoel7@gmail.com';

-- ============================================
-- COMENTÁRIOS DO SISTEMA SIMPLIFICADO:
-- ============================================
-- ✅ Agora o sistema funciona assim:
-- 1. CPM cadastra usuário com senha fixa
-- 2. Usuário sempre usa a mesma senha
-- 3. Não há mais "primeira vez" vs "segunda vez"
-- 4. Senha é definitiva desde o início
-- 5. Mais simples para o usuário e administrador
-- ============================================

COMMENT ON COLUMN usuarios_rdm.senha IS 'Senha definitiva do usuário - não temporária';
COMMENT ON COLUMN usuarios_rdm.senha_temporaria IS 'DEPRECATED: Use coluna senha';

-- Exemplo de como criar novo usuário com senha definitiva:
/*
INSERT INTO usuarios_rdm (
    tenant_id,
    nome_usuario,
    unidade_setor,
    nome_coordenador,
    telefone,
    email,
    senha,
    convite_aceito,
    ativo,
    materiais
) VALUES (
    'SEU_TENANT_ID',
    'Nome do Setor',
    'Secretaria XYZ',
    'Nome do Coordenador',
    '(61) 3315-2425',
    'email@governo.br',
    'CB20250001', -- Senha definitiva
    true,         -- Já aceito
    true,         -- Ativo
    '[]'::jsonb   -- Materiais vazios
);
*/ 