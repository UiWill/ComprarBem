<template>
  <div class="gerenciador-relatorios">
    <div class="header-section">
      <div class="title-and-stats">
        <h2>📋 Gerenciador de Relatórios</h2>
        <div class="stats-mini">
          <span class="stat-item">
            <strong>{{ totalRelatorios }}</strong> Relatórios
          </span>
          <span class="stat-item pendentes">
            <strong>{{ relatoriosPendentes }}</strong> Pendentes
          </span>
          <span class="stat-item concluidos">
            <strong>{{ relatoriosConcluidos }}</strong> Concluídos
          </span>
        </div>
      </div>
      
      <div class="actions-header">
        <button @click="abrirModalNovoRelatorio" class="btn-primary">
          + Novo Relatório
        </button>
        <button @click="carregarRelatorios" class="btn-secondary">
          🔄 Atualizar
        </button>
      </div>
    </div>

    <!-- Filtros -->
    <div class="filtros-section">
      <div class="filtros-linha">
        <div class="filtro-group">
          <label>📝 Título:</label>
          <input 
            v-model="filtros.titulo" 
            type="text" 
            placeholder="Filtrar por título..."
            @input="aplicarFiltros"
          >
        </div>
        
        <div class="filtro-group">
          <label>📊 Categoria:</label>
          <select v-model="filtros.categoria" @change="aplicarFiltros">
            <option value="">Todas</option>
            <option value="pesquisa_mercado">Pesquisa de Mercado</option>
            <option value="cotacoes">Cotações</option>
            <option value="comparativos">Comparativos</option>
            <option value="analise_precos">Análise de Preços</option>
            <option value="executivo">Executivo</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>📈 Status:</label>
          <select v-model="filtros.status" @change="aplicarFiltros">
            <option value="">Todos</option>
            <option value="pendente">Pendente</option>
            <option value="gerando">Gerando</option>
            <option value="concluido">Concluído</option>
            <option value="erro">Com Erro</option>
            <option value="cancelado">Cancelado</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>📋 Tipo:</label>
          <select v-model="filtros.tipo_relatorio" @change="aplicarFiltros">
            <option value="">Todos</option>
            <option value="consolidado">Consolidado</option>
            <option value="analise_tecnica">Análise Técnica</option>
            <option value="comparativo_precos">Comparativo de Preços</option>
            <option value="executivo">Executivo</option>
            <option value="custom">Personalizado</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Lista de Relatórios -->
    <div class="relatorios-lista">
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Carregando relatórios...</p>
      </div>

      <div v-else-if="relatoriosFiltrados.length === 0" class="empty-state">
        <div class="empty-icon">📊</div>
        <h3>Nenhum relatório encontrado</h3>
        <p>Não há relatórios que correspondam aos filtros aplicados.</p>
        <button @click="limparFiltros" class="btn-secondary">Limpar Filtros</button>
      </div>

      <div v-else class="relatorios-grid">
        <div 
          v-for="relatorio in relatoriosPaginados" 
          :key="relatorio.id"
          class="relatorio-card"
          :class="'status-' + relatorio.status"
        >
          <div class="card-header">
            <div class="titulo-e-categoria">
              <h4>{{ relatorio.titulo }}</h4>
              <span class="categoria-badge" :class="'categoria-' + relatorio.categoria">
                {{ getCategoriaLabel(relatorio.categoria) }}
              </span>
            </div>
            
            <div class="status-badge" :class="'status-' + relatorio.status">
              {{ getStatusLabel(relatorio.status) }}
            </div>
          </div>

          <div class="card-content">
            <div class="info-linha">
              <strong>Tipo:</strong> {{ getTipoLabel(relatorio.tipo_relatorio) }}
            </div>
            
            <div v-if="relatorio.descricao" class="descricao">
              {{ relatorio.descricao }}
            </div>
            
            <div class="progress-section" v-if="relatorio.status === 'gerando'">
              <div class="progress-bar">
                <div 
                  class="progress-fill" 
                  :style="{ width: relatorio.progresso + '%' }"
                ></div>
              </div>
              <span class="progress-text">{{ relatorio.progresso }}%</span>
            </div>
            
            <div class="metadados">
              <span><strong>Criado:</strong> {{ formatarData(relatorio.created_at) }}</span>
              <span v-if="relatorio.gerado_em">
                <strong>Gerado:</strong> {{ formatarData(relatorio.gerado_em) }}
              </span>
              <span v-if="relatorio.visualizacoes > 0">
                <strong>Visualizações:</strong> {{ relatorio.visualizacoes }}
              </span>
            </div>
          </div>

          <div class="card-actions">
            <button 
              v-if="relatorio.status === 'concluido' && relatorio.url_arquivo_principal"
              @click="baixarRelatorio(relatorio)"
              class="btn-action download"
              title="Baixar Relatório"
            >
              📥 Baixar
            </button>
            
            <button 
              v-if="relatorio.status === 'concluido'"
              @click="visualizarRelatorio(relatorio)"
              class="btn-action view"
              title="Visualizar"
            >
              👁️ Ver
            </button>
            
            <button 
              @click="editarRelatorio(relatorio)"
              class="btn-action edit"
              title="Editar"
              :disabled="relatorio.status === 'gerando'"
            >
              ✏️ Editar
            </button>
            
            <button 
              v-if="relatorio.status === 'pendente' || relatorio.status === 'erro'"
              @click="gerarRelatorio(relatorio)"
              class="btn-action generate"
              title="Gerar Relatório"
            >
              ⚡ Gerar
            </button>
            
            <button 
              @click="excluirRelatorio(relatorio)"
              class="btn-action delete"
              title="Excluir"
              :disabled="relatorio.status === 'gerando'"
            >
              🗑️ Excluir
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Paginação -->
    <div v-if="totalPaginas > 1" class="paginacao">
      <button 
        @click="paginaAtual--" 
        :disabled="paginaAtual <= 1"
        class="btn-paginacao"
      >
        ‹ Anterior
      </button>
      
      <span class="pagina-info">
        Página {{ paginaAtual }} de {{ totalPaginas }}
      </span>
      
      <button 
        @click="paginaAtual++" 
        :disabled="paginaAtual >= totalPaginas"
        class="btn-paginacao"
      >
        Próxima ›
      </button>
    </div>

    <!-- Modal Novo/Editar Relatório -->
    <div v-if="showModal" class="modal-overlay" @click="fecharModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ relatorioEditando.id ? 'Editar Relatório' : 'Novo Relatório' }}</h3>
          <button @click="fecharModal" class="modal-close">×</button>
        </div>

        <div class="modal-body">
          <form @submit.prevent="salvarRelatorio">
            <div class="form-row">
              <div class="form-group">
                <label>📝 Título*</label>
                <input 
                  v-model="relatorioEditando.titulo" 
                  type="text" 
                  required
                  placeholder="Digite o título do relatório"
                >
              </div>
              
              <div class="form-group">
                <label>📊 Categoria*</label>
                <select v-model="relatorioEditando.categoria" required>
                  <option value="">Selecione...</option>
                  <option value="pesquisa_mercado">Pesquisa de Mercado</option>
                  <option value="cotacoes">Cotações</option>
                  <option value="comparativos">Comparativos</option>
                  <option value="analise_precos">Análise de Preços</option>
                  <option value="executivo">Executivo</option>
                </select>
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>📋 Tipo de Relatório*</label>
                <select v-model="relatorioEditando.tipo_relatorio" required>
                  <option value="">Selecione...</option>
                  <option value="consolidado">Consolidado</option>
                  <option value="analise_tecnica">Análise Técnica</option>
                  <option value="comparativo_precos">Comparativo de Preços</option>
                  <option value="executivo">Executivo</option>
                  <option value="custom">Personalizado</option>
                </select>
              </div>
              
              <div class="form-group">
                <label>📄 Formato de Saída</label>
                <select v-model="relatorioEditando.formato_saida">
                  <option value="pdf">PDF</option>
                  <option value="xlsx">Excel (XLSX)</option>
                  <option value="docx">Word (DOCX)</option>
                  <option value="csv">CSV</option>
                  <option value="html">HTML</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label>📝 Descrição</label>
              <textarea 
                v-model="relatorioEditando.descricao" 
                rows="3"
                placeholder="Descreva o objetivo e conteúdo do relatório"
              ></textarea>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>📅 Período - Início</label>
                <input 
                  v-model="relatorioEditando.periodo_dados_inicio" 
                  type="date"
                >
              </div>
              
              <div class="form-group">
                <label>📅 Período - Fim</label>
                <input 
                  v-model="relatorioEditando.periodo_dados_fim" 
                  type="date"
                >
              </div>
            </div>

            <div class="form-group">
              <label>🎯 Fonte Principal dos Dados</label>
              <select v-model="relatorioEditando.fonte_principal">
                <option value="">Selecione...</option>
                <option value="cotacoes">Cotações</option>
                <option value="comparativos">Comparativos</option>
                <option value="analises">Análises de Preços</option>
                <option value="manual">Entrada Manual</option>
                <option value="multiplas">Múltiplas Fontes</option>
              </select>
            </div>

            <div class="configuracoes-section">
              <h4>⚙️ Configurações de Geração</h4>
              <div class="checkbox-group">
                <label class="checkbox-item">
                  <input 
                    type="checkbox" 
                    v-model="relatorioEditando.incluir_graficos"
                  >
                  <span>📊 Incluir Gráficos</span>
                </label>
                
                <label class="checkbox-item">
                  <input 
                    type="checkbox" 
                    v-model="relatorioEditando.incluir_tabelas"
                  >
                  <span>📋 Incluir Tabelas</span>
                </label>
                
                <label class="checkbox-item">
                  <input 
                    type="checkbox" 
                    v-model="relatorioEditando.incluir_anexos"
                  >
                  <span>📎 Incluir Anexos</span>
                </label>
                
                <label class="checkbox-item">
                  <input 
                    type="checkbox" 
                    v-model="relatorioEditando.incluir_assinaturas"
                  >
                  <span>✍️ Incluir Assinaturas</span>
                </label>
              </div>
            </div>

            <div class="modal-actions">
              <button type="button" @click="fecharModal" class="btn-secondary">
                Cancelar
              </button>
              <button type="submit" class="btn-primary" :disabled="salvando">
                {{ salvando ? 'Salvando...' : 'Salvar Relatório' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase, getTenantId } from '@/services/supabase'

export default {
  name: 'GerenciadorRelatorios',
  data() {
    return {
      relatorios: [],
      loading: false,
      salvando: false,
      showModal: false,
      
      // Filtros
      filtros: {
        titulo: '',
        categoria: '',
        status: '',
        tipo_relatorio: ''
      },
      
      // Paginação
      paginaAtual: 1,
      itensPorPagina: 12,
      
      // Modal
      relatorioEditando: this.getRelatorioVazio(),
      
      // Estado
      erro: null
    }
  },
  
  computed: {
    totalRelatorios() {
      return this.relatorios.length
    },
    
    relatoriosPendentes() {
      return this.relatorios.filter(r => ['pendente', 'gerando'].includes(r.status)).length
    },
    
    relatoriosConcluidos() {
      return this.relatorios.filter(r => r.status === 'concluido').length
    },
    
    relatoriosFiltrados() {
      let filtrados = this.relatorios
      
      if (this.filtros.titulo) {
        filtrados = filtrados.filter(r => 
          r.titulo.toLowerCase().includes(this.filtros.titulo.toLowerCase())
        )
      }
      
      if (this.filtros.categoria) {
        filtrados = filtrados.filter(r => r.categoria === this.filtros.categoria)
      }
      
      if (this.filtros.status) {
        filtrados = filtrados.filter(r => r.status === this.filtros.status)
      }
      
      if (this.filtros.tipo_relatorio) {
        filtrados = filtrados.filter(r => r.tipo_relatorio === this.filtros.tipo_relatorio)
      }
      
      return filtrados.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    },
    
    totalPaginas() {
      return Math.ceil(this.relatoriosFiltrados.length / this.itensPorPagina)
    },
    
    relatoriosPaginados() {
      const inicio = (this.paginaAtual - 1) * this.itensPorPagina
      const fim = inicio + this.itensPorPagina
      return this.relatoriosFiltrados.slice(inicio, fim)
    }
  },
  
  async mounted() {
    await this.carregarRelatorios()
  },
  
  methods: {
    async carregarRelatorios() {
      this.loading = true
      this.erro = null
      
      try {
        const tenantId = getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const { data, error } = await supabase
          .from('relatorios')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', { ascending: false })
        
        if (error) throw error
        
        this.relatorios = data || []
      } catch (error) {
        console.error('Erro ao carregar relatórios:', error)
        this.erro = 'Erro ao carregar relatórios: ' + error.message
      } finally {
        this.loading = false
      }
    },
    
    aplicarFiltros() {
      this.paginaAtual = 1
    },
    
    limparFiltros() {
      this.filtros = {
        titulo: '',
        categoria: '',
        status: '',
        tipo_relatorio: ''
      }
      this.paginaAtual = 1
    },
    
    abrirModalNovoRelatorio() {
      this.relatorioEditando = this.getRelatorioVazio()
      this.showModal = true
    },
    
    editarRelatorio(relatorio) {
      this.relatorioEditando = { ...relatorio }
      this.showModal = true
    },
    
    fecharModal() {
      this.showModal = false
      this.relatorioEditando = this.getRelatorioVazio()
    },
    
    async salvarRelatorio() {
      this.salvando = true
      
      try {
        const tenantId = getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const dadosRelatorio = {
          ...this.relatorioEditando,
          tenant_id: tenantId,
          updated_at: new Date().toISOString()
        }
        
        if (this.relatorioEditando.id) {
          // Editar
          const { error } = await supabase
            .from('relatorios')
            .update(dadosRelatorio)
            .eq('id', this.relatorioEditando.id)
          
          if (error) throw error
        } else {
          // Criar novo
          dadosRelatorio.created_at = new Date().toISOString()
          
          const { error } = await supabase
            .from('relatorios')
            .insert([dadosRelatorio])
          
          if (error) throw error
        }
        
        await this.carregarRelatorios()
        this.fecharModal()
      } catch (error) {
        console.error('Erro ao salvar relatório:', error)
        alert('Erro ao salvar relatório: ' + error.message)
      } finally {
        this.salvando = false
      }
    },
    
    async excluirRelatorio(relatorio) {
      if (!confirm(`Tem certeza que deseja excluir o relatório "${relatorio.titulo}"?`)) {
        return
      }
      
      try {
        const { error } = await supabase
          .from('relatorios')
          .delete()
          .eq('id', relatorio.id)
        
        if (error) throw error
        
        await this.carregarRelatorios()
      } catch (error) {
        console.error('Erro ao excluir relatório:', error)
        alert('Erro ao excluir relatório: ' + error.message)
      }
    },
    
    async gerarRelatorio(relatorio) {
      try {
        const { error } = await supabase
          .from('relatorios')
          .update({ 
            status: 'gerando',
            progresso: 0,
            updated_at: new Date().toISOString()
          })
          .eq('id', relatorio.id)
        
        if (error) throw error
        
        // Simular processo de geração
        this.simularGeracaoRelatorio(relatorio.id)
        
        await this.carregarRelatorios()
      } catch (error) {
        console.error('Erro ao iniciar geração:', error)
        alert('Erro ao iniciar geração: ' + error.message)
      }
    },
    
    async simularGeracaoRelatorio(relatorioId) {
      // Simula o progresso de geração
      for (let progresso = 10; progresso <= 100; progresso += 10) {
        await new Promise(resolve => setTimeout(resolve, 500))
        
        await supabase
          .from('relatorios')
          .update({ 
            progresso,
            ...(progresso === 100 && {
              status: 'concluido',
              gerado_em: new Date().toISOString(),
              url_arquivo_principal: `#relatorio-${relatorioId}.pdf`
            })
          })
          .eq('id', relatorioId)
        
        if (progresso % 20 === 0) {
          await this.carregarRelatorios()
        }
      }
    },
    
    baixarRelatorio(relatorio) {
      // Simular download
      alert(`Download do relatório "${relatorio.titulo}" iniciado!`)
    },
    
    visualizarRelatorio(relatorio) {
      // Simular visualização
      alert(`Visualizando relatório "${relatorio.titulo}"`)
    },
    
    getRelatorioVazio() {
      return {
        titulo: '',
        descricao: '',
        categoria: '',
        tipo_relatorio: '',
        subtipo: 'detalhado',
        formato_saida: 'pdf',
        fonte_principal: '',
        periodo_dados_inicio: '',
        periodo_dados_fim: '',
        incluir_graficos: true,
        incluir_tabelas: true,
        incluir_anexos: false,
        incluir_assinaturas: true,
        status: 'pendente',
        progresso: 0
      }
    },
    
    getCategoriaLabel(categoria) {
      const labels = {
        pesquisa_mercado: 'Pesquisa de Mercado',
        cotacoes: 'Cotações',
        comparativos: 'Comparativos',
        analise_precos: 'Análise de Preços',
        executivo: 'Executivo'
      }
      return labels[categoria] || categoria
    },
    
    getStatusLabel(status) {
      const labels = {
        pendente: 'Pendente',
        gerando: 'Gerando',
        concluido: 'Concluído',
        erro: 'Erro',
        cancelado: 'Cancelado'
      }
      return labels[status] || status
    },
    
    getTipoLabel(tipo) {
      const labels = {
        consolidado: 'Consolidado',
        analise_tecnica: 'Análise Técnica',
        comparativo_precos: 'Comparativo de Preços',
        executivo: 'Executivo',
        custom: 'Personalizado'
      }
      return labels[tipo] || tipo
    },
    
    formatarData(data) {
      if (!data) return ''
      return new Date(data).toLocaleDateString('pt-BR')
    }
  }
}
</script>

<style scoped>
.gerenciador-relatorios {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.header-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 2px solid #e1e5e9;
}

.title-and-stats h2 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 24px;
}

