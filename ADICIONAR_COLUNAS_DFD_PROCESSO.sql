-- =====================================================
-- ADICIONAR COLUNAS FALTANTES EM DFD_PROCESSO
-- =====================================================

-- Adicionar colunas dos dados do demandante/presidente
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS nome_presidente TEXT;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS matricula_presidente TEXT;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS email_presidente TEXT;
ALTER TABLE dfd_processo ADD COLUMN IF NOT EXISTS telefone_presidente TEXT;

-- Adicionar comentários explicativos
COMMENT ON COLUMN dfd_processo.nome_presidente IS 'Nome completo do presidente da CPPM';
COMMENT ON COLUMN dfd_processo.matricula_presidente IS 'Matrícula funcional do presidente';
COMMENT ON COLUMN dfd_processo.email_presidente IS 'Email institucional do presidente';
COMMENT ON COLUMN dfd_processo.telefone_presidente IS 'Telefone de contato do presidente';

-- Verificação
SELECT 'Colunas do presidente adicionadas com sucesso!' as resultado;

-- Mostrar estrutura atualizada
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'dfd_processo' 
AND column_name IN ('nome_presidente', 'matricula_presidente', 'email_presidente', 'telefone_presidente');

SELECT 'PRONTO! Agora a tabela dfd_processo tem as colunas do presidente ✅' as status;