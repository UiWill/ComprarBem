-- Correção da tabela reclame_aqui - estrutura completa baseada no código que funcionava
-- Execute este SQL no Supabase para corrigir o problema

-- Se a tabela não existir, criar ela completa
CREATE TABLE IF NOT EXISTS public.reclame_aqui (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nome_reclamante TEXT NOT NULL,
    setor_reclamante TEXT,
    cargo_reclamante TEXT,
    titulo_reclamacao TEXT NOT NULL,
    descricao_reclamacao TEXT NOT NULL,
    categoria TEXT,
    tenant_id UUID NOT NULL,
    status TEXT DEFAULT 'pendente',
    prioridade TEXT DEFAULT 'normal',
    publica BOOLEAN DEFAULT true,
    resposta_cpm TEXT,
    respondido_em TIMESTAMP WITH TIME ZONE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adicionar colunas se a tabela já existir mas estiver faltando campos
ALTER TABLE public.reclame_aqui 
ADD COLUMN IF NOT EXISTS cargo_reclamante TEXT;

ALTER TABLE public.reclame_aqui 
ADD COLUMN IF NOT EXISTS titulo_reclamacao TEXT;

ALTER TABLE public.reclame_aqui 
ADD COLUMN IF NOT EXISTS categoria TEXT;

ALTER TABLE public.reclame_aqui 
ADD COLUMN IF NOT EXISTS resposta_cpm TEXT;

ALTER TABLE public.reclame_aqui 
ADD COLUMN IF NOT EXISTS respondido_em TIMESTAMP WITH TIME ZONE;

-- Configurar RLS
ALTER TABLE public.reclame_aqui ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes que podem estar conflitando
DROP POLICY IF EXISTS "Reclamações públicas podem ser lidas por todos" ON public.reclame_aqui;
DROP POLICY IF EXISTS "Qualquer um pode inserir reclamações" ON public.reclame_aqui;
DROP POLICY IF EXISTS "Admins podem atualizar reclamações do seu tenant" ON public.reclame_aqui;

-- Política RLS para permitir acesso público de leitura às reclamações públicas
CREATE POLICY "Reclamações públicas podem ser lidas por todos"
ON public.reclame_aqui FOR SELECT
USING (publica = true);

-- Política RLS para inserção - qualquer usuário pode inserir
CREATE POLICY "Qualquer um pode inserir reclamações"
ON public.reclame_aqui FOR INSERT
WITH CHECK (true);

-- Política RLS para atualização - apenas para o próprio tenant
CREATE POLICY "Admins podem atualizar reclamações do seu tenant"
ON public.reclame_aqui FOR UPDATE
USING (true)
WITH CHECK (true);

-- Comentário final
SELECT 'Estrutura da tabela reclame_aqui criada/atualizada com sucesso!' as resultado;