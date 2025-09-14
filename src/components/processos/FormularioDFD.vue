<template>
  <div class="dfd-container">
    <div class="dfd-header">
      <h2>📋 Documento de Formalização de Demanda (DFD)</h2>
      <p class="subtitle">Processo: {{ numeroProcesso }}</p>
    </div>

    <div class="modelo-selector">
      <h3>Escolha o Modelo de DFD</h3>
      <div class="modelos-opcoes">
        <div 
          class="modelo-opcao" 
          :class="{ active: modeloSelecionado === 'modelo_1' }"
          @click="selecionarModelo('modelo_1')"
        >
          <div class="modelo-icon">📄</div>
          <div class="modelo-info">
            <h4>Modelo 1</h4>
            <p>Para processos de padronização com produtos específicos e quantidades definidas</p>
            <ul>
              <li>Especificações técnicas detalhadas</li>
              <li>Quantidades estimadas</li>
              <li>Critérios de aceitação</li>
              <li>Prazo e local de entrega</li>
            </ul>
          </div>
        </div>
        
        <div 
          class="modelo-opcao" 
          :class="{ active: modeloSelecionado === 'modelo_2' }"
          @click="selecionarModelo('modelo_2')"
        >
          <div class="modelo-icon">📋</div>
          <div class="modelo-info">
            <h4>Modelo 2</h4>
            <p>Para processos de despadronização com base em reclamações e RDM</p>
            <ul>
              <li>Análise de relatórios RDM</li>
              <li>Justificativas de despadronização</li>
              <li>Histórico de problemas</li>
              <li>Motivações técnicas</li>
            </ul>
          </div>
        </div>
        
        <div 
          class="modelo-opcao" 
          :class="{ active: modeloSelecionado === 'modelo_geral' }"
          @click="selecionarModelo('modelo_geral')"
        >
          <div class="modelo-icon">📑</div>
          <div class="modelo-info">
            <h4>Modelo Geral</h4>
            <p>Modelo flexível para situações especiais e processos customizados</p>
            <ul>
              <li>Campos opcionais adaptáveis</li>
              <li>Seções configuráveis</li>
              <li>Adequado para casos específicos</li>
              <li>Permite maior personalização</li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <form v-if="modeloSelecionado" @submit.prevent="salvarDFD" class="dfd-form">
      <!-- Seção de Dados do Demandante -->
      <div class="form-section">
        <h3>👨‍💼 Dados do Demandante</h3>
        <div class="form-row">
          <div class="form-group">
            <label>Nome do Presidente da CPPM *</label>
            <input 
              type="text" 
              v-model="dadosDFD.nome_presidente" 
              required
              placeholder="Nome completo do presidente..."
            >
            <small>Nome do presidente da Comissão Permanente de Padronização de Materiais</small>
          </div>
          
          <div class="form-group">
            <label>Matrícula *</label>
            <input 
              type="text" 
              v-model="dadosDFD.matricula_presidente" 
              required
              placeholder="Ex: 12345678"
            >
            <small>Matrícula funcional do presidente</small>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-group">
            <label>E-mail *</label>
            <input 
              type="email" 
              v-model="dadosDFD.email_presidente" 
              required
              placeholder="presidente@exemplo.gov.br"
            >
            <small>E-mail institucional do presidente</small>
          </div>
          
          <div class="form-group">
            <label>Telefone</label>
            <input 
              type="tel" 
              v-model="dadosDFD.telefone_presidente"
              placeholder="(xx) 9xxxx-xxxx"
            >
            <small>Telefone para contato</small>
          </div>
        </div>
      </div>
      
      <div class="form-section">
        <h3>🎯 Justificativa</h3>
        <div class="form-group">
          <label>Justificativa da Demanda *</label>
          <textarea 
            v-model="dadosDFD.justificativa" 
            rows="4" 
            required
            placeholder="Descreva a justificativa para esta demanda de pré-qualificação..."
          ></textarea>
          <small>Explique a necessidade institucional que motiva este processo</small>
        </div>
      </div>

      <div class="form-section">
        <h3>📝 Descrição da Necessidade</h3>
        <div class="form-group">
          <label>Descrição Detalhada da Necessidade *</label>
          <textarea 
            v-model="dadosDFD.necessidade_descricao" 
            rows="5" 
            required
            placeholder="Descreva detalhadamente a necessidade que será atendida..."
          ></textarea>
          <small>Seja específico sobre o que será adquirido e para que será usado</small>
        </div>
      </div>

      <!-- Campos específicos do Modelo 1 (Padronização) -->
      <div v-if="modeloSelecionado === 'modelo_1'" class="modelo-1-fields">
        <div class="form-section">
          <h3>📦 Produtos a serem pré-qualificados</h3>
          <div class="form-group">
            <label>Especificação dos Produtos/Serviços *</label>
            <textarea 
              v-model="dadosDFD.produtos_especificacao" 
              rows="4"
              required
              placeholder="Descreva detalhadamente os produtos ou serviços que serão pré-qualificados..."
            ></textarea>
            <small>Especifique marca, modelo, características técnicas, normas aplicáveis</small>
          </div>
        </div>

        <div class="form-section">
          <h3>🔢 Quantidades e Amostragem</h3>
          <div class="form-row">
            <div class="form-group">
              <label>Quantidade de Amostras para Análise</label>
              <input 
                type="number" 
                v-model.number="dadosDFD.quantidade_amostras"
                placeholder="Ex: 5 unidades"
              >
              <small>Quantidade de amostras necessárias para avaliação técnica</small>
            </div>
            
            <div class="form-group">
              <label>Aquisições Previstas (12 meses)</label>
              <input 
                type="number" 
                v-model.number="dadosDFD.previsao_aquisicoes"
                placeholder="Ex: 1000"
              >
              <small>Quantidade estimada de aquisições no próximo ano</small>
            </div>
          </div>
        </div>

        <div class="form-section">
          <h3>📋 Especificações Técnicas Detalhadas</h3>
          <div class="form-group">
            <label>Especificações Técnicas Obrigatórias</label>
            <textarea 
              v-model="dadosDFD.especificacoes_tecnicas" 
              rows="6"
              placeholder="Liste todas as especificações técnicas obrigatórias que o produto deve atender..."
            ></textarea>
            <small>Normas ABNT, certificações, dimensões, materiais, desempenho, etc.</small>
          </div>
        </div>

        <div class="form-section">
          <h3>✅ Critérios de Aceitação e Ensaios</h3>
          <div class="form-group">
            <label>Critérios de Aceitação</label>
            <textarea 
              v-model="dadosDFD.criterios_aceitacao" 
              rows="4"
              placeholder="Defina os critérios que os produtos devem atender para serem aceitos..."
            ></textarea>
            <small>Padrões de qualidade, tolerâncias, métodos de ensaio</small>
          </div>
          
          <div class="form-group">
            <label>Ensaios e Testes Exigidos</label>
            <textarea 
              v-model="dadosDFD.ensaios_exigidos" 
              rows="3"
              placeholder="Descreva os ensaios e testes que serão realizados..."
            ></textarea>
            <small>Testes de laboratório, certificações de terceiros, etc.</small>
          </div>
        </div>

        <div class="form-section">
          <h3>📍 Condições de Entrega</h3>
          <div class="form-row">
            <div class="form-group">
              <label>Local de Entrega das Amostras</label>
              <textarea 
                v-model="dadosDFD.local_entrega_amostras" 
                rows="2"
                placeholder="Endereço para entrega das amostras..."
              ></textarea>
            </div>
            
            <div class="form-group">
              <label>Prazo para Entrega das Amostras</label>
              <input 
                type="text" 
                v-model="dadosDFD.prazo_entrega_amostras"
                placeholder="Ex: 15 dias corridos"
              >
              <small>Prazo máximo para entrega das amostras</small>
            </div>
          </div>
        </div>
      </div>

      <!-- Campos específicos do Modelo 2 (Despadronização) -->
      <div v-if="modeloSelecionado === 'modelo_2'" class="modelo-2-fields">
        <div class="form-section">
          <h3>🚫 Produtos a serem despadronizados</h3>
          <div class="form-group">
            <label>Identificação dos Produtos/Serviços *</label>
            <textarea 
              v-model="dadosDFD.produtos_despadronizar" 
              rows="4"
              required
              placeholder="Liste os produtos que devem ser despadronizados (marca, modelo, especificações)..."
            ></textarea>
            <small>Identifique claramente quais produtos serão removidos da padronização</small>
          </div>
        </div>

        <div class="form-section">
          <h3>📊 Fonte das Informações</h3>
          <div class="form-group">
            <label>Origem das Reclamações/Problemas</label>
            <div class="checkbox-group">
              <label class="checkbox-item">
                <input type="checkbox" v-model="dadosDFD.fonte_rdm"> 
                Relatórios RDM (Relatório de Desempenho de Material)
              </label>
              <label class="checkbox-item">
                <input type="checkbox" v-model="dadosDFD.fonte_reclamacoes_usuarios"> 
                Reclamações de usuários finais
              </label>
              <label class="checkbox-item">
                <input type="checkbox" v-model="dadosDFD.fonte_sistema_comprar_bem"> 
                Sistema "Reclame Aqui" do Comprar Bem
              </label>
              <label class="checkbox-item">
                <input type="checkbox" v-model="dadosDFD.fonte_analise_tecnica"> 
                Análise técnica da CPPM
              </label>
              <label class="checkbox-item">
                <input type="checkbox" v-model="dadosDFD.fonte_outros"> 
                Outros (especificar no campo abaixo)
              </label>
            </div>
          </div>

          <div class="form-group">
            <label>Outras Fontes (se aplicável)</label>
            <input 
              type="text" 
              v-model="dadosDFD.outras_fontes"
              placeholder="Especifique outras fontes de informação..."
            >
          </div>
        </div>

        <div class="form-section">
          <h3>⚠️ Motivações para Despadronização</h3>
          <div class="form-group">
            <label>Principais Problemas Identificados *</label>
            <textarea 
              v-model="dadosDFD.problemas_identificados" 
              rows="5"
              required
              placeholder="Descreva detalhadamente os problemas que motivam a despadronização..."
            ></textarea>
            <small>Problemas de qualidade, durabilidade, adequação ao uso, segurança, etc.</small>
          </div>

          <div class="form-group">
            <label>Frequência dos Problemas</label>
            <select v-model="dadosDFD.frequencia_problemas">
              <option value="">Selecione a frequência</option>
              <option value="isolados">Casos isolados (menos de 5%)</option>
              <option value="esporadicos">Esporádicos (5% a 15%)</option>
              <option value="recorrentes">Recorrentes (15% a 30%)</option>
              <option value="frequentes">Frequentes (mais de 30%)</option>
              <option value="sistematicos">Sistemáticos (maioria dos casos)</option>
            </select>
          </div>

          <div class="form-group">
            <label>Impacto dos Problemas</label>
            <textarea 
              v-model="dadosDFD.impacto_problemas" 
              rows="3"
              placeholder="Descreva o impacto dos problemas na operação..."
            ></textarea>
            <small>Prejuízos financeiros, operacionais, riscos à segurança, etc.</small>
          </div>
        </div>

        <div class="form-section">
          <h3>📈 Dados Quantitativos</h3>
          <div class="form-row">
            <div class="form-group">
              <label>Quantidade Adquirida (últimos 12 meses)</label>
              <input 
                type="number" 
                v-model.number="dadosDFD.quantidade_adquirida"
                placeholder="Ex: 500"
              >
              <small>Total de unidades adquiridas no período</small>
            </div>
            
            <div class="form-group">
              <label>Quantidade com Problemas</label>
              <input 
                type="number" 
                v-model.number="dadosDFD.quantidade_problemas"
                placeholder="Ex: 150"
              >
              <small>Unidades que apresentaram problemas</small>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Prejuízo Estimado (R$)</label>
              <input 
                type="number" 
                step="0.01"
                v-model.number="dadosDFD.prejuizo_estimado"
                placeholder="Ex: 25000.00"
              >
              <small>Valor dos prejuízos causados pelos problemas</small>
            </div>
            
            <div class="form-group">
              <label>Número de RDMs Negativos</label>
              <input 
                type="number" 
                v-model.number="dadosDFD.rdms_negativos"
                placeholder="Ex: 12"
              >
              <small>Quantidade de RDMs com avaliação negativa</small>
            </div>
          </div>
        </div>

        <div class="form-section">
          <h3>🔍 Análise Técnica</h3>
          <div class="form-group">
            <label>Parecer Técnico da CPPM</label>
            <textarea 
              v-model="dadosDFD.parecer_tecnico" 
              rows="4"
              placeholder="Análise técnica da comissão sobre os problemas reportados..."
            ></textarea>
            <small>Avaliação técnica dos problemas e necessidade de despadronização</small>
          </div>

          <div class="form-group">
            <label>Alternativas Avaliadas</label>
            <textarea 
              v-model="dadosDFD.alternativas_avaliadas" 
              rows="3"
              placeholder="Descreva as alternativas consideradas antes da despadronização..."
            ></textarea>
            <small>Tentativas de correção, substituição, renegociação com fornecedores, etc.</small>
          </div>
        </div>
      </div>

      <!-- Campos específicos do Modelo Geral -->
      <div v-if="modeloSelecionado === 'modelo_geral'" class="modelo-geral-fields">
        <div class="form-section">
          <h3>🎯 Informações Complementares</h3>
          
          <div class="form-group">
            <label>Base Legal</label>
            <textarea 
              v-model="dadosDFD.base_legal" 
              rows="3"
              placeholder="Cite a base legal que fundamenta esta demanda..."
            ></textarea>
            <small>Lei 14.133/2021, regulamentos específicos, etc.</small>
          </div>

          <div class="form-group">
            <label>Impacto Esperado</label>
            <textarea 
              v-model="dadosDFD.impacto_esperado" 
              rows="3"
              placeholder="Descreva o impacto esperado com esta ação..."
            ></textarea>
            <small>Benefícios esperados, melhorias de qualidade, economia, etc.</small>
          </div>
        </div>

        <div class="form-section">
          <h3>📊 Análise de Risco</h3>
          
          <div class="form-group">
            <label>Riscos Identificados</label>
            <textarea 
              v-model="dadosDFD.riscos_identificados" 
              rows="3"
              placeholder="Liste os principais riscos identificados..."
            ></textarea>
            <small>Riscos técnicos, de fornecimento, regulatórios, etc.</small>
          </div>

          <div class="form-group">
            <label>Medidas Mitigadoras</label>
            <textarea 
              v-model="dadosDFD.medidas_mitigadoras" 
              rows="3"
              placeholder="Descreva as medidas para mitigar os riscos..."
            ></textarea>
            <small>Ações preventivas e corretivas para os riscos identificados</small>
          </div>
        </div>

        <div class="form-section">
          <h3>📈 Informações Gerenciais</h3>
          
          <div class="form-row">
            <div class="form-group">
              <label>Prazo de Vigência (meses)</label>
              <input 
                type="number" 
                v-model.number="dadosDFD.prazo_vigencia"
                placeholder="Ex: 12"
              >
              <small>Tempo estimado de validade da pré-qualificação</small>
            </div>
            
            <div class="form-group">
              <label>Periodicidade de Revisão</label>
              <select v-model="dadosDFD.periodicidade_revisao">
                <option value="">Selecione</option>
                <option value="semestral">Semestral</option>
                <option value="anual">Anual</option>
                <option value="bienal">Bienal</option>
                <option value="conforme_demanda">Conforme demanda</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div class="form-section">
        <h3>💭 Observações Especiais</h3>
        <div class="form-group">
          <label>Observações Adicionais</label>
          <textarea 
            v-model="dadosDFD.observacoes_especiais" 
            rows="3"
            placeholder="Inclua qualquer informação adicional relevante..."
          ></textarea>
          <small>Informações complementares, restrições especiais, etc.</small>
        </div>
      </div>

      <div class="form-actions">
        <button type="button" @click="$emit('cancelar')" class="btn-secondary">
          Cancelar
        </button>
        <button type="button" @click="salvarRascunho" class="btn-outline" :disabled="salvando">
          💾 Salvar Rascunho
        </button>
        <button type="submit" :disabled="salvando" class="btn-primary">
          {{ salvando ? 'Salvando...' : '✅ Criar DFD e Continuar' }}
        </button>
      </div>
    </form>

    <!-- Preview do DFD -->
    <div v-if="mostrarPreview" class="dfd-preview">
      <div class="preview-header">
        <h3>👁️ Visualização do DFD</h3>
        <button @click="mostrarPreview = false" class="btn-close">×</button>
      </div>
      <div class="preview-content" v-html="previewHTML"></div>
    </div>
  </div>
