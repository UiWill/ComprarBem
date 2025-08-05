-- RESOLUÇÃO DIRETA DO ERRO 403 EM PROCESSOS ADMINISTRATIVOS

-- 1. Desabilitar RLS nas tabelas problemáticas
ALTER TABLE processos_administrativos DISABLE ROW LEVEL SECURITY;
ALTER TABLE configuracao_numeracao DISABLE ROW LEVEL SECURITY;

-- 2. Se existir a tabela documentos_processo, desabilitar também
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'documentos_processo') THEN
        ALTER TABLE documentos_processo DISABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- 3. Verificar se funcionou
SELECT 
    'TABELAS CORRIGIDAS' as status,
    tablename,
    CASE WHEN rowsecurity THEN 'RLS ATIVO' ELSE 'RLS DESABILITADO' END as estado
FROM pg_tables 
WHERE tablename IN ('processos_administrativos', 'configuracao_numeracao', 'documentos_processo');

-- 4. Limpar políticas restritivas se existirem
DROP POLICY IF EXISTS "Processos isolados por tenant" ON processos_administrativos;
DROP POLICY IF EXISTS "Configuração por tenant" ON configuracao_numeracao;
DROP POLICY IF EXISTS "Documentos por tenant" ON documentos_processo;

-- 5. Verificar estrutura da tabela processos_administrativos
SELECT 
    'ESTRUTURA PROCESSOS_ADMINISTRATIVOS' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos'
ORDER BY ordinal_position;

-- 6. Testar consulta simples
SELECT 
    'TESTE DE CONSULTA' as teste,
    COUNT(*) as total_processos
FROM processos_administrativos;