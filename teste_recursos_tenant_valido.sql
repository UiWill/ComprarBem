-- Script de teste com tenant válido fornecido
-- Tenant ID: dcfe1030-27dd-4964-8e22-08a9c3fab790

-- 1. Adicionar colunas que estão faltando
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS fundamentacao TEXT;
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS documento_recorrente TEXT;
ALTER TABLE recursos ADD COLUMN IF NOT EXISTS documentos_anexos TEXT[];

-- 2. Ajustar constraint da coluna data_recurso
ALTER TABLE recursos ALTER COLUMN data_recurso SET DEFAULT NOW();
ALTER TABLE recursos ALTER COLUMN data_recurso DROP NOT NULL;

-- 3. Configurar RLS permissivo
ALTER TABLE recursos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "recursos_select_policy" ON recursos;
DROP POLICY IF EXISTS "recursos_insert_policy" ON recursos;
DROP POLICY IF EXISTS "recursos_update_policy" ON recursos;
DROP POLICY IF EXISTS "recursos_delete_policy" ON recursos;

CREATE POLICY "recursos_select_policy" ON recursos FOR SELECT USING (true);
CREATE POLICY "recursos_insert_policy" ON recursos FOR INSERT WITH CHECK (true);
CREATE POLICY "recursos_update_policy" ON recursos FOR UPDATE USING (true);
CREATE POLICY "recursos_delete_policy" ON recursos FOR DELETE USING (true);

-- 4. Garantir permissões
GRANT ALL ON recursos TO authenticated;
GRANT ALL ON recursos TO anon;
GRANT ALL ON recursos TO service_role;

-- 5. Teste de inserção com tenant válido
INSERT INTO recursos (
    tenant_id, 
    ata_referencia, 
    produto_nome, 
    recorrente, 
    data_recurso,
    prazo_final, 
    fundamentacao
) VALUES (
    'dcfe1030-27dd-4964-8e22-08a9c3fab790'::uuid, 
    'TESTE-TENANT-VALIDO-001', 
    'Produto Teste com Tenant Válido', 
    'Sistema Teste Final',
    NOW(),
    NOW() + INTERVAL '3 days',
    'Teste final de funcionamento da tabela recursos com tenant válido'
);

-- 6. Verificar se funcionou
SELECT 
    'TESTE CONCLUÍDO COM SUCESSO' as status,
    count(*) as total_recursos,
    max(criado_em) as ultimo_registro
FROM recursos;

-- 7. Mostrar último recurso criado
SELECT 
    'ÚLTIMO RECURSO CRIADO' as status,
    id,
    tenant_id,
    recorrente,
    produto_nome,
    ata_referencia,
    status,
    criado_em
FROM recursos 
ORDER BY criado_em DESC 
LIMIT 1;