.stats-mini {
  display: flex;
  gap: 20px;
}

.stat-item {
  font-size: 14px;
  color: #666;
}

.stat-item.pendentes {
  color: #f39c12;
}

.stat-item.concluidos {
  color: #27ae60;
}

.actions-header {
  display: flex;
  gap: 10px;
}

.btn-primary, .btn-secondary {
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  border: none;
  transition: all 0.2s;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover {
  background: #2980b9;
}

.btn-secondary {
  background: #95a5a6;
  color: white;
}

.btn-secondary:hover {
  background: #7f8c8d;
}

.filtros-section {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
}

.filtros-linha {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 15px;
}

.filtro-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filtro-group label {
  font-weight: 500;
  color: #2c3e50;
  font-size: 13px;
}

.filtro-group input,
.filtro-group select {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.relatorios-lista {
  min-height: 400px;
}

.loading-state,
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 15px;
}

.relatorios-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 20px;
}

.relatorio-card {
  background: white;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  padding: 15px;
  transition: all 0.2s;
  position: relative;
}

.relatorio-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.relatorio-card.status-gerando {
  border-left: 4px solid #f39c12;
}

.relatorio-card.status-concluido {
  border-left: 4px solid #27ae60;
}

.relatorio-card.status-erro {
  border-left: 4px solid #e74c3c;
}

