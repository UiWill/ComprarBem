-- Script para configurar Row Level Security na tabela recursos
-- Execute este script APÓS criar_tabela_recursos.sql

-- Verificar se a tabela recursos existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recursos') THEN
        RAISE NOTICE 'Tabela recursos encontrada. Configurando RLS...';
        
        -- Habilitar RLS na tabela recursos
        ALTER TABLE recursos ENABLE ROW LEVEL SECURITY;
        
        -- Remover política existente se houver
        DROP POLICY IF EXISTS "recursos_tenant_policy" ON recursos;
        DROP POLICY IF EXISTS "recursos_select_policy" ON recursos;
        DROP POLICY IF EXISTS "recursos_insert_policy" ON recursos;
        DROP POLICY IF EXISTS "recursos_update_policy" ON recursos;
        DROP POLICY IF EXISTS "recursos_delete_policy" ON recursos;
        
        -- Criar política para SELECT (leitura)
        CREATE POLICY "recursos_select_policy" ON recursos
            FOR SELECT USING (true); -- Permitir leitura para todos (ajustar conforme necessário)
        
        -- Criar política para INSERT (criação)
        CREATE POLICY "recursos_insert_policy" ON recursos
            FOR INSERT WITH CHECK (true); -- Permitir inserção para todos (ajustar conforme necessário)
        
        -- Criar política para UPDATE (atualização)
        CREATE POLICY "recursos_update_policy" ON recursos
            FOR UPDATE USING (true); -- Permitir atualização para todos (ajustar conforme necessário)
        
        -- Criar política para DELETE (exclusão)
        CREATE POLICY "recursos_delete_policy" ON recursos
            FOR DELETE USING (true); -- Permitir exclusão para todos (ajustar conforme necessário)
        
        RAISE NOTICE 'RLS configurado com sucesso na tabela recursos.';
        
    ELSE
        RAISE NOTICE 'Tabela recursos não encontrada. Execute primeiro o script criar_tabela_recursos.sql';
    END IF;
END $$;

-- Verificar se as políticas foram criadas
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
WHERE tablename = 'recursos';

-- Grant de permissões básicas (ajustar conforme o setup do Supabase)
GRANT ALL ON recursos TO authenticated;
GRANT ALL ON recursos TO anon;
GRANT ALL ON recursos TO service_role;

-- Verificar se a tabela está acessível
SELECT 'Tabela recursos está acessível!' as status, count(*) as total_registros FROM recursos;