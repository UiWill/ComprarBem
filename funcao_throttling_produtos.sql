-- ============================================
-- FUNÇÃO PARA VERIFICAR NOVOS PRODUTOS COM SISTEMA ANTI-SPAM
-- ============================================

-- Substitui a função buscar_produtos_pendentes_notificacao
-- Implementa throttling para evitar notificações excessivas de novos produtos

-- Remover função existente se houver
DROP FUNCTION IF EXISTS buscar_produtos_pendentes_notificacao_com_throttling();

CREATE OR REPLACE FUNCTION buscar_produtos_pendentes_notificacao_com_throttling()
RETURNS TABLE (
  np_produto_id uuid,
  np_usuario_rdm_id uuid,
  np_tenant_id uuid,
  np_nome_produto text,
  np_usuario_nome text,
  np_usuario_email text,
  np_data_criacao_produto timestamptz,
  np_ultima_notificacao timestamptz
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id::uuid,
    urdm.id::uuid,
    urdm.tenant_id::uuid,
    p.nome::text,
    urdm.nome_usuario::text,
    urdm.email::text,
    p.updated_at::timestamptz,
    npn.ultima_notificacao::timestamptz
    
  FROM produtos p
  JOIN usuarios_rdm urdm ON urdm.tenant_id = p.tenant_id
  
  -- LEFT JOIN para verificar se já foi notificado
  LEFT JOIN (
    SELECT 
      produto_id,
      usuario_rdm_id,
      MAX(created_at) as ultima_notificacao
    FROM novos_produtos_notificados
    GROUP BY produto_id, usuario_rdm_id
  ) npn ON p.id = npn.produto_id AND urdm.id = npn.usuario_rdm_id
  
  WHERE 
    -- Produto atualizado recentemente (últimas 72 horas)
    p.updated_at > NOW() - INTERVAL '72 hours'
    
    -- Status ativo
    AND p.status = 'ATIVO'
    
    -- Usuário ativo e convite aceito
    AND urdm.ativo = true
    AND urdm.convite_aceito = true
    
    -- Sistema anti-spam: só notifica se nunca notificou OU se passou 24 horas
    AND (
      npn.ultima_notificacao IS NULL OR
      npn.ultima_notificacao < NOW() - INTERVAL '24 hours'
    )
  
  ORDER BY p.updated_at DESC
  LIMIT 50; -- Limita a 50 produtos por execução para evitar sobrecarga
  
END;
$$;

-- ============================================
-- FUNÇÃO PARA MARCAR PRODUTO COMO NOTIFICADO (ATUALIZADA)
-- ============================================

CREATE OR REPLACE FUNCTION marcar_produto_notificado(
  p_usuario_rdm_id uuid,
  p_produto_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  v_tenant_id uuid;
BEGIN
  -- Buscar tenant_id do usuário
  SELECT tenant_id INTO v_tenant_id
  FROM usuarios_rdm 
  WHERE id = p_usuario_rdm_id;
  
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não encontrado: %', p_usuario_rdm_id;
  END IF;
  
  -- Inserir registro na tabela de controle com throttling
  INSERT INTO novos_produtos_notificados (
    produto_id,
    usuario_rdm_id,
    tenant_id,
    created_at
  ) VALUES (
    p_produto_id,
    p_usuario_rdm_id,
    v_tenant_id,
    NOW()
  )
  ON CONFLICT (produto_id, usuario_rdm_id) 
  DO UPDATE SET 
    created_at = NOW(); -- Atualiza timestamp da última notificação
  
  RETURN true;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Erro ao marcar produto como notificado: %', SQLERRM;
    RETURN false;
END;
$$;

-- ============================================
-- CRIAR TABELA DE CONTROLE SE NÃO EXISTIR
-- ============================================

CREATE TABLE IF NOT EXISTS novos_produtos_notificados (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  produto_id uuid NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
  usuario_rdm_id uuid NOT NULL REFERENCES usuarios_rdm(id) ON DELETE CASCADE,
  tenant_id uuid NOT NULL,
  created_at timestamptz DEFAULT NOW(),
  
  -- Constraint para evitar duplicatas
  UNIQUE(produto_id, usuario_rdm_id)
);

-- Index para performance
CREATE INDEX IF NOT EXISTS idx_novos_produtos_notificados_lookup 
ON novos_produtos_notificados(produto_id, usuario_rdm_id);

CREATE INDEX IF NOT EXISTS idx_novos_produtos_notificados_tenant 
ON novos_produtos_notificados(tenant_id);

-- RLS Policy
ALTER TABLE novos_produtos_notificados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Notificações isoladas por tenant" ON novos_produtos_notificados;
CREATE POLICY "Notificações isoladas por tenant" ON novos_produtos_notificados
  FOR ALL 
  USING (tenant_id = (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid);