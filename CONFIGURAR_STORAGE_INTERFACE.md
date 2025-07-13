# 🗂️ Configurar Storage via Interface do Supabase

## 🛠️ Alternativa: Configurar pela Interface (Mais Fácil)

Se o SQL deu erro, você pode configurar diretamente pela interface do Supabase:

### 1. Acessar o Storage
- Vá para o dashboard do Supabase
- Clique em **"Storage"** no menu lateral

### 2. Criar Bucket "minutas-padrao"
- Clique em **"Create bucket"**
- Nome: `minutas-padrao`
- ☑️ Public bucket: **Habilitado**
- File size limit: `50 MB`
- Allowed MIME types: 
  - `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
  - `application/msword`
- Clique em **"Create bucket"**

### 3. Criar Bucket "editais-arquivos"
- Clique em **"Create bucket"**
- Nome: `editais-arquivos`
- ☑️ Public bucket: **Habilitado**
- File size limit: `50 MB`
- Allowed MIME types:
  - `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
  - `application/msword`
  - `application/pdf`
- Clique em **"Create bucket"**

### 4. Configurar Policies (Opcional)
Se quiser configurar policies de segurança:

- Clique no bucket criado
- Vá para **"Policies"**
- Clique em **"Add policy"**
- Escolha templates para:
  - **"SELECT"** (leitura pública)
  - **"INSERT"** (upload por usuários autenticados)

## 📋 Verificação

Após criar, você deve ver:
- ✅ Bucket `minutas-padrao` criado
- ✅ Bucket `editais-arquivos` criado
- ✅ Ambos marcados como "Public"

## 🔄 Próximos Passos

1. **Copiar arquivo**: `DOCUMENTOS ESCRITOS/MINUTA PADRAO.docx` → `public/MINUTA_PADRAO.docx`
2. **Testar sistema**: Acessar Dashboard CPM → Novo Edital
3. **Verificar logs**: Console do navegador (F12)

## 🆘 Se Ainda Houver Problemas

Execute apenas as tabelas do banco:
```sql
-- Execute apenas isto no SQL Editor:
-- Arquivo: SQL_MINUTAS_PADRAO.sql
```

O storage pode ser configurado pela interface mesmo se o SQL falhar! 