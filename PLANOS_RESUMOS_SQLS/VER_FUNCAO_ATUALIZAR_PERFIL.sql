-- VER A FUNÇÃO QUE ESTÁ DANDO ERRO
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'atualizar_perfil_usuario';