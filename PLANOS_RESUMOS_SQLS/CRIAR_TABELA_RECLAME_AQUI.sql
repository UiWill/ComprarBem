-- Criar tabela para o sistema Reclame Aqui
-- Sistema de reclamações públicas com respostas da CPM

CREATE TABLE IF NOT EXISTS reclame_aqui (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- Dados do reclamante
  nome_reclamante VARCHAR(255) NOT NULL,
  setor_reclamante VARCHAR(255),
  cargo_reclamante VARCHAR(255),
  
  -- Dados da reclamação
  titulo_reclamacao VARCHAR(500) NOT NULL,
  descricao_reclamacao TEXT NOT NULL,
  categoria VARCHAR(100), -- Ex: "Produto", "Atendimento", "Sistema", etc.
  
  -- Status da reclamação
  status VARCHAR(50) DEFAULT 'pendente', -- pendente, em_analise, respondida, resolvida
  prioridade VARCHAR(20) DEFAULT 'normal', -- baixa, normal, alta, critica
  
  -- Dados da resposta da CPM
  resposta_cpm TEXT,
  respondido_por UUID REFERENCES auth.users(id),
  respondido_em TIMESTAMP WITH TIME ZONE,
  
  -- Controle
  publica BOOLEAN DEFAULT true, -- Se a reclamação é pública ou privada
  tenant_id UUID REFERENCES tenants(id),
  
  -- Timestamps
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_reclame_aqui_status ON reclame_aqui(status);
CREATE INDEX IF NOT EXISTS idx_reclame_aqui_tenant ON reclame_aqui(tenant_id);
CREATE INDEX IF NOT EXISTS idx_reclame_aqui_publica ON reclame_aqui(publica);
CREATE INDEX IF NOT EXISTS idx_reclame_aqui_data ON reclame_aqui(criado_em DESC);

-- RLS (Row Level Security)
ALTER TABLE reclame_aqui ENABLE ROW LEVEL SECURITY;

-- Política para leitura pública das reclamações públicas
CREATE POLICY "Reclamações públicas podem ser lidas por todos" ON reclame_aqui
  FOR SELECT 
  USING (publica = true);

-- Política para CPM gerenciar todas as reclamações do seu tenant
CREATE POLICY "CPM pode gerenciar reclamações do seu tenant" ON reclame_aqui
  FOR ALL 
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios 
      WHERE id = auth.uid() 
      AND perfil_usuario = 'cpm'
      AND tenant_id = reclame_aqui.tenant_id
    )
  );

-- Política para inserção pública (qualquer pessoa pode criar reclamação)
CREATE POLICY "Qualquer pessoa pode criar reclamação" ON reclame_aqui
  FOR INSERT 
  WITH CHECK (true);

-- Trigger para atualizar timestamp
CREATE OR REPLACE FUNCTION update_reclame_aqui_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_reclame_aqui_timestamp
  BEFORE UPDATE ON reclame_aqui
  FOR EACH ROW
  EXECUTE FUNCTION update_reclame_aqui_timestamp();

-- Comentários
COMMENT ON TABLE reclame_aqui IS 'Tabela para sistema de reclamações públicas tipo Reclame Aqui';
COMMENT ON COLUMN reclame_aqui.publica IS 'Define se a reclamação aparece na lista pública';
COMMENT ON COLUMN reclame_aqui.status IS 'Status: pendente, em_analise, respondida, resolvida';
COMMENT ON COLUMN reclame_aqui.prioridade IS 'Prioridade: baixa, normal, alta, critica';