.relatorio-card.status-pendente {
  border-left: 4px solid #95a5a6;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.titulo-e-categoria h4 {
  margin: 0 0 5px 0;
  color: #2c3e50;
  font-size: 16px;
  line-height: 1.3;
}

.categoria-badge {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 12px;
  font-weight: 500;
  color: white;
}

.categoria-badge.categoria-pesquisa_mercado {
  background: #3498db;
}

.categoria-badge.categoria-cotacoes {
  background: #9b59b6;
}

.categoria-badge.categoria-comparativos {
  background: #e67e22;
}

.categoria-badge.categoria-analise_precos {
  background: #2ecc71;
}

.categoria-badge.categoria-executivo {
  background: #34495e;
}

.status-badge {
  font-size: 11px;
  padding: 4px 8px;
  border-radius: 4px;
  font-weight: 500;
  color: white;
}

.status-badge.status-pendente {
  background: #95a5a6;
}

.status-badge.status-gerando {
  background: #f39c12;
}

.status-badge.status-concluido {
  background: #27ae60;
}

.status-badge.status-erro {
  background: #e74c3c;
}

.status-badge.status-cancelado {
  background: #7f8c8d;
}

.card-content {
  margin-bottom: 15px;
}

.info-linha {
  font-size: 13px;
  margin-bottom: 5px;
  color: #666;
}

