-- ============================================
-- DESABILITAR RLS TEMPORARIAMENTE - usuarios_rdm
-- Sistema Comprar Bem - Correção Emergencial
-- ============================================

-- OPÇÃO 1: REMOVER TODAS AS POLÍTICAS E CRIAR UMA PERMISSIVA
DROP POLICY IF EXISTS "usuarios_rdm_select_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_insert_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_update_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_delete_policy" ON usuarios_rdm;

-- Criar política temporária SUPER PERMISSIVA
CREATE POLICY "usuarios_rdm_temp_all_access" ON usuarios_rdm
    FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- OPÇÃO 2: DESABILITAR RLS COMPLETAMENTE (SE OPÇÃO 1 NÃO FUNCIONAR)
-- ============================================

-- Descomente a linha abaixo se ainda der erro:
-- ALTER TABLE usuarios_rdm DISABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFICAÇÃO
-- ============================================

-- Verificar se RLS está ativo
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    forcerowsecurity
FROM pg_tables 
WHERE tablename = 'usuarios_rdm';

-- Verificar políticas ativas
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'usuarios_rdm';

-- ============================================
-- PARA REATIVAR DEPOIS (QUANDO ESTIVER FUNCIONANDO)
-- ============================================

/*
-- Reativar RLS e criar políticas corretas
ALTER TABLE usuarios_rdm ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuarios_rdm_temp_all_access" ON usuarios_rdm;

CREATE POLICY "usuarios_rdm_select_policy" ON usuarios_rdm
    FOR SELECT USING (tenant_id = (SELECT auth.uid()));

CREATE POLICY "usuarios_rdm_insert_policy" ON usuarios_rdm
    FOR INSERT WITH CHECK (tenant_id = (SELECT auth.uid()));

CREATE POLICY "usuarios_rdm_update_policy" ON usuarios_rdm
    FOR UPDATE USING (tenant_id = (SELECT auth.uid()));

CREATE POLICY "usuarios_rdm_delete_policy" ON usuarios_rdm
    FOR DELETE USING (tenant_id = (SELECT auth.uid()));
*/ 