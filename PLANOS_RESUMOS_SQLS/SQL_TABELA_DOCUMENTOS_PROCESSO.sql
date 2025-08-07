-- Criar tabela para controle de documentos dos processos administrativos
-- com numeração sequencial automática (Fl. 001, 002, 003, etc.)

CREATE TABLE IF NOT EXISTS documentos_processo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Relacionamentos
    processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    
    -- Numeração sequencial
    numero_sequencial INTEGER NOT NULL,
    folha_numero VARCHAR(20) NOT NULL, -- Ex: "Fl. 001", "Fl. 002"
    
    -- Informações do documento
    tipo_documento VARCHAR(50) NOT NULL, -- DFD, EDITAL, ATA, PARECER, ANEXO, etc.
    nome_documento TEXT NOT NULL,
    descricao TEXT,
    
    -- Conteúdo
    conteudo JSONB, -- Conteúdo estruturado do documento
    conteudo_html TEXT, -- Versão HTML para visualização
    arquivo_url TEXT, -- URL do arquivo (se uploadado)
    
    -- Metadados
    tamanho_arquivo BIGINT, -- Tamanho em bytes
    tipo_mime VARCHAR(100),
    hash_arquivo VARCHAR(64), -- Para verificar integridade
    
    -- Controle de estado
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'arquivado')),
    
    -- Auditoria
    criado_por UUID,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    data_remocao TIMESTAMP WITH TIME ZONE,
    
    -- Versionamento
    versao INTEGER DEFAULT 1,
    documento_pai UUID REFERENCES documentos_processo(id), -- Para controle de versões
    
    -- Observações
    observacoes TEXT
);

-- Índices para performance
CREATE INDEX idx_documentos_processo_processo_id ON documentos_processo(processo_id);
CREATE INDEX idx_documentos_processo_tenant_id ON documentos_processo(tenant_id);
CREATE INDEX idx_documentos_processo_numero_seq ON documentos_processo(processo_id, numero_sequencial);
CREATE INDEX idx_documentos_processo_status ON documentos_processo(status);
CREATE INDEX idx_documentos_processo_tipo ON documentos_processo(tipo_documento);
CREATE INDEX idx_documentos_processo_data_criacao ON documentos_processo(data_criacao);

-- Constraint para garantir numeração única por processo
CREATE UNIQUE INDEX idx_documentos_processo_numeracao_unica 
ON documentos_processo(processo_id, numero_sequencial) 
WHERE status = 'ativo';

-- Trigger para atualizar data_atualizacao
CREATE OR REPLACE FUNCTION atualizar_data_atualizacao_documentos_processo()
RETURNS TRIGGER AS $$
BEGIN
    NEW.data_atualizacao = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_data_atualizacao_documentos_processo
    BEFORE UPDATE ON documentos_processo
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_data_atualizacao_documentos_processo();

