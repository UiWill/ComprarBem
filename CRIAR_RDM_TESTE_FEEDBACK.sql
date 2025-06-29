-- Criar RDM de teste para William Martins testar o sistema de Feedback
-- Execute este SQL no Supabase para criar uma RDM aprovada

-- Inserir RDM de teste com status APROVADO
INSERT INTO rdms_online (
  tenant_id,
  usuario_rdm_id,
  material_nome,
  material_codigo,
  quantidade,
  unidade_medida,
  urgencia,
  justificativa,
  status,
  criado_em,
  atualizado_em
) VALUES (
  -- Pegar o tenant_id do William Martins
  (SELECT tenant_id FROM usuarios_rdm WHERE email = 'devwilliamemanoel7@gmail.com'),
  
  -- Pegar o ID do William Martins
  (SELECT id FROM usuarios_rdm WHERE email = 'devwilliamemanoel7@gmail.com'),
  
  'Caneta Esferográfica Azul',
  'CAN001',
  50,
  'UN',
  'NORMAL',
  'Necessário para atividades administrativas do setor de saúde.',
  'APROVADO',
  NOW() - INTERVAL '3 days',  -- Criado há 3 dias
  NOW() - INTERVAL '1 day'    -- Aprovado há 1 dia
);

-- Inserir mais uma RDM de teste
INSERT INTO rdms_online (
  tenant_id,
  usuario_rdm_id,
  material_nome,
  material_codigo,
  quantidade,
  unidade_medida,
  urgencia,
  justificativa,
  status,
  criado_em,
  atualizado_em
) VALUES (
  (SELECT tenant_id FROM usuarios_rdm WHERE email = 'devwilliamemanoel7@gmail.com'),
  (SELECT id FROM usuarios_rdm WHERE email = 'devwilliamemanoel7@gmail.com'),
  'Papel A4 Sulfite',
  'PAP002',
  10,
  'CX',
  'ALTA',
  'Impressão de documentos importantes para atendimento aos pacientes.',
  'APROVADO',
  NOW() - INTERVAL '5 days',
  NOW() - INTERVAL '2 days'
);

-- Verificar as RDMs criadas
SELECT 
  id,
  material_nome,
  material_codigo,
  quantidade,
  unidade_medida,
  status,
  criado_em,
  atualizado_em
FROM rdms_online 
WHERE usuario_rdm_id = (
  SELECT id FROM usuarios_rdm WHERE email = 'devwilliamemanoel7@gmail.com'
)
ORDER BY criado_em DESC;

-- INSTRUÇÕES:
-- 1. Execute este SQL no Supabase Dashboard > SQL Editor
-- 2. Isso criará 2 RDMs aprovadas para o William Martins
-- 3. Agora ele poderá testar a aba "⭐ Feedback" no sistema
-- 4. As RDMs aparecerão para avaliação quando ele clicar na aba Feedback 