</template>

<script>
import ProcessosAdministrativosService from '../../services/processosAdministrativosService'

export default {
  name: 'FormularioDFD',
  props: {
    processoId: {
      type: String,
      required: true
    },
    numeroProcesso: {
      type: String,
      required: true
    },
    tipoProcesso: {
      type: String,
      required: true
    },
    dfdEditando: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      modeloSelecionado: null,
      salvando: false,
      mostrarPreview: false,
      autoSaveTimeout: null,
      dadosDFD: {
        // Dados do demandante
        nome_presidente: '',
        matricula_presidente: '',
        email_presidente: '',
        telefone_presidente: '',
        // Campos principais
        justificativa: '',
        necessidade_descricao: '',
        observacoes_especiais: '',
        // Campos específicos do modelo 1 (Padronização)
        produtos_especificacao: '',
        quantidade_amostras: null,
        previsao_aquisicoes: null,
        especificacoes_tecnicas: '',
        criterios_aceitacao: '',
        ensaios_exigidos: '',
        local_entrega_amostras: '',
        prazo_entrega_amostras: '',
        // Campos específicos do modelo 2 (Despadronização)
        produtos_despadronizar: '',
        fonte_rdm: false,
        fonte_reclamacoes_usuarios: false,
        fonte_sistema_comprar_bem: false,
        fonte_analise_tecnica: false,
        fonte_outros: false,
        outras_fontes: '',
        problemas_identificados: '',
        frequencia_problemas: '',
        impacto_problemas: '',
        quantidade_adquirida: null,
        quantidade_problemas: null,
        prejuizo_estimado: null,
        rdms_negativos: null,
        parecer_tecnico: '',
        alternativas_avaliadas: '',
        // Campos específicos do modelo geral
        base_legal: '',
        impacto_esperado: '',
        riscos_identificados: '',
        medidas_mitigadoras: '',
        prazo_vigencia: null,
        periodicidade_revisao: ''
      }
    }
  },
  
  computed: {
    previewHTML() {
      return this.gerarPreviewHTML()
    }
  },
  
  watch: {
    dadosDFD: {
      handler() {
        // Salvar automaticamente após mudanças (com debounce)
        this.salvarAutomaticamente()
      },
      deep: true
    },
    modeloSelecionado: {
      handler() {
        // Salvar automaticamente quando modelo muda
        this.salvarAutomaticamente()
      }
    },
    dfdEditando: {
      handler(newValue) {
        if (newValue) {
          // Carregar dados quando DFD para edição é fornecido
          this.carregarDadosDFD()
        }
      },
      immediate: true
    }
  },
  
  
  methods: {
    carregarDadosDFD() {
      if (!this.dfdEditando) return

      console.log('📝 Carregando dados do DFD para edição:', this.dfdEditando.id)

      // Carregar dados do DFD existente
      Object.keys(this.dadosDFD).forEach(key => {
        if (this.dfdEditando[key] !== undefined) {
          this.dadosDFD[key] = this.dfdEditando[key]
        }
      })

      // Determinar o modelo baseado nos dados
      if (this.dfdEditando.modelo) {
        this.modeloSelecionado = this.dfdEditando.modelo
      } else {
        // Inferir modelo baseado no tipo de processo ou dados existentes
        if (this.tipoProcesso === 'despadronizacao') {
          this.modeloSelecionado = 'modelo_2'
        } else {
          this.modeloSelecionado = 'modelo_1'
        }
      }

      console.log('✅ DFD carregado com sucesso para edição')
    },

    selecionarModelo(modelo) {
      this.modeloSelecionado = modelo
      // Limpar campos específicos de outros modelos
      if (modelo === 'modelo_1') {
        // Limpar campos do modelo 2
        this.dadosDFD.produtos_despadronizar = ''
        this.dadosDFD.fonte_rdm = false
        this.dadosDFD.fonte_reclamacoes_usuarios = false
        this.dadosDFD.fonte_sistema_comprar_bem = false
        this.dadosDFD.fonte_analise_tecnica = false
        this.dadosDFD.fonte_outros = false
        this.dadosDFD.outras_fontes = ''
        this.dadosDFD.problemas_identificados = ''
        this.dadosDFD.frequencia_problemas = ''
        this.dadosDFD.impacto_problemas = ''
        this.dadosDFD.quantidade_adquirida = null
        this.dadosDFD.quantidade_problemas = null
        this.dadosDFD.prejuizo_estimado = null
        this.dadosDFD.rdms_negativos = null
        this.dadosDFD.parecer_tecnico = ''
        this.dadosDFD.alternativas_avaliadas = ''
        // Limpar campos do modelo geral
        this.dadosDFD.base_legal = ''
        this.dadosDFD.impacto_esperado = ''
        this.dadosDFD.riscos_identificados = ''
        this.dadosDFD.medidas_mitigadoras = ''
        this.dadosDFD.prazo_vigencia = null
        this.dadosDFD.periodicidade_revisao = ''
      } else if (modelo === 'modelo_2') {
        // Limpar campos do modelo 1
        this.dadosDFD.produtos_especificacao = ''
        this.dadosDFD.quantidade_amostras = null
        this.dadosDFD.previsao_aquisicoes = null
        this.dadosDFD.especificacoes_tecnicas = ''
        this.dadosDFD.criterios_aceitacao = ''
        this.dadosDFD.ensaios_exigidos = ''
        this.dadosDFD.local_entrega_amostras = ''
        this.dadosDFD.prazo_entrega_amostras = ''
        // Limpar campos do modelo geral
        this.dadosDFD.base_legal = ''
        this.dadosDFD.impacto_esperado = ''
        this.dadosDFD.riscos_identificados = ''
        this.dadosDFD.medidas_mitigadoras = ''
        this.dadosDFD.prazo_vigencia = null
        this.dadosDFD.periodicidade_revisao = ''
      } else if (modelo === 'modelo_geral') {
        // Limpar campos específicos dos modelos 1 e 2
        this.dadosDFD.produtos_especificacao = ''
        this.dadosDFD.quantidade_amostras = null
        this.dadosDFD.previsao_aquisicoes = null
        this.dadosDFD.especificacoes_tecnicas = ''
        this.dadosDFD.criterios_aceitacao = ''
        this.dadosDFD.ensaios_exigidos = ''
        this.dadosDFD.local_entrega_amostras = ''
        this.dadosDFD.prazo_entrega_amostras = ''
        this.dadosDFD.produtos_despadronizar = ''
        this.dadosDFD.fonte_rdm = false
        this.dadosDFD.fonte_reclamacoes_usuarios = false
        this.dadosDFD.fonte_sistema_comprar_bem = false
        this.dadosDFD.fonte_analise_tecnica = false
        this.dadosDFD.fonte_outros = false
        this.dadosDFD.outras_fontes = ''
        this.dadosDFD.problemas_identificados = ''
        this.dadosDFD.frequencia_problemas = ''
        this.dadosDFD.impacto_problemas = ''
        this.dadosDFD.quantidade_adquirida = null
        this.dadosDFD.quantidade_problemas = null
        this.dadosDFD.prejuizo_estimado = null
        this.dadosDFD.rdms_negativos = null
        this.dadosDFD.parecer_tecnico = ''
        this.dadosDFD.alternativas_avaliadas = ''
      }
    },
    
    async salvarDFD() {
      // Prevenir múltiplas submissões
      if (this.salvando) {
        console.log('⚠️ Já está salvando DFD, ignorando nova chamada')
        return
      }

      try {
        this.salvando = true

        const dadosCompletos = {
          ...this.dadosDFD,
          modelo_usado: this.modeloSelecionado
        }

        let resultado

        if (this.dfdEditando && this.dfdEditando.id) {
          // Editando DFD existente
          console.log('✏️ Atualizando DFD existente:', this.dfdEditando.id)
          resultado = await ProcessosAdministrativosService.atualizarDFD(
            this.dfdEditando.id,
            dadosCompletos
          )
        } else {
          // Criando novo DFD
          console.log('🆕 Criando novo DFD')
          resultado = await ProcessosAdministrativosService.criarDFD(
            this.processoId,
            dadosCompletos
          )
        }

        this.$emit('dfd-criado', resultado)

      } catch (error) {
        console.error('Erro ao salvar DFD:', error)
        alert(`Erro ao salvar DFD: ${error.message}`)
      } finally {
        this.salvando = false
      }
    },

    async salvarAutomaticamente() {
      // Auto-salvamento silencioso para não perder dados
      if (!this.modeloSelecionado || this.salvando) return

      console.log('💾 Iniciando auto-save:', {
        dfdEditando: !!this.dfdEditando,
        dfdId: this.dfdEditando?.id,
        modelo: this.modeloSelecionado
      })

      try {
        const dadosCompletos = {
          ...this.dadosDFD,
          modelo_usado: this.modeloSelecionado,
          status: 'rascunho' // Marcar como rascunho no auto-save
        }

        if (this.dfdEditando && this.dfdEditando.id) {
          // Atualizar DFD existente silenciosamente
          await ProcessosAdministrativosService.atualizarDFD(
            this.dfdEditando.id,
            dadosCompletos
          )
          console.log('💾 DFD atualizado automaticamente')
        } else {
          // Para novos DFDs, criar no banco mas não emitir evento ainda
          const resultado = await ProcessosAdministrativosService.criarDFD(
            this.processoId,
            dadosCompletos
          )

          // Após criar, atualizar as props para que vire "edição"
          this.$emit('dfd-auto-criado', resultado)
          console.log('💾 Novo DFD salvo automaticamente como rascunho')
        }

      } catch (error) {
        console.warn('⚠️ Erro no auto-save (não crítico):', error.message)
      }
    },
    
    async salvarRascunho() {
      try {
        this.salvando = true
        
        // Salvar no localStorage como rascunho
        const rascunho = {
          processoId: this.processoId,
          modeloSelecionado: this.modeloSelecionado,
          dadosDFD: { ...this.dadosDFD },
          dataSalvo: new Date().toISOString()
        }
        
        localStorage.setItem(`dfd_rascunho_${this.processoId}`, JSON.stringify(rascunho))
        
        alert('Rascunho salvo com sucesso!')
        
      } catch (error) {
        console.error('Erro ao salvar rascunho:', error)
        alert('Erro ao salvar rascunho')
      } finally {
        this.salvando = false
      }
    },
    
    salvarRascunhoAutomatico() {
      // Limpar timeout anterior se existir
      if (this.autoSaveTimeout) {
        clearTimeout(this.autoSaveTimeout)
      }
      
      // Definir novo timeout para salvar após 3 segundos de inatividade
      this.autoSaveTimeout = setTimeout(async () => {
        // Usar o novo método de salvamento automático no banco
        await this.salvarAutomaticamente()
      }, 3000) // 3 segundos de debounce
    },
    
    carregarRascunho() {
      try {
        const rascunho = localStorage.getItem(`dfd_rascunho_${this.processoId}`)
        if (rascunho) {
          const dados = JSON.parse(rascunho)
          this.modeloSelecionado = dados.modeloSelecionado
          this.dadosDFD = { ...dados.dadosDFD }
          return true
        }
      } catch (error) {
        console.error('Erro ao carregar rascunho:', error)
      }
      return false
    },
    
    gerarPreviewHTML() {
      if (!this.modeloSelecionado) return ''
      
      return `
        <div class="documento-dfd">
          <h1>DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${this.modeloSelecionado.toUpperCase()}</h1>
          
          <div class="secao">
            <h2>PROCESSO</h2>
            <p><strong>Número:</strong> ${this.numeroProcesso}</p>
            <p><strong>Tipo:</strong> ${this.tipoProcesso === 'padronizacao' ? 'Padronização' : 'Despadronização'}</p>
          </div>

          <div class="secao">
            <h2>JUSTIFICATIVA</h2>
            <p>${this.dadosDFD.justificativa || '[Não preenchido]'}</p>
          </div>

          <div class="secao">
            <h2>DESCRIÇÃO DA NECESSIDADE</h2>
            <p>${this.dadosDFD.necessidade_descricao || '[Não preenchido]'}</p>
          </div>

          ${this.modeloSelecionado === 'modelo_1' ? `
            ${this.dadosDFD.quantidade_estimada ? `
            <div class="secao">
              <h2>QUANTIDADE ESTIMADA</h2>
              <p>${this.dadosDFD.quantidade_estimada}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.prazo_entrega ? `
            <div class="secao">
              <h2>PRAZO DE ENTREGA</h2>
              <p>${this.dadosDFD.prazo_entrega}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.local_entrega ? `
            <div class="secao">
              <h2>LOCAL DE ENTREGA</h2>
              <p>${this.dadosDFD.local_entrega}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.criterios_aceitacao ? `
            <div class="secao">
              <h2>CRITÉRIOS DE ACEITAÇÃO</h2>
              <p>${this.dadosDFD.criterios_aceitacao}</p>
            </div>
            ` : ''}
          ` : ''}

          ${this.modeloSelecionado === 'modelo_2' ? `
            ${this.dadosDFD.fonte_reclamacoes ? `
            <div class="secao">
              <h2>FONTE DAS RECLAMAÇÕES</h2>
              <p>${this.dadosDFD.fonte_reclamacoes}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.descricao_problemas ? `
            <div class="secao">
              <h2>PROBLEMAS IDENTIFICADOS</h2>
              <p>${this.dadosDFD.descricao_problemas}</p>
            </div>
            ` : ''}
          ` : ''}

          ${this.modeloSelecionado === 'modelo_geral' ? `
            ${this.dadosDFD.base_legal ? `
            <div class="secao">
              <h2>BASE LEGAL</h2>
              <p>${this.dadosDFD.base_legal}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.impacto_esperado ? `
            <div class="secao">
              <h2>IMPACTO ESPERADO</h2>
              <p>${this.dadosDFD.impacto_esperado}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.riscos_identificados ? `
            <div class="secao">
              <h2>RISCOS IDENTIFICADOS</h2>
              <p>${this.dadosDFD.riscos_identificados}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.medidas_mitigadoras ? `
            <div class="secao">
              <h2>MEDIDAS MITIGADORAS</h2>
              <p>${this.dadosDFD.medidas_mitigadoras}</p>
            </div>
            ` : ''}

            ${this.dadosDFD.prazo_vigencia ? `
            <div class="secao">
              <h2>PRAZO DE VIGÊNCIA</h2>
              <p>${this.dadosDFD.prazo_vigencia} meses</p>
            </div>
            ` : ''}

            ${this.dadosDFD.periodicidade_revisao ? `
            <div class="secao">
              <h2>PERIODICIDADE DE REVISÃO</h2>
              <p>${this.dadosDFD.periodicidade_revisao}</p>
            </div>
            ` : ''}
          ` : ''}

          ${this.dadosDFD.observacoes_especiais ? `
          <div class="secao">
            <h2>OBSERVAÇÕES ESPECIAIS</h2>
            <p>${this.dadosDFD.observacoes_especiais}</p>
          </div>
          ` : ''}

          <div class="assinatura">
            <p>Data: ${new Date().toLocaleDateString('pt-BR')}</p>
            <br>
            <p>_________________________________________</p>
            <p>Presidente da CPPM</p>
          </div>
        </div>
      `
    }
  },
  
  mounted() {
    console.log('🔧 FormularioDFD mounted:', {
      dfdEditando: !!this.dfdEditando,
      dfdId: this.dfdEditando?.id
    })

    // Se estamos editando um DFD existente, carregar seus dados (SEM perguntar sobre rascunho)
    if (this.dfdEditando) {
      console.log('✏️ Modo edição - carregando dados do DFD:', this.dfdEditando.id)
      this.carregarDadosDFD()
      return
    }

    // Modo novo DFD - configurar padrões
    console.log('🆕 Modo novo DFD')

    // Se for processo de despadronização, selecionar modelo 2 automaticamente
    if (this.tipoProcesso === 'despadronizacao') {
      this.modeloSelecionado = 'modelo_2'
    }

    // NÃO carregar rascunho para evitar confusão - começar sempre limpo para novos DFDs
    console.log('🧹 Iniciando com formulário limpo (novo DFD)')
  },
  
  beforeUnmount() {
    // Limpar timeout de auto-save quando componente for destruído
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
  }
}
</script>

<style scoped>
.dfd-container {
  max-width: 1000px;
  margin: 0 auto;
  padding: 2rem;
}

.dfd-header {
  text-align: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #e2e8f0;
}

.dfd-header h2 {
  color: #2d3748;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #718096;
  margin: 0;
}

.modelo-selector {
  margin-bottom: 2rem;
}

.modelo-selector h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.modelos-opcoes {
  display: grid;
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.modelo-opcao {
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  gap: 1rem;
  align-items: flex-start;
}

.modelo-opcao:hover {
  border-color: #cbd5e0;
  background: #f8fafc;
}

.modelo-opcao.active {
  border-color: #2c3e50;
  background: #f0f9ff;
  box-shadow: 0 4px 12px rgba(44, 62, 80, 0.1);
}

.modelo-icon {
  font-size: 3rem;
  flex-shrink: 0;
}

.modelo-info h4 {
  margin: 0 0 0.5rem 0;
  color: #1f2937;
  font-size: 1.2rem;
}

.modelo-info p {
  margin: 0 0 1rem 0;
  color: #6b7280;
  line-height: 1.5;
}

.modelo-info ul {
  margin: 0;
  padding-left: 1.5rem;
  color: #4b5563;
}

.modelo-info li {
  margin-bottom: 0.25rem;
  font-size: 0.9rem;
}

.dfd-form {
  background: white;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  overflow: hidden;
}

.form-section {
  padding: 2rem;
  border-bottom: 1px solid #f3f4f6;
}

.form-section:last-child {
  border-bottom: none;
}

.form-section h3 {
  color: #2d3748;
  margin: 0 0 1.5rem 0;
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group:last-child {
  margin-bottom: 0;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #374151;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: border-color 0.3s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #2c3e50;
  box-shadow: 0 0 0 3px rgba(44, 62, 80, 0.1);
}

.form-group small {
  display: block;
  margin-top: 0.5rem;
  color: #6b7280;
  font-size: 0.85rem;
  line-height: 1.4;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.modelo-1-fields,
.modelo-2-fields,
.modelo-geral-fields {
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.form-actions {
  padding: 2rem;
  background: #f8fafc;
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  border-top: 1px solid #e2e8f0;
}

.btn-primary,
.btn-secondary,
.btn-outline {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
}

.btn-primary {
  background: #2c3e50;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #34495e;
  transform: translateY(-1px);
}

.btn-primary:disabled {
  background: #a0aec0;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover {
  background: #cbd5e0;
}

.btn-outline {
  background: white;
  color: #2c3e50;
  border: 2px solid #2c3e50;
}

.btn-outline:hover:not(:disabled) {
  background: #2c3e50;
  color: white;
}

.btn-outline:disabled {
  border-color: #a0aec0;
  color: #a0aec0;
  cursor: not-allowed;
}

.dfd-preview {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
}

.preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
  background: #2c3e50;
  color: white;
  border-radius: 12px 12px 0 0;
}

.preview-content {
  background: white;
  max-width: 800px;
  max-height: 80vh;
  overflow-y: auto;
  border-radius: 0 0 12px 12px;
  padding: 2rem;
}

.btn-close {
  background: none;
  border: none;
  color: white;
  font-size: 1.5rem;
  cursor: pointer;
}

/* Estilos para o preview do documento */
.documento-dfd h1 {
  text-align: center;
  color: #2d3748;
  margin-bottom: 2rem;
  font-size: 1.5rem;
}

.documento-dfd .secao {
  margin-bottom: 2rem;
}

.documento-dfd .secao h2 {
  color: #2c3e50;
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 0.25rem;
}

.documento-dfd .secao p {
  color: #4a5568;
  line-height: 1.6;
  margin: 0;
}

.documento-dfd .assinatura {
  margin-top: 3rem;
  text-align: center;
  color: #6b7280;
}

.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-top: 0.5rem;
}

.checkbox-item {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  font-weight: normal !important;
  margin-bottom: 0 !important;
  cursor: pointer;
}

.checkbox-item input[type="checkbox"] {
  width: auto;
  margin: 0;
  margin-top: 2px;
  flex-shrink: 0;
}

.checkbox-item:hover {
  color: #2c3e50;
}

@media (max-width: 768px) {
  .dfd-container {
    padding: 1rem;
  }

  .modelos-opcoes {
    grid-template-columns: 1fr;
  }

  .modelo-opcao {
    flex-direction: column;
    text-align: center;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .form-actions {
    flex-direction: column;
  }

  .dfd-preview {
    padding: 1rem;
  }

  .preview-content {
    padding: 1rem;
  }
}
</style>