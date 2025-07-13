-- ============================================
-- CORRIGIR TABELA lembretes_feedback
-- Adicionar coluna erro_envio que está faltando
-- ============================================

-- 1. VERIFICAR ESTRUTURA ATUAL
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'lembretes_feedback' 
ORDER BY ordinal_position;

-- 2. ADICIONAR COLUNA erro_envio se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lembretes_feedback' 
        AND column_name = 'erro_envio'
    ) THEN
        ALTER TABLE lembretes_feedback 
        ADD COLUMN erro_envio TEXT NULL;
        
        COMMENT ON COLUMN lembretes_feedback.erro_envio IS 'Mensagem de erro caso o envio falhe';
        
        RAISE NOTICE '✅ Coluna erro_envio adicionada com sucesso!';
    ELSE
        RAISE NOTICE '⚠️  Coluna erro_envio já existe';
    END IF;
END $$;

-- 3. VERIFICAR ESTRUTURA FINAL
SELECT 'ESTRUTURA FINAL DA TABELA lembretes_feedback:' as status;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'lembretes_feedback' 
ORDER BY ordinal_position;

-- 4. TESTAR A FUNÇÃO novamente
SELECT 'TESTE: Registrar lembrete com erro' as teste;
SELECT registrar_lembrete_enviado(
    'd1289bf3-12b0-4fca-9245-990af88bb165'::uuid,
    'dcfe1030-27dd-4964-8e22-08a9c3fab790'::uuid,
    '44341608-9422-41cf-8f82-a308c7ffbdb8'::uuid,
    '15_DIAS',
    false,
    'Erro de teste para verificar se funciona'
);

-- 5. VERIFICAR SE FOI INSERIDO
SELECT 'RESULTADO DO TESTE:' as resultado;
SELECT * FROM lembretes_feedback 
WHERE rdm_id = 'd1289bf3-12b0-4fca-9245-990af88bb165'::uuid
ORDER BY criado_em DESC LIMIT 3; 