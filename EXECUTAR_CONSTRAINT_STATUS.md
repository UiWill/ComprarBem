# Correção da Constraint de Status

## Problema
Erro ao devolver processo CCL: `new row for relation "processos_administrativos" violates check constraint "processos_administrativos_status_check"`

## Solução
Execute o arquivo SQL: `CORRIGIR_CONSTRAINT_STATUS.sql`

## Como aplicar

### 1. Via Supabase Dashboard
1. Acesse o Supabase Dashboard
2. Vá para "SQL Editor"
3. Cole o conteúdo do arquivo `CORRIGIR_CONSTRAINT_STATUS.sql`
4. Execute o comando

### 2. Via CLI do PostgreSQL
```bash
psql -h db.supabase.co -U postgres -d your_database -f CORRIGIR_CONSTRAINT_STATUS.sql
```

## Status incluídos na nova constraint:
- Status de padronização: `rascunho`, `criado_cpm`, `aguardando_assinatura_orgao`, `assinado_admin`, `julgamento_ccl`, `aprovado_ccl`, `aprovado_juridico`, `edital_publicado`, `homologado`, `finalizado`
- Status de despadronização: `criado_cpm_desp`, `aguardando_assinatura_orgao_desp`, `abertura_autorizada_desp`, `aviso_publicado`, `com_recurso_desp`, `homologado_desp`, `excluindo_marcas`
- Status de rejeição: `rejeitado_cpm`, `rejeitado_admin`, `rejeitado_ccl`, `rejeitado_juridico`, `rejeitado_final`
- **Status de devolução**: `devolvido_pelo_orgao`, `devolvido_pela_ccl`, `devolvido_pelo_juridico`

## Correções aplicadas:
1. ✅ **Layout do modal CCL**: Ajustado para `width: 700px` e `maxWidth: 90vw` com melhor CSS responsivo
2. ✅ **Constraint de status**: Arquivo SQL criado para incluir status de devolução