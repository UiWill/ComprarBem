# 📧 CONFIGURAÇÃO DO SISTEMA DE EMAILS - DILIGÊNCIAS

## 📋 **VISÃO GERAL**

Para que o sistema de diligências funcione completamente, é necessário configurar o envio de emails para notificar os fornecedores. Este documento explica todas as etapas necessárias.

---

## 🎯 **IMPLEMENTAÇÕES REALIZADAS**

### ✅ **1. Campo de Email no Cadastro**
- ✅ Adicionado campo **"Email do Fornecedor"** no cadastro de produtos
- ✅ Campo obrigatório para garantir comunicação
- ✅ Validação de formato de email

### ✅ **2. Sistema de Envio de Emails**
- ✅ Serviço `emailService.js` criado
- ✅ Template HTML profissional para diligências
- ✅ Integração com Supabase para logs
- ✅ Suporte a múltiplos provedores (SendGrid, Mailgun, SMTP)

### ✅ **3. Integração com Diligências**
- ✅ Envio automático ao solicitar diligência
- ✅ Verificação de email antes do envio
- ✅ Feedback ao usuário sobre status do envio
- ✅ Logs de todos os emails enviados

---

## 🔧 **CONFIGURAÇÃO NECESSÁRIA**

### **PASSO 1: Executar SQL no Supabase**

```sql
-- 1. Adicionar campo email na tabela produtos
-- Execute: SQL_ADICIONAR_EMAIL_FORNECEDOR.sql

-- 2. Criar tabela de logs de emails
-- Execute: SQL_EMAILS_SISTEMA.sql
```

### **PASSO 2: Configurar Variáveis de Ambiente**

Crie/edite o arquivo `.env` na raiz do projeto:

```env
# 📧 CONFIGURAÇÕES DE EMAIL
VUE_APP_EMAIL_PROVIDER=sendgrid  # ou 'mailgun' ou 'smtp'

# SendGrid (Recomendado)
VUE_APP_SENDGRID_API_KEY=your_sendgrid_api_key_here

# Mailgun (Alternativa)
VUE_APP_MAILGUN_API_KEY=your_mailgun_api_key_here
VUE_APP_MAILGUN_DOMAIN=your_domain.com

# SMTP Genérico (Qualquer provedor)
VUE_APP_SMTP_HOST=smtp.gmail.com
VUE_APP_SMTP_PORT=587
VUE_APP_SMTP_SECURE=true
VUE_APP_SMTP_USER=your_email@gmail.com
VUE_APP_SMTP_PASS=your_app_password
```

### **PASSO 3: Configurar Dados da Organização**

Edite o arquivo `src/config/emailConfig.js`:

```javascript
export const EMAIL_ORGANIZACAO = {
  // 📧 Seus dados reais
  email: 'cpm@suaorganizacao.com.br',
  nome: 'CPM - Comissão de Padronização de Materiais',
  
  // 🏢 Dados da sua organização
  organizacao: {
    nome: 'Nome da Sua Organização',
    cnpj: '00.000.000/0000-00',
    endereco: 'Rua Exemplo, 123 - Cidade/UF',
    telefone: '(11) 99999-9999',
    website: 'https://www.suaorganizacao.com.br'
  }
}
```

---

## 🚀 **COMO USAR**

### **1. Cadastrar Produto com Email**
- Acesse **Cadastro de Produto**
- Preencha todos os campos, incluindo **"Email do Fornecedor"**
- Salve o produto

### **2. Solicitar Diligência**
- Acesse **Análise de Produto**
- Clique no botão **"🔍 Solicitar Diligência"**
- Preencha os dados da diligência
- O sistema automaticamente:
  - ✅ Salva a diligência no banco
  - ✅ Envia email para o fornecedor
  - ✅ Atualiza status do produto
  - ✅ Registra log do email

### **3. Verificar Logs de Email**
Consulte no Supabase a tabela `emails_enviados`:

```sql
-- Ver todos os emails enviados
SELECT * FROM emails_enviados 
ORDER BY created_at DESC;

-- Ver estatísticas
SELECT * FROM v_estatisticas_emails;
```

