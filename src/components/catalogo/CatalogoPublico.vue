<template>
  <div class="reclame-aqui">
    <!-- Etapa 1: Seleção do Órgão -->
    <div v-if="etapaAtual === 'selecao'" class="selecao-orgao">
      <div class="container">
        <div class="header-section">
          <h1>📢 Reclame Aqui - Sistema de Reclamações</h1>
          <p class="subtitle">Selecione o órgão para fazer sua reclamação ou ver reclamações existentes</p>
        </div>
        
        <div class="orgaos-grid" v-if="!carregandoOrgaos">
          <div v-if="orgaos.length === 0" class="no-orgaos">
            <p>Nenhum órgão encontrado.</p>
          </div>
          <div 
            v-else
            v-for="orgao in orgaos" 
            :key="orgao.tenant_id" 
            class="orgao-card"
            @click="selecionarOrgao(orgao)">
            <div class="orgao-info">
              <h3>{{ orgao.nome_orgao || orgao.tenant_id }}</h3>
              <p v-if="orgao.descricao">{{ orgao.descricao }}</p>
              <div class="orgao-stats">
                <span class="stat">{{ orgao.total_reclamacoes || 0 }} reclamações</span>
              </div>
            </div>
            <div class="orgao-arrow">→</div>
          </div>
        </div>
        
        <div v-if="carregandoOrgaos" class="loading-state">
          <div class="spinner"></div>
          <p>Carregando órgãos...</p>
        </div>
      </div>
    </div>
    
    <!-- Etapa 2: Sistema de Reclamações do Órgão -->
    <div v-if="etapaAtual === 'reclamacoes'" class="sistema-reclamacoes">
      <div class="container">
        <div class="breadcrumb">
          <button @click="voltarSelecao" class="btn-voltar">← Voltar</button>
          <span class="breadcrumb-text">{{ orgaoSelecionado.nome_orgao || orgaoSelecionado.tenant_id }}</span>
        </div>
        
        <div class="reclamacoes-header">
          <h2>Sistema de Reclamações</h2>
          <p>Faça sua reclamação ou consulte reclamações existentes</p>
        </div>
        
        <!-- Ações principais -->
        <div class="acoes-principais">
          <button @click="abrirFormularioReclamacao" class="btn-nova-reclamacao">
            📝 Nova Reclamação
          </button>
          <button @click="alternarVisualizacao" class="btn-ver-reclamacoes" :class="{ active: mostrandoReclamacoes }">
            👁️ {{ mostrandoReclamacoes ? 'Ver Formulário' : 'Ver Reclamações' }}
          </button>
        </div>
        
        <!-- Formulário de Nova Reclamação -->
        <div v-if="!mostrandoReclamacoes" class="formulario-reclamacao">
          <div class="form-card">
            <h3>📝 Nova Reclamação</h3>
            <form @submit.prevent="salvarReclamacao">
              <div class="form-row">
                <div class="form-group">
                  <label for="nomeReclamante">Nome Completo *</label>
                  <input 
                    id="nomeReclamante" 
                    v-model="novaReclamacao.nome_reclamante" 
                    type="text" 
                    required 
                    placeholder="Digite seu nome completo"
                  >
                </div>
                
                <div class="form-group">
                  <label for="setorReclamante">Setor/Unidade</label>
                  <input 
                    id="setorReclamante" 
                    v-model="novaReclamacao.setor_reclamante" 
                    type="text" 
                    placeholder="Departamento, Setor ou Unidade"
                  >
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label for="cargoReclamante">Cargo/Função</label>
                  <input 
                    id="cargoReclamante" 
                    v-model="novaReclamacao.cargo_reclamante" 
                    type="text" 
                    placeholder="Seu cargo ou função"
                  >
                </div>
                
                <div class="form-group">
                  <label for="categoriaReclamacao">Categoria da Reclamação</label>
                  <select id="categoriaReclamacao" v-model="novaReclamacao.categoria">
                    <option value="">Selecione uma categoria</option>
                    <option value="Produto">Produto</option>
                    <option value="Atendimento">Atendimento</option>
                    <option value="Sistema">Sistema</option>
                    <option value="Processo">Processo</option>
                    <option value="Outro">Outro</option>
                  </select>
                </div>
              </div>
              
              <div class="form-group">
                <label for="tituloReclamacao">Título da Reclamação *</label>
                <input 
                  id="tituloReclamacao" 
                  v-model="novaReclamacao.titulo_reclamacao" 
                  type="text" 
                  required
                  placeholder="Título resumido da sua reclamação"
                  maxlength="500"
                >
              </div>
              
              <div class="form-group">
                <label for="descricaoReclamacao">Descrição da Reclamação *</label>
                <textarea 
                  id="descricaoReclamacao" 
                  v-model="novaReclamacao.descricao_reclamacao" 
                  rows="6"
                  required
                  placeholder="Descreva detalhadamente sua reclamação. Inclua datas, nomes, situações específicas e qualquer informação relevante..."
                ></textarea>
              </div>
              
              <div class="form-actions">
                <button type="submit" class="btn-enviar" :disabled="salvandoReclamacao">
                  <span v-if="salvandoReclamacao" class="spinner-small"></span>
                  {{ salvandoReclamacao ? 'Enviando...' : '🚀 Enviar Reclamação' }}
                </button>
              </div>
            </form>
          </div>
        </div>
        
        <!-- Lista de Reclamações -->
        <div v-if="mostrandoReclamacoes" class="lista-reclamacoes">
          <div class="reclamacoes-filtros">
            <div class="filtros-row">
              <div class="filtro-status">
                <label>Status:</label>
                <select v-model="filtroStatus" @change="filtrarReclamacoes">
                  <option value="">Todos</option>
                  <option value="pendente">Pendente</option>
                  <option value="em_analise">Em Análise</option>
                  <option value="respondida">Respondida</option>
                  <option value="resolvida">Resolvida</option>
                </select>
              </div>
              
              <div class="filtro-categoria">
                <label>Categoria:</label>
                <select v-model="filtroCategoria" @change="filtrarReclamacoes">
                  <option value="">Todas</option>
                  <option value="Produto">Produto</option>
                  <option value="Atendimento">Atendimento</option>
                  <option value="Sistema">Sistema</option>
                  <option value="Processo">Processo</option>
                  <option value="Outro">Outro</option>
                </select>
              </div>
              
              <div class="busca-reclamacao">
                <input 
                  type="text" 
                  v-model="buscaTexto" 
                  @input="filtrarReclamacoes"
                  placeholder="Buscar reclamação..." 
                >
              </div>
            </div>
          </div>
          
          <div v-if="reclamacoesFiltradas.length === 0 && !carregandoReclamacoes" class="no-reclamacoes">
            <p>📢 Nenhuma reclamação encontrada</p>
          </div>
          
          <div v-if="carregandoReclamacoes" class="loading-state">
            <div class="spinner"></div>
            <p>Carregando reclamações...</p>
          </div>
          
          <div class="reclamacoes-grid">
            <div 
              v-for="reclamacao in reclamacoesFiltradas" 
              :key="reclamacao.id" 
              class="reclamacao-card"
              @click="verDetalhesReclamacao(reclamacao)"
            >
              <div class="reclamacao-header">
                <div class="reclamacao-info">
                  <h4>{{ reclamacao.titulo_reclamacao }}</h4>
                  <div class="reclamacao-meta">
                    <span class="reclamante">{{ reclamacao.nome_reclamante }}</span>
                    <span class="data">{{ formatarData(reclamacao.criado_em) }}</span>
                  </div>
                </div>
                <div class="reclamacao-status">
                  <span class="status-badge" :class="getStatusClass(reclamacao.status)">
                    {{ getStatusText(reclamacao.status) }}
                  </span>
                  <span v-if="reclamacao.categoria" class="categoria-badge">
                    {{ reclamacao.categoria }}
                  </span>
                </div>
              </div>
              
              <div class="reclamacao-preview">
                <p>{{ reclamacao.descricao_reclamacao.substring(0, 150) }}{{ reclamacao.descricao_reclamacao.length > 150 ? '...' : '' }}</p>
              </div>
              
              <div class="reclamacao-footer">
                <div class="interacao-info">
                  <span v-if="reclamacao.resposta_cpm" class="tem-resposta">✅ Respondida pela CPM</span>
                  <span v-else class="sem-resposta">⏳ Aguardando resposta</span>
                </div>
                <div class="ver-mais">
                  <span class="ver-detalhes">Ver detalhes →</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Modal de Detalhes da Reclamação -->
    <div class="modal-overlay" v-if="reclamacaoSelecionada" @click="fecharDetalhesReclamacao">
      <div class="modal-content reclamacao-detalhes-modal" @click.stop>
        <div class="modal-header">
          <h3>{{ reclamacaoSelecionada.titulo_reclamacao }}</h3>
          <button class="btn-close" @click="fecharDetalhesReclamacao">×</button>
        </div>
        <div class="modal-body">
          <div class="reclamacao-detalhes">
            <!-- Informações do Reclamante -->
            <div class="detalhes-section">
              <h4>👤 Informações do Reclamante</h4>
              <div class="info-grid">
                <div><strong>Nome:</strong> {{ reclamacaoSelecionada.nome_reclamante }}</div>
                <div v-if="reclamacaoSelecionada.setor_reclamante"><strong>Setor:</strong> {{ reclamacaoSelecionada.setor_reclamante }}</div>
                <div v-if="reclamacaoSelecionada.cargo_reclamante"><strong>Cargo:</strong> {{ reclamacaoSelecionada.cargo_reclamante }}</div>
                <div><strong>Data:</strong> {{ formatarData(reclamacaoSelecionada.criado_em) }}</div>
              </div>
            </div>
            
            <!-- Status e Categoria -->
            <div class="detalhes-section">
              <h4>📊 Status e Categoria</h4>
              <div class="badges-container">
                <span class="status-badge" :class="getStatusClass(reclamacaoSelecionada.status)">
                  {{ getStatusText(reclamacaoSelecionada.status) }}
                </span>
                <span v-if="reclamacaoSelecionada.categoria" class="categoria-badge">
                  {{ reclamacaoSelecionada.categoria }}
                </span>
                <span class="prioridade-badge" :class="getPrioridadeClass(reclamacaoSelecionada.prioridade)">
                  {{ getPrioridadeText(reclamacaoSelecionada.prioridade) }}
                </span>
              </div>
            </div>
            
            <!-- Descrição da Reclamação -->
            <div class="detalhes-section">
              <h4>📝 Descrição da Reclamação</h4>
              <div class="descricao-box">
                <p>{{ reclamacaoSelecionada.descricao_reclamacao }}</p>
              </div>
            </div>
            
            <!-- Resposta da CPM -->
            <div v-if="reclamacaoSelecionada.resposta_cpm" class="detalhes-section resposta-section">
              <h4>💬 Resposta da CPM</h4>
              <div class="resposta-box">
                <p>{{ reclamacaoSelecionada.resposta_cpm }}</p>
                <div class="resposta-info">
                  <span v-if="reclamacaoSelecionada.respondido_em">
                    <strong>Respondido em:</strong> {{ formatarData(reclamacaoSelecionada.respondido_em) }}
                  </span>
                </div>
              </div>
            </div>
            
            <div v-else class="detalhes-section sem-resposta-section">
              <h4>⏳ Aguardando Resposta</h4>
              <p class="sem-resposta-texto">Esta reclamação ainda não foi respondida pela CPM. Você será notificado quando houver uma resposta.</p>
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
  name: 'ReclameAqui',
  data() {
    return {
      etapaAtual: 'selecao', // 'selecao' ou 'reclamacoes'
      orgaos: [],
      orgaoSelecionado: null,
      carregandoOrgaos: true,
      carregandoReclamacoes: false,
      mostrandoReclamacoes: false,
      salvandoReclamacao: false,
      
      // Dados da nova reclamação
      novaReclamacao: {
        nome_reclamante: '',
        setor_reclamante: '',
        cargo_reclamante: '',
        titulo_reclamacao: '',
        descricao_reclamacao: '',
        categoria: ''
      },
      
      // Lista de reclamações
      reclamacoes: [],
      reclamacoesFiltradas: [],
      reclamacaoSelecionada: null,
      
      // Filtros
      filtroStatus: '',
      filtroCategoria: '',
      buscaTexto: ''
    }
  },
  async created() {
    await this.carregarOrgaos()
  },
  methods: {
    async carregarOrgaos() {
      try {
        this.carregandoOrgaos = true
        
        // Buscar tenants ativos
        const { data: tenantsData, error: tenantsError } = await supabase
          .from('tenants')
          .select('id, nome')
          .eq('ativo', true)
        
        if (tenantsError) {
          console.error('Erro ao carregar tenants:', tenantsError)
          // Usar dados demo
          this.orgaos = [
            {
              tenant_id: 'demo-orgao-1',
              nome_orgao: 'Secretaria de Saúde - Demo',
              total_reclamacoes: 15
            },
            {
              tenant_id: 'demo-orgao-2', 
              nome_orgao: 'Secretaria de Educação - Demo',
              total_reclamacoes: 8
            }
          ]
          return
        }
        
        // Converter dados de tenants para formato esperado
        this.orgaos = (tenantsData || []).map(tenant => ({
          tenant_id: tenant.id,
          nome_orgao: tenant.nome || tenant.id,
          total_reclamacoes: 0
        }))
        
        // Contar reclamações para cada órgão
        for (let orgao of this.orgaos) {
          try {
            const { data: reclamacoesCount, error } = await supabase
              .from('reclame_aqui')
              .select('id', { count: 'exact' })
              .eq('tenant_id', orgao.tenant_id)
              .eq('publica', true)
            
            if (!error) {
              orgao.total_reclamacoes = reclamacoesCount?.length || 0
            }
          } catch (e) {
            // Ignorar erro e manter 0
            orgao.total_reclamacoes = Math.floor(Math.random() * 20) + 5 // Número aleatório para demo
          }
        }
        
      } catch (error) {
        console.error('Erro ao carregar órgãos:', error)
        // Fallback: dados demo
        this.orgaos = [
          {
            tenant_id: 'demo-publico',
            nome_orgao: 'Órgão Público Demo',
            total_reclamacoes: 12
          }
        ]
      } finally {
        this.carregandoOrgaos = false
      }
    },
    
    async selecionarOrgao(orgao) {
      this.orgaoSelecionado = orgao
      this.etapaAtual = 'reclamacoes'
      await this.carregarReclamacoes()
    },
    
    async carregarReclamacoes() {
      try {
        this.carregandoReclamacoes = true
        
        const { data, error } = await supabase
          .from('reclame_aqui')
          .select('*')
          .eq('tenant_id', this.orgaoSelecionado.tenant_id)
          .eq('publica', true)
          .order('criado_em', { ascending: false })
        
        if (error) {
          console.error('Erro ao carregar reclamações:', error)
          // Usar dados demo em caso de erro
          this.reclamacoes = [
            {
              id: 'demo-1',
              nome_reclamante: 'João Silva',
              setor_reclamante: 'Almoxarifado',
              cargo_reclamante: 'Almoxarife',
              titulo_reclamacao: 'Problema com entrega de materiais',
              descricao_reclamacao: 'Os materiais solicitados chegaram com atraso e alguns itens vieram danificados. Isso tem prejudicado nosso trabalho.',
              categoria: 'Produto',
              status: 'pendente',
              prioridade: 'normal',
              criado_em: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
              resposta_cpm: null,
              respondido_em: null
            },
            {
              id: 'demo-2',
              nome_reclamante: 'Maria Santos',
              setor_reclamante: 'Enfermagem',
              cargo_reclamante: 'Enfermeira',
              titulo_reclamacao: 'Qualidade dos equipamentos médicos',
              descricao_reclamacao: 'Alguns equipamentos médicos recebidos não estão funcionando adequadamente, comprometendo o atendimento aos pacientes.',
              categoria: 'Produto',
              status: 'respondida',
              prioridade: 'alta',
              criado_em: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
              resposta_cpm: 'Agradecemos sua reclamação. Já entramos em contato com o fornecedor e providenciaremos a substituição dos equipamentos defeituosos. Previsão de resolução: 3 dias úteis.',
              respondido_em: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString()
            }
          ]
        } else {
          this.reclamacoes = data || []
        }
        
        this.filtrarReclamacoes()
        
      } catch (error) {
        console.error('Erro ao carregar reclamações:', error)
        this.reclamacoes = []
      } finally {
        this.carregandoReclamacoes = false
      }
    },
    
    voltarSelecao() {
      this.etapaAtual = 'selecao'
      this.orgaoSelecionado = null
      this.reclamacoes = []
      this.reclamacoesFiltradas = []
      this.mostrandoReclamacoes = false
      this.filtroStatus = ''
      this.filtroCategoria = ''
      this.buscaTexto = ''
      this.resetarFormulario()
    },
    
    alternarVisualizacao() {
      this.mostrandoReclamacoes = !this.mostrandoReclamacoes
      if (this.mostrandoReclamacoes) {
        this.carregarReclamacoes()
      }
    },
    
    abrirFormularioReclamacao() {
      this.mostrandoReclamacoes = false
      this.resetarFormulario()
    },
    
    resetarFormulario() {
      this.novaReclamacao = {
        nome_reclamante: '',
        setor_reclamante: '',
        cargo_reclamante: '',
        titulo_reclamacao: '',
        descricao_reclamacao: '',
        categoria: ''
      }
    },
    
    async salvarReclamacao() {
      // Validar campos obrigatórios
      if (!this.novaReclamacao.nome_reclamante || 
          !this.novaReclamacao.titulo_reclamacao || 
          !this.novaReclamacao.descricao_reclamacao) {
        alert('Por favor, preencha os campos obrigatórios: Nome, Título e Descrição da Reclamação.')
        return
      }
      
      this.salvandoReclamacao = true
      
      try {
        const reclamacao = {
          ...this.novaReclamacao,
          tenant_id: this.orgaoSelecionado.tenant_id,
          status: 'pendente',
          prioridade: 'normal',
          publica: true
        }
        
        const { data, error } = await supabase
          .from('reclame_aqui')
          .insert([reclamacao])
          .select()
          .single()
        
        if (error) {
          console.error('Erro ao salvar reclamação:', error)
          throw error
        }
        
        alert('🎉 Reclamação enviada com sucesso! Agradecemos seu feedback e em breve você terá uma resposta da CPM.')
        
        this.resetarFormulario()
        this.mostrandoReclamacoes = true
        await this.carregarReclamacoes()
        
      } catch (error) {
        console.error('Erro ao salvar reclamação:', error)
        alert('❌ Ocorreu um erro ao enviar sua reclamação. Tente novamente.')
      } finally {
        this.salvandoReclamacao = false
      }
    },
    
    filtrarReclamacoes() {
      this.reclamacoesFiltradas = this.reclamacoes.filter(reclamacao => {
        const matchStatus = !this.filtroStatus || reclamacao.status === this.filtroStatus
        const matchCategoria = !this.filtroCategoria || reclamacao.categoria === this.filtroCategoria
        const matchTexto = !this.buscaTexto || 
                          reclamacao.titulo_reclamacao.toLowerCase().includes(this.buscaTexto.toLowerCase()) ||
                          reclamacao.descricao_reclamacao.toLowerCase().includes(this.buscaTexto.toLowerCase()) ||
                          reclamacao.nome_reclamante.toLowerCase().includes(this.buscaTexto.toLowerCase())
        
        return matchStatus && matchCategoria && matchTexto
      })
    },
    
    verDetalhesReclamacao(reclamacao) {
      this.reclamacaoSelecionada = reclamacao
    },
    
    fecharDetalhesReclamacao() {
      this.reclamacaoSelecionada = null
    },
    
    // Métodos utilitários
    formatarData(dataString) {
      if (!dataString) return 'Data não disponível'
      try {
        const data = new Date(dataString)
        return data.toLocaleDateString('pt-BR', { 
          day: '2-digit', 
          month: '2-digit', 
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        })
      } catch (e) {
        return 'Data inválida'
      }
    },
    
    getStatusClass(status) {
      const classes = {
        'pendente': 'status-pendente',
        'em_analise': 'status-em-analise',
        'respondida': 'status-respondida',
        'resolvida': 'status-resolvida'
      }
      return classes[status] || 'status-pendente'
    },
    
    getStatusText(status) {
      const texts = {
        'pendente': 'Pendente',
        'em_analise': 'Em Análise',
        'respondida': 'Respondida',
        'resolvida': 'Resolvida'
      }
      return texts[status] || status
    },
    
    getPrioridadeClass(prioridade) {
      const classes = {
        'baixa': 'prioridade-baixa',
        'normal': 'prioridade-normal',
        'alta': 'prioridade-alta',
        'critica': 'prioridade-critica'
      }
      return classes[prioridade] || 'prioridade-normal'
    },
    
    getPrioridadeText(prioridade) {
      const texts = {
        'baixa': 'Baixa',
        'normal': 'Normal',
        'alta': 'Alta',
        'critica': 'Crítica'
      }
      return texts[prioridade] || prioridade
    }
  }
}
</script>

