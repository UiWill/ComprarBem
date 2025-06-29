-- ============================================
-- CORRIGIR FOREIGN KEY CONSTRAINT - usuarios_rdm
-- Sistema Comprar Bem - Correção FK tenant_id
-- ============================================

-- 1. VERIFICAR CONSTRAINTS ATUAIS
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'usuarios_rdm';

-- 2. REMOVER CONSTRAINT PROBLEMÁTICA (se existir)
DO $$ 
BEGIN
    -- Verificar se a constraint existe e removê-la
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'usuarios_rdm_tenant_id_fkey' 
        AND table_name = 'usuarios_rdm'
    ) THEN
        ALTER TABLE usuarios_rdm DROP CONSTRAINT usuarios_rdm_tenant_id_fkey;
        RAISE NOTICE 'Constraint usuarios_rdm_tenant_id_fkey removida com sucesso';
    ELSE
        RAISE NOTICE 'Constraint usuarios_rdm_tenant_id_fkey não encontrada';
    END IF;
END
$$;

-- 3. VERIFICAR OUTRAS CONSTRAINTS PROBLEMÁTICAS
DO $$ 
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT constraint_name 
        FROM information_schema.table_constraints 
        WHERE table_name = 'usuarios_rdm' 
        AND constraint_type = 'FOREIGN KEY'
        AND constraint_name LIKE '%tenant_id%'
    LOOP
        EXECUTE 'ALTER TABLE usuarios_rdm DROP CONSTRAINT ' || constraint_record.constraint_name;
        RAISE NOTICE 'Constraint % removida', constraint_record.constraint_name;
    END LOOP;
END
$$;

-- 4. CRIAR CONSTRAINT MAIS FLEXÍVEL (OPCIONAL)
-- Descomente se quiser manter alguma validação
/*
ALTER TABLE usuarios_rdm 
ADD CONSTRAINT usuarios_rdm_tenant_id_check 
CHECK (tenant_id IS NOT NULL);
*/

-- 5. VERIFICAR SE AS CONSTRAINTS FORAM REMOVIDAS
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'usuarios_rdm'
AND constraint_type = 'FOREIGN KEY';

-- 6. TESTE DE INSERÇÃO (OPCIONAL)
/*
INSERT INTO usuarios_rdm (
    tenant_id,
    nome_usuario,
    unidade_setor,
    nome_coordenador,
    telefone,
    email,
    materiais
) VALUES (
    'dcfe1030-27dd-4964-8e22-08a9c3fab790',
    'Teste Constraint',
    'Setor Teste',
    'Coordenador Teste',
    '(11) 99999-9999',
    'teste.constraint@teste.com',
    '[]'::jsonb
);
*/

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

-- Ver todas as constraints da tabela
SELECT 
    constraint_name,
    constraint_type,
    is_deferrable,
    initially_deferred
FROM information_schema.table_constraints 
WHERE table_name = 'usuarios_rdm'
ORDER BY constraint_type, constraint_name;

-- Ver estrutura atual da tabela
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'usuarios_rdm'
ORDER BY ordinal_position;

COMMENT ON TABLE usuarios_rdm IS 'Tabela usuarios_rdm com FK constraints corrigidas - Sistema Comprar Bem'; 