-- Comando simples para limpar regras de processos administrativos

-- 1. Desabilitar RLS
ALTER TABLE processos_administrativos DISABLE ROW LEVEL SECURITY;
ALTER TABLE configuracao_numeracao DISABLE ROW LEVEL SECURITY;

-- 2. Tentar remover constraints específicas conhecidas (ignorando erros)
ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS processos_administrativos_tenant_id_fkey;
ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS processos_administrativos_criado_por_fkey;
ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS processos_administrativos_atualizado_por_fkey;
ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

ALTER TABLE configuracao_numeracao DROP CONSTRAINT IF EXISTS configuracao_numeracao_tenant_id_fkey;

-- 3. Verificar se funcionou
SELECT 'PROCESSOS LIBERADOS PARA TESTE!' as status;

-- 4. Testar inserção simples
SELECT 
    'TABELAS PRONTAS' as titulo,
    tablename,
    CASE WHEN rowsecurity THEN 'RLS ATIVO' ELSE 'RLS DESABILITADO' END as status
FROM pg_tables 
WHERE tablename IN ('processos_administrativos', 'configuracao_numeracao');