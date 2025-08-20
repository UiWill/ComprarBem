-- ============================================================
-- CORREÇÃO DA CONSTRAINT DE STATUS PARA INCLUIR STATUS CCL
-- ============================================================

-- 1. Remover a constraint antiga de status (se existir)
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- 2. Criar nova constraint com TODOS os status necessários, incluindo CCL
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
    -- STATUS PADRONIZAÇÃO (VERDE)
    'em_criacao',
    'criado_cpm',
    'submetido_autoridade',
    'abertura_autorizada',
    'edital_chamamento',
    'analise_juridica',
    'edital_publicado',
    'com_impugnacao',
    'recebendo_amostras',
    'avaliacao_cpm',
    'julgamento_ccl',
    'ata_ccl',
    'publicacao_ata',
    'com_recurso',
    'homologado',
    'expedindo_dcbs',
    'incluindo_marcas',
    
    -- STATUS DESPADRONIZAÇÃO (VERMELHO)
    'em_criacao_desp',
    'criado_cpm_desp',
    'submetido_autoridade_desp',
    'abertura_autorizada_desp',
    'aviso_publicado_desp',
    'com_recurso_desp',
    'homologado_desp',
    'excluindo_marcas',
    
    -- STATUS DE DEVOLUÇÃO
    'devolvido_pelo_orgao',
    'devolvido_pela_ccl',
    'devolvido_pelo_juridico',
    
    -- STATUS CCL DE JULGAMENTO (NECESSÁRIOS PARA HOMOLOGAÇÃO)
    'ata_julgamento_ccl_homologacao',
    'ata_julgamento_ccl_indeferimento',
    'ata_julgamento_ccl_aprovacao',
    'ata_julgamento_ccl_rejeicao',
    'diligencia_ccl',
    'tramitando_ccl',
    'julgado_ccl',
    
    -- STATUS LEGADOS (manter para compatibilidade)
    'rascunho',
    'iniciado',
    'aguardando_aprovacao',
    'analise_cppm',
    'aguardando_assinatura_orgao',
    'assinado_admin',
    'aprovado_ccl',
    'aprovado_juridico',
    'rejeitado_cpm',
    'rejeitado_admin',
    'rejeitado_ccl',
    'rejeitado_juridico',
    'rejeitado_final',
    'finalizado',
    'aguardando_assinatura_orgao_desp',
    'aviso_publicado',
    'indeferido'
));

-- 3. Verificar se a constraint foi criada corretamente
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND conname = 'processos_administrativos_status_check';

-- 4. Testar se os status CCL são aceitos
SELECT 'Teste - Status CCL permitidos' as status_teste;