-- Remover políticas existentes e recriar
-- Execute este arquivo no SQL Editor do Supabase

-- Remover políticas existentes (se existirem)
DROP POLICY IF EXISTS "Permitir leitura pública de produtos aprovados" ON produtos;
DROP POLICY IF EXISTS "Permitir leitura pública de tenants ativos" ON tenants;
DROP POLICY IF EXISTS "Permitir leitura pública de categorias" ON categorias;
DROP POLICY IF EXISTS "Permitir leitura pública de reclamações" ON reclamacoes_usuarios;
DROP POLICY IF EXISTS "Permitir inserção pública de reclamações" ON reclamacoes_usuarios;
DROP POLICY IF EXISTS "Permitir leitura pública de marcas despadronizadas" ON marcas_despadronizadas;

-- Criar novas políticas
CREATE POLICY "Permitir leitura pública de produtos aprovados" ON produtos
FOR SELECT
TO public
USING (status = 'aprovado');

CREATE POLICY "Permitir leitura pública de tenants ativos" ON tenants
FOR SELECT
TO public
USING (ativo = true);

CREATE POLICY "Permitir leitura pública de categorias" ON categorias
FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir leitura pública de reclamações" ON reclamacoes_usuarios
FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir inserção pública de reclamações" ON reclamacoes_usuarios
FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir leitura pública de marcas despadronizadas" ON marcas_despadronizadas
FOR SELECT
TO public
USING (status_atual = 'ativa');