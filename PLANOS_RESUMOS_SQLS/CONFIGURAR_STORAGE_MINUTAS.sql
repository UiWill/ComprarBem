-- Script para configurar o Storage do Supabase para Minutas Padrão
-- Execute este script no SQL Editor do Supabase

-- 1. Criar bucket para minutas-padrao (se não existir)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'minutas-padrao',
    'minutas-padrao',
    true,
    52428800, -- 50MB
    ARRAY['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
) ON CONFLICT (id) DO NOTHING;

-- 2. Criar policies para o bucket minutas-padrao
-- Policy para SELECT (leitura pública)
CREATE POLICY "Leitura pública de minutas padrão"
ON storage.objects FOR SELECT
USING (bucket_id = 'minutas-padrao');

-- Policy para INSERT (upload por usuários autenticados)
CREATE POLICY "Upload de minutas padrão por usuários autenticados"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'minutas-padrao' 
    AND auth.role() = 'authenticated'
);

-- Policy para UPDATE (atualização por usuários autenticados)
CREATE POLICY "Atualização de minutas padrão por usuários autenticados"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'minutas-padrao' 
    AND auth.role() = 'authenticated'
);

-- Policy para DELETE (exclusão por usuários autenticados)
CREATE POLICY "Exclusão de minutas padrão por usuários autenticados"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'minutas-padrao' 
    AND auth.role() = 'authenticated'
);

-- 3. Habilitar RLS no bucket
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 4. Criar bucket para editais-arquivos (se não existir)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'editais-arquivos',
    'editais-arquivos',
    true,
    52428800, -- 50MB
    ARRAY['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- 5. Criar policies para o bucket editais-arquivos
-- Policy para SELECT (leitura pública)
CREATE POLICY "Leitura pública de arquivos de editais"
ON storage.objects FOR SELECT
USING (bucket_id = 'editais-arquivos');

-- Policy para INSERT (upload por usuários autenticados)
CREATE POLICY "Upload de arquivos de editais por usuários autenticados"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'editais-arquivos' 
    AND auth.role() = 'authenticated'
);

-- Policy para UPDATE (atualização por usuários autenticados)
CREATE POLICY "Atualização de arquivos de editais por usuários autenticados"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'editais-arquivos' 
    AND auth.role() = 'authenticated'
);

-- Policy para DELETE (exclusão por usuários autenticados)
CREATE POLICY "Exclusão de arquivos de editais por usuários autenticados"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'editais-arquivos' 
    AND auth.role() = 'authenticated'
); 