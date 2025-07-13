-- ============================================
-- REMOVER TODAS AS FK CONSTRAINTS - usuarios_rdm
-- Sistema Comprar Bem - Solução Definitiva
-- ============================================

-- 1. LISTAR TODAS AS FK CONSTRAINTS ATUAIS
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

-- 2. REMOVER TODAS AS FK CONSTRAINTS
DO $$ 
DECLARE
    constraint_record RECORD;
BEGIN
    -- Remover TODAS as constraints FK da tabela usuarios_rdm
    FOR constraint_record IN 
        SELECT constraint_name 
        FROM information_schema.table_constraints 
        WHERE table_name = 'usuarios_rdm' 
        AND constraint_type = 'FOREIGN KEY'
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE usuarios_rdm DROP CONSTRAINT ' || constraint_record.constraint_name;
            RAISE NOTICE 'FK Constraint % removida com sucesso', constraint_record.constraint_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erro ao remover constraint %: %', constraint_record.constraint_name, SQLERRM;
        END;
    END LOOP;
    
    -- Verificar se ainda restam constraints FK
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'usuarios_rdm' 
        AND constraint_type = 'FOREIGN KEY'
    ) THEN
        RAISE NOTICE 'ATENÇÃO: Ainda existem FK constraints na tabela usuarios_rdm';
    ELSE
        RAISE NOTICE 'SUCESSO: Todas as FK constraints foram removidas da tabela usuarios_rdm';
    END IF;
END
$$;

-- 3. VERIFICAÇÃO - DEVE RETORNAR VAZIO
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'usuarios_rdm'
AND constraint_type = 'FOREIGN KEY';

-- 4. TESTE DE INSERÇÃO PARA VALIDAR
INSERT INTO usuarios_rdm (
    tenant_id,
    nome_usuario,
    unidade_setor,
    nome_coordenador,
    telefone,
    email,
    materiais,
    user_id
) VALUES (
    'dcfe1030-27dd-4964-8e22-08a9c3fab790',
    'TESTE FK REMOVIDA',
    'Setor Teste',
    'Coordenador Teste',
    '(11) 99999-9999',
    'teste.fk@removida.com',
    '[{"nome": "Material Teste", "codigo": "TEST001", "periodicidade_rdm": "Mensal"}]'::jsonb,
    '79a096d8-3b32-4583-b024-d5b59f2570a4'
);

-- 5. REMOVER O TESTE (LIMPAR)
DELETE FROM usuarios_rdm WHERE email = 'teste.fk@removida.com';

-- 6. VERIFICAÇÃO FINAL
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'usuarios_rdm'
AND column_name IN ('tenant_id', 'user_id')
ORDER BY column_name;

-- ============================================
-- CONSTRAINTS RESTANTES (APENAS PK E CHECK)
-- ============================================

SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'usuarios_rdm'
ORDER BY constraint_type, constraint_name;

COMMENT ON TABLE usuarios_rdm IS 'Tabela usuarios_rdm SEM FK constraints - Sistema Comprar Bem'; 