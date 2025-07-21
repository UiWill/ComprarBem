# 📋 Configuração do Sistema de Minutas Padrão

## 🔧 Configuração Inicial

### 1. Configurar o Banco de Dados

Execute o script SQL no Supabase SQL Editor:

```sql
-- Execute o arquivo: SQL_MINUTAS_PADRAO.sql
```

### 2. Configurar o Storage do Supabase

Execute o script SQL no Supabase SQL Editor:

```sql
-- Execute o arquivo: CONFIGURAR_STORAGE_MINUTAS.sql
```

### 3. Configurar o Arquivo de Minuta Padrão

1. **Copie o arquivo original**:
   ```
   DOCUMENTOS ESCRITOS/MINUTA PADRAO.docx
   ```

2. **Cole na pasta public**:
   ```
   public/MINUTA_PADRAO.docx
   ```

3. **Importante**: O nome deve ser exatamente `MINUTA_PADRAO.docx` (sem espaços)

## 🚀 Como Funciona

### Inicialização Automática

Quando o sistema inicializar, ele irá:

1. ✅ Verificar se existe minuta padrão no banco
2. ✅ Verificar se o arquivo existe no storage
3. ✅ Fazer upload automático do arquivo `public/MINUTA_PADRAO.docx`
4. ✅ Criar registro no banco de dados

### Fluxo de Criação de Editais

1. **Seleção de Minuta**: Usuário escolhe entre minutas do sistema ou personalizadas
2. **Número do Edital**: Sistema sugere próximo número, mas usuário pode editar
3. **Validação**: Sistema verifica se número já existe
4. **Criação**: Edital criado em status RASCUNHO
5. **Workflow**: Download → Preenchimento → Upload → Conversão PDF → Publicação

## 🎯 Funcionalidades Implementadas

### ✅ Edição de Número do Edital
- Sistema sugere próximo número automaticamente
- Usuário pode editar antes de confirmar
- Validação de duplicatas
- Formato padrão: 001/2024, 002/2024, etc.

### ✅ Upload Automático da Minuta Padrão
- Verificação automática na inicialização
- Upload para Supabase Storage
- Registro automático no banco
- Fallback para arquivo local

### ✅ Gerenciamento de Minutas
- Minutas do sistema (🏛️)
- Minutas personalizadas (📄)
- Upload de novas minutas
- Categorização

### ✅ Workflow Visual
- 3 etapas claramente definidas
- Indicadores de progresso
- Estados visuais (ativo/inativo)
- Feedback para o usuário

## 🔍 Verificações e Troubleshooting

### Verificar se a Minuta Padrão foi Configurada

```sql
SELECT * FROM minutas_padrao WHERE eh_padrao_sistema = true;
```

### Verificar Storage

No Supabase Dashboard:
- Storage → minutas-padrao → sistema → MINUTA_PADRAO.docx
- Storage → editais-arquivos (para arquivos preenchidos)

### Logs do Sistema

Abrir DevTools (F12) e verificar:
- Console para logs de upload
- Network para verificar requisições
- Application → Local Storage para dados do Vue

## 📁 Estrutura de Arquivos

```
COMPRAR BEM/
├── public/
│   └── MINUTA_PADRAO.docx              # Arquivo original da minuta
├── SQL_MINUTAS_PADRAO.sql              # Script do banco
├── CONFIGURAR_STORAGE_MINUTAS.sql      # Script do storage
└── src/components/dashboard/
    └── DashboardCPM.vue                # Componente principal
```

## 🔒 Segurança

- RLS habilitado em todas as tabelas
- Políticas de acesso configuradas
- Validação de tipos de arquivo
- Limite de tamanho de arquivo (50MB)

## 📊 Monitoramento

O sistema registra:
- Uso de minutas no `minuta_uso_historico`
- Logs de upload e conversão
- Status de cada etapa do workflow

---

## 🆘 Suporte

Se houver problemas:

1. Verificar se os buckets foram criados no Supabase
2. Confirmar que o arquivo está em `public/MINUTA_PADRAO.docx`
3. Verificar logs no console do navegador
4. Testar criação manual de minuta personalizada 