-- Adicionar coluna para armazenar URL do PDF do relatório completo do processo
-- Este PDF será gerado quando o processo for enviado para CCL

ALTER TABLE processos_administrativos 
ADD COLUMN arquivo_relatorio_pdf TEXT;

-- Comentário na coluna
COMMENT ON COLUMN processos_administrativos.arquivo_relatorio_pdf IS 'URL do arquivo PDF completo do processo gerado quando enviado para CCL';

-- Verificar se a coluna foi adicionada
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'processos_administrativos' 
AND column_name = 'arquivo_relatorio_pdf';