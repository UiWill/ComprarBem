-- 🔧 CORREÇÃO URGENTE - POLÍTICA RLS PRODUTOS
-- Execute este código no Supabase SQL Editor

-- 1. Remover política antiga (que não funciona)
DROP POLICY IF EXISTS "tenant_isolation_produtos" ON produtos;

-- 2. Criar política corrigida (que funciona com o código atual)
CREATE POLICY "tenant_isolation_produtos" ON produtos
FOR ALL TO authenticated
USING (
    tenant_id = (
        SELECT tenant_id 
        FROM usuarios 
        WHERE email = auth.email()
        LIMIT 1
    )
);

-- 3. Política alternativa para INSERT (mais permissiva se necessário)
CREATE POLICY "allow_insert_produtos" ON produtos
FOR INSERT TO authenticated
WITH CHECK (true);

-- 4. Verificar se a tabela tem RLS habilitado
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;

-- 5. TESTE: Para verificar se funcionou
-- SELECT * FROM produtos WHERE tenant_id IS NOT NULL; 