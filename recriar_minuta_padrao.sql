-- =====================================================
-- RECRIAR MINUTA PADRÃO DO SISTEMA
-- Para ser executado no Supabase SQL Editor
-- Tabela: minutas_padrao
-- =====================================================

-- Inserir minuta padrão na tabela 'minutas_padrao'
INSERT INTO minutas_padrao (
  id,
  nome,
  descricao,
  arquivo_nome,
  arquivo_url,
  tipo_arquivo,
  categoria,
  ativa,
  eh_padrao_sistema,
  criado_por,
  criado_em,
  atualizado_em
) VALUES (
  gen_random_uuid(),
  'Minuta Padrão - Chamamento Público para Pré-Qualificação',
  'Modelo padrão de edital para chamamento público de pré-qualificação de produtos conforme Lei nº 14.133/2021',
  'minuta_padrao_prequalificacao.docx',
  NULL, -- VOCÊ VAI COLOCAR A URL AQUI DEPOIS
  'docx',
  'prequalificacao',
  true,
  true,
  NULL,
  NOW(),
  NOW()
);

-- Verificar se foi inserido corretamente
SELECT 
  id,
  nome,
  descricao,
  arquivo_nome,
  arquivo_url,
  categoria,
  ativa,
  eh_padrao_sistema,
  criado_em
FROM minutas_padrao 
WHERE eh_padrao_sistema = true 
  AND nome LIKE '%Minuta Padrão%'
ORDER BY criado_em DESC;

-- =====================================================
-- INSTRUÇÕES:
-- =====================================================
-- 1. Execute o INSERT acima no Supabase SQL Editor
-- 2. Anote o ID gerado da nova minuta
-- 3. Faça upload do arquivo .docx para o storage
-- 4. Execute o UPDATE abaixo com a URL do arquivo:

/*
UPDATE minutas_padrao 
SET arquivo_url = 'SUA_URL_AQUI'
WHERE eh_padrao_sistema = true 
  AND nome = 'Minuta Padrão - Chamamento Público para Pré-Qualificação';
*/