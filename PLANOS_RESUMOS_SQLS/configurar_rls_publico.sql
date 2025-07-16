-- Configuração de políticas RLS para permitir acesso público ao catálogo
-- Execute estes comandos no SQL Editor do Supabase

-- 1. Política para permitir leitura pública de produtos aprovados
CREATE POLICY "Permitir leitura pública de produtos aprovados" ON produtos
FOR SELECT
TO public
USING (status = 'aprovado');

-- 2. Política para permitir leitura pública de tenants ativos
CREATE POLICY "Permitir leitura pública de tenants ativos" ON tenants
FOR SELECT
TO public
USING (ativo = true);

-- 3. Política para permitir leitura pública de categorias
CREATE POLICY "Permitir leitura pública de categorias" ON categorias
FOR SELECT
TO public
USING (true);

-- 4. Política para permitir leitura pública de reclamações (para mostrar avaliações)
CREATE POLICY "Permitir leitura pública de reclamações" ON reclamacoes_usuarios
FOR SELECT
TO public
USING (true);

-- 5. Permitir inserção pública de reclamações (para permitir que usuários não logados avaliem)
CREATE POLICY "Permitir inserção pública de reclamações" ON reclamacoes_usuarios
FOR INSERT
TO public
WITH CHECK (true);

-- 6. Política para permitir leitura pública de marcas despadronizadas (para mostrar status correto)
CREATE POLICY "Permitir leitura pública de marcas despadronizadas" ON marcas_despadronizadas
FOR SELECT
TO public
USING (status_atual = 'ativa');

-- Comandos para verificar se as políticas foram criadas corretamente:
-- SELECT * FROM pg_policies WHERE tablename IN ('produtos', 'tenants', 'categorias', 'reclamacoes_usuarios', 'marcas_despadronizadas');