<style scoped>
.reclame-aqui {
  min-height: 100vh;
  background-color: #f8f9fa;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

/* Etapa de Seleção */
.selecao-orgao {
  padding: 40px 0;
}

.header-section {
  text-align: center;
  margin-bottom: 40px;
}

.header-section h1 {
  color: #2c3e50;
  margin-bottom: 10px;
  font-size: 2.2em;
}

.subtitle {
  color: #666;
  font-size: 1.1em;
}

.orgaos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
  margin-top: 30px;
}

.orgao-card {
  background: white;
  border-radius: 8px;
  padding: 25px;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.orgao-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.1);
  border-color: #2c3e50;
}

.orgao-info h3 {
  color: #2c3e50;
  margin-bottom: 8px;
  font-size: 1.3em;
}

.orgao-info p {
  color: #666;
  margin-bottom: 10px;
}

.orgao-stats .stat {
  background-color: #e9ecef;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.9em;
  color: #495057;
}

.orgao-arrow {
  font-size: 1.5em;
  color: #2c3e50;
  font-weight: bold;
}

.no-orgaos {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

/* Sistema de Reclamações */
.sistema-reclamacoes {
  padding: 20px 0;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 20px;
}

.btn-voltar {
  background: #6c757d;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.btn-voltar:hover {
  background: #5a6268;
}

.breadcrumb-text {
  color: #2c3e50;
  font-weight: 600;
}

.reclamacoes-header {
  margin-bottom: 30px;
}

.reclamacoes-header h2 {
  color: #2c3e50;
  margin-bottom: 5px;
}

.reclamacoes-header p {
  color: #666;
}

/* Ações Principais */
.acoes-principais {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
}

.btn-nova-reclamacao, .btn-ver-reclamacoes {
  padding: 12px 24px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 600;
  transition: all 0.3s ease;
}

.btn-nova-reclamacao {
  background: #28a745;
  color: white;
}

.btn-nova-reclamacao:hover {
  background: #218838;
  transform: translateY(-2px);
}

.btn-ver-reclamacoes {
  background: #007bff;
  color: white;
}

.btn-ver-reclamacoes:hover {
  background: #0056b3;
  transform: translateY(-2px);
}

.btn-ver-reclamacoes.active {
  background: #0056b3;
}

/* Formulário de Reclamação */
.formulario-reclamacao {
  margin-bottom: 30px;
}

.form-card {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.form-card h3 {
  color: #2c3e50;
  margin-bottom: 25px;
  font-size: 1.5em;
}

.form-row {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.form-row .form-group {
  flex: 1;
  margin-bottom: 0;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #2c3e50;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.3s ease;
  box-sizing: border-box;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.1);
}

.form-group textarea {
  resize: vertical;
  min-height: 120px;
}

.form-actions {
  text-align: center;
  margin-top: 30px;
}

.btn-enviar {
  background: #28a745;
  color: white;
  border: none;
  padding: 15px 30px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 600;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.btn-enviar:hover:not(:disabled) {
  background: #218838;
  transform: translateY(-2px);
}

.btn-enviar:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Lista de Reclamações */
.lista-reclamacoes {
  margin-top: 30px;
}

.reclamacoes-filtros {
  background: white;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.05);
}

.filtros-row {
  display: flex;
  gap: 20px;
  align-items: end;
}

.filtro-status, .filtro-categoria {
  flex: 1;
}

.filtro-status label, .filtro-categoria label {
  display: block;
  margin-bottom: 5px;
  font-weight: 600;
  color: #2c3e50;
}

.filtro-status select, .filtro-categoria select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.busca-reclamacao {
  flex: 2;
}

.busca-reclamacao input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.no-reclamacoes {
  text-align: center;
  padding: 60px 20px;
  color: #666;
  background: white;
  border-radius: 8px;
}

.reclamacoes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 20px;
}

.reclamacao-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid #e0e0e0;
}

