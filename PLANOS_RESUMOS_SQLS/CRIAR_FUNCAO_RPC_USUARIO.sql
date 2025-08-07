-- CRIAR FUNÇÃO RPC PARA INSERÇÃO PRIVILEGIADA DE USUÁRIOS
-- Esta função ignora RLS para permitir criação durante registro

CREATE OR REPLACE FUNCTION inserir_usuario_sistema(
    p_id UUID,
    p_email TEXT,
    p_nome TEXT,
    p_tipo TEXT,
    p_perfil_usuario TEXT,
    p_tenant_id UUID,
    p_ativo BOOLEAN DEFAULT true
)
RETURNS TABLE(
    id UUID,
    email TEXT,
    nome TEXT,
    tipo TEXT,
    perfil_usuario TEXT,
    tenant_id UUID,
    ativo BOOLEAN,
    criado_em TIMESTAMPTZ
)
SECURITY DEFINER -- Roda com privilégios do criador da função
LANGUAGE plpgsql
AS $$
DECLARE
    usuario_criado RECORD;
BEGIN
    -- Inserir usuário ignorando RLS policies
    INSERT INTO usuarios (
        id,
        email,
        nome,
        tipo,
        perfil_usuario,
        tenant_id,
        ativo,
        criado_em
    ) VALUES (
        p_id,
        p_email,
        p_nome,
        p_tipo,
        p_perfil_usuario,
        p_tenant_id,
        p_ativo,
        NOW()
    ) RETURNING * INTO usuario_criado;
    
    -- Retornar o usuário criado
    RETURN QUERY SELECT 
        usuario_criado.id,
        usuario_criado.email,
        usuario_criado.nome,
        usuario_criado.tipo,
        usuario_criado.perfil_usuario,
        usuario_criado.tenant_id,
        usuario_criado.ativo,
        usuario_criado.criado_em;
END;
$$;

-- Dar permissões para uso público
GRANT EXECUTE ON FUNCTION inserir_usuario_sistema TO PUBLIC;

-- Testar a função
SELECT 'FUNCAO_CRIADA' as status, 'inserir_usuario_sistema disponível' as mensagem;