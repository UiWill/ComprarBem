# 🚀 INSTRUÇÕES PARA DEPLOY DO SISTEMA AUTOMÁTICO

Este guia mostra como implementar o sistema de notificações **completamente automático** usando Supabase Edge Functions + pg_cron.

## 📋 PASSO 1: Deploy da Edge Function

### 1.1 Fazer Login no Supabase
```bash
# Vá para: https://app.supabase.com/
# Faça login na sua conta
# Acesse seu projeto: https://app.supabase.com/project/ruagsbbczuwgfflgcaol
```

### 1.2 Obter Token de Acesso
```bash
# No dashboard do Supabase:
# 1. Vá em "Settings" → "API"
# 2. Copie o "Service Role Key" (secret)
# 3. Anote a "Project URL"
```

### 1.3 Deploy via CLI (Método Recomendado)
```bash
# Definir variáveis de ambiente
set SUPABASE_ACCESS_TOKEN=seu_token_aqui
set SUPABASE_PROJECT_REF=ruagsbbczuwgfflgcaol

# Fazer deploy da função
npx supabase functions deploy notificacoes-automaticas --project-ref ruagsbbczuwgfflgcaol

# Ou fazer deploy local para teste
npx supabase functions serve notificacoes-automaticas
```

### 1.4 Deploy via Dashboard (Método Manual)
```bash
# Se o CLI não funcionar:
# 1. Vá em "Edge Functions" no dashboard
# 2. Clique em "Create Function"
# 3. Nome: "notificacoes-automaticas"
# 4. Cole o código do arquivo: supabase/functions/notificacoes-automaticas/index.ts
# 5. Clique em "Deploy"
```

## 📋 PASSO 2: Configurar pg_cron no Supabase

### 2.1 Acessar SQL Editor
```bash
# No dashboard do Supabase:
# 1. Vá em "SQL Editor"
# 2. Clique em "New Query"
# 3. Cole o conteúdo do arquivo: setup_cron_automatico.sql
# 4. Clique em "Run"
```

### 2.2 Verificar se pg_cron está Disponível
```sql
-- Execute primeiro para verificar disponibilidade
SELECT * FROM pg_available_extensions WHERE name = 'pg_cron';
```

### 2.3 Ativar Extensão (se disponível)
```sql
-- Se pg_cron estiver na lista, execute:
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

### 2.4 Configurar Jobs de Cron
```sql
-- Execute o resto do script setup_cron_automatico.sql
-- Isso vai criar 3 jobs:
-- 1. Notificações a cada 30 minutos
-- 2. Teste a cada 5 minutos
-- 3. Limpeza diária de logs
```

## 📋 PASSO 3: Configurar Variáveis de Ambiente

### 3.1 No Dashboard Supabase
```bash
# Vá em "Settings" → "Edge Functions"
# Adicione as seguintes variáveis:
SUPABASE_URL=https://ruagsbbczuwgfflgcaol.supabase.co
SUPABASE_SERVICE_ROLE_KEY=seu_service_role_key_aqui
```

## 📋 PASSO 4: Testar o Sistema

### 4.1 Teste Manual da Edge Function
```bash
# Execute no SQL Editor:
SELECT
  net.http_post(
    url:='https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas',
    headers:=jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.jwt_secret', true)
    ),
    body:=jsonb_build_object(
      'trigger', 'teste_manual',
      'timestamp', now()::text
    )
  ) as request_id;
```

### 4.2 Verificar Jobs de Cron
```sql
-- Ver jobs criados
SELECT * FROM cron.job WHERE jobname LIKE '%notificacoes%';

-- Ver últimas execuções
SELECT * FROM monitorar_execucoes_cron();

-- Ver status do sistema
SELECT controlar_notificacoes_automaticas('status');
```

### 4.3 Controlar Sistema
```sql
-- Ativar notificações
SELECT controlar_notificacoes_automaticas('ativar');

-- Desativar notificações
SELECT controlar_notificacoes_automaticas('desativar');

-- Ver status atual
SELECT controlar_notificacoes_automaticas('status');
```

## 📋 PASSO 5: Monitoramento

### 5.1 Logs da Edge Function
```bash
# No dashboard: "Edge Functions" → "notificacoes-automaticas" → "Logs"
# Aqui você verá todas as execuções e possíveis erros
```

### 5.2 Logs do Banco
```sql
-- Ver emails enviados recentemente
SELECT * FROM emails_enviados 
WHERE criado_em >= NOW() - INTERVAL '24 hours'
ORDER BY criado_em DESC;

-- Ver lembretes enviados recentemente
SELECT * FROM lembretes_enviados 
WHERE criado_em >= NOW() - INTERVAL '24 hours'
ORDER BY criado_em DESC;
```

### 5.3 Métricas do Sistema
```sql
-- Estatísticas gerais
SELECT 
    COUNT(*) as total_emails,
    COUNT(CASE WHEN status = 'enviado' THEN 1 END) as enviados,
    COUNT(CASE WHEN status = 'erro' THEN 1 END) as erros,
    MAX(criado_em) as ultimo_envio
FROM emails_enviados 
WHERE criado_em >= NOW() - INTERVAL '24 hours';
```

## 🎯 CRONOGRAMA DE EXECUÇÃO

- **A cada 5 minutos**: Teste (apenas para verificar funcionamento)
- **A cada 30 minutos**: Processamento principal de notificações
- **Todo dia às 2h**: Limpeza de logs antigos

## ⚠️ PROBLEMAS COMUNS

### pg_cron não disponível
```sql
-- Se pg_cron não estiver disponível, use esta alternativa:
-- Crie um workflow GitHub Actions ou use Vercel Cron
```

### Edge Function não deploying
```bash
# Tente fazer deploy manualmente via dashboard
# Ou use o método curl:
curl -X POST 'https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas' \
  -H 'Authorization: Bearer [SERVICE_ROLE_KEY]' \
  -H 'Content-Type: application/json' \
  -d '{"trigger": "teste_manual"}'
```

### Emails não enviando
```sql
-- Verifique se as credenciais do EmailJS estão corretas
-- Verifique se os usuários RDM têm emails válidos
-- Verifique se as funções do banco estão funcionando
```

## 🎉 RESULTADO FINAL

Após seguir todos os passos, você terá:

- ✅ **Sistema completamente automático**
- ✅ **Executa sem intervenção humana**
- ✅ **Não precisa de servidor rodando**
- ✅ **Logs e monitoramento completos**
- ✅ **Controle total via SQL**

## 📞 SUPORTE

Se tiver problemas:

1. Verifique os logs da Edge Function
2. Execute as consultas de monitoramento
3. Teste a função manualmente
4. Verifique se pg_cron está ativo

O sistema está pronto para funcionar **24/7 automaticamente**! 🚀