-- =====================================================
-- 🚀 CONFIGURAÇÃO AUTOMÁTICA DE CRON NO SUPABASE
-- =====================================================
-- Este script configura o sistema de notificações automáticas
-- utilizando pg_cron + Supabase Edge Functions

-- =====================================================
-- 1. ATIVAR EXTENSÃO PG_CRON
-- =====================================================

-- Verificar se pg_cron está disponível
SELECT * FROM pg_available_extensions WHERE name = 'pg_cron';

-- Ativar extensão pg_cron (se disponível)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- =====================================================
-- 2. CONFIGURAR JOBS DE CRON
-- =====================================================

-- Verificar jobs existentes
SELECT * FROM cron.job;

-- Limpar jobs antigos (se existirem)
DELETE FROM cron.job WHERE jobname LIKE '%notificacoes%';

-- =====================================================
-- 3. CRIAR JOB PRINCIPAL (A CADA 30 MINUTOS)
-- =====================================================

-- Job principal que executa a Edge Function
SELECT cron.schedule(
    'notificacoes-automaticas-30min',
    '*/30 * * * *', -- A cada 30 minutos
    $$
    SELECT
      net.http_post(
        url:='https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas',
        headers:=jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.jwt_secret', true)
        ),
        body:=jsonb_build_object(
          'trigger', 'cron_job',
          'timestamp', now()::text
        )
      ) as request_id;
    $$
);

-- =====================================================
-- 4. CRIAR JOB DE TESTE (A CADA 5 MINUTOS)
-- =====================================================

-- Job de teste que executa mais frequentemente
SELECT cron.schedule(
    'notificacoes-teste-5min',
    '*/5 * * * *', -- A cada 5 minutos
    $$
    SELECT
      net.http_post(
        url:='https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas',
        headers:=jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.jwt_secret', true)
        ),
        body:=jsonb_build_object(
          'trigger', 'cron_teste',
          'timestamp', now()::text,
          'debug', true
        )
      ) as request_id;
    $$
);

-- =====================================================
-- 5. CRIAR JOB DE LIMPEZA (DIÁRIO)
-- =====================================================

-- Job que limpa logs antigos uma vez por dia
SELECT cron.schedule(
    'limpeza-logs-diario',
    '0 2 * * *', -- Todo dia às 2h da manhã
    $$
    -- Limpar logs de emails antigos (mais de 30 dias)
    DELETE FROM emails_enviados 
    WHERE criado_em < NOW() - INTERVAL '30 days'
    AND status = 'enviado';
    
    -- Limpar logs de lembretes antigos (mais de 90 dias)
    DELETE FROM lembretes_enviados 
    WHERE criado_em < NOW() - INTERVAL '90 days'
    AND email_enviado = true;
    
    -- Log da limpeza
    INSERT INTO emails_enviados (
      tipo, destinatario, assunto, status, corpo
    ) VALUES (
      'sistema', 'sistema@interno.com', 
      'Limpeza automática de logs executada', 
      'enviado', 
      'Logs mais antigos foram removidos automaticamente'
    );
    $$
);

-- =====================================================
-- 6. VERIFICAR JOBS CRIADOS
-- =====================================================

-- Listar todos os jobs de cron
SELECT 
    jobid,
    schedule,
    command,
    nodename,
    nodeport,
    database,
    username,
    active,
    jobname
FROM cron.job 
WHERE jobname LIKE '%notificacoes%' OR jobname LIKE '%limpeza%'
ORDER BY jobname;

-- =====================================================
-- 7. FUNÇÃO PARA MONITORAR EXECUÇÕES
-- =====================================================

CREATE OR REPLACE FUNCTION monitorar_execucoes_cron()
RETURNS TABLE (
    execucao_id bigint,
    job_nome text,
    status text,
    inicio_execucao timestamp,
    fim_execucao timestamp,
    duracao interval,
    mensagem text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.runid,
        j.jobname,
        CASE 
            WHEN r.return_message IS NULL THEN 'sucesso'
            ELSE 'erro'
        END as status,
        r.start_time,
        r.end_time,
        r.end_time - r.start_time as duracao,
        COALESCE(r.return_message, 'Executado com sucesso') as mensagem
    FROM cron.job_run_details r
    JOIN cron.job j ON r.jobid = j.jobid
    WHERE j.jobname LIKE '%notificacoes%'
    ORDER BY r.start_time DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. FUNÇÃO PARA ATIVAR/DESATIVAR JOBS
-- =====================================================

CREATE OR REPLACE FUNCTION controlar_notificacoes_automaticas(
    p_acao text DEFAULT 'status' -- 'ativar', 'desativar', 'status'
) RETURNS jsonb AS $$
DECLARE
    resultado jsonb;
    job_record record;
BEGIN
    IF p_acao = 'ativar' THEN
        -- Ativar todos os jobs de notificações
        UPDATE cron.job 
        SET active = true 
        WHERE jobname LIKE '%notificacoes%';
        
        resultado = jsonb_build_object(
            'status', 'ativado',
            'mensagem', 'Notificações automáticas ativadas',
            'timestamp', now()
        );
        
    ELSIF p_acao = 'desativar' THEN
        -- Desativar todos os jobs de notificações
        UPDATE cron.job 
        SET active = false 
        WHERE jobname LIKE '%notificacoes%';
        
        resultado = jsonb_build_object(
            'status', 'desativado',
            'mensagem', 'Notificações automáticas desativadas',
            'timestamp', now()
        );
        
    ELSE
        -- Mostrar status atual
        SELECT jsonb_agg(
            jsonb_build_object(
                'job_name', jobname,
                'ativo', active,
                'agendamento', schedule,
                'proximo_execucao', (
                    SELECT start_time 
                    FROM cron.job_run_details 
                    WHERE jobid = j.jobid 
                    ORDER BY start_time DESC 
                    LIMIT 1
                ) + INTERVAL '30 minutes'
            )
        ) INTO resultado
        FROM cron.job j
        WHERE jobname LIKE '%notificacoes%';
        
        resultado = jsonb_build_object(
            'status', 'consultado',
            'jobs', resultado,
            'timestamp', now()
        );
    END IF;
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. EXECUTAR VERIFICAÇÃO INICIAL
-- =====================================================

-- Verificar se tudo foi criado corretamente
SELECT controlar_notificacoes_automaticas('status');

-- Mostrar últimas execuções
SELECT * FROM monitorar_execucoes_cron();

-- =====================================================
-- 10. INSTRUÇÕES DE USO
-- =====================================================

-- Para ativar notificações:
-- SELECT controlar_notificacoes_automaticas('ativar');

-- Para desativar notificações:
-- SELECT controlar_notificacoes_automaticas('desativar');

-- Para ver status:
-- SELECT controlar_notificacoes_automaticas('status');

-- Para ver últimas execuções:
-- SELECT * FROM monitorar_execucoes_cron();

-- Para executar manualmente (teste):
-- SELECT
--   net.http_post(
--     url:='https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas',
--     headers:=jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer ' || current_setting('app.jwt_secret', true)
--     ),
--     body:=jsonb_build_object(
--       'trigger', 'teste_manual',
--       'timestamp', now()::text
--     )
--   ) as request_id;

-- =====================================================
-- RESULTADO FINAL
-- =====================================================

SELECT 
    '✅ Sistema de notificações automáticas configurado!' as status,
    'Jobs de cron criados e ativados' as detalhes,
    'Edge Function será executada automaticamente' as funcionamento,
    NOW() as configurado_em;