---

## 📊 **PROVEDORES DE EMAIL RECOMENDADOS**

### 🥇 **1. SendGrid** (Recomendado)
- ✅ Até 100 emails/dia grátis
- ✅ Entregabilidade excelente
- ✅ Fácil configuração
- 🔗 [Criar conta SendGrid](https://sendgrid.com)

### 🥈 **2. Mailgun**
- ✅ Até 5.000 emails/mês grátis (3 meses)
- ✅ Boa entregabilidade
- 🔗 [Criar conta Mailgun](https://www.mailgun.com)

### 🥉 **3. SMTP (Gmail, Outlook, etc.)**
- ✅ Gratuito
- ⚠️ Limitações de envio
- ⚠️ Pode ser bloqueado

---

## 🎨 **EXEMPLO DO EMAIL ENVIADO**

O fornecedor receberá um email profissional com:

```
📋 Diligência Solicitada
Comissão de Padronização de Materiais

Prezado(a) Fornecedor,

Foi solicitada uma diligência para o produto em análise:

📦 Dados do Produto:
Nome: [Nome do Produto]
Marca: [Marca]
Modelo: [Modelo]
Fabricante: [Fabricante]

⚠️ Tipo de Diligência:
[Tipo selecionado]
[Descrição detalhada]

⏰ Prazo para Resposta:
5 dias úteis
Data Limite: 15/12/2024

📝 Instruções:
• Responda a esta diligência dentro do prazo estabelecido
• Envie todos os documentos solicitados em formato PDF
• Em caso de dúvidas, entre em contato conosco
• O não atendimento da diligência pode resultar na reprovação do produto
```

---

## 🔍 **TESTE DO SISTEMA**

### **Em Desenvolvimento**
- Os emails são **simulados** e aparecem no console
- Logs são salvos normalmente no banco
- Para testar: veja o console do navegador

### **Em Produção**
- Configure o provedor de email
- Os emails serão enviados realmente
- Monitore os logs na tabela `emails_enviados`

---

## 🐛 **SOLUÇÃO DE PROBLEMAS**

### **❌ Erro: "Email do Fornecedor Necessário"**
**Solução:** Adicione o email no cadastro do produto

### **❌ Erro no Envio do Email**
**Soluções:**
1. Verifique as variáveis de ambiente
2. Confirme a API key do provedor
3. Verifique os logs na tabela `emails_enviados`

### **❌ Email não Chegou**
**Soluções:**
1. Verifique spam/lixo eletrônico
2. Confirme o email do fornecedor
3. Verifique limite do provedor

### **❌ Formato de Email Inválido**
**Solução:** O campo valida automaticamente. Use formato: `nome@dominio.com`

---

## 📈 **ESTATÍSTICAS E MONITORAMENTO**

### **Ver Estatísticas de Emails**
```sql
-- Estatísticas gerais
SELECT 
  tipo,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE status = 'enviado') as enviados,
  COUNT(*) FILTER (WHERE status = 'erro') as erros
FROM emails_enviados 
WHERE created_at > now() - INTERVAL '30 days'
GROUP BY tipo;
```

### **Reenviar Emails com Erro**
```sql
-- Marcar emails com erro para reenvio
SELECT reenviar_emails_com_erro();
```

---

## 🔒 **SEGURANÇA**

- ✅ **RLS (Row Level Security)** ativado
- ✅ Logs por tenant isolados
- ✅ Validação de email obrigatória
- ✅ API keys em variáveis de ambiente
- ✅ Não exposição de dados sensíveis

---

## ✅ **CHECKLIST FINAL**

- [ ] SQL executado no Supabase
- [ ] Variáveis de ambiente configuradas
- [ ] Dados da organização atualizados
- [ ] Provedor de email configurado
- [ ] Teste realizado
- [ ] Emails sendo enviados corretamente

---

## 📞 **SUPORTE**

Em caso de dúvidas:
1. Verifique este documento
2. Consulte os logs no Supabase
3. Teste com emails conhecidos
4. Verifique o console do navegador

---

**🎉 Sistema de Diligências com Email Configurado com Sucesso!** 