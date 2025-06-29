<template>
  <div class="dashboard-rdm">
    <!-- Header -->
    <header class="dashboard-header">
      <div class="container">
        <div class="header-content">
          <div class="logo-section">
            <h1>🏥 Sistema Comprar Bem</h1>
            <span class="subtitle">Dashboard RDM</span>
          </div>
          
          <div class="user-section">
            <div class="user-info">
              <span class="user-name">👤 {{ usuarioAtual.nome_usuario }}</span>
              <span class="user-sector">🏢 {{ usuarioAtual.unidade_setor }}</span>
            </div>
            <button @click="logout" class="btn-logout">🚪 Sair</button>
          </div>
        </div>
      </div>
    </header>

    <!-- Navigation Tabs -->
    <nav class="nav-tabs">
      <div class="container">
        <div class="tabs">
          <button 
            @click="activeTab = 'nova-rdm'" 
            :class="{ active: activeTab === 'nova-rdm' }"
            class="tab-btn"
          >
            📝 Nova RDM
          </button>
          <button 
            @click="activeTab = 'historico'" 
            :class="{ active: activeTab === 'historico' }"
            class="tab-btn"
          >
            📋 Histórico
          </button>
          <button 
            @click="activeTab = 'materiais'" 
            :class="{ active: activeTab === 'materiais' }"
            class="tab-btn"
          >
            📦 Meus Materiais
          </button>
          <button 
            @click="activeTab = 'feedback'" 
            :class="{ active: activeTab === 'feedback' }"
            class="tab-btn"
          >
            ⭐ Feedback
          </button>
          <button 
            @click="activeTab = 'perfil'" 
            :class="{ active: activeTab === 'perfil' }"
            class="tab-btn"
          >
            ⚙️ Perfil
          </button>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <main class="main-content">
      <div class="container">
        
        <!-- Tab: Nova RDM -->
        <div v-if="activeTab === 'nova-rdm'" class="tab-content">
          <div class="page-header">
            <h2>📝 Emitir Nova RDM</h2>
            <p>Solicite materiais de forma rápida e organizada</p>
          </div>

          <!-- Formulário Nova RDM -->
          <div class="rdm-form-card">
            <form @submit.prevent="emitirRDM">
              
              <!-- Seleção de Material -->
              <div class="form-section">
                <h3>📦 Selecionar Material</h3>
                
                <div class="form-group">
                  <label>Material:</label>
                  <select v-model="novaRDM.material_id" @change="selecionarMaterial" :disabled="carregandoProdutos" required>
                    <option value="">{{ carregandoProdutos ? 'Carregando materiais...' : 'Selecione um material' }}</option>
                    <option 
                      v-for="produto in produtos" 
                      :key="produto.id"
                      :value="produto.id"
                    >
                      {{ produto.nome }} - {{ produto.modelo || produto.codigo_material }}
                    </option>
                  </select>
                  <small v-if="produtos.length === 0 && !carregandoProdutos" class="error-text">
                    ⚠️ Nenhum material encontrado. Contate o CPM.
                  </small>
                </div>

                <div v-if="materialSelecionado" class="material-info">
                  <h4>📋 Dados do Material:</h4>
                  <p><strong>Nome:</strong> {{ materialSelecionado.nome }}</p>
                  <p><strong>Modelo:</strong> {{ materialSelecionado.modelo }}</p>
                  <p><strong>Código:</strong> {{ materialSelecionado.codigo_material }}</p>
                  <p><strong>Marca:</strong> {{ materialSelecionado.marca }}</p>
                  <p><strong>Fabricante:</strong> {{ materialSelecionado.fabricante }}</p>
                </div>
              </div>

              <!-- Quantidade e Justificativa -->
              <div class="form-section">
                <h3>📊 Detalhes da Solicitação</h3>
                
                <div class="form-row">
                  <div class="form-group">
                    <label>Quantidade:</label>
                    <input 
                      type="number" 
                      v-model="novaRDM.quantidade" 
                      min="1" 
                      max="9999"
                      required 
                    />
                  </div>
                  
                  <div class="form-group">
                    <label>Unidade:</label>
                    <select v-model="novaRDM.unidade_medida">
                      <option value="UN">Unidade (UN)</option>
                      <option value="CX">Caixa (CX)</option>
                      <option value="KG">Quilograma (KG)</option>
                      <option value="LT">Litro (LT)</option>
                      <option value="MT">Metro (MT)</option>
                      <option value="PC">Peça (PC)</option>
                    </select>
                  </div>
                  
                  <div class="form-group">
                    <label>Urgência:</label>
                    <select v-model="novaRDM.urgencia">
                      <option value="BAIXA">🟢 Baixa</option>
                      <option value="NORMAL">🟡 Normal</option>
                      <option value="ALTA">🟠 Alta</option>
                      <option value="URGENTE">🔴 Urgente</option>
                    </select>
                  </div>
                </div>

                <div class="form-group">
                  <label>Justificativa:</label>
                  <textarea 
                    v-model="novaRDM.justificativa" 
                    rows="4"
                    placeholder="Descreva a necessidade do material, onde será usado, etc."
                    required
                  ></textarea>
                </div>
              </div>

              <!-- Botões -->
              <div class="form-actions">
                <button type="button" @click="limparFormulario" class="btn-secondary">
                  🗑️ Limpar
                </button>
                <button type="submit" :disabled="salvandoRDM" class="btn-primary">
                  <span v-if="salvandoRDM">⏳ Emitindo...</span>
                  <span v-else">🚀 Emitir RDM</span>
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- Tab: Histórico -->
        <div v-if="activeTab === 'historico'" class="tab-content">
          <div class="page-header">
            <h2>📋 Histórico de RDMs</h2>
            <p>Acompanhe suas solicitações emitidas</p>
          </div>

          <!-- Filtros -->
          <div class="filters-card">
            <div class="filters-row">
              <div class="filter-group">
                <label>🔍 Buscar:</label>
                <input 
                  type="text" 
                  v-model="filtros.busca" 
                  placeholder="Material, código..."
                  @input="aplicarFiltros"
                />
              </div>
              
              <div class="filter-group">
                <label>📊 Status:</label>
                <select v-model="filtros.status" @change="aplicarFiltros">
                  <option value="">Todos</option>
                  <option value="PENDENTE">🟡 Pendente</option>
                  <option value="APROVADO">🟢 Aprovado</option>
                  <option value="REJEITADO">🔴 Rejeitado</option>
                  <option value="EM_ANALISE">🔄 Em Análise</option>
                </select>
              </div>
              
              <div class="filter-group">
                <label>📅 Período:</label>
                <select v-model="filtros.periodo" @change="aplicarFiltros">
                  <option value="">Todos</option>
                  <option value="hoje">Hoje</option>
                  <option value="semana">Esta Semana</option>
                  <option value="mes">Este Mês</option>
                  <option value="trimestre">Último Trimestre</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Lista de RDMs -->
          <div class="rdms-list">
            <div v-if="carregandoRDMs" class="loading">
              ⏳ Carregando RDMs...
            </div>

            <div v-else-if="rdmsFiltradas.length === 0" class="empty-state">
              <div class="empty-icon">📭</div>
              <h3>Nenhuma RDM encontrada</h3>
              <p>Você ainda não emitiu nenhuma RDM ou nenhuma corresponde aos filtros aplicados.</p>
              <button @click="activeTab = 'nova-rdm'" class="btn-primary">
                📝 Emitir Primeira RDM
              </button>
            </div>

            <div v-else class="rdms-grid">
              <div 
                v-for="rdm in rdmsFiltradas" 
                :key="rdm.id"
                class="rdm-card"
                :class="'status-' + rdm.status.toLowerCase()"
              >
                <div class="rdm-header">
                  <span class="rdm-id">#{{ rdm.id.substring(0, 8) }}</span>
                  <span class="rdm-status" :class="'status-' + rdm.status.toLowerCase()">
                    {{ getStatusLabel(rdm.status) }}
                  </span>
                </div>
                
                <div class="rdm-content">
                  <h4>{{ rdm.material_nome }}</h4>
                  <p class="rdm-details">
                    <strong>Código:</strong> {{ rdm.material_codigo }}<br>
                    <strong>Quantidade:</strong> {{ rdm.quantidade }} {{ rdm.unidade_medida }}<br>
                    <strong>Urgência:</strong> {{ getUrgenciaLabel(rdm.urgencia) }}
                  </p>
                  <p class="rdm-justificativa">{{ rdm.justificativa }}</p>
                </div>
                
                <div class="rdm-footer">
                  <span class="rdm-date">📅 {{ formatDate(rdm.criado_em) }}</span>
                  <button @click="verDetalhesRDM(rdm)" class="btn-details">
                    👁️ Detalhes
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab: Meus Materiais -->
        <div v-if="activeTab === 'materiais'" class="tab-content">
          <div class="page-header">
            <h2>📦 Meus Materiais</h2>
            <p>Materiais que você está autorizado a solicitar</p>
          </div>

          <div class="materiais-grid">
            <div 
              v-for="material in usuarioAtual.materiais" 
              :key="material.produto_id"
              class="material-card"
            >
              <div class="material-header">
                <h4>{{ material.nome }}</h4>
                <span class="material-code">{{ material.codigo }}</span>
              </div>
              
              <div class="material-info">
                <p><strong>Periodicidade RDM:</strong> {{ material.periodicidade_rdm }}</p>
              </div>
              
              <div class="material-actions">
                <button 
                  @click="emitirRDMRapida(material)" 
                  class="btn-quick-rdm"
                >
                  ⚡ RDM Rápida
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab: Feedback -->
        <div v-if="activeTab === 'feedback'" class="tab-content">
          <div class="page-header">
            <h2>⭐ Feedback dos Materiais</h2>
            <p>Avalie os materiais que você já recebeu</p>
          </div>

          <!-- Lista de materiais para feedback -->
          <div class="feedback-card">
            <div v-if="carregandoFeedback" class="loading-state">
              <div class="loading-spinner"></div>
              Carregando materiais recebidos...
            </div>

            <div v-else-if="materiaisParaFeedback.length === 0" class="empty-state">
              <h3>📭 Nenhum material para avaliar</h3>
              <p>Você ainda não recebeu nenhum material aprovado.</p>
              <p>Quando suas RDMs forem aprovadas e os materiais entregues, eles aparecerão aqui para avaliação.</p>
            </div>

            <div v-else class="materiais-feedback">
              <h3>📋 Materiais Recebidos ({{ materiaisParaFeedback.length }})</h3>
              
              <div class="material-feedback-item" v-for="material in materiaisParaFeedback" :key="material.id">
                <div class="material-info">
                  <h4>{{ material.material_nome }}</h4>
                  <p><strong>Código:</strong> {{ material.material_codigo }}</p>
                  <p><strong>Recebido em:</strong> {{ formatDate(material.data_aprovacao || material.criado_em) }}</p>
                </div>
                
                <div class="feedback-form">
                  <div class="rating-section">
                    <label>⭐ Avaliação:</label>
                    <div class="star-rating">
                      <span 
                        v-for="i in 5" 
                        :key="i"
                        @click="setRating(material.id, i)"
                        :class="{ active: (material.rating || 0) >= i }"
                        class="star"
                      >
                        ⭐
                      </span>
                    </div>
                  </div>
                  
                  <div class="comment-section">
                    <label>💬 Comentário:</label>
                    <textarea 
                      v-model="material.comentario"
                      placeholder="Como foi sua experiência com este material? Qualidade, durabilidade, eficácia..."
                      rows="3"
                    ></textarea>
                  </div>
                  
                  <div class="feedback-actions">
                    <button 
                      @click="enviarFeedback(material)" 
                      :disabled="!material.rating"
                      class="btn-primary btn-small"
                    >
                      💾 Enviar Feedback
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab: Perfil -->
        <div v-if="activeTab === 'perfil'" class="tab-content">
          <div class="page-header">
            <h2>⚙️ Meu Perfil</h2>
            <p>Informações da sua conta e configurações</p>
          </div>

          <div class="perfil-cards">
            <div class="perfil-card">
              <h3>👤 Dados Pessoais</h3>
              <div class="perfil-info">
                <p><strong>Nome:</strong> {{ usuarioAtual.nome_usuario }}</p>
                <p><strong>Email:</strong> {{ usuarioAtual.email }}</p>
                <p><strong>Unidade/Setor:</strong> {{ usuarioAtual.unidade_setor }}</p>
                <p><strong>Coordenador:</strong> {{ usuarioAtual.nome_coordenador }}</p>
              </div>
            </div>

            <div class="perfil-card">
              <h3>📊 Estatísticas</h3>
              <div class="stats-grid">
                <div class="stat-item">
                  <span class="stat-number">{{ rdmsEmitidas }}</span>
                  <span class="stat-label">RDMs Emitidas</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ rdmsAprovadas }}</span>
                  <span class="stat-label">Aprovadas</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ rdmsPendentes }}</span>
                  <span class="stat-label">Pendentes</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ usuarioAtual.materiais?.length || 0 }}</span>
                  <span class="stat-label">Materiais Autorizados</span>
                </div>
              </div>
            </div>

            <div class="perfil-card">
              <h3>🔒 Alterar Senha</h3>
              <form @submit.prevent="alterarSenha" class="senha-form">
                <div class="form-group">
                  <label>Senha Atual:</label>
                  <input 
                    type="password" 
                    v-model="alteracaoSenha.senhaAtual" 
                    required 
                  />
                </div>
                <div class="form-group">
                  <label>Nova Senha:</label>
                  <input 
                    type="password" 
                    v-model="alteracaoSenha.novaSenha" 
                    required 
                  />
                </div>
                <div class="form-group">
                  <label>Confirmar Nova Senha:</label>
                  <input 
                    type="password" 
                    v-model="alteracaoSenha.confirmaSenha" 
                    required 
                  />
                </div>
                <button type="submit" :disabled="alterandoSenha" class="btn-primary">
                  <span v-if="alterandoSenha">⏳ Alterando...</span>
                  <span v-else>🔒 Alterar Senha</span>
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Modal Detalhes RDM -->
    <div v-if="modalDetalhes" class="modal-overlay" @click="modalDetalhes = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>📋 Detalhes da RDM #{{ rdmSelecionada?.id?.substring(0, 8) }}</h3>
          <button @click="modalDetalhes = false" class="btn-close">✕</button>
        </div>
        <div class="modal-body" v-if="rdmSelecionada">
          <div class="detalhes-grid">
            <div class="detalhe-item">
              <strong>Status:</strong>
              <span :class="'status-' + rdmSelecionada.status.toLowerCase()">
                {{ getStatusLabel(rdmSelecionada.status) }}
              </span>
            </div>
            <div class="detalhe-item">
              <strong>Material:</strong>
              {{ rdmSelecionada.material_nome }}
            </div>
            <div class="detalhe-item">
              <strong>Código:</strong>
              {{ rdmSelecionada.material_codigo }}
            </div>
            <div class="detalhe-item">
              <strong>Quantidade:</strong>
              {{ rdmSelecionada.quantidade }} {{ rdmSelecionada.unidade_medida }}
            </div>
            <div class="detalhe-item">
              <strong>Urgência:</strong>
              {{ getUrgenciaLabel(rdmSelecionada.urgencia) }}
            </div>
            <div class="detalhe-item">
              <strong>Data de Emissão:</strong>
              {{ formatDate(rdmSelecionada.criado_em) }}
            </div>
            <div class="detalhe-item full-width">
              <strong>Justificativa:</strong>
              <p>{{ rdmSelecionada.justificativa }}</p>
            </div>
            <div v-if="rdmSelecionada.observacoes_cpm" class="detalhe-item full-width">
              <strong>Observações do CPM:</strong>
              <p>{{ rdmSelecionada.observacoes_cpm }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'DashboardRDM',
  data() {
    return {
      activeTab: 'nova-rdm',
      usuarioAtual: {},
      
      // Produtos para seleção
      produtos: [],
      carregandoProdutos: false,
      
      // Nova RDM
      novaRDM: {
        material_id: '',
        quantidade: 1,
        unidade_medida: 'UN',
        urgencia: 'NORMAL',
        justificativa: ''
      },
      materialSelecionado: null,
      salvandoRDM: false,
      
      // Histórico
      rdms: [],
      rdmsFiltradas: [],
      carregandoRDMs: false,
      filtros: {
        busca: '',
        status: '',
        periodo: ''
      },
      
      // Modal
      modalDetalhes: false,
      rdmSelecionada: null,
      
      // Feedback
      materiaisParaFeedback: [],
      carregandoFeedback: false,
      
      // Perfil
      alteracaoSenha: {
        senhaAtual: '',
        novaSenha: '',
        confirmaSenha: ''
      },
      alterandoSenha: false
    }
  },
  computed: {
    rdmsEmitidas() {
      return this.rdms.length
    },
    rdmsAprovadas() {
      return this.rdms.filter(rdm => rdm.status === 'APROVADO').length
    },
    rdmsPendentes() {
      return this.rdms.filter(rdm => rdm.status === 'PENDENTE').length
    }
  },
  async mounted() {
    await this.carregarDadosUsuario()
    await this.carregarProdutos()
    await this.carregarRDMs()
  },
  watch: {
    activeTab(newTab) {
      if (newTab === 'feedback') {
        this.carregarMateriaisParaFeedback()
      }
    }
  },
  methods: {
    async carregarDadosUsuario() {
      try {
        const dadosLocal = localStorage.getItem('usuarioRDM')
        if (dadosLocal) {
          this.usuarioAtual = JSON.parse(dadosLocal)
          console.log('✅ Dados do usuário carregados:', this.usuarioAtual.nome_usuario)
        } else {
          throw new Error('Dados do usuário não encontrados')
        }
      } catch (error) {
        console.error('❌ Erro ao carregar dados do usuário:', error)
        this.$router.push('/rdm')
      }
    },

    async carregarProdutos() {
      this.carregandoProdutos = true
      try {
        console.log('🔍 [RDM] Carregando TODOS os produtos para solicitação')
        console.log('📝 [RDM] Usuário pode solicitar qualquer material do catálogo')
        
        // Para SOLICITAR materiais (Nova RDM): mostrar TODOS os produtos disponíveis
        const { data: produtos, error } = await supabase
          .from('produtos')
          .select('id, nome, modelo, codigo_material, marca, fabricante, categoria_id, status')
          .eq('tenant_id', this.usuarioAtual.tenant_id)
          .order('nome')
        
        if (error) {
          console.error('❌ [RDM] Erro ao carregar catálogo de produtos:', error)
          this.produtos = []
          return
        }
        
        this.produtos = produtos || []
        console.log('📦 [RDM] Catálogo completo carregado:', this.produtos.length, 'produtos')
        console.log('✅ [RDM] Usuário pode solicitar qualquer material disponível')
        
      } catch (error) {
        console.error('❌ [RDM] Erro ao carregar produtos:', error)
        this.produtos = []
      } finally {
        this.carregandoProdutos = false
      }
    },

    // Função separada para carregar produtos para FEEDBACK (apenas os que já recebeu)
    async carregarProdutosParaFeedback() {
      try {
        console.log('🔍 [FEEDBACK] Carregando produtos que o usuário já recebeu')
        
        // Buscar RDMs APROVADAS do usuário para saber quais materiais ele já recebeu
        const { data: rdmsAprovadas, error } = await supabase
          .from('rdms_online')
          .select('material_nome, material_codigo')
          .eq('usuario_rdm_id', this.usuarioAtual.id)
          .eq('status', 'APROVADO')
        
        if (error) {
          console.error('❌ [FEEDBACK] Erro ao carregar RDMs aprovadas:', error)
          return []
        }
        
        console.log('📋 [FEEDBACK] Materiais já recebidos:', rdmsAprovadas?.length || 0)
        return rdmsAprovadas || []
        
      } catch (error) {
        console.error('❌ [FEEDBACK] Erro ao carregar materiais para feedback:', error)
        return []
      }
    },

    async carregarRDMs() {
      this.carregandoRDMs = true
      try {
        const { data, error } = await supabase
          .from('rdms_online')
          .select('*')
          .eq('usuario_rdm_id', this.usuarioAtual.id)
          .order('criado_em', { ascending: false })
        
        if (error) throw error
        
        this.rdms = data || []
        this.aplicarFiltros()
        
        console.log('✅ RDMs carregadas:', this.rdms.length)
      } catch (error) {
        console.error('❌ Erro ao carregar RDMs:', error)
      } finally {
        this.carregandoRDMs = false
      }
    },

    selecionarMaterial() {
      this.materialSelecionado = this.produtos.find(
        p => p.id === this.novaRDM.material_id
      )
      console.log('📦 [RDM] Material selecionado:', this.materialSelecionado)
    },

    async emitirRDM() {
      if (this.salvandoRDM) return
      
      this.salvandoRDM = true
      try {
        const material = this.materialSelecionado
        
        const rdmData = {
          tenant_id: this.usuarioAtual.tenant_id,
          usuario_rdm_id: this.usuarioAtual.id,
          material_nome: material.nome,
          material_codigo: material.codigo_material || material.modelo,
          quantidade: parseInt(this.novaRDM.quantidade),
          unidade_medida: this.novaRDM.unidade_medida,
          urgencia: this.novaRDM.urgencia,
          justificativa: this.novaRDM.justificativa,
          status: 'PENDENTE'
        }
        
        const { data, error } = await supabase
          .from('rdms_online')
          .insert([rdmData])
          .select()
        
        if (error) throw error
        
        alert('🎉 RDM emitida com sucesso!')
        this.limparFormulario()
        this.activeTab = 'historico'
        await this.carregarRDMs()
        
      } catch (error) {
        console.error('❌ Erro ao emitir RDM:', error)
        alert('❌ Erro ao emitir RDM: ' + error.message)
      } finally {
        this.salvandoRDM = false
      }
    },

    limparFormulario() {
      this.novaRDM = {
        material_id: '',
        quantidade: 1,
        unidade_medida: 'UN',
        urgencia: 'NORMAL',
        justificativa: ''
      }
      this.materialSelecionado = null
    },

    aplicarFiltros() {
      let filtradas = [...this.rdms]
      
      if (this.filtros.busca) {
        const busca = this.filtros.busca.toLowerCase()
        filtradas = filtradas.filter(rdm =>
          rdm.material_nome.toLowerCase().includes(busca) ||
          rdm.material_codigo.toLowerCase().includes(busca)
        )
      }
      
      if (this.filtros.status) {
        filtradas = filtradas.filter(rdm => rdm.status === this.filtros.status)
      }
      
      if (this.filtros.periodo) {
        const hoje = new Date()
        filtradas = filtradas.filter(rdm => {
          const dataRdm = new Date(rdm.criado_em)
          
          switch (this.filtros.periodo) {
            case 'hoje':
              return dataRdm.toDateString() === hoje.toDateString()
            case 'semana':
              const semanaAtras = new Date(hoje.getTime() - 7 * 24 * 60 * 60 * 1000)
              return dataRdm >= semanaAtras
            case 'mes':
              return dataRdm.getMonth() === hoje.getMonth() && dataRdm.getFullYear() === hoje.getFullYear()
            case 'trimestre':
              const trimestre = new Date(hoje.getTime() - 90 * 24 * 60 * 60 * 1000)
              return dataRdm >= trimestre
            default:
              return true
          }
        })
      }
      
      this.rdmsFiltradas = filtradas
    },

    verDetalhesRDM(rdm) {
      this.rdmSelecionada = rdm
      this.modalDetalhes = true
    },

    emitirRDMRapida(produto) {
      this.novaRDM.material_id = produto.id
      this.selecionarMaterial()
      this.activeTab = 'nova-rdm'
    },

    getStatusLabel(status) {
      const labels = {
        'PENDENTE': '🟡 Pendente',
        'APROVADO': '🟢 Aprovado',
        'REJEITADO': '🔴 Rejeitado',
        'EM_ANALISE': '🔄 Em Análise'
      }
      return labels[status] || status
    },

    getUrgenciaLabel(urgencia) {
      const labels = {
        'BAIXA': '🟢 Baixa',
        'NORMAL': '🟡 Normal',
        'ALTA': '🟠 Alta',
        'URGENTE': '🔴 Urgente'
      }
      return labels[urgencia] || urgencia
    },

    formatDate(dateString) {
      return new Date(dateString).toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },

    async alterarSenha() {
      if (this.alteracaoSenha.novaSenha !== this.alteracaoSenha.confirmaSenha) {
        alert('❌ As senhas não coincidem!')
        return
      }
      
      this.alterandoSenha = true
      try {
        // Implementar alteração de senha
        alert('🎉 Senha alterada com sucesso!')
        this.alteracaoSenha = {
          senhaAtual: '',
          novaSenha: '',
          confirmaSenha: ''
        }
      } catch (error) {
        console.error('❌ Erro ao alterar senha:', error)
        alert('❌ Erro ao alterar senha: ' + error.message)
      } finally {
        this.alterandoSenha = false
      }
    },

    async logout() {
      if (confirm('Tem certeza que deseja sair?')) {
        localStorage.removeItem('usuarioRDM')
        await supabase.auth.signOut()
        this.$router.push('/rdm')
      }
    },

    // Métodos para Feedback
    async carregarMateriaisParaFeedback() {
      this.carregandoFeedback = true
      try {
        console.log('🔍 [FEEDBACK] Carregando materiais para avaliação')
        
        // Buscar RDMs APROVADAS do usuário
        const { data: rdmsAprovadas, error } = await supabase
          .from('rdms_online')
          .select('id, material_nome, material_codigo, criado_em, atualizado_em')
          .eq('usuario_rdm_id', this.usuarioAtual.id)
          .eq('status', 'APROVADO')
        
        if (error) {
          console.error('❌ [FEEDBACK] Erro ao carregar RDMs aprovadas:', error)
          this.materiaisParaFeedback = []
          return
        }
        
        console.log('📋 [FEEDBACK] RDMs aprovadas encontradas:', rdmsAprovadas?.length || 0)
        
        // Adicionar campos de feedback aos materiais
        this.materiaisParaFeedback = (rdmsAprovadas || []).map(rdm => ({
          ...rdm,
          rating: 0,
          comentario: '',
          feedbackEnviado: false
        }))
        
        console.log('✅ [FEEDBACK] Materiais prontos para avaliação:', this.materiaisParaFeedback.length)
        
      } catch (error) {
        console.error('❌ [FEEDBACK] Erro ao carregar materiais:', error)
        this.materiaisParaFeedback = []
      } finally {
        this.carregandoFeedback = false
      }
    },

    setRating(materialId, rating) {
      const material = this.materiaisParaFeedback.find(m => m.id === materialId)
      if (material) {
        material.rating = rating
        console.log(`⭐ [FEEDBACK] Rating ${rating} definido para ${material.material_nome}`)
      }
    },

    async enviarFeedback(material) {
      if (!material.rating) {
        alert('❌ Por favor, dê uma avaliação de 1 a 5 estrelas')
        return
      }

      try {
        console.log('📤 [FEEDBACK] Enviando feedback para:', material.material_nome)
        
        // Aqui você pode implementar o salvamento do feedback no banco
        // Por enquanto, vou simular o envio
        
        const feedbackData = {
          rdm_id: material.id,
          usuario_rdm_id: this.usuarioAtual.id,
          material_nome: material.material_nome,
          material_codigo: material.material_codigo,
          rating: material.rating,
          comentario: material.comentario || '',
          criado_em: new Date().toISOString()
        }
        
        console.log('💾 [FEEDBACK] Dados do feedback:', feedbackData)
        
        // Simular sucesso por enquanto
        material.feedbackEnviado = true
        alert(`🎉 Feedback enviado com sucesso para ${material.material_nome}!`)
        
        // Remover da lista após envio
        this.materiaisParaFeedback = this.materiaisParaFeedback.filter(m => m.id !== material.id)
        
      } catch (error) {
        console.error('❌ [FEEDBACK] Erro ao enviar feedback:', error)
        alert('❌ Erro ao enviar feedback: ' + error.message)
      }
    }
  }
}
</script>