-- Função para obter próximo número sequencial
CREATE OR REPLACE FUNCTION obter_proximo_numero_sequencial(processo_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    proximo_numero INTEGER;
BEGIN
    SELECT COALESCE(MAX(numero_sequencial), 0) + 1
    INTO proximo_numero
    FROM documentos_processo
    WHERE processo_id = processo_uuid AND status = 'ativo';
    
    RETURN proximo_numero;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar número da folha
CREATE OR REPLACE FUNCTION formatar_folha_numero(numero INTEGER)
RETURNS VARCHAR(20) AS $$
BEGIN
    RETURN 'Fl. ' || LPAD(numero::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql;

-- View para facilitar consultas de documentos com informações do processo
CREATE OR REPLACE VIEW vw_documentos_processo AS
SELECT 
    dp.*,
    pa.numero_processo,
    pa.tipo_processo,
    pa.titulo as titulo_processo,
    pa.status as status_processo,
    u.nome as criado_por_nome
FROM documentos_processo dp
LEFT JOIN processos_administrativos pa ON dp.processo_id = pa.id
LEFT JOIN usuarios u ON dp.criado_por = u.id
WHERE dp.status = 'ativo'
ORDER BY dp.processo_id, dp.numero_sequencial;

-- Política RLS para documentos_processo
ALTER TABLE documentos_processo ENABLE ROW LEVEL SECURITY;

-- Política para permitir acesso baseado no tenant_id
CREATE POLICY "Acesso por tenant" ON documentos_processo
    FOR ALL
    USING (tenant_id = (auth.jwt() ->> 'user_metadata' ->> 'tenant_id')::uuid);

-- Função para validar sequência de documentos
CREATE OR REPLACE FUNCTION validar_sequencia_documentos(processo_uuid UUID)
RETURNS TABLE(
    valida BOOLEAN,
    total_documentos INTEGER,
    lacunas INTEGER[],
    duplicatas INTEGER[]
) AS $$
DECLARE
    doc_record RECORD;
    numeros_existentes INTEGER[];
    numero_atual INTEGER;
    lacunas_encontradas INTEGER[] := '{}';
    duplicatas_encontradas INTEGER[] := '{}';
    numero_maximo INTEGER := 0;
    contador INTEGER := 0;
BEGIN
    -- Buscar todos os números sequenciais ativos
    SELECT array_agg(numero_sequencial ORDER BY numero_sequencial)
    INTO numeros_existentes
    FROM documentos_processo
    WHERE processo_id = processo_uuid AND status = 'ativo';
    
    -- Se não há documentos
    IF numeros_existentes IS NULL THEN
        RETURN QUERY SELECT true, 0, '{}'::INTEGER[], '{}'::INTEGER[];
        RETURN;
    END IF;
    
    -- Encontrar número máximo e contar total
    numero_maximo := numeros_existentes[array_upper(numeros_existentes, 1)];
    contador := array_length(numeros_existentes, 1);
    
    -- Verificar lacunas (números que deveriam existir mas não existem)
    FOR numero_atual IN 1..numero_maximo LOOP
        IF NOT (numero_atual = ANY(numeros_existentes)) THEN
            lacunas_encontradas := array_append(lacunas_encontradas, numero_atual);
        END IF;
    END LOOP;
    
    -- Verificar duplicatas
    FOR numero_atual IN 1..numero_maximo LOOP
        IF (SELECT COUNT(*) FROM unnest(numeros_existentes) AS n WHERE n = numero_atual) > 1 THEN
            duplicatas_encontradas := array_append(duplicatas_encontradas, numero_atual);
        END IF;
    END LOOP;
    
    -- Retornar resultado
    RETURN QUERY SELECT 
        (array_length(lacunas_encontradas, 1) IS NULL AND array_length(duplicatas_encontradas, 1) IS NULL),
        contador,
        lacunas_encontradas,
        duplicatas_encontradas;
END;
$$ LANGUAGE plpgsql;

-- Inserir dados de exemplo para documentos base
INSERT INTO documentos_processo (processo_id, tenant_id, numero_sequencial, folha_numero, tipo_documento, nome_documento, descricao, criado_por)
SELECT 
    pa.id,
    pa.tenant_id,
    1,
    'Fl. 001',
    'FOLHA_ROSTO',
    'Folha de Rosto do Processo',
    'Capa inicial do processo administrativo com informações básicas',
    pa.criado_por
FROM processos_administrativos pa
WHERE NOT EXISTS (
    SELECT 1 FROM documentos_processo dp 
    WHERE dp.processo_id = pa.id AND dp.tipo_documento = 'FOLHA_ROSTO'
);

-- Comentários na tabela
COMMENT ON TABLE documentos_processo IS 'Controla a numeração sequencial automática de documentos em processos administrativos';
COMMENT ON COLUMN documentos_processo.numero_sequencial IS 'Número sequencial único por processo (1, 2, 3...)';
COMMENT ON COLUMN documentos_processo.folha_numero IS 'Formatação da folha (Fl. 001, Fl. 002, etc.)';
COMMENT ON COLUMN documentos_processo.tipo_documento IS 'Tipo do documento: FOLHA_ROSTO, DFD, EDITAL, ATA, PARECER, ANEXO, etc.';
COMMENT ON COLUMN documentos_processo.conteudo IS 'Conteúdo estruturado em JSON para documentos gerados pelo sistema';
COMMENT ON COLUMN documentos_processo.conteudo_html IS 'Versão HTML para visualização e impressão';
COMMENT ON COLUMN documentos_processo.hash_arquivo IS 'Hash SHA-256 para verificação de integridade do arquivo';

-- Verificar se a tabela foi criada corretamente
SELECT 
    'Tabela documentos_processo criada com sucesso!' as status,
    COUNT(*) as total_constraints
FROM information_schema.table_constraints 
WHERE table_name = 'documentos_processo';