-- LIMPEZA SEGURA RESPEITANDO FOREIGN KEYS
-- Remove dependências antes de limpar usuários

-- 1. VER DEPENDÊNCIAS ATUAIS
SELECT 'DEPENDENCIAS_ANALISES' as tipo, COUNT(*) as quantidade FROM analises;

-- 2. VER QUAIS USUÁRIOS TÊM ANÁLISES
SELECT 
    'USUARIOS_COM_ANALISES' as tipo,
    u.email,
    u.id,
    COUNT(a.id) as qtd_analises
FROM usuarios u
LEFT JOIN analises a ON u.id = a.avaliador_id
GROUP BY u.email, u.id
HAVING COUNT(a.id) > 0;

-- 3. REMOVER PRIMEIRO AS ANÁLISES (dependências)
DELETE FROM analises WHERE avaliador_id IS NOT NULL;

-- 4. VERIFICAR SE REMOVEU
SELECT 'ANALISES_APOS_LIMPEZA' as tipo, COUNT(*) as quantidade FROM analises;

-- 5. AGORA REMOVER USUÁRIOS (sem dependências)
DELETE FROM usuarios WHERE email LIKE '%@%';

-- 6. REMOVER TENANTS
DELETE FROM tenants WHERE nome IS NOT NULL;

-- 7. VERIFICAR RESULTADO FINAL
SELECT 'FINAL_USUARIOS' as tipo, COUNT(*) as quantidade FROM usuarios
UNION ALL
SELECT 'FINAL_TENANTS' as tipo, COUNT(*) as quantidade FROM tenants
UNION ALL
SELECT 'FINAL_ANALISES' as tipo, COUNT(*) as quantidade FROM analises;

SELECT 'LIMPEZA_CONCLUIDA' as status, 'Sistema limpo com Foreign Keys respeitadas' as mensagem;