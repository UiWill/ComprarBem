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
- **Recebe processos  pela 
- **Emite julgamento e envia o processo para homologação ao Órgão Administrativo**
- Após homologação, **retorna processo para CPPM** para emissão de DCB

Painel CCL

- **R

### **Atualização no Fluxo de Envio para a CCL**
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
    - **Caso esteja assinado**, o processo é considerado 
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

--