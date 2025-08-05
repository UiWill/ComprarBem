# 🎯 NOVA TRAMITAÇÃO - PROCESSOS ADMINISTRATIVOS

## 📋 Fluxo Conforme Lei 14.133/2021

### **FASE 1: CRIAÇÃO (CPM)**
- **Responsável:** CPM
- **Ações:** 
  - Criar processo (Padronização/Des-padronização)
  - Preencher DFD (Declaração de Funcionalidade e Desempenho)
  - Anexar documentos técnicos
  - Submeter para análise
- **Status:** `criado_cpm`

### **FASE 2: ANÁLISE TÉCNICA (CPM)**
- **Responsável:** CPM  
- **Ações:**
  - Analisar documentação técnica
  - Validar especificações
  - Aprovar ou solicitar correções
  - Encaminhar para autoridade competente
- **Status:** `aprovado_cpm` / `rejeitado_cpm`

### **FASE 3: ANÁLISE ADMINISTRATIVA (ÓRGÃO ADMINISTRATIVO)**
- **Responsável:** Órgão Administrativo
- **Ações:**
  - Revisar processo e documentação
  - Verificar conformidade administrativa
  - Assinar digitalmente
  - Encaminhar para análise jurídica
- **Status:** `assinado_admin` / `rejeitado_admin`

### **FASE 4: ANÁLISE JURÍDICA (ASSESSORIA JURÍDICA)**
- **Responsável:** Assessoria Jurídica
- **Ações:**
  - Análise de conformidade legal
  - Verificar adequação à Lei 14.133/2021
  - Emitir parecer jurídico
  - Aprovar ou solicitar correções
- **Status:** `aprovado_juridico` / `rejeitado_juridico`

### **FASE 5: HOMOLOGAÇÃO FINAL (ÓRGÃO ADMINISTRATIVO)**
- **Responsável:** Órgão Administrativo
- **Ações:**
  - Revisar análises anteriores
  - Assinatura final de homologação
  - Publicar processo
  - Atualizar catálogo (se padronização)
- **Status:** `homologado` / `rejeitado_final`

## 🔄 Status Possíveis:
- `rascunho` - Em criação pelo CPM
- `criado_cpm` - Submetido pelo CPM
- `aprovado_cpm` - Aprovado tecnicamente 
- `assinado_admin` - Assinado pela autoridade
- `aprovado_juridico` - Aprovado juridicamente
- `homologado` - Processo finalizado
- `rejeitado_*` - Rejeitado em qualquer fase

## 🔐 Controle de Acesso por Perfil:
- **CPM:** Pode criar, editar (rascunho), e aprovar tecnicamente
- **Órgão Admin:** Pode assinar e homologar
- **Assessoria:** Pode analisar juridicamente  
- **CCL:** Sem acesso aos processos administrativos