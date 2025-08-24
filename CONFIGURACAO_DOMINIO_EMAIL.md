# 📧 Configuração de Domínio para Emails - Sistema Comprar Bem

## 🎯 OBJETIVO
Configurar domínio próprio para envio de emails de notificações automáticas via Resend.

## 📋 STATUS ATUAL
- ✅ **Resend configurado** com API Key
- ✅ **Edge Function funcionando** 
- ✅ **GitHub Actions funcionando**
- 🟡 **Domínio próprio** - EM PROCESSAMENTO (comprarbem.tec.br)

## 🚀 PRÓXIMOS PASSOS

### 1. COMPRAR DOMÍNIO
- **Domínio**: `comprarbem.tec.br` ✅ COMPRADO
- **Status**: Pedido #30053191 - Aguardando processamento

### 2. CONFIGURAR DNS NO RESEND
Após comprar o domínio, seguir estes passos:

#### 2.1 Adicionar domínio no Resend
1. Acesse: https://resend.com/domains
2. Clique em **"Add Domain"**
3. Digite: `comprarbem.tec.br`
4. Selecione região: **São Paulo**

#### 2.2 Copiar registros DNS
O Resend vai fornecer registros DNS similares a:

```dns
Tipo: MX
Nome: send
Valor: feedback-smtp.sa-east-1.amazonses.com
Prioridade: 10

Tipo: TXT  
Nome: send
Valor: v=spf1 include:amazonses.com ~all

Tipo: TXT
Nome: resend._domainkey
Valor: p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD... (valor longo)

Tipo: TXT
Nome: _dmarc
Valor: v=DMARC1; p=none;
```

#### 2.3 Configurar no provedor do domínio
1. Acesse painel do domínio
2. Vá em **DNS/Zona DNS**
3. Adicione TODOS os registros fornecidos pelo Resend
4. Aguarde propagação (1-24h)

### 3. ATUALIZAR CÓDIGO

#### 3.1 Arquivo para atualizar no Supabase
Arquivo: `EDGE_FUNCTION_DOMINIO_FINAL.ts` (será criado)

#### 3.2 Testar configuração
1. Aguardar propagação DNS
2. Verificar no Resend se domínio está verificado
3. Atualizar Edge Function no Supabase  
4. Testar envio via GitHub Actions

## 📝 COMANDOS ÚTEIS

### Verificar propagação DNS
```bash
nslookup -q=MX send.comprarbem.tec.br
nslookup -q=TXT send.comprarbem.tec.br
```

### Testar Edge Function
```bash
# Via GitHub Actions
GitHub → Actions → Run workflow

# Verificar logs
Supabase → Edge Functions → Logs
```

## 🔧 CONFIGURAÇÕES TÉCNICAS

### Resend API Key
- **Atual**: `re_foA2xb39_2S5yaKQQ4Da5g2SdeUJdKoBg`
- **Onde está**: GitHub Secrets + Supabase Environment Variables

### Edge Function
- **Nome**: `notificacoes-automaticas`
- **URL**: `https://ruagsbbczuwgfflgcaol.supabase.co/functions/v1/notificacoes-automaticas`

### GitHub Actions
- **Arquivo**: `.github/workflows/notificacoes-automaticas.yml`
- **Frequência**: A cada 30 minutos
- **Comando manual**: Run workflow

## ⚠️ IMPORTANTE
- **NÃO deletar** a API Key do Resend
- **Manter** configurações do GitHub Actions
- **Aguardar** propagação DNS antes de testar
- **Verificar** no Resend se domínio foi aprovado

## 📞 CONTATOS DE SUPORTE
- **Resend**: https://resend.com/support
- **DNS**: Provedor do domínio
- **Supabase**: https://supabase.com/support

---
📅 **Criado em**: 19/07/2025  
👤 **Por**: Claude Code + William  
🎯 **Projeto**: Sistema Comprar Bem - Notificações Automáticas