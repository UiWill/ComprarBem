<template>
  <div class="gerenciador-analise-precos">
    <!-- Cabeçalho com ações principais -->
    <div class="analise-header">
      <div class="header-info">
        <h4>📈 Gerenciamento de Análise de Preços</h4>
        <p>Analise variações de preços ao longo do tempo, identifique tendências e tome decisões baseadas em dados estatísticos.</p>
      </div>
      
      <div class="header-actions">
        <button @click="abrirModalNovaAnalise" class="btn-primary">
          ➕ Nova Análise
        </button>
        <button @click="gerarRelatorioConsolidado" class="btn-secondary">
          📊 Relatório Consolidado
        </button>
        <button @click="exportarDados" class="btn-secondary">
          📤 Exportar Dados
        </button>
      </div>
    </div>

    <!-- Filtros e busca -->
    <div class="analise-filtros">
      <div class="filtros-row">
        <div class="filtro-group">
          <label>Buscar:</label>
          <input 
            v-model="filtros.busca" 
            type="text" 
            placeholder="Título, categoria ou produto..."
            class="input-field"
          >
        </div>
        
        <div class="filtro-group">
          <label>Status:</label>
          <select v-model="filtros.status" class="select-field">
            <option value="">Todos</option>
            <option value="processando">Processando</option>
            <option value="concluida">Concluída</option>
            <option value="erro">Erro</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>Tipo:</label>
          <select v-model="filtros.tipo" class="select-field">
            <option value="">Todos</option>
            <option value="temporal">Temporal</option>
            <option value="comparativa">Comparativa</option>
            <option value="estatistica">Estatística</option>
            <option value="tendencia">Tendência</option>
          </select>
        </div>
        
        <div class="filtro-group-periodo">
          <label>Período:</label>
          <div class="periodo-inputs">
            <input 
              v-model="filtros.dataInicio" 
              type="date" 
              class="input-field"
              placeholder="Data inicial"
            >
            <span class="periodo-separador">até</span>
            <input 
              v-model="filtros.dataFim" 
              type="date" 
              class="input-field"
              placeholder="Data final"
            >
          </div>
        </div>
        
        <button @click="limparFiltros" class="btn-ghost">
          🗑️ Limpar
        </button>
      </div>
    </div>

    <!-- Métricas em destaque -->
    <div class="metricas-destaque" v-if="!loading && analises.length > 0">
      <div class="metrica-card">
        <div class="metrica-icon">📊</div>
        <div class="metrica-content">
          <h4>{{ analises.length }}</h4>
          <p>Análises Realizadas</p>
        </div>
      </div>
      
      <div class="metrica-card">
        <div class="metrica-icon">📈</div>
        <div class="metrica-content">
          <h4>{{ analisesComTendencia }}</h4>
          <p>Com Tendências</p>
        </div>
      </div>
      
      <div class="metrica-card">
        <div class="metrica-icon">⚠️</div>
        <div class="metrica-content">
          <h4>{{ alertasAtivos }}</h4>
          <p>Alertas Ativos</p>
        </div>
      </div>
      
      <div class="metrica-card">
        <div class="metrica-icon">💰</div>
        <div class="metrica-content">
          <h4>{{ mediaVariacao }}%</h4>
          <p>Variação Média</p>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>Carregando análises...</p>
    </div>

    <!-- Lista de análises -->
    <div v-else class="analises-container">
      <!-- Estado vazio -->
      <div v-if="analisesFiltradas.length === 0 && !temFiltrosAplicados" class="empty-state">
        <div class="empty-icon">📈</div>
        <h3>Nenhuma análise registrada</h3>
        <p>Comece criando análises de preços para identificar tendências e oportunidades de economia.</p>
        <button @click="abrirModalNovaAnalise" class="btn-primary">
          ➕ Criar Primeira Análise
        </button>
      </div>

      <!-- Nenhum resultado encontrado -->
      <div v-else-if="analisesFiltradas.length === 0 && temFiltrosAplicados" class="empty-state">
        <div class="empty-icon">🔍</div>
        <h3>Nenhuma análise encontrada</h3>
        <p>Nenhuma análise corresponde aos filtros aplicados.</p>
        <button @click="limparFiltros" class="btn-secondary">
          🗑️ Limpar Filtros
        </button>
      </div>

      <!-- Grid de análises -->
      <div v-else class="analises-grid">
        <div 
          v-for="analise in analisesFiltradas" 
          :key="analise.id"
          class="analise-card"
          :class="{ 
            'concluida': analise.status === 'concluida',
            'erro': analise.status === 'erro',
            'processando': analise.status === 'processando'
          }"
        >
          <!-- Cabeçalho da análise -->
          <div class="analise-header-card">
            <div class="analise-info">
              <h5>{{ analise.titulo }}</h5>
              <div class="analise-meta">
                <span class="categoria">{{ analise.categoria || 'Sem categoria' }}</span>
                <span class="tipo">{{ getTipoLabel(analise.tipo_analise) }}</span>
                <span class="status" :class="analise.status">{{ getStatusLabel(analise.status) }}</span>
              </div>
            </div>
            <div class="analise-progresso" v-if="analise.status === 'processando'">
              <div class="progress-bar">
                <div 
                  class="progress-fill" 
                  :style="{ width: analise.progresso + '%' }"
                ></div>
              </div>
              <span class="progress-text">{{ analise.progresso }}%</span>
            </div>
          </div>

          <!-- Métricas da análise -->
          <div class="analise-metricas" v-if="analise.status === 'concluida'">
            <div class="metrica-item">
              <span class="label">Período:</span>
              <span class="value">{{ formatPeriodo(analise.periodo_inicio, analise.periodo_fim) }}</span>
            </div>
            <div class="metrica-item" v-if="analise.preco_medio">
              <span class="label">Preço Médio:</span>
              <span class="value">{{ formatCurrency(analise.preco_medio) }}</span>
            </div>
            <div class="metrica-item" v-if="analise.variacao_percentual">
              <span class="label">Variação:</span>
              <span class="value" :class="getVariacaoClass(analise.variacao_percentual)">
                {{ formatPercentual(analise.variacao_percentual) }}
              </span>
            </div>
            <div class="metrica-item" v-if="analise.desvio_padrao">
              <span class="label">Volatilidade:</span>
              <span class="value">{{ formatCurrency(analise.desvio_padrao) }}</span>
            </div>
          </div>

          <!-- Corpo da análise -->
          <div class="analise-body">
            <div class="analise-desc">
              <p v-if="analise.descricao">{{ truncateText(analise.descricao, 120) }}</p>
              <p v-else class="sem-descricao">Sem descrição</p>
            </div>
            
            <div class="analise-detalhes" v-if="analise.status === 'concluida'">
              <div class="detalhe-badges">
                <span class="badge" v-if="analise.preco_minimo && analise.preco_maximo">
                  💰 {{ formatCurrency(analise.preco_minimo) }} - {{ formatCurrency(analise.preco_maximo) }}
                </span>
                <span class="badge" v-if="analise.granularidade">
                  📅 {{ getGranularidadeLabel(analise.granularidade) }}
                </span>
                <span class="badge" v-if="temTendencias(analise.id)">
                  📈 Com Tendências
                </span>
                <span class="badge warning" v-if="temAlertas(analise.id)">
                  ⚠️ Alertas
                </span>
              </div>
            </div>
          </div>

          <!-- Ações da análise -->
          <div class="analise-actions">
            <button @click="visualizarAnalise(analise)" class="btn-small">👁️ Ver</button>
            <button 
              v-if="analise.status === 'concluida'" 
              @click="verGraficos(analise)" 
              class="btn-small"
            >
              📊 Gráficos
            </button>
            <button 
              v-if="analise.status === 'concluida'" 
              @click="verTendencias(analise)" 
              class="btn-small"
            >
              📈 Tendências
            </button>
            <button @click="editarAnalise(analise)" class="btn-small">✏️ Editar</button>
            <button @click="duplicarAnalise(analise)" class="btn-small">📋 Duplicar</button>
            <button 
              v-if="analise.status === 'processando'" 
              @click="cancelarAnalise(analise)" 
              class="btn-small btn-warning"
            >
              ❌ Cancelar
            </button>
            <button @click="removerAnalise(analise)" class="btn-small btn-danger">🗑️ Remover</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Nova/Editar Análise -->
    <div v-if="modalAnalise.show" class="modal-overlay" @click="fecharModalAnalise">
      <div class="modal-content large" @click.stop>
        <div class="modal-header">
          <h3>{{ modalAnalise.editando ? '✏️ Editar Análise' : '➕ Nova Análise de Preços' }}</h3>
          <button @click="fecharModalAnalise" class="btn-close">✕</button>
        </div>
        
        <div class="modal-body">
          <form @submit.prevent="salvarAnalise" class="form-analise">
            <!-- Dados Básicos -->
            <fieldset class="form-section">
              <legend>📋 Dados Básicos</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Título da Análise*</label>
                  <input 
                    v-model="analiseForm.titulo" 
                    type="text" 
                    required 
                    class="input-field"
                    placeholder="Ex: Análise de Notebooks - Q1 2024"
                  >
                </div>
                <div class="form-group">
                  <label>Categoria</label>
                  <input 
                    v-model="analiseForm.categoria" 
                    type="text" 
                    class="input-field"
                    placeholder="Ex: Informática, Móveis, Veículos"
                  >
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group full-width">
                  <label>Descrição</label>
                  <textarea 
                    v-model="analiseForm.descricao" 
                    class="textarea-field"
                    rows="3"
                    placeholder="Descreva o objetivo e escopo da análise..."
                  ></textarea>
                </div>
              </div>
            </fieldset>

            <!-- Configurações da Análise -->
            <fieldset class="form-section">
              <legend>⚙️ Configurações da Análise</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Tipo de Análise*</label>
                  <select v-model="analiseForm.tipo_analise" required class="select-field">
                    <option value="temporal">Temporal (evolução no tempo)</option>
                    <option value="comparativa">Comparativa (entre produtos)</option>
                    <option value="estatistica">Estatística (distribuições)</option>
                    <option value="tendencia">Tendência (previsões)</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Granularidade</label>
                  <select v-model="analiseForm.granularidade" class="select-field">
                    <option value="diaria">Diária</option>
                    <option value="semanal">Semanal</option>
                    <option value="mensal">Mensal</option>
                    <option value="trimestral">Trimestral</option>
                    <option value="anual">Anual</option>
                  </select>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>Data Início*</label>
                  <input 
                    v-model="analiseForm.periodo_inicio" 
                    type="date" 
                    required
                    class="input-field"
                  >
                </div>
                <div class="form-group">
                  <label>Data Fim*</label>
                  <input 
                    v-model="analiseForm.periodo_fim" 
                    type="date" 
                    required
                    class="input-field"
                  >
                </div>
              </div>
            </fieldset>

            <!-- Filtros de Dados -->
            <fieldset class="form-section">
              <legend>🔍 Filtros de Dados</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Produtos Específicos</label>
                  <input 
                    v-model="filtrosProdutos" 
                    type="text" 
                    class="input-field"
                    placeholder="Digite nomes de produtos separados por vírgula"
                  >
                  <small class="form-help">Deixe vazio para incluir todos os produtos</small>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>Fornecedores Específicos</label>
                  <input 
                    v-model="filtrosFornecedores" 
                    type="text" 
                    class="input-field"
                    placeholder="Digite nomes de fornecedores separados por vírgula"
                  >
                  <small class="form-help">Deixe vazio para incluir todos os fornecedores</small>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>Faixa de Preços</label>
                  <div class="price-range">
                    <input 
                      v-model.number="faixaPrecos.min" 
                      type="number" 
                      step="0.01"
                      class="input-field"
                      placeholder="Preço mínimo"
                    >
                    <span>até</span>
                    <input 
                      v-model.number="faixaPrecos.max" 
                      type="number" 
                      step="0.01"
                      class="input-field"
                      placeholder="Preço máximo"
                    >
                  </div>
                </div>
              </div>
            </fieldset>
          </form>
        </div>
        
        <div class="modal-footer">
          <button @click="fecharModalAnalise" class="btn-secondary">Cancelar</button>
          <button @click="salvarAnalise" class="btn-primary" :disabled="salvandoAnalise">
            {{ salvandoAnalise ? 'Processando...' : 'Iniciar Análise' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Visualizar Análise -->
    <div v-if="modalVisualizacao.show" class="modal-overlay" @click="fecharModalVisualizacao">
      <div class="modal-content extra-large" @click.stop>
        <div class="modal-header">
          <h3>📊 {{ modalVisualizacao.analise?.titulo }}</h3>
          <button @click="fecharModalVisualizacao" class="btn-close">✕</button>
        </div>
        
        <div class="modal-body">
          <div class="analise-detalhada" v-if="modalVisualizacao.analise">
            <!-- Resumo Executivo -->
            <div class="resumo-executivo">
              <h4>📈 Resumo Executivo</h4>
              <div class="resumo-grid">
                <div class="resumo-item">
                  <span class="label">Período Analisado:</span>
                  <span class="value">{{ formatPeriodo(modalVisualizacao.analise.periodo_inicio, modalVisualizacao.analise.periodo_fim) }}</span>
                </div>
                <div class="resumo-item">
                  <span class="label">Tipo de Análise:</span>
                  <span class="value">{{ getTipoLabel(modalVisualizacao.analise.tipo_analise) }}</span>
                </div>
                <div class="resumo-item">
                  <span class="label">Granularidade:</span>
                  <span class="value">{{ getGranularidadeLabel(modalVisualizacao.analise.granularidade) }}</span>
                </div>
                <div class="resumo-item">
                  <span class="label">Status:</span>
                  <span class="value">{{ getStatusLabel(modalVisualizacao.analise.status) }}</span>
                </div>
              </div>
            </div>

            <!-- Métricas Principais -->
            <div class="metricas-principais" v-if="modalVisualizacao.analise.status === 'concluida'">
              <h4>📊 Métricas Principais</h4>
              <div class="metricas-grid">
                <div class="metrica-detalhada">
                  <div class="metrica-icon">💰</div>
                  <div class="metrica-content">
                    <h5>{{ formatCurrency(modalVisualizacao.analise.preco_medio || 0) }}</h5>
                    <p>Preço Médio</p>
                  </div>
                </div>
                <div class="metrica-detalhada">
                  <div class="metrica-icon">📈</div>
                  <div class="metrica-content">
                    <h5 :class="getVariacaoClass(modalVisualizacao.analise.variacao_percentual)">
                      {{ formatPercentual(modalVisualizacao.analise.variacao_percentual || 0) }}
                    </h5>
                    <p>Variação Total</p>
                  </div>
                </div>
                <div class="metrica-detalhada">
                  <div class="metrica-icon">📊</div>
                  <div class="metrica-content">
                    <h5>{{ formatCurrency(modalVisualizacao.analise.desvio_padrao || 0) }}</h5>
                    <p>Desvio Padrão</p>
                  </div>
                </div>
                <div class="metrica-detalhada">
                  <div class="metrica-icon">🎯</div>
                  <div class="metrica-content">
                    <h5>{{ formatPercentual(modalVisualizacao.analise.coeficiente_variacao || 0) }}</h5>
                    <p>Coef. Variação</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Placeholder para gráficos -->
            <div class="graficos-section" v-if="modalVisualizacao.analise.status === 'concluida'">
              <h4>📈 Visualizações</h4>
              <div class="graficos-placeholder">
                <div class="placeholder-box">
                  <div class="placeholder-icon">📊</div>
                  <h5>Gráficos em desenvolvimento</h5>
                  <p>Em breve: gráficos interativos de evolução de preços, histogramas e box plots</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase, getTenantId } from '@/services/supabase'

export default {
  name: 'GerenciadorAnalisePrecos',
  data() {
    return {
      analises: [],
      loading: false,
      salvandoAnalise: false,
      
      // Filtros
      filtros: {
        busca: '',
        status: '',
        tipo: '',
        dataInicio: '',
        dataFim: ''
      },
      
      // Modal Nova/Editar Análise
      modalAnalise: {
        show: false,
        editando: false
      },
      
      // Modal Visualização
      modalVisualizacao: {
        show: false,
        analise: null
      },
      
      // Formulário de análise
      analiseForm: {
        id: null,
        titulo: '',
        descricao: '',
        categoria: '',
        tipo_analise: 'temporal',
        granularidade: 'mensal',
        periodo_inicio: '',
        periodo_fim: ''
      },
      
      // Filtros de dados
      filtrosProdutos: '',
      filtrosFornecedores: '',
      faixaPrecos: {
        min: null,
        max: null
      }
    }
  },
  
  computed: {
    analisesFiltradas() {
      let resultado = [...this.analises]
      
      // Filtro de busca
      if (this.filtros.busca) {
        const busca = this.filtros.busca.toLowerCase()
        resultado = resultado.filter(analise => 
          analise.titulo.toLowerCase().includes(busca) ||
          (analise.categoria && analise.categoria.toLowerCase().includes(busca)) ||
          (analise.descricao && analise.descricao.toLowerCase().includes(busca))
        )
      }
      
      // Filtro de status
      if (this.filtros.status) {
        resultado = resultado.filter(analise => analise.status === this.filtros.status)
      }
      
      // Filtro de tipo
      if (this.filtros.tipo) {
        resultado = resultado.filter(analise => analise.tipo_analise === this.filtros.tipo)
      }
      
      // Filtro de data
      if (this.filtros.dataInicio) {
        resultado = resultado.filter(analise => analise.periodo_inicio >= this.filtros.dataInicio)
      }
      
      if (this.filtros.dataFim) {
        resultado = resultado.filter(analise => analise.periodo_fim <= this.filtros.dataFim)
      }
      
      return resultado.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    },
    
    temFiltrosAplicados() {
      return this.filtros.busca || this.filtros.status || this.filtros.tipo || this.filtros.dataInicio || this.filtros.dataFim
    },
    
    // Métricas de destaque
    analisesComTendencia() {
      return this.analises.filter(a => a.status === 'concluida').length
    },
    
    alertasAtivos() {
      return Math.floor(Math.random() * 5) // Placeholder
    },
    
    mediaVariacao() {
      const analisesCompletas = this.analises.filter(a => a.status === 'concluida' && a.variacao_percentual)
      if (analisesCompletas.length === 0) return 0
      
      const soma = analisesCompletas.reduce((acc, a) => acc + (a.variacao_percentual || 0), 0)
      return (soma / analisesCompletas.length).toFixed(1)
    }
  },
  
  async mounted() {
    await this.carregarAnalises()
    this.definirDatasPadrao()
  },
  
  methods: {
    async carregarAnalises() {
      this.loading = true
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const { data, error } = await supabase
          .from('analises_precos')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', { ascending: false })
        
        if (error) throw error
        
        this.analises = data || []
      } catch (error) {
        console.error('Erro ao carregar análises:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao carregar análises: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.loading = false
      }
    },
    
    // Modais
    abrirModalNovaAnalise() {
      this.modalAnalise.show = true
      this.modalAnalise.editando = false
      this.resetarFormulario()
    },
    
    fecharModalAnalise() {
      this.modalAnalise.show = false
      this.resetarFormulario()
    },
    
    fecharModalVisualizacao() {
      this.modalVisualizacao.show = false
      this.modalVisualizacao.analise = null
    },
    
    resetarFormulario() {
      this.analiseForm = {
        id: null,
        titulo: '',
        descricao: '',
        categoria: '',
        tipo_analise: 'temporal',
        granularidade: 'mensal',
        periodo_inicio: '',
        periodo_fim: ''
      }
      this.filtrosProdutos = ''
      this.filtrosFornecedores = ''
      this.faixaPrecos = { min: null, max: null }
    },
    
    definirDatasPadrao() {
      const hoje = new Date()
      const inicioAno = new Date(hoje.getFullYear(), 0, 1)
      
      this.analiseForm.periodo_fim = hoje.toISOString().split('T')[0]
      this.analiseForm.periodo_inicio = inicioAno.toISOString().split('T')[0]
    },
    
    // CRUD
    async salvarAnalise() {
      this.salvandoAnalise = true
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        // Preparar filtros
        const filtros = {}
        if (this.filtrosProdutos) {
          filtros.produtos = this.filtrosProdutos.split(',').map(p => p.trim())
        }
        if (this.filtrosFornecedores) {
          filtros.fornecedores = this.filtrosFornecedores.split(',').map(f => f.trim())
        }
        if (this.faixaPrecos.min || this.faixaPrecos.max) {
          filtros.faixa_precos = this.faixaPrecos
        }
        
        const analiseData = {
          ...this.analiseForm,
          tenant_id: tenantId,
          filtros_aplicados: Object.keys(filtros).length > 0 ? filtros : null,
          status: 'processando',
          progresso: 0
        }
        
        if (this.modalAnalise.editando) {
          const { error } = await supabase
            .from('analises_precos')
            .update(analiseData)
            .eq('id', this.analiseForm.id)
          
          if (error) throw error
        } else {
          delete analiseData.id
          const { error } = await supabase
            .from('analises_precos')
            .insert([analiseData])
          
          if (error) throw error
        }
        
        this.$swal({
          title: 'Sucesso!',
          text: `Análise ${this.modalAnalise.editando ? 'atualizada' : 'iniciada'} com sucesso`,
          icon: 'success',
          timer: 2000
        })
        
        await this.carregarAnalises()
        this.fecharModalAnalise()
        
      } catch (error) {
        console.error('Erro ao salvar análise:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao salvar análise: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.salvandoAnalise = false
      }
    },
    
    editarAnalise(analise) {
      this.analiseForm = { ...analise }
      this.modalAnalise.show = true
      this.modalAnalise.editando = true
    },
    
    async removerAnalise(analise) {
      const confirm = await this.$swal({
        title: 'Confirmar exclusão',
        text: `Deseja realmente remover a análise "${analise.titulo}"?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sim, remover',
        cancelButtonText: 'Cancelar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('analises_precos')
            .delete()
            .eq('id', analise.id)
          
          if (error) throw error
          
          this.$swal({
            title: 'Removida!',
            text: 'Análise removida com sucesso',
            icon: 'success',
            timer: 2000
          })
          
          await this.carregarAnalises()
        } catch (error) {
          console.error('Erro ao remover análise:', error)
          this.$swal({
            title: 'Erro',
            text: 'Erro ao remover análise: ' + error.message,
            icon: 'error'
          })
        }
      }
    },
    
    // Ações específicas
    visualizarAnalise(analise) {
      this.modalVisualizacao.show = true
      this.modalVisualizacao.analise = analise
    },
    
    duplicarAnalise(analise) {
      this.analiseForm = {
        ...analise,
        id: null,
        titulo: analise.titulo + ' (Cópia)',
        status: 'processando'
      }
      this.modalAnalise.show = true
      this.modalAnalise.editando = false
    },
    
    async cancelarAnalise(analise) {
      const confirm = await this.$swal({
        title: 'Cancelar Análise',
        text: `Deseja cancelar o processamento da análise "${analise.titulo}"?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Sim, cancelar',
        cancelButtonText: 'Continuar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('analises_precos')
            .update({ status: 'erro', progresso: 0 })
            .eq('id', analise.id)
          
          if (error) throw error
          
          await this.carregarAnalises()
        } catch (error) {
          console.error('Erro ao cancelar análise:', error)
        }
      }
    },
    
    verGraficos(analise) {
      this.$swal({
        title: '📊 Gráficos da Análise',
        text: 'Funcionalidade em desenvolvimento - Visualizações gráficas interativas',
        icon: 'info'
      })
    },
    
    verTendencias(analise) {
      this.$swal({
        title: '📈 Análise de Tendências',
        text: 'Funcionalidade em desenvolvimento - Detecção automática de tendências',
        icon: 'info'
      })
    },
    
    // Filtros
    limparFiltros() {
      this.filtros = {
        busca: '',
        status: '',
        tipo: '',
        dataInicio: '',
        dataFim: ''
      }
    },
    
    // Exportação
    async gerarRelatorioConsolidado() {
      try {
        if (this.analisesFiltradas.length === 0) {
          this.$swal({
            title: 'Atenção',
            text: 'Não há análises para incluir no relatório com os filtros aplicados.',
            icon: 'warning'
          })
          return
        }

        // Confirmar geração do relatório
        const confirmacao = await this.$swal({
          title: '📊 Gerar Relatório Consolidado',
          html: `
            <div style="text-align: left; margin: 20px 0;">
              <p><strong>Análises a serem incluídas:</strong> ${this.analisesFiltradas.length}</p>
              <p><strong>Análises concluídas:</strong> ${this.analisesFiltradas.filter(a => a.status === 'concluida').length}</p>
              <br>
              <p>O relatório será aberto em uma nova janela e poderá ser impresso ou salvo como PDF.</p>
            </div>
          `,
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: '📊 Gerar Relatório',
          cancelButtonText: 'Cancelar'
        })

        if (!confirmacao.isConfirmed) return

        // Importar serviço de relatório
        const { gerarRelatorioAnalisePrecos } = await import('@/services/relatorioService')
        
        // Gerar relatório
        await gerarRelatorioAnalisePrecos(this.analisesFiltradas, 'Relatório Consolidado de Análise de Preços')
        
        this.$swal({
          title: 'Sucesso!',
          text: 'Relatório consolidado gerado com sucesso!',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao gerar relatório:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao gerar relatório: ' + error.message,
          icon: 'error'
        })
      }
    },
    
    async exportarDados() {
      try {
        if (this.analisesFiltradas.length === 0) {
          this.$swal({
            title: 'Atenção',
            text: 'Não há dados para exportar com os filtros aplicados.',
            icon: 'warning'
          })
          return
        }

        // Perguntar formato de exportação
        const { value: formato } = await this.$swal({
          title: '📤 Exportar Dados de Análise',
          text: `Exportar dados de ${this.analisesFiltradas.length} análise(s). Escolha o formato:`,
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: '📊 Excel (.xlsx)',
          cancelButtonText: '📄 CSV (.csv)',
          showDenyButton: true,
          denyButtonText: 'Cancelar',
          reverseButtons: true
        })

        if (formato === undefined) return // Cancelou

        // Importar serviço de exportação
        const { exportAnalises } = await import('@/services/exportService')
        
        // Exportar
        const tipoExport = formato ? 'excel' : 'csv'
        await exportAnalises(this.analisesFiltradas, tipoExport)
        
        this.$swal({
          title: 'Sucesso!',
          text: `Dados de ${this.analisesFiltradas.length} análise(s) exportados com sucesso!`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao exportar dados:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao exportar dados: ' + error.message,
          icon: 'error'
        })
      }
    },
    
    // Utilitários
    temTendencias(analiseId) {
      return Math.random() > 0.5 // Placeholder
    },
    
    temAlertas(analiseId) {
      return Math.random() > 0.7 // Placeholder
    },
    
    truncateText(text, maxLength) {
      if (!text) return ''
      return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
    },
    
    getVariacaoClass(variacao) {
      if (!variacao) return ''
      if (variacao > 5) return 'positiva'
      if (variacao < -5) return 'negativa'
      return 'neutra'
    },
    
    // Formatação
    formatDate(date) {
      if (!date) return ''
      return new Date(date).toLocaleDateString('pt-BR')
    },
    
    formatPeriodo(inicio, fim) {
      return `${this.formatDate(inicio)} - ${this.formatDate(fim)}`
    },
    
    formatCurrency(value) {
      if (!value) return 'R$ 0,00'
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
      }).format(value)
    },
    
    formatPercentual(value) {
      if (!value) return '0%'
      return (value > 0 ? '+' : '') + value.toFixed(1) + '%'
    },
    
    getStatusLabel(status) {
      const labels = {
        'processando': 'Processando',
        'concluida': 'Concluída',
        'erro': 'Erro'
      }
      return labels[status] || status
    },
    
    getTipoLabel(tipo) {
      const labels = {
        'temporal': 'Temporal',
        'comparativa': 'Comparativa',
        'estatistica': 'Estatística',
        'tendencia': 'Tendência'
      }
      return labels[tipo] || tipo
    },
    
    getGranularidadeLabel(granularidade) {
      const labels = {
        'diaria': 'Diária',
        'semanal': 'Semanal',
        'mensal': 'Mensal',
        'trimestral': 'Trimestral',
        'anual': 'Anual'
      }
      return labels[granularidade] || granularidade
    }
  }
}
</script>

<style scoped>
@import './GerenciadorAnalisePrecos.css';
</style>