-- ==============================================
-- SCRIPT PARA CORRIGIR CHECK CONSTRAINT DOS STATUS
-- ==============================================
-- Este script atualiza a constraint de status para incluir os novos status de devolução

-- 1. Primeiro, vamos ver qual é a constraint atual
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c';

-- 2. Remover a constraint antiga de status (se existir)
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- 3. Criar nova constraint com todos os status necessários
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
    -- Status originais do fluxo de padronização
    'rascunho',
    'criado_cpm',
    'aguardando_aprovacao',
    'aguardando_assinatura_orgao',
    'assinado_admin',
    'julgamento_ccl',
    'aprovado_ccl',
    'aprovado_juridico',
    'edital_publicado',
    'homologado',
    'finalizado',
    
    -- Status de despadronização
    'criado_cpm_desp',
    'aguardando_assinatura_orgao_desp',
    'abertura_autorizada_desp',
    'aviso_publicado',
    'com_recurso_desp',
    'homologado_desp',
    'excluindo_marcas',
    
    -- Status de rejeição
    'rejeitado_cpm',
    'rejeitado_admin',
    'rejeitado_ccl',
    'rejeitado_juridico',
    'rejeitado_final',
    
    -- NOVOS STATUS DE DEVOLUÇÃO
    'devolvido_pelo_orgao',
    'devolvido_pela_ccl',
    'devolvido_pelo_juridico'
));

-- 4. Verificar se a constraint foi criada corretamente
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND conname = 'processos_administrativos_status_check';

-- 5. Testar se os novos status são aceitos (opcional - remover após teste)
-- UPDATE processos_administrativos 
-- SET status = 'devolvido_pelo_orgao' 
-- WHERE id = 'algum-id-de-teste';

-- ✅ EXECUÇÃO CONCLUÍDA
-- A constraint foi atualizada para aceitar os novos status de devolução