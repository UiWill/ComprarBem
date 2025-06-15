-- 🚨 CORREÇÃO URGENTE - POLÍTICAS RLS DILIGÊNCIAS
-- Execute este código no Supabase SQL Editor para corrigir o erro de diligências

-- 1. Remover políticas antigas que não funcionam
DROP POLICY IF EXISTS "Diligências apenas do próprio tenant" ON diligencias;
DROP POLICY IF EXISTS "Editais apenas do próprio tenant" ON editais;
DROP POLICY IF EXISTS "Impugnações apenas do próprio tenant" ON impugnacoes;

-- 2. Criar políticas corretas usando o método que funciona
CREATE POLICY "tenant_isolation_diligencias" ON diligencias
FOR ALL TO authenticated
USING (
    tenant_id = (
        SELECT tenant_id 
        FROM usuarios 
        WHERE email = auth.email()
        LIMIT 1
    )
);

CREATE POLICY "tenant_isolation_editais" ON editais
FOR ALL TO authenticated
USING (
    tenant_id = (
        SELECT tenant_id 
        FROM usuarios 
        WHERE email = auth.email()
        LIMIT 1
    )
);

CREATE POLICY "tenant_isolation_impugnacoes" ON impugnacoes
FOR ALL TO authenticated
USING (
    tenant_id = (
        SELECT tenant_id 
        FROM usuarios 
        WHERE email = auth.email()
        LIMIT 1
    )
);

-- 3. Verificar se RLS está habilitado
ALTER TABLE diligencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE editais ENABLE ROW LEVEL SECURITY;
ALTER TABLE impugnacoes ENABLE ROW LEVEL SECURITY;

-- 4. Verificar se tabelas existem (consulta corrigida)
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('diligencias', 'editais', 'impugnacoes')
AND table_schema = 'public';

-- ✅ PRONTO! Execute este SQL no Supabase e teste as diligências novamente. 