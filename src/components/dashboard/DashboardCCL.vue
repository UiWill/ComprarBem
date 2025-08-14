<template>
  <div class="dashboard">
    <h2>Painel Comissão de Contratação ou Licitação</h2>
    
    <div class="tab-header">
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'dashboard' }" 
        @click="setActiveTab('dashboard')"
      >
        📊 Dashboard
        <span v-if="notificacoes.filter(n => !n.lido).length > 0" class="tab-notification">
          {{ notificacoes.filter(n => !n.lido).length }}
        </span>
      </button>
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'atas' }" 
        @click="setActiveTab('atas')"
      >
        📋 Atas de Julgamento
      </button>
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'homologacoes' }" 
        @click="setActiveTab('homologacoes')"
      >
        ✅ Homologações
      </button>
    </div>
    
    <!-- Conteúdo das Abas -->
    <div class="tab-content">
      <!-- Aba Dashboard -->
      <div v-show="activeTab === 'dashboard'" class="tab-pane">
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
            <h3>📋 Processos Aguardando Julgamento CCL</h3>
            <p class="section-description">
              Processos administrativos assinados pelo órgão competente que aguardam análise técnica e julgamento pela CCL
            </p>
            <div class="section-actions">
              <button @click="carregarProcessosPendentes" class="btn-secondary">
                🔄 Atualizar Lista
              </button>
              <button @click="gerarRelatorioProcessos" class="btn-secondary">
                📊 Relatório
              </button>
            </div>
          </div>
        <table v-if="processosPendentesArray.length > 0">
          <thead>
            <tr>
              <th>Número do Processo</th>
              <th>Objeto</th>
              <th>Órgão Solicitante</th>
              <th>Data Assinatura</th>
              <th>Prazo CCL</th>
              <th>Situação</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="processo in processosPendentesPaginados" :key="processo.id">
              <td class="processo-info">
                <strong>{{ processo.numero_processo }}</strong>
              </td>
              <td class="objeto-processo">
                <span class="objeto-text" :title="processo.objeto || 'Objeto não informado'">
                  {{ truncateText(processo.objeto || 'Objeto não informado', 80) }}
                </span>
              </td>
              <td class="orgao-info">
                <span class="orgao-nome">{{ processo.orgao_responsavel || 'Órgão não informado' }}</span>
              </td>
              <td>{{ formatDate(processo.data_assinatura_orgao || processo.atualizado_em) }}</td>
              <td>
                <span class="prazo-badge" :class="getPrazoCCLClass(processo.data_assinatura_orgao || processo.atualizado_em)">
                  {{ calcularPrazoCCL(processo.data_assinatura_orgao || processo.atualizado_em) }}
                </span>
              </td>
              <td>
                <span class="status-badge" :class="getStatusClass(processo.status)">
                  {{ formatarStatusProcesso(processo.status) }}
                </span>
              </td>
              <td class="actions-cell">
                <div class="action-buttons">
                  <button @click="visualizarProcesso(processo)" class="btn-small btn-secondary" title="Ver detalhes do processo">
                    👁️ Ver
                  </button>
                  <button 
                    v-if="processo.status === 'julgamento_ccl'"
                    @click="iniciarJulgamentoCCL(processo)" 
                    class="btn-small btn-primary"
                    title="Iniciar julgamento técnico CCL"
                  >
                    ⚖️ Julgar
                  </button>
                  <button 
                    v-if="processo.status === 'julgamento_ccl'"
                    @click="devolverProcesso(processo)" 
                    class="btn-small btn-warning"
                    title="Devolver processo para correções"
                  >
                    ↩️ Devolver
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
        
        <!-- Controles de Paginação para Processos Pendentes -->
        <div v-if="processosPendentesArray.length > 0" class="pagination-controls">
          <button @click="paginaAnterior('processosPendentes')" :disabled="paginacao.processosPendentes.paginaAtual <= 1" class="pagination-btn">
            ← Anterior
          </button>
          <span class="pagination-info">
            Página {{ paginacao.processosPendentes.paginaAtual }} de {{ calcularTotalPaginas('processosPendentes') || 1 }}
            ({{ processosPendentesArray.length }} itens)
          </span>
          <button @click="proximaPagina('processosPendentes')" :disabled="paginacao.processosPendentes.paginaAtual >= calcularTotalPaginas('processosPendentes')" class="pagination-btn">
            Próxima →
          </button>
        </div>
        
        <div v-else class="empty-state">
          <div class="empty-icon">⚖️</div>
          <h4>Não há processos administrativos pendentes</h4>
          <p>Não há processos administrativos finalizados pela CPM aguardando julgamento da CCL.</p>
        </div>
      </div>

      <!-- Alertas e Notificações -->
      <div v-if="notificacoes.filter(n => !n.lido).length > 0" class="alertas-section">
        <div class="alertas-header">
          <h3>🚨 Alertas Críticos</h3>
          <button @click="marcarTodosComoLidos" class="btn-link">
            Marcar todos como lidos
          </button>
          <button @click="limparNotificacoesAntigas" class="btn-link" style="margin-left: 10px; color: #dc3545;">
            🗑️ Limpar antigas
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
            <tr v-for="recurso in recursosAnalisePageinados" :key="recurso.id">
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
        
        <!-- Controles de Paginação para Recursos em Análise -->
        <div v-if="recursos.length > 0" class="pagination-controls">
          <button @click="paginaAnterior('recursosAnalise')" :disabled="paginacao.recursosAnalise.paginaAtual <= 1" class="pagination-btn">
            ← Anterior
          </button>
          <span class="pagination-info">
            Página {{ paginacao.recursosAnalise.paginaAtual }} de {{ calcularTotalPaginas('recursosAnalise') || 1 }}
            ({{ recursos.length }} itens)
          </span>
          <button @click="proximaPagina('recursosAnalise')" :disabled="paginacao.recursosAnalise.paginaAtual >= calcularTotalPaginas('recursosAnalise')" class="pagination-btn">
            Próxima →
          </button>
        </div>
        
        <div v-else class="empty-state">
          <div class="empty-icon">📄</div>
          <h4>Não há recursos em análise</h4>
          <p>Todas as decisões da CCL estão dentro do prazo recursal ou já foram julgadas.</p>
        </div>
        </div>
      </div>
      
      <!-- Aba Atas de Julgamento -->
      <div v-show="activeTab === 'atas'" class="atas-julgamento tab-pane">
      <div class="atas-header">
        <h3>📋 Atas de Julgamento CCL</h3>
        <p class="atas-description">
          Acompanhe as atas de julgamento técnico emitidas pela CCL após análise dos processos de padronização
        </p>
        <div class="alert-info" style="background: #e8f5e8; border: 1px solid #4caf50; padding: 12px; border-radius: 8px; margin: 15px 0;">
          <strong>ℹ️ Como funciona:</strong> 
          Após julgar um processo, a CCL emite uma ata oficial que documenta a decisão técnica tomada.
        </div>
        <div class="atas-actions">
          <button @click="carregarDados(true)" class="btn-secondary">
            🔄 Atualizar Dados
          </button>
          <button @click="gerarRelatorioAtas" class="btn-secondary">
            📊 Gerar Relatório
          </button>
        </div>
      </div>

      <div class="atas-stats">
        <div class="ata-stat-card">
          <div class="ata-stat-icon">✏️</div>
          <div class="ata-stat-info">
            <h4>{{ atasEmElaboracao.length }}</h4>
            <p>Atas em Elaboração</p>
          </div>
        </div>
        <div class="ata-stat-card">
          <div class="ata-stat-icon">📋</div>
          <div class="ata-stat-info">
            <h4>{{ atasPublicadasRecentes.length }}</h4>
            <p>Atas Publicadas</p>
          </div>
        </div>
        <div class="ata-stat-card">
          <div class="ata-stat-icon">📄</div>
          <div class="ata-stat-info">
            <h4>{{ atasEmElaboracao.length + atasPublicadasRecentes.length }}</h4>
            <p>Total de Atas CCL</p>
          </div>
        </div>
      </div>

      <div class="atas-content">
        <!-- Atas em Elaboração -->
        <div class="atas-section">
          <div class="section-header">
            <h4>✏️ Atas em Elaboração</h4>
            <p class="section-description">Atas que estão sendo criadas após julgamentos recentes</p>
          </div>
          
          <div v-if="atasEmElaboracao.length > 0" class="atas-table-container">
            <table class="atas-elaboracao-table">
              <thead>
                <tr>
                  <th>Ata</th>
                  <th>Data Criação</th>
                  <th>Processos</th>
                  <th>Status</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="ata in atasEmElaboracao" :key="ata.id">
                  <td>
                    <strong>{{ ata.numero_ata || `ATA-CCL-${String(ata.id).slice(-4)}` }}</strong>
                  </td>
                  <td>{{ formatDate(ata.data_inicio) }}</td>
                  <td class="processos-cell">
                    <span class="badge-info">{{ ata.processos_count || 0 }} processo(s)</span>
                  </td>
                  <td>
                    <span class="status-badge status-elaboracao">
                      ✏️ Em Elaboração
                    </span>
                  </td>
                  <td class="actions-cell">
                    <div class="action-buttons">
                      <button @click="editarAta(ata)" class="btn-small btn-primary" title="Continuar elaborando a ata">
                        ✏️ Continuar
                      </button>
                      <button @click="visualizarAta(ata)" class="btn-small btn-secondary" title="Visualizar rascunho">
                        👁️ Visualizar
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          
          <div v-else class="empty-state">
            <div class="empty-icon">✏️</div>
            <h4>Nenhuma ata em elaboração</h4>
            <p>Quando você julgar um processo, a ata será criada automaticamente e aparecerá aqui para elaboração final.</p>
          </div>
        </div>

        <!-- Atas Publicadas -->
        <div class="atas-section">
          <div class="section-header">
            <h4>📋 Atas Publicadas</h4>
            <p class="section-description">Atas oficiais já finalizadas e publicadas</p>
          </div>
          
          <div v-if="atasPublicadasRecentes.length > 0" class="atas-table-container">
            <table class="atas-publicadas-table">
              <thead>
                <tr>
                  <th>Ata</th>
                  <th>Data Publicação</th>
                  <th>Processos</th>
                  <th>Status</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="ata in atasPublicadasRecentes" :key="ata.id">
                  <td>
                    <strong>{{ ata.numero || `ATA-${String(ata.id).slice(-4)}` }}</strong>
                  </td>
                  <td>{{ formatDate(ata.dataPublicacao) }}</td>
                  <td class="processos-cell">
                    <span class="badge-info">{{ ata.totalProcessos || 0 }} processo(s)</span>
                  </td>
                  <td>
                    <span class="status-badge status-publicada">
                      📋 Publicada
                    </span>
                  </td>
                  <td class="actions-cell">
                    <div class="action-buttons">
                      <button @click="baixarAta(ata)" class="btn-small btn-primary" title="Baixar arquivo PDF da ata">
                        📄 Baixar PDF
                      </button>
                      <button @click="visualizarAta(ata)" class="btn-small btn-secondary" title="Visualizar conteúdo da ata">
                        👁️ Visualizar
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          
          <div v-else class="empty-state">
            <div class="empty-icon">📋</div>
            <h4>Nenhuma ata publicada ainda</h4>
            <p>As atas aparecerão aqui depois de serem elaboradas e oficialmente publicadas.</p>
          </div>
        </div>
            
            <!-- Controles de Paginação para Atas Publicadas -->
            <div v-if="atasPublicadasRecentes.length > 0" class="pagination-controls">
              <button @click="paginaAnterior('atasPublicadas')" :disabled="paginacao.atasPublicadas.paginaAtual <= 1" class="pagination-btn">
                ← Anterior
              </button>
              <span class="pagination-info">
                Página {{ paginacao.atasPublicadas.paginaAtual }} de {{ calcularTotalPaginas('atasPublicadas') || 1 }}
                ({{ atasPublicadasRecentes.length }} itens)
              </span>
              <button @click="proximaPagina('atasPublicadas')" :disabled="paginacao.atasPublicadas.paginaAtual >= calcularTotalPaginas('atasPublicadas')" class="pagination-btn">
                Próxima →
              </button>
            </div>
            
            <div v-else class="empty-message">
              <p>Não há atas publicadas recentemente.</p>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Aba Homologações -->
      <div v-show="activeTab === 'homologacoes'" class="homologacoes tab-pane">
      <div class="homologacoes-header">
        <h3>📋 Homologações</h3>
        <div class="alert-duvida" style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 5px; margin: 10px 0;">
          <strong>⚠️ DÚVIDA PENDENTE:</strong> Verificar se a responsabilidade por homologações deve ser da CCL ou da Autoridade Competente conforme fluxo legal. 
          <br><small>Esta aba será ajustada após confirmação do cliente sobre o responsável correto.</small>
        </div>
        <p class="homologacoes-description">
          Gestão de atos de homologação (responsabilidade a confirmar: CCL ou Autoridade Competente)
        </p>
        <div class="homologacoes-actions">
          <button @click="consultarPendentes" class="btn-primary">
            📋 Processos Pendentes
          </button>
          <button @click="relatorioHomologacoes" class="btn-secondary">
            📊 Relatório Geral
          </button>
        </div>
      
        <div class="empty-state">
          <div class="empty-icon">⚖️</div>
          <h4>Aba de Homologações</h4>
          <p>Esta funcionalidade será implementada conforme definição do responsável correto.</p>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import TramitacaoProcessosService from '@/services/tramitacaoProcessosService'
import ProcessosAdministrativosService from '@/services/processosAdministrativosService'

