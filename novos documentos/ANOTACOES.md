### **Estrutura de Acessos por Órgãos e Perfis de Usuário**

Todos os órgãos compartilham o mesmo **Tenant ID**, permitindo comunicação entre si. No entanto, cada órgão possui **acessos distintos**, com visibilidade limitada às funcionalidades que lhes competem.

---

### 🟩 **CPPM (Comissão Permanente de Padronização de Materiais)**

**Acessos:**

- Painel CPPM
- Cadastro de Produtos
- Catálogo de Marcas
- Classificação de Bens
- DCB (Declaração de Conformidade de Bens)
- RDM (Relatório de Desempenho de Materiais)
- Processos Administrativos:
    - Pode **criar processos**
    - Inserção de documentos
    - Envio de processo ao **Órgão Administrativo** (fase inicial)
    - Recebimento de processo com **pendências ou assinado**
    - Reencaminhamento com ajustes
    - Encaminhamento à CCL **apenas após processo homologado**

---

### 🟧 **CCL (Comissão de Contratação e Licitação)**

**Acessos:**

- Painel CCL
- **Recebe processos administrativos finalizados** pela CPPM
- **Emite julgamento e envia o processo para homologação ao Órgão Administrativo**
- Após homologação, **retorna processo para CPPM** para emissão de DCB

Painel CCL

- **Receberá apenas processos administrativos finalizados**

### **Atualização no Fluxo de Envio para a CCL**

> Antes:
> 
> 
> Assim que a CPPM aprovava um produto, ele já era encaminhado diretamente para a CCL.
> 

> Agora:
> 
> 
> A **CCL só receberá o processo administrativo após sua finalização completa**. O novo fluxo é o seguinte:
> 
1. A **CPPM cria e monta** o processo administrativo, com todos os documentos exigidos.
2. O processo é **enviado para o Órgão Administrativo**, que:
    - **Assina digitalmente** ou
    - **Devolve com pendências** para correção.
3. A CPPM recebe de volta o processo:
    - **Caso tenha pendência**, ela corrige e reenvia.
    - **Caso esteja assinado**, o processo é considerado **finalizado**.
4. **Somente após essa finalização e retorno do processo assinado à CPPM**, será habilitada no sistema a **opção de tramitação para a CCL**.

📌 **Resumo:**

A CCL **não receberá mais os produtos diretamente da CPPM**, mas apenas os **processos administrativos completos e assinados pela autoridade competente**, representando a padronização final validada.

---

### 🟦 **Órgão Administrativo**

**Acessos:**

- Painel de Processos Administrativos
- Visualiza **somente processos pendentes de sua assinatura**
- Funções:
    - **Assinar digitalmente**
    - **Solicitar ajustes** com mensagem para CPPM ou CCL
    - **Homologar** o julgamento (fase final)

---

### 🟥 **Assessoria Jurídica**

**Acessos:**

- Painel de Processos Administrativos
- Visualiza **somente processos finalizados**
- Funções:
    - Avaliar minutas e editais
    - Emitir parecer jurídico
    - Aprovar ou devolver com diligências

---

### 🔁 **Envio ao Órgão Administrativo: Quem envia e quando**

| Situação | Responsável pelo envio ao Órgão Administrativo |
| --- | --- |
| Durante a **montagem ou abertura** do processo (ex: envio do DFD) | **CPPM** |
| Após **julgamento técnico**, para **homologação** do processo | **CCL** |

O mesmo processo pode ser enviado ao Órgão Administrativo mais de uma vez, por órgãos diferentes, **dependendo da etapa em que ele se encontra**.

---

### 🧾 **Fluxo do Processo Administrativo**

1. A **CPPM inicia** o processo (botão "Iniciar Processo" → “Padronização” ou “Despadronização”)
2. O sistema gera a **folha de rosto** e o **DFD**
3. CPPM insere documentos em **ordem cronológica e numerada**
4. CPPM envia o processo para o **Órgão Administrativo** (para abertura/autorização)
5. Processo retorna à CPPM
6. CPPM finaliza tecnicamente e envia para a **CCL**
7. CCL realiza o **julgamento e emite ata**
8. CCL envia o processo ao **Órgão Administrativo para homologação**
9. Órgão Administrativo homologa e devolve à CCL
10. CCL devolve o processo homologado à CPPM
11. CPPM emite a **Declaração de Conformidade de Bem (DCB)**

