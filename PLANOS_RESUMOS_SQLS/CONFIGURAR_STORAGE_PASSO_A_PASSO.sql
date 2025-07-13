-- CONFIGURAÇÃO DO STORAGE - EXECUTE PASSO A PASSO
-- Copie e cole cada comando individualmente no SQL Editor do Supabase

-- PASSO 1: Criar bucket minutas-padrao
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'minutas-padrao',
    'minutas-padrao',
    true,
    52428800,
    ARRAY['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
) ON CONFLICT (id) DO NOTHING;

-- PASSO 2: Criar bucket editais-arquivos  
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'editais-arquivos',
    'editais-arquivos',
    true,
    52428800,
    ARRAY['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- PASSO 3: Habilitar RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- PASSO 4: Policy de leitura para minutas-padrao
CREATE POLICY "Public read minutas" ON storage.objects FOR SELECT USING (bucket_id = 'minutas-padrao');

-- PASSO 5: Policy de upload para minutas-padrao
CREATE POLICY "Auth upload minutas" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'minutas-padrao' AND auth.role() = 'authenticated');

-- PASSO 6: Policy de leitura para editais-arquivos
CREATE POLICY "Public read editais" ON storage.objects FOR SELECT USING (bucket_id = 'editais-arquivos');

-- PASSO 7: Policy de upload para editais-arquivos
CREATE POLICY "Auth upload editais" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'editais-arquivos' AND auth.role() = 'authenticated');

-- PASSO 8: Verificar se funcionou
SELECT id, name, public FROM storage.buckets WHERE id IN ('minutas-padrao', 'editais-arquivos'); 