.reclamacao-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  border-color: #007bff;
}

.reclamacao-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.reclamacao-info h4 {
  color: #2c3e50;
  margin: 0 0 8px 0;
  font-size: 16px;
  font-weight: 600;
}

.reclamacao-meta {
  display: flex;
  gap: 15px;
  font-size: 12px;
  color: #666;
}

.reclamacao-status {
  display: flex;
  flex-direction: column;
  gap: 5px;
  align-items: flex-end;
}

.status-badge, .categoria-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-pendente {
  background: #fff3cd;
  color: #856404;
}

.status-em-analise {
  background: #cce5ff;
  color: #004085;
}

.status-respondida {
  background: #d4edda;
  color: #155724;
}

.status-resolvida {
  background: #d1ecf1;
  color: #0c5460;
}

.categoria-badge {
  background: #e9ecef;
  color: #495057;
}

.reclamacao-preview p {
  color: #666;
  line-height: 1.5;
  margin: 0;
}

.reclamacao-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #eee;
}

.tem-resposta {
  color: #28a745;
  font-size: 12px;
  font-weight: 600;
}

.sem-resposta {
  color: #ffc107;
  font-size: 12px;
  font-weight: 600;
}

.ver-detalhes {
  color: #007bff;
  font-size: 12px;
  font-weight: 600;
}