.descricao {
  font-size: 13px;
  color: #666;
  margin: 8px 0;
  line-height: 1.4;
  max-height: 40px;
  overflow: hidden;
}

.progress-section {
  margin: 10px 0;
}

.progress-bar {
  background: #ecf0f1;
  border-radius: 10px;
  height: 6px;
  overflow: hidden;
  margin-bottom: 5px;
}

.progress-fill {
  background: #3498db;
  height: 100%;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 12px;
  color: #666;
}

.metadados {
  display: flex;
  flex-direction: column;
  gap: 3px;
  font-size: 12px;
  color: #666;
}

.card-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.btn-action {
  padding: 6px 10px;
  border: none;
  border-radius: 4px;
  font-size: 11px;
  cursor: pointer;
  transition: all 0.2s;
  flex: 1;
  min-width: fit-content;
}

.btn-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-action.download {
  background: #27ae60;
  color: white;
}

.btn-action.download:hover:not(:disabled) {
  background: #229954;
}

.btn-action.view {
  background: #3498db;
  color: white;
}

.btn-action.view:hover:not(:disabled) {
  background: #2980b9;
}

.btn-action.edit {
  background: #f39c12;
  color: white;
}

.btn-action.edit:hover:not(:disabled) {
  background: #e67e22;
}

