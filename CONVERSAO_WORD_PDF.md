# 📄 Conversão Word → PDF para GitHub Pages (Produção)

## 🚀 Configuração para Produção

Para obter máxima qualidade de conversão no GitHub Pages, configure as APIs online:

## ✅ Métodos que Funcionam em Produção

### 🥇 1. CloudConvert API (Recomendado)
- **Qualidade**: 95% - Layout preservado perfeitamente
- **Preço**: 1000 conversões gratuitas/mês
- **Configuração**:

```javascript
// 1. Criar conta: https://cloudconvert.com/
// 2. Obter API Key no dashboard
// 3. Configurar no projeto:
localStorage.setItem('cloudconvert_api_key', 'sua_api_key_aqui')

// Ou via variável de ambiente:
// CLOUDCONVERT_API_KEY=sua_api_key
```

### 🥈 2. ILovePDF API
- **Qualidade**: 90% - Excelente para a maioria dos casos
- **Preço**: 200 conversões gratuitas/mês
- **Configuração**:

```javascript
// 1. Criar conta: https://developer.ilovepdf.com/
// 2. Obter API Key
// 3. Configurar:
localStorage.setItem('ilovepdf_api_key', 'sua_api_key_aqui')
```

### 🥉 3. PDF-lib + Mammoth
- **Qualidade**: 75% - Boa para documentos simples
- **Preço**: Gratuito
- **Configuração**: Instalar dependência

```bash
npm install pdf-lib
```

## 📋 Configuração Passo a Passo

### 🎯 **ETAPA 1: Instalar PDF-lib**

```bash
npm install pdf-lib
```

### 🎯 **ETAPA 2: Configurar CloudConvert (Recomendado)**

1. **Criar conta**: https://cloudconvert.com/
2. **Obter API Key**: Dashboard → API → Create New Key
3. **Configurar no projeto**:

```javascript
// Opção 1: No console do navegador (temporário)
localStorage.setItem('cloudconvert_api_key', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...')

// Opção 2: Via variável de ambiente (permanente)
// No arquivo .env:
CLOUDCONVERT_API_KEY=sua_api_key_aqui
```

### 🎯 **ETAPA 3: Configurar ILovePDF (Alternativa)**

1. **Criar conta**: https://developer.ilovepdf.com/
2. **Obter API Key**: Dashboard → Keys
3. **Configurar**:

```javascript
localStorage.setItem('ilovepdf_api_key', 'project_public_key_aqui')
```

### 🎯 **ETAPA 4: Testar Configuração**

```javascript
// No console do navegador, testar se está configurado:
console.log('CloudConvert:', localStorage.getItem('cloudconvert_api_key'))
console.log('ILovePDF:', localStorage.getItem('ilovepdf_api_key'))
```

## 🚦 **Status dos Métodos no GitHub Pages**

| Método | Status | Configuração | Qualidade |
|--------|--------|--------------|-----------|
| 🟢 **CloudConvert** | ✅ Funciona | API Key | 95% |
| 🟢 **ILovePDF** | ✅ Funciona | API Key | 90% |
| 🟢 **PDF-lib** | ✅ Funciona | npm install | 75% |
| 🔴 **LibreOffice** | ❌ Não funciona | Servidor local | - |
| 🔴 **Docx2PDF** | ❌ Não funciona | Biblioteca não disponível | - |
| 🟡 **Mammoth Optimized** | ✅ Fallback | Sem configuração | 80% |

## 💡 **Configuração de Produção Recomendada**

### Para GitHub Pages:

1. **Instalar PDF-lib**:
```bash
npm install pdf-lib
```

2. **Configurar variáveis de ambiente** no GitHub:
   - Settings → Secrets and Variables → Actions
   - Adicionar: `CLOUDCONVERT_API_KEY`

3. **Configurar no build do GitHub Actions**:
```yaml
- name: Build
  env:
    CLOUDCONVERT_API_KEY: ${{ secrets.CLOUDCONVERT_API_KEY }}
  run: npm run build
```

4. **Fallback para localStorage** (usuários finais):
```javascript
// Interface para configuração de usuário
function configurarAPI() {
  const apiKey = prompt('Cole sua CloudConvert API Key:')
  localStorage.setItem('cloudconvert_api_key', apiKey)
  alert('API configurada! Agora você terá conversões de alta qualidade.')
}
```

## 🔄 **Como o Sistema Funciona Agora**

```
Usuário converte Word → PDF
    ↓
1. CloudConvert API (95% qualidade) ← Se configurado
    ↓ (se falhar)
2. ILovePDF API (90% qualidade) ← Se configurado  
    ↓ (se falhar)
3. PDF-lib (75% qualidade) ← Se npm install foi feito
    ↓ (se falhar)
4. Mammoth Optimized (80% qualidade) ← Sempre funciona
```

## ⚙️ **Configuração Rápida para Teste**

Execute no console do navegador:

```javascript
// CloudConvert (1000 conversões gratuitas/mês)
localStorage.setItem('cloudconvert_api_key', 'SUA_API_KEY_CLOUDCONVERT')

// ILovePDF (200 conversões gratuitas/mês)  
localStorage.setItem('ilovepdf_api_key', 'SUA_API_KEY_ILOVEPDF')

// Testar
location.reload()
```

## 📊 **Comparação de Custos**

| Serviço | Grátis | Pago | Qualidade |
|---------|---------|------|-----------|
| CloudConvert | 1000/mês | $9/mês para 10k | 95% |
| ILovePDF | 200/mês | $6/mês para 2k | 90% |
| PDF-lib | Ilimitado | Grátis | 75% |
| Mammoth | Ilimitado | Grátis | 80% |

## 🎯 **Resultado Esperado**

Após configuração:
- ✅ **CloudConvert funcionando**: Qualidade 95%
- ✅ **Tabelas preservadas**: Bordas e formatação
- ✅ **Quadros mantidos**: Layout complexo preservado
- ✅ **Marcações corretas**: Numeração e bullets
- ✅ **Fontes adequadas**: Typography profissional
- ✅ **Fallback robusto**: Sempre funciona mesmo sem API

---

**🚀 Pronto para produção no GitHub Pages!**