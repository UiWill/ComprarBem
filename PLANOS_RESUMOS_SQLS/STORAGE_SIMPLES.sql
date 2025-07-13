-- SCRIPT SIMPLES PARA STORAGE
-- Execute um comando por vez no SQL Editor do Supabase

-- 1. Criar bucket minutas-padrao
INSERT INTO storage.buckets (id, name, public) VALUES ('minutas-padrao', 'minutas-padrao', true) ON CONFLICT DO NOTHING;

-- 2. Criar bucket editais-arquivos
INSERT INTO storage.buckets (id, name, public) VALUES ('editais-arquivos', 'editais-arquivos', true) ON CONFLICT DO NOTHING;

-- 3. Verificar se funcionou
SELECT * FROM storage.buckets WHERE id IN ('minutas-padrao', 'editais-arquivos'); 