.btn-action.generate {
  background: #9b59b6;
  color: white;
}

.btn-action.generate:hover:not(:disabled) {
  background: #8e44ad;
}

.btn-action.delete {
  background: #e74c3c;
  color: white;
}

.btn-action.delete:hover:not(:disabled) {
  background: #c0392b;
}

.paginacao {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #e1e5e9;
}

.btn-paginacao {
  padding: 8px 15px;
  border: 1px solid #ddd;
  background: white;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-paginacao:hover:not(:disabled) {
  background: #f8f9fa;
}

.btn-paginacao:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagina-info {
  font-size: 14px;
  color: #666;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 700px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #e1e5e9;
}

.modal-header h3 {
  margin: 0;
  color: #2c3e50;
}

.modal-close {
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

.modal-close:hover {
  color: #e74c3c;
}

.modal-body {
  padding: 20px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
  margin-bottom: 15px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.form-group label {
  font-weight: 500;
  color: #2c3e50;
  font-size: 14px;
}

.form-group input,
.form-group select,
.form-group textarea {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.configuracoes-section {
  margin: 20px 0;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
}

.configuracoes-section h4 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 16px;
}

.checkbox-group {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 14px;
}

.checkbox-item input[type="checkbox"] {
  margin: 0;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 25px;
  padding-top: 20px;
  border-top: 1px solid #e1e5e9;
}

@media (max-width: 768px) {
  .relatorios-grid {
    grid-template-columns: 1fr;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .filtros-linha {
    grid-template-columns: 1fr;
  }
  
  .checkbox-group {
    grid-template-columns: 1fr;
  }
  
  .card-actions {
    flex-direction: column;
  }
  
  .btn-action {
    flex: none;
  }
}
</style>