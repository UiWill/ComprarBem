-- Adicionar campos para suporte à numeração individual de páginas PDF
-- Permite que cada página de um PDF seja tratada como uma folha separada no processo

ALTER TABLE documentos_processo
ADD COLUMN IF NOT EXISTS pagina_pdf INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS total_paginas_pdf INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS nome_arquivo_original TEXT;

-- Comentários explicativos
COMMENT ON COLUMN documentos_processo.pagina_pdf IS 'Número da página dentro do PDF original (1, 2, 3, etc.)';
COMMENT ON COLUMN documentos_processo.total_paginas_pdf IS 'Total de páginas do arquivo PDF original';
COMMENT ON COLUMN documentos_processo.nome_arquivo_original IS 'Nome original do arquivo PDF antes do processamento';

-- Atualizar registros existentes para compatibilidade
UPDATE documentos_processo
SET pagina_pdf = 1,
    total_paginas_pdf = 1,
    nome_arquivo_original = nome_documento
WHERE pagina_pdf IS NULL;

-- Criar índice para consultas por página
CREATE INDEX IF NOT EXISTS idx_documentos_processo_pagina
ON documentos_processo(processo_id, pagina_pdf, total_paginas_pdf);

-- Verificar se a alteração foi aplicada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'documentos_processo'
  AND column_name IN ('pagina_pdf', 'total_paginas_pdf', 'nome_arquivo_original')
ORDER BY column_name;