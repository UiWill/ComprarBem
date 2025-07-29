-- Script de teste para inserir um recurso manualmente
-- Execute este script para testar se a tabela recursos está funcionando

-- Primeiro, verificar se podemos acessar a tabela
SELECT 'TESTE DE ACESSO À TABELA' as status, count(*) as registros_existentes FROM recursos;

-- Testar inserção de um recurso de teste (sem as colunas que podem não existir)
INSERT INTO recursos (
    tenant_id, 
    ata_referencia, 
    produto_nome, 
    recorrente, 
    data_recurso,
    prazo_final, 
    fundamentacao,
    status
) VALUES (
    gen_random_uuid(), 
    'ATA-TESTE-001/2025', 
    'Produto Teste - Protocolo Manual', 
    'Empresa Teste Ltda', 
    NOW(),
    NOW() + INTERVAL '3 days',
    'Fundamentação teste: Questionamento sobre decisão da CCL conforme Lei 14.133/2021',
    'EM ANÁLISE'
);

-- Verificar se a inserção funcionou
SELECT 
    'RECURSO INSERIDO COM SUCESSO' as status,
    id,
    recorrente,
    produto_nome,
    ata_referencia,
    status,
    criado_em
FROM recursos 
WHERE recorrente = 'Empresa Teste Ltda'
ORDER BY criado_em DESC 
LIMIT 1;

-- Mostrar todos os recursos para verificação
SELECT 
    'TODOS OS RECURSOS' as status,
    id,
    recorrente,
    produto_nome,
    status,
    criado_em
FROM recursos 
ORDER BY criado_em DESC;