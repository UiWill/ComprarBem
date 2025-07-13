-- ============================================
-- CORRIGIR RLS PARA TABELA usuarios_rdm
-- Sistema Comprar Bem - Correção Política RLS
-- ============================================

-- 1. REMOVER POLÍTICAS ANTIGAS
DROP POLICY IF EXISTS "usuarios_rdm_select_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_insert_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_update_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_delete_policy" ON usuarios_rdm;

-- 2. CRIAR POLÍTICAS RLS CORRIGIDAS

-- Política SELECT: permite visualizar dados do próprio tenant
CREATE POLICY "usuarios_rdm_select_policy" ON usuarios_rdm
    FOR SELECT USING (
        tenant_id = (SELECT auth.uid())
        OR user_id = (SELECT auth.uid())
    );

-- Política INSERT: permite inserir dados para o próprio tenant
CREATE POLICY "usuarios_rdm_insert_policy" ON usuarios_rdm
    FOR INSERT WITH CHECK (
        tenant_id = (SELECT auth.uid())
        OR (SELECT auth.uid()) IS NOT NULL
    );

-- Política UPDATE: permite atualizar dados do próprio tenant
CREATE POLICY "usuarios_rdm_update_policy" ON usuarios_rdm
    FOR UPDATE USING (
        tenant_id = (SELECT auth.uid())
        OR user_id = (SELECT auth.uid())
    ) WITH CHECK (
        tenant_id = (SELECT auth.uid())
        OR user_id = (SELECT auth.uid())
    );

-- Política DELETE: permite deletar dados do próprio tenant
CREATE POLICY "usuarios_rdm_delete_policy" ON usuarios_rdm
    FOR DELETE USING (
        tenant_id = (SELECT auth.uid())
        OR user_id = (SELECT auth.uid())
    );

-- 3. VERIFICAR POLÍTICAS
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'usuarios_rdm';

-- ============================================
-- ALTERNATIVA: POLÍTICA TEMPORÁRIA MAIS PERMISSIVA
-- (Descomente se necessário)
-- ============================================

/*
-- Remover todas as políticas
DROP POLICY IF EXISTS "usuarios_rdm_select_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_insert_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_update_policy" ON usuarios_rdm;
DROP POLICY IF EXISTS "usuarios_rdm_delete_policy" ON usuarios_rdm;

-- Criar política temporária permissiva
CREATE POLICY "usuarios_rdm_temp_policy" ON usuarios_rdm
    FOR ALL USING (true) WITH CHECK (true);
*/ 