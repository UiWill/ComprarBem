-- ============================================
-- DEBUG PASSO A PASSO - DESCOBRIR ERRO
-- Sistema Comprar Bem - Diagnóstico Detalhado
-- ============================================

-- EXECUTE UM COMANDO POR VEZ E PARE QUANDO DER ERRO!

-- COMANDO 1: Verificar estrutura atual
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'rdms_online' ORDER BY ordinal_position;

-- COMANDO 2: Remover views que podem estar causando problema
DROP VIEW IF EXISTS v_rdms_pendentes_feedback CASCADE;
DROP VIEW IF EXISTS v_estatisticas_lembretes CASCADE;

-- COMANDO 3: Remover funções que podem estar causando problema  
DROP FUNCTION IF EXISTS verificar_rdms_para_lembrete() CASCADE;
DROP FUNCTION IF EXISTS registrar_lembrete_enviado(UUID, UUID, UUID, TEXT, BOOLEAN, TEXT) CASCADE;

-- COMANDO 4: Remover tabelas antigas
DROP TABLE IF EXISTS lembretes_feedback CASCADE;
DROP TABLE IF EXISTS rdm_feedbacks CASCADE;

-- COMANDO 5: Criar tabela simples SEM foreign keys primeiro
CREATE TABLE rdm_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL,
    usuario_rdm_id UUID NOT NULL,
    material_nome TEXT NOT NULL,
    material_codigo TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comentario TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- COMANDO 6: Criar segunda tabela simples SEM foreign keys
CREATE TABLE lembretes_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    rdm_id UUID NOT NULL,
    usuario_rdm_id UUID NOT NULL,
    tipo_lembrete TEXT NOT NULL,
    email_enviado BOOLEAN DEFAULT false,
    data_envio TIMESTAMPTZ,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- COMANDO 7: Testar inserção básica
INSERT INTO rdm_feedbacks (tenant_id, rdm_id, usuario_rdm_id, material_nome, material_codigo, rating)
VALUES (
    'dcfe1030-27dd-4964-8e22-08a9c3fab790'::uuid,
    'd1289bf3-12b0-4fca-9245-990af88bb165'::uuid,
    '44341608-9422-41cf-8f82-a308c7ffbdb8'::uuid,
    'Teste',
    'TST001',
    5
);

-- COMANDO 8: Verificar se funcionou
SELECT * FROM rdm_feedbacks;

-- PARE AQUI SE DEU ERRO E ME INFORME EM QUAL COMANDO! 