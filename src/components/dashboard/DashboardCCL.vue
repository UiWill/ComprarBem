<template>
  <div class="dashboard">
    <h2>Painel Comissão de Contratação ou Licitação</h2>
    
    <div class="tabs">
      <div 
        class="tab" 
        :class="{ active: activeTab === 'dashboard' }" 
        @click="activeTab = 'dashboard'"
      >
        Dashboard
        <span v-if="notificacoes.filter(n => !n.lido).length > 0" class="tab-notification">
          {{ notificacoes.filter(n => !n.lido).length }}
        </span>
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'atas' }" 
        @click="activeTab = 'atas'"
      >
        Atas de Julgamento
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'homologacoes' }" 
        @click="activeTab = 'homologacoes'"
      >
        Homologações
      </div>
    </div>
    
    <!-- Aba Dashboard -->
    <div v-if="activeTab === 'dashboard'">
      <div class="stats-container">
        <div class="stat-card status-pendente-card">
          <div class="stat-icon">⚖️</div>
          <h3>Processos em Julgamento</h3>
          <div class="stat-value">{{ pendentes }}</div>
          <p class="stat-description">Aguardando decisão da CCL</p>
        </div>
        
        <div class="stat-card status-aprovado-card">
          <div class="stat-icon">✅</div>
          <h3>Homologações</h3>
          <div class="stat-value">{{ aprovados }}</div>
          <p class="stat-description">Processos homologados este mês</p>
        </div>
        
        <div class="stat-card status-diligencia-card">
          <div class="stat-icon">📋</div>
          <h3>Processos com Diligências</h3>
          <div class="stat-value">{{ diligencias }}</div>
          <p class="stat-description">Solicitação de documentação</p>
        </div>
        
        <div class="stat-card status-recurso-card" :class="{ 'stat-card-alert': prazosVencidos > 0 }">
          <div class="stat-icon">📄</div>
          <h3>Recursos em Análise</h3>
          <div class="stat-value">
            {{ recursosEmAnalise }}
            <span v-if="prazosVencidos > 0" class="alert-badge">
              {{ prazosVencidos }} vencido{{ prazosVencidos > 1 ? 's' : '' }}
            </span>
          </div>
          <p class="stat-description">Aguardando julgamento</p>
        </div>
      </div>
      
      <div class="dashboard-section">
        <div class="section-header">
          <h3>📋 Processos Pendentes de Julgamento</h3>
          <p class="section-description">
            Processos analisados pela CPM que aguardam julgamento pela Comissão de Contratação ou Licitação (CCL)
          </p>
        </div>
        <table v-if="produtosPendentes.length > 0">
          <thead>
            <tr>
              <th>Nome do Produto</th>
              <th>Marca/Modelo</th>
              <th>Fornecedor</th>
              <th>Categoria</th>
              <th>Parecer CPM</th>
              <th>Data Análise</th>
              <th>Prazo CCL</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in produtosPendentes" :key="produto.id">
              <td class="produto-info">
                <strong>{{ produto.nome }}</strong>
                <br>
                <small>{{ produto.modelo || 'Modelo não informado' }}</small>
              </td>
              <td>{{ produto.marca }}</td>
              <td>{{ produto.fabricante || 'Não informado' }}</td>
              <td>{{ getCategoriaName(produto.categoria_id) }}</td>
              <td>
                <span class="status-badge" :class="getStatusClass(produto.status)">
                  {{ formatarStatusCPM(produto.status) }}
                </span>
              </td>
              <td>{{ formatDate(produto.criado_em) }}</td>
              <td>
                <span class="prazo-badge" :class="getPrazoClass(produto.criado_em)">
                  {{ calcularPrazoRestante(produto.criado_em) }}
                </span>
              </td>
              <td>
                <button @click="julgarProcesso(produto)" class="btn-small btn-primary">
                  ⚖️ Julgar
                </button>
                <button @click="visualizarDocumentacao(produto)" class="btn-small btn-secondary">
                  📄 Docs
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-else class="empty-state">
          <div class="empty-icon">⚖️</div>
          <h4>Não há processos pendentes de julgamento</h4>
          <p>Todos os processos analisados pela CPM já foram julgados pela CCL.</p>
        </div>
      </div>

      <!-- Alertas e Notificações -->
      <div v-if="notificacoes.filter(n => !n.lido).length > 0" class="alertas-section">
        <div class="alertas-header">
          <h3>🚨 Alertas Críticos</h3>
          <button @click="marcarTodosComoLidos" class="btn-link">
            Marcar todos como lidos
          </button>
        </div>
        <div class="alertas-grid">
          <div v-for="alerta in notificacoes.filter(n => !n.lido)" :key="alerta.id" 
               class="alerta-card" 
               :class="alerta.tipo">
            <div class="alerta-icon">
              {{ getAlertaIcon(alerta.tipo) }}
            </div>
            <div class="alerta-content">
              <h5>{{ alerta.titulo }}</h5>
              <p>{{ alerta.mensagem }}</p>
              <small>{{ formatDate(alerta.criado_em) }}</small>
            </div>
            <div class="alerta-actions">
              <button @click="abrirAlerta(alerta)" class="btn-small btn-primary">
                Ver Detalhes
              </button>
              <button @click="marcarComoLido(alerta.id)" class="btn-small btn-secondary">
                ✓ Lido
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <div class="dashboard-section">
        <div class="section-header">
          <h3>📄 Recursos em Análise</h3>
          <p class="section-description">
            Recursos apresentados contra decisões da CCL que aguardam julgamento (prazo: 3 dias úteis - art. 165 da Lei 14.133/2021)
          </p>
        </div>
        <table v-if="recursos.length > 0">
          <thead>
            <tr>
              <th>Recorrente</th>
              <th>Produto/Ata</th>
              <th>Data do Recurso</th>
              <th>Prazo Final</th>
              <th>Status</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="recurso in recursos" :key="recurso.id">
              <td>{{ recurso.recorrente }}</td>
              <td>
                <strong>{{ recurso.produto_nome }}</strong>
                <br>
                <small>{{ recurso.ata_referencia }}</small>
              </td>
              <td>{{ formatDate(recurso.data_recurso) }}</td>
              <td>
                <span class="prazo-badge" :class="getPrazoRecursoClass(recurso.prazo_final)">
                  {{ formatDate(recurso.prazo_final) }}
                </span>
              </td>
              <td>
                <span class="status-badge" :class="getRecursoStatusClass(recurso.status)">
                  {{ recurso.status }}
                </span>
              </td>
              <td>
                <button @click="analisarRecurso(recurso)" class="btn-small btn-primary">
                  📋 Analisar
                </button>
                <button @click="visualizarDocumentacaoRecurso(recurso)" class="btn-small btn-secondary">
                  📄 Docs
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-else class="empty-state">
          <div class="empty-icon">📄</div>
          <h4>Não há recursos em análise</h4>
          <p>Todas as decisões da CCL estão dentro do prazo recursal ou já foram julgadas.</p>
        </div>
      </div>
    </div>
    
    <!-- Aba Atas de Julgamento -->
    <div v-if="activeTab === 'atas'" class="atas-julgamento">
      <div class="atas-header">
        <h3>📋 Atas de Julgamento</h3>
        <p class="atas-description">
          Gerenciamento de atas de julgamento da Comissão de Contratação ou Licitação (CCL) conforme art. 78, § 2º da Lei 14.133/2021
        </p>
        <div class="atas-actions">
          <button @click="criarNovaAta" class="btn-primary">
            ➕ Criar Nova Ata
          </button>
          <button @click="visualizarHistorico" class="btn-secondary">
            📊 Histórico Completo
          </button>
        </div>
      </div>

      <div class="atas-stats">
        <div class="ata-stat-card">
          <div class="ata-stat-icon">📋</div>
          <div class="ata-stat-info">
            <h4>{{ atasEmAndamento }}</h4>
            <p>Atas em Elaboração</p>
          </div>
        </div>
        <div class="ata-stat-card">
          <div class="ata-stat-icon">✅</div>
          <div class="ata-stat-info">
            <h4>{{ atasPublicadas }}</h4>
            <p>Atas Publicadas</p>
          </div>
        </div>
        <div class="ata-stat-card">
          <div class="ata-stat-icon">📄</div>
          <div class="ata-stat-info">
            <h4>{{ processosPendentes }}</h4>
            <p>Processos Pendentes</p>
          </div>
        </div>
      </div>

      <div class="atas-content">
        <!-- Atas em Elaboração -->
        <div class="atas-section">
          <h4>📝 Atas em Elaboração</h4>
          <div v-if="atasEmElaboracao.length > 0" class="atas-grid">
            <div v-for="ata in atasEmElaboracao" :key="ata.id" class="ata-card em-elaboracao">
              <div class="ata-card-header">
                <h5>{{ ata.numero }}</h5>
                <span class="ata-status status-elaboracao">Em Elaboração</span>
              </div>
              <div class="ata-card-content">
                <p><strong>Período:</strong> {{ ata.periodo }}</p>
                <p><strong>Processos:</strong> {{ ata.totalProcessos }} processos</p>
                <p><strong>Iniciado em:</strong> {{ formatDate(ata.dataInicio) }}</p>
              </div>
              <div class="ata-card-actions">
                <button @click="editarAta(ata)" class="btn-small btn-primary">
                  ✏️ Continuar Edição
                </button>
                <button @click="finalizarAta(ata)" class="btn-small btn-success">
                  ✅ Finalizar
                </button>
              </div>
            </div>
          </div>
          <div v-else class="empty-message">
            <p>Não há atas em elaboração no momento.</p>
          </div>
        </div>

        <!-- Atas Recentes -->
        <div class="atas-section">
          <h4>📋 Atas Publicadas Recentemente</h4>
          <div class="atas-table-container">
            <table v-if="atasPublicadasRecentes.length > 0" class="atas-table">
              <thead>
                <tr>
                  <th>Número da Ata</th>
                  <th>Data Publicação</th>
                  <th>Período</th>
                  <th>Processos</th>
                  <th>Status Recursal</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="ata in atasPublicadasRecentes" :key="ata.id">
                  <td>
                    <strong>{{ ata.numero }}</strong>
                  </td>
                  <td>{{ formatDate(ata.dataPublicacao) }}</td>
                  <td>{{ ata.periodo }}</td>
                  <td>
                    <span class="badge-info">{{ ata.totalProcessos }} processos</span>
                  </td>
                  <td>
                    <span class="status-badge" :class="getStatusRecursalClass(ata.statusRecursal)">
                      {{ ata.statusRecursal }}
                    </span>
                  </td>
                  <td>
                    <button @click="visualizarAta(ata)" class="btn-small btn-secondary">
                      👁️ Visualizar
                    </button>
                    <button @click="baixarPDF(ata)" class="btn-small btn-primary">
                      📥 PDF
                    </button>
                    <button v-if="ata.statusRecursal === 'EM PRAZO'" 
                            @click="gerenciarRecursos(ata)" 
                            class="btn-small btn-warning">
                      📄 Recursos
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
            <div v-else class="empty-message">
              <p>Não há atas publicadas recentemente.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Aba Homologações -->
    <div v-if="activeTab === 'homologacoes'" class="homologacoes">
      <div class="homologacoes-header">
        <h3>📋 Homologações</h3>
        <p class="homologacoes-description">
          Gestão de atos de homologação pela autoridade competente conforme Passo 8 dos documentos oficiais
        </p>
        <div class="homologacoes-actions">
          <button @click="consultarPendentes" class="btn-primary">
            📋 Processos Pendentes
          </button>
          <button @click="relatorioHomologacoes" class="btn-secondary">
            📊 Relatório Geral
          </button>
        </div>
      </div>

      <div class="homologacoes-stats">
        <div class="homo-stat-card pending">
          <div class="homo-stat-icon">⏳</div>
          <div class="homo-stat-info">
            <h4>{{ homologacoesPendentes }}</h4>
            <p>Aguardando Homologação</p>
            <small>Atas julgadas pela CCL</small>
          </div>
        </div>
        <div class="homo-stat-card approved">
          <div class="homo-stat-icon">✅</div>
          <div class="homo-stat-info">
            <h4>{{ homologacoesAprovadas }}</h4>
            <p>Homologadas</p>
            <small>Este mês</small>
          </div>
        </div>
        <div class="homo-stat-card rejected">
          <div class="homo-stat-icon">❌</div>
          <div class="homo-stat-info">
            <h4>{{ homologacoesIndeferidas }}</h4>
            <p>Indeferidas</p>
            <small>Este mês</small>
          </div>
        </div>
        <div class="homo-stat-card dcb">
          <div class="homo-stat-icon">📜</div>
          <div class="homo-stat-info">
            <h4>{{ dcbsEmitidas }}</h4>
            <p>DCBs Emitidas</p>
            <small>Total ativo</small>
          </div>
        </div>
      </div>

      <div class="homologacoes-content">
        <!-- Processos Pendentes de Homologação -->
        <div class="homo-section">
          <div class="homo-section-header">
            <h4>⏳ Processos Aguardando Homologação</h4>
            <span class="homo-count">{{ processosPendentesHomologacao.length }} processos</span>
          </div>
          <div v-if="processosPendentesHomologacao.length > 0" class="homo-table-container">
            <table class="homo-table">
              <thead>
                <tr>
                  <th>Número da Ata</th>
                  <th>Data Julgamento</th>
                  <th>Produtos</th>
                  <th>Decisão CCL</th>
                  <th>Recursos</th>
                  <th>Prazo</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="processo in processosPendentesHomologacao" :key="processo.id">
                  <td><strong>{{ processo.numeroAta }}</strong></td>
                  <td>{{ formatDate(processo.dataJulgamento) }}</td>
                  <td>
                    <span class="badge-info">{{ processo.totalProdutos }} produtos</span>
                  </td>
                  <td>
                    <span class="status-badge status-aprovado">{{ processo.decisaoCCL }}</span>
                  </td>
                  <td>
                    <span class="status-badge" :class="getRecursoStatusClass(processo.statusRecursos)">
                      {{ processo.statusRecursos }}
                    </span>
                  </td>
                  <td>
                    <span class="prazo-badge" :class="getPrazoHomologacaoClass(processo.dataJulgamento)">
                      {{ calcularPrazoHomologacao(processo.dataJulgamento) }}
                    </span>
                  </td>
                  <td>
                    <button @click="homologarProcesso(processo)" class="btn-small btn-success">
                      ✅ Homologar
                    </button>
                    <button @click="indeferirProcesso(processo)" class="btn-small btn-danger">
                      ❌ Indeferir
                    </button>
                    <button @click="visualizarAta(processo)" class="btn-small btn-secondary">
                      👁️ Ver Ata
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="empty-message">
            <div class="empty-icon">⚖️</div>
            <h4>Não há processos pendentes de homologação</h4>
            <p>Todos os processos julgados pela CCL já foram homologados.</p>
          </div>
        </div>

        <!-- Homologações Recentes -->
        <div class="homo-section">
          <div class="homo-section-header">
            <h4>📋 Homologações Recentes</h4>
            <button @click="verTodas" class="btn-link">Ver todas</button>
          </div>
          <div v-if="homologacoesRecentes.length > 0" class="homo-cards-grid">
            <div v-for="homo in homologacoesRecentes" :key="homo.id" class="homo-card">
              <div class="homo-card-header">
                <div class="homo-card-status" :class="homo.tipo">
                  <span class="homo-status-icon">{{ homo.tipo === 'homologada' ? '✅' : '❌' }}</span>
                  <span class="homo-status-text">{{ homo.tipo === 'homologada' ? 'HOMOLOGADA' : 'INDEFERIDA' }}</span>
                </div>
                <span class="homo-date">{{ formatDate(homo.dataHomologacao) }}</span>
              </div>
              <div class="homo-card-content">
                <h5>{{ homo.numeroAta }}</h5>
                <p><strong>Produtos:</strong> {{ homo.totalProdutos }}</p>
                <p><strong>Autoridade:</strong> {{ homo.autoridade }}</p>
                <p><strong>Motivo:</strong> {{ homo.motivo }}</p>
              </div>
              <div class="homo-card-actions">
                <button @click="baixarPDFHomologacao(homo)" class="btn-small btn-primary">
                  📥 PDF
                </button>
                <button @click="visualizarDCBs(homo)" class="btn-small btn-secondary">
                  📜 DCBs
                </button>
                <button @click="notificarFornecedores(homo)" class="btn-small btn-info">
                  📧 Notificar
                </button>
              </div>
            </div>
          </div>
          <div v-else class="empty-message">
            <p>Não há homologações recentes.</p>
          </div>
        </div>

        <!-- DCBs Ativas -->
        <div class="homo-section">
          <div class="homo-section-header">
            <h4>📜 Declarações de Conformidade de Bem (DCBs) Ativas</h4>
            <button @click="gerenciarDCBs" class="btn-link">Gerenciar todas</button>
          </div>
          <div v-if="dcbsAtivas.length > 0" class="dcb-grid">
            <div v-for="dcb in dcbsAtivas" :key="dcb.id" class="dcb-card">
              <div class="dcb-header">
                <span class="dcb-number">DCB {{ dcb.numero }}/{{ dcb.ano }}</span>
                <span class="dcb-status" :class="getDCBStatusClass(dcb.status)">{{ dcb.status }}</span>
              </div>
              <div class="dcb-content">
                <h6>{{ dcb.produto }}</h6>
                <p><strong>Marca:</strong> {{ dcb.marca }}</p>
                <p><strong>Validade:</strong> {{ formatDate(dcb.validade) }}</p>
                <p><strong>Emitida em:</strong> {{ formatDate(dcb.dataEmissao) }}</p>
              </div>
              <div class="dcb-actions">
                <button @click="visualizarDCB(dcb)" class="btn-small btn-primary">
                  👁️ Visualizar
                </button>
                <button @click="renovarDCB(dcb)" class="btn-small btn-warning">
                  🔄 Renovar
                </button>
                <button @click="cancelarDCB(dcb)" class="btn-small btn-danger">
                  ❌ Cancelar
                </button>
              </div>
            </div>
          </div>
          <div v-else class="empty-message">
            <p>Não há DCBs ativas no momento.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'DashboardCCL',
  data() {
    return {
      activeTab: 'dashboard',
      produtosPendentes: [],
      atasRecentes: [],
      pendentes: 0,
      aprovados: 0,
      diligencias: 0,
      recursosEmAnalise: 0,
      categorias: [],
      currentTenantId: null,
      loading: false,
      recursos: [],
      // Sistema de notificações
      notificacoes: [],
      prazosVencidos: 0,
      prazosUrgentes: 0,
      autoCheckInterval: null,
      // Dados para Atas de Julgamento
      atasEmAndamento: 0,
      atasPublicadas: 0,
      processosPendentes: 0,
      atasEmElaboracao: [],
      atasPublicadasRecentes: [],
      // Dados para Homologações
      homologacoesPendentes: 0,
      homologacoesAprovadas: 0,
      homologacoesIndeferidas: 0,
      dcbsEmitidas: 0,
      processosPendentesHomologacao: [],
      homologacoesRecentes: [],
      dcbsAtivas: []
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarDados()
      this.carregarCategorias()
      this.carregarAtasJulgamento()
      this.carregarAtasEmElaboracao()
      this.carregarHomologacoes()
      this.carregarProcessosPendentesHomologacao()
      this.carregarDCBsAtivas()
      this.iniciarMonitoramentoPrazos()
    })
  },
  beforeUnmount() {
    // Limpar interval ao destruir componente
    if (this.autoCheckInterval) {
      clearInterval(this.autoCheckInterval)
    }
  },
  methods: {
    async obterTenantId() {
      try {
        // Tenta obter o tenant_id do usuário logado
        const { data } = await supabase.auth.getSession()
        const user = data?.session?.user
        
        if (!user) {
          console.error('Usuário não está autenticado')
          return
        }
        
        // Primeiro tenta obter dos metadados
        if (user.user_metadata?.tenant_id) {
          this.currentTenantId = user.user_metadata.tenant_id
          return
        }
        
        // Se não estiver nos metadados, tenta buscar na tabela usuarios
        const { data: userData, error: userError } = await supabase
          .from('usuarios')
          .select('tenant_id')
          .eq('email', user.email)
          .single()
        
        if (userError) {
          console.error('Erro ao buscar tenant_id:', userError)
          return
        }
        
        if (userData?.tenant_id) {
          this.currentTenantId = userData.tenant_id
        } else {
          console.error('Tenant ID não encontrado para o usuário')
        }
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
      }
    },
    async carregarCategorias() {
      try {
        const { data, error } = await supabase
          .from('categorias')
          .select('*')
        
        if (error) throw error
        
        this.categorias = data || []
      } catch (error) {
        console.error('Erro ao carregar categorias:', error)
      }
    },
    getCategoriaName(categoriaId) {
      const categoria = this.categorias.find(cat => cat.id === categoriaId)
      return categoria ? categoria.nome : 'Categoria não encontrada'
    },
    async carregarDados() {
      try {
        this.loading = true
        
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível')
          return
        }
        
        // Carregar produtos pendentes
        const { data: pendentesData, error: pendentesError } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['aprovado', 'reprovado']) // produtos já analisados pela CPM, pendentes de julgamento pela CCL
          .order('criado_em', { ascending: false })
          .limit(10)
        
        if (pendentesError) throw pendentesError
        
        this.produtosPendentes = pendentesData || []
        
        // Carregar recursos do banco de dados
        await this.carregarRecursos()
        
        // Fallback: se não há recursos no banco, inicializar array vazio
        if (!this.recursos) {
          this.recursos = []
        }
        
        // Contar por status - ajustado para o fluxo correto da CCL
        const statsCounts = await Promise.all([
          this.contarPorStatus(['aprovado', 'reprovado']), // CPM já analisou, CCL precisa julgar
          this.contarPorStatus('homologado'), // Processos homologados
          this.contarPorStatus('diligencia') // Em diligência
        ])
        
        this.pendentes = statsCounts[0] || this.produtosPendentes.length
        this.aprovados = statsCounts[1]
        this.diligencias = statsCounts[2]
        
        // Contar recursos em análise
        this.recursosEmAnalise = this.recursos.filter(r => r.status === 'EM ANÁLISE' || r.status === 'AGUARDANDO CPM').length
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
      } finally {
        this.loading = false
      }
    },
    async contarPorStatus(status) {
      if (!this.currentTenantId) return 0
      
      let query = supabase
        .from('produtos')
        .select('id', { count: 'exact' })
        .eq('tenant_id', this.currentTenantId)
      
      if (Array.isArray(status)) {
        query = query.in('status', status)
      } else {
        query = query.eq('status', status)
      }
      
      const { count, error } = await query
      
      if (error) {
        console.error(`Erro ao contar produtos ${status}:`, error)
        return 0
      }
      
      return count || 0
    },
    formatDate(dateString) {
      if (!dateString) return ''
      
      // Se for uma data no formato ISO
      if (dateString.includes('T')) {
        const date = new Date(dateString)
        return date.toLocaleDateString('pt-BR')
      }
      
      // Se for uma data no formato YYYY-MM-DD
      const parts = dateString.split('-')
      if (parts.length === 3) {
        return `${parts[2]}/${parts[1]}/${parts[0]}`
      }
      
      return dateString
    },
    formatarStatus(status) {
      switch (status) {
        case 'pendente': return 'Em avaliação'
        case 'aprovado': return 'Em Diligência'
        case 'reprovado': return 'Em Análise'
        case 'diligencia': return 'Em diligência'
        default: return status
      }
    },
    formatarStatusCPM(status) {
      switch (status) {
        case 'aprovado': return 'Favorável'
        case 'reprovado': return 'Desfavorável'
        case 'diligencia': return 'Com Diligência'
        case 'pendente': return 'Em Análise'
        default: return status
      }
    },
    calcularPrazoRestante(dataAnalise) {
      if (!dataAnalise) return 'Sem prazo'
      
      const hoje = new Date()
      const prazoFinal = this.adicionarDiasUteis(new Date(dataAnalise), 10) // 10 dias úteis reais
      
      if (hoje > prazoFinal) return 'Vencido'
      
      const diasUteisRestantes = this.calcularDiasUteisEntre(hoje, prazoFinal)
      
      if (diasUteisRestantes === 0) return 'Hoje (último dia útil)'
      if (diasUteisRestantes === 1) return '1 dia útil'
      return `${diasUteisRestantes} dias úteis`
    },
    getPrazoClass(dataAnalise) {
      if (!dataAnalise) return 'prazo-indefinido'
      
      const hoje = new Date()
      const prazoFinal = this.adicionarDiasUteis(new Date(dataAnalise), 10) // 10 dias úteis reais
      
      if (hoje > prazoFinal) return 'prazo-vencido'
      
      const diasUteisRestantes = this.calcularDiasUteisEntre(hoje, prazoFinal)
      
      if (diasUteisRestantes <= 1) return 'prazo-urgente'
      if (diasUteisRestantes <= 3) return 'prazo-atencao'
      return 'prazo-normal'
    },
    async julgarProcesso(produto) {
      // Buscar informações técnicas completas do produto
      const informacoesTecnicas = await this.buscarInformacoesTecnicasProduto(produto.id)
      
      this.$swal({
        title: '⚖️ Julgamento CCL - Análise Técnica Completa',
        html: `
          <div style="text-align: left; padding: 15px; max-height: 600px; overflow-y: auto;">
            <!-- Cabeçalho do Processo -->
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h3 style="margin: 0 0 10px 0; color: #2c3e50;">📋 Dados do Processo</h3>
              <p><strong>Produto:</strong> ${produto.nome}</p>
              <p><strong>Marca/Modelo:</strong> ${produto.marca} ${produto.modelo || ''}</p>
              <p><strong>Fabricante:</strong> ${produto.fabricante || 'Não informado'}</p>
              <p><strong>Categoria:</strong> ${this.getCategoriaName(produto.categoria_id)}</p>
              <p><strong>Data de Cadastro:</strong> ${this.formatDate(produto.criado_em)}</p>
            </div>

            <!-- Parecer Técnico da CPM -->
            <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 10px 0; color: #1976d2;">🔬 Parecer Técnico da CPM</h4>
              <p><strong>Status:</strong> <span style="color: ${this.getStatusColor(produto.status)}; font-weight: bold;">${this.formatarStatusCPM(produto.status)}</span></p>
              <p><strong>Data da Análise:</strong> ${this.formatDate(produto.atualizado_em)}</p>
              ${produto.observacoes_cpm ? `<p><strong>Observações CPM:</strong> ${produto.observacoes_cpm}</p>` : ''}
              ${informacoesTecnicas.laudos ? `<p><strong>Laudos Técnicos:</strong> ${informacoesTecnicas.laudos}</p>` : ''}
              ${informacoesTecnicas.amostras ? `<p><strong>Amostras Testadas:</strong> ${informacoesTecnicas.amostras}</p>` : ''}
            </div>

            <!-- Documentação Técnica -->
            <div style="background: #fff3e0; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 10px 0; color: #f57c00;">📄 Documentação Técnica</h4>
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; font-size: 14px;">
                <label><input type="checkbox" id="doc_catalogo" checked disabled> Catálogo Técnico</label>
                <label><input type="checkbox" id="doc_manual" checked disabled> Manual do Produto</label>
                <label><input type="checkbox" id="doc_certificados" checked disabled> Certificados (ABNT/ISO)</label>
                <label><input type="checkbox" id="doc_laudos" checked disabled> Laudos de Laboratório</label>
                <label><input type="checkbox" id="doc_normas" checked disabled> Atendimento a Normas</label>
                <label><input type="checkbox" id="doc_garantia" checked disabled> Termo de Garantia</label>
              </div>
            </div>

            <!-- Análise de Conformidade -->
            <div style="background: #f3e5f5; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 15px 0; color: #7b1fa2;">✅ Análise de Conformidade CCL</h4>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 8px;">🔍 Adequação às Especificações Técnicas:</label>
                <select id="adequacao_tecnica" class="swal2-select" style="width: 100%; margin-bottom: 5px;">
                  <option value="">Selecione...</option>
                  <option value="plenamente_adequado">Plenamente Adequado</option>
                  <option value="adequado_ressalvas">Adequado com Ressalvas</option>
                  <option value="inadequado">Inadequado</option>
                </select>
              </div>

              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 8px;">📋 Atendimento aos Requisitos Mínimos:</label>
                <select id="requisitos_minimos" class="swal2-select" style="width: 100%; margin-bottom: 5px;">
                  <option value="">Selecione...</option>
                  <option value="atende_plenamente">Atende Plenamente</option>
                  <option value="atende_parcialmente">Atende Parcialmente</option>
                  <option value="nao_atende">Não Atende</option>
                </select>
              </div>

              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 8px;">⚖️ Conformidade Legal (Lei 14.133/2021):</label>
                <select id="conformidade_legal" class="swal2-select" style="width: 100%; margin-bottom: 5px;">
                  <option value="">Selecione...</option>
                  <option value="conforme">Conforme</option>
                  <option value="nao_conforme">Não Conforme</option>
                </select>
              </div>
            </div>

            <!-- Decisão da CCL -->
            <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 15px 0; color: #388e3c;">⚖️ Decisão da CCL</h4>
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 8px;">Decisão Final:</label>
                <select id="decisaoCCL" class="swal2-select" style="width: 100%;">
                  <option value="">Selecione uma decisão</option>
                  <option value="homologado">✅ Homologar (Aprovar pré-qualificação)</option>
                  <option value="indeferido">❌ Indeferir (Rejeitar pré-qualificação)</option>
                  <option value="diligencia">📋 Solicitar Diligência à CPM</option>
                  <option value="pendencia">⏳ Aguardar Documentação Complementar</option>
                </select>
              </div>
            </div>

            <!-- Fundamentação -->
            <div style="background: #fff8e1; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
              <h4 style="margin: 0 0 15px 0; color: #f9a825;">📝 Fundamentação da Decisão</h4>
              <textarea id="fundamentacao" class="swal2-textarea" placeholder="Fundamentação técnica e jurídica da decisão (obrigatório - art. 5º Lei 14.133/2021)..." style="height: 120px; width: 100%;"></textarea>
              
              <div style="margin-top: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 8px;">📚 Base Legal/Normativa:</label>
                <textarea id="base_legal" class="swal2-textarea" placeholder="Cite artigos da Lei 14.133/2021, normas técnicas (ABNT) e outros dispositivos aplicáveis..." style="height: 80px; width: 100%;"></textarea>
              </div>
            </div>

            <!-- Informações Adicionais -->
            <div style="background: #f5f5f5; padding: 15px; border-radius: 8px;">
              <h4 style="margin: 0 0 15px 0; color: #424242;">📋 Informações Complementares</h4>
              <div style="margin-bottom: 10px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Observações da CCL:</label>
                <textarea id="observacoes_ccl" class="swal2-textarea" placeholder="Observações adicionais (opcional)..." style="height: 60px; width: 100%;"></textarea>
              </div>
              
              <div style="margin-top: 15px;">
                <label><input type="checkbox" id="incluir_ata" checked> Incluir na próxima Ata de Julgamento</label>
              </div>
              
              <div style="margin-top: 10px; font-size: 12px; color: #666;">
                <strong>Nota:</strong> Esta decisão será registrada conforme art. 78, § 2º da Lei 14.133/2021 e incluída na Ata de Julgamento da CCL.
              </div>
            </div>
          </div>
        `,
        width: '900px',
        showCancelButton: true,
        confirmButtonText: '⚖️ Confirmar Julgamento',
        cancelButtonText: '❌ Cancelar',
        confirmButtonColor: '#2e7d32',
        cancelButtonColor: '#d32f2f',
        preConfirm: () => {
          const decisao = document.getElementById('decisaoCCL').value
          const fundamentacao = document.getElementById('fundamentacao').value.trim()
          const baseLegal = document.getElementById('base_legal').value.trim()
          const adequacaoTecnica = document.getElementById('adequacao_tecnica').value
          const requisitosMinimos = document.getElementById('requisitos_minimos').value
          const conformidadeLegal = document.getElementById('conformidade_legal').value
          const observacoesCcl = document.getElementById('observacoes_ccl').value.trim()
          const incluirAta = document.getElementById('incluir_ata').checked
          
          // Validações obrigatórias
          if (!decisao) {
            this.$swal.showValidationMessage('Selecione uma decisão da CCL')
            return false
          }
          if (!fundamentacao) {
            this.$swal.showValidationMessage('A fundamentação é obrigatória (art. 5º Lei 14.133/2021)')
            return false
          }
          if (!adequacaoTecnica) {
            this.$swal.showValidationMessage('Informe a adequação às especificações técnicas')
            return false
          }
          if (!requisitosMinimos) {
            this.$swal.showValidationMessage('Informe o atendimento aos requisitos mínimos')
            return false
          }
          if (!conformidadeLegal) {
            this.$swal.showValidationMessage('Informe a conformidade legal')
            return false
          }
          
          return { 
            decisao, 
            fundamentacao, 
            baseLegal,
            adequacaoTecnica,
            requisitosMinimos, 
            conformidadeLegal,
            observacoesCcl,
            incluirAta
          }
        }
      }).then(async (result) => {
        if (result.isConfirmed) {
          try {
            // Salvar julgamento no banco de dados
            await this.salvarJulgamentoCCL(produto, result.value)
            
            this.$swal({
              title: '⚖️ Julgamento Registrado',
              text: 'A decisão da CCL foi registrada com sucesso e será incluída na próxima ata de julgamento.',
              icon: 'success',
              confirmButtonText: '✅ OK'
            })
            
            // Recarregar dados
            await this.carregarDados()
            
          } catch (error) {
            this.$swal({
              title: '❌ Erro',
              text: `Erro ao registrar julgamento: ${error.message}`,
              icon: 'error'
            })
          }
        }
      })
    },
    
    async buscarInformacoesTecnicasProduto(produtoId) {
      try {
        // Buscar informações técnicas adicionais do produto
        const { data, error } = await supabase
          .from('produtos')
          .select('observacoes_cpm, laudos_tecnicos, amostras_testadas')
          .eq('id', produtoId)
          .single()
        
        if (error) {
          console.error('Erro ao buscar informações técnicas:', error)
          return {}
        }
        
        return {
          laudos: data?.laudos_tecnicos || 'Não informado',
          amostras: data?.amostras_testadas || 'Não informado'
        }
      } catch (error) {
        console.error('Erro ao buscar informações técnicas:', error)
        return {}
      }
    },
    
    getStatusColor(status) {
      switch (status) {
        case 'aprovado': return '#4caf50'
        case 'reprovado': return '#f44336'
        case 'diligencia': return '#ff9800'
        case 'pendente': return '#2196f3'
        default: return '#666'
      }
    },
    
    async salvarJulgamentoCCL(produto, julgamento) {
      try {
        // Atualizar status do produto baseado na decisão da CCL
        const novoStatus = this.mapearDecisaoParaStatus(julgamento.decisao)
        
        const { error: errorProduto } = await supabase
          .from('produtos')
          .update({
            status: novoStatus,
            observacoes_ccl: julgamento.fundamentacao,
            adequacao_tecnica: julgamento.adequacaoTecnica,
            requisitos_minimos: julgamento.requisitosMinimos,
            conformidade_legal: julgamento.conformidadeLegal,
            base_legal: julgamento.baseLegal,
            observacoes_ccl_adicional: julgamento.observacoesCcl,
            julgado_em: new Date().toISOString(),
            atualizado_em: new Date().toISOString()
          })
          .eq('id', produto.id)
        
        if (errorProduto) {
          throw new Error(`Erro ao atualizar produto: ${errorProduto.message}`)
        }
        
        // Se for para incluir na ata e a decisão for homologada, pode criar entrada para futura ata
        if (julgamento.incluirAta && julgamento.decisao === 'homologado') {
          // Aqui poderia ser implementada a lógica para incluir na próxima ata
          console.log('Produto será incluído na próxima ata de julgamento')
        }
        
        console.log('Julgamento CCL salvo com sucesso para produto:', produto.id)
        
      } catch (error) {
        console.error('Erro ao salvar julgamento CCL:', error)
        throw error
      }
    },
    
    mapearDecisaoParaStatus(decisao) {
      switch (decisao) {
        case 'homologado': return 'julgado_aprovado'
        case 'indeferido': return 'julgado_reprovado'
        case 'diligencia': return 'diligencia'
        case 'pendencia': return 'pendencia_documentacao'
        default: return 'julgamento_pendente'
      }
    },
    
    // ==================== SISTEMA DE CÁLCULO DE DIAS ÚTEIS ====================
    
    getFeriadosNacionais(ano) {
      // Feriados fixos nacionais
      const feriadosFixos = [
        `${ano}-01-01`, // Confraternização Universal
        `${ano}-04-21`, // Tiradentes
        `${ano}-05-01`, // Dia do Trabalhador
        `${ano}-09-07`, // Independência do Brasil
        `${ano}-10-12`, // Nossa Senhora Aparecida
        `${ano}-11-02`, // Finados
        `${ano}-11-15`, // Proclamação da República
        `${ano}-12-25`, // Natal
      ]
      
      // Feriados móveis (Carnaval, Páscoa, etc.) - simplificado para 2024/2025
      const feriadosMoveis = []
      if (ano === 2024) {
        feriadosMoveis.push(
          '2024-02-12', // Carnaval (Segunda)
          '2024-02-13', // Carnaval (Terça)
          '2024-03-29', // Sexta-feira Santa
          '2024-05-30', // Corpus Christi
        )
      } else if (ano === 2025) {
        feriadosMoveis.push(
          '2025-03-03', // Carnaval (Segunda)
          '2025-03-04', // Carnaval (Terça)
          '2025-04-18', // Sexta-feira Santa
          '2025-06-19', // Corpus Christi
        )
      }
      
      return [...feriadosFixos, ...feriadosMoveis]
    },
    
    isFeriado(data) {
      const dataStr = data.toISOString().split('T')[0] // Format YYYY-MM-DD
      const ano = data.getFullYear()
      const feriados = this.getFeriadosNacionais(ano)
      return feriados.includes(dataStr)
    },
    
    isFimDeSemana(data) {
      const diaSemana = data.getDay()
      return diaSemana === 0 || diaSemana === 6 // Domingo = 0, Sábado = 6
    },
    
    isDiaUtil(data) {
      return !this.isFimDeSemana(data) && !this.isFeriado(data)
    },
    
    adicionarDiasUteis(dataInicial, diasUteis) {
      const data = new Date(dataInicial)
      let diasAdicionados = 0
      
      while (diasAdicionados < diasUteis) {
        data.setDate(data.getDate() + 1)
        if (this.isDiaUtil(data)) {
          diasAdicionados++
        }
      }
      
      return data
    },
    
    calcularDiasUteisEntre(dataInicial, dataFinal) {
      const inicio = new Date(dataInicial)
      const fim = new Date(dataFinal)
      let diasUteis = 0
      const dataAtual = new Date(inicio)
      
      while (dataAtual <= fim) {
        if (this.isDiaUtil(dataAtual)) {
          diasUteis++
        }
        dataAtual.setDate(dataAtual.getDate() + 1)
      }
      
      return diasUteis
    },
    
    calcularPrazoRecursal(dataPublicacao, diasUteis = 3) {
      const dataFinal = this.adicionarDiasUteis(new Date(dataPublicacao), diasUteis)
      return dataFinal
    },
    
    calcularPrazoHomologacaoUtil(dataJulgamento, diasUteis = 10) {
      const dataFinal = this.adicionarDiasUteis(new Date(dataJulgamento), diasUteis)
      return dataFinal
    },
    
    getPrazoRecursoClass(prazoFinal) {
      if (!prazoFinal) return 'prazo-indefinido'
      
      const hoje = new Date()
      const prazo = new Date(prazoFinal)
      
      if (hoje > prazo) return 'prazo-vencido'
      
      const diasUteisRestantes = this.calcularDiasUteisEntre(hoje, prazo)
      
      if (diasUteisRestantes <= 0) return 'prazo-urgente'
      if (diasUteisRestantes <= 1) return 'prazo-atencao'
      return 'prazo-normal'
    },
    
    // ==================== MÉTODOS ATUALIZADOS COM DIAS ÚTEIS ====================
    
    visualizarDocumentacao(produto) {
      this.$swal({
        title: '📄 Documentação do Processo',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Produto: ${produto.nome}</h4>
            <p><strong>Marca:</strong> ${produto.marca}</p>
            <hr>
            <h5>Documentos Disponíveis:</h5>
            <ul style="text-align: left;">
              <li>📋 Parecer Técnico da CPM</li>
              <li>📑 Documentação do Fornecedor</li>
              <li>🔬 Laudos Técnicos</li>
              <li>📝 Ata de Recebimento de Amostras</li>
              <li>📄 Edital de Chamamento Público</li>
            </ul>
            <div style="margin-top: 20px;">
              <button class="swal2-confirm swal2-styled" onclick="window.open('/api/downloads/documentacao-completa.pdf', '_blank')">
                📥 Baixar Documentação Completa
              </button>
            </div>
          </div>
        `,
        showConfirmButton: false,
        showCancelButton: true,
        cancelButtonText: '❌ Fechar'
      })
    },
    getStatusClass(status) {
      switch (status) {
        case 'aprovado': return 'status-aprovado'
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        case 'diligencia': return 'status-diligencia'
        default: return ''
      }
    },
    publicarDecisao(id) {
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, abriria um formulário para registrar a decisão da comissão e publicar no Diário Oficial.',
        icon: 'info'
      })
    },
    visualizarAta(id) {
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, exibiria o documento da ata de julgamento e permitiria fazer download.',
        icon: 'info'
      })
    },
    getRecursoStatusClass(status) {
      switch (status) {
        case 'EM ANÁLISE': return 'status-pendente'
        case 'DEFERIDO': return 'status-aprovado'
        case 'INDEFERIDO': return 'status-reprovado'
        default: return ''
      }
    },
    async carregarRecursos() {
      try {
        if (!this.currentTenantId) return
        
        // Carregar recursos do banco de dados
        const { data: recursosData, error } = await supabase
          .from('recursos')
          .select(`
            id,
            ata_referencia,
            recorrente,
            produto_nome,
            data_recurso,
            prazo_final,
            status,
            fundamentacao_recurso,
            decisao,
            fundamentacao_decisao,
            autoridade_decisao,
            criado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .order('data_recurso', { ascending: false })
          .limit(10)
        
        if (error) {
          console.error('Erro ao carregar recursos:', error)
          // Se houver erro, manter dados simulados como fallback
          return
        }
        
        // Se há dados no banco, usar eles; senão, manter simulados
        if (recursosData && recursosData.length > 0) {
          this.recursos = recursosData
          console.log('Recursos carregados do banco de dados:', recursosData.length)
        } else {
          console.log('Nenhum recurso encontrado no banco')
        }
        
      } catch (error) {
        console.error('Erro ao carregar recursos:', error)
        // Em caso de erro, manter array vazio
      }
    },
    
    async carregarAtasJulgamento() {
      try {
        if (!this.currentTenantId) return
        
        // Carregar atas de julgamento publicadas do banco de dados
        const { data: atasData, error } = await supabase
          .from('atas_julgamento')
          .select(`
            id,
            numero,
            data_publicacao,
            periodo,
            total_processos,
            status_ata,
            conteudo_ata,
            arquivo_pdf_url,
            data_inicio_prazo_recursal,
            data_fim_prazo_recursal,
            observacoes,
            criado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .neq('status_ata', 'ELABORACAO') // Filtrar apenas atas publicadas
          .order('data_publicacao', { ascending: false })
          .limit(10) // Limitar às 10 mais recentes
        
        if (error) {
          console.error('Erro ao carregar atas de julgamento:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (atasData && atasData.length > 0) {
          this.atasPublicadasRecentes = atasData.map(ata => ({
            id: ata.id,
            numero: ata.numero,
            dataPublicacao: ata.data_publicacao,
            periodo: ata.periodo,
            totalProcessos: ata.total_processos,
            statusRecursal: ata.status_ata,
            conteudoAta: ata.conteudo_ata,
            arquivoPdfUrl: ata.arquivo_pdf_url,
            dataInicioPrazoRecursal: ata.data_inicio_prazo_recursal,
            dataFimPrazoRecursal: ata.data_fim_prazo_recursal,
            observacoes: ata.observacoes,
            criadoEm: ata.criado_em
          }))
          // Atualizar contador de atas publicadas
          this.atasPublicadas = atasData.length
          console.log('Atas de julgamento carregadas do banco:', atasData.length)
        } else {
          this.atasPublicadas = 0
          console.log('Nenhuma ata de julgamento encontrada no banco')
        }
        
      } catch (error) {
        console.error('Erro ao carregar atas de julgamento:', error)
      }
    },
    
    async carregarAtasEmElaboracao() {
      try {
        if (!this.currentTenantId) return
        
        // Carregar atas em elaboração do banco de dados
        const { data: atasData, error } = await supabase
          .from('atas_julgamento')
          .select(`
            id,
            numero,
            periodo,
            total_processos,
            status_ata,
            data_inicio_elaboracao,
            responsavel_elaboracao,
            progresso_elaboracao,
            observacoes,
            criado_em,
            atualizado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .eq('status_ata', 'ELABORACAO') // Filtrar apenas atas em elaboração
          .order('data_inicio_elaboracao', { ascending: false })
        
        if (error) {
          console.error('Erro ao carregar atas em elaboração:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (atasData && atasData.length > 0) {
          this.atasEmElaboracao = atasData.map(ata => ({
            id: ata.id,
            numero: ata.numero,
            periodo: ata.periodo,
            totalProcessos: ata.total_processos,
            status: 'elaboracao',
            dataInicio: ata.data_inicio_elaboracao,
            responsavel: ata.responsavel_elaboracao,
            progresso: ata.progresso_elaboracao,
            observacoes: ata.observacoes,
            criadoEm: ata.criado_em,
            atualizadoEm: ata.atualizado_em
          }))
          // Atualizar contador de atas em andamento
          this.atasEmAndamento = atasData.length
          console.log('Atas em elaboração carregadas do banco:', atasData.length)
        } else {
          this.atasEmAndamento = 0
          console.log('Nenhuma ata em elaboração encontrada no banco')
        }
        
      } catch (error) {
        console.error('Erro ao carregar atas em elaboração:', error)
      }
    },
    
    async carregarHomologacoes() {
      try {
        if (!this.currentTenantId) return
        
        // Carregar homologações do banco de dados
        const { data: homologacoesData, error } = await supabase
          .from('homologacoes')
          .select(`
            id,
            numero_ata,
            data_homologacao,
            tipo_homologacao,
            total_produtos,
            autoridade_competente,
            fundamentacao,
            arquivo_pdf_url,
            observacoes,
            criado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .order('data_homologacao', { ascending: false })
          .limit(10) // Limitar às 10 mais recentes
        
        if (error) {
          console.error('Erro ao carregar homologações:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (homologacoesData && homologacoesData.length > 0) {
          this.homologacoesRecentes = homologacoesData.map(homo => ({
            id: homo.id,
            numeroAta: homo.numero_ata,
            dataHomologacao: homo.data_homologacao,
            totalProdutos: homo.total_produtos,
            tipo: homo.tipo_homologacao.toLowerCase(),
            autoridade: homo.autoridade_competente,
            motivo: homo.fundamentacao,
            arquivoPdfUrl: homo.arquivo_pdf_url,
            observacoes: homo.observacoes,
            criadoEm: homo.criado_em
          }))
          
          // Atualizar contadores
          this.homologacoesAprovadas = homologacoesData.filter(h => h.tipo_homologacao === 'HOMOLOGADA').length
          this.homologacoesIndeferidas = homologacoesData.filter(h => h.tipo_homologacao === 'INDEFERIDA').length
          
          console.log('Homologações carregadas do banco:', homologacoesData.length)
        } else {
          console.log('Nenhuma homologação encontrada no banco')
        }
        
      } catch (error) {
        console.error('Erro ao carregar homologações:', error)
      }
    },
    
    async carregarProcessosPendentesHomologacao() {
      try {
        if (!this.currentTenantId) return
        
        // Buscar atas de julgamento publicadas que ainda não foram homologadas
        const { data: atasData, error } = await supabase
          .from('atas_julgamento')
          .select(`
            id,
            numero,
            data_publicacao,
            total_processos,
            status_ata,
            observacoes
          `)
          .eq('tenant_id', this.currentTenantId)
          .neq('status_ata', 'ELABORACAO')
          .not('id', 'in', `(SELECT ata_julgamento_id FROM homologacoes WHERE tenant_id = '${this.currentTenantId}')`)
          .order('data_publicacao', { ascending: true })
        
        if (error) {
          console.error('Erro ao carregar processos pendentes de homologação:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (atasData && atasData.length > 0) {
          this.processosPendentesHomologacao = atasData.map(ata => ({
            id: ata.id,
            numeroAta: ata.numero,
            dataJulgamento: ata.data_publicacao,
            totalProdutos: ata.total_processos,
            decisaoCCL: this.mapearStatusParaDecisao(ata.status_ata),
            statusRecursos: this.determinarStatusRecursos(ata.status_ata),
            observacoes: ata.observacoes
          }))
          
          this.homologacoesPendentes = atasData.length
          this.processosPendentes = atasData.length // Mesmo valor que homologações pendentes
          console.log('Processos pendentes de homologação carregados:', atasData.length)
        } else {
          this.homologacoesPendentes = 0
          this.processosPendentes = 0
          console.log('Nenhum processo pendente de homologação encontrado')
        }
        
      } catch (error) {
        console.error('Erro ao carregar processos pendentes de homologação:', error)
      }
    },
    
    mapearStatusParaDecisao(statusAta) {
      switch (statusAta) {
        case 'PUBLICADA_EM_PRAZO':
        case 'PUBLICADA_ENCERRADA':
          return 'APROVADA'
        case 'PUBLICADA_COM_RECURSOS':
          return 'APROVADA COM RECURSOS'
        case 'PUBLICADA_PRAZO_VENCIDO':
          return 'PARCIALMENTE APROVADA'
        default:
          return 'APROVADA'
      }
    },
    
    determinarStatusRecursos(statusAta) {
      switch (statusAta) {
        case 'PUBLICADA_EM_PRAZO':
          return 'EM PRAZO RECURSAL'
        case 'PUBLICADA_ENCERRADA':
          return 'SEM RECURSOS'
        case 'PUBLICADA_COM_RECURSOS':
          return 'RECURSOS JULGADOS'
        case 'PUBLICADA_PRAZO_VENCIDO':
          return 'PRAZO VENCIDO'
        default:
          return 'SEM RECURSOS'
      }
    },
    
    async carregarDCBsAtivas() {
      try {
        if (!this.currentTenantId) return
        
        // Primeiro, atualizar status das DCBs baseado na validade
        await supabase.rpc('atualizar_status_dcbs')
        
        // Carregar DCBs ativas e vencendo do banco de dados
        const { data: dcbsData, error } = await supabase
          .from('dcbs')
          .select(`
            id,
            numero_completo,
            numero,
            ano,
            produto_nome,
            marca,
            modelo,
            fabricante,
            data_emissao,
            data_validade,
            status_dcb,
            autoridade_emissora,
            arquivo_pdf_url,
            qr_code_data,
            observacoes,
            criado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status_dcb', ['ATIVA', 'VENCENDO'])
          .order('data_emissao', { ascending: false })
          .limit(20) // Limitar às 20 mais recentes
        
        if (error) {
          console.error('Erro ao carregar DCBs ativas:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (dcbsData && dcbsData.length > 0) {
          this.dcbsAtivas = dcbsData.map(dcb => ({
            id: dcb.id,
            numero: dcb.numero_completo,
            numeroSeparado: dcb.numero,
            ano: dcb.ano,
            produto: dcb.produto_nome,
            marca: dcb.marca,
            modelo: dcb.modelo,
            fabricante: dcb.fabricante,
            dataEmissao: dcb.data_emissao,
            validade: dcb.data_validade,
            status: dcb.status_dcb,
            autoridade: dcb.autoridade_emissora,
            arquivoPdf: dcb.arquivo_pdf_url,
            qrCode: dcb.qr_code_data,
            observacoes: dcb.observacoes,
            criadoEm: dcb.criado_em
          }))
          
          // Atualizar contador de DCBs emitidas (contar todas, não só as ativas)
          const { count } = await supabase
            .from('dcbs')
            .select('*', { count: 'exact', head: true })
            .eq('tenant_id', this.currentTenantId)
          
          this.dcbsEmitidas = count || 0
          
          console.log('DCBs ativas carregadas do banco:', dcbsData.length)
          console.log('Total de DCBs emitidas:', this.dcbsEmitidas)
        } else {
          console.log('Nenhuma DCB ativa encontrada no banco')
          this.dcbsEmitidas = 0
        }
        
      } catch (error) {
        console.error('Erro ao carregar DCBs ativas:', error)
      }
    },
    
    async gerarDCBsAutomaticamente(homologacao, processo) {
      try {
        // Buscar produtos relacionados à ata de julgamento
        const { data: produtos, error: errorProdutos } = await supabase
          .from('produtos')
          .select(`
            id,
            nome,
            marca,
            modelo,
            fabricante,
            status
          `)
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'aprovado') // Apenas produtos já aprovados pela CPM
          .limit(processo.totalProdutos || 50) // Limitar para evitar criar muitas DCBs
        
        if (errorProdutos) {
          console.error('Erro ao buscar produtos para DCB:', errorProdutos)
          return
        }
        
        if (!produtos || produtos.length === 0) {
          console.log('Nenhum produto aprovado encontrado para gerar DCBs')
          return
        }
        
        // Obter próximo número de DCB para o ano atual
        const anoAtual = new Date().getFullYear()
        
        // Gerar DCBs para cada produto
        const dcbsParaCriar = produtos.map((produto, index) => ({
          tenant_id: this.currentTenantId,
          homologacao_id: homologacao.id,
          produto_id: produto.id,
          numero: null, // Será definido pela função obter_proximo_numero_dcb
          ano: anoAtual,
          produto_nome: produto.nome,
          marca: produto.marca,
          modelo: produto.modelo || 'Não informado',
          fabricante: produto.fabricante || 'Não informado',
          data_emissao: homologacao.data_homologacao,
          data_validade: new Date(new Date(homologacao.data_homologacao).getTime() + 365 * 24 * 60 * 60 * 1000).toISOString(), // +1 ano
          status_dcb: 'ATIVA',
          autoridade_emissora: homologacao.autoridade_competente
        }))
        
        // Inserir DCBs com numeração automática
        for (const dcbData of dcbsParaCriar) {
          // Obter próximo número disponível
          const { data: proximoNumero, error: errorNumero } = await supabase
            .rpc('obter_proximo_numero_dcb', { 
              tenant_uuid: this.currentTenantId, 
              ano_dcb: anoAtual 
            })
          
          if (errorNumero) {
            console.error('Erro ao obter próximo número DCB:', errorNumero)
            continue
          }
          
          dcbData.numero = proximoNumero
          
          const { error: errorInsert } = await supabase
            .from('dcbs')
            .insert([dcbData])
          
          if (errorInsert) {
            console.error('Erro ao inserir DCB:', errorInsert)
          }
        }
        
        console.log(`${dcbsParaCriar.length} DCBs geradas automaticamente para homologação ${homologacao.numero_ata}`)
        
      } catch (error) {
        console.error('Erro ao gerar DCBs automaticamente:', error)
        throw error
      }
    },
    
    getPrazoRecursoClass(prazoFinal) {
      if (!prazoFinal) return 'prazo-indefinido'
      
      const prazo = new Date(prazoFinal)
      const hoje = new Date()
      const diffTime = prazo - hoje
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      
      if (diffDays < 0) return 'prazo-vencido'
      if (diffDays === 0) return 'prazo-urgente'
      if (diffDays <= 1) return 'prazo-urgente'
      return 'prazo-normal'
    },
    analisarRecurso(recurso) {
      this.$swal({
        title: '📋 Analisar Recurso',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Recurso: ${recurso.produto_nome}</h4>
            <p><strong>Recorrente:</strong> ${recurso.recorrente}</p>
            <p><strong>Ata:</strong> ${recurso.ata_referencia}</p>
            <p><strong>Data:</strong> ${this.formatDate(recurso.data_recurso)}</p>
            <p><strong>Prazo:</strong> ${this.formatDate(recurso.prazo_final)}</p>
            <hr>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Decisão sobre o Recurso:</label>
              <select id="decisaoRecurso" class="swal2-select" style="width: 100%;">
                <option value="">Selecione uma decisão</option>
                <option value="deferido">Deferir Recurso (Reverter decisão CCL)</option>
                <option value="indeferido">Indeferir Recurso (Manter decisão CCL)</option>
                <option value="encaminhar_cpm">Encaminhar para CPM</option>
              </select>
            </div>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Fundamentação:</label>
              <textarea id="fundamentacaoRecurso" class="swal2-textarea" placeholder="Justificativa da decisão..." style="height: 100px;"></textarea>
            </div>
            <div style="background: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Nota:</strong> A decisão será encaminhada para homologação pela autoridade competente.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '✅ Confirmar Decisão',
        cancelButtonText: '❌ Cancelar',
        preConfirm: () => {
          const decisao = document.getElementById('decisaoRecurso').value
          const fundamentacao = document.getElementById('fundamentacaoRecurso').value
          
          if (!decisao) {
            this.$swal.showValidationMessage('Selecione uma decisão')
            return false
          }
          if (!fundamentacao.trim()) {
            this.$swal.showValidationMessage('Informe a fundamentação da decisão')
            return false
          }
          
          return { decisao, fundamentacao }
        }
      }).then(async (result) => {
        if (result.isConfirmed) {
          try {
            // Salvar decisão no banco de dados
            const { error } = await supabase
              .from('recursos')
              .update({
                decisao: result.value.decisao,
                fundamentacao_decisao: result.value.fundamentacao,
                status: result.value.decisao === 'encaminhar_cpm' ? 'AGUARDANDO CPM' : 
                        result.value.decisao === 'deferido' ? 'DEFERIDO' : 'INDEFERIDO',
                atualizado_em: new Date().toISOString()
              })
              .eq('id', recurso.id)
              .eq('tenant_id', this.currentTenantId)
            
            if (error) {
              console.error('Erro ao salvar decisão:', error)
              this.$swal({
                title: '❌ Erro',
                text: 'Erro ao salvar a decisão. Tente novamente.',
                icon: 'error'
              })
              return
            }
            
            this.$swal({
              title: '✅ Recurso Analisado',
              text: 'A decisão foi registrada e será incluída na documentação oficial.',
              icon: 'success'
            })
            
            // Recarregar dados
            await this.carregarDados()
            
          } catch (error) {
            console.error('Erro ao processar decisão:', error)
            this.$swal({
              title: '❌ Erro',
              text: 'Erro ao processar a decisão. Tente novamente.',
              icon: 'error'
            })
          }
        }
      })
    },
    visualizarDocumentacaoRecurso(recurso) {
      this.$swal({
        title: '📄 Documentação do Recurso',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Recurso: ${recurso.produto_nome}</h4>
            <p><strong>Recorrente:</strong> ${recurso.recorrente}</p>
            <p><strong>Protocolo:</strong> ${recurso.id.toUpperCase()}</p>
            <hr>
            <h5>Documentos Disponíveis:</h5>
            <ul style="text-align: left;">
              <li>📋 Razões do Recurso</li>
              <li>📑 Ata de Julgamento Original (${recurso.ata_referencia})</li>
              <li>🔍 Documentação Técnica</li>
              <li>📝 Parecer da CPM</li>
              <li>⚖️ Fundamentação da CCL</li>
            </ul>
            <div style="background: #e3f2fd; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Prazo Final:</strong> ${this.formatDate(recurso.prazo_final)}</small>
            </div>
            <div style="margin-top: 15px;">
              <button class="swal2-confirm swal2-styled" onclick="window.open('/api/downloads/recurso-documentacao.pdf', '_blank')">
                📥 Baixar Documentação Completa
              </button>
            </div>
          </div>
        `,
        showConfirmButton: false,
        showCancelButton: true,
        cancelButtonText: '❌ Fechar'
      })
    },
    julgarRecurso(id) {
      // Método mantido para compatibilidade, mas agora redireciona para analisarRecurso
      const recurso = this.recursos.find(r => r.id === id)
      if (recurso) {
        this.analisarRecurso(recurso)
      }
    },
    
    // Método para criar novo recurso (se necessário)
    async criarRecurso(dadosRecurso) {
      try {
        if (!this.currentTenantId) {
          throw new Error('Tenant ID não disponível')
        }
        
        const { data, error } = await supabase
          .from('recursos')
          .insert([{
            tenant_id: this.currentTenantId,
            produto_id: dadosRecurso.produto_id,
            ata_referencia: dadosRecurso.ata_referencia,
            recorrente: dadosRecurso.recorrente,
            produto_nome: dadosRecurso.produto_nome,
            data_recurso: dadosRecurso.data_recurso,
            prazo_final: dadosRecurso.prazo_final,
            status: 'EM ANÁLISE',
            fundamentacao_recurso: dadosRecurso.fundamentacao_recurso
          }])
          .select()
        
        if (error) throw error
        
        // Recarregar dados após criação
        await this.carregarDados()
        
        return data[0]
      } catch (error) {
        console.error('Erro ao criar recurso:', error)
        throw error
      }
    },
    
    // Sistema de Notificações e Monitoramento de Prazos
    iniciarMonitoramentoPrazos() {
      // Verificação inicial
      this.verificarPrazos()
      
      // Verificar a cada 5 minutos (300000ms)
      this.autoCheckInterval = setInterval(() => {
        this.verificarPrazos()
      }, 300000)
      
      console.log('Sistema de monitoramento de prazos iniciado')
    },
    
    async verificarPrazos() {
      try {
        await this.verificarPrazosRecursos()
        await this.verificarPrazosJulgamento()
        await this.verificarPrazosHomologacao()
        
        this.atualizarContadoresAlertas()
        
      } catch (error) {
        console.error('Erro ao verificar prazos:', error)
      }
    },
    
    async verificarPrazosRecursos() {
      if (!this.recursos || this.recursos.length === 0) return
      
      const hoje = new Date()
      
      this.recursos.forEach(recurso => {
        const prazoFinal = new Date(recurso.prazo_final)
        const diffTime = prazoFinal - hoje
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
        
        // Recurso vencido
        if (diffDays < 0 && recurso.status === 'EM ANÁLISE') {
          this.criarNotificacao({
            tipo: 'prazo-vencido',
            titulo: 'Prazo de Recurso Vencido',
            mensagem: `Recurso de ${recurso.recorrente} para ${recurso.produto_nome} está ${Math.abs(diffDays)} dia(s) em atraso`,
            recurso_id: recurso.id,
            prioridade: 'alta'
          })
        }
        // Recurso urgente (vence em 1 dia)
        else if (diffDays <= 1 && diffDays >= 0 && recurso.status === 'EM ANÁLISE') {
          this.criarNotificacao({
            tipo: 'prazo-urgente',
            titulo: 'Prazo de Recurso Urgente',
            mensagem: `Recurso de ${recurso.recorrente} para ${recurso.produto_nome} vence ${diffDays === 0 ? 'hoje' : 'amanhã'}`,
            recurso_id: recurso.id,
            prioridade: 'media'
          })
        }
      })
    },
    
    async verificarPrazosJulgamento() {
      if (!this.produtosPendentes || this.produtosPendentes.length === 0) return
      
      const hoje = new Date()
      
      this.produtosPendentes.forEach(produto => {
        const dataAnalise = new Date(produto.criado_em)
        const prazoFinal = new Date(dataAnalise)
        prazoFinal.setDate(dataAnalise.getDate() + 10) // 10 dias úteis
        
        const diffTime = prazoFinal - hoje
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
        
        // Processo vencido
        if (diffDays < 0) {
          this.criarNotificacao({
            tipo: 'julgamento-vencido',
            titulo: 'Prazo de Julgamento Vencido',
            mensagem: `Produto ${produto.nome} está ${Math.abs(diffDays)} dia(s) sem julgamento da CCL`,
            produto_id: produto.id,
            prioridade: 'alta'
          })
        }
        // Processo urgente (vence em 2 dias)
        else if (diffDays <= 2 && diffDays >= 0) {
          this.criarNotificacao({
            tipo: 'julgamento-urgente',
            titulo: 'Julgamento Urgente Necessário',
            mensagem: `Produto ${produto.nome} precisa ser julgado em ${diffDays} dia(s)`,
            produto_id: produto.id,
            prioridade: 'media'
          })
        }
      })
    },
    
    async verificarPrazosHomologacao() {
      // Verificar processos aguardando homologação
      if (this.processosPendentesHomologacao && this.processosPendentesHomologacao.length > 0) {
        const hoje = new Date()
        
        this.processosPendentesHomologacao.forEach(processo => {
          const dataJulgamento = new Date(processo.dataJulgamento)
          const diffTime = hoje - dataJulgamento
          const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
          
          // Processo aguardando homologação há mais de 10 dias
          if (diffDays > 10) {
            this.criarNotificacao({
              tipo: 'homologacao-atrasada',
              titulo: 'Homologação Atrasada',
              mensagem: `Ata ${processo.numeroAta} aguarda homologação há ${diffDays} dias`,
              ata_id: processo.id,
              prioridade: 'alta'
            })
          }
          // Processo urgente (mais de 7 dias)
          else if (diffDays > 7) {
            this.criarNotificacao({
              tipo: 'homologacao-urgente',
              titulo: 'Homologação Pendente',
              mensagem: `Ata ${processo.numeroAta} aguarda homologação há ${diffDays} dias`,
              ata_id: processo.id,
              prioridade: 'media'
            })
          }
        })
      }
    },
    
    criarNotificacao(dados) {
      // Verificar se já existe notificação similar
      const existe = this.notificacoes.find(n => 
        n.tipo === dados.tipo && 
        (n.recurso_id === dados.recurso_id || n.produto_id === dados.produto_id || n.ata_id === dados.ata_id)
      )
      
      if (!existe) {
        const notificacao = {
          id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          ...dados,
          criado_em: new Date().toISOString(),
          lido: false
        }
        
        this.notificacoes.unshift(notificacao)
        
        // Limitar a 20 notificações
        if (this.notificacoes.length > 20) {
          this.notificacoes = this.notificacoes.slice(0, 20)
        }
        
        // Mostrar notificação toast para alertas críticos
        if (dados.prioridade === 'alta') {
          this.mostrarToast(notificacao)
        }
      }
    },
    
    atualizarContadoresAlertas() {
      this.prazosVencidos = this.notificacoes.filter(n => 
        n.tipo.includes('vencido') && !n.lido
      ).length
      
      this.prazosUrgentes = this.notificacoes.filter(n => 
        n.tipo.includes('urgente') && !n.lido
      ).length
    },
    
    getAlertaIcon(tipo) {
      switch (tipo) {
        case 'prazo-vencido':
        case 'julgamento-vencido':
        case 'homologacao-atrasada':
          return '🚨'
        case 'prazo-urgente':
        case 'julgamento-urgente':
        case 'homologacao-urgente':
          return '⚠️'
        default:
          return '📢'
      }
    },
    
    abrirAlerta(alerta) {
      let htmlContent = `
        <div style="text-align: left; padding: 15px;">
          <h4>${alerta.titulo}</h4>
          <p>${alerta.mensagem}</p>
          <hr>
          <small><strong>Criado em:</strong> ${this.formatDate(alerta.criado_em)}</small>
        `
      
      // Adicionar ações específicas baseado no tipo
      if (alerta.recurso_id) {
        const recurso = this.recursos.find(r => r.id === alerta.recurso_id)
        if (recurso) {
          htmlContent += `
            <div style="margin-top: 15px;">
              <button class="swal2-confirm swal2-styled" onclick="document.dispatchEvent(new CustomEvent('abrirRecurso', {detail: '${recurso.id}'}))">
                📋 Analisar Recurso
              </button>
            </div>
          `
        }
      }
      
      if (alerta.produto_id) {
        htmlContent += `
          <div style="margin-top: 15px;">
            <button class="swal2-confirm swal2-styled" onclick="document.dispatchEvent(new CustomEvent('abrirProduto', {detail: '${alerta.produto_id}'}))">
              ⚖️ Julgar Processo
            </button>
          </div>
        `
      }
      
      htmlContent += '</div>'
      
      this.$swal({
        title: '🚨 Detalhes do Alerta',
        html: htmlContent,
        showConfirmButton: false,
        showCancelButton: true,
        cancelButtonText: '❌ Fechar'
      })
      
      // Marcar como lido
      this.marcarComoLido(alerta.id)
    },
    
    marcarComoLido(alertaId) {
      const alerta = this.notificacoes.find(n => n.id === alertaId)
      if (alerta) {
        alerta.lido = true
        this.atualizarContadoresAlertas()
      }
    },
    
    marcarTodosComoLidos() {
      this.notificacoes.forEach(n => n.lido = true)
      this.atualizarContadoresAlertas()
    },
    
    mostrarToast(notificacao) {
      // Toast notification para alertas críticos
      this.$swal({
        title: notificacao.titulo,
        text: notificacao.mensagem,
        icon: 'warning',
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 8000,
        timerProgressBar: true
      })
    },
    
    // Métodos para Atas de Julgamento
    criarNovaAta() {
      this.$swal({
        title: '📋 Criar Nova Ata de Julgamento',
        html: `
          <div style="text-align: left; padding: 15px;">
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Período de Referência:</label>
              <input id="periodoAta" class="swal2-input" type="text" placeholder="Ex: Janeiro 2025" value="">
            </div>
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Número da Ata:</label>
              <input id="numeroAta" class="swal2-input" type="text" placeholder="Ex: ATA-CCL-008/2025" value="">
            </div>
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Descrição:</label>
              <textarea id="descricaoAta" class="swal2-textarea" placeholder="Descrição da ata de julgamento..." rows="3"></textarea>
            </div>
            <div style="background: #f8f9fa; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Nota:</strong> A ata incluirá automaticamente todos os processos julgados no período especificado.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '✅ Criar Ata',
        cancelButtonText: '❌ Cancelar',
        preConfirm: () => {
          const periodo = document.getElementById('periodoAta').value
          const numero = document.getElementById('numeroAta').value
          const descricao = document.getElementById('descricaoAta').value
          
          if (!periodo || !numero) {
            this.$swal.showValidationMessage('Preencha o período e número da ata')
            return false
          }
          
          return { periodo, numero, descricao }
        }
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: '✅ Ata Criada',
            text: 'Nova ata de julgamento criada com sucesso. Você pode agora editá-la e incluir os julgamentos.',
            icon: 'success'
          })
        }
      })
    },
    editarAta(ata) {
      this.$swal({
        title: '✏️ Editar Ata de Julgamento',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${ata.numero}</h4>
            <p><strong>Período:</strong> ${ata.periodo}</p>
            <p><strong>Processos incluídos:</strong> ${ata.totalProcessos}</p>
            <hr>
            <div style="margin: 15px 0;">
              <h5>Ações Disponíveis:</h5>
              <ul style="text-align: left; margin-left: 20px;">
                <li>Incluir novos julgamentos</li>
                <li>Editar julgamentos existentes</li>
                <li>Revisar fundamentações</li>
                <li>Verificar documentação</li>
                <li>Preparar para publicação</li>
              </ul>
            </div>
            <div style="background: #e3f2fd; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Status:</strong> Em elaboração - A ata pode ser editada até a publicação oficial.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '📝 Abrir Editor',
        cancelButtonText: '❌ Fechar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: 'Editor de Ata',
            text: 'Em uma implementação completa, abriria o editor completo da ata com todos os julgamentos.',
            icon: 'info'
          })
        }
      })
    },
    finalizarAta(ata) {
      this.$swal({
        title: '✅ Finalizar Ata de Julgamento',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${ata.numero}</h4>
            <p><strong>Período:</strong> ${ata.periodo}</p>
            <p><strong>Total de processos:</strong> ${ata.totalProcessos}</p>
            <hr>
            <div style="margin: 15px 0;">
              <h5>⚠️ Atenção:</h5>
              <p>Ao finalizar a ata:</p>
              <ul style="text-align: left; margin-left: 20px;">
                <li>Será gerado o documento PDF oficial</li>
                <li>Será publicado extrato no Diário Oficial</li>
                <li>Será aberto prazo recursal de 3 dias úteis</li>
                <li>A ata não poderá mais ser editada</li>
              </ul>
            </div>
            <div style="background: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Confirma a finalização?</strong> Esta ação não pode ser desfeita.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '✅ Confirmar Finalização',
        cancelButtonText: '❌ Cancelar',
        confirmButtonColor: '#28a745'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: '🎉 Ata Finalizada',
            text: 'Ata publicada com sucesso! Prazo recursal iniciado automaticamente.',
            icon: 'success'
          })
        }
      })
    },
    visualizarHistorico() {
      this.$swal({
        title: '📊 Histórico de Atas',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h5>Filtros de Pesquisa:</h5>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 15px;">
              <input type="date" class="swal2-input" placeholder="Data início" style="margin: 0;">
              <input type="date" class="swal2-input" placeholder="Data fim" style="margin: 0;">
            </div>
            <select class="swal2-select" style="margin-bottom: 15px;">
              <option value="">Todos os status</option>
              <option value="elaboracao">Em elaboração</option>
              <option value="publicada">Publicadas</option>
              <option value="prazo_recursal">Em prazo recursal</option>
              <option value="encerrada">Encerradas</option>
            </select>
            <hr>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 4px;">
              <h6>Estatísticas Gerais:</h6>
              <p>📋 Total de atas: 25</p>
              <p>✅ Atas publicadas: 23</p>
              <p>📄 Processos julgados: 284</p>
              <p>⚖️ Taxa de aprovação: 78%</p>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '🔍 Pesquisar',
        cancelButtonText: '❌ Fechar'
      })
    },
    getStatusRecursalClass(status) {
      switch (status) {
        case 'EM PRAZO': return 'status-em-prazo'
        case 'ENCERRADO': return 'status-encerrado'
        case 'COM RECURSOS': return 'status-com-recursos'
        default: return 'status-indefinido'
      }
    },
    baixarPDF(ata) {
      this.$swal({
        title: '📥 Download da Ata',
        text: `Baixando ata ${ata.numero} em formato PDF...`,
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      })
    },
    gerenciarRecursos(ata) {
      this.$swal({
        title: '📄 Gerenciar Recursos',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${ata.numero}</h4>
            <p><strong>Status:</strong> ${ata.statusRecursal}</p>
            <hr>
            <h5>Recursos Apresentados:</h5>
            <div style="background: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;">
              <p><strong>Fornecedor:</strong> Equipamentos Médicos LTDA</p>
              <p><strong>Produto:</strong> Monitor de Sinais Vitais</p>
              <p><strong>Data:</strong> 15/01/2025</p>
              <p><strong>Status:</strong> Aguardando análise CPM</p>
            </div>
            <div style="margin-top: 15px;">
              <button class="swal2-confirm swal2-styled" onclick="this.parentNode.parentNode.querySelector('.swal2-close').click()">
                📋 Analisar Recurso
              </button>
            </div>
          </div>
        `,
        showConfirmButton: false,
        showCancelButton: true,
        cancelButtonText: '❌ Fechar'
      })
    },
    // Métodos para Homologações
    calcularPrazoHomologacao(dataJulgamento) {
      if (!dataJulgamento) return 'Sem prazo'
      
      const data = new Date(dataJulgamento)
      const hoje = new Date()
      const prazoLimite = this.adicionarDiasUteis(data, 10) // 10 dias úteis para homologação
      
      if (hoje > prazoLimite) {
        const diasAtraso = this.calcularDiasUteisEntre(prazoLimite, hoje)
        return `Vencido há ${diasAtraso} dia${diasAtraso > 1 ? 's' : ''} úteis`
      }
      
      const diasRestantes = this.calcularDiasUteisEntre(hoje, prazoLimite)
      
      if (diasRestantes === 0) return 'Último dia útil'
      if (diasRestantes === 1) return '1 dia útil restante'
      return `${diasRestantes} dias úteis restantes`
    },
    getPrazoHomologacaoClass(dataJulgamento) {
      if (!dataJulgamento) return 'prazo-indefinido'
      
      const data = new Date(dataJulgamento)
      const hoje = new Date()
      const prazoLimite = this.adicionarDiasUteis(data, 10) // 10 dias úteis para homologação
      
      if (hoje > prazoLimite) return 'prazo-vencido'
      
      const diasRestantes = this.calcularDiasUteisEntre(hoje, prazoLimite)
      
      if (diasRestantes <= 1) return 'prazo-urgente'
      if (diasRestantes <= 3) return 'prazo-atencao'
      return 'prazo-normal'
    },
    homologarProcesso(processo) {
      this.$swal({
        title: '✅ Homologar Processo',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${processo.numeroAta}</h4>
            <p><strong>Produtos:</strong> ${processo.totalProdutos}</p>
            <p><strong>Decisão CCL:</strong> ${processo.decisaoCCL}</p>
            <hr>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Autoridade Competente:</label>
              <input id="autoridadeHomo" class="swal2-input" type="text" placeholder="Nome da autoridade" value="Dr. João Silva - Secretário">
            </div>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Fundamentação da Homologação:</label>
              <textarea id="fundamentacaoHomo" class="swal2-textarea" placeholder="Justificativa para homologação..." style="height: 100px;">Os processos foram conduzidos em conformidade com a Lei 14.133/2021 e demais normas aplicáveis, atendendo aos princípios da legalidade, impessoalidade e moralidade.</textarea>
            </div>
            <div style="background: #d4edda; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Efeitos:</strong> Serão emitidas as DCBs para os produtos aprovados e incluídos no Catálogo de Bens Padronizados.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '✅ Confirmar Homologação',
        cancelButtonText: '❌ Cancelar',
        confirmButtonColor: '#28a745',
        preConfirm: () => {
          const autoridade = document.getElementById('autoridadeHomo').value
          const fundamentacao = document.getElementById('fundamentacaoHomo').value
          
          if (!autoridade.trim() || !fundamentacao.trim()) {
            this.$swal.showValidationMessage('Preencha todos os campos obrigatórios')
            return false
          }
          
          return { autoridade, fundamentacao }
        }
      }).then(async (result) => {
        if (result.isConfirmed) {
          try {
            // Criar registro de homologação no banco
            const homologacaoData = {
              tenant_id: this.currentTenantId,
              ata_julgamento_id: processo.id,
              numero_ata: processo.numeroAta,
              data_homologacao: new Date().toISOString(),
              tipo_homologacao: 'HOMOLOGADA',
              total_produtos: processo.totalProdutos,
              autoridade_competente: result.value.autoridade,
              fundamentacao: result.value.fundamentacao
            }
            
            const { data: homologacao, error: errorHomologacao } = await supabase
              .from('homologacoes')
              .insert([homologacaoData])
              .select()
              .single()
            
            if (errorHomologacao) {
              throw new Error(`Erro ao criar homologação: ${errorHomologacao.message}`)
            }
            
            // Gerar DCBs automaticamente para produtos da ata homologada
            await this.gerarDCBsAutomaticamente(homologacao, processo)
            
            // Recarregar dados atualizados
            await this.carregarHomologacoes()
            await this.carregarProcessosPendentesHomologacao()
            await this.carregarDCBsAtivas()
            
            this.$swal({
              title: '🎉 Processo Homologado',
              text: 'O processo foi homologado com sucesso! As DCBs foram emitidas automaticamente.',
              icon: 'success'
            })
            
          } catch (error) {
            console.error('Erro ao homologar processo:', error)
            this.$swal({
              title: '❌ Erro',
              text: `Erro ao homologar processo: ${error.message}`,
              icon: 'error'
            })
          }
        }
      })
    },
    indeferirProcesso(processo) {
      this.$swal({
        title: '❌ Indeferir Processo',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${processo.numeroAta}</h4>
            <p><strong>Produtos:</strong> ${processo.totalProdutos}</p>
            <p><strong>Decisão CCL:</strong> ${processo.decisaoCCL}</p>
            <hr>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Motivo do Indeferimento:</label>
              <select id="motivoIndeferimento" class="swal2-select">
                <option value="">Selecione o motivo</option>
                <option value="irregularidade_processual">Irregularidade Processual</option>
                <option value="documentacao_incompleta">Documentação Incompleta</option>
                <option value="nao_atendimento_requisitos">Não Atendimento aos Requisitos</option>
                <option value="interesse_publico">Contrário ao Interesse Público</option>
                <option value="outros">Outros Motivos</option>
              </select>
            </div>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Fundamentação:</label>
              <textarea id="fundamentacaoIndeferimento" class="swal2-textarea" placeholder="Justificativa detalhada..." style="height: 100px;"></textarea>
            </div>
            <div style="background: #f8d7da; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Atenção:</strong> O indeferimento impedirá a emissão das DCBs e os produtos não serão incluídos no catálogo.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '❌ Confirmar Indeferimento',
        cancelButtonText: '🔙 Cancelar',
        confirmButtonColor: '#dc3545',
        preConfirm: () => {
          const motivo = document.getElementById('motivoIndeferimento').value
          const fundamentacao = document.getElementById('fundamentacaoIndeferimento').value
          
          if (!motivo || !fundamentacao.trim()) {
            this.$swal.showValidationMessage('Selecione o motivo e forneça a fundamentação')
            return false
          }
          
          return { motivo, fundamentacao }
        }
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: '📝 Processo Indeferido',
            text: 'O processo foi indeferido. Os interessados serão notificados automaticamente.',
            icon: 'warning'
          })
        }
      })
    },
    consultarPendentes() {
      this.$swal({
        title: '📋 Consulta de Processos Pendentes',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h5>Filtros de Pesquisa:</h5>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 15px;">
              <input type="date" class="swal2-input" placeholder="Data início" style="margin: 0;">
              <input type="date" class="swal2-input" placeholder="Data fim" style="margin: 0;">
            </div>
            <select class="swal2-select" style="margin-bottom: 15px;">
              <option value="">Todos os status de recursos</option>
              <option value="sem_recursos">Sem recursos</option>
              <option value="recursos_julgados">Recursos julgados</option>
              <option value="com_recursos_pendentes">Com recursos pendentes</option>
            </select>
            <hr>
            <div style="background: #e3f2fd; padding: 15px; border-radius: 4px;">
              <h6>Resumo de Pendências:</h6>
              <p>⏳ Aguardando homologação: ${this.homologacoesPendentes}</p>
              <p>📋 Atas sem recursos: 2</p>
              <p>📄 Atas com recursos julgados: 1</p>
              <p>⚡ Urgente (> 15 dias): 0</p>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '🔍 Aplicar Filtros',
        cancelButtonText: '❌ Fechar'
      })
    },
    relatorioHomologacoes() {
      this.$swal({
        title: '📊 Relatório de Homologações',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h5>Período do Relatório:</h5>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 15px;">
              <input type="date" class="swal2-input" placeholder="Data início" style="margin: 0;">
              <input type="date" class="swal2-input" placeholder="Data fim" style="margin: 0;">
            </div>
            <hr>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 4px;">
              <h6>Estatísticas Gerais (Este Ano):</h6>
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <div>
                  <p><strong>✅ Homologações:</strong> ${this.homologacoesAprovadas + 47}</p>
                  <p><strong>❌ Indeferimentos:</strong> ${this.homologacoesIndeferidas + 3}</p>
                  <p><strong>📜 DCBs Emitidas:</strong> ${this.dcbsEmitidas}</p>
                </div>
                <div>
                  <p><strong>⏱️ Tempo Médio:</strong> 5,2 dias</p>
                  <p><strong>📋 Taxa Aprovação:</strong> 94%</p>
                  <p><strong>🔄 Renovações:</strong> 23</p>
                </div>
              </div>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '📥 Gerar PDF',
        cancelButtonText: '❌ Fechar'
      })
    },
    baixarPDFHomologacao(homo) {
      this.$swal({
        title: '📥 Download de Homologação',
        text: `Baixando documento de homologação ${homo.numeroAta}...`,
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      })
    },
    visualizarDCBs(homo) {
      this.$swal({
        title: '📜 DCBs da Homologação',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${homo.numeroAta}</h4>
            <p><strong>Data:</strong> ${this.formatDate(homo.dataHomologacao)}</p>
            <hr>
            <h5>DCBs Emitidas:</h5>
            <div style="background: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;">
              <p><strong>DCB 001/2024:</strong> Monitor de Sinais Vitais - MedTech Pro</p>
              <p><strong>DCB 002/2024:</strong> Desfibrilador Automático - CardiacSafe</p>
              <p><strong>DCB 003/2024:</strong> Autoclave Hospitalar - SterilMax</p>
            </div>
            <div style="margin-top: 15px;">
              <button class="swal2-confirm swal2-styled" onclick="window.open('/api/downloads/dcbs-todas.pdf', '_blank')">
                📥 Baixar Todas as DCBs
              </button>
            </div>
          </div>
        `,
        showConfirmButton: false,
        showCancelButton: true,
        cancelButtonText: '❌ Fechar'
      })
    },
    notificarFornecedores(homo) {
      this.$swal({
        title: '📧 Notificar Fornecedores',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${homo.numeroAta}</h4>
            <p><strong>Tipo:</strong> ${homo.tipo === 'homologada' ? 'Homologação' : 'Indeferimento'}</p>
            <hr>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Tipo de Notificação:</label>
              <select class="swal2-select">
                <option value="email">E-mail</option>
                <option value="postal">Correio</option>
                <option value="ambos">E-mail + Correio</option>
              </select>
            </div>
            <div style="background: #e3f2fd; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <h6>Fornecedores a serem notificados:</h6>
              <p>• MedTech Pro - medtech@empresa.com</p>
              <p>• CardiacSafe - contato@cardiacsafe.com</p>
              <p>• SterilMax - vendas@sterilmax.com.br</p>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '📤 Enviar Notificações',
        cancelButtonText: '❌ Cancelar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: '✅ Notificações Enviadas',
            text: 'Todos os fornecedores foram notificados sobre a decisão.',
            icon: 'success'
          })
        }
      })
    },
    getDCBStatusClass(status) {
      switch (status) {
        case 'ATIVA': return 'dcb-ativa'
        case 'VENCENDO': return 'dcb-vencendo'
        case 'VENCIDA': return 'dcb-vencida'
        case 'CANCELADA': return 'dcb-cancelada'
        default: return 'dcb-indefinida'
      }
    },
    visualizarDCB(dcb) {
      this.$swal({
        title: `📜 DCB ${dcb.numero}/${dcb.ano}`,
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>${dcb.produto}</h4>
            <p><strong>Marca:</strong> ${dcb.marca}</p>
            <p><strong>Status:</strong> ${dcb.status}</p>
            <hr>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 4px;">
              <h6>Informações da DCB:</h6>
              <p><strong>Emitida em:</strong> ${this.formatDate(dcb.dataEmissao)}</p>
              <p><strong>Válida até:</strong> ${this.formatDate(dcb.validade)}</p>
              <p><strong>Autoridade:</strong> Dr. João Silva - Secretário</p>
              <p><strong>CPM Responsável:</strong> Comissão de Padronização de Materiais</p>
            </div>
            <div style="margin-top: 15px;">
              <button class="swal2-confirm swal2-styled" onclick="window.open(\`/api/downloads/dcb-\${dcb.numero}.pdf\`, '_blank')">
                📥 Baixar DCB Oficial
              </button>
            </div>
          </div>
        `,
        showConfirmButton: false,
        showCancelButton: true,
        cancelButtonText: '❌ Fechar'
      })
    },
    renovarDCB(dcb) {
      this.$swal({
        title: `🔄 Renovar DCB ${dcb.numero}/${dcb.ano}`,
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>${dcb.produto} - ${dcb.marca}</h4>
            <p><strong>Validade atual:</strong> ${this.formatDate(dcb.validade)}</p>
            <hr>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Nova data de validade:</label>
              <input id="novaValidade" class="swal2-input" type="date" value="">
            </div>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Justificativa:</label>
              <textarea id="justificativaRenovacao" class="swal2-textarea" placeholder="Motivo da renovação..." style="height: 80px;">Renovação padrão - produto mantém conformidade técnica e qualidade.</textarea>
            </div>
            <div style="background: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Nota:</strong> A renovação manterá o mesmo número da DCB com validade estendida.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '🔄 Confirmar Renovação',
        cancelButtonText: '❌ Cancelar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: '✅ DCB Renovada',
            text: 'A DCB foi renovada com sucesso e permanece ativa no catálogo.',
            icon: 'success'
          })
        }
      })
    },
    cancelarDCB(dcb) {
      this.$swal({
        title: `❌ Cancelar DCB ${dcb.numero}/${dcb.ano}`,
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>${dcb.produto} - ${dcb.marca}</h4>
            <p><strong>Status atual:</strong> ${dcb.status}</p>
            <hr>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Motivo do cancelamento:</label>
              <select id="motivoCancelamento" class="swal2-select">
                <option value="">Selecione o motivo</option>
                <option value="problemas_qualidade">Problemas de Qualidade</option>
                <option value="descontinuacao">Descontinuação do Produto</option>
                <option value="mudanca_normativa">Mudança de Normativa</option>
                <option value="solicitacao_fornecedor">Solicitação do Fornecedor</option>
                <option value="outros">Outros Motivos</option>
              </select>
            </div>
            <div style="margin: 15px 0;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Fundamentação:</label>
              <textarea id="fundamentacaoCancelamento" class="swal2-textarea" placeholder="Justificativa detalhada..." style="height: 100px;"></textarea>
            </div>
            <div style="background: #f8d7da; padding: 10px; border-radius: 4px; margin-top: 15px;">
              <small><strong>Atenção:</strong> O cancelamento remove o produto do catálogo e impede futuras aquisições.</small>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '❌ Confirmar Cancelamento',
        cancelButtonText: '🔙 Cancelar',
        confirmButtonColor: '#dc3545'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: '📝 DCB Cancelada',
            text: 'A DCB foi cancelada e o produto removido do catálogo oficial.',
            icon: 'warning'
          })
        }
      })
    },
    verTodas() {
      this.$swal({
        title: '📋 Todas as Homologações',
        text: 'Em uma implementação completa, abriria uma tela com filtros avançados e paginação.',
        icon: 'info'
      })
    },
    gerenciarDCBs() {
      this.$swal({
        title: '📜 Gerenciar DCBs',
        text: 'Em uma implementação completa, abriria o módulo completo de gestão de DCBs.',
        icon: 'info'
      })
    }
  }
}
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
  border-bottom: 1px solid #ddd;
}

.tab {
  padding: 10px 20px;
  cursor: pointer;
  font-weight: 500;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
}

.tab:hover {
  background-color: #f5f5f5;
}

.tab.active {
  border-bottom: 3px solid #3498db;
  color: #3498db;
}

.tab {
  position: relative;
}

.tab-notification {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #e74c3c;
  color: white;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  font-size: 11px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

.atas-julgamento,
.homologacoes {
  margin-top: 20px;
}

.info-card {
  background: white;
  border-radius: 8px;
  padding: 25px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  position: relative;
  overflow: hidden;
}

.info-card h3 {
  color: #2c3e50;
  margin-bottom: 15px;
}

.info-card p {
  margin-bottom: 15px;
  color: #555;
}

.info-card ul {
  margin-left: 20px;
  margin-bottom: 20px;
}

.info-card li {
  margin-bottom: 8px;
  color: #555;
}

.em-desenvolvimento {
  position: relative;
  margin-top: 20px;
  padding: 8px 15px;
  background-color: #f39c12;
  color: white;
  border-radius: 4px;
  display: inline-block;
  font-weight: bold;
  text-transform: uppercase;
  font-size: 12px;
}

.stats-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  position: relative;
  overflow: hidden;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,0,0,0.15);
}

.stat-icon {
  font-size: 2.5rem;
  margin-bottom: 12px;
  opacity: 0.8;
}

.stat-description {
  color: #666;
  font-size: 13px;
  margin-top: 8px;
  margin-bottom: 0;
}

.stat-card-alert {
  border: 2px solid #e74c3c !important;
  animation: borderPulse 2s infinite;
}

@keyframes borderPulse {
  0%, 100% { border-color: #e74c3c; }
  50% { border-color: #c0392b; }
}

.alert-badge {
  display: block;
  background: #e74c3c;
  color: white;
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 10px;
  margin-top: 4px;
  font-weight: normal;
  text-transform: uppercase;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  text-align: center;
  margin-top: 10px;
}

.dashboard-section {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

h3 {
  margin-top: 0;
  margin-bottom: 15px;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 15px;
}

th, td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

th {
  background-color: #f5f5f5;
}

.btn-small {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.status-badge {
  display: inline-block;
  padding: 5px 10px;
  border-radius: 20px;
  font-size: 12px;
  text-transform: uppercase;
  font-weight: bold;
}

.status-aprovado {
  background-color: #2ecc71;
  color: white;
}

.status-pendente {
  background-color: #f39c12;
  color: white;
}

.status-reprovado {
  background-color: #e74c3c;
  color: white;
}

.status-aprovado-card {
  border-top: 5px solid #2ecc71;
}

.status-pendente-card {
  border-top: 5px solid #f39c12;
}

.status-reprovado-card {
  border-top: 5px solid #e74c3c;
}

.status-diligencia-card {
  border-top: 5px solid #9b59b6;
}

.status-diligencia {
  background-color: #9b59b6;
  color: white;
}

.status-recurso-card {
  border-top: 5px solid #e67e22;
}

.section-header {
  margin-bottom: 20px;
}

.section-header h3 {
  margin-bottom: 8px;
  color: #2c3e50;
  font-size: 1.3rem;
}

.section-description {
  color: #666;
  font-size: 14px;
  margin: 0;
  line-height: 1.4;
}

.produto-info {
  max-width: 200px;
}

.produto-info strong {
  color: #2c3e50;
}

.produto-info small {
  color: #666;
  font-size: 12px;
}

.prazo-badge {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.prazo-normal {
  background-color: #2ecc71;
  color: white;
}

.prazo-atencao {
  background-color: #f39c12;
  color: white;
}

.prazo-urgente {
  background-color: #e67e22;
  color: white;
}

.prazo-vencido {
  background-color: #e74c3c;
  color: white;
}

.prazo-indefinido {
  background-color: #95a5a6;
  color: white;
}

.btn-primary {
  background-color: #3498db;
  color: white;
  margin-right: 5px;
}

.btn-primary:hover {
  background-color: #2980b9;
}

.btn-secondary {
  background-color: #95a5a6;
  color: white;
}

.btn-secondary:hover {
  background-color: #7f8c8d;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 16px;
  opacity: 0.6;
}

.empty-state h4 {
  margin-bottom: 8px;
  color: #2c3e50;
}

.empty-state p {
  margin: 0;
  font-size: 14px;
}

/* Estilos para Atas de Julgamento */
.atas-julgamento {
  padding: 0;
}

.atas-header {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.atas-header h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1.4rem;
}

.atas-description {
  color: #666;
  margin: 0 0 20px 0;
  line-height: 1.5;
}

.atas-actions {
  display: flex;
  gap: 12px;
}

.atas-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.ata-stat-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  display: flex;
  align-items: center;
  gap: 16px;
  transition: transform 0.2s ease;
}

.ata-stat-card:hover {
  transform: translateY(-2px);
}

.ata-stat-icon {
  font-size: 2rem;
  opacity: 0.8;
}

.ata-stat-info h4 {
  margin: 0 0 4px 0;
  font-size: 1.8rem;
  font-weight: bold;
  color: #2c3e50;
}

.ata-stat-info p {
  margin: 0;
  color: #666;
  font-size: 14px;
}

.atas-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.atas-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.atas-section h4 {
  margin: 0 0 20px 0;
  color: #2c3e50;
  font-size: 1.2rem;
  padding-bottom: 12px;
  border-bottom: 2px solid #f1f2f6;
}

.atas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 16px;
}

.ata-card {
  border: 1px solid #e1e8ed;
  border-radius: 8px;
  padding: 16px;
  transition: all 0.2s ease;
}

.ata-card:hover {
  border-color: #3498db;
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.1);
}

.ata-card.em-elaboracao {
  border-left: 4px solid #f39c12;
}

.ata-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.ata-card-header h5 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.ata-status {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-elaboracao {
  background-color: #f39c12;
  color: white;
}

.ata-card-content p {
  margin: 0 0 8px 0;
  color: #555;
  font-size: 14px;
}

.ata-card-actions {
  margin-top: 16px;
  display: flex;
  gap: 8px;
}

.btn-success {
  background-color: #28a745;
  color: white;
}

.btn-success:hover {
  background-color: #218838;
}

.btn-warning {
  background-color: #ffc107;
  color: #212529;
}

.btn-warning:hover {
  background-color: #e0a800;
}

.atas-table-container {
  overflow-x: auto;
}

.atas-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 16px;
}

.atas-table th,
.atas-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid #e1e8ed;
}

.atas-table th {
  background-color: #f8f9fa;
  font-weight: 600;
  color: #2c3e50;
}

.atas-table tr:hover {
  background-color: #f8f9fa;
}

.badge-info {
  background-color: #17a2b8;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: bold;
}

.status-em-prazo {
  background-color: #ffc107;
  color: #212529;
}

.status-encerrado {
  background-color: #28a745;
  color: white;
}

.status-com-recursos {
  background-color: #dc3545;
  color: white;
}

.status-indefinido {
  background-color: #6c757d;
  color: white;
}

.empty-message {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}

.empty-message p {
  margin: 0;
  font-style: italic;
}

/* Estilos para Homologações */
.homologacoes {
  padding: 0;
}

.homologacoes-header {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.homologacoes-header h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1.4rem;
}

.homologacoes-description {
  color: #666;
  margin: 0 0 20px 0;
  line-height: 1.5;
}

.homologacoes-actions {
  display: flex;
  gap: 12px;
}

.homologacoes-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.homo-stat-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  display: flex;
  align-items: center;
  gap: 16px;
  transition: transform 0.2s ease;
}

.homo-stat-card:hover {
  transform: translateY(-2px);
}

.homo-stat-card.pending {
  border-left: 4px solid #f39c12;
}

.homo-stat-card.approved {
  border-left: 4px solid #28a745;
}

.homo-stat-card.rejected {
  border-left: 4px solid #dc3545;
}

.homo-stat-card.dcb {
  border-left: 4px solid #6f42c1;
}

.homo-stat-icon {
  font-size: 2rem;
  opacity: 0.8;
}

.homo-stat-info h4 {
  margin: 0 0 4px 0;
  font-size: 1.8rem;
  font-weight: bold;
  color: #2c3e50;
}

.homo-stat-info p {
  margin: 0 0 2px 0;
  color: #2c3e50;
  font-weight: 600;
  font-size: 14px;
}

.homo-stat-info small {
  color: #666;
  font-size: 12px;
}

.homologacoes-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.homo-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.homo-section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 2px solid #f1f2f6;
}

.homo-section-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.2rem;
}

.homo-count {
  background: #e3f2fd;
  color: #1976d2;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: bold;
}

.btn-link {
  background: none;
  border: none;
  color: #3498db;
  cursor: pointer;
  font-size: 14px;
  text-decoration: underline;
}

.btn-link:hover {
  color: #2980b9;
}

.homo-table-container {
  overflow-x: auto;
}

.homo-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 16px;
}

.homo-table th,
.homo-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid #e1e8ed;
}

.homo-table th {
  background-color: #f8f9fa;
  font-weight: 600;
  color: #2c3e50;
  font-size: 13px;
}

.homo-table tr:hover {
  background-color: #f8f9fa;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
  margin-left: 5px;
}

.btn-danger:hover {
  background-color: #c82333;
}

.btn-info {
  background-color: #17a2b8;
  color: white;
  margin-left: 5px;
}

.btn-info:hover {
  background-color: #138496;
}

.homo-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.homo-card {
  border: 1px solid #e1e8ed;
  border-radius: 12px;
  padding: 20px;
  transition: all 0.2s ease;
}

.homo-card:hover {
  border-color: #3498db;
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.1);
}

.homo-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.homo-card-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: bold;
}

.homo-card-status.homologada {
  background-color: #d4edda;
  color: #155724;
}

.homo-card-status.indeferida {
  background-color: #f8d7da;
  color: #721c24;
}

.homo-status-icon {
  font-size: 14px;
}

.homo-date {
  color: #666;
  font-size: 12px;
}

.homo-card-content h5 {
  margin: 0 0 12px 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.homo-card-content p {
  margin: 0 0 8px 0;
  color: #555;
  font-size: 14px;
}

.homo-card-actions {
  margin-top: 16px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.dcb-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.dcb-card {
  border: 1px solid #e1e8ed;
  border-radius: 8px;
  padding: 16px;
  transition: all 0.2s ease;
}

.dcb-card:hover {
  border-color: #6f42c1;
  box-shadow: 0 4px 12px rgba(111, 66, 193, 0.1);
}

.dcb-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.dcb-number {
  font-weight: bold;
  color: #2c3e50;
  font-size: 14px;
}

.dcb-status {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.dcb-ativa {
  background-color: #28a745;
  color: white;
}

.dcb-vencendo {
  background-color: #ffc107;
  color: #212529;
}

.dcb-vencida {
  background-color: #dc3545;
  color: white;
}

.dcb-cancelada {
  background-color: #6c757d;
  color: white;
}

.dcb-indefinida {
  background-color: #e9ecef;
  color: #495057;
}

.dcb-content h6 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1rem;
}

.dcb-content p {
  margin: 0 0 6px 0;
  color: #555;
  font-size: 13px;
}

.dcb-actions {
  margin-top: 12px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

/* Estilos para Sistema de Alertas */
.alertas-section {
  background: linear-gradient(135deg, #ff6b6b 0%, #ffa726 100%);
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 24px;
  box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3);
  animation: pulseAlert 2s infinite;
}

@keyframes pulseAlert {
  0%, 100% { box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3); }
  50% { box-shadow: 0 6px 20px rgba(255, 107, 107, 0.5); }
}

.alertas-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.alertas-header h3 {
  margin: 0;
  color: white;
  font-size: 1.3rem;
}

.alertas-header .btn-link {
  color: white;
  text-decoration: underline;
  opacity: 0.9;
}

.alertas-header .btn-link:hover {
  opacity: 1;
}

.alertas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 16px;
}

.alerta-card {
  background: white;
  border-radius: 8px;
  padding: 16px;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s ease;
}

.alerta-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.alerta-card.prazo-vencido,
.alerta-card.julgamento-vencido,
.alerta-card.homologacao-atrasada {
  border-left: 4px solid #e74c3c;
}

.alerta-card.prazo-urgente,
.alerta-card.julgamento-urgente,
.alerta-card.homologacao-urgente {
  border-left: 4px solid #f39c12;
}

.alerta-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.alerta-content {
  flex: 1;
}

.alerta-content h5 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1rem;
}

.alerta-content p {
  margin: 0 0 8px 0;
  color: #555;
  font-size: 14px;
  line-height: 1.4;
}

.alerta-content small {
  color: #666;
  font-size: 12px;
}

.alerta-actions {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex-shrink: 0;
}
</style> 