---

### 📬 **Notificações Automáticas**

O sistema deverá disparar **alertas por e-mail** para os órgãos responsáveis sempre que:

- Um processo for recebido para análise, assinatura ou homologação
- Houver pendências ou documentos aguardando resposta
- Um processo for devolvido com observações
- O processo for aprovado ou homologado

---

### 👁️ **Permissão de Leitura Externa**

O sistema deve permitir que processos administrativos sejam **compartilhados com usuários externos apenas em modo de leitura**, sem opção de assinatura ou edição. Isso pode ser usado, por exemplo, para consulta pública ou acompanhamento por terceiros autorizados.

---

### 📋 **PENDÊNCIAS TÉCNICAS IDENTIFICADAS**

#### **🔄 Ajustes no Fluxo Atual (CRÍTICO)**
- [ ] **Corrigir condição para "Enviar para CCL"**: Só deve aparecer após processo estar assinado pelo Órgão Admin
- [ ] **Atualizar status do fluxo**: Incluir estados intermediários para controle de quando CCL pode receber
- [ ] **Ajustar assistente de processos**: Corrigir formulários de Padronização/Despadronização com scroll

#### **📧 Sistema de Notificações Automáticas (ALTA)**
- [ ] **Email quando processo é tramitado**: Notificar órgão responsável
- [ ] **Alertas de pendências**: Lembretes automáticos de processos parados
- [ ] **Confirmações de ação**: Notificar quando processo é assinado/homologado
- [ ] **Template de emails**: Criar templates específicos por tipo de notificação

#### **📄 Gestão de Documentos (ALTA)**
- [ ] **Numeração sequencial**: Controle automático de numeração de folhas (Fl. 001, 002, etc.)
- [ ] **Modelos de DFD**: Implementar os 3 modelos diferentes baseados nos arquivos .docx
- [ ] **Inserção ordenada**: Documentos em ordem cronológica no processo
- [ ] **Upload de documentos**: Interface para adicionar documentos ao processo

#### **🏛️ Emissão de DCB (ALTA)**
- [ ] **Geração automática**: Criar DCB após retorno da CCL homologada
- [ ] **Template de DCB**: Baseado no processo e produtos aprovados
- [ ] **Numeração de DCB**: Sistema de numeração única para DCBs

#### **🔗 Funcionalidades Complementares (MÉDIA)**
- [ ] **Compartilhamento público**: Links para visualização externa (somente leitura)
- [ ] **Histórico de tramitação**: Timeline visual completa do processo
- [ ] **Relatórios gerenciais**: Dashboard com métricas de processos por órgão
- [ ] **Backup/Arquivamento**: Sistema de arquivamento de processos finalizados

#### **✅ Funcionalidades Já Implementadas**
- [x] **Sistema de 4 perfis**: CPM, CCL, Órgão Admin, Assessoria Jurídica
- [x] **Navegação restrita**: Cada perfil vê apenas suas funcionalidades
- [x] **Fluxo de 5 fases**: Conforme Lei 14.133/2021
- [x] **Assinatura digital**: Por perfil com cargos automáticos
- [x] **Controle de transições**: Validação de permissões por status
- [x] **Interface de workflow**: Botões de ação dinâmicos por perfil
- [x] **Registro de tramitação**: Log completo de movimentações

---

### 🎯 **ROTEIRO PARA AMANHÃ**

**PRIORIDADE MÁXIMA (Fazer primeiro):**
1. 🔧 **Corrigir assistente de processos** (scroll e formulários)
2. 🔄 **Ajustar fluxo CCL** (só receber processos assinados)
3. 📧 **Implementar notificações básicas** (email de tramitação)

**PRIORIDADE ALTA (Se der tempo):**
4. 📄 **Modelos de DFD corretos**
5. 🔢 **Numeração de documentos**
6. 🏛️ **Geração de DCB**

**Para a semana:**
7. 🔗 **Compartilhamento externo**
8. 📊 **Relatórios e métricas**