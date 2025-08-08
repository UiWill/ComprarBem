-- =====================================================
-- TABELA PARA DOCUMENTOS DOS PRODUTOS VINCULADOS AO PROCESSO
-- VERSÃO ALTERNATIVA SEM RLS COMPLEXO
-- =====================================================

-- Criar tabela exclusiva para documentos de produtos no processo
CREATE TABLE IF NOT EXISTS documentos_produtos_processo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  processo_id UUID NOT NULL REFERENCES processos_administrativos(id) ON DELETE CASCADE,
  produto_id UUID NOT NULL, -- Referência ao produto original
  tenant_id UUID NOT NULL,
  
  -- Informações do documento
  nome_arquivo TEXT NOT NULL,
  tipo_arquivo TEXT,
  tamanho BIGINT,
  url_arquivo TEXT NOT NULL,
  
  -- Informações do produto (para facilitar consultas)
  nome_produto TEXT NOT NULL,
  marca TEXT,
  fabricante TEXT,
  
  -- Controle
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  criado_por UUID REFERENCES auth.users(id),
  
  -- Constraint única
  UNIQUE(processo_id, produto_id, nome_arquivo, tenant_id)
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_documentos_produtos_processo_processo_id ON documentos_produtos_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_documentos_produtos_processo_produto_id ON documentos_produtos_processo(produto_id);
CREATE INDEX IF NOT EXISTS idx_documentos_produtos_processo_tenant_id ON documentos_produtos_processo(tenant_id);

-- Habilitar RLS (Row Level Security)
ALTER TABLE documentos_produtos_processo ENABLE ROW LEVEL SECURITY;

-- Política RLS simples para usuários autenticados
DROP POLICY IF EXISTS "Documentos produtos processo acesso" ON documentos_produtos_processo;
CREATE POLICY "Documentos produtos processo acesso" ON documentos_produtos_processo
  FOR ALL 
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Comentários para documentação
COMMENT ON TABLE documentos_produtos_processo IS 'Documentos dos produtos vinculados especificamente a processos administrativos';
COMMENT ON COLUMN documentos_produtos_processo.processo_id IS 'ID do processo administrativo';
COMMENT ON COLUMN documentos_produtos_processo.produto_id IS 'ID do produto original (referência)';
COMMENT ON COLUMN documentos_produtos_processo.nome_produto IS 'Nome do produto (desnormalizado para facilitar consultas)';
COMMENT ON COLUMN documentos_produtos_processo.url_arquivo IS 'URL do arquivo no storage';

-- Conceder permissões para uso
GRANT ALL ON documentos_produtos_processo TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;