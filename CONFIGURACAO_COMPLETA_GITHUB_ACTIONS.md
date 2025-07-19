# 🚀 CONFIGURAÇÃO COMPLETA - Sistema Automático GitHub Actions

## 📋 DADOS DO SEU PROJETO SUPABASE

- **Project URL**: `https://ruagsbbczuwgfflgcaol.supabase.co`
- **Project ID**: `ruagsbbczuwgfflgcaol`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8`
- **Service Role Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDQ2ODkwNCwiZXhwIjoyMDYwMDQ0OTA0fQ.-U_GgvJQf4FymWIQ6tdj2KclhNZZ2RLQAE7NJzz226s`

---

## 🎯 PASSO 1: Configurar Secrets no GitHub

### 1.1 Acessar Settings do Repositório
1. Vá para o seu repositório no GitHub
2. Clique em **"Settings"** (na aba superior)
3. No menu lateral, clique em **"Secrets and variables"** → **"Actions"**
4. Clique em **"New repository secret"**

### 1.2 Adicionar PRIMEIRO Secret (Service Role Key)
```
Name: SUPABASE_SERVICE_ROLE_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDQ2ODkwNCwiZXhwIjoyMDYwMDQ0OTA0fQ.-U_GgvJQf4FymWIQ6tdj2KclhNZZ2RLQAE7NJzz226s
```

### 1.3 Adicionar SEGUNDO Secret (Anon Key)
```
Name: SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8
```

---

## 🎯 PASSO 2: Deploy da Edge Function no Supabase

### 2.1 Acessar Dashboard Supabase
1. Vá para: `https://app.supabase.com/project/ruagsbbczuwgfflgcaol/functions`
2. Clique em **"Create Function"**

### 2.2 Configurar a Função
```
Nome da Função: notificacoes-automaticas
```

### 2.3 Copiar o Código
Copie todo o conteúdo do arquivo: `supabase/functions/notificacoes-automaticas/index.ts`
Cole no editor de código do Supabase

### 2.4 Deploy
Clique em **"Deploy"**

### 2.5 Testar a Edge Function
Execute este comando no terminal para testar:
```bash
curl -X POST 'https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/dynamic-responder' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDQ2ODkwNCwiZXhwIjoyMDYwMDQ0OTA0fQ.-U_GgvJQf4FymWIQ6tdj2KclhNZZ2RLQAE7NJzz226s' \
  -d '{"trigger": "teste_manual"}'
```

---

## 🎯 PASSO 3: Ativar GitHub Actions

### 3.1 Fazer Commit dos Arquivos
```bash
git add .github/workflows/notificacoes-automaticas.yml
git commit -m "🚀 Adicionar sistema automático de notificações"
git push origin main
```

### 3.2 Verificar Workflow
1. Vá para: `https://github.com/seu-usuario/seu-repositorio/actions`
2. Você verá o workflow **"🚀 Sistema de Notificações Automáticas"**

### 3.3 Testar Execução Manual
1. Clique no workflow
2. Clique em **"Run workflow"**
3. Marque **"debug"** como `true`
4. Clique em **"Run workflow"**

---

## 🎯 PASSO 4: Monitoramento e Verificação

### 4.1 Ver Logs da Execução
1. Na página Actions, clique em uma execução
2. Clique em **"processar-notificacoes"**
3. Veja os logs detalhados

### 4.2 Verificar no Banco de Dados
Execute no SQL Editor do Supabase:
```sql
-- Ver execuções do sistema automático
SELECT * FROM emails_enviados 
WHERE tipo = 'sistema_automatico' 
ORDER BY criado_em DESC;

-- Ver emails enviados nas últimas 24h
SELECT * FROM emails_enviados 
WHERE criado_em >= NOW() - INTERVAL '24 hours'
ORDER BY criado_em DESC;

-- Ver lembretes enviados
SELECT * FROM lembretes_enviados 
WHERE criado_em >= NOW() - INTERVAL '24 hours'
ORDER BY criado_em DESC;
```

---

## 🎯 CRONOGRAMA DE EXECUÇÃO

- **A cada 30 minutos**: O sistema verifica automaticamente novos produtos e lembretes pendentes
- **24/7**: Funciona continuamente sem intervenção
- **Execução manual**: Disponível a qualquer momento via GitHub Actions

---

## 🎯 FUNCIONALIDADES IMPLEMENTADAS

### ✅ Notificações de Novos Produtos
- Email automático quando produto é adicionado ao usuário RDM
- Template HTML profissional
- Tracking no banco de dados

### ✅ Lembretes Escalonados
- **5 minutos**: Teste do sistema (opcional)
- **10 dias**: Primeiro lembrete amigável
- **20 dias**: Segundo lembrete importante
- **30 dias**: Lembrete urgente final

### ✅ Monitoramento Completo
- Logs detalhados no GitHub Actions
- Estatísticas de envio em tempo real
- Registros no banco de dados
- Controle de erros automático

---

## 🚨 TROUBLESHOOTING

### Se a Edge Function não funcionar:
1. Verifique se foi feito o deploy correto
2. Teste com o comando curl acima
3. Verifique os logs no dashboard Supabase

### Se o GitHub Actions não executar:
1. Verifique se os secrets foram configurados corretamente
2. Verifique se o workflow foi commitado
3. Execute manualmente para testar

### Se emails não estão sendo enviados:
1. Verifique se há usuários RDM com produtos pendentes
2. Verifique as credenciais do EmailJS
3. Verifique os logs da Edge Function

---

## 🎉 RESULTADO FINAL

Após seguir todos os passos, você terá:

- ✅ **Sistema 100% automático** executando a cada 30 minutos
- ✅ **Sem necessidade de PC ligado** ou servidor
- ✅ **Gratuito para sempre** (GitHub Actions + Supabase)
- ✅ **Logs e monitoramento completos**
- ✅ **Controle total** via GitHub e Supabase
- ✅ **Emails profissionais** com templates HTML

O sistema funcionará **automaticamente 24/7** e enviará todas as notificações necessárias! 🚀