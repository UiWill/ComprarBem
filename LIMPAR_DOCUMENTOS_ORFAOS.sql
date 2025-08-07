-- =====================================================
-- LIMPAR DOCUMENTOS ÓRFÃOS E CORRIGIR RELACIONAMENTO
-- =====================================================

-- 1. PRIMEIRO: Verificar documentos órfãos
SELECT 'DOCUMENTOS ÓRFÃOS ENCONTRADOS:' as status;
SELECT 
    dp.id, 
    dp.processo_id, 
    dp.nome_documento,
    dp.tipo_documento,
    dp.criado_em
FROM documentos_processo dp
LEFT JOIN processos_administrativos pa ON dp.processo_id = pa.id
WHERE pa.id IS NULL
ORDER BY dp.criado_em DESC;

-- 2. LIMPAR: Remover documentos órfãos
DELETE FROM documentos_processo 
WHERE id IN (
    SELECT dp.id
    FROM documentos_processo dp
    LEFT JOIN processos_administrativos pa ON dp.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- 3. Verificar quantos documentos foram removidos
SELECT 'Documentos órfãos removidos!' as status;

-- 4. Fazer o mesmo para tabela dfd_processo se existir
DELETE FROM dfd_processo 
WHERE id IN (
    SELECT dfd.id
    FROM dfd_processo dfd
    LEFT JOIN processos_administrativos pa ON dfd.processo_id = pa.id
    WHERE pa.id IS NULL
);

-- 5. AGORA: Criar foreign key
ALTER TABLE documentos_processo 
ADD CONSTRAINT fk_documentos_processo_processo_id 
FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;

-- 6. Criar foreign key para dfd_processo também
ALTER TABLE dfd_processo 
ADD CONSTRAINT fk_dfd_processo_processo_id 
FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;

-- 7. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_documentos_processo_processo_id ON documentos_processo(processo_id);
CREATE INDEX IF NOT EXISTS idx_dfd_processo_processo_id ON dfd_processo(processo_id);

-- 8. Verificação final
SELECT 'Verificação final - Documentos restantes:' as status;
SELECT 
    COUNT(*) as total_documentos,
    COUNT(DISTINCT processo_id) as processos_com_documentos
FROM documentos_processo;

SELECT 'Verificação final - DFDs restantes:' as status;
SELECT 
    COUNT(*) as total_dfds,
    COUNT(DISTINCT processo_id) as processos_com_dfd
FROM dfd_processo;

SELECT 'LIMPEZA E CORREÇÃO CONCLUÍDA! ✅' as resultado;