-- ============================================================
-- MIGRAÇÃO DE STATUS DOS PROCESSOS ADMINISTRATIVOS
-- Conforme especificação do cliente para nova tramitação
-- ============================================================

-- IMPORTANTE: Execute este script em ambiente de desenvolvimento primeiro!
-- Faça backup da tabela antes de executar em produção!

-- Backup da tabela (opcional - descomente se necessário)
-- CREATE TABLE processos_administrativos_backup AS SELECT * FROM processos_administrativos;

-- ============================================================
-- 1. MIGRAÇÃO DOS STATUS DE PADRONIZAÇÃO (VERDE)
-- ============================================================

-- Mapeamento dos status antigos para os novos status conforme cliente:
-- rascunho → em_criacao
-- aguardando_aprovacao → criado_cpm (legado)
-- criado_cpm → criado_cpm (mantém)
-- aguardando_assinatura_orgao → submetido_autoridade
-- assinado_admin → abertura_autorizada
-- julgamento_ccl → julgamento_ccl (mantém, mas agora é "Submetido ao Julgamento da CCL")
-- aprovado_ccl → ata_ccl
-- aprovado_juridico → analise_juridica
-- edital_publicado → edital_publicado (mantém)
-- homologado → homologado (mantém)
-- finalizado → incluindo_marcas

BEGIN;

-- Atualizar status de padronização
UPDATE processos_administrativos 
SET status = 'em_criacao' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'rascunho';

UPDATE processos_administrativos 
SET status = 'criado_cpm' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'aguardando_aprovacao';

UPDATE processos_administrativos 
SET status = 'submetido_autoridade' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'aguardando_assinatura_orgao';

UPDATE processos_administrativos 
SET status = 'abertura_autorizada' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'assinado_admin';

UPDATE processos_administrativos 
SET status = 'ata_ccl' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'aprovado_ccl';

UPDATE processos_administrativos 
SET status = 'analise_juridica' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'aprovado_juridico';

UPDATE processos_administrativos 
SET status = 'incluindo_marcas' 
WHERE tipo_processo = 'padronizacao' 
AND status = 'finalizado';

-- ============================================================
-- 2. MIGRAÇÃO DOS STATUS DE DESPADRONIZAÇÃO (VERMELHO)
-- ============================================================

-- Mapeamento dos status antigos para os novos status conforme cliente:
-- rascunho → em_criacao_desp
-- aguardando_assinatura_orgao_desp → submetido_autoridade_desp
-- aviso_publicado → aviso_publicado_desp

UPDATE processos_administrativos 
SET status = 'em_criacao_desp' 
WHERE tipo_processo = 'despadronizacao' 
AND status = 'rascunho';

UPDATE processos_administrativos 
SET status = 'submetido_autoridade_desp' 
WHERE tipo_processo = 'despadronizacao' 
AND status = 'aguardando_assinatura_orgao_desp';

UPDATE processos_administrativos 
SET status = 'aviso_publicado_desp' 
WHERE tipo_processo = 'despadronizacao' 
AND status = 'aviso_publicado';

-- ============================================================
-- 3. ATUALIZAR CONSTRAINT PARA ACEITAR NOVOS STATUS
-- ============================================================

-- Remover constraint antiga se existir
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- Adicionar nova constraint com todos os status
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
  -- STATUS PADRONIZAÇÃO
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
  
  -- STATUS DESPADRONIZAÇÃO
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
  'aviso_publicado'
));

-- ============================================================
-- 4. VERIFICAÇÃO DOS RESULTADOS
-- ============================================================

-- Verificar contagem de status após migração
SELECT 
  tipo_processo,
  status,
  COUNT(*) as quantidade
FROM processos_administrativos 
GROUP BY tipo_processo, status
ORDER BY tipo_processo, status;

-- Verificar se há algum status inválido
SELECT DISTINCT status 
FROM processos_administrativos 
WHERE status NOT IN (
  -- STATUS PADRONIZAÇÃO
  'em_criacao', 'criado_cpm', 'submetido_autoridade', 'abertura_autorizada',
  'edital_chamamento', 'analise_juridica', 'edital_publicado', 'com_impugnacao',
  'recebendo_amostras', 'avaliacao_cpm', 'julgamento_ccl', 'ata_ccl',
  'publicacao_ata', 'com_recurso', 'homologado', 'expedindo_dcbs', 'incluindo_marcas',
  
  -- STATUS DESPADRONIZAÇÃO
  'em_criacao_desp', 'criado_cpm_desp', 'submetido_autoridade_desp',
  'abertura_autorizada_desp', 'aviso_publicado_desp', 'com_recurso_desp',
  'homologado_desp', 'excluindo_marcas',
  
  -- STATUS DE DEVOLUÇÃO
  'devolvido_pelo_orgao', 'devolvido_pela_ccl', 'devolvido_pelo_juridico',
  
  -- STATUS LEGADOS
  'rascunho', 'iniciado', 'aguardando_aprovacao', 'analise_cppm',
  'aguardando_assinatura_orgao', 'assinado_admin', 'aprovado_ccl',
  'aprovado_juridico', 'rejeitado_cpm', 'rejeitado_admin', 'rejeitado_ccl',
  'rejeitado_juridico', 'rejeitado_final', 'finalizado',
  'aguardando_assinatura_orgao_desp', 'aviso_publicado'
);

COMMIT;

-- ============================================================
-- 5. COMENTÁRIOS E OBSERVAÇÕES
-- ============================================================

-- MAPEAMENTO COMPLETO DE STATUS:
-- 
-- PADRONIZAÇÃO (VERDE):
-- 1. Em Criação (em_criacao)
-- 2. Criado pela CPM (criado_cpm)
-- 3. Submetido à Autoridade Competente (submetido_autoridade)
-- 4. Abertura Autorizada (abertura_autorizada)
-- 5. Edital de Chamamento Público (edital_chamamento)
-- 6. Em Análise Jurídica (analise_juridica)
-- 7. Com Edital Publicado (edital_publicado)
-- 8. Com Impugnação ao Edital (com_impugnacao)
-- 9. Recebendo Amostras e Documentação (recebendo_amostras)
-- 10. Com Avaliação e Relatório da CPM (avaliacao_cpm)
-- 11. Submetido ao Julgamento da CCL (julgamento_ccl)
-- 12. Ata de Julgamento da CCL (ata_ccl)
-- 13. Publicação da Ata e Prazo Recursal (publicacao_ata)
-- 14. Com Recurso Administrativo (com_recurso)
-- 15. Com Homologação (homologado)
-- 16. Expedindo as DCBs (expedindo_dcbs)
-- 17. Incluindo Marcas no Catálogo (incluindo_marcas)
--
-- DESPADRONIZAÇÃO (VERMELHO):
-- 1. Em Criação (em_criacao_desp)
-- 2. Criado pela CPM (criado_cpm_desp)
-- 3. Submetido à Autoridade Competente (submetido_autoridade_desp)
-- 4. Abertura Autorizada (abertura_autorizada_desp)
-- 5. Com Aviso Publicado (aviso_publicado_desp)
-- 6. Com Recurso Administrativo (com_recurso_desp)
-- 7. Com Homologação (homologado_desp)
-- 8. Excluindo Marcas do Catálogo (excluindo_marcas)

-- FIM DO SCRIPT