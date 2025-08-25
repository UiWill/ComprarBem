-- ============================================
-- FUNÇÃO PARA VERIFICAR LEMBRETES COM SISTEMA ANTI-SPAM
-- ============================================

-- Esta função implementa um sistema de throttling que evita envio excessivo de emails
-- Regras de throttling:
-- - 10 DIAS: Só envia se não enviou nas últimas 24 horas
-- - 20 DIAS: Só envia se não enviou nas últimas 48 horas  
-- - 30 DIAS: Só envia se não enviou nas últimas 6 horas (mais urgente)

-- Remover função existente se houver
DROP FUNCTION IF EXISTS verificar_usuarios_lembretes_com_throttling();

CREATE OR REPLACE FUNCTION verificar_usuarios_lembretes_com_throttling()
RETURNS TABLE (
  rdm_usuario_id uuid,
  rdm_produto_id uuid,
  rdm_tenant_id uuid,
  rdm_usuario_email text,
  rdm_usuario_nome text,
  rdm_material_nome text,
  rdm_material_codigo text,
  rdm_unidade_setor text,
  rdm_dias_desde_vinculacao integer,
  rdm_tipo_lembrete_necessario text,
  rdm_ultimo_lembrete_enviado timestamptz
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rdm.usuario_rdm_id::uuid,
    rdm.produto_id::uuid,
    rdm.tenant_id::uuid,
    rdm.usuario_email::text,
    rdm.usuario_nome::text,
    rdm.material_nome::text,
    rdm.material_codigo::text,
    rdm.unidade_setor::text,
    rdm.dias_desde_vinculacao::integer,
    rdm.tipo_lembrete_necessario::text,
    le.ultimo_envio::timestamptz
  FROM (
    -- Subquery com todos os lembretes necessários
    SELECT 
      urdm.id as usuario_rdm_id,
      p.id as produto_id,
      urdm.tenant_id,
      urdm.email as usuario_email,
      urdm.nome_usuario as usuario_nome,
      p.nome as material_nome,
      p.codigo_material as material_codigo,
      urdm.unidade_setor,
      DATE_PART('day', NOW() - (material_item->>'data_vinculacao')::timestamptz)::integer as dias_desde_vinculacao,
      
      -- Determinar tipo de lembrete necessário
      CASE 
        WHEN DATE_PART('day', NOW() - (material_item->>'data_vinculacao')::timestamptz) >= 30 THEN '30_DIAS'
        WHEN DATE_PART('day', NOW() - (material_item->>'data_vinculacao')::timestamptz) >= 20 THEN '20_DIAS'  
        WHEN DATE_PART('day', NOW() - (material_item->>'data_vinculacao')::timestamptz) >= 10 THEN '10_DIAS'
        WHEN DATE_PART('minute', NOW() - (material_item->>'data_vinculacao')::timestamptz) >= 5 THEN '5_MINUTOS'
        ELSE NULL
      END as tipo_lembrete_necessario

    FROM usuarios_rdm urdm
    CROSS JOIN LATERAL jsonb_array_elements(urdm.materiais) as material_item
    JOIN produtos p ON p.id = (material_item->>'produto_id')::uuid
    WHERE 
      urdm.ativo = true
      AND urdm.convite_aceito = true
      AND material_item->>'data_vinculacao' IS NOT NULL
      AND (material_item->>'avaliacao_enviada')::boolean = false
      -- Só produtos que precisam de lembrete
      AND (
        DATE_PART('day', NOW() - (material_item->>'data_vinculacao')::timestamptz) >= 10 OR
        DATE_PART('minute', NOW() - (material_item->>'data_vinculacao')::timestamptz) >= 5
      )
  ) rdm
  
  -- LEFT JOIN para verificar último lembrete enviado
  LEFT JOIN (
    SELECT 
      usuario_rdm_id,
      produto_id,
      tipo_lembrete,
      MAX(criado_em) as ultimo_envio
    FROM lembretes_enviados 
    WHERE email_enviado = true
    GROUP BY usuario_rdm_id, produto_id, tipo_lembrete
  ) le ON rdm.usuario_rdm_id = le.usuario_rdm_id 
    AND rdm.produto_id = le.produto_id 
    AND rdm.tipo_lembrete_necessario = le.tipo_lembrete

  WHERE 
    rdm.tipo_lembrete_necessario IS NOT NULL
    AND (
      -- Aplicar regras de throttling baseadas no tipo de lembrete
      CASE rdm.tipo_lembrete_necessario
        -- 5_MINUTOS: Só para testes, sem throttling
        WHEN '5_MINUTOS' THEN (
          le.ultimo_envio IS NULL OR 
          le.ultimo_envio < NOW() - INTERVAL '30 minutes'
        )
        
        -- 10_DIAS: Throttling de 24 horas
        WHEN '10_DIAS' THEN (
          le.ultimo_envio IS NULL OR 
          le.ultimo_envio < NOW() - INTERVAL '24 hours'
        )
        
        -- 20_DIAS: Throttling de 48 horas 
        WHEN '20_DIAS' THEN (
          le.ultimo_envio IS NULL OR 
          le.ultimo_envio < NOW() - INTERVAL '48 hours'
        )
        
        -- 30_DIAS: Throttling de 6 horas (mais urgente)
        WHEN '30_DIAS' THEN (
          le.ultimo_envio IS NULL OR 
          le.ultimo_envio < NOW() - INTERVAL '6 hours'
        )
        
        ELSE false
      END
    )
  
  ORDER BY rdm.dias_desde_vinculacao DESC, rdm.tipo_lembrete_necessario DESC;
  
END;
$$;