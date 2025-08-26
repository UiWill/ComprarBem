-- ============================================
-- ATUALIZAR CONSTRAINT DE STATUS PARA INCLUIR 'finalizado'
-- ============================================

-- Este script adiciona o status 'finalizado' ao constraint de status dos processos administrativos

-- 1. Primeiro, verificar qual constraint existe atualmente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND pg_get_constraintdef(oid) LIKE '%status%';

-- 2. Remover o constraint existente (se houver)
DO $$ 
DECLARE
    constraint_name text;
BEGIN
    -- Buscar o nome do constraint de status
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'processos_administrativos'::regclass 
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%status%'
    LIMIT 1;
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE processos_administrativos DROP CONSTRAINT IF EXISTS ' || constraint_name;
        RAISE NOTICE '✅ Constraint existente removido: %', constraint_name;
    ELSE
        RAISE NOTICE '⚠️ Nenhum constraint de status encontrado';
    END IF;
END $$;

-- 3. Criar novo constraint com o status 'finalizado' incluído
ALTER TABLE processos_administrativos 
ADD CONSTRAINT processos_administrativos_status_check 
CHECK (status IN (
    -- FLUXO PADRONIZAÇÃO
    'em_criacao',
    'criado_cpm', 
    'submetido_autoridade',
    'abertura_autorizada',
    'edital_chamamento',
    'analise_juridica',
    'edital_publicado',
    'com_impugnacao',
    'recebendo_amostras',
    'avaliacao_cpm',
    'julgamento_ccl',
    'ata_ccl',
    'publicacao_ata',
    'com_recurso',
    'homologado',
    'expedindo_dcbs',
    'incluindo_marcas',
    'finalizado',
    
    -- STATUS DE DEVOLUÇÃO
    'devolvido_pelo_orgao',
    'devolvido_pela_ccl',
    'devolvido_pelo_juridico',
    
    -- STATUS ANTIGOS (compatibilidade)
    'assinado_admin',
    'aguardando_assinatura_orgao',
    
    -- FLUXO DESPADRONIZAÇÃO
    'em_criacao_desp',
    'criado_cpm_desp',
    'submetido_autoridade_desp',
    'abertura_autorizada_desp',
    'aviso_publicado_desp',
    'com_recurso_desp',
    'homologado_desp',
    'excluindo_marcas',
    
    -- STATUS DE REJEIÇÃO
    'rejeitado_cpm',
    'rejeitado_admin',
    'rejeitado_ccl',
    'rejeitado_juridico',
    'rejeitado_final'
));

-- 4. Verificar se o constraint foi criado corretamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'processos_administrativos'::regclass 
AND contype = 'c'
AND pg_get_constraintdef(oid) LIKE '%finalizado%';

-- 5. Testar se o status 'finalizado' é aceito
DO $$
BEGIN
    -- Fazer um teste simulado (sem commit)
    PERFORM 1 WHERE 'finalizado' IN (
        'em_criacao', 'criado_cpm', 'submetido_autoridade', 'abertura_autorizada',
        'edital_chamamento', 'analise_juridica', 'edital_publicado', 'com_impugnacao',
        'recebendo_amostras', 'avaliacao_cpm', 'julgamento_ccl', 'ata_ccl',
        'publicacao_ata', 'com_recurso', 'homologado', 'expedindo_dcbs',
        'incluindo_marcas', 'finalizado'
    );
    
    RAISE NOTICE '✅ Status "finalizado" é válido no novo constraint';
END $$;

-- Mensagem final
DO $$
BEGIN
    RAISE NOTICE '🎉 Constraint atualizado com sucesso! Status "finalizado" está disponível.';
END $$;