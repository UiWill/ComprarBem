-- ==============================================
-- SCRIPT SIMPLES PARA CORRIGIR STATUS
-- ==============================================

-- Remover constraint antiga
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- Adicionar nova constraint com todos os status
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
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
    'criado_cpm_desp',
    'aguardando_assinatura_orgao_desp',
    'abertura_autorizada_desp',
    'aviso_publicado',
    'com_recurso_desp',
    'homologado_desp',
    'excluindo_marcas',
    'rejeitado_cpm',
    'rejeitado_admin',
    'rejeitado_ccl',
    'rejeitado_juridico',
    'rejeitado_final',
    'devolvido_pelo_orgao',
    'devolvido_pela_ccl',
    'devolvido_pelo_juridico'
));

-- Verificar se funcionou
SELECT 'Constraint criada com sucesso!' as resultado;