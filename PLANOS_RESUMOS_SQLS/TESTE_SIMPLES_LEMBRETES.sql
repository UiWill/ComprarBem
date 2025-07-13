-- ============================================
-- TESTE SIMPLES PARA IDENTIFICAR PROBLEMA
-- Sistema Comprar Bem - Debug
-- ============================================

-- PASSO 1: Verificar se conseguimos criar uma tabela simples
CREATE TABLE IF NOT EXISTS teste_rdm_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL,
    usuario_rdm_id UUID NOT NULL,
    material_nome TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- PASSO 2: Testar inserção simples
INSERT INTO teste_rdm_feedbacks (tenant_id, rdm_id, usuario_rdm_id, material_nome, rating)
VALUES (
    'dcfe1030-27dd-4964-8e22-08a9c3fab790',
    'd1289bf3-12b0-4fca-9245-990af88bb165',
    '44341608-9422-41cf-8f82-a308c7ffbdb8',
    'Teste Material',
    5
);

-- PASSO 3: Verificar se consegue ler
SELECT * FROM teste_rdm_feedbacks;

-- PASSO 4: Limpar teste
DROP TABLE teste_rdm_feedbacks; 