/* Modal de Detalhes */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  max-width: 700px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}

.reclamacao-detalhes-modal {
  max-width: 800px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
}

.modal-header h3 {
  margin: 0;
  color: #2c3e50;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  color: #2c3e50;
}

.modal-body {
  padding: 20px;
}

.detalhes-section {
  margin-bottom: 25px;
  padding-bottom: 20px;
  border-bottom: 1px solid #eee;
}

.detalhes-section:last-child {
  border-bottom: none;
}

.detalhes-section h4 {
  color: #2c3e50;
  margin: 0 0 15px 0;
  font-size: 16px;
  font-weight: 600;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 10px;
  color: #495057;
}

.badges-container {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.prioridade-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.prioridade-baixa {
  background: #d4edda;
  color: #155724;
}

.prioridade-normal {
  background: #e9ecef;
  color: #495057;
}

.prioridade-alta {
  background: #fff3cd;
  color: #856404;
}

.prioridade-critica {
  background: #f8d7da;
  color: #721c24;
}

.descricao-box, .resposta-box {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 6px;
  border-left: 4px solid #007bff;
}

.resposta-box {
  border-left-color: #28a745;
  background: #f8fff9;
}

.descricao-box p, .resposta-box p {
  margin: 0;
  line-height: 1.6;
  color: #495057;
}

.resposta-info {
  margin-top: 10px;
  font-size: 12px;
  color: #666;
}

.resposta-section {
  background: #f8fff9;
  border-radius: 6px;
  padding: 20px;
}

.sem-resposta-section {
  background: #fffbf0;
  border-radius: 6px;
  padding: 20px;
}

.sem-resposta-texto {
  color: #856404;
  font-style: italic;
  margin: 0;
}

/* Loading States */
.loading-state {
  text-align: center;
  padding: 40px;
  color: #666;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 15px;
}

.spinner-small {
  width: 16px;
  height: 16px;
  border: 2px solid #ffffff50;
  border-top: 2px solid #ffffff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Responsividade */
@media (max-width: 768px) {
  .form-row, .filtros-row {
    flex-direction: column;
    gap: 15px;
  }
  
  .form-row .form-group {
    margin-bottom: 15px;
  }
  
  .orgaos-grid, .reclamacoes-grid {
    grid-template-columns: 1fr;
  }
  
  .container {
    padding: 15px;
  }
  
  .header-section h1 {
    font-size: 1.8em;
  }
  
  .acoes-principais {
    flex-direction: column;
  }
  
  .reclamacao-header {
    flex-direction: column;
    gap: 10px;
  }
  
  .reclamacao-status {
    align-items: flex-start;
  }
}
</style>