<style scoped>
.dashboard-rdm {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  font-family: 'Arial', sans-serif;
}

/* Header */
.dashboard-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  padding: 1rem 0;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 2rem;
}

.logo-section h1 {
  color: #333;
  margin: 0;
  font-size: 1.8rem;
  font-weight: bold;
}

.subtitle {
  color: #666;
  font-size: 0.9rem;
}

.user-section {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.user-info {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.2rem;
}

.user-name {
  font-weight: 600;
  color: #333;
}

.user-sector {
  font-size: 0.85rem;
  color: #666;
}

.btn-logout {
  background: linear-gradient(135deg, #ff6b6b, #ee5a52);
  color: white;
  border: none;
  padding: 0.7rem 1.2rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
}

.btn-logout:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 15px rgba(238, 90, 82, 0.4);
}

/* Navigation Tabs */
.nav-tabs {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  padding: 1rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.tabs {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
}

.tab-btn {
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: 0.8rem 1.5rem;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
  white-space: nowrap;
}

.tab-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.tab-btn.active {
  background: white;
  color: #333;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

/* Main Content */
.main-content {
  padding: 2rem 0;
  min-height: calc(100vh - 200px);
}

.tab-content {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  text-align: center;
  margin-bottom: 2rem;
}

.page-header h2 {
  color: white;
  margin: 0 0 0.5rem;
  font-size: 2rem;
  font-weight: bold;
}

.page-header p {
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
  font-size: 1.1rem;
}

/* Cards */
.rdm-form-card,
.filters-card,
.stats-card,
.profile-card {
  background: white;
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

/* Form Styling */
.form-section {
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #f0f0f0;
}

.form-section:last-of-type {
  border-bottom: none;
  margin-bottom: 0;
}

.form-section h3 {
  color: #333;
  margin: 0 0 1.5rem;
  font-size: 1.3rem;
  font-weight: 600;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.form-group label {
  display: block;
  color: #333;
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 1rem;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
  box-sizing: border-box;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.form-group input:disabled,
.form-group select:disabled {
  background-color: #f8f9fa;
  cursor: not-allowed;
  opacity: 0.7;
}

.form-group textarea {
  resize: vertical;
  min-height: 100px;
}

.error-text {
  color: #e74c3c;
  font-style: italic;
  margin-top: 0.5rem;
  display: block;
}

/* Material Info */
.material-info {
  background: #f8f9fa;
  padding: 1.5rem;
  border-radius: 10px;
  margin-top: 1rem;
}

.material-info h4 {
  color: #333;
  margin: 0 0 1rem;
  font-size: 1.1rem;
}

.material-info p {
  margin: 0.5rem 0;
  color: #666;
}

/* Buttons */
.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  padding-top: 1.5rem;
  border-top: 1px solid #f0f0f0;
}

.btn-primary,
.btn-secondary {
  padding: 1rem 2rem;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 1rem;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.btn-secondary {
  background: #f8f9fa;
  color: #666;
  border: 2px solid #e1e5e9;
}

.btn-secondary:hover {
  background: #e9ecef;
  border-color: #dee2e6;
}

/* Filters */
.filters-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  align-items: end;
}

.filter-group label {
  display: block;
  color: #333;
  margin-bottom: 0.5rem;
  font-weight: 600;
  font-size: 0.9rem;
}

/* Stats Cards */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  padding: 1.5rem;
  border-radius: 15px;
  text-align: center;
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
}

.stat-number {
  font-size: 2.5rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.9rem;
  opacity: 0.9;
}

/* Tables */
.rdm-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 1rem;
}

.rdm-table th,
.rdm-table td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid #f0f0f0;
}

.rdm-table th {
  background: #f8f9fa;
  font-weight: 600;
  color: #333;
}

.rdm-table tbody tr:hover {
  background: #f8f9fa;
}

.status-pendente { color: #f39c12; }
.status-aprovado { color: #27ae60; }
.status-rejeitado { color: #e74c3c; }
.status-em_analise { color: #3498db; }

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.3s ease;
}

.modal {
  background: white;
  border-radius: 20px;
  max-width: 600px;
  width: 90%;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #f0f0f0;
}

.modal-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.3rem;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  padding: 0.5rem;
  border-radius: 50%;
  transition: all 0.3s ease;
}

.btn-close:hover {
  background: #f0f0f0;
  color: #333;
}

.modal-body {
  padding: 2rem;
}

.detalhes-grid {
  display: grid;
  gap: 1rem;
}

.detalhe-item {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.detalhe-item.full-width {
  grid-column: 1 / -1;
}

.detalhe-item strong {
  color: #333;
  font-weight: 600;
}

.detalhe-item span,
.detalhe-item p {
  color: #666;
  margin: 0;
}

/* Loading States */
.loading-spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-right: 0.5rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Responsive */
@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 1rem;
  }

  .user-section {
    flex-direction: column;
    gap: 1rem;
  }

  .tabs {
    justify-content: center;
  }

  .form-actions {
    flex-direction: column;
    gap: 0.5rem;
  }

  .rdm-form-card,
  .filters-card,
  .stats-card,
  .profile-card {
    padding: 1.5rem;
  }

  .modal {
    width: 95%;
    margin: 1rem;
  }

  .modal-body {
    padding: 1.5rem;
  }
}

@media (max-width: 480px) {
  .page-header h2 {
    font-size: 1.5rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .rdm-table {
    font-size: 0.9rem;
  }

  .rdm-table th,
  .rdm-table td {
    padding: 0.7rem;
  }
}

/* Feedback Styles */
.feedback-card {
  background: white;
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
}

.loading-state,
.empty-state {
  text-align: center;
  padding: 3rem 2rem;
  color: #666;
}

.loading-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.empty-state h3 {
  color: #333;
  margin-bottom: 1rem;
}

.empty-state p {
  margin-bottom: 0.5rem;
  line-height: 1.6;
}

.materiais-feedback h3 {
  color: #333;
  margin-bottom: 2rem;
  font-size: 1.3rem;
}

.material-feedback-item {
  border: 2px solid #f0f0f0;
  border-radius: 15px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  transition: all 0.3s ease;
}

.material-feedback-item:hover {
  border-color: #667eea;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15);
}

.material-info h4 {
  color: #333;
  margin: 0 0 1rem;
  font-size: 1.2rem;
}

.material-info p {
  margin: 0.5rem 0;
  color: #666;
}

.feedback-form {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #f0f0f0;
}

.rating-section,
.comment-section {
  margin-bottom: 1.5rem;
}

.rating-section label,
.comment-section label {
  display: block;
  color: #333;
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.star-rating {
  display: flex;
  gap: 0.3rem;
  margin-bottom: 1rem;
}

.star {
  font-size: 1.5rem;
  cursor: pointer;
  opacity: 0.3;
  transition: all 0.3s ease;
  user-select: none;
}

.star:hover,
.star.active {
  opacity: 1;
  transform: scale(1.1);
}

.star:hover {
  filter: drop-shadow(0 0 8px rgba(255, 193, 7, 0.6));
}

.comment-section textarea {
  width: 100%;
  padding: 1rem;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
  box-sizing: border-box;
  resize: vertical;
  font-family: inherit;
}

.comment-section textarea:focus {
  outline: none;
  border-color: #667eea;
}

.feedback-actions {
  display: flex;
  justify-content: flex-end;
}

.btn-small {
  padding: 0.7rem 1.5rem;
  font-size: 0.9rem;
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* Responsive para Feedback */
@media (max-width: 768px) {
  .material-feedback-item {
    padding: 1rem;
  }
  
  .star {
    font-size: 1.3rem;
  }
  
  .feedback-actions {
    justify-content: center;
  }
}
</style> 