export default {
  name: 'DashboardCCL',
  data() {
    return {
      activeTab: 'dashboard',
      processosPendentesArray: [],
      atasRecentes: [],
      pendentes: 0,
      aprovados: 0,
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
      // Controle de recarregamento excessivo
      isLoadingData: false,
      dataLoadTimeout: null,
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
      dcbsAtivas: [],
      // Paginação
      paginacao: {
        atasElaboracao: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        atasPublicadas: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        processosPendentes: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        homologacoesRecentes: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        dcbsAtivas: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        recursos: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        processosPendentes: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        },
        recursosAnalise: {
          paginaAtual: 1,
          itensPorPagina: 5,
          total: 0
        }
      }
    }
  },
  computed: {
    // Computadas para paginação
    atasElaboracaoPaginadas() {
      const inicio = (this.paginacao.atasElaboracao.paginaAtual - 1) * this.paginacao.atasElaboracao.itensPorPagina
      const fim = inicio + this.paginacao.atasElaboracao.itensPorPagina
      return this.atasEmElaboracao.slice(inicio, fim)
    },
    
    atasPublicadasPaginadas() {
      const inicio = (this.paginacao.atasPublicadas.paginaAtual - 1) * this.paginacao.atasPublicadas.itensPorPagina
      const fim = inicio + this.paginacao.atasPublicadas.itensPorPagina
      return this.atasPublicadasRecentes.slice(inicio, fim)
    },
    
    processosPendentesHomologacaoPaginados() {
      const inicio = (this.paginacao.processosPendentes.paginaAtual - 1) * this.paginacao.processosPendentes.itensPorPagina
      const fim = inicio + this.paginacao.processosPendentes.itensPorPagina
      return this.processosPendentesHomologacao.slice(inicio, fim)
    },
    
    homologacoesRecentesPaginadas() {
      const inicio = (this.paginacao.homologacoesRecentes.paginaAtual - 1) * this.paginacao.homologacoesRecentes.itensPorPagina
      const fim = inicio + this.paginacao.homologacoesRecentes.itensPorPagina
      return this.homologacoesRecentes.slice(inicio, fim)
    },
    
    dcbsAtivasPaginadas() {
      const inicio = (this.paginacao.dcbsAtivas.paginaAtual - 1) * this.paginacao.dcbsAtivas.itensPorPagina
      const fim = inicio + this.paginacao.dcbsAtivas.itensPorPagina
      return this.dcbsAtivas.slice(inicio, fim)
    },
    
    recursosPaginados() {
      const inicio = (this.paginacao.recursos.paginaAtual - 1) * this.paginacao.recursos.itensPorPagina
      const fim = inicio + this.paginacao.recursos.itensPorPagina
      return this.recursos.slice(inicio, fim)
    },
    
    processosPendentesPaginados() {
      const inicio = (this.paginacao.processosPendentes.paginaAtual - 1) * this.paginacao.processosPendentes.itensPorPagina
      const fim = inicio + this.paginacao.processosPendentes.itensPorPagina
      const resultado = this.processosPendentesArray.slice(inicio, fim)
      
      // LOG FINAL: Verificar se os dados chegam até o template
      console.log('🖥️ [DEBUG CCL TEMPLATE] processosPendentesPaginados chamado')
      console.log('🖥️ [DEBUG CCL TEMPLATE] this.processosPendentesArray.length:', this.processosPendentesArray?.length || 0)
      console.log('🖥️ [DEBUG CCL TEMPLATE] resultado.length:', resultado?.length || 0)
      if (resultado?.length > 0) {
        resultado.forEach(proc => {
          console.log(`🖥️ [DEBUG CCL TEMPLATE] Processo para template: ${proc.numero_processo} - Status: ${proc.status}`)
        })
      }
      
      return resultado
    },
    
    recursosAnalisePageinados() {
      const inicio = (this.paginacao.recursosAnalise.paginaAtual - 1) * this.paginacao.recursosAnalise.itensPorPagina
      const fim = inicio + this.paginacao.recursosAnalise.itensPorPagina
      return this.recursos.slice(inicio, fim)
    }
  },
  created() {
    this.obterTenantId().then((tenantId) => {
      // Só carrega dados se obtivemos um tenant ID válido
      if (tenantId) {
        this.carregarDados(true)
        this.carregarCategorias()
        this.carregarAtasJulgamento()
        this.carregarAtasEmElaboracao()
        this.carregarHomologacoes()
        this.carregarProcessosPendentesHomologacao()
        this.carregarHomologacoesRecentes()
        this.carregarDCBsAtivas()
        this.iniciarMonitoramentoPrazos()
      } else {
        console.warn('Não foi possível obter tenant ID no created()')
      }
    })
  },
  watch: {
    currentTenantId: {
      handler(newTenantId, oldTenantId) {
        // Evitar recarregamentos desnecessários
        if (newTenantId && newTenantId !== oldTenantId && !this.isLoadingData) {
          console.log('🔄 [DEBUG CCL] Tenant ID mudou, recarregando dados:', newTenantId)
          
          // Usar debounce mais longo para evitar múltiplas chamadas
          if (this.dataLoadTimeout) {
            clearTimeout(this.dataLoadTimeout)
          }
          
          this.dataLoadTimeout = setTimeout(() => {
            // Verificar novamente se não está carregando antes de iniciar
            if (!this.isLoadingData) {
              this.isLoadingData = true
              this.$nextTick(() => {
                this.carregarDados(true).finally(() => {
                  this.isLoadingData = false
                })
              })
            }
          }, 500) // Debounce aumentado para 500ms
        }
      },
      immediate: false
    },
    activeTab(newTab, oldTab) {
      // Evitar recarregamentos desnecessários ao trocar de aba
      if (newTab !== oldTab && this.currentTenantId) {
        if (newTab === 'homologacoes') {
          console.log('Entrando na aba homologações - recarregando dados específicos...')
          this.carregarHomologacoes()
          this.carregarProcessosPendentesHomologacao()
          this.carregarHomologacoesRecentes()
        } else if (newTab === 'atas') {
          console.log('Entrando na aba atas de julgamento - recarregando dados específicos...')
          this.carregarAtasJulgamento()
          this.carregarAtasEmElaboracao()
        }
        // Evitar recarregar dados gerais desnecessariamente
        else if (newTab === 'dashboard' && this.processosPendentesArray.length === 0) {
          console.log('Voltando ao dashboard - recarregando apenas se necessário...')
          this.carregarDados(true)
        }
      }
    }
  },
  beforeUnmount() {
    // Limpar interval ao destruir componente
    if (this.autoCheckInterval) {
      clearInterval(this.autoCheckInterval)
    }
    // Limpar timeout de debounce
    if (this.dataLoadTimeout) {
      clearTimeout(this.dataLoadTimeout)
    }
  },
  methods: {
    setActiveTab(tab) {
      this.activeTab = tab
    },

    truncateText(text, maxLength) {
      if (!text) return ''
      if (text.length <= maxLength) return text
      return text.substring(0, maxLength) + '...'
    },

    // Métodos específicos para botões da interface
    async carregarProcessosPendentes() {
      console.log('🔄 Recarregando processos pendentes...')
      await this.carregarDados(true)
      this.$swal({
        title: '✅ Sucesso!',
        text: 'Lista de processos atualizada com sucesso!',
        icon: 'success',
        timer: 2000,
        showConfirmButton: false
      })
    },

    gerarRelatorioProcessos() {
      this.$swal({
        title: '📊 Relatório de Processos CCL',
        text: 'Esta funcionalidade gerará um relatório detalhado dos processos sob análise da CCL.',
        icon: 'info',
        showCancelButton: true,
        confirmButtonText: '📄 Gerar PDF',
        cancelButtonText: 'Cancelar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: 'Em desenvolvimento',
            text: 'A geração de relatórios será implementada em breve.',
            icon: 'info'
          })
        }
      })
    },

    gerarRelatorioAtas() {
      this.$swal({
        title: '📋 Relatório de Atas CCL',
        text: 'Esta funcionalidade gerará um relatório das atas de julgamento emitidas pela CCL.',
        icon: 'info',
        showCancelButton: true,
        confirmButtonText: '📄 Gerar PDF',
        cancelButtonText: 'Cancelar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: 'Em desenvolvimento',
            text: 'A geração de relatórios de atas será implementada em breve.',
            icon: 'info'
          })
        }
      })
    },

    // Métodos específicos para Atas de Julgamento
    editarAta(ata) {
      this.$swal({
        title: '✏️ Editar Ata de Julgamento',
        text: `Editando ata ${ata.numero_ata || `ATA-CCL-${ata.id}`}`,
        icon: 'info',
        showCancelButton: true,
        confirmButtonText: '📝 Abrir Editor',
        cancelButtonText: 'Cancelar'
      }).then((result) => {
        if (result.isConfirmed) {
          this.$swal({
            title: 'Em desenvolvimento',
            text: 'O editor de atas será implementado em breve.',
            icon: 'info'
          })
        }
      })
    },

    visualizarAta(ata) {
      this.$swal({
        title: '📄 Visualizar Ata',
        html: `
          <div style="text-align: left;">
            <p><strong>Número:</strong> ${ata.numero_ata || `ATA-CCL-${ata.id}`}</p>
            <p><strong>Data:</strong> ${this.formatDate(ata.data_publicacao || ata.data_inicio)}</p>
            <p><strong>Status:</strong> ${ata.status || 'Em Elaboração'}</p>
            <p><strong>Processos:</strong> ${ata.total_processos || ata.processos_count || 0}</p>
            <p><strong>Observação:</strong> Visualização completa em desenvolvimento</p>
          </div>
        `,
        icon: 'info',
        confirmButtonText: 'Fechar'
      })
    },

    async baixarAta(ata) {
      try {
        // Buscar o processo relacionado à ata
        const { data: processo, error } = await supabase
          .from('processos_administrativos')
          .select('*')
          .not('ata_emitida_ccl_em', 'is', null)
          .eq('tenant_id', this.currentTenantId)
          .order('ata_emitida_ccl_em', { ascending: false })
          .limit(1)
          .single()
          
        if (error || !processo) {
          this.$swal({
            title: '❌ Erro',
            text: 'Não foi possível encontrar o processo relacionado à ata.',
            icon: 'error'
          })
          return
        }

        this.$swal({
          title: '📄 Gerar Relatório com Ata',
          text: `Gerando relatório completo do processo ${processo.numero_processo} incluindo a Ata de Julgamento CCL...`,
          icon: 'info',
          showCancelButton: true,
          confirmButtonText: '📄 Gerar PDF',
          cancelButtonText: 'Cancelar'
        }).then(async (result) => {
          if (result.isConfirmed) {
            // Usar o mesmo sistema de geração de PDF dos Processos Administrativos
            await this.gerarRelatorioComAta(processo, ata)
          }
        })
      } catch (error) {
        console.error('Erro ao buscar processo da ata:', error)
        this.$swal({
          title: '❌ Erro',
          text: 'Erro ao buscar dados do processo.',
          icon: 'error'
        })
      }
    },

    async gerarRelatorioComAta(processo, ata) {
      try {
        console.log('📄 Gerando relatório com Ata CCL para processo:', processo.numero_processo)
        
        // Importar o componente ProcessosAdministrativosComponent dinamicamente
        const ProcessosAdministrativosComponent = await import('../processos/ProcessosAdministrativosComponent.vue')
        const componentInstance = ProcessosAdministrativosComponent.default
        
        // Usar o método de geração de relatório do ProcessosAdministrativosComponent
        // Mas vamos adaptar para incluir a ata CCL
        
        // Buscar dados completos do processo
        const processoCompleto = await this.obterProcessoCompleto(processo.id)
        if (!processoCompleto) {
          throw new Error('Processo não encontrado')
        }
        
        // Buscar todos os documentos
        const { default: ProcessosAdministrativosService } = await import('../../services/processosAdministrativosService')
        let documentos = await ProcessosAdministrativosService.listarDocumentosProcesso(processo.id)
        
        // Buscar produtos se for padronização
        let produtos = []
        if (processoCompleto.tipo_processo === 'padronizacao') {
          produtos = await ProcessosAdministrativosService.listarProdutosProcesso(processo.id)
        }
        
        // ADICIONAR ATA CCL COMO NOVO DOCUMENTO (após DFD - Fl. 003)
        documentos.push({
          id: `ata_ccl_${ata.id}`,
          tipo_documento: 'ATA_CCL',
          nome_documento: 'Ata de Julgamento CCL',
          titulo: 'ATA DE JULGAMENTO TÉCNICO - CCL',
          descricao: 'Ata de Julgamento emitida pela Comissão Central de Licitação',
          numero_sequencial: 3, // Após DFD (Fl. 002)
          folha_numero: 'Fl. 003',
          data_autuacao: ata.dataPublicacao || new Date(),
          conteudo_html: this.gerarHTMLAtaCCL(processo, ata)
        })
        
        // Renumerar documentos subsequentes
        documentos.sort((a, b) => (a.numero_sequencial || 999) - (b.numero_sequencial || 999))
        documentos.forEach((doc, index) => {
          if (doc.tipo_documento !== 'ATA_CCL' && (doc.numero_sequencial || 999) >= 3) {
            doc.numero_sequencial = (doc.numero_sequencial || 0) + 1
            doc.folha_numero = `Fl. ${String(doc.numero_sequencial).padStart(3, '0')}`
          }
        })
        
        // Chamar o método de geração do componente de Processos Administrativos
        // Isso vai gerar o PDF completo com todos os documentos incluindo nossa ata
        const componentMethods = componentInstance.methods
        if (componentMethods && componentMethods.gerarHTMLRelatorio) {
          const htmlRelatorio = componentMethods.gerarHTMLRelatorio.call(this, processoCompleto, documentos, produtos)
          
          // Abrir em nova janela
          const novaJanela = window.open('', '_blank')
          novaJanela.document.write(htmlRelatorio)
          novaJanela.document.close()
          novaJanela.document.title = `Processo_${processoCompleto.numero_processo}_com_Ata_CCL.pdf`
        }
        
      } catch (error) {
        console.error('Erro ao gerar relatório com ata:', error)
        this.$swal({
          title: '❌ Erro ao Gerar Relatório',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },

    gerarHTMLAtaCCL(processo, ata) {
      return `
        <div class="documento-header">
          <h1>${processo.nome_orgao || 'Órgão Administrativo'}</h1>
          <h2>ATA DE JULGAMENTO TÉCNICO - CCL</h2>
          <p>Processo nº ${processo.numero_processo}</p>
        </div>

        <div class="documento-content">
          <h3>IDENTIFICAÇÃO DO PROCESSO</h3>
          <p><strong>Número do Processo:</strong> ${processo.numero_processo}</p>
          <p><strong>Objeto:</strong> ${processo.objeto}</p>
          <p><strong>Data do Julgamento CCL:</strong> ${this.formatDate(processo.data_julgamento_ccl || new Date())}</p>
          
          <h3>DECISÃO DA CCL</h3>
          <p><strong>Decisão:</strong> APROVADO TECNICAMENTE</p>
          <p><strong>Ata Número:</strong> ${ata.numero || 'N/A'}</p>
          <p><strong>Data de Publicação:</strong> ${this.formatDate(ata.dataPublicacao || new Date())}</p>
          
          <h3>FUNDAMENTAÇÃO TÉCNICA</h3>
          <div style="text-align: justify; margin: 20px 0;">
            ${processo.ata_julgamento_ccl || 'Fundamentação técnica da decisão CCL.'}
          </div>
          
          <h3>PRÓXIMOS PASSOS</h3>
          <p>O processo segue para análise da Assessoria Jurídica conforme fluxo estabelecido.</p>
          
          <div style="margin-top: 40px; text-align: center;">
            <p><strong>Comissão Central de Licitação - CCL</strong></p>
            <p>Data: ${this.formatDate(new Date())}</p>
          </div>
        </div>
      `
    },

    async obterProcessoCompleto(processoId) {
      try {
        const { default: ProcessosAdministrativosService } = await import('../../services/processosAdministrativosService')
        return await ProcessosAdministrativosService.obterProcesso(processoId)
      } catch (error) {
        console.error('Erro ao obter processo completo:', error)
        return null
      }
    },

    getStatusRecursoClass(status) {
      switch (status) {
        case 'Em prazo recursal': return 'status-recurso-prazo'
        case 'Sem recursos': return 'status-sem-recursos'
        case 'Com recursos': return 'status-com-recursos'
        default: return 'status-indefinido'
      }
    },
    
    async obterTenantId() {
      try {
        // Se já temos o tenant_id, não precisa buscar novamente
        if (this.currentTenantId) {
          return this.currentTenantId
        }
        
        // Tenta obter o tenant_id do usuário logado
        const { data } = await supabase.auth.getSession()
        const user = data?.session?.user
        
        if (!user) {
          console.error('Usuário não está autenticado')
          return
        }
        
        let tenantId = null
        
        // Primeiro tenta obter dos metadados
        if (user.user_metadata?.tenant_id) {
          tenantId = user.user_metadata.tenant_id
        } else {
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
          
          tenantId = userData?.tenant_id
        }
        
        // Só atualiza se o valor mudou para evitar triggers desnecessários
        if (tenantId && tenantId !== this.currentTenantId) {
          this.currentTenantId = tenantId
        } else if (!tenantId) {
          console.error('Tenant ID não encontrado para o usuário')
        }
        
        return tenantId
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
    async carregarDados(forceReload = false) {
      try {
        // Evitar múltiplos carregamentos simultâneos
        if (this.isLoadingData && !forceReload) {
          console.log('🔄 [DEBUG CCL] Já carregando dados, ignorando chamada duplicada')
          return
        }
        
        this.loading = true
        this.isLoadingData = true
        
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível')
          this.loading = false
          this.isLoadingData = false
          return
        }
        
        // Verificar se já temos dados e não é um reload forçado
        if (!forceReload && this.processosPendentesArray.length > 0) {
          console.log('🔄 [DEBUG CCL] Dados já carregados, usando cache')
          this.loading = false
          this.isLoadingData = false
          return
        }
        
        // DEBUG: Carregar TODOS os processos do tenant primeiro para debug
        console.log('🔍 [DEBUG CCL] Iniciando busca de processos...')
        console.log('🔍 [DEBUG CCL] Tenant ID:', this.currentTenantId)
        
        // Query direta para debug - buscar TODOS os processos do tenant
        const { data: todosProcessosTenant, error: errorTodos } = await supabase
          .from('processos_administrativos')
          .select('id, numero_processo, status, tipo_processo, tenant_id')
          .eq('tenant_id', this.currentTenantId)
          .order('atualizado_em', { ascending: false })
        
        if (errorTodos) {
          console.error('❌ [DEBUG CCL] Erro ao buscar todos os processos:', errorTodos)
          throw errorTodos
        }
        
        console.log('📊 [DEBUG CCL] TODOS os processos do tenant:', todosProcessosTenant?.length || 0)
        todosProcessosTenant?.forEach(proc => {
          console.log(`📋 [DEBUG CCL] Processo: ${proc.numero_processo} - Status: ${proc.status} - Tipo: ${proc.tipo_processo}`)
        })
        
        // Agora filtrar apenas os que a CCL deve ver (conforme TramitacaoProcessosService)
        const processosData = (todosProcessosTenant || []).filter(processo => 
          ['assinado_admin', 'julgamento_ccl'].includes(processo.status)
        )
        
        console.log('🎯 [DEBUG CCL] Status filtrados para CCL:', ['assinado_admin', 'julgamento_ccl'])
        console.log('🎯 [DEBUG CCL] Processos que deveriam aparecer:')
        todosProcessosTenant?.forEach(proc => {
          if (['assinado_admin', 'julgamento_ccl'].includes(proc.status)) {
            console.log(`✅ DEVE APARECER: ${proc.numero_processo} - Status: ${proc.status}`)
          } else {
            console.log(`❌ NÃO APARECE: ${proc.numero_processo} - Status: ${proc.status}`)
          }
        })
        
        console.log('🎯 [DEBUG CCL] Processos FILTRADOS para CCL:', processosData.length)
        processosData.forEach(proc => {
          console.log(`✅ [DEBUG CCL] Processo para CCL: ${proc.numero_processo} - Status: ${proc.status}`)
        })
        
        console.log('📊 CCL Dashboard - Processos encontrados:', processosData?.length || 0)
        processosData?.forEach(processo => {
          console.log(`📋 Processo ${processo.numero_processo} - Status: ${processo.status} - Tipo: ${processo.tipo_processo}`)
        })
        
        // Buscar dados completos dos processos filtrados
        if (processosData.length > 0) {
          const idsProcessos = processosData.map(p => p.id)
          const { data: processosCompletos, error: errorCompletos } = await supabase
            .from('processos_administrativos')
            .select('*')
            .in('id', idsProcessos)
            .eq('tenant_id', this.currentTenantId)
          
          if (errorCompletos) {
            console.error('❌ [DEBUG CCL] Erro ao buscar dados completos:', errorCompletos)
            this.processosPendentesArray = []
          } else {
            this.processosPendentesArray = Array.isArray(processosCompletos) ? processosCompletos : []
            console.log('✅ [DEBUG CCL] Dados completos carregados:', this.processosPendentesArray.length)
          }
        } else {
          console.log('⚠️ [DEBUG CCL] Nenhum processo filtrado encontrado')
          this.processosPendentesArray = []
        }
        
        // Carregar recursos do banco de dados
        await this.carregarRecursos()
        
        // Fallback: se não há recursos no banco, inicializar array vazio
        if (!this.recursos) {
          this.recursos = []
        }
        
        // Contar por status - ajustado para o fluxo correto da CCL
        const statsCounts = await Promise.all([
          this.contarPorStatus(['aprovado', 'reprovado']), // CPM já analisou, CCL precisa julgar (pendentes)
          this.contarPorStatus(['julgado_aprovado', 'julgado_reprovado']), // Já julgados pela CCL
          this.contarPorStatus('homologado') // Processos homologados
        ])
        
        // Garantir que processosPendentes é um array antes de usar filter
        const processosArray = Array.isArray(this.processosPendentes) ? this.processosPendentes : []
        this.pendentes = statsCounts[0] || processosArray.filter(p => ['assinado_admin', 'julgamento_ccl'].includes(p.status)).length
        this.aprovados = statsCounts[1] || processosArray.filter(p => p.status === 'julgado_ccl').length
        this.homologados = statsCounts[2]
        
        // Contar recursos em análise
        this.recursosEmAnalise = this.recursos.filter(r => r.status === 'EM ANÁLISE' || r.status === 'AGUARDANDO CPM').length
        
        // Atualizar paginação
        this.atualizarTotalPaginacao('processosPendentes', this.processosPendentesArray.length)
        this.atualizarTotalPaginacao('recursosAnalise', this.recursos.length)
        
        
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
      } finally {
        this.loading = false
        this.isLoadingData = false
      }
    },
    async contarPorStatus(status) {
      if (!this.currentTenantId) return 0
      
      let query = supabase
        .from('processos_administrativos')
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
    formatDate(dateInput) {
      if (!dateInput) return ''
      
      // Se já for um objeto Date
      if (dateInput instanceof Date) {
        return dateInput.toLocaleDateString('pt-BR')
      }
      
      // Converter para string se necessário
      const dateString = String(dateInput)
      
      // Se for uma data no formato ISO
      if (dateString.includes('T')) {
        const date = new Date(dateString)
        return date.toLocaleDateString('pt-BR')
      }
      
      // Se for uma data no formato YYYY-MM-DD
      if (dateString.includes('-')) {
        const parts = dateString.split('-')
        if (parts.length === 3) {
          return `${parts[2]}/${parts[1]}/${parts[0]}`
        }
      }
      
      // Tentar converter para Date como último recurso
      const date = new Date(dateString)
      if (!isNaN(date.getTime())) {
        return date.toLocaleDateString('pt-BR')
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
        case 'julgado_aprovado': return 'Julgado Favorável' // Produto aprovado pela CCL
        case 'julgado_reprovado': return 'Julgado Desfavorável' // Produto reprovado pela CCL
        case 'homologado': return 'Homologado' // Produto homologado
        case 'reprovado': return 'Desfavorável'
        case 'diligencia': return 'Com Diligência'
        case 'pendente': return 'Em Análise'
        default: return status
      }
    },
    
    formatarStatusProcesso(status) {
      switch (status) {
        case 'assinado_admin': return 'Pronto para Julgamento'
        case 'julgamento_ccl': return 'Em Julgamento pela CCL'
        case 'aprovado_ccl': return 'Aprovado pela CCL'
        case 'ata_julgamento_ccl_aprovacao': return 'Ata de Julgamento Emitida - Recomenda Aprovação'
        case 'ata_julgamento_ccl_rejeicao': return 'Ata de Julgamento Emitida - Recomenda Rejeição'
        case 'diligencia_ccl': return 'Diligência CCL'
        case 'homologado': return 'Homologado pela Autoridade Competente'
        case 'indeferido': return 'Indeferido pela Autoridade Competente'
        case 'tramitando_ccl': return 'Em Análise CCL'
        default: return status
      }
    },
    
    getTipoProcessoClass(tipo) {
      switch (tipo) {
        case 'Padronização': return 'tipo-padronizacao'
        case 'Despadronização': return 'tipo-despadronizacao'
        default: return 'tipo-default'
      }
    },
    
    async visualizarProcesso(processo) {
      try {
        console.log('📄 Visualizando processo na CCL:', processo.id, processo.numero_processo)
        
        // Importar o componente dos Processos Administrativos para usar o método dele diretamente
        const ProcessosAdministrativosComponent = await import('@/components/processos/ProcessosAdministrativosComponent.vue')
        const processosComponent = ProcessosAdministrativosComponent.default
        
        // Usar diretamente o método gerarRelatorio dos Processos Administrativos
        // Isso garante que o PDF seja EXATAMENTE IDÊNTICO, incluindo todos os documentos complementares
        await processosComponent.methods.gerarRelatorio.call({
          // Contexto mínimo necessário
          formatarData: this.formatarData,
          formatarStatus: this.formatarStatus,
          ...processosComponent.methods
        }, processo)
        
      } catch (error) {
        console.error('Erro ao visualizar processo:', error)
        alert(`Erro ao gerar relatório: ${error.message}`)
      }
    },

    // REMOVIDOS TODOS OS MÉTODOS DUPLICADOS - AGORA USA DIRETAMENTE DOS PROCESSOS ADMINISTRATIVOS

    formatarData(data) {
      if (!data) return 'N/A'
      return new Date(data).toLocaleDateString('pt-BR')
    },

    formatarStatus(status) {
      const statusMap = {
        'criado_cpm': 'Criado pela CPM',
        'aguardando_aprovacao': 'Aguardando Aprovação',
        'aprovado_cpm': 'Aprovado pela CPM',
        'rejeitado_cpm': 'Rejeitado pela CPM',
        'aguardando_assinatura_orgao': 'Aguardando Assinatura do Órgão',
        'assinado_admin': 'Assinado pelo Órgão Administrativo',
        'rejeitado_admin': 'Rejeitado pelo Órgão Administrativo',
        'julgamento_ccl': 'Em Julgamento pela CCL',
        'aprovado_ccl': 'Aprovado pela CCL',
        'rejeitado_ccl': 'Rejeitado pela CCL',
        'aguardando_assinatura_juridico': 'Aguardando Assinatura Jurídica',
        'aprovado_juridico': 'Aprovado pelo Jurídico',
        'rejeitado_juridico': 'Rejeitado pelo Jurídico',
        'finalizado': 'Processo Finalizado',
        'cancelado': 'Processo Cancelado'
      }
      return statusMap[status] || status
    },
    
    async tramitarProcessoAdministrativo(processo) {
      try {
        const confirmacao = confirm(
          `⚖️ TRAMITAR PROCESSO PARA JULGAMENTO\n\n` +
          `Processo: ${processo.numero_processo}\n` +
          `Status atual: Assinado pelo Órgão Administrativo\n` +
          `Próximo status: Em Julgamento pela CCL\n\n` +
          `Confirma a tramitação?`
        )

        if (!confirmacao) return

        console.log('🚀 Tramitando processo para julgamento CCL:', processo.id)
        console.log('📊 Status atual do processo:', processo.status)
        console.log('📊 Tipo do processo:', processo.tipo_processo)
        
        const resultado = await TramitacaoProcessosService.enviarProcesso(processo.id, 'Processo tramitado para julgamento da CCL')
        console.log('📊 Resultado da tramitação:', resultado)
        
        if (resultado && resultado.sucesso) {
          this.$swal({
            title: '✅ Processo Tramitado!',
            text: `O processo ${processo.numero_processo} foi tramitado para julgamento da CCL com sucesso.`,
            icon: 'success'
          })
          
          // Recarregar dados
          await this.carregarDados(true)
        } else {
          throw new Error('Falha na tramitação do processo')
        }
        
      } catch (error) {
        console.error('Erro ao tramitar processo:', error)
        this.$swal({
          title: '❌ Erro na Tramitação',
          text: `Erro ao tramitar processo: ${error.message}`,
          icon: 'error'
        })
      }
    },

    async julgarProcessoAdministrativo(processo) {
      try {
        const { value: julgamento } = await this.$swal({
          title: `📋 Emitir Ata de Julgamento - Processo ${processo.numero_processo}`,
          html: `
            <div style="text-align: left; padding: 15px; max-height: 70vh; overflow-y: auto;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 10px 0;">📄 Dados do Processo</h4>
                <p><strong>Número:</strong> ${processo.numero_processo}</p>
                <p><strong>Tipo:</strong> ${processo.tipo_processo || 'Pré-qualificação de Bens'}</p>
                <p><strong>Data de Autuação:</strong> ${this.formatDate(processo.criado_em)}</p>
              </div>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">
                  📋 Recomendação da CCL para a Autoridade Competente:
                  <span style="color: red;">*</span>
                </label>
                <select id="recomendacaoProcesso" class="swal2-select" style="width: 100%; padding: 8px;">
                  <option value="">Selecione a recomendação...</option>
                  <option value="recomendar_homologacao">✅ Recomendar Homologação</option>
                  <option value="recomendar_indeferimento">❌ Recomendar Indeferimento</option>
                  <option value="solicitar_diligencia">📄 Solicitar Diligência à CPM</option>
                </select>
              </div>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">
                  🔍 Fundamentação Legal:
                  <span style="color: red;">*</span>
                </label>
                <textarea id="fundamentacaoLegal" class="swal2-textarea" rows="3" placeholder="Base legal da decisão (Ex: Art. 78, § 2º da Lei 14.133/2021 c/c Regulamento Interno...)" style="width: 100%; padding: 8px;"></textarea>
              </div>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">
                  📝 Análise Técnica da CCL:
                  <span style="color: red;">*</span>
                </label>
                <textarea id="fundamentacaoProcesso" class="swal2-textarea" rows="6" placeholder="Descreva a análise técnica detalhada realizada pela CCL sobre o trabalho da CPM, incluindo a verificação da regularidade dos procedimentos, análise da documentação apresentada, e avaliação dos pareceres técnicos..." style="width: 100%; padding: 8px;"></textarea>
              </div>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">
                  💡 Considerações Adicionais:
                </label>
                <textarea id="consideracoesAdicionais" class="swal2-textarea" rows="3" placeholder="Observações adicionais da CCL (se houver)..." style="width: 100%; padding: 8px;"></textarea>
              </div>
              
              <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                <h5 style="margin: 0 0 10px 0; color: #2e7d32;">📋 Fluxo da Ata de Julgamento:</h5>
                <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
                  <li>CCL elabora Ata de Julgamento com análise técnica completa</li>
                  <li>Ata é salva em formato Word e posteriormente em PDF</li>
                  <li>Documento é assinado eletronicamente por todos os membros da CCL</li>
                  <li>Ata é anexada ao processo administrativo</li>
                  <li>Processo é encaminhado à Autoridade Competente para decisão final</li>
                </ol>
              </div>
              
              <div style="background: #fff3cd; padding: 10px; border-radius: 4px;">
                <small><strong>⚠️ Importante:</strong> A CCL elabora a Ata de Julgamento com recomendação técnica. A decisão final de homologar ou indeferir é competência exclusiva da Autoridade Competente.</small>
              </div>
            </div>
          `,
          width: '90%',
          maxWidth: '800px',
          heightAuto: false,
          customClass: {
            container: 'swal2-container-modal',
            popup: 'swal2-popup-modal'
          },
          showCancelButton: true,
          confirmButtonText: '📋 Emitir Ata de Julgamento',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const recomendacao = document.getElementById('recomendacaoProcesso').value
            const fundamentacao = document.getElementById('fundamentacaoProcesso').value.trim()
            const fundamentacaoLegal = document.getElementById('fundamentacaoLegal').value.trim()
            const consideracoesAdicionais = document.getElementById('consideracoesAdicionais').value.trim()
            
            if (!recomendacao) {
              this.$swal.showValidationMessage('Selecione uma recomendação')
              return false
            }
            
            if (!fundamentacaoLegal) {
              this.$swal.showValidationMessage('A fundamentação legal é obrigatória')
              return false
            }
            
            if (!fundamentacao) {
              this.$swal.showValidationMessage('A análise técnica da CCL é obrigatória')
              return false
            }
            
            return { 
              recomendacao, 
              fundamentacao, 
              fundamentacaoLegal,
              consideracoesAdicionais 
            }
          }
        })
        
        if (!julgamento) return
        
        // Definir novo status baseado na recomendação da CCL
        let novoStatus
        switch (julgamento.recomendacao) {
          case 'recomendar_homologacao':
            novoStatus = 'ata_julgamento_ccl_homologacao'
            break
          case 'recomendar_indeferimento':
            novoStatus = 'ata_julgamento_ccl_indeferimento'
            break
          case 'solicitar_diligencia':
            novoStatus = 'diligencia_ccl'
            break
        }
        
        // Atualizar processo no banco
        const { error } = await supabase
          .from('processos_administrativos')
          .update({
            status: novoStatus,
            ata_julgamento_ccl: julgamento.fundamentacao,
            recomendacao_ccl: julgamento.recomendacao,
            fundamentacao_legal_ccl: julgamento.fundamentacaoLegal,
            consideracoes_adicionais_ccl: julgamento.consideracoesAdicionais,
            ata_emitida_ccl_em: new Date().toISOString(),
            atualizado_em: new Date().toISOString()
          })
          .eq('id', processo.id)
        
        if (error) throw error
        
        // Recarregar dados
        await this.carregarDados(true)
        
        this.$swal({
          title: '📋 Ata de Julgamento Emitida!',
          text: `A Ata de Julgamento do processo ${processo.numero_processo} foi criada com sucesso. O processo será encaminhado à Autoridade Competente para decisão final.`,
          icon: 'success'
        })
        
      } catch (error) {
        console.error('Erro ao julgar processo:', error)
        this.$swal({
          title: '❌ Erro',
          text: `Erro ao registrar julgamento: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    // Método para emitir ata de julgamento (substitui homologar/indeferir)
    async emitirAtaJulgamento(processo) {
      try {
        const { value: ataJulgamento } = await this.$swal({
          title: `📋 Emitir Ata de Julgamento - Processo ${processo.numeroAta}`,
          html: `
            <div style="text-align: left; padding: 15px;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 10px 0;">📄 Dados do Processo</h4>
                <p><strong>Ata:</strong> ${processo.numeroAta}</p>
                <p><strong>Produtos:</strong> ${processo.totalProdutos}</p>
                <p><strong>Data do Julgamento CCL:</strong> ${this.formatDate(processo.dataJulgamento)}</p>
              </div>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Recomendação da CCL para a Autoridade Competente:</label>
                <select id="recomendacaoAta" class="swal2-select" style="width: 100%;">
                  <option value="">Selecione a recomendação...</option>
                  <option value="recomendar_homologacao">📋 Recomendar Homologação do Processo</option>
                  <option value="recomendar_indeferimento">📋 Recomendar Indeferimento do Processo</option>
                  <option value="solicitar_esclarecimentos">📋 Solicitar Esclarecimentos Adicionais</option>
                </select>
              </div>
              
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Fundamentação Técnica da CCL:</label>
                <textarea id="fundamentacaoAta" class="swal2-textarea" rows="6" placeholder="Descreva a análise técnica completa que será incluída na Ata de Julgamento..." style="width: 100%;"></textarea>
              </div>
              
              <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                <h5 style="margin: 0 0 10px 0; color: #2e7d32;">📋 Fluxo da Ata de Julgamento:</h5>
                <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
                  <li>CCL elabora Ata com análise técnica e recomendação</li>
                  <li>Ata é salva em formato Word e PDF</li>
                  <li>Documento é assinado eletronicamente pelos membros da CCL</li>
                  <li>Ata é anexada ao processo administrativo</li>
                  <li>Processo é remetido à Autoridade Competente para decisão final</li>
                </ol>
              </div>
              
              <div style="background: #fff3cd; padding: 10px; border-radius: 4px;">
                <small><strong>⚠️ Importante:</strong> A CCL elabora a Ata com recomendação técnica. A decisão final de homologar ou indeferir é competência exclusiva da Autoridade Competente.</small>
              </div>
            </div>
          `,
          width: '700px',
          showCancelButton: true,
          confirmButtonText: '📋 Emitir Ata de Julgamento',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const recomendacao = document.getElementById('recomendacaoAta').value
            const fundamentacao = document.getElementById('fundamentacaoAta').value.trim()
            
            if (!recomendacao) {
              this.$swal.showValidationMessage('Selecione uma recomendação')
              return false
            }
            
            if (!fundamentacao) {
              this.$swal.showValidationMessage('A fundamentação técnica é obrigatória')
              return false
            }
            
            return { recomendacao, fundamentacao }
          }
        })
        
        if (!ataJulgamento) return
        
        // Simular criação da ata (aqui seria integrado com sistema de documentos)
        this.$swal({
          title: '📋 Ata de Julgamento Emitida!',
          html: `
            <div style="text-align: left; padding: 15px;">
              <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                <h4 style="margin: 0 0 10px 0; color: #2e7d32;">✅ Ata Criada com Sucesso</h4>
                <p><strong>Processo:</strong> ${processo.numeroAta}</p>
                <p><strong>Recomendação:</strong> ${ataJulgamento.recomendacao.replace('recomendar_', '').replace('_', ' ').toUpperCase()}</p>
                <p><strong>Status:</strong> Aguardando assinatura eletrônica dos membros da CCL</p>
              </div>
              
              <div style="background: #d1ecf1; padding: 15px; border-radius: 8px;">
                <h5 style="margin: 0 0 10px 0; color: #0277bd;">📋 Próximos Passos:</h5>
                <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
                  <li>Ata será disponibilizada para assinatura eletrônica</li>
                  <li>Após assinatura, será salva como PDF</li>
                  <li>Processo será encaminhado à Autoridade Competente</li>
                  <li>Autoridade decidirá pela homologação ou indeferimento</li>
                </ol>
              </div>
            </div>
          `,
          icon: 'success',
          confirmButtonText: '✅ Entendido'
        })
        
        // Aqui você atualizaria o status no banco de dados
        // Por exemplo: status = 'ata_julgamento_emitida_ccl'
        
        // Recarregar dados
        await this.carregarDados(true)
        
      } catch (error) {
        console.error('Erro ao emitir ata de julgamento:', error)
        this.$swal({
          title: '❌ Erro',
          text: `Erro ao emitir ata de julgamento: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async julgarProcessoCCL(processo) {
      try {
        const { value: decisaoCCL } = await this.$swal({
          title: `⚖️ Julgamento CCL - ${processo.numeroAta}`,
          html: `
            <div style="text-align: left; padding: 10px; max-width: 100%; box-sizing: border-box;">
              <div style="background: #f8f9fa; padding: 12px; border-radius: 8px; margin-bottom: 15px;">
                <h4 style="margin: 0 0 8px 0; font-size: 16px;">📄 Resumo do Processo</h4>
                <p style="margin: 5px 0; word-wrap: break-word;"><strong>Ata:</strong> ${processo.numeroAta}</p>
                <p style="margin: 5px 0;"><strong>Produtos:</strong> ${processo.totalProdutos}</p>
                <p style="margin: 5px 0;"><strong>Data Julgamento CCL:</strong> ${this.formatDate(processo.dataJulgamento)}</p>
                <p style="margin: 5px 0; word-wrap: break-word;"><strong>Recomendação da CCL:</strong> <span style="color: #2e7d32; font-weight: bold;">${processo.decisaoCCL}</span></p>
              </div>
              
              <div style="margin-bottom: 12px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px; font-size: 14px;">Decisão da CCL:</label>
                <select id="decisaoCCL" class="swal2-select" style="width: 100%; box-sizing: border-box;">
                  <option value="">Selecione a decisão...</option>
                  <option value="homologar">✅ APROVAR - Recomendar aprovação do processo</option>
                  <option value="indeferir">❌ REJEITAR - Rejeitar o processo</option>
                  <option value="diligencia">📄 DILIGÊNCIA - Solicitar correções/esclarecimentos</option>
                </select>
              </div>
              
              <div style="margin-bottom: 12px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px; font-size: 14px;">Parecer Técnico da CCL:</label>
                <textarea id="parecerCCL" class="swal2-textarea" rows="5" 
                  placeholder="Fundamente tecnicamente sua decisão..." 
                  style="width: 100%; box-sizing: border-box; resize: vertical;"></textarea>
              </div>
              
              <div style="background: #e3f2fd; padding: 12px; border-radius: 8px; margin-bottom: 12px;">
                <h5 style="margin: 0 0 8px 0; color: #1976d2; font-size: 14px;">⚖️ Efeitos da Decisão:</h5>
                <div style="font-size: 12px; line-height: 1.4;">
                  <p style="margin: 3px 0;"><strong>✅ HOMOLOGAÇÃO:</strong> Processo aprovado, DCBs serão emitidas</p>
                  <p style="margin: 3px 0;"><strong>❌ INDEFERIMENTO:</strong> Processo rejeitado, fornecedores notificados</p>
                  <p style="margin: 3px 0;"><strong>📄 DILIGÊNCIA:</strong> Processo retorna para análise complementar</p>
                </div>
              </div>
              
              <div style="background: #fff3cd; padding: 8px; border-radius: 4px;">
                <small style="font-size: 12px;"><strong>⚠️ Importante:</strong> Esta é a decisão final da Autoridade Competente sobre a recomendação técnica emitida pela CCL.</small>
              </div>
            </div>
          `,
          width: '750px',
          maxWidth: '92vw',
          showCancelButton: true,
          confirmButtonText: '⚖️ Confirmar Julgamento',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const decisao = document.getElementById('decisaoCCL').value
            const parecer = document.getElementById('parecerCCL').value.trim()
            
            if (!decisao) {
              this.$swal.showValidationMessage('Selecione uma decisão')
              return false
            }
            
            if (!parecer) {
              this.$swal.showValidationMessage('O parecer técnico é obrigatório')
              return false
            }
            
            return { decisao, parecer }
          }
        })
        
        if (!decisaoCCL) return
        
        // Usar o serviço de tramitação para enviar para próxima etapa
        const resultado = await TramitacaoProcessosService.enviarProcesso(
          processo.id, 
          `CCL julgou processo: ${decisaoCCL.decisao.toUpperCase()} - ${decisaoCCL.parecer}`
        )
        
        if (!resultado || !resultado.sucesso) {
          throw new Error('Falha na tramitação do processo')
        }
        
        // Mostrar resultado da decisão
        let tituloResultado, iconeResultado, corResultado, proximosPassos
        
        switch(decisaoCCL.decisao) {
          case 'homologar':
            tituloResultado = '✅ CCL Aprovou o Processo!'
            iconeResultado = 'success'
            corResultado = '#2e7d32'
            proximosPassos = `
              <li>Processo será enviado para Assessoria Jurídica</li>
              <li>Análise jurídica será realizada</li>
              <li>Após aprovação jurídica, edital será publicado</li>
              <li>Autoridade Competente fará homologação final</li>
            `
            break
          case 'indeferir':
            tituloResultado = '❌ CCL Rejeitou o Processo'
            iconeResultado = 'warning'
            corResultado = '#d32f2f'
            proximosPassos = `
              <li>Processo será devolvido para CPM</li>
              <li>CPM pode fazer correções e reenviar</li>
              <li>Fornecedores serão notificados</li>
              <li>Nova análise será necessária se aplicável</li>
            `
            break
          case 'diligencia':
            tituloResultado = '📄 CCL Solicitou Diligência'
            iconeResultado = 'info'
            corResultado = '#1976d2'
            proximosPassos = `
              <li>Processo será devolvido para CPM</li>
              <li>CPM deve providenciar esclarecimentos</li>
              <li>Após correções, retorna para nova análise CCL</li>
              <li>Nova decisão será tomada pela CCL</li>
            `
            break
        }
        
        await this.$swal({
          title: tituloResultado,
          html: `
            <div style="text-align: left; padding: 15px;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                <h4 style="margin: 0 0 10px 0; color: ${corResultado};">Decisão Registrada</h4>
                <p><strong>Processo:</strong> ${processo.numeroAta}</p>
                <p><strong>Decisão:</strong> ${decisaoCCL.decisao.toUpperCase()}</p>
                <p><strong>Data:</strong> ${this.formatDate(new Date())}</p>
              </div>
              
              <div style="background: #e8f5e8; padding: 15px; border-radius: 8px;">
                <h5 style="margin: 0 0 10px 0; color: ${corResultado};">📋 Próximos Passos:</h5>
                <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
                  ${proximosPassos}
                </ol>
              </div>
            </div>
          `,
          icon: iconeResultado,
          confirmButtonText: '✅ Entendido'
        })
        
        // Recarregar os dados para atualizar as listas
        await this.carregarDados(true)
        
        // Recarregar especificamente as seções de homologação
        await this.carregarProcessosPendentesHomologacao()
        await this.carregarHomologacoesRecentes()
        
        // Forçar atualização da interface
        this.$forceUpdate()
        
      } catch (error) {
        console.error('Erro ao processar decisão da autoridade:', error)
        this.$swal({
          title: '❌ Erro',
          text: `Erro ao processar decisão: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async carregarHomologacoesRecentes() {
      try {
        if (!this.currentTenantId) return
        
        // Buscar processos homologados, indeferidos ou em diligência pela autoridade
        const { data: homologacoesData, error } = await supabase
          .from('processos_administrativos')
          .select(`
            id,
            numero_processo,
            objeto,
            status,
            decisao_autoridade,
            fundamentacao_autoridade,
            data_decisao_autoridade,
            criado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['aprovado_ccl', 'aprovado_juridico', 'edital_publicado', 'homologado'])
          .order('data_decisao_autoridade', { ascending: false })
          .limit(10)
        
        if (error) {
          console.error('Erro ao carregar homologações recentes:', error)
          return
        }
        
        // Mapear dados para o formato da interface
        this.homologacoesRecentes = (homologacoesData || []).map(processo => {
          return {
            id: processo.id,
            numeroAta: processo.numero_processo,
            dataHomologacao: processo.data_decisao_autoridade,
            totalProdutos: 1,
            autoridade: 'Autoridade Competente',
            motivo: processo.fundamentacao_autoridade || 'Decisão fundamentada',
            tipo: processo.decisao_autoridade === 'homologar' ? 'homologada' : 
                  processo.decisao_autoridade === 'indeferir' ? 'indeferida' : 'diligencia'
          }
        })
        
        // Atualizar contadores
        this.homologacoesAprovadas = this.homologacoesRecentes.filter(h => h.tipo === 'homologada').length
        this.homologacoesIndeferidas = this.homologacoesRecentes.filter(h => h.tipo === 'indeferida').length
        
        console.log('✅ Homologações recentes carregadas:', this.homologacoesRecentes.length)
        
      } catch (error) {
        console.error('Erro ao carregar homologações recentes:', error)
      }
    },
    
    calcularPrazoCCL(dataAssinatura) {
      if (!dataAssinatura) return 'Sem prazo'
      
      const hoje = new Date()
      const dataAssinado = new Date(dataAssinatura)
      const prazoFinal = this.adicionarDiasUteis(dataAssinado, 10) // 10 dias úteis para CCL
      
      if (hoje > prazoFinal) return 'Vencido'
      
      const diasUteisRestantes = this.calcularDiasUteisEntre(hoje, prazoFinal)
      return diasUteisRestantes <= 0 ? 'Hoje' : `${diasUteisRestantes} dias úteis`
    },
    
    getPrazoCCLClass(dataAssinatura) {
      if (!dataAssinatura) return 'prazo-indefinido'
      
      const hoje = new Date()
      const dataAssinado = new Date(dataAssinatura)
      const prazoFinal = this.adicionarDiasUteis(dataAssinado, 10)
      
      if (hoje > prazoFinal) return 'prazo-vencido'
      
      const diasUteis = this.calcularDiasUteisEntre(hoje, prazoFinal)
      if (diasUteis <= 2) return 'prazo-urgente'
      if (diasUteis <= 5) return 'prazo-atencao'
      return 'prazo-normal'
    },
    
    getStatusClass(status) {
      const statusMap = {
        'AGUARDANDO AUTORIDADE': 'status-pendente',
        'HOMOLOGADO': 'status-aprovado',
        'INDEFERIDO': 'status-rejeitado',
        'EM DILIGÊNCIA': 'status-diligencia',
        'EM ANÁLISE': 'status-analise'
      }
      return statusMap[status] || 'status-padrao'
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

            <!-- Recomendação da CCL -->
            <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 15px 0; color: #388e3c;">📋 Recomendação da CCL para Autoridade Competente</h4>
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 8px;">Recomendação Técnica:</label>
                <select id="decisaoCCL" class="swal2-select" style="width: 100%;">
                  <option value="">Selecione uma recomendação</option>
                  <option value="recomendar_homologacao">📋 Recomendar Homologação (Aprovar pré-qualificação)</option>
                  <option value="recomendar_indeferimento">📋 Recomendar Indeferimento (Rejeitar pré-qualificação)</option>
                  <option value="diligencia">📋 Solicitar Diligência à CPM</option>
                  <option value="pendencia">⏳ Aguardar Documentação Complementar</option>
                </select>
              </div>
              <div style="background: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 10px;">
                <small><strong>⚠️ Importante:</strong> Esta é uma recomendação técnica da CCL. A decisão final de homologar ou indeferir será tomada pela Autoridade Competente.</small>
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
        confirmButtonText: '📋 Emitir Ata de Julgamento',
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
        case 'recomendar_homologacao': return 'ata_julgamento_recomenda_aprovacao'
        case 'recomendar_indeferimento': return 'ata_julgamento_recomenda_rejeicao'
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
              <button class="swal2-confirm swal2-styled" onclick="window.baixarDocumentacaoProduto('${produto.id}')">
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
        case 'julgado_aprovado': return 'status-aprovado' // Verde para produtos julgados como aprovados
        case 'julgado_reprovado': return 'status-reprovado' // Vermelho para produtos julgados como reprovados
        case 'homologado': return 'status-aprovado' // Verde para produtos homologados
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        case 'diligencia': return 'status-diligencia'
        default: return 'status-pendente' // Badge cinza padrão para status desconhecidos
      }
    },
    publicarDecisao(id) {
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, abriria um formulário para registrar a decisão da comissão e publicar no Diário Oficial.',
        icon: 'info'
      })
    },
    async visualizarAta(ata) {
      try {
        // Verificar se é uma ata de homologação (tem numeroAta) ou uma ata publicada (tem numero)
        const isHomologacao = ata.numeroAta !== undefined
        
        // Buscar dados da ata completa se for um processo de homologação
        let ataCompleta = ata
        if (isHomologacao) {
          const { data: ataData, error: ataError } = await supabase
            .from('atas_julgamento')
            .select('*')
            .eq('id', ata.id)
            .eq('tenant_id', this.currentTenantId)
            .single()
            
          if (ataError) throw ataError
          ataCompleta = ataData
        }
        
        // Buscar produtos vinculados à ata
        const { data: produtos, error } = await supabase
          .from('produtos')
          .select(`
            id,
            nome,
            marca,
            modelo,
            fabricante,
            status,
            julgado_em,
            adequacao_tecnica,
            observacoes_ccl,
            base_legal
          `)
          .eq('ata_julgamento_id', ata.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (error) throw error
        
        const produtosAprovados = produtos?.filter(p => p.status === 'julgado_aprovado') || []
        const produtosReprovados = produtos?.filter(p => p.status === 'julgado_reprovado') || []
        
        // Usar as propriedades corretas dependendo do tipo
        const numero = isHomologacao ? ata.numeroAta : (ata.numero || ataCompleta.numero)
        const periodo = isHomologacao ? ataCompleta.periodo : ata.periodo
        const dataPublicacao = isHomologacao ? ata.dataJulgamento : ata.dataPublicacao
        const status = isHomologacao ? ata.decisaoCCL : ata.statusRecursal
        const totalProcessos = isHomologacao ? ata.totalProdutos : ata.totalProcessos
        
        this.$swal({
          title: `📋 Ata de Julgamento: ${numero || 'N/A'}`,
          html: `
            <div style="text-align: left; padding: 15px; max-height: 500px; overflow-y: auto;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 15px 0; color: #495057;">📄 Informações da Ata</h4>
                <p><strong>Número:</strong> ${numero || 'N/A'}</p>
                <p><strong>Período:</strong> ${periodo || 'N/A'}</p>
                <p><strong>Data Publicação:</strong> ${this.formatDate(dataPublicacao) || 'N/A'}</p>
                <p><strong>Status:</strong> ${status || 'N/A'}</p>
                <p><strong>Total de Processos:</strong> ${totalProcessos || 0}</p>
                ${isHomologacao ? `<p><strong>Tipo:</strong> Aguardando Homologação pela Autoridade Competente</p>` : ''}
              </div>
              
              <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                <h5 style="color: #2d5a2d; margin: 0 0 10px 0;">✅ Produtos Aprovados (${produtosAprovados.length})</h5>
                ${produtosAprovados.length > 0 ? 
                  produtosAprovados.map(p => `
                    <div style="border-bottom: 1px solid #c8e6c8; padding: 8px 0;">
                      <strong>${p.nome}</strong> - ${p.marca}<br>
                      <small>Julgado em: ${this.formatDate(p.julgado_em)}</small>
                    </div>
                  `).join('') : 
                  '<p style="color: #666; font-style: italic;">Nenhum produto aprovado</p>'
                }
              </div>
              
              <div style="background: #fce8e8; padding: 15px; border-radius: 8px;">
                <h5 style="color: #5a2d2d; margin: 0 0 10px 0;">❌ Produtos Reprovados (${produtosReprovados.length})</h5>
                ${produtosReprovados.length > 0 ? 
                  produtosReprovados.map(p => `
                    <div style="border-bottom: 1px solid #f5c6c6; padding: 8px 0;">
                      <strong>${p.nome}</strong> - ${p.marca}<br>
                      <small>Julgado em: ${this.formatDate(p.julgado_em)}</small>
                    </div>
                  `).join('') : 
                  '<p style="color: #666; font-style: italic;">Nenhum produto reprovado</p>'
                }
              </div>
              
              ${ata.conteudoAta ? `
                <div style="background: #fff; border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-top: 15px;">
                  <h5>📝 Conteúdo da Ata</h5>
                  <pre style="white-space: pre-wrap; font-family: Arial; font-size: 12px;">${ata.conteudoAta}</pre>
                </div>
              ` : ''}
            </div>
          `,
          width: '800px',
          showCancelButton: true,
          confirmButtonText: '📥 Baixar PDF',
          cancelButtonText: '❌ Fechar'
        }).then((result) => {
          if (result.isConfirmed) {
            this.baixarPDF(ata)
          }
        })
        
      } catch (error) {
        console.error('Erro ao visualizar ata:', error)
        this.$swal({
          title: '❌ Erro ao Carregar Ata',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
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
            fundamentacao,
            decisao,
            fundamentacao_decisao,
            responsavel_decisao,
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
          this.atualizarTotalPaginacao('recursosAnalise', recursosData.length)
          console.log('Recursos carregados do banco de dados:', recursosData.length)
        } else {
          this.recursos = []
          this.atualizarTotalPaginacao('recursosAnalise', 0)
          console.log('Nenhum recurso encontrado no banco')
        }
        
      } catch (error) {
        console.error('Erro ao carregar recursos:', error)
        // Em caso de erro, manter array vazio
        this.recursos = []
        this.atualizarTotalPaginacao('recursosAnalise', 0)
      }
    },
    
    async carregarAtasJulgamento() {
      try {
        if (!this.currentTenantId) return
        
        // Carregar atas de julgamento PUBLICADAS da tabela atas_julgamento
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
          .in('status_ata', ['EM PRAZO', 'PRAZO_EXPIRADO', 'PUBLICADA']) // Atas publicadas (em prazo, prazo expirado ou finalizadas)
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
          this.atualizarTotalPaginacao('atasPublicadas', atasData.length)
          console.log('Atas de julgamento carregadas do banco:', atasData.length)
        } else {
          this.atasPublicadas = 0
          this.atualizarTotalPaginacao('atasPublicadas', 0)
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
          .in('status_ata', ['ELABORACAO', 'EM_ELABORACAO']) // Filtrar apenas atas em elaboração
          .order('data_inicio', { ascending: false })
        
        if (error) {
          console.error('Erro ao carregar atas em elaboração:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (atasData && atasData.length > 0) {
          this.atasEmElaboracao = atasData.map(ata => ({
            id: ata.id,
            numero_ata: ata.numero,
            numero: ata.numero,
            periodo: ata.periodo,
            processos_count: ata.total_processos,
            status: 'elaboracao',
            data_inicio: ata.data_inicio || ata.criado_em,
            responsavel: ata.responsavel_elaboracao || 'CCL',
            progresso: ata.progresso_elaboracao || 0,
            observacoes: ata.observacoes,
            criadoEm: ata.criado_em,
            atualizadoEm: ata.atualizado_em
          }))
          // Atualizar contador de atas em andamento
          this.atasEmAndamento = atasData.length
          this.atualizarTotalPaginacao('atasElaboracao', atasData.length)
          console.log('Atas em elaboração carregadas do banco:', atasData.length)
        } else {
          this.atasEmAndamento = 0
          this.atualizarTotalPaginacao('atasElaboracao', 0)
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
          
          // Atualizar paginação
          this.atualizarTotalPaginacao('homologacoesRecentes', homologacoesData.length)
          
          console.log('Homologações carregadas do banco:', homologacoesData.length)
        } else {
          this.atualizarTotalPaginacao('homologacoesRecentes', 0)
          console.log('Nenhuma homologação encontrada no banco')
        }
        
      } catch (error) {
        console.error('Erro ao carregar homologações:', error)
      }
    },
    
    async carregarProcessosPendentesHomologacao() {
      try {
        if (!this.currentTenantId) return
        
        // Buscar processos que foram julgados pela CCL e aguardam decisão da autoridade
        const { data: processosData, error } = await supabase
          .from('processos_administrativos')
          .select(`
            id,
            numero_processo,
            objeto,
            status,
            ata_emitida_ccl_em,
            ata_julgamento_ccl,
            recomendacao_ccl,
            fundamentacao_legal_ccl,
            decisao_autoridade,
            fundamentacao_autoridade,
            data_decisao_autoridade,
            criado_em,
            atualizado_em
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['julgamento_ccl', 'aprovado_ccl'])
          .order('ata_emitida_ccl_em', { ascending: true })
        
        console.log('Debug Processos Homologação:')
        console.log('- Tenant ID:', this.currentTenantId)
        console.log('- Query error:', error)
        console.log('- Processos encontrados:', processosData?.length || 0)
        console.log('- Dados dos processos:', processosData)
        
        if (error) {
          console.error('Erro ao carregar processos pendentes de homologação:', error)
          return
        }
        
        // Mapear os dados para o formato usado no template
        if (processosData && processosData.length > 0) {
          this.processosPendentesHomologacao = processosData.map(processo => {
            const jaDecidido = processo.status === 'aprovado_ccl'
            
            return {
              id: processo.id,
              numeroAta: processo.numero_processo, 
              dataJulgamento: processo.ata_emitida_ccl_em,
              totalProdutos: 1, // Cada processo representa um conjunto de produtos
              decisaoCCL: this.mapearRecomendacaoParaTexto(processo.recomendacao_ccl),
              statusRecursos: this.determinarStatusRecursosProcesso(processo.status),
              observacoes: processo.fundamentacao_legal_ccl,
              jaDecidido: jaDecidido,
              tipoDecisao: jaDecidido ? this.mapearDecisaoAutoridade(processo.decisao_autoridade) : null,
              dataDecisao: processo.data_decisao_autoridade
            }
          })
          
          // Separar processos pendentes dos já decididos
          const processosPendentes = this.processosPendentesHomologacao.filter(p => !p.jaDecidido)
          const processosDecididos = this.processosPendentesHomologacao.filter(p => p.jaDecidido)
          
          this.homologacoesPendentes = processosPendentes.length
          this.processosPendentes = processosPendentes.length
          
          console.log('Processos pendentes de homologação:', processosPendentes.length)
          console.log('Processos já decididos:', processosDecididos.length)
          
          // Atualizar paginação
          this.atualizarTotalPaginacao('processosPendentes', this.processosPendentesHomologacao.length)
        } else {
          this.homologacoesPendentes = 0
          this.processosPendentes = 0
          this.atualizarTotalPaginacao('processosPendentes', 0)
          console.log('Nenhum processo encontrado')
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
    
    mapearRecomendacaoParaTexto(recomendacao) {
      switch (recomendacao) {
        case 'recomendar_homologacao':
          return 'HOMOLOGAÇÃO RECOMENDADA'
        case 'recomendar_indeferimento':
          return 'INDEFERIMENTO RECOMENDADO'
        case 'solicitar_esclarecimentos':
          return 'ESCLARECIMENTOS SOLICITADOS'
        default:
          return 'APROVADA'
      }
    },
    
    determinarStatusRecursosProcesso(status) {
      switch (status) {
        case 'julgado_ccl':
          return 'AGUARDANDO AUTORIDADE'
        case 'homologado_autoridade':
          return 'HOMOLOGADO'
        case 'indeferido_autoridade':
          return 'INDEFERIDO'
        case 'diligencia_autoridade':
          return 'EM DILIGÊNCIA'
        default:
          return 'EM ANÁLISE'
      }
    },
    
    mapearDecisaoAutoridade(decisao) {
      switch (decisao) {
        case 'homologar':
          return 'HOMOLOGADA'
        case 'indeferir':
          return 'INDEFERIDA'
        case 'diligencia':
          return 'DILIGÊNCIA SOLICITADA'
        default:
          return null
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
          
          // Atualizar paginação
          this.atualizarTotalPaginacao('dcbsAtivas', dcbsData.length)
          
          console.log('DCBs ativas carregadas do banco:', dcbsData.length)
          console.log('Total de DCBs emitidas:', this.dcbsEmitidas)
        } else {
          console.log('Nenhuma DCB ativa encontrada no banco')
          this.dcbsEmitidas = 0
          this.atualizarTotalPaginacao('dcbsAtivas', 0)
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
    async analisarRecurso(recurso) {
      try {
        const prazoVencido = new Date(recurso.prazo_final) < new Date()
        
        const result = await this.$swal({
          title: '📋 Analisar Recurso Administrativo',
          html: `
            <div style="text-align: left; padding: 15px;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 10px 0; color: #495057;">📄 Dados do Recurso</h4>
                <p><strong>Produto/Processo:</strong> ${recurso.produto_nome}</p>
                <p><strong>Recorrente:</strong> ${recurso.recorrente}</p>
                <p><strong>Ata Referência:</strong> ${recurso.ata_referencia}</p>
                <p><strong>Data do Recurso:</strong> ${this.formatDate(recurso.data_recurso)}</p>
                <p><strong>Prazo para Decisão:</strong> ${this.formatDate(recurso.prazo_final)} 
                  ${prazoVencido ? '<span style="color: #dc3545; font-weight: bold;">(VENCIDO)</span>' : '<span style="color: #28a745; font-weight: bold;">(EM PRAZO)</span>'}
                </p>
                <p><strong>Status Atual:</strong> ${recurso.status}</p>
              </div>
              
              <div style="background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin-bottom: 15px;">
                <h5 style="margin: 0 0 10px 0; color: #495057;">📝 Fundamentação do Recorrente</h5>
                <div style="background: #f9f9f9; padding: 10px; border-radius: 4px; max-height: 150px; overflow-y: auto;">
                  ${recurso.fundamentacao || 'Fundamentação não disponível'}
                </div>
              </div>
              
              <div style="background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px;">
                <h5 style="margin: 0 0 20px 0; color: #495057; text-align: center;">⚖️ Decisão da Comissão</h5>
                
                <!-- Decisão -->
                <div style="margin-bottom: 20px;">
                  <label style="display: block; font-weight: bold; margin-bottom: 8px; color: #333;">Decisão sobre o Recurso:</label>
                  <select id="decisaoRecurso" style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px; background: white;">
                    <option value="">🔽 Selecione uma decisão</option>
                    <option value="deferido">✅ DEFERIR - Reverter decisão da CCL (procedente)</option>
                    <option value="indeferido">❌ INDEFERIR - Manter decisão da CCL (improcedente)</option>
                    <option value="encaminhar_cpm">📋 ENCAMINHAR para CPM - Requerer nova análise técnica</option>
                  </select>
                </div>
                
                <!-- Fundamentação -->
                <div style="margin-bottom: 20px;">
                  <label style="display: block; font-weight: bold; margin-bottom: 8px; color: #333;">Fundamentação Legal e Técnica:</label>
                  <textarea id="fundamentacaoRecurso" 
                            style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px; font-family: Arial, sans-serif; resize: vertical; min-height: 120px;" 
                            placeholder="Justificativa da decisão com base legal e técnica...
                            
Exemplo:
- Análise da fundamentação apresentada
- Verificação da tempestividade 
- Base legal: Lei 14.133/2021, Art. XXX
- Considerações técnicas específicas"></textarea>
                </div>
                
                <!-- Responsável -->
                <div style="margin-bottom: 15px;">
                  <label style="display: block; font-weight: bold; margin-bottom: 8px; color: #333;">Responsável pela Decisão:</label>
                  <input id="responsavelRecurso" 
                         style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px;" 
                         type="text" 
                         placeholder="Nome do responsável pela decisão" 
                         value="${this.usuarioNome || 'CCL'}">
                </div>
              </div>
              
              <div style="background: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 15px;">
                <small><strong>📚 Base Legal:</strong> Art. 165-171 da Lei 14.133/2021. A decisão será registrada e encaminhada para conhecimento das partes.</small>
              </div>
            </div>
          `,
          width: '950px',
          showCancelButton: true,
          confirmButtonText: '✅ Confirmar Decisão',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const decisao = document.getElementById('decisaoRecurso').value
            const fundamentacao = document.getElementById('fundamentacaoRecurso').value.trim()
            const responsavel = document.getElementById('responsavelRecurso').value.trim()
            
            if (!decisao) {
              this.$swal.showValidationMessage('Selecione uma decisão')
              return false
            }
            if (!fundamentacao) {
              this.$swal.showValidationMessage('Informe a fundamentação da decisão')
              return false
            }
            if (!responsavel) {
              this.$swal.showValidationMessage('Informe o responsável pela decisão')
              return false
            }
            
            return { decisao, fundamentacao, responsavel }
          }
        })

        if (!result.isConfirmed) return

        // Salvar decisão no banco de dados
        const updateData = {
          decisao: result.value.decisao,
          fundamentacao_decisao: result.value.fundamentacao,
          responsavel_decisao: result.value.responsavel,
          data_decisao: new Date().toISOString(),
          status: result.value.decisao === 'encaminhar_cpm' ? 'AGUARDANDO CPM' : 
                  result.value.decisao === 'deferido' ? 'DEFERIDO' : 'INDEFERIDO',
          atualizado_em: new Date().toISOString()
        }

        console.log('Atualizando recurso:', recurso.id, 'com dados:', updateData)

        const { data: updatedData, error } = await supabase
          .from('recursos')
          .update(updateData)
          .eq('id', recurso.id)
          .select()

        console.log('Resultado da atualização:', { updatedData, error })
        
        if (error) {
          console.warn('Erro ao salvar decisão (tabela pode não existir):', error)
          this.$swal({
            title: '⚠️ Erro ao Salvar Decisão',
            html: `
              <div style="text-align: left; padding: 15px;">
                <p>Não foi possível salvar a decisão no banco de dados.</p>
                <p><strong>Possível causa:</strong> Tabela de recursos não existe.</p>
                <p><strong>Ação necessária:</strong> Execute o script <code>criar_tabela_recursos.sql</code></p>
                <hr>
                <p><strong>Decisão registrada localmente:</strong></p>
                <p><strong>Recurso:</strong> ${recurso.produto_nome}</p>
                <p><strong>Decisão:</strong> ${result.value.decisao.toUpperCase()}</p>
                <p><strong>Responsável:</strong> ${result.value.responsavel}</p>
              </div>
            `,
            icon: 'warning'
          })
          return
        }
        
        // Recarregar dados
        await this.carregarRecursos()
        await this.carregarDados()
        
        // Sucesso
        const decisaoTexto = result.value.decisao === 'deferido' ? 'DEFERIDO' : 
                            result.value.decisao === 'indeferido' ? 'INDEFERIDO' : 'ENCAMINHADO PARA CPM'
        
        this.$swal({
          title: '✅ Recurso Analisado com Sucesso!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4>📋 Decisão Registrada</h4>
              <p><strong>Recurso:</strong> ${recurso.produto_nome}</p>
              <p><strong>Recorrente:</strong> ${recurso.recorrente}</p>
              <p><strong>Decisão:</strong> <span style="font-weight: bold; color: ${result.value.decisao === 'deferido' ? '#28a745' : result.value.decisao === 'indeferido' ? '#dc3545' : '#ffc107'};">${decisaoTexto}</span></p>
              <p><strong>Responsável:</strong> ${result.value.responsavel}</p>
              <p><strong>Data da Decisão:</strong> ${this.formatDate(new Date())}</p>
              <hr>
              <p>A decisão foi registrada e constará na documentação oficial do processo.</p>
            </div>
          `,
          icon: 'success',
          confirmButtonText: '📄 Gerar Documento',
          showCancelButton: true,
          cancelButtonText: '✅ OK'
        }).then((docResult) => {
          if (docResult.isConfirmed) {
            this.gerarDocumentoRecurso(recurso, result.value)
          }
        })

      } catch (error) {
        console.error('Erro ao analisar recurso:', error)
        this.$swal({
          title: '❌ Erro ao Processar Decisão',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async gerarDocumentoRecurso(recurso, decisao) {
      try {
        // Importar jsPDF
        const { jsPDF } = await import('jspdf')
        
        const doc = new jsPDF()
        const pageWidth = doc.internal.pageSize.getWidth()
        const pageHeight = doc.internal.pageSize.getHeight()
        let yPosition = 25
        
        // Cabeçalho oficial
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 8
        
        doc.setFontSize(12)
        doc.setFont(undefined, 'normal')
        doc.text('Sistema de Pré-Qualificação de Bens - Lei 14.133/2021', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 15
        
        // Linha decorativa
        doc.setLineWidth(0.5)
        doc.line(30, yPosition, pageWidth - 30, yPosition)
        yPosition += 20
        
        // Título do documento
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('DECISÃO DE RECURSO ADMINISTRATIVO', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 20
        
        // Dados do recurso
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('I. IDENTIFICAÇÃO DO RECURSO', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const dadosRecurso = [
          ['Protocolo:', `REC-${String(recurso.id).substring(0, 8).toUpperCase()}/${new Date().getFullYear()}`],
          ['Recorrente:', recurso.recorrente],
          ['Produto/Processo:', recurso.produto_nome],
          ['Ata de Referência:', recurso.ata_referencia],
          ['Data do Recurso:', this.formatDate(recurso.data_recurso)],
          ['Prazo Final:', this.formatDate(recurso.prazo_final)]
        ]
        
        dadosRecurso.forEach(([label, valor]) => {
          doc.setFont(undefined, 'bold')
          doc.text(label, 35, yPosition)
          doc.setFont(undefined, 'normal')
          doc.text(valor, 90, yPosition)
          yPosition += 8
        })
        
        yPosition += 10
        
        // Fundamentação do recorrente
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('II. FUNDAMENTAÇÃO DO RECORRENTE', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(10)
        doc.setFont(undefined, 'normal')
        const fundamentacaoRecorrente = recurso.fundamentacao || 'Fundamentação não disponível'
        const linhasFundamentacao = doc.splitTextToSize(fundamentacaoRecorrente, pageWidth - 60)
        doc.text(linhasFundamentacao, 35, yPosition)
        yPosition += linhasFundamentacao.length * 5 + 15
        
        // Decisão da comissão
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('III. DECISÃO DA COMISSÃO', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const dadosDecisao = [
          ['Decisão:', decisao.decisao.toUpperCase()],
          ['Responsável:', decisao.responsavel],
          ['Data da Decisão:', this.formatDate(new Date())],
          ['Status:', decisao.decisao === 'deferido' ? 'DEFERIDO (Procedente)' : 
                      decisao.decisao === 'indeferido' ? 'INDEFERIDO (Improcedente)' : 'ENCAMINHADO PARA CPM']
        ]
        
        dadosDecisao.forEach(([label, valor]) => {
          doc.setFont(undefined, 'bold')
          doc.text(label, 35, yPosition)
          doc.setFont(undefined, 'normal')
          doc.text(valor, 90, yPosition)
          yPosition += 8
        })
        
        yPosition += 10
        
        // Fundamentação da decisão
        doc.setFontSize(12)
        doc.setFont(undefined, 'bold')
        doc.text('Fundamentação Legal e Técnica:', 35, yPosition)
        yPosition += 10
        
        doc.setFontSize(10)
        doc.setFont(undefined, 'normal')
        const linhasFundamentacaoDecisao = doc.splitTextToSize(decisao.fundamentacao, pageWidth - 60)
        doc.text(linhasFundamentacaoDecisao, 35, yPosition)
        yPosition += linhasFundamentacaoDecisao.length * 5 + 20
        
        // Base legal
        if (yPosition > pageHeight - 80) {
          doc.addPage()
          yPosition = 30
        }
        
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('IV. BASE LEGAL', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(10)
        doc.setFont(undefined, 'normal')
        
        const basesLegais = [
          '• Lei nº 14.133/2021 - Nova Lei de Licitações e Contratos',
          '• Art. 165 - Direito de recurso dos interessados',
          '• Art. 166 - Prazo para interposição de recurso (3 dias úteis)',
          '• Art. 167 - Processamento dos recursos administrativos',
          '• Art. 169 - Decisão dos recursos pela comissão competente'
        ]
        
        basesLegais.forEach(base => {
          doc.text(base, 35, yPosition)
          yPosition += 6
        })
        
        // Assinatura
        yPosition += 20
        doc.setFontSize(11)
        doc.setFont(undefined, 'bold')
        doc.text(`${decisao.responsavel}`, pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 6
        doc.setFont(undefined, 'normal')
        doc.text('Comissão de Contratação ou Licitação (CCL)', pageWidth / 2, yPosition, { align: 'center' })
        
        // Rodapé
        doc.setFontSize(8)
        doc.text(`Documento gerado em: ${new Date().toLocaleDateString('pt-BR')} às ${new Date().toLocaleTimeString('pt-BR')}`, 30, pageHeight - 15)
        doc.text(`Sistema Comprar Bem - Recursos Administrativos`, pageWidth - 30, pageHeight - 15, { align: 'right' })
        
        // Salvar PDF
        const nomeArquivo = `Recurso_${String(recurso.id).substring(0, 8)}_${decisao.decisao}_${new Date().toISOString().split('T')[0]}.pdf`
        doc.save(nomeArquivo)
        
        this.$swal({
          title: '📄 Documento Gerado!',
          text: `O documento PDF foi gerado com sucesso: ${nomeArquivo}`,
          icon: 'success'
        })

      } catch (error) {
        console.error('Erro ao gerar documento:', error)
        this.$swal({
          title: '❌ Erro ao Gerar Documento',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
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
              <button class="swal2-confirm swal2-styled" onclick="window.baixarDocumentacaoRecursoEspecifico('${recurso.id}')">
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
            fundamentacao: dadosRecurso.fundamentacao
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
      // Limpeza inicial de notificações antigas
      this.limparNotificacoesAntigas()
      
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
        // Limpar notificações antigas/irrelevantes antes de criar novas
        this.limparNotificacoesAntigas()
        
        await this.verificarPrazosRecursos()
        await this.verificarPrazosJulgamento()
        await this.verificarPrazosHomologacao()
        
        this.atualizarContadoresAlertas()
        
      } catch (error) {
        console.error('Erro ao verificar prazos:', error)
      }
    },
    
    limparNotificacoesAntigas() {
      const hoje = new Date()
      
      // Remover notificações de processos vencidos há mais de 30 dias
      this.notificacoes = this.notificacoes.filter(notificacao => {
        // Se é uma notificação de homologação atrasada
        if (notificacao.tipo === 'homologacao-atrasada' && notificacao.ata_id) {
          const processo = this.processosPendentesHomologacao.find(p => p.id === notificacao.ata_id)
          if (processo) {
            const dataJulgamento = new Date(processo.dataJulgamento)
            const diffTime = hoje - dataJulgamento
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
            
            // Remover se vencido há mais de 30 dias
            if (diffDays > 30) {
              return false
            }
          }
        }
        
        // Se é uma notificação de julgamento vencido
        if (notificacao.tipo === 'julgamento-vencido' && notificacao.produto_id) {
          const produto = this.produtosPendentes.find(p => p.id === notificacao.produto_id)
          if (produto) {
            const dataAnalise = new Date(produto.criado_em)
            const prazoFinal = new Date(dataAnalise)
            prazoFinal.setDate(dataAnalise.getDate() + 10)
            
            const diffTime = prazoFinal - hoje
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
            
            // Remover se vencido há mais de 30 dias
            if (diffDays < 0 && Math.abs(diffDays) > 30) {
              return false
            }
          }
        }
        
        // Se é uma notificação de recurso vencido
        if (notificacao.tipo === 'prazo-vencido' && notificacao.recurso_id) {
          const recurso = this.recursos.find(r => r.id === notificacao.recurso_id)
          if (recurso) {
            const prazoFinal = new Date(recurso.prazo_final)
            const diffTime = prazoFinal - hoje
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
            
            // Remover se vencido há mais de 30 dias
            if (diffDays < 0 && Math.abs(diffDays) > 30) {
              return false
            }
          }
        }
        
        // Manter todas as outras notificações
        return true
      })
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
          // Não exibir notificações para recursos vencidos há mais de 30 dias (sem solução possível)
          if (Math.abs(diffDays) > 30) {
            return // Pular este recurso
          }
          
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
          // Não exibir notificações para produtos vencidos há mais de 30 dias (sem solução possível)
          if (Math.abs(diffDays) > 30) {
            return // Pular este produto
          }
          
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
          
          // Não exibir notificações para processos vencidos há mais de 30 dias (sem solução possível)
          if (diffDays > 30) {
            return // Pular este processo
          }
          
          // Processo aguardando homologação há mais de 10 dias (mas menos de 30)
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
    async criarNovaAta() {
      try {
        // 1. Buscar processos julgados que ainda não foram incluídos em ata consolidada
        const { data: processosJulgados, error: errorProcessos } = await supabase
          .from('processos_administrativos')
          .select(`
            id,
            numero_processo,
            objeto,
            status,
            ata_emitida_ccl_em,
            ata_julgamento_ccl,
            recomendacao_ccl,
            fundamentacao_legal_ccl,
            consideracoes_adicionais_ccl,
            observacoes_ccl
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['ata_julgamento_ccl_homologacao', 'ata_julgamento_ccl_indeferimento', 'ata_julgamento_ccl_aprovacao', 'ata_julgamento_ccl_rejeicao'])
          .not('ata_emitida_ccl_em', 'is', null) // Só processos que foram efetivamente julgados

        if (errorProcessos) throw errorProcessos

        // 2. Verificar se há processos para incluir na ata
        if (!processosJulgados || processosJulgados.length === 0) {
          this.$swal({
            title: '⚠️ Nenhum Processo Disponível',
            text: 'Não há processos julgados disponíveis para incluir em uma nova ata. Realize julgamentos primeiro.',
            icon: 'warning'
          })
          return
        }

        // 3. Função auxiliar para truncar texto
        const truncateText = (text, maxLength = 80) => {
          if (!text) return 'Processo de pré-qualificação'
          return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
        }

        // 4. Mostrar prévia dos processos e formulário de criação da ata
        const processosList = processosJulgados.map(processo => `
          <tr style="border-bottom: 1px solid #dee2e6; transition: background 0.2s;" onmouseover="this.style.background='#f8f9fa'" onmouseout="this.style.background='white'">
            <td style="padding: 12px 8px; font-weight: bold; color: #0d6efd; vertical-align: top;">${processo.numero_processo}</td>
            <td style="padding: 12px 8px; word-wrap: break-word; line-height: 1.4; vertical-align: top;" title="${processo.objeto || 'Processo de pré-qualificação'}">${truncateText(processo.objeto, 120)}</td>
            <td style="padding: 12px 8px; text-align: center; vertical-align: top;">
              <span style="padding: 6px 12px; border-radius: 16px; font-size: 12px; font-weight: 600; color: white; background: ${processo.recomendacao_ccl === 'recomendar_homologacao' ? '#28a745' : '#dc3545'}; display: inline-block; white-space: nowrap;">
                ${processo.recomendacao_ccl === 'recomendar_homologacao' ? '✅ Homologação' : '❌ Indeferimento'}
              </span>
            </td>
            <td style="padding: 12px 8px; text-align: center; color: #6c757d; vertical-align: top; font-size: 12px;">${this.formatDate(processo.ata_emitida_ccl_em)}</td>
          </tr>
        `).join('')

        const result = await this.$swal({
          title: '📋 Criar Nova Ata de Julgamento',
          html: `
            <div style="text-align: left; padding: 15px;">
              <!-- Formulário da Ata -->
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 15px 0; color: #495057;">📄 Dados da Ata</h4>
                
                <!-- Linha 1: Período e Número lado a lado -->
                <div style="display: flex; gap: 15px; margin-bottom: 15px;">
                  <div style="flex: 1;">
                    <label style="display: block; font-weight: bold; margin-bottom: 5px;">Período de Referência:</label>
                    <input id="periodoAta" class="swal2-input" type="text" placeholder="Ex: Janeiro 2025" value="${new Date().toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' })}" style="margin: 0; width: 100%;">
                  </div>
                  <div style="flex: 1;">
                    <label style="display: block; font-weight: bold; margin-bottom: 5px;">Número da Ata:</label>
                    <input id="numeroAta" class="swal2-input" type="text" placeholder="Ex: ATA-CCL-008/2025" value="ATA-CCL-${String(Math.floor(Math.random() * 900) + 100)}/${new Date().getFullYear()}" style="margin: 0; width: 100%;">
                  </div>
                </div>
                
                <!-- Linha 2: Descrição -->
                <div style="margin-bottom: 0;">
                  <label style="display: block; font-weight: bold; margin-bottom: 5px;">Descrição:</label>
                  <textarea id="descricaoAta" class="swal2-textarea" placeholder="Descrição da ata de julgamento..." rows="3" style="margin: 0; width: 100%;">Ata de julgamento da Comissão de Contratação ou Licitação referente aos processos de pré-qualificação de bens do período.</textarea>
                </div>
              </div>

              <!-- Lista de Processos -->
              <div style="background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;">
                <h4 style="margin: 0 0 15px 0; color: #495057;">📋 Processos a serem incluídos (${processosJulgados.length})</h4>
                <div style="max-height: 300px; overflow-y: auto; border: 1px solid #e9ecef; border-radius: 4px;">
                  <table style="width: 100%; font-size: 13px; border-collapse: collapse;">
                    <thead>
                      <tr style="background: #f8f9fa; position: sticky; top: 0;">
                        <th style="padding: 12px 8px; text-align: left; border-bottom: 2px solid #dee2e6; font-weight: 600; width: 15%;">Processo</th>
                        <th style="padding: 12px 8px; text-align: left; border-bottom: 2px solid #dee2e6; font-weight: 600; width: 50%;">Descrição</th>
                        <th style="padding: 12px 8px; text-align: center; border-bottom: 2px solid #dee2e6; font-weight: 600; width: 20%;">Recomendação</th>
                        <th style="padding: 12px 8px; text-align: center; border-bottom: 2px solid #dee2e6; font-weight: 600; width: 15%;">Data Julgamento</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${processosList}
                    </tbody>
                  </table>
                </div>
              </div>

              <div style="background: #d1ecf1; padding: 10px; border-radius: 4px; margin-top: 15px;">
                <small><strong>📝 Próximos passos:</strong> Após criar a ata, ela estará disponível na aba "Atas de Julgamento" para elaboração do conteúdo e publicação oficial.</small>
              </div>
            </div>
          `,
          width: '900px',
          showCancelButton: true,
          confirmButtonText: '✅ Criar Ata com ' + processosJulgados.length + ' Processos',
          cancelButtonText: '❌ Cancelar',
          confirmButtonColor: '#28a745',
          preConfirm: () => {
            const periodo = document.getElementById('periodoAta').value.trim()
            const numero = document.getElementById('numeroAta').value.trim()
            const descricao = document.getElementById('descricaoAta').value.trim()
            
            if (!periodo || !numero) {
              this.$swal.showValidationMessage('Preencha o período e número da ata')
              return false
            }
            
            return { periodo, numero, descricao }
          }
        })

        if (!result.isConfirmed) return

        // 4. Criar a ata no banco de dados - COM STATUS CORRETO PARA ELABORAÇÃO
        const ataData = {
          tenant_id: this.currentTenantId,
          numero: result.value.numero,
          periodo: result.value.periodo,
          descricao: result.value.descricao,
          total_processos: processosJulgados.length,
          status_ata: 'ELABORACAO', // Status correto: ata vai para "Atas em Elaboração"
          data_inicio_elaboracao: new Date().toISOString(),
          responsavel_elaboracao: this.usuarioNome || 'CCL',
          progresso_elaboracao: 10, // Iniciada (10%)
          conteudo_ata: this.gerarConteudoAtaInicial(processosJulgados, result.value),
          criado_em: new Date().toISOString(),
          atualizado_em: new Date().toISOString()
        }

        const { data: novaAta, error: errorAta } = await supabase
          .from('atas_julgamento')
          .insert([ataData])
          .select()

        if (errorAta) throw errorAta

        // 5. Vincular produtos à ata criada
        const ataId = novaAta[0].id
        const { error: errorVinculo } = await supabase
          .from('produtos')
          .update({ 
            ata_julgamento_id: ataId,
            atualizado_em: new Date().toISOString()
          })
          .in('id', processosJulgados.map(p => p.id))

        if (errorVinculo) throw errorVinculo

        // 6. Recarregar dados da interface
        await this.carregarAtasJulgamento()
        await this.carregarAtasEmElaboracao()
        await this.carregarDados(true) // Recarregar contadores

        // 7. Mostrar sucesso e orientar o usuário
        this.$swal({
          title: '✅ Ata Criada com Sucesso!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4>${result.value.numero}</h4>
              <p><strong>Período:</strong> ${result.value.periodo}</p>
              <p><strong>Processos incluídos:</strong> ${processosJulgados.length}</p>
              <hr>
              <p>🔄 <strong>Status:</strong> ELABORAÇÃO</p>
              <p>A ata foi criada e está disponível na seção <strong>"📝 Atas em Elaboração"</strong> para:</p>
              <ul style="text-align: left; margin: 10px 0; padding-left: 30px;">
                <li>Revisar conteúdo</li>
                <li>Ajustar fundamentações</li>
                <li>Finalizar para publicação</li>
              </ul>
            </div>
          `,
          icon: 'success',
          confirmButtonText: '📝 Ver Atas em Elaboração',
          showCancelButton: true,
          cancelButtonText: '✅ OK'
        }).then((result) => {
          if (result.isConfirmed) {
            // Ir para a aba de atas
            this.activeTab = 'atas'
          }
        })

      } catch (error) {
        console.error('Erro ao criar nova ata:', error)
        this.$swal({
          title: '❌ Erro ao Criar Ata',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },

    async criarAtaAutomatica(processo, julgamento) {
      try {
        console.log('🏗️ Criando ata automática para processo aprovado:', processo.numero_processo)
        
        // Gerar número da ata baseado na data
        const agora = new Date()
        const ano = agora.getFullYear()
        const mes = String(agora.getMonth() + 1).padStart(2, '0')
        const dia = String(agora.getDate()).padStart(2, '0')
        const numeroAta = `ATA-CCL-${ano}${mes}${dia}-${String(processo.id).slice(-4)}`
        
        // Criar registro na tabela atas_julgamento
        const { data: novaAta, error } = await supabase
          .from('atas_julgamento')
          .insert({
            tenant_id: this.currentTenantId,
            numero: numeroAta,
            data_inicio: agora.toISOString(),
            data_publicacao: agora.toISOString(),
            periodo: `${mes}/${ano}`,
            total_processos: 1,
            status_ata: 'EM_ELABORACAO',
            conteudo_ata: `Ata de Julgamento CCL referente ao processo ${processo.numero_processo}\n\nDECISÃO: APROVADO\n\nFUNDAMENTAÇÃO: ${julgamento.fundamentacao}`,
            observacoes: `Ata criada automaticamente após julgamento CCL do processo ${processo.numero_processo}`,
            criado_em: agora.toISOString()
          })
          .select()
          .single()
        
        if (error) {
          console.error('Erro ao criar ata automática:', error)
          return
        }
        
        console.log('✅ Ata automática criada:', numeroAta)
        
        // Atualizar listas locais para mostrar a nova ata
        await this.carregarAtasEmElaboracao()
        await this.carregarAtasJulgamento()
        
      } catch (error) {
        console.error('Erro ao criar ata automática:', error)
      }
    },

    async editarAta(ata) {
      try {
        // Buscar produtos vinculados à ata
        const { data: produtos, error } = await supabase
          .from('produtos')
          .select(`
            id,
            nome,
            marca,
            modelo,
            fabricante,
            status,
            julgado_em,
            adequacao_tecnica,
            observacoes_ccl,
            base_legal
          `)
          .eq('ata_julgamento_id', ata.id)
          .eq('tenant_id', this.currentTenantId)
          .order('nome')
        
        if (error) throw error
        
        const produtosAprovados = produtos?.filter(p => p.status === 'julgado_aprovado') || []
        const produtosReprovados = produtos?.filter(p => p.status === 'julgado_reprovado') || []
        
        const result = await this.$swal({
          title: '✏️ Editor de Ata de Julgamento',
          html: `
            <div style="text-align: left; padding: 15px; max-height: 600px; overflow-y: auto;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 15px 0; color: #495057;">📋 Informações da Ata</h4>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                  <div>
                    <label style="display: block; font-weight: bold; margin-bottom: 5px;">Número da Ata:</label>
                    <input id="numeroAta" class="swal2-input" type="text" value="${ata.numero}" style="margin: 0;">
                  </div>
                  <div>
                    <label style="display: block; font-weight: bold; margin-bottom: 5px;">Período:</label>
                    <input id="periodoAta" class="swal2-input" type="text" value="${ata.periodo}" style="margin: 0;">
                  </div>
                </div>
                <div style="margin-top: 15px;">
                  <label style="display: block; font-weight: bold; margin-bottom: 5px;">Descrição:</label>
                  <textarea id="descricaoAta" class="swal2-textarea" rows="2" style="margin: 0; width: 100%; max-width: 100%; resize: vertical;">${ata.descricao || ''}</textarea>
                </div>
              </div>
              
              <div style="background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin-bottom: 15px;">
                <h4 style="margin: 0 0 15px 0; color: #495057;">📝 Conteúdo da Ata</h4>
                <textarea id="conteudoAta" class="swal2-textarea" rows="12" placeholder="Digite ou edite o conteúdo completo da ata..." style="margin: 0; font-family: 'Courier New', monospace; font-size: 12px; width: 100%; max-width: 100%; resize: vertical;">${ata.conteudoAta || ''}</textarea>
                <small style="color: #666; margin-top: 5px; display: block;">💡 Use este campo para redigir o conteúdo oficial da ata que será publicado</small>
              </div>
              
              <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                <h5 style="color: #2d5a2d; margin: 0 0 10px 0;">✅ Produtos Aprovados (${produtosAprovados.length})</h5>
                ${produtosAprovados.length > 0 ? 
                  produtosAprovados.map(p => `
                    <div style="border-bottom: 1px solid #c8e6c8; padding: 5px 0; font-size: 12px;">
                      <strong>${p.nome}</strong> - ${p.marca} (${p.modelo})
                    </div>
                  `).join('') : 
                  '<p style="color: #666; font-style: italic;">Nenhum produto aprovado</p>'
                }
              </div>
              
              <div style="background: #fce8e8; padding: 15px; border-radius: 8px;">
                <h5 style="color: #5a2d2d; margin: 0 0 10px 0;">❌ Produtos Reprovados (${produtosReprovados.length})</h5>
                ${produtosReprovados.length > 0 ? 
                  produtosReprovados.map(p => `
                    <div style="border-bottom: 1px solid #f5c6c6; padding: 5px 0; font-size: 12px;">
                      <strong>${p.nome}</strong> - ${p.marca} (${p.modelo})
                    </div>
                  `).join('') : 
                  '<p style="color: #666; font-style: italic;">Nenhum produto reprovado</p>'
                }
              </div>
            </div>
          `,
          width: '1100px',
          showCancelButton: true,
          confirmButtonText: '💾 Salvar Alterações',
          cancelButtonText: '❌ Cancelar',
          confirmButtonColor: '#28a745',
          preConfirm: () => {
            const numero = document.getElementById('numeroAta').value.trim()
            const periodo = document.getElementById('periodoAta').value.trim()
            const descricao = document.getElementById('descricaoAta').value.trim()
            const conteudo = document.getElementById('conteudoAta').value.trim()
            
            if (!numero || !periodo) {
              this.$swal.showValidationMessage('Número da ata e período são obrigatórios')
              return false
            }
            
            return { numero, periodo, descricao, conteudo }
          }
        })
        
        if (!result.isConfirmed) return
        
        // Atualizar a ata no banco de dados
        const { error: updateError } = await supabase
          .from('atas_julgamento')
          .update({
            numero: result.value.numero,
            periodo: result.value.periodo,
            descricao: result.value.descricao,
            conteudo_ata: result.value.conteudo,
            progresso_elaboracao: result.value.conteudo ? 50 : 10, // Atualizar progresso baseado no conteúdo
            atualizado_em: new Date().toISOString()
          })
          .eq('id', ata.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (updateError) throw updateError
        
        // Recarregar dados
        await this.carregarAtasEmElaboracao()
        
        this.$swal({
          title: '✅ Ata Atualizada!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4>📋 ${result.value.numero}</h4>
              <p><strong>Período:</strong> ${result.value.periodo}</p>
              <p>✏️ <strong>Status:</strong> Alterações salvas com sucesso</p>
              <hr>
              <p>A ata continua em elaboração e pode ser editada até a publicação oficial.</p>
              <div style="background: #d4edda; padding: 10px; border-radius: 4px; margin-top: 15px;">
                <small><strong>📝 Próximos passos:</strong> Continue editando ou clique em "Finalizar" quando estiver pronta para publicação.</small>
              </div>
            </div>
          `,
          icon: 'success'
        })
        
      } catch (error) {
        console.error('Erro ao editar ata:', error)
        this.$swal({
          title: '❌ Erro ao Editar Ata',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    async finalizarAta(ata) {
      const result = await this.$swal({
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
      })
      
      if (!result.isConfirmed) return
      
      try {
        // Atualizar status da ata para publicada
        const dataPublicacao = new Date()
        const dataFimPrazoRecursal = this.adicionarDiasUteis(dataPublicacao, 3) // 3 dias úteis
        
        const { error } = await supabase
          .from('atas_julgamento')
          .update({
            status_ata: 'EM PRAZO', // Status para ata publicada em prazo recursal
            data_publicacao: dataPublicacao.toISOString(),
            data_inicio_prazo_recursal: dataPublicacao.toISOString(),
            data_fim_prazo_recursal: dataFimPrazoRecursal.toISOString(),
            progresso_elaboracao: 100, // 100% completa
            atualizado_em: new Date().toISOString()
          })
          .eq('id', ata.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (error) throw error
        
        // Recarregar dados
        await this.carregarAtasJulgamento()
        await this.carregarAtasEmElaboracao()
        await this.carregarDados()
        
        this.$swal({
          title: '🎉 Ata Finalizada e Publicada!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4>${ata.numero}</h4>
              <p>✅ Status atualizado para: <strong>EM PRAZO RECURSAL</strong></p>
              <p>📅 Publicada em: <strong>${dataPublicacao.toLocaleDateString('pt-BR')}</strong></p>
              <p>⏰ Prazo recursal até: <strong>${dataFimPrazoRecursal.toLocaleDateString('pt-BR')}</strong></p>
              <hr>
              <p>A ata agora está disponível na seção <strong>"📋 Atas Publicadas Recentemente"</strong></p>
            </div>
          `,
          icon: 'success'
        })
        
      } catch (error) {
        console.error('Erro ao finalizar ata:', error)
        this.$swal({
          title: '❌ Erro ao Finalizar',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
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
    async baixarPDF(ata) {
      try {
        // Importar jsPDF
        const { jsPDF } = await import('jspdf')
        
        // Buscar produtos vinculados à ata
        const { data: produtos, error } = await supabase
          .from('produtos')
          .select(`
            id,
            nome,
            marca,
            modelo,
            fabricante,
            status,
            julgado_em,
            adequacao_tecnica,
            observacoes_ccl,
            base_legal
          `)
          .eq('ata_julgamento_id', ata.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (error) throw error
        
        // Criar PDF com layout profissional
        const doc = new jsPDF()
        const pageWidth = doc.internal.pageSize.getWidth()
        const pageHeight = doc.internal.pageSize.getHeight()
        let yPosition = 25
        
        // ====================== CABEÇALHO OFICIAL ======================
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 8
        
        doc.setFontSize(12)
        doc.setFont(undefined, 'normal')
        doc.text('Sistema de Pré-Qualificação de Bens - Lei 14.133/2021', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 15
        
        // Linha decorativa
        doc.setLineWidth(0.5)
        doc.line(30, yPosition, pageWidth - 30, yPosition)
        yPosition += 20
        
        // ====================== TÍTULO DA ATA ======================
        doc.setFontSize(18)
        doc.setFont(undefined, 'bold')
        doc.text('ATA DE JULGAMENTO', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 15
        
        // ====================== DADOS DA ATA ======================
        doc.setFontSize(12)
        doc.setFont(undefined, 'normal')
        doc.text(`Número: ${ata.numero || 'Não informado'}`, 30, yPosition)
        yPosition += 8
        doc.text(`Período: ${ata.periodo || 'Não informado'}`, 30, yPosition)
        yPosition += 8
        doc.text(`Data de Publicação: ${this.formatDate(ata.dataPublicacao || ata.data_publicacao)}`, 30, yPosition)
        yPosition += 8
        doc.text(`Status: ${ata.statusRecursal || ata.status_recursal || ata.status_ata || 'Não informado'}`, 30, yPosition)
        yPosition += 20
        
        // ====================== PRODUTOS JULGADOS ======================
        const produtosAprovados = produtos?.filter(p => p.status === 'julgado_aprovado') || []
        const produtosReprovados = produtos?.filter(p => p.status === 'julgado_reprovado') || []
        
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('RESUMO DOS JULGAMENTOS', 30, yPosition)
        yPosition += 15
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        doc.text(`Total de processos julgados: ${produtos?.length || 0}`, 35, yPosition)
        yPosition += 8
        doc.text(`Produtos aprovados: ${produtosAprovados.length}`, 35, yPosition)
        yPosition += 8
        doc.text(`Produtos reprovados: ${produtosReprovados.length}`, 35, yPosition)
        yPosition += 20
        
        // ====================== PRODUTOS APROVADOS ======================
        if (produtosAprovados.length > 0) {
          doc.setFontSize(14)
          doc.setFont(undefined, 'bold')
          doc.text('PRODUTOS APROVADOS', 30, yPosition)
          yPosition += 12
          
          produtosAprovados.forEach((produto, index) => {
            if (yPosition > pageHeight - 40) {
              doc.addPage()
              yPosition = 30
            }
            
            doc.setFontSize(11)
            doc.setFont(undefined, 'bold')
            doc.text(`${index + 1}. ${produto.nome || 'Nome não informado'}`, 35, yPosition)
            yPosition += 6
            
            doc.setFont(undefined, 'normal')
            doc.text(`Marca: ${produto.marca || 'Não informada'} | Modelo: ${produto.modelo || 'Não informado'}`, 40, yPosition)
            yPosition += 6
            doc.text(`Fabricante: ${produto.fabricante || 'Não informado'}`, 40, yPosition)
            yPosition += 6
            doc.text(`Julgado em: ${this.formatDate(produto.julgado_em) || 'Data não informada'}`, 40, yPosition)
            yPosition += 6
            
            if (produto.adequacao_tecnica) {
              doc.text(`Adequação Técnica: ${produto.adequacao_tecnica}`, 40, yPosition)
              yPosition += 6
            }
            
            yPosition += 5
          })
          
          yPosition += 10
        }
        
        // ====================== PRODUTOS REPROVADOS ======================
        if (produtosReprovados.length > 0) {
          if (yPosition > pageHeight - 60) {
            doc.addPage()
            yPosition = 30
          }
          
          doc.setFontSize(14)
          doc.setFont(undefined, 'bold')
          doc.text('PRODUTOS REPROVADOS', 30, yPosition)
          yPosition += 12
          
          produtosReprovados.forEach((produto, index) => {
            if (yPosition > pageHeight - 40) {
              doc.addPage()
              yPosition = 30
            }
            
            doc.setFontSize(11)
            doc.setFont(undefined, 'bold')
            doc.text(`${index + 1}. ${produto.nome || 'Nome não informado'}`, 35, yPosition)
            yPosition += 6
            
            doc.setFont(undefined, 'normal')
            doc.text(`Marca: ${produto.marca || 'Não informada'} | Modelo: ${produto.modelo || 'Não informado'}`, 40, yPosition)
            yPosition += 6
            doc.text(`Fabricante: ${produto.fabricante || 'Não informado'}`, 40, yPosition)
            yPosition += 6
            doc.text(`Julgado em: ${this.formatDate(produto.julgado_em) || 'Data não informada'}`, 40, yPosition)
            yPosition += 6
            
            if (produto.observacoes_ccl) {
              doc.setFont(undefined, 'italic')
              doc.text(`Motivo: ${produto.observacoes_ccl}`, 40, yPosition)
              yPosition += 6
            }
            
            yPosition += 5
          })
        }
        
        // ====================== CONTEÚDO DA ATA ======================
        if (ata.conteudoAta || ata.conteudo_ata) {
          if (yPosition > pageHeight - 80) {
            doc.addPage()
            yPosition = 30
          }
          
          doc.setFontSize(14)
          doc.setFont(undefined, 'bold')
          doc.text('CONTEÚDO COMPLETO DA ATA', 30, yPosition)
          yPosition += 12
          
          doc.setFontSize(10)
          doc.setFont(undefined, 'normal')
          const conteudoLines = doc.splitTextToSize(ata.conteudoAta || ata.conteudo_ata, pageWidth - 70)
          doc.text(conteudoLines, 35, yPosition)
        }
        
        // ====================== RODAPÉ ======================
        const totalPages = doc.internal.getNumberOfPages()
        
        for (let i = 1; i <= totalPages; i++) {
          doc.setPage(i)
          
          // Linha no rodapé
          doc.setLineWidth(0.3)
          doc.line(30, pageHeight - 25, pageWidth - 30, pageHeight - 25)
          
          // Textos do rodapé
          doc.setFontSize(8)
          doc.setFont(undefined, 'normal')
          doc.text('Sistema Comprar Bem - Atas de Julgamento CCL', 30, pageHeight - 18)
          doc.text(`Página ${i} de ${totalPages}`, pageWidth / 2, pageHeight - 18, { align: 'center' })
          doc.text('Lei 14.133/2021', pageWidth - 30, pageHeight - 18, { align: 'right' })
          
          doc.text(`Gerado em: ${new Date().toLocaleDateString('pt-BR')} às ${new Date().toLocaleTimeString('pt-BR')}`, 30, pageHeight - 12)
        }
        
        // Salvar PDF
        const nomeArquivo = `ATA_${(ata.numero || 'SemNumero').replace(/[^a-zA-Z0-9]/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`
        doc.save(nomeArquivo)
        
        this.$swal({
          title: '✅ PDF Gerado!',
          html: `
            <div style="text-align: center; padding: 15px;">
              <h4>📋 ${ata.numero || 'Ata sem número'}</h4>
              <p><strong>Arquivo:</strong> ${nomeArquivo}</p>
              <p>PDF da ata de julgamento gerado com sucesso!</p>
              <p><strong>📊 Conteúdo:</strong></p>
              <ul style="text-align: left; margin: 10px 0; padding-left: 30px;">
                <li>${produtosAprovados.length} produto(s) aprovado(s)</li>
                <li>${produtosReprovados.length} produto(s) reprovado(s)</li>
                <li>Informações detalhadas de cada julgamento</li>
                <li>Base legal e fundamentações</li>
              </ul>
            </div>
          `,
          icon: 'success'
        })
        
      } catch (error) {
        console.error('Erro ao gerar PDF da ata:', error)
        this.$swal({
          title: '❌ Erro ao Gerar PDF',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    async gerenciarRecursos(ata) {
      try {
        // Buscar recursos relacionados à ata
        const { data: recursos, error } = await supabase
          .from('recursos')
          .select('*')
          .eq('ata_referencia', ata.numero)
          .eq('tenant_id', this.currentTenantId)
          .order('data_recurso', { ascending: false })
        
        if (error) {
          console.warn('Erro ao carregar recursos (talvez tabela não exista):', error)
          // Continuar com array vazio se tabela não existir
        }
        
        const recursosAtivos = recursos || []
        const prazoRecursal = this.formatDate(ata.dataFimPrazoRecursal)
        const isPrazoVencido = ata.dataFimPrazoRecursal && new Date(ata.dataFimPrazoRecursal) < new Date()
        
        this.$swal({
          title: '📄 Gerenciar Recursos Administrativos',
          html: `
            <div style="text-align: left; padding: 15px; max-height: 500px; overflow-y: auto;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 10px 0; color: #495057;">📋 Informações da Ata</h4>
                <p><strong>Número:</strong> ${ata.numero}</p>
                <p><strong>Data Publicação:</strong> ${this.formatDate(ata.dataPublicacao)}</p>
                <p><strong>Status Recursal:</strong> ${ata.statusRecursal}</p>
                <p><strong>Prazo para Recursos:</strong> ${prazoRecursal || 'Não definido'}</p>
                ${isPrazoVencido ? 
                  '<p style="color: #dc3545; font-weight: bold;">⚠️ Prazo recursal VENCIDO</p>' : 
                  '<p style="color: #28a745; font-weight: bold;">✅ Prazo recursal ATIVO</p>'
                }
              </div>
              
              <div style="background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin-bottom: 15px;">
                <h4 style="margin: 0 0 15px 0; color: #495057;">📄 Recursos Protocolados (${recursosAtivos.length})</h4>
                ${recursosAtivos.length > 0 ? 
                  recursosAtivos.map(recurso => `
                    <div style="border-bottom: 1px solid #eee; padding: 10px 0;">
                      <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                          <strong>${recurso.recorrente || 'Recorrente não informado'}</strong>
                          <p style="margin: 5px 0; color: #666;">Produto: ${recurso.produto_nome || 'Não especificado'}</p>
                          <small>Protocolado em: ${this.formatDate(recurso.data_recurso)}</small>
                        </div>
                        <span class="status-badge ${this.getRecursoStatusClass(recurso.status)}">
                          ${recurso.status || 'EM ANÁLISE'}
                        </span>
                      </div>
                    </div>
                  `).join('') : 
                  '<div style="text-align: center; color: #666; padding: 20px;"><p><em>Nenhum recurso protocolado ainda.</em></p></div>'
                }
              </div>
              
              ${!isPrazoVencido ? `
                <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
                  <h5 style="color: #1976d2; margin: 0 0 10px 0;">⚡ Ações Disponíveis</h5>
                  <button id="novoRecurso" class="swal2-confirm swal2-styled" style="margin: 5px;">
                    ➕ Protocolar Novo Recurso
                  </button>
                  <button id="analisarRecursos" class="swal2-confirm swal2-styled" style="margin: 5px; background: #4caf50;">
                    🔍 Analisar Recursos Existentes
                  </button>
                </div>
              ` : ''}
              
              <div style="background: #fff3cd; padding: 10px; border-radius: 4px;">
                <small><strong>📚 Base Legal:</strong> Art. 165-171 da Lei 14.133/2021 - Recursos administrativos em processos licitatórios</small>
              </div>
            </div>
          `,
          width: '700px',
          showCancelButton: true,
          confirmButtonText: '📥 Gerar Relatório PDF',
          cancelButtonText: '❌ Fechar',
          didOpen: () => {
            // Adicionar event listeners para os botões
            const novoRecursoBtn = document.getElementById('novoRecurso')
            const analisarRecursosBtn = document.getElementById('analisarRecursos')
            
            if (novoRecursoBtn) {
              novoRecursoBtn.onclick = () => {
                this.$swal.close()
                this.novoRecurso(ata)
              }
            }
            
            if (analisarRecursosBtn) {
              analisarRecursosBtn.onclick = () => {
                this.$swal.close()
                this.analisarRecursos(ata, recursosAtivos)
              }
            }
          }
        })
        
      } catch (error) {
        console.error('Erro ao gerenciar recursos:', error)
        this.$swal({
          title: '❌ Erro ao Carregar Recursos',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async novoRecurso(ata) {
      try {
        const result = await this.$swal({
          title: '➕ Protocolar Novo Recurso',
          html: `
            <div style="text-align: left; padding: 15px;">
              <p><strong>Ata:</strong> ${ata.numero}</p>
              <hr>
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Nome do Recorrente:</label>
                <input id="recorrente" class="swal2-input" type="text" placeholder="Nome da empresa/pessoa">
              </div>
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Documento (CNPJ/CPF) - <em>Opcional</em>:</label>
                <input id="documento" class="swal2-input" type="text" placeholder="CNPJ ou CPF do recorrente (opcional)">
              </div>
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Produto/Processo:</label>
                <input id="produtoNome" class="swal2-input" type="text" placeholder="Nome do produto contestado">
              </div>
              <div style="margin-bottom: 15px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Fundamentação do Recurso:</label>
                <textarea id="fundamentacao" class="swal2-textarea" rows="4" placeholder="Descreva os motivos e fundamentos legais do recurso..."></textarea>
              </div>
              <div style="background: #f8f9fa; padding: 10px; border-radius: 4px;">
                <small><strong>⚠️ Prazo:</strong> Recursos devem ser protocolados em até 3 dias úteis após a publicação da ata.</small>
              </div>
            </div>
          `,
          showCancelButton: true,
          confirmButtonText: '✅ Protocolar Recurso',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const recorrente = document.getElementById('recorrente').value.trim()
            const documento = document.getElementById('documento').value.trim()
            const produtoNome = document.getElementById('produtoNome').value.trim()
            const fundamentacao = document.getElementById('fundamentacao').value.trim()
            
            if (!recorrente || !produtoNome || !fundamentacao) {
              this.$swal.showValidationMessage('Preencha todos os campos obrigatórios')
              return false
            }
            
            return { recorrente, documento, produtoNome, fundamentacao }
          }
        })

        if (!result.isConfirmed) return

        // Calcular prazo final (3 dias úteis a partir de hoje)
        const dataRecurso = new Date()
        const prazoFinal = this.adicionarDiasUteis(dataRecurso, 3)

        // Salvar recurso no banco de dados
        const recursoData = {
          tenant_id: this.currentTenantId,
          ata_referencia: ata.numero,
          produto_nome: result.value.produtoNome,
          recorrente: result.value.recorrente,
          documento_recorrente: result.value.documento,
          data_recurso: dataRecurso.toISOString(),
          prazo_final: prazoFinal.toISOString(),
          fundamentacao: result.value.fundamentacao,
          status: 'EM ANÁLISE'
        }

        const { data: novoRecurso, error } = await supabase
          .from('recursos')
          .insert([recursoData])
          .select()

        if (error) {
          console.error('Erro ao inserir recurso:', error)
          
          // Se for erro de tabela não existir, tentar criar automaticamente ou dar instruções
          if (error.message.includes('relation "recursos" does not exist') || 
              error.code === '42P01' || 
              error.message.includes('recursos')) {
            this.$swal({
              title: '⚠️ Tabela de Recursos Não Encontrada',
              html: `
                <div style="text-align: left; padding: 15px;">
                  <p>A tabela de recursos ainda não foi criada no banco de dados.</p>
                  <p><strong>Ação necessária:</strong></p>
                  <ol>
                    <li>Execute o script SQL: <code>criar_tabela_recursos.sql</code></li>
                    <li>Depois tente protocolar o recurso novamente</li>
                  </ol>
                  <hr>
                  <p><strong>Erro técnico:</strong> ${error.message}</p>
                  <p><strong>Dados do recurso (temporário):</strong></p>
                  <p><strong>Recorrente:</strong> ${result.value.recorrente}</p>
                  <p><strong>Produto:</strong> ${result.value.produtoNome}</p>
                  <p><strong>Status:</strong> Aguardando criação da tabela</p>
                </div>
              `,
              icon: 'warning'
            })
          } else {
            // Outros erros
            this.$swal({
              title: '❌ Erro ao Protocolar Recurso',
              text: `Erro: ${error.message}`,
              icon: 'error'
            })
          }
          return
        }

        // Recarregar dados
        await this.carregarRecursos()
        await this.carregarDados()

        // Sucesso
        const protocoloNumero = `REC-${String(novoRecurso[0].id).substring(0, 8).toUpperCase()}/${new Date().getFullYear()}`
        
        this.$swal({
          title: '✅ Recurso Protocolado com Sucesso!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4>📄 Protocolo: ${protocoloNumero}</h4>
              <p><strong>Recorrente:</strong> ${result.value.recorrente}</p>
              <p><strong>Produto:</strong> ${result.value.produtoNome}</p>
              <p><strong>Status:</strong> EM ANÁLISE</p>
              <p><strong>Prazo para Decisão:</strong> ${this.formatDate(prazoFinal)}</p>
              <hr>
              <p>O recurso foi protocolado e será analisado pela Comissão dentro do prazo legal.</p>
            </div>
          `,
          icon: 'success',
          confirmButtonText: '📋 Ver Recursos',
          showCancelButton: true,
          cancelButtonText: '✅ OK'
        }).then((showResult) => {
          if (showResult.isConfirmed) {
            // Ir para a seção de recursos (que fica na aba principal)
            this.activeTab = 'dashboard'
          }
        })

      } catch (error) {
        console.error('Erro ao criar recurso:', error)
        this.$swal({
          title: '❌ Erro ao Protocolar Recurso',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async analisarRecursos(ata, recursos) {
      try {
        // Se não há recursos na variável, buscar do banco
        let recursosParaAnalise = recursos
        if (!recursosParaAnalise || recursosParaAnalise.length === 0) {
          const { data: recursosDB, error } = await supabase
            .from('recursos')
            .select('*')
            .eq('ata_referencia', ata.numero)
            .eq('tenant_id', this.currentTenantId)
            .order('data_recurso', { ascending: false })
          
          if (!error && recursosDB) {
            recursosParaAnalise = recursosDB
          }
        }

        if (!recursosParaAnalise || recursosParaAnalise.length === 0) {
          this.$swal({
            title: '📄 Nenhum Recurso Encontrado',
            text: `Não há recursos protocolados para a ata ${ata.numero}.`,
            icon: 'info'
          })
          return
        }

        // Montar interface de análise
        const recursosHTML = recursosParaAnalise.map(recurso => {
          const prazoVencido = new Date(recurso.prazo_final) < new Date()
          const statusColor = recurso.status === 'EM ANÁLISE' ? '#ffc107' : 
                             recurso.status === 'DEFERIDO' ? '#28a745' : 
                             recurso.status === 'INDEFERIDO' ? '#dc3545' : '#6c757d'
          
          return `
            <div style="border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin-bottom: 15px; background: #fff;">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                <h6 style="margin: 0; color: #495057;">📄 ${recurso.produto_nome}</h6>
                <span style="background: ${statusColor}; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold;">
                  ${recurso.status}
                </span>
              </div>
              <p style="margin: 5px 0;"><strong>Recorrente:</strong> ${recurso.recorrente}</p>
              <p style="margin: 5px 0;"><strong>Data do Recurso:</strong> ${this.formatDate(recurso.data_recurso)}</p>
              <p style="margin: 5px 0;"><strong>Prazo Final:</strong> ${this.formatDate(recurso.prazo_final)} 
                ${prazoVencido ? '<span style="color: #dc3545; font-weight: bold;">(VENCIDO)</span>' : '<span style="color: #28a745; font-weight: bold;">(EM PRAZO)</span>'}
              </p>
              
              <div style="background: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;">
                <strong>Fundamentação:</strong><br>
                <small>${recurso.fundamentacao || 'Não informada'}</small>
              </div>
              
              ${recurso.status === 'EM ANÁLISE' ? `
                <button onclick="analisarRecursoEspecifico('${recurso.id}')" 
                        style="background: #007bff; color: white; border: none; padding: 8px 15px; border-radius: 4px; cursor: pointer; margin-top: 10px;">
                  📋 Analisar Este Recurso
                </button>
              ` : recurso.decisao ? `
                <div style="background: #e9ecef; padding: 10px; border-radius: 4px; margin-top: 10px; font-size: 14px;">
                  <strong>Decisão:</strong> ${recurso.decisao.toUpperCase()}<br>
                  <strong>Responsável:</strong> ${recurso.responsavel_decisao || 'Não informado'}<br>
                  <strong>Data:</strong> ${this.formatDate(recurso.data_decisao)}
                </div>
              ` : ''}
            </div>
          `
        }).join('')

        this.$swal({
          title: '🔍 Análise de Recursos Administrativos',
          html: `
            <div style="text-align: left; padding: 15px; max-height: 600px; overflow-y: auto;">
              <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h5 style="margin: 0 0 10px 0; color: #495057;">📋 Informações da Ata</h5>
                <p><strong>Número:</strong> ${ata.numero}</p>
                <p><strong>Total de Recursos:</strong> ${recursosParaAnalise.length}</p>
                <p><strong>Em Análise:</strong> ${recursosParaAnalise.filter(r => r.status === 'EM ANÁLISE').length}</p>
                <p><strong>Julgados:</strong> ${recursosParaAnalise.filter(r => r.status !== 'EM ANÁLISE').length}</p>
              </div>
              
              <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h6 style="color: #1976d2; margin: 0 0 10px 0;">⚖️ Processo de Análise</h6>
                <ol style="margin: 0; padding-left: 20px; font-size: 14px;">
                  <li>Verificação da tempestividade (3 dias úteis)</li>
                  <li>Análise da fundamentação legal</li>
                  <li>Avaliação técnica do mérito</li>
                  <li>Análise técnica e recomendação motivada à Autoridade Competente</li>
                  <li>Comunicação às partes interessadas</li>
                </ol>
              </div>
              
              <h6 style="color: #495057; margin-bottom: 15px;">📄 Recursos Protocolados:</h6>
              ${recursosHTML}
            </div>
          `,
          width: '900px',
          confirmButtonText: '📊 Gerar Relatório Geral',
          showCancelButton: true,
          cancelButtonText: '❌ Fechar',
          didOpen: () => {
            // Adicionar funcionalidade aos botões
            window.analisarRecursoEspecifico = (recursoId) => {
              this.$swal.close()
              const recurso = recursosParaAnalise.find(r => r.id === recursoId)
              if (recurso) {
                this.analisarRecurso(recurso)
              }
            }
          }
        }).then((result) => {
          if (result.isConfirmed) {
            this.gerarRelatorioRecursos(ata, recursosParaAnalise)
          }
        })

      } catch (error) {
        console.error('Erro ao analisar recursos:', error)
        this.$swal({
          title: '❌ Erro ao Carregar Recursos',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async gerarRelatorioRecursos(ata, recursos) {
      try {
        // Importar jsPDF
        const { jsPDF } = await import('jspdf')
        
        const doc = new jsPDF()
        const pageWidth = doc.internal.pageSize.getWidth()
        const pageHeight = doc.internal.pageSize.getHeight()
        let yPosition = 25
        
        // Cabeçalho oficial
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 8
        
        doc.setFontSize(12)
        doc.setFont(undefined, 'normal')
        doc.text('Sistema de Pré-Qualificação de Bens - Lei 14.133/2021', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 15
        
        // Linha decorativa
        doc.setLineWidth(0.5)
        doc.line(30, yPosition, pageWidth - 30, yPosition)
        yPosition += 20
        
        // Título do documento
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('RELATÓRIO GERAL DE RECURSOS ADMINISTRATIVOS', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 20
        
        // Informações da ata
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('I. INFORMAÇÕES DA ATA', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const dadosAta = [
          ['Número da Ata:', ata.numero],
          ['Total de Recursos:', recursos.length.toString()],
          ['Em Análise:', recursos.filter(r => r.status === 'EM ANÁLISE').length.toString()],
          ['Deferidos:', recursos.filter(r => r.status === 'DEFERIDO').length.toString()],
          ['Indeferidos:', recursos.filter(r => r.status === 'INDEFERIDO').length.toString()],
          ['Data do Relatório:', this.formatDate(new Date())]
        ]
        
        dadosAta.forEach(([label, valor]) => {
          doc.setFont(undefined, 'bold')
          doc.text(label, 35, yPosition)
          doc.setFont(undefined, 'normal')
          doc.text(valor, 100, yPosition)
          yPosition += 8
        })
        
        yPosition += 15
        
        // Recursos detalhados
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('II. RECURSOS PROTOCOLADOS', 30, yPosition)
        yPosition += 12
        
        recursos.forEach((recurso, index) => {
          if (yPosition > pageHeight - 60) {
            doc.addPage()
            yPosition = 30
          }
          
          doc.setFontSize(12)
          doc.setFont(undefined, 'bold')
          doc.text(`${index + 1}. ${recurso.produto_nome}`, 35, yPosition)
          yPosition += 10
          
          doc.setFontSize(10)
          doc.setFont(undefined, 'normal')
          
          const dadosRecurso = [
            `Recorrente: ${recurso.recorrente}`,
            `Data do Recurso: ${this.formatDate(recurso.data_recurso)}`,
            `Prazo Final: ${this.formatDate(recurso.prazo_final)}`,
            `Status: ${recurso.status}`,
          ]
          
          if (recurso.decisao) {
            dadosRecurso.push(`Decisão: ${recurso.decisao.toUpperCase()}`)
            dadosRecurso.push(`Responsável: ${recurso.responsavel_decisao || 'Não informado'}`)
            dadosRecurso.push(`Data da Decisão: ${this.formatDate(recurso.data_decisao)}`)
          }
          
          dadosRecurso.forEach(linha => {
            doc.text(linha, 40, yPosition)
            yPosition += 6
          })
          
          if (recurso.fundamentacao) {
            doc.text('Fundamentação:', 40, yPosition)
            yPosition += 6
            const linhasFundamentacao = doc.splitTextToSize(recurso.fundamentacao, pageWidth - 80)
            doc.text(linhasFundamentacao, 45, yPosition)
            yPosition += linhasFundamentacao.length * 5
          }
          
          yPosition += 10
        })
        
        // Rodapé
        doc.setFontSize(8)
        doc.text(`Relatório gerado em: ${new Date().toLocaleDateString('pt-BR')} às ${new Date().toLocaleTimeString('pt-BR')}`, 30, pageHeight - 15)
        doc.text(`Sistema Comprar Bem - Recursos Administrativos`, pageWidth - 30, pageHeight - 15, { align: 'right' })
        
        // Salvar PDF
        const nomeArquivo = `Relatorio_Recursos_${(ata.numero || 'SemNumero').replace(/[^a-zA-Z0-9]/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`
        doc.save(nomeArquivo)
        
        this.$swal({
          title: '📄 Relatório Gerado!',
          text: `O relatório PDF foi gerado com sucesso: ${nomeArquivo}`,
          icon: 'success'
        })

      } catch (error) {
        console.error('Erro ao gerar relatório:', error)
        this.$swal({
          title: '❌ Erro ao Gerar Relatório',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
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
    },
    // Função auxiliar para gerar conteúdo inicial da ata
    gerarConteudoAtaInicial(produtos, dadosAta) {
      const produtosAprovados = produtos.filter(p => p.status === 'julgado_aprovado')
      const produtosReprovados = produtos.filter(p => p.status === 'julgado_reprovado')
      
      return `
ATA DE JULGAMENTO DA COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)

Número: ${dadosAta.numero}
Período: ${dadosAta.periodo}
Data de Elaboração: ${new Date().toLocaleDateString('pt-BR')}

RESUMO:
- Total de processos julgados: ${produtos.length}
- Produtos aprovados: ${produtosAprovados.length}
- Produtos reprovados: ${produtosReprovados.length}

PRODUTOS APROVADOS:
${produtosAprovados.map((produto, index) => `
${index + 1}. ${produto.nome} - ${produto.marca}
   Adequação Técnica: ${produto.adequacao_tecnica}
   Base Legal: ${produto.base_legal || 'Lei 14.133/2021'}
`).join('')}

PRODUTOS REPROVADOS:
${produtosReprovados.map((produto, index) => `
${index + 1}. ${produto.nome} - ${produto.marca}
   Motivo: ${produto.observacoes_ccl || 'Não atendimento aos requisitos técnicos'}
`).join('')}

[CONTEÚDO A SER COMPLETADO NA ELABORAÇÃO FINAL]
      `.trim()
    },
    
    // ==================== SISTEMA DE DOWNLOADS ====================
    async baixarDocumentacaoProduto(produtoId) {
      try {
        // Importar jsPDF
        const { jsPDF } = await import('jspdf')
        
        // Buscar produto específico
        const { data: produto, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', produtoId)
          .eq('tenant_id', this.currentTenantId)
          .single()
        
        if (error) throw error
        
        // Buscar documentos vinculados ao produto
        const { data: documentos, error: errorDocs } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', produtoId)
          .eq('tenant_id', this.currentTenantId)
          .order('nome', { ascending: true })
        
        if (errorDocs) {
          console.warn('Erro ao carregar documentos:', errorDocs)
        }
        
        if (!produto) {
          this.$swal({
            title: '⚠️ Produto Não Encontrado',
            text: 'Não foi possível encontrar os dados do produto.',
            icon: 'warning'
          })
          return
        }
        
        // Criar PDF com layout profissional
        const doc = new jsPDF()
        const pageWidth = doc.internal.pageSize.getWidth()
        const pageHeight = doc.internal.pageSize.getHeight()
        let yPosition = 25
        
        // ====================== CABEÇALHO OFICIAL ======================
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 8
        
        doc.setFontSize(12)
        doc.setFont(undefined, 'normal')
        doc.text('Sistema de Pré-Qualificação de Bens - Lei 14.133/2021', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 15
        
        // Linha decorativa
        doc.setLineWidth(0.5)
        doc.line(30, yPosition, pageWidth - 30, yPosition)
        yPosition += 20
        
        // ====================== TÍTULO DO DOCUMENTO ======================
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('DOCUMENTAÇÃO TÉCNICA COMPLETA', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 8
        
        doc.setFontSize(12)
        doc.text('Processo de Pré-Qualificação de Bem', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 20
        
        // ====================== DADOS DE IDENTIFICAÇÃO ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('I. IDENTIFICAÇÃO DO BEM', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const dadosBasicos = [
          ['Nome do Produto:', produto.nome || 'Não informado'],
          ['Marca:', produto.marca || 'Não informado'],
          ['Modelo:', produto.modelo || 'Não informado'],
          ['Fabricante:', produto.fabricante || 'Não informado'],
          ['Código do Material:', produto.codigo_material || 'Não informado'],
          ['Categoria:', this.getCategoriaName(produto.categoria_id) || 'Não informado'],
          ['CNPJ Fabricante:', produto.cnpj_fabricante || produto.cnpj || 'Não informado']
        ]
        
        dadosBasicos.forEach(([label, valor]) => {
          doc.setFont(undefined, 'bold')
          doc.text(label, 35, yPosition)
          doc.setFont(undefined, 'normal')
          doc.text(valor, 90, yPosition)
          yPosition += 8
        })
        
        yPosition += 10
        
        // ====================== HISTÓRICO DO PROCESSO ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('II. HISTÓRICO DO PROCESSO', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const historico = [
          ['Data de Cadastro:', this.formatDate(produto.criado_em)],
          ['Status Atual:', this.formatarStatusCPM(produto.status)],
          ['Última Atualização:', this.formatDate(produto.atualizado_em)]
        ]
        
        if (produto.julgado_em) {
          historico.push(['Data do Julgamento CCL:', this.formatDate(produto.julgado_em)])
        }
        
        if (produto.adequacao_tecnica) {
          historico.push(['Adequação Técnica:', produto.adequacao_tecnica])
        }
        
        historico.forEach(([label, valor]) => {
          doc.setFont(undefined, 'bold')
          doc.text(label, 35, yPosition)
          doc.setFont(undefined, 'normal')
          doc.text(valor, 90, yPosition)
          yPosition += 8
        })
        
        yPosition += 15
        
        // ====================== PARECER TÉCNICO DA CPM ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('III. PARECER TÉCNICO DA CPM', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        if (produto.observacoes_cpm) {
          const parecerCpm = doc.splitTextToSize(produto.observacoes_cpm, pageWidth - 70)
          doc.text(parecerCpm, 35, yPosition)
          yPosition += parecerCpm.length * 6 + 10
        } else {
          doc.setFont(undefined, 'italic')
          doc.text('Parecer da CPM não disponível.', 35, yPosition)
          yPosition += 15
        }
        
        // Verificar nova página
        if (yPosition > pageHeight - 80) {
          doc.addPage()
          yPosition = 30
        }
        
        // ====================== DECISÃO DA CCL ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('IV. DECISÃO DA COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        if (produto.observacoes_ccl) {
          doc.setFont(undefined, 'bold')
          doc.text('Fundamentação da Decisão:', 35, yPosition)
          yPosition += 8
          
          doc.setFont(undefined, 'normal')
          const decisaoCcl = doc.splitTextToSize(produto.observacoes_ccl, pageWidth - 70)
          doc.text(decisaoCcl, 35, yPosition)
          yPosition += decisaoCcl.length * 6 + 10
        }
        
        if (produto.base_legal) {
          doc.setFont(undefined, 'bold')
          doc.text('Base Legal:', 35, yPosition)
          yPosition += 8
          
          doc.setFont(undefined, 'normal')
          const baseLegal = doc.splitTextToSize(produto.base_legal, pageWidth - 70)
          doc.text(baseLegal, 35, yPosition)
          yPosition += baseLegal.length * 6 + 10
        }
        
        if (!produto.observacoes_ccl && !produto.base_legal) {
          doc.setFont(undefined, 'italic')
          doc.text('Processo ainda não foi julgado pela CCL.', 35, yPosition)
          yPosition += 15
        }
        
        // ====================== ESPECIFICAÇÕES TÉCNICAS ======================
        if (produto.especificacoes_tecnicas) {
          if (yPosition > pageHeight - 60) {
            doc.addPage()
            yPosition = 30
          }
          
          doc.setFontSize(14)
          doc.setFont(undefined, 'bold')
          doc.text('V. ESPECIFICAÇÕES TÉCNICAS', 30, yPosition)
          yPosition += 12
          
          doc.setFontSize(11)
          doc.setFont(undefined, 'normal')
          const especificacoes = doc.splitTextToSize(produto.especificacoes_tecnicas, pageWidth - 70)
          doc.text(especificacoes, 35, yPosition)
          yPosition += especificacoes.length * 6 + 15
        }
        
        // ====================== DOCUMENTOS ANEXOS ======================
        if (documentos && documentos.length > 0) {
          if (yPosition > pageHeight - 80) {
            doc.addPage()
            yPosition = 30
          }
          
          doc.setFontSize(14)
          doc.setFont(undefined, 'bold')
          doc.text(produto.especificacoes_tecnicas ? 'VI. DOCUMENTOS ANEXOS' : 'V. DOCUMENTOS ANEXOS', 30, yPosition)
          yPosition += 12
          
          doc.setFontSize(11)
          doc.setFont(undefined, 'normal')
          
          doc.text('Os seguintes documentos estão vinculados a este produto:', 35, yPosition)
          yPosition += 10
          
          documentos.forEach((documento, index) => {
            // Verificar se precisa de nova página
            if (yPosition > pageHeight - 40) {
              doc.addPage()
              yPosition = 30
            }
            
            doc.setFont(undefined, 'bold')
            doc.text(`${index + 1}. ${documento.nome}`, 35, yPosition)
            yPosition += 6
            
            doc.setFont(undefined, 'normal')
            doc.text(`Tipo: ${documento.tipo || 'Não especificado'}`, 40, yPosition)
            yPosition += 6
            
            if (documento.arquivo_url) {
              doc.setFontSize(9)
              doc.setFont(undefined, 'italic')
              doc.text(`URL: ${documento.arquivo_url}`, 40, yPosition)
              yPosition += 6
              doc.setFontSize(11)
            }
            
            yPosition += 3
          })
          
          yPosition += 10
          
          // Nota sobre acesso aos documentos
          doc.setFontSize(10)
          doc.setFont(undefined, 'italic')
          const nota = doc.splitTextToSize('Nota: Os documentos listados acima estão disponíveis digitalmente no sistema e podem ser acessados através das URLs fornecidas ou solicitados à administração.', pageWidth - 70)
          doc.text(nota, 35, yPosition)
          yPosition += nota.length * 5 + 15
        }
        
        // ====================== RODAPÉ LEGAL ======================
        const totalPages = doc.internal.getNumberOfPages()
        
        for (let i = 1; i <= totalPages; i++) {
          doc.setPage(i)
          
          // Linha no rodapé
          doc.setLineWidth(0.3)
          doc.line(30, pageHeight - 25, pageWidth - 30, pageHeight - 25)
          
          // Textos do rodapé
          doc.setFontSize(8)
          doc.setFont(undefined, 'normal')
          doc.text('Sistema Comprar Bem - Pré-Qualificação de Bens', 30, pageHeight - 18)
          doc.text(`Página ${i} de ${totalPages}`, pageWidth / 2, pageHeight - 18, { align: 'center' })
          doc.text('Lei 14.133/2021', pageWidth - 30, pageHeight - 18, { align: 'right' })
          
          doc.text(`Documento gerado em: ${new Date().toLocaleDateString('pt-BR')} às ${new Date().toLocaleTimeString('pt-BR')}`, 30, pageHeight - 12)
          doc.text('Processo de Pré-Qualificação - CCL', pageWidth - 30, pageHeight - 12, { align: 'right' })
        }
        
        // Salvar PDF
        const nomeArquivo = `CCL_${(produto.nome || 'Produto').replace(/[^a-zA-Z0-9]/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`
        doc.save(nomeArquivo)
        
        this.$swal({
          title: '✅ Documentação Gerada!',
          html: `
            <div style="text-align: center; padding: 15px;">
              <h4>📋 ${produto.nome}</h4>
              <p><strong>Arquivo:</strong> ${nomeArquivo}</p>
              <p>Documentação técnica completa gerada com sucesso!</p>
              ${documentos && documentos.length > 0 ? 
                `<p><strong>📎 ${documentos.length} documento(s) anexo(s)</strong> incluído(s) no PDF</p>` : 
                '<p><em>Nenhum documento anexo vinculado ao produto</em></p>'
              }
            </div>
          `,
          icon: 'success',
          confirmButtonText: '✅ Perfeito!'
        })
        
      } catch (error) {
        console.error('Erro ao gerar PDF:', error)
        this.$swal({
          title: '❌ Erro ao Gerar PDF',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    async baixarDocumentacaoRecursoEspecifico(recursoId) {
      try {
        // Importar jsPDF
        const { jsPDF } = await import('jspdf')
        
        // Buscar recurso específico
        const recurso = this.recursos?.find(r => r.id === recursoId)
        
        if (!recurso) {
          this.$swal({
            title: '⚠️ Recurso Não Encontrado',
            text: 'Não foi possível encontrar os dados do recurso.',
            icon: 'warning'
          })
          return
        }
        
        // Criar PDF profissional
        const doc = new jsPDF()
        const pageWidth = doc.internal.pageSize.getWidth()
        const pageHeight = doc.internal.pageSize.getHeight()
        let yPosition = 25
        
        // ====================== CABEÇALHO OFICIAL ======================
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 8
        
        doc.setFontSize(12)
        doc.setFont(undefined, 'normal')
        doc.text('Recurso Administrativo - Lei 14.133/2021, Art. 165-171', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 15
        
        // Linha decorativa
        doc.setLineWidth(0.5)
        doc.line(30, yPosition, pageWidth - 30, yPosition)
        yPosition += 20
        
        // ====================== TÍTULO DO DOCUMENTO ======================
        doc.setFontSize(16)
        doc.setFont(undefined, 'bold')
        doc.text('DOCUMENTAÇÃO DE RECURSO ADMINISTRATIVO', pageWidth / 2, yPosition, { align: 'center' })
        yPosition += 20
        
        // ====================== DADOS DO RECURSO ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('I. IDENTIFICAÇÃO DO RECURSO', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const dadosRecurso = [
          ['Protocolo:', recursoId],
          ['Produto:', recurso.produto_nome || 'Não informado'],
          ['Recorrente:', recurso.recorrente || 'Não informado'],
          ['Data do Recurso:', this.formatDate(recurso.data_recurso)],
          ['Prazo Final:', this.formatDate(recurso.prazo_final)],
          ['Status Atual:', recurso.status || 'Em Análise'],
          ['Ata de Referência:', recurso.ata_referencia || 'Não informado']
        ]
        
        dadosRecurso.forEach(([label, valor]) => {
          doc.setFont(undefined, 'bold')
          doc.text(label, 35, yPosition)
          doc.setFont(undefined, 'normal')
          doc.text(valor, 90, yPosition)
          yPosition += 8
        })
        
        yPosition += 15
        
        // ====================== FUNDAMENTAÇÃO DO RECURSO ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('II. FUNDAMENTAÇÃO DO RECURSO', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        if (recurso.fundamentacao) {
          const fundamentacao = doc.splitTextToSize(recurso.fundamentacao, pageWidth - 70)
          doc.text(fundamentacao, 35, yPosition)
          yPosition += fundamentacao.length * 6 + 15
        } else {
          doc.setFont(undefined, 'italic')
          doc.text('Fundamentação não disponível.', 35, yPosition)
          yPosition += 15
        }
        
        // ====================== ANÁLISE E DECISÃO DA CCL ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('III. ANÁLISE E DECISÃO DA CCL', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        if (recurso.decisao) {
          doc.setFont(undefined, 'bold')
          doc.text('Decisão:', 35, yPosition)
          yPosition += 8
          
          doc.setFont(undefined, 'normal')
          doc.text(recurso.decisao.toUpperCase(), 35, yPosition)
          yPosition += 10
          
          if (recurso.fundamentacao_decisao) {
            doc.setFont(undefined, 'bold')
            doc.text('Fundamentação da Decisão:', 35, yPosition)
            yPosition += 8
            
            doc.setFont(undefined, 'normal')
            const fundamentacaoDecisao = doc.splitTextToSize(recurso.fundamentacao_decisao, pageWidth - 70)
            doc.text(fundamentacaoDecisao, 35, yPosition)
            yPosition += fundamentacaoDecisao.length * 6 + 15
          }
        } else {
          doc.setFont(undefined, 'italic')
          doc.text('Recurso ainda em análise pela CCL.', 35, yPosition)
          yPosition += 15
        }
        
        // ====================== BASE LEGAL ======================
        doc.setFontSize(14)
        doc.setFont(undefined, 'bold')
        doc.text('IV. BASE LEGAL', 30, yPosition)
        yPosition += 12
        
        doc.setFontSize(11)
        doc.setFont(undefined, 'normal')
        
        const basesLegais = [
          '• Lei nº 14.133/2021 - Nova Lei de Licitações e Contratos',
          '• Art. 165 - Direito de recurso dos interessados',
          '• Art. 166 - Prazo para interposição de recurso',
          '• Art. 167 - Processamento dos recursos',
          '• Art. 168 - Efeito suspensivo dos recursos',
          '• Art. 169 - Decisão dos recursos',
          '• Art. 170 - Recursos contra atos da CCL',
          '• Art. 171 - Irrecorribilidade das decisões'
        ]
        
        basesLegais.forEach(base => {
          doc.text(base, 35, yPosition)
          yPosition += 6
        })
        
        // ====================== RODAPÉ LEGAL ======================
        const totalPages = doc.internal.getNumberOfPages()
        
        for (let i = 1; i <= totalPages; i++) {
          doc.setPage(i)
          
          // Linha no rodapé
          doc.setLineWidth(0.3)
          doc.line(30, pageHeight - 25, pageWidth - 30, pageHeight - 25)
          
          // Textos do rodapé
          doc.setFontSize(8)
          doc.setFont(undefined, 'normal')
          doc.text('Sistema Comprar Bem - Recursos Administrativos', 30, pageHeight - 18)
          doc.text(`Página ${i} de ${totalPages}`, pageWidth / 2, pageHeight - 18, { align: 'center' })
          doc.text('Lei 14.133/2021 - Art. 165-171', pageWidth - 30, pageHeight - 18, { align: 'right' })
          
          doc.text(`Documento gerado em: ${new Date().toLocaleDateString('pt-BR')} às ${new Date().toLocaleTimeString('pt-BR')}`, 30, pageHeight - 12)
          doc.text(`Protocolo: ${recursoId}`, pageWidth - 30, pageHeight - 12, { align: 'right' })
        }
        
        // Salvar PDF
        const nomeArquivo = `CCL_Recurso_${recurso.produto_nome?.replace(/[^a-zA-Z0-9]/g, '_') || 'Recurso'}_${new Date().toISOString().split('T')[0]}.pdf`
        doc.save(nomeArquivo)
        
        this.$swal({
          title: '✅ Documentação do Recurso Gerada!',
          html: `
            <div style="text-align: center; padding: 15px;">
              <h4>⚖️ ${recurso.produto_nome || 'Recurso Administrativo'}</h4>
              <p><strong>Recorrente:</strong> ${recurso.recorrente}</p>
              <p><strong>Arquivo:</strong> ${nomeArquivo}</p>
              <p>Documentação completa do recurso gerada com sucesso!</p>
            </div>
          `,
          icon: 'success',
          confirmButtonText: '✅ Perfeito!'
        })
        
      } catch (error) {
        console.error('Erro ao gerar PDF do recurso:', error)
        this.$swal({
          title: '❌ Erro ao Gerar PDF',
          text: `Erro: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    // ==================== MÉTODOS DE PAGINAÇÃO ====================
    
    mudarPagina(secao, novaPagina) {
      if (novaPagina >= 1 && novaPagina <= this.calcularTotalPaginas(secao)) {
        this.paginacao[secao].paginaAtual = novaPagina
      }
    },
    
    calcularTotalPaginas(secao) {
      const total = this.paginacao[secao].total
      const itensPorPagina = this.paginacao[secao].itensPorPagina
      return total > 0 ? Math.ceil(total / itensPorPagina) : 1
    },
    
    atualizarTotalPaginacao(secao, novoTotal) {
      this.paginacao[secao].total = novoTotal
      // Se a página atual é maior que o total de páginas, volta para a primeira
      if (this.paginacao[secao].paginaAtual > this.calcularTotalPaginas(secao)) {
        this.paginacao[secao].paginaAtual = 1
      }
    },
    
    proximaPagina(secao) {
      const totalPaginas = this.calcularTotalPaginas(secao)
      if (this.paginacao[secao].paginaAtual < totalPaginas) {
        this.paginacao[secao].paginaAtual++
      }
    },
    
    paginaAnterior(secao) {
      if (this.paginacao[secao].paginaAtual > 1) {
        this.paginacao[secao].paginaAtual--
      }
    },

    // =====================================================
    // NOVOS MÉTODOS PARA FLUXO CCL CORRETO
    // =====================================================
    async iniciarJulgamentoCCL(processo) {
      try {
        const { value: julgamento } = await this.$swal({
          title: `⚖️ Julgamento Técnico CCL`,
          html: `
            <div style="text-align: left; padding: 10px; max-width: 100%; box-sizing: border-box;">
              <div style="background: #f8f9fa; padding: 12px; border-radius: 8px; margin-bottom: 15px;">
                <h4 style="margin: 0 0 8px 0; font-size: 16px;">📄 Dados do Processo</h4>
                <p style="margin: 5px 0; word-wrap: break-word;"><strong>Número:</strong> ${processo.numero_processo}</p>
                <p style="margin: 5px 0; word-wrap: break-word;"><strong>Objeto:</strong> ${processo.objeto || 'Não informado'}</p>
                <p style="margin: 5px 0;"><strong>Status:</strong> ${this.formatarStatusProcesso(processo.status)}</p>
              </div>
              
              <div style="margin-bottom: 12px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px; font-size: 14px;">Decisão Técnica da CCL:</label>
                <select id="decisaoTecnica" class="swal2-select" style="width: 95%; box-sizing: border-box;">
                  <option value="">Selecione a decisão...</option>
                  <option value="aprovar">✅ APROVAR - Processo está tecnicamente adequado</option>
                  <option value="devolver">↩️ DEVOLVER - Solicitar correções</option>
                  <option value="rejeitar">❌ REJEITAR - Processo inadequado</option>
                </select>
              </div>
              
              <div style="margin-bottom: 12px;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px; font-size: 14px;">Fundamentação Técnica:</label>
                <textarea id="fundamentacaoTecnica" class="swal2-textarea" rows="4" 
                  placeholder="Descreva a análise técnica realizada e fundamente sua decisão..." 
                  style="width: 95%; box-sizing: border-box; resize: vertical;"></textarea>
              </div>
              
              <div style="background: #e3f2fd; padding: 12px; border-radius: 8px;">
                <h5 style="margin: 0 0 8px 0; color: #1976d2; font-size: 14px;">ℹ️ Próximos Passos:</h5>
                <div style="font-size: 12px; line-height: 1.4;">
                  <p style="margin: 3px 0;"><strong>✅ APROVAR:</strong> Processo vai para Assessoria Jurídica</p>
                  <p style="margin: 3px 0;"><strong>↩️ DEVOLVER:</strong> Processo volta para CPM com observações</p>
                  <p style="margin: 3px 0;"><strong>❌ REJEITAR:</strong> Processo é rejeitado definitivamente</p>
                </div>
              </div>
            </div>
          `,
          width: '700px',
          maxWidth: '90vw',
          showCancelButton: true,
          confirmButtonText: '⚖️ Confirmar Julgamento',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const decisao = document.getElementById('decisaoTecnica').value
            const fundamentacao = document.getElementById('fundamentacaoTecnica').value.trim()
            
            if (!decisao) {
              this.$swal.showValidationMessage('Selecione uma decisão técnica')
              return false
            }
            
            if (!fundamentacao) {
              this.$swal.showValidationMessage('A fundamentação técnica é obrigatória')
              return false
            }
            
            return { decisao, fundamentacao }
          }
        })
        
        if (!julgamento) return
        
        // Processar decisão usando TramitacaoProcessosService
        let resultado
        
        switch(julgamento.decisao) {
          case 'aprovar':
            // Enviar para próxima etapa (aprovado_ccl -> Assessoria Jurídica)
            resultado = await TramitacaoProcessosService.enviarProcesso(
              processo.id, 
              `CCL aprovou tecnicamente o processo: ${julgamento.fundamentacao}`
            )
            break
            
          case 'devolver':
            // Devolver para CPM
            resultado = await TramitacaoProcessosService.devolverProcesso(
              processo.id,
              'Solicitação de correções técnicas pela CCL',
              julgamento.fundamentacao
            )
            break
            
          case 'rejeitar':
            // Rejeitar processo
            resultado = await TramitacaoProcessosService.rejeitarProcesso(
              processo.id,
              'Processo rejeitado tecnicamente pela CCL',
              julgamento.fundamentacao
            )
            break
        }
        
        if (!resultado || !resultado.sucesso) {
          throw new Error('Falha na tramitação do processo')
        }
        
        // Salvar dados específicos da CCL
        const { error: updateError } = await supabase
          .from('processos_administrativos')
          .update({
            ata_julgamento_ccl: julgamento.fundamentacao,
            ata_emitida_ccl_em: new Date().toISOString(),
            data_julgamento_ccl: new Date().toISOString()
          })
          .eq('id', processo.id)
        
        if (updateError) {
          console.warn('Erro ao salvar dados CCL (processo foi tramitado):', updateError)
        }

        // Se foi aprovado, criar ata de julgamento automaticamente
        if (julgamento.decisao === 'aprovar') {
          await this.criarAtaAutomatica(processo, julgamento)
        }
        
        // Mostrar resultado
        const decisaoTexto = {
          aprovar: 'aprovado',
          devolver: 'devolvido para correções',
          rejeitar: 'rejeitado'
        }[julgamento.decisao]
        
        await this.$swal({
          title: '✅ Julgamento Realizado!',
          html: `
            <p>Processo <strong>${processo.numero_processo}</strong> foi <strong>${decisaoTexto}</strong> pela CCL.</p>
            <p><strong>Novo status:</strong> ${resultado.statusNovo}</p>
            <p><strong>Próximo responsável:</strong> ${resultado.proximoResponsavel || 'Definido pelo sistema'}</p>
          `,
          icon: 'success'
        })
        
        // Recarregar dados
        await this.carregarDados(true)
        
      } catch (error) {
        console.error('Erro no julgamento CCL:', error)
        await this.$swal({
          title: '❌ Erro no Julgamento',
          text: error.message || 'Erro interno do sistema',
          icon: 'error'
        })
      }
    },

    async devolverProcesso(processo) {
      try {
        const { value: motivo } = await this.$swal({
          title: `↩️ Devolver Processo`,
          html: `
            <div style="text-align: left; padding: 15px;">
              <p><strong>Processo:</strong> ${processo.numero_processo}</p>
              <p><strong>Status atual:</strong> ${this.formatarStatusProcesso(processo.status)}</p>
              
              <div style="margin: 15px 0;">
                <label style="display: block; font-weight: bold; margin-bottom: 5px;">Motivo da devolução:</label>
                <textarea id="motivoDevolucao" class="swal2-textarea" rows="4" 
                  placeholder="Descreva os motivos pelos quais o processo está sendo devolvido..." 
                  style="width: 100%;"></textarea>
              </div>
              
              <div style="background: #fff3cd; padding: 10px; border-radius: 4px;">
                <small><strong>⚠️ Atenção:</strong> O processo será devolvido para a CPM com status de devolução.</small>
              </div>
            </div>
          `,
          width: '600px',
          showCancelButton: true,
          confirmButtonText: '↩️ Confirmar Devolução',
          cancelButtonText: '❌ Cancelar',
          preConfirm: () => {
            const motivo = document.getElementById('motivoDevolucao').value.trim()
            if (!motivo) {
              this.$swal.showValidationMessage('O motivo da devolução é obrigatório')
              return false
            }
            return motivo
          }
        })
        
        if (!motivo) return
        
        const resultado = await TramitacaoProcessosService.devolverProcesso(
          processo.id,
          motivo,
          `Processo devolvido pela CCL: ${motivo}`
        )
        
        if (!resultado || !resultado.sucesso) {
          throw new Error('Falha na devolução do processo')
        }
        
        await this.$swal({
          title: '✅ Processo Devolvido!',
          html: `
            <p>Processo <strong>${processo.numero_processo}</strong> foi devolvido para a CPM.</p>
            <p><strong>Novo status:</strong> ${resultado.statusNovo}</p>
          `,
          icon: 'success'
        })
        
        await this.carregarDados(true)
        
      } catch (error) {
        console.error('Erro na devolução:', error)
        await this.$swal({
          title: '❌ Erro na Devolução',
          text: error.message || 'Erro interno do sistema',
          icon: 'error'
        })
      }
    }
  },
  
  mounted() {
    // Expor as funções no window para que possam ser chamadas pelos onclick dos SweetAlert
    window.baixarDocumentacaoProduto = (produtoId) => this.baixarDocumentacaoProduto(produtoId)
    window.baixarDocumentacaoRecursoEspecifico = (recursoId) => this.baixarDocumentacaoRecursoEspecifico(recursoId)
    
    // Não carregar dados automaticamente no mounted para evitar duplicação
    // O carregamento será feito pelo created() e pelo watcher do currentTenantId
  }
}
</script>

<style scoped>
/* Sistema de abas simplificado */
.tab-content {
  margin-top: 20px;
}

.tab-pane {
  width: 100%;
}

.tab-header {
  display: flex;
  border-bottom: 2px solid #e9ecef;
  margin-bottom: 20px;
}

.tab-button {
  padding: 16px 32px;
  background: none;
  border: none;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
  font-weight: 500;
  font-size: 1.1rem;
  min-height: 50px;
}

.tab-button.active {
  border-bottom-color: #e74c3c;
  color: #e74c3c;
  font-weight: 600;
}

.tab-button:hover {
  background-color: #f8f9fa;
  color: #e74c3c;
}

/* Correções para os modais SweetAlert */
:global(.swal2-container-modal) {
  padding: 10px !important;
}

:global(.swal2-popup-modal) {
  max-width: 90vw !important;
  max-height: 90vh !important;
}

/* Estilo para as abas */
.dashboard {
  background-color: #f5f7fa;
  min-height: 100vh;
  padding: 1.5rem;
}

.dashboard h2 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
  font-size: 2rem;
  font-weight: 600;
}

.tabs {
  display: flex;
  border-bottom: 2px solid #e9ecef;
  margin-bottom: 2rem;
}

.tab {
  padding: 1rem 2rem;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
  position: relative;
  font-weight: 500;
}

.tab:hover {
  background-color: #f8f9fa;
}

.tab.active {
  border-bottom-color: #e74c3c;
  color: #e74c3c;
  font-weight: 600;
}

.tab-notification {
  position: absolute;
  top: 5px;
  right: 5px;
  background: #dc3545;
  color: white;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  font-size: 11px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
}

/* Cards dos stats */
.stats-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 2rem;
  margin-bottom: 2.5rem;
}

.stat-card {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 8px rgba(0,0,0,0.12);
  transition: transform 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-3px);
}

.stat-card h3 {
  margin: 0 0 0.75rem 0;
  color: #2c3e50;
  font-size: 1.2rem;
  font-weight: 600;
}

.stat-icon {
  font-size: 2.5rem;
  margin-bottom: 0.75rem;
}

.stat-value {
  font-size: 3rem;
  font-weight: bold;
  margin: 0.75rem 0;
}

.stat-description {
  margin: 0;
  color: #666;
  font-size: 1rem;
}

.status-pendente-card .stat-value {
  color: #f39c12;
}

.status-aprovado-card .stat-value {
  color: #27ae60;
}

.status-recurso-card .stat-value {
  color: #3498db;
}

.stat-card-alert {
  border-left: 4px solid #e74c3c;
}

.stat-card-alert .stat-value {
  color: #e74c3c;
}

/* Seções do dashboard */
.dashboard-section {
  background: white;
  padding: 2.5rem;
  border-radius: 12px;
  box-shadow: 0 4px 8px rgba(0,0,0,0.12);
  margin-bottom: 2.5rem;
}

.section-header {
  margin-bottom: 1.5rem;
}

.section-header h3 {
  margin: 0 0 0.75rem 0;
  color: #2c3e50;
  font-size: 1.4rem;
  font-weight: 600;
}

.section-description {
  margin: 0;
  color: #666;
  font-size: 1.1rem;
  line-height: 1.5;
}

.section-actions {
  display: flex;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

/* Tabelas */
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 1.5rem;
  font-size: 1rem;
}

th, td {
  padding: 1.25rem 1rem;
  text-align: left;
  border-bottom: 1px solid #ddd;
  vertical-align: top;
}

th {
  background-color: #f8f9fa;
  font-weight: 600;
  color: #2c3e50;
  font-size: 1.1rem;
  letter-spacing: 0.5px;
}

tr:hover {
  background-color: #f8f9fa;
}

.processo-info {
  font-size: 1rem;
  line-height: 1.4;
}

.processo-info strong {
  font-size: 1.1rem;
  color: #2c3e50;
}

.processo-id {
  font-size: 0.9rem;
  color: #666;
  margin-top: 0.25rem;
}

.objeto-processo {
  max-width: 400px;
  font-size: 1rem;
  line-height: 1.4;
}

.objeto-text {
  color: #2c3e50;
  cursor: help;
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 100%;
}

/* Botões */
.btn-primary {
  background-color: #3498db;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.2s ease;
  min-height: 42px;
}

.btn-primary:hover {
  background-color: #2980b9;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.btn-secondary {
  background-color: #95a5a6;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.2s ease;
  min-height: 42px;
}

.btn-secondary:hover {
  background-color: #7f8c8d;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.btn-warning {
  background-color: #f39c12;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.2s ease;
  min-height: 42px;
}

.btn-warning:hover {
  background-color: #e67e22;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.btn-small {
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
  min-height: 36px;
}

/* Estados vazios */
.empty-state {
  text-align: center;
  padding: 3rem 2rem;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1.5rem;
  opacity: 0.5;
}

.empty-state h4 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
  font-size: 1.3rem;
  font-weight: 600;
}

.empty-state p {
  margin: 0;
  font-size: 1.1rem;
  line-height: 1.4;
}

/* Paginação */
.pagination-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1.5rem;
  margin-top: 1.5rem;
  padding: 1.5rem;
}

.pagination-btn {
  background-color: #3498db;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.2s ease;
  min-height: 42px;
}

.pagination-btn:hover:not(:disabled) {
  background-color: #2980b9;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.pagination-btn:disabled {
  background-color: #bdc3c7;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.pagination-info {
  color: #666;
  font-size: 1rem;
  font-weight: 500;
}

/* Alertas */
.alertas-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 1.5rem;
  border-left: 4px solid #e74c3c;
}

.alertas-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.alertas-header h3 {
  margin: 0;
  color: #e74c3c;
}

.btn-link {
  background: none;
  border: none;
  color: #3498db;
  cursor: pointer;
  text-decoration: underline;
  font-size: 0.9rem;
}

.btn-link:hover {
  color: #2980b9;
}

.alertas-grid {
  display: grid;
  gap: 1rem;
}

.alerta-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid #ddd;
}

.alerta-card.critico {
  background: #fff5f5;
  border-color: #e74c3c;
}

.alerta-card.aviso {
  background: #fff8dc;
  border-color: #f39c12;
}

.alerta-icon {
  font-size: 1.5rem;
}

.alerta-content {
  flex: 1;
}

.alerta-content h5 {
  margin: 0 0 0.25rem 0;
  color: #2c3e50;
}

.alerta-content p {
  margin: 0 0 0.25rem 0;
  color: #666;
}

.alerta-content small {
  color: #999;
  font-size: 0.8rem;
}

.alerta-actions {
  display: flex;
  gap: 0.5rem;
}

/* Atas específicos */
.atas-julgamento {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.atas-header {
  margin-bottom: 2rem;
}

.atas-header h3 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.atas-description {
  margin: 0 0 1rem 0;
  color: #666;
  font-size: 0.95rem;
}

.alert-info {
  background: #e3f2fd;
  border: 1px solid #2196f3;
  padding: 10px;
  border-radius: 5px;
  margin: 10px 0;
}

.atas-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}

.atas-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.ata-stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  border-left: 4px solid #3498db;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.ata-stat-icon {
  font-size: 2rem;
  color: #3498db;
}

.ata-stat-info h4 {
  margin: 0;
  font-size: 1.8rem;
  color: #2c3e50;
  font-weight: 600;
}

.ata-stat-info p {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

.atas-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.atas-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.atas-section .section-header h4 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
  font-size: 1.2rem;
}

.atas-table-container {
  overflow-x: auto;
  margin-top: 1rem;
}

.processos-julgamento-table,
.processos-julgados-table {
  width: 100%;
  border-collapse: collapse;
}

.processos-julgamento-table th,
.processos-julgados-table th,
.processos-julgamento-table td,
.processos-julgados-table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

.processos-julgamento-table th,
.processos-julgados-table th {
  background-color: #f8f9fa;
  font-weight: 600;
  color: #2c3e50;
}

.objeto-cell {
  max-width: 300px;
  word-wrap: break-word;
}

.status-julgamento {
  background-color: #fff3cd;
  color: #856404;
  padding: 0.25rem 0.5rem;
  border-radius: 3px;
  font-size: 0.8rem;
  font-weight: 500;
}

.decisao-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 3px;
  font-size: 0.8rem;
  font-weight: 500;
}

.decisao-aprovado {
  background-color: #d4edda;
  color: #155724;
}

.responsavel-badge {
  background-color: #e3f2fd;
  color: #0d47a1;
  padding: 0.25rem 0.5rem;
  border-radius: 3px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-elaboracao {
  background-color: #fff3cd;
  color: #856404;
}

.decisao-rejeitado {
  background-color: #f8d7da;
  color: #721c24;
}

.decisoes-summary {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.processos-cell {
  font-weight: 500;
  color: #2c3e50;
}

.status-recurso-prazo {
  background-color: #fff3cd;
  color: #856404;
}

.status-sem-recursos {
  background-color: #d4edda;
  color: #155724;
}

.status-com-recursos {
  background-color: #f8d7da;
  color: #721c24;
}

.status-indefinido {
  background-color: #e2e3e5;
  color: #383d41;
}

.atas-elaboracao-table,
.atas-publicadas-table {
  width: 100%;
  border-collapse: collapse;
}

.atas-elaboracao-table th,
.atas-publicadas-table th,
.atas-elaboracao-table td,
.atas-publicadas-table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

.atas-elaboracao-table th,
.atas-publicadas-table th {
  background-color: #f8f9fa;
  font-weight: 600;
  color: #2c3e50;
}

/* Homologações específicos */
.homologacoes {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.homologacoes-header h3 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.alert-duvida {
  background: #fff3cd;
  border: 1px solid #ffeaa7;
  padding: 10px;
  border-radius: 5px;
  margin: 10px 0;
}

/* Processo específicos */
.processo-numero {
  font-weight: bold;
  color: #2c3e50;
}

.processo-id {
  color: #666;
  font-size: 0.8rem;
}

.objeto-processo {
  max-width: 300px;
}

.objeto-text {
  color: #2c3e50;
  cursor: help;
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 100%;
}

.orgao-info {
  max-width: 200px;
}

.orgao-nome {
  color: #2c3e50;
  font-weight: 500;
}

/* Responsivos */
@media (max-width: 768px) {
  .stats-container {
    grid-template-columns: 1fr;
  }
  
  .tabs {
    flex-direction: column;
  }
  
  .tab {
    padding: 0.75rem 1rem;
  }
  
  .section-actions {
    flex-direction: column;
  }
  
  .pagination-controls {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .alertas-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .alerta-card {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .alerta-actions {
    width: 100%;
    justify-content: flex-end;
  }
  
  table {
    font-size: 0.8rem;
  }
  
  th, td {
    padding: 0.5rem;
  }
}
</style>