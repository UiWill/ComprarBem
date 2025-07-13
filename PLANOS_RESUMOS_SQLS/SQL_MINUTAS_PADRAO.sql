-- Sistema de Minutas Padrão para Editais de Pré-Qualificação
-- Criado em: 2024

-- Tabela para armazenar minutas padrão
CREATE TABLE IF NOT EXISTS minutas_padrao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    arquivo_nome VARCHAR(255) NOT NULL,
    arquivo_url TEXT,
    arquivo_conteudo BYTEA, -- Para armazenar o arquivo Word diretamente
    tipo_arquivo VARCHAR(10) DEFAULT 'docx',
    categoria VARCHAR(100), -- Ex: 'medicamentos', 'material_escritorio', etc.
    ativa BOOLEAN DEFAULT true,
    eh_padrao_sistema BOOLEAN DEFAULT false, -- Indica se é a minuta padrão do sistema
    criado_por UUID,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela para histórico de uso das minutas
CREATE TABLE IF NOT EXISTS minuta_uso_historico (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    minuta_id UUID REFERENCES minutas_padrao(id),
    edital_id UUID, -- Referência ao edital criado
    usuario_id UUID,
    data_uso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT
);

-- Atualizar tabela de editais para incluir referência à minuta usada
ALTER TABLE editais ADD COLUMN IF NOT EXISTS minuta_usada_id UUID REFERENCES minutas_padrao(id);
ALTER TABLE editais ADD COLUMN IF NOT EXISTS minuta_preenchida_url TEXT;
ALTER TABLE editais ADD COLUMN IF NOT EXISTS minuta_preenchida_nome VARCHAR(255);
ALTER TABLE editais ADD COLUMN IF NOT EXISTS pdf_convertido_url TEXT;
ALTER TABLE editais ADD COLUMN IF NOT EXISTS pdf_convertido_nome VARCHAR(255);

-- Inserir a minuta padrão do sistema
INSERT INTO minutas_padrao (
    nome, 
    descricao, 
    arquivo_nome, 
    categoria, 
    eh_padrao_sistema
) VALUES (
    'Minuta Padrão Sistema',
    'Minuta padrão do sistema para editais de pré-qualificação',
    'MINUTA PADRAO.docx',
    'geral',
    true
) ON CONFLICT DO NOTHING;

-- Índices para otimização
CREATE INDEX IF NOT EXISTS idx_minutas_padrao_ativa ON minutas_padrao(ativa);
CREATE INDEX IF NOT EXISTS idx_minutas_padrao_categoria ON minutas_padrao(categoria);
CREATE INDEX IF NOT EXISTS idx_minutas_padrao_eh_padrao ON minutas_padrao(eh_padrao_sistema);
CREATE INDEX IF NOT EXISTS idx_minuta_uso_historico_minuta_id ON minuta_uso_historico(minuta_id);
CREATE INDEX IF NOT EXISTS idx_editais_minuta_usada ON editais(minuta_usada_id);

-- Comentários para documentação
COMMENT ON TABLE minutas_padrao IS 'Armazena minutas padrão para editais de pré-qualificação';
COMMENT ON COLUMN minutas_padrao.eh_padrao_sistema IS 'Indica se é a minuta padrão do sistema (não pode ser excluída)';
COMMENT ON COLUMN minutas_padrao.arquivo_conteudo IS 'Conteúdo binário do arquivo Word';
COMMENT ON TABLE minuta_uso_historico IS 'Histórico de uso das minutas padrão'; 