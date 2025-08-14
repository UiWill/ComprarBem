-- ==============================================
-- SCRIPT PARA CORRIGIR CHECK CONSTRAINT DOS STATUS
-- ==============================================
-- Este script atualiza a constraint de status para incluir TODOS os status do sistema
-- Alinhado com TramitacaoProcessosService e filtros dos Processos Administrativos

-- Remover a constraint antiga de status (se existir)
ALTER TABLE processos_administrativos 
DROP CONSTRAINT IF EXISTS processos_administrativos_status_check;

-- Criar nova constraint com TODOS os status necessários
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
    -- STATUS DE PADRONIZAÇÃO (Fluxo Principal)
    'rascunho',                        -- Em criação
    'criado_cpm',                      -- Criado pela CPM
    'aguardando_assinatura_orgao',     -- Aguardando assinatura do órgão
    'assinado_admin',                  -- Assinado pelo órgão
    'julgamento_ccl',                  -- Em julgamento na CCL
    'aprovado_ccl',                    -- Aprovado pela CCL
    'aprovado_juridico',               -- Aprovado pela Assessoria Jurídica
    'edital_publicado',                -- Edital publicado
    'homologado',                      -- Homologado
    'finalizado',                      -- Finalizado
    
    -- STATUS DE DESPADRONIZAÇÃO (Fluxo Principal)
    'criado_cpm_desp',                 -- Criado pela CPM (despadronização)
    'aguardando_assinatura_orgao_desp', -- Aguardando assinatura do órgão (desp)
    'abertura_autorizada_desp',        -- Abertura autorizada
    'aviso_publicado',                 -- Aviso publicado
    'com_recurso_desp',                -- Com recurso administrativo
    'homologado_desp',                 -- Homologado (despadronização)
    'excluindo_marcas',                -- Excluindo marcas do catálogo
    
    -- STATUS DE DEVOLUÇÃO (Podem retornar ao fluxo)
    'devolvido_pelo_orgao',            -- Devolvido pelo Órgão Administrativo
    'devolvido_pela_ccl',              -- Devolvido pela CCL
    'devolvido_pelo_juridico',         -- Devolvido pela Assessoria Jurídica
    
    -- STATUS DE REJEIÇÃO (Status finais)
    'rejeitado_cpm',                   -- Rejeitado pela CPM
    'rejeitado_admin',                 -- Rejeitado pelo Órgão
    'rejeitado_ccl',                   -- Rejeitado pela CCL
    'rejeitado_juridico',              -- Rejeitado pela Assessoria Jurídica
    'rejeitado_final'                  -- Rejeitado final
));

-- Verificar se a constraint foi criada corretamente
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND conname = 'processos_administrativos_status_check';