-- CONFIGURAÇÃO PARA DESABILITAR CONFIRMAÇÃO DE EMAIL
-- IMPORTANTE: Execute via painel do Supabase OU peça para administrador

-- No painel do Supabase:
-- 1. Vá em "Authentication" > "Settings"
-- 2. Em "User Signups" > "Enable email confirmations" = OFF
-- 3. Salvar

-- OU execute estas configurações via SQL (se tiver permissão de admin):

-- Atualizar configuração para não requerer confirmação
-- UPDATE auth.config 
-- SET 
--     confirmation_required = false,
--     email_confirm_required = false
-- WHERE key = 'email_settings';

-- Para usuários já criados, confirmar automaticamente:
UPDATE auth.users 
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
WHERE email_confirmed_at IS NULL;

SELECT 'CONFIGURACAO_APLICADA' as status, 'Emails confirmados automaticamente' as mensagem;