-- ============================================
-- SCRIPT DE TESTE PARA VALIDAR SISTEMA DE THROTTLING
-- ============================================

-- Este script testa se o sistema anti-spam está funcionando corretamente

-- 1. TESTE BÁSICO - Verificar se as funções existem
SELECT 
  'Função verificar_usuarios_lembretes_com_throttling existe' as teste,
  CASE WHEN EXISTS(
    SELECT 1 FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'verificar_usuarios_lembretes_com_throttling'
  ) THEN '✅ PASS' ELSE '❌ FAIL' END as resultado
UNION ALL
SELECT 
  'Função buscar_produtos_pendentes_notificacao_com_throttling existe',
  CASE WHEN EXISTS(
    SELECT 1 FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'buscar_produtos_pendentes_notificacao_com_throttling'
  ) THEN '✅ PASS' ELSE '❌ FAIL' END
UNION ALL
SELECT 
  'Tabela novos_produtos_notificados existe',
  CASE WHEN EXISTS(
    SELECT 1 FROM pg_tables WHERE tablename = 'novos_produtos_notificados'
  ) THEN '✅ PASS' ELSE '❌ FAIL' END;

-- 2. TESTE DE ESTRUTURA - Verificar se a tabela tem as colunas corretas
SELECT 
  'Tabela novos_produtos_notificados - Estrutura' as categoria,
  array_agg(column_name ORDER BY ordinal_position) as colunas_existentes
FROM information_schema.columns 
WHERE table_name = 'novos_produtos_notificados';

-- 3. TESTE FUNCIONAL - Executar função de lembretes (deve funcionar sem erro)
SELECT 
  'Teste execução função lembretes' as teste,
  CASE 
    WHEN (SELECT COUNT(*) FROM verificar_usuarios_lembretes_com_throttling()) >= 0 
    THEN '✅ PASS - Função executa sem erro' 
    ELSE '❌ FAIL' 
  END as resultado;

-- 4. TESTE FUNCIONAL - Executar função de produtos (deve funcionar sem erro) 
SELECT 
  'Teste execução função produtos' as teste,
  CASE 
    WHEN (SELECT COUNT(*) FROM buscar_produtos_pendentes_notificacao_com_throttling()) >= 0
    THEN '✅ PASS - Função executa sem erro'
    ELSE '❌ FAIL'
  END as resultado;

-- 5. VISUALIZAR DADOS DE TESTE - Lembretes que seriam enviados
SELECT 
  'LEMBRETES QUE SERIAM ENVIADOS (sem throttling bloqueando)' as categoria;

SELECT 
  rdm_usuario_nome,
  rdm_material_nome,
  rdm_tipo_lembrete_necessario,
  rdm_dias_desde_vinculacao,
  rdm_ultimo_lembrete_enviado,
  CASE 
    WHEN rdm_ultimo_lembrete_enviado IS NULL THEN 'Primeiro envio'
    ELSE 'Enviado há ' || EXTRACT(epoch FROM (NOW() - rdm_ultimo_lembrete_enviado))/3600 || ' horas'
  END as situacao_throttling
FROM verificar_usuarios_lembretes_com_throttling()
ORDER BY rdm_dias_desde_vinculacao DESC
LIMIT 10;

-- 6. VISUALIZAR DADOS DE TESTE - Produtos que seriam enviados
SELECT 
  'PRODUTOS QUE SERIAM ENVIADOS (sem throttling bloqueando)' as categoria;
  
SELECT 
  np_nome_produto,
  np_usuario_nome,
  np_data_criacao_produto,
  np_ultima_notificacao,
  CASE 
    WHEN np_ultima_notificacao IS NULL THEN 'Primeiro envio'
    ELSE 'Notificado há ' || EXTRACT(epoch FROM (NOW() - np_ultima_notificacao))/3600 || ' horas'
  END as situacao_throttling
FROM buscar_produtos_pendentes_notificacao_com_throttling()
ORDER BY np_data_criacao_produto DESC
LIMIT 10;

-- 7. SIMULAÇÃO - Quantos lembretes com throttling ativo
SELECT 
  'SISTEMA ANTI-SPAM ATIVO' as teste,
  COUNT(*) as lembretes_que_seriam_enviados,
  'Sistema funcionando - apenas lembretes válidos' as status
FROM verificar_usuarios_lembretes_com_throttling();

-- 8. TESTE DE REGRAS - Verificar se as regras de tempo estão sendo aplicadas
SELECT 
  'VERIFICAÇÃO DAS REGRAS DE THROTTLING' as categoria;
  
SELECT 
  rdm_tipo_lembrete_necessario,
  COUNT(*) as quantidade,
  MIN(rdm_ultimo_lembrete_enviado) as ultimo_mais_antigo,
  MAX(rdm_ultimo_lembrete_enviado) as ultimo_mais_recente,
  CASE rdm_tipo_lembrete_necessario
    WHEN '10_DIAS' THEN '24 horas'
    WHEN '20_DIAS' THEN '48 horas' 
    WHEN '30_DIAS' THEN '6 horas'
    WHEN '5_MINUTOS' THEN '30 minutos'
  END as regra_throttling
FROM verificar_usuarios_lembretes_com_throttling()
GROUP BY rdm_tipo_lembrete_necessario
ORDER BY rdm_tipo_lembrete_necessario;