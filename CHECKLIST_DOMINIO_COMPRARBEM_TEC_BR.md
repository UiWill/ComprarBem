# ✅ CHECKLIST: Ativação de comprarbem.tec.br

## 📊 STATUS ATUAL
- **Domínio**: `comprarbem.tec.br` 
- **Pedido**: #30053191 (Registro.br)
- **Status**: 🟡 Aguardando processamento/pagamento

## 🎯 QUANDO O DOMÍNIO ESTIVER ATIVO

### 1. CONFIGURAR GITHUB PAGES (5 min)
```bash
# 1. Ir para o repositório UiWill/ComprarBem
# 2. Settings → Pages → Custom domain
# 3. Digite: comprarbem.tec.br
# 4. Save (GitHub cria arquivo CNAME automaticamente)
# 5. Enable "Enforce HTTPS" após propagação
```

### 2. CONFIGURAR DNS NO REGISTRO.BR (10 min)
```dns
# A Records (para comprarbem.tec.br):
Tipo: A
Nome: @
Valor: 185.199.108.153

Tipo: A  
Nome: @
Valor: 185.199.109.153

Tipo: A
Nome: @
Valor: 185.199.110.153

Tipo: A
Nome: @
Valor: 185.199.111.153

# CNAME Record (para www):
Tipo: CNAME
Nome: www
Valor: uiwill.github.io
```

### 3. CONFIGURAR EMAIL NO RESEND (15 min)
```bash
# 1. Acessar resend.com/domains
# 2. Add Domain → comprarbem.tec.br
# 3. Copiar registros DNS fornecidos:

# Exemplo dos registros que aparecerão:
MX: send → feedback-smtp.sa-east-1.amazonses.com (Prioridade: 10)
TXT: send → v=spf1 include:amazonses.com ~all
TXT: resend._domainkey → [valor DKIM longo]
TXT: _dmarc → v=DMARC1; p=none;

# 4. Adicionar TODOS no DNS do Registro.br
# 5. Aguardar verificação (1-24h)
```

### 4. ATUALIZAR EDGE FUNCTION NO SUPABASE (3 min)
```bash
# 1. Acessar Supabase Dashboard
# 2. Edge Functions → notificacoes-automaticas
# 3. Substituir código atual pelo conteúdo de:
#    EDGE_FUNCTION_DOMINIO_FINAL.ts
# 4. Deploy
```

### 5. TESTAR SISTEMA COMPLETO (5 min)
```bash
# 1. GitHub Actions → Run workflow (manual)
# 2. Verificar logs no Supabase
# 3. Confirmar emails chegando nos usuários teste
# 4. Verificar site funcionando em comprarbem.tec.br
```

## ⏱️ TEMPO TOTAL: ~40 minutos

## 📧 RESULTADOS ESPERADOS

### Sistema Funcional:
- ✅ Site: `https://comprarbem.tec.br` (HTTPS automático)
- ✅ Emails automáticos a cada 30 minutos
- ✅ Lembretes funcionando para todos usuários
- ✅ Templates HTML bonitos nos emails

### Emails de Teste:
- **Para**: williamemanoel777@gmail.com
- **Assunto**: "📋 Lembrete: Avalie o material recebido - [Nome do Material]"
- **Remetente**: Sistema Comprar Bem <notificacoes@comprarbem.tec.br>

## 🔍 COMANDOS DE VERIFICAÇÃO

### Verificar propagação DNS:
```bash
nslookup comprarbem.tec.br
nslookup -q=MX send.comprarbem.tec.br
nslookup -q=TXT send.comprarbem.tec.br
```

### Verificar SSL/HTTPS:
```bash
# Aguardar até GitHub mostrar ✅ ao lado de "Enforce HTTPS"
# Testar: https://comprarbem.tec.br
```

### Verificar emails:
```bash
# GitHub Actions → Latest run → Ver logs
# Supabase → Edge Functions → Logs
# Verificar caixa de entrada dos usuários teste
```

## ⚠️ TROUBLESHOOTING

### Se DNS não propagar:
- Aguardar até 24h (normal)
- Verificar registros no painel Registro.br
- Usar ferramentas online de verificação DNS

### Se HTTPS não ativar:
- Remover e re-adicionar domínio no GitHub Pages
- Aguardar propagação DNS completa primeiro

### Se emails não chegarem:
- Verificar se domínio está verificado no Resend
- Conferir se Edge Function foi atualizada
- Verificar logs do Supabase para erros

## 📞 LINKS ÚTEIS

- **GitHub Pages**: https://github.com/UiWill/ComprarBem/settings/pages
- **Resend Dashboard**: https://resend.com/domains  
- **Supabase Edge Functions**: https://supabase.com/dashboard/project/ruagsbbczuwgfflgcaol/functions
- **GitHub Actions**: https://github.com/UiWill/ComprarBem/actions

---
📅 **Criado**: 24/08/2025  
🎯 **Objetivo**: Ativação completa do sistema com domínio comprarbem.tec.br  
📧 **Resultado**: Sistema 100% funcional com emails automáticos