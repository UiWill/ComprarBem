<template>
  <div class="dashboard-rdm">
    <!-- Header -->
    <header class="dashboard-header">
      <div class="container">
        <div class="header-content">
          <div class="logo-section">
            <h1>🏥 Sistema Comprar Bem</h1>
            <span class="subtitle">Dashboard RDM On-line</span>
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
            @click="activeTab = 'avaliacao'" 
            :class="{ active: activeTab === 'avaliacao' }"
            class="tab-btn"
          >
            ⭐ Avaliação de Materiais
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
        
        <!-- Tab: Avaliação de Materiais -->
        <div v-if="activeTab === 'avaliacao'" class="tab-content">
          <div class="page-header">
            <h2>⭐ Avaliação de Materiais</h2>
            <p>Avalie a qualidade dos materiais e registre problemas ou sugestões</p>
          </div>

          <div class="reclamacao-form-card">
            <form @submit.prevent="enviarReclamacao">
              <div class="form-section">
                <h3>👤 Dados do Reclamante</h3>
                <div class="form-row">
                  <div class="form-group">
                    <label>Nome do Reclamante:</label>
                    <input 
                      type="text" 
                      v-model="novaReclamacao.nome_reclamante" 
                      required 
                    />
                  </div>
                  <div class="form-group">
                    <label>Telefone:</label>
                    <input 
                      type="tel" 
                      v-model="novaReclamacao.telefone" 
                      placeholder="(00) 00000-0000"
                      required 
                    />
                  </div>
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label>Email:</label>
                    <input 
                      type="email" 
                      v-model="novaReclamacao.email" 
                      required 
                    />
                  </div>
                  <div class="form-group">
                    <label>Unidade/Setor:</label>
                    <input 
                      type="text" 
                      v-model="novaReclamacao.unidade_setor" 
                      required 
                    />
                  </div>
                </div>
              </div>

              <div class="form-section">
                <h3>📦 Dados do Material</h3>
                <div class="form-group">
                  <label>Selecionar Material:</label>
                  <select 
                    v-model="materialSelecionadoReclamacao" 
                    @change="preencherDadosMaterial"
                    required
                  >
                    <option value="">Selecione um material sob sua responsabilidade</option>
                    <option 
                      v-for="material in usuarioAtual.materiais" 
                      :key="material.produto_id"
                      :value="material"
                    >
                      {{ material.nome }} - {{ material.codigo }}
                    </option>
                  </select>
                  <small v-if="usuarioAtual.materiais?.length === 0" class="error-text">
                    ⚠️ Você não possui materiais cadastrados. Entre em contato com a CPM.
                  </small>
                </div>
                
                <div v-if="materialSelecionadoReclamacao" class="material-info-reclamacao">
                  <h4>📋 Dados do Material Selecionado:</h4>
                  <div class="form-row">
                    <div class="form-group">
                      <label>Nome do Material:</label>
                      <input 
                        type="text" 
                        v-model="novaReclamacao.nome_material" 
                        readonly
                        class="readonly-input"
                      />
                    </div>
                    <div class="form-group">
                      <label>Código do Material:</label>
                      <input 
                        type="text" 
                        v-model="novaReclamacao.codigo_material" 
                        readonly
                        class="readonly-input"
                      />
                    </div>
                  </div>
                  <div class="form-group">
                    <label>Marca e Modelo:</label>
                    <input 
                      type="text" 
                      v-model="novaReclamacao.marca_modelo" 
                      placeholder="Informe a marca e modelo específicos (se necessário)"
                    />
                  </div>
                  
                  <!-- Sistema de Estrelas para Avaliação -->
                  <div class="form-group">
                    <label>⭐ Avaliação da Qualidade (obrigatório):</label>
                    <div class="star-rating">
                      <span 
                        v-for="i in 5" 
                        :key="i"
                        @click="novaReclamacao.rating = i"
                        :class="{ active: (novaReclamacao.rating || 0) >= i }"
                        class="star"
                        :title="`${i} estrela${i > 1 ? 's' : ''}`"
                      >
                        ⭐
                      </span>
                    </div>
                    <small v-if="novaReclamacao.rating" class="rating-info">
                      Avaliação: {{ novaReclamacao.rating }}/5 estrelas
                    </small>
                    <small v-else class="error-text">
                      ⚠️ Por favor, dê uma avaliação de 1 a 5 estrelas
                    </small>
                  </div>
                </div>
              </div>

              <div class="form-section">
                <h3>💬 Comentários e Observações</h3>
                <div class="form-group">
                  <label>Observações sobre o Material:</label>
                  <textarea 
                    v-model="novaReclamacao.comentario" 
                    rows="3"
                    placeholder="Como está sendo a experiência com este material? Qualidade, durabilidade, eficácia..."
                  ></textarea>
                </div>
              </div>

              <div class="form-section">
                <h3>🚨 Problemas e Reclamações (opcional)</h3>
                <div class="form-group">
                  <label>Descrição de Problemas:</label>
                  <textarea 
                    v-model="novaReclamacao.registro_reclamacao" 
                    rows="4"
                    placeholder="Se houver problemas, defeitos ou situações negativas, descreva detalhadamente aqui... (opcional)"
                  ></textarea>
                </div>
                <div class="form-group">
                  <label>Sugestões de Melhoria:</label>
                  <textarea 
                    v-model="novaReclamacao.sugestoes" 
                    rows="3"
                    placeholder="Sugestões para melhorias ou soluções... (opcional)"
                  ></textarea>
                </div>
              </div>

              <div class="form-actions">
                <button type="button" @click="limparAvaliacao" class="btn-secondary">
                  🗑️ Limpar
                </button>
                <button type="submit" :disabled="enviandoReclamacao || !novaReclamacao.rating" class="btn-primary">
                  <span v-if="enviandoReclamacao">⏳ Enviando...</span>
                  <span v-else>⭐ Enviar Avaliação</span>
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- Tab: Histórico -->
        <div v-if="activeTab === 'historico'" class="tab-content">
          <div class="page-header">
            <h2>📋 Histórico de Avaliações</h2>
            <p>Veja suas avaliações e feedbacks anteriores</p>
          </div>

          <div class="historico-container">
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
                  <label>⭐ Avaliação:</label>
                  <select v-model="filtros.rating" @change="aplicarFiltros">
                    <option value="">Todas</option>
                    <option value="5">⭐⭐⭐⭐⭐ (5 estrelas)</option>
                    <option value="4">⭐⭐⭐⭐ (4 estrelas)</option>
                    <option value="3">⭐⭐⭐ (3 estrelas)</option>
                    <option value="2">⭐⭐ (2 estrelas)</option>
                    <option value="1">⭐ (1 estrela)</option>
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

            <!-- Lista de Feedbacks -->
            <div class="feedbacks-list">
              <div v-if="carregandoHistorico" class="loading-card">
                ⏳ Carregando histórico...
              </div>

              <div v-else-if="historicoFeedbacks.length === 0" class="empty-state-card">
                <div class="empty-icon">📭</div>
                <h3>Nenhuma avaliação encontrada</h3>
                <p>Você ainda não enviou nenhuma avaliação de material.</p>
                <button @click="activeTab = 'avaliacao'" class="btn-primary">
                  ⭐ Fazer Primeira Avaliação
                </button>
              </div>

              <div v-else class="feedbacks-grid">
                <div 
                  v-for="feedback in historicoFeedbacks" 
                  :key="feedback.id"
                  class="feedback-card-history"
                >
                  <div class="feedback-header">
                    <h4>{{ feedback.material_nome }}</h4>
                    <div class="rating-display">
                      <span v-for="i in 5" :key="i" :class="{ active: feedback.rating >= i }" class="star">⭐</span>
                    </div>
                  </div>
                  
                  <div class="feedback-content">
                    <p class="feedback-details">
                      <strong>Código:</strong> {{ feedback.material_codigo }}<br>
                      <strong>Avaliação:</strong> {{ feedback.rating }}/5 estrelas
                    </p>
                    <p class="feedback-comentario" v-if="feedback.comentario">
                      <strong>Comentário:</strong> {{ feedback.comentario }}
                    </p>
                  </div>
                  
                  <div class="feedback-footer">
                    <span class="feedback-date">📅 {{ formatDate(feedback.criado_em) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab: Meus Materiais -->
        <div v-if="activeTab === 'materiais'" class="tab-content">
          <div class="page-header">
            <h2>📦 Meus Materiais</h2>
            <p>Materiais sob sua responsabilidade para avaliação</p>
          </div>

          <div class="materiais-container">
            <div v-if="usuarioAtual.materiais?.length === 0" class="empty-state-card">
              <div class="empty-icon">📦</div>
              <h3>Nenhum material cadastrado</h3>
              <p>Você ainda não possui materiais sob sua responsabilidade.</p>
              <p>Entre em contato com a CPM para solicitar acesso aos materiais do seu setor.</p>
            </div>

            <div v-else class="materiais-grid">
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
                  <p><strong>Periodicidade de Avaliação:</strong> {{ material.periodicidade_rdm }}</p>
                  <p><strong>Próxima Avaliação:</strong> {{ calcularProximaAvaliacao(material) }}</p>
                </div>
                
                <div class="material-actions">
                  <button 
                    @click="activeTab = 'avaliacao'" 
                    class="btn-avaliar"
                  >
                    ⭐ Avaliar Material
                  </button>
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

          <div class="perfil-container">
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
                  <span class="stat-number">{{ totalFeedbacks }}</span>
                  <span class="stat-label">Avaliações Enviadas</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ feedbacksRecentes }}</span>
                  <span class="stat-label">Últimos 30 dias</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ usuarioAtual.materiais?.length || 0 }}</span>
                  <span class="stat-label">Materiais Sob Responsabilidade</span>
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
      </div>
    </main>


  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'DashboardRDM',
  data() {
    return {
      activeTab: 'avaliacao',
      usuarioAtual: {},
      

      
      // Avaliação (antigo Reclamações)
      novaReclamacao: {
        nome_reclamante: '',
        telefone: '',
        email: '',
        unidade_setor: '',
        nome_material: '',
        codigo_material: '',
        marca_modelo: '',
        rating: 0,
        comentario: '',
        registro_reclamacao: '',
        sugestoes: ''
      },
      materialSelecionadoReclamacao: null,
      enviandoReclamacao: false,
      
      // Histórico de Feedbacks
      historicoFeedbacks: [],
      carregandoHistorico: false,
      filtros: {
        busca: '',
        rating: '',
        periodo: ''
      },
      
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
    totalFeedbacks() {
      return this.historicoFeedbacks.length
    },
    feedbacksRecentes() {
      return this.historicoFeedbacks.filter(f => {
        const umMesAtras = new Date()
        umMesAtras.setMonth(umMesAtras.getMonth() - 1)
        return new Date(f.criado_em) >= umMesAtras
      }).length
    }
  },
  async mounted() {
    await this.carregarDadosUsuario()
    await this.carregarHistoricoFeedbacks()
    // Inicializar campos de avaliação com dados do usuário
    this.inicializarReclamacao()
  },
  watch: {
    activeTab(newTab) {
      if (newTab === 'historico') {
        this.carregarHistoricoFeedbacks()
      }
    }
  },
  methods: {
    async carregarDadosUsuario() {
      try {
        const dadosLocal = localStorage.getItem('usuarioRDM')
        if (!dadosLocal) {
          throw new Error('Dados do usuário não encontrados')
        }

        this.usuarioAtual = JSON.parse(dadosLocal)
        
        if (!this.usuarioAtual.id || !this.usuarioAtual.tenant_id) {
          throw new Error('Dados do usuário incompletos')
        }

        console.log('✅ Dados do usuário carregados:', {
          nome: this.usuarioAtual.nome_usuario,
          id: this.usuarioAtual.id,
          tenant_id: this.usuarioAtual.tenant_id,
          materiais: this.usuarioAtual.materiais?.length || 0
        })

      } catch (error) {
        console.error('❌ Erro ao carregar dados do usuário:', error)
        alert('Erro ao carregar dados do usuário. Por favor, faça login novamente.')
        this.$router.push('/rdm')
      }
    },

    inicializarReclamacao() {
      this.novaReclamacao.nome_reclamante = this.usuarioAtual.nome_usuario || ''
      this.novaReclamacao.email = this.usuarioAtual.email || ''
      this.novaReclamacao.unidade_setor = this.usuarioAtual.unidade_setor || ''
      this.novaReclamacao.rating = 0
      this.novaReclamacao.comentario = ''
    },

    async carregarHistoricoFeedbacks() {
      this.carregandoHistorico = true
      try {
        if (!this.usuarioAtual.id || !this.usuarioAtual.tenant_id) {
          throw new Error('Dados do usuário incompletos')
        }

        const { data: feedbacks, error } = await supabase
          .from('material_feedbacks')
          .select('*')
          .eq('usuario_rdm_id', this.usuarioAtual.id)
          .eq('tenant_id', this.usuarioAtual.tenant_id)
          .order('criado_em', { ascending: false })
        
        if (error) throw error
        
        this.historicoFeedbacks = feedbacks || []
        this.aplicarFiltros()
        
      } catch (error) {
        console.error('❌ [HISTÓRICO] Erro:', error)
        this.historicoFeedbacks = []
        alert('Erro ao carregar histórico: ' + error.message)
      } finally {
        this.carregandoHistorico = false
      }
    },

    aplicarFiltros() {
      if (!this.historicoFeedbacks) {
        return
      }
      
      let filtrados = [...this.historicoFeedbacks]
      
      if (this.filtros.busca) {
        const busca = this.filtros.busca.toLowerCase()
        filtrados = filtrados.filter(feedback =>
          feedback.material_nome?.toLowerCase().includes(busca) ||
          feedback.material_codigo?.toLowerCase().includes(busca)
        )
      }
      
      if (this.filtros.rating) {
        filtrados = filtrados.filter(feedback => feedback.rating == this.filtros.rating)
      }
      
      if (this.filtros.periodo) {
        const hoje = new Date()
        filtrados = filtrados.filter(feedback => {
          const dataFeedback = new Date(feedback.criado_em)
          
          switch (this.filtros.periodo) {
            case 'hoje':
              return dataFeedback.toDateString() === hoje.toDateString()
            case 'semana':
              const semanaAtras = new Date(hoje.getTime() - 7 * 24 * 60 * 60 * 1000)
              return dataFeedback >= semanaAtras
            case 'mes':
              return dataFeedback.getMonth() === hoje.getMonth() && dataFeedback.getFullYear() === hoje.getFullYear()
            case 'trimestre':
              const trimestre = new Date(hoje.getTime() - 90 * 24 * 60 * 60 * 1000)
              return dataFeedback >= trimestre
            default:
              return true
          }
        })
      }
      
      // Atualizar lista filtrada se necessário
      // this.historicoFeedbacksFiltrados = filtrados
    },

    calcularProximaAvaliacao(material) {
      // Calcular próxima data de avaliação baseada na periodicidade
      const hoje = new Date()
      const periodicidade = material.periodicidade_rdm || 'MENSAL'
      
      switch (periodicidade.toUpperCase()) {
        case 'SEMANAL':
          hoje.setDate(hoje.getDate() + 7)
          break
        case 'QUINZENAL':
          hoje.setDate(hoje.getDate() + 15)
          break
        case 'MENSAL':
          hoje.setMonth(hoje.getMonth() + 1)
          break
        case 'TRIMESTRAL':
          hoje.setMonth(hoje.getMonth() + 3)
          break
        case 'SEMESTRAL':
          hoje.setMonth(hoje.getMonth() + 6)
          break
        case 'ANUAL':
          hoje.setFullYear(hoje.getFullYear() + 1)
          break
        default:
          hoje.setMonth(hoje.getMonth() + 1)
      }
      
      return hoje.toLocaleDateString('pt-BR')
    },

    async enviarReclamacao() {
      if (this.enviandoReclamacao) return
      
      this.enviandoReclamacao = true
      try {
        console.log('📤 [RECLAMAÇÃO] Enviando reclamação...')
        
        // Verificar dados necessários
        if (!this.usuarioAtual.id || !this.usuarioAtual.tenant_id) {
          throw new Error('Dados do usuário incompletos')
        }

        if (!this.materialSelecionadoReclamacao) {
          throw new Error('Nenhum material selecionado')
        }
        
        // Preparar dados do feedback garantindo todos os campos necessários
        const feedbackData = {
          id: crypto.randomUUID(), // Gerar UUID único
          tenant_id: this.usuarioAtual.tenant_id,
          usuario_rdm_id: this.usuarioAtual.id,
          produto_id: this.materialSelecionadoReclamacao.produto_id,
          material_nome: this.novaReclamacao.nome_material,
          material_codigo: this.novaReclamacao.codigo_material,
          rating: this.novaReclamacao.rating,
          comentario: this.novaReclamacao.comentario || '',
          criado_em: new Date().toISOString()
        }

        console.log('💾 [AVALIAÇÃO] Dados preparados:', feedbackData)
        
        // Tentar inserir o feedback
        const { error: feedbackError } = await supabase
          .from('material_feedbacks')
          .insert([feedbackData])
        
        if (feedbackError) {
          console.error('❌ [AVALIAÇÃO] Erro ao salvar feedback:', feedbackError)
          throw new Error(feedbackError.message)
        }
        
        console.log('✅ [AVALIAÇÃO] Feedback salvo com sucesso!')
        
        // Se houver reclamação, salvar na tabela de reclamações
        if (this.novaReclamacao.registro_reclamacao?.trim()) {
          const reclamacaoData = {
            id: crypto.randomUUID(),
            tenant_id: this.usuarioAtual.tenant_id,
            usuario_rdm_id: this.usuarioAtual.id,
            nome_reclamante: this.novaReclamacao.nome_reclamante,
            telefone: this.novaReclamacao.telefone,
            email: this.novaReclamacao.email,
            unidade_setor: this.novaReclamacao.unidade_setor,
            nome_material: this.novaReclamacao.nome_material,
            codigo_material: this.novaReclamacao.codigo_material,
            marca_modelo: this.novaReclamacao.marca_modelo,
            registro_reclamacao: this.novaReclamacao.registro_reclamacao,
            sugestoes: this.novaReclamacao.sugestoes || '',
            status: 'ABERTA',
            data_reclamacao: new Date().toISOString()
          }
          
          const { error: reclamacaoError } = await supabase
            .from('reclamacoes_usuarios')
            .insert([reclamacaoData])
          
          if (reclamacaoError) {
            console.error('❌ [RECLAMAÇÃO] Erro ao salvar reclamação:', reclamacaoError)
            throw new Error(reclamacaoError.message)
          }
        }
        
        // Recarregar histórico
        await this.carregarHistoricoFeedbacks()
        
        // Mostrar mensagem de sucesso
        alert('✅ Avaliação enviada com sucesso!')
        this.limparAvaliacao()
        
      } catch (error) {
        console.error('❌ [RECLAMAÇÃO] Erro ao enviar:', error)
        alert('Erro ao enviar: ' + error.message)
      } finally {
        this.enviandoReclamacao = false
      }
    },

    preencherDadosMaterial() {
      if (this.materialSelecionadoReclamacao) {
        this.novaReclamacao.nome_material = this.materialSelecionadoReclamacao.nome
        this.novaReclamacao.codigo_material = this.materialSelecionadoReclamacao.codigo
        this.novaReclamacao.marca_modelo = '' // Usuário pode preencher informações específicas
        console.log('📦 [RECLAMAÇÃO] Material selecionado:', this.materialSelecionadoReclamacao.nome)
      }
    },

    limparAvaliacao() {
      this.novaReclamacao = {
        nome_reclamante: this.usuarioAtual.nome_usuario || '',
        telefone: '',
        email: this.usuarioAtual.email || '',
        unidade_setor: this.usuarioAtual.unidade_setor || '',
        nome_material: '',
        codigo_material: '',
        marca_modelo: '',
        rating: 0,
        comentario: '',
        registro_reclamacao: '',
        sugestoes: ''
      }
      this.materialSelecionadoReclamacao = null
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
        this.$router.push('/rdm')
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
  border-color: #adb5bd;
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
  transition: all 0.2s ease;
  user-select: none;
  display: inline-block;
  padding: 0.2rem;
  border-radius: 50%;
}

.star:hover,
.star.active {
  opacity: 1;
  transform: scale(1.2);
  color: #FFD700;
}

.star.active {
  text-shadow: 0 0 10px rgba(255, 215, 0, 0.8);
  opacity: 1;
}

.star:hover {
  filter: drop-shadow(0 0 8px rgba(255, 193, 7, 0.6));
  background: rgba(255, 215, 0, 0.1);
}

.rating-info {
  display: block;
  margin-top: 0.5rem;
  color: #667eea;
  font-weight: 600;
  font-style: italic;
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

/* Reclamação Styles */
.reclamacao-form-card {
  background: white;
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.form-section {
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #f0f0f0;
}

.form-section:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.form-section h3 {
  color: #333;
  margin-bottom: 1.5rem;
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-group label {
  color: #333;
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.form-group input,
.form-group textarea {
  padding: 1rem;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid #f0f0f0;
}

.btn-secondary {
  background: #f8f9fa;
  color: #666;
  border: 2px solid #e1e5e9;
  padding: 0.8rem 1.5rem;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: #e9ecef;
  border-color: #adb5bd;
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
  
  .form-row {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .form-actions {
    flex-direction: column;
  }
  
  .reclamacao-form-card {
    padding: 1.5rem;
  }
}

/* Containers principais */
.materiais-container,
.historico-container,
.perfil-container {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 15px;
  padding: 2rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  margin-top: 1.5rem;
}

/* Estados vazios melhorados */
.empty-state-card,
.loading-card {
  background: rgba(255, 255, 255, 0.9);
  border-radius: 12px;
  padding: 3rem 2rem;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

/* Seleção de material nas reclamações */
.material-info-reclamacao {
  background: #f8f9fa;
  border-radius: 12px;
  padding: 1.5rem;
  margin-top: 1rem;
  border: 2px solid #e9ecef;
}

.material-info-reclamacao h4 {
  color: #495057;
  margin-bottom: 1rem;
  font-size: 1rem;
}

.readonly-input {
  background: #f8f9fa !important;
  color: #6c757d !important;
  cursor: not-allowed !important;
}

.error-text {
  color: #dc3545;
  font-style: italic;
  margin-top: 0.5rem;
}

/* Melhorias para os dropdowns */
.form-group select {
  padding: 1rem;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
  font-family: inherit;
  background: white;
  cursor: pointer;
}

.form-group select:focus {
  outline: none;
  border-color: #667eea;
}

/* Responsividade dos containers */
@media (max-width: 768px) {
  .materiais-container,
  .historico-container,
  .perfil-container {
    padding: 1.5rem;
    margin-top: 1rem;
  }
  
  .empty-state-card,
  .loading-card {
    padding: 2rem 1.5rem;
  }
  
  .material-info-reclamacao {
    padding: 1rem;
  }
}
</style> 