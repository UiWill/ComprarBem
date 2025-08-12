-- ==============================================
-- SCRIPT PARA ADICIONAR COLUNAS DE DEVOLUÇÃO
-- ==============================================
-- Este script adiciona as colunas necessárias para o sistema de devolução

-- Adicionar colunas de devolução à tabela processos_administrativos
ALTER TABLE processos_administrativos 
ADD COLUMN IF NOT EXISTS motivo_devolucao TEXT,
ADD COLUMN IF NOT EXISTS observacoes_devolucao TEXT,
ADD COLUMN IF NOT EXISTS devolvido_por VARCHAR(50),
ADD COLUMN IF NOT EXISTS data_devolucao TIMESTAMPTZ;

-- Comentários para documentação
COMMENT ON COLUMN processos_administrativos.motivo_devolucao IS 'Motivo da devolução do processo';
COMMENT ON COLUMN processos_administrativos.observacoes_devolucao IS 'Observações adicionais sobre a devolução';
COMMENT ON COLUMN processos_administrativos.devolvido_por IS 'Perfil do usuário que devolveu o processo (orgao_administrativo, ccl, assessoria_juridica)';
COMMENT ON COLUMN processos_administrativos.data_devolucao IS 'Data e hora da devolução do processo';

-- Verificar se as colunas foram criadas com sucesso
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name IN ('motivo_devolucao', 'observacoes_devolucao', 'devolvido_por', 'data_devolucao')
ORDER BY column_name;

-- ✅ EXECUÇÃO CONCLUÍDA
-- As colunas foram adicionadas com sucesso à tabela processos_administrativos