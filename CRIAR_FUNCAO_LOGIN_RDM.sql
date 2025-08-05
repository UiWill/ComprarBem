-- Função RPC para permitir login de usuários RDM sem contexto de autenticação
-- Contorna políticas RLS para permitir que usuários façam login

CREATE OR REPLACE FUNCTION buscar_usuario_rdm_login(p_email TEXT)
RETURNS TABLE(
  id UUID,
  user_id UUID,
  nome_usuario TEXT,
  email TEXT,
  senha_temporaria TEXT,
  unidade_setor TEXT,
  nome_coordenador TEXT,
  materiais JSONB,
  tenant_id UUID,
  ativo BOOLEAN,
  convite_enviado BOOLEAN,
  convite_aceito BOOLEAN,
  criado_em TIMESTAMP WITH TIME ZONE,
  atualizado_em TIMESTAMP WITH TIME ZONE,
  data_convite TIMESTAMP WITH TIME ZONE,
  telefone TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER -- Executa com privilégios do proprietário da função
AS $$
BEGIN
  -- Log para debug
  RAISE NOTICE 'Buscando usuário RDM com email: %', p_email;
  
  -- Retornar dados do usuário RDM ativo
  RETURN QUERY
  SELECT 
    u.id,
    u.user_id,
    u.nome_usuario,
    u.email,
    u.senha_temporaria,
    u.unidade_setor,
    u.nome_coordenador,
    u.materiais,
    u.tenant_id,
    u.ativo,
    u.convite_enviado,
    u.convite_aceito,
    u.criado_em,
    u.atualizado_em,
    u.data_convite,
    u.telefone
  FROM usuarios_rdm u
  WHERE u.email = p_email
    AND u.ativo = true
  LIMIT 1;
  
  -- Log de resultado
  IF NOT FOUND THEN
    RAISE NOTICE 'Nenhum usuário RDM encontrado para email: %', p_email;
  ELSE
    RAISE NOTICE 'Usuário RDM encontrado para email: %', p_email;
  END IF;
END;
$$;

-- Permitir acesso público à função
GRANT EXECUTE ON FUNCTION buscar_usuario_rdm_login(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION buscar_usuario_rdm_login(TEXT) TO authenticated;

-- Comentário
COMMENT ON FUNCTION buscar_usuario_rdm_login(TEXT) IS 'Função para autenticar usuários RDM contornando políticas RLS';

-- Verificar se a função foi criada
SELECT 
  'Função buscar_usuario_rdm_login criada com sucesso!' as status,
  proname as nome_funcao,
  proargnames as parametros
FROM pg_proc 
WHERE proname = 'buscar_usuario_rdm_login';