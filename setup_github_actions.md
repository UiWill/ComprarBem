# 🚀 CONFIGURAÇÃO GITHUB ACTIONS - Sistema Automático

Como o Supabase não permite pg_cron no plano gratuito, vamos usar **GitHub Actions** que é ainda melhor!

## ✅ VANTAGENS DO GITHUB ACTIONS

- **100% Gratuito** (2.000 minutos/mês)
- **Mais confiável** que pg_cron
- **Logs detalhados** de cada execução
- **Controle total** via interface GitHub
- **Execução manual** quando necessário
- **Sem limitações** de permissão

## 📋 PASSO 1: Configurar Secrets no GitHub

### 1.1 Acessar Settings do Repositório
1. Vá para: `https://github.com/seu-usuario/seu-repositorio/settings/secrets/actions`
2. Clique em "New repository secret"

### 1.2 Adicionar Service Role Key
```
Name: SUPABASE_SERVICE_ROLE_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDQ2ODkwNCwiZXhwIjoyMDYwMDQ0OTA0fQ.-U_GgvJQf4FymWIQ6tdj2KclhNZZ2RLQAE7NJzz226s
```

### 1.3 Adicionar Anon Key
```
Name: SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8
```

## 📋 PASSO 2: Fazer Deploy da Edge Function

### 2.1 Método Manual (Recomendado)
1. Acesse: `https://app.supabase.com/project/ruagsbbczuwgfflgcaol/functions`
2. Clique em "Create Function"
3. **Nome:** `notificacoes-automaticas`
4. **Código:** Cole o conteúdo do arquivo `supabase/functions/notificacoes-automaticas/index.ts`
5. Clique em "Deploy"

### 2.2 Testar a Edge Function
```bash
# Execute este comando para testar:
curl -X POST 'https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDQ2ODkwNCwiZXhwIjoyMDYwMDQ0OTA0fQ.-U_GgvJQf4FymWIQ6tdj2KclhNZZ2RLQAE7NJzz226s' \
  -d '{"trigger": "teste_manual"}'
```

## 📋 PASSO 3: Ativar GitHub Actions

### 3.1 Commit e Push
```bash
# Faça commit dos arquivos:
git add .github/workflows/notificacoes-automaticas.yml
git commit -m "Adicionar sistema automático GitHub Actions"
git push origin main
```

### 3.2 Verificar Workflow
1. Vá para: `https://github.com/seu-usuario/seu-repositorio/actions`
2. Você verá o workflow "Sistema de Notificações Automáticas"
3. Clique nele para ver detalhes

### 3.3 Execução Manual (Teste)
1. Na página de Actions, clique no workflow
2. Clique em "Run workflow"
3. Marque "debug" como true
4. Clique em "Run workflow"

## 📋 PASSO 4: Monitoramento

### 4.1 Ver Logs das Execuções
1. Acesse: `https://github.com/seu-usuario/seu-repositorio/actions`
2. Clique em uma execução
3. Clique em "processar-notificacoes"
4. Veja os logs detalhados

### 4.2 Verificar no Banco
```sql
-- Ver execuções do sistema automático
SELECT * FROM emails_enviados 
WHERE tipo = 'sistema_automatico' 
ORDER BY criado_em DESC;

-- Ver emails enviados nas últimas 24h
SELECT * FROM emails_enviados 
WHERE criado_em >= NOW() - INTERVAL '24 hours'
ORDER BY criado_em DESC;
```

## 📋 PASSO 5: Configurações Avançadas

### 5.1 Alterar Frequência
```yaml
# No arquivo .github/workflows/notificacoes-automaticas.yml
# Altere a linha:
- cron: '*/30 * * * *'  # A cada 30 minutos

# Para outros intervalos:
- cron: '*/15 * * * *'  # A cada 15 minutos
- cron: '0 */2 * * *'   # A cada 2 horas
- cron: '0 9,15 * * *'  # Às 9h e 15h todos os dias
```

### 5.2 Desativar Temporariamente
```yaml
# Comente a seção schedule:
# schedule:
#   - cron: '*/30 * * * *'
```

## 🎯 CRONOGRAMA PADRÃO

- **A cada 30 minutos**: Verifica novos produtos e lembretes
- **Execução manual**: Disponível a qualquer momento
- **Logs completos**: Armazenados por 90 dias

## 📊 ESTATÍSTICAS DISPONÍVEIS

Cada execução mostra:
- 📧 Total de emails enviados
- ❌ Total de erros
- 🎉 Novos produtos notificados
- 📋 Lembretes enviados
- ⏰ Timestamp da execução

## 🔧 TROUBLESHOOTING

### Workflow não executando?
1. Verifique se os secrets estão configurados
2. Verifique se a Edge Function foi deployada
3. Execute manualmente para testar

### Edge Function retornando erro?
1. Verifique os logs no dashboard Supabase
2. Teste a função manualmente
3. Verifique se as credenciais EmailJS estão corretas

### Emails não enviando?
1. Verifique se há usuários RDM com produtos pendentes
2. Verifique se o EmailJS está configurado corretamente
3. Verifique se as funções do banco estão funcionando

## 🎉 RESULTADO FINAL

Após configurar, você terá:

- ✅ **Sistema 100% automático**
- ✅ **Executa sem PC ligado**
- ✅ **Logs detalhados**
- ✅ **Gratuito para sempre**
- ✅ **Controle total**
- ✅ **Mais confiável que pg_cron**

O sistema executará automaticamente a cada 30 minutos e enviará todos os emails pendentes! 🚀