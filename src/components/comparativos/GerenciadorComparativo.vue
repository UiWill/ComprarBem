<template>
  <div class="gerenciador-comparativo">
    <!-- Cabeçalho com ações principais -->
    <div class="comparativo-header">
      <div class="header-info">
        <h4>📊 Gerenciamento de Comparativos Técnicos</h4>
        <p>Compare especificações técnicas, preços e condições de produtos similares para tomada de decisão fundamentada.</p>
      </div>
      
      <div class="header-actions">
        <button @click="abrirModalNovoComparativo" class="btn-primary">
          ➕ Novo Comparativo
        </button>
        <button @click="exportarComparativos" class="btn-secondary">
          📤 Exportar
        </button>
      </div>
    </div>

    <!-- Filtros e busca -->
    <div class="comparativo-filtros">
      <div class="filtros-row">
        <div class="filtro-group">
          <label>Buscar:</label>
          <input 
            v-model="filtros.busca" 
            type="text" 
            placeholder="Título, categoria ou descrição..."
            class="input-field"
          >
        </div>
        
        <div class="filtro-group">
          <label>Status:</label>
          <select v-model="filtros.status" class="select-field">
            <option value="">Todos</option>
            <option value="em_andamento">Em Andamento</option>
            <option value="finalizado">Finalizado</option>
            <option value="cancelado">Cancelado</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>Tipo:</label>
          <select v-model="filtros.tipo" class="select-field">
            <option value="">Todos</option>
            <option value="tecnico">Técnico</option>
            <option value="preco">Preço</option>
            <option value="completo">Completo</option>
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

    <!-- Loading -->
    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>Carregando comparativos...</p>
    </div>

    <!-- Lista de comparativos -->
    <div v-else class="comparativos-container">
      <!-- Estado vazio -->
      <div v-if="comparativosFiltrados.length === 0 && !temFiltrosAplicados" class="empty-state">
        <div class="empty-icon">📊</div>
        <h3>Nenhum comparativo registrado</h3>
        <p>Comece criando comparativos técnicos para análise detalhada de produtos e fornecedores.</p>
        <button @click="abrirModalNovoComparativo" class="btn-primary">
          ➕ Criar Primeiro Comparativo
        </button>
      </div>

      <!-- Nenhum resultado encontrado -->
      <div v-else-if="comparativosFiltrados.length === 0 && temFiltrosAplicados" class="empty-state">
        <div class="empty-icon">🔍</div>
        <h3>Nenhum comparativo encontrado</h3>
        <p>Nenhum comparativo corresponde aos filtros aplicados.</p>
        <button @click="limparFiltros" class="btn-secondary">
          🗑️ Limpar Filtros
        </button>
      </div>

      <!-- Grid de comparativos -->
      <div v-else class="comparativos-grid">
        <div 
          v-for="comparativo in comparativosFiltrados" 
          :key="comparativo.id"
          class="comparativo-card"
          :class="{ 
            'finalizado': comparativo.status === 'finalizado',
            'cancelado': comparativo.status === 'cancelado',
            'vencido': isComparativoVencido(comparativo)
          }"
        >
          <!-- Cabeçalho do comparativo -->
          <div class="comparativo-header-card">
            <div class="comparativo-info">
              <h5>{{ comparativo.titulo }}</h5>
              <div class="comparativo-meta">
                <span class="categoria">{{ comparativo.categoria || 'Sem categoria' }}</span>
                <span class="data">{{ formatDate(comparativo.data_inicio) }}</span>
                <span class="status" :class="comparativo.status">{{ getStatusLabel(comparativo.status) }}</span>
              </div>
            </div>
            <div class="comparativo-stats">
              <div class="stat">
                <span class="number">{{ getItensCount(comparativo.id) }}</span>
                <span class="label">Itens</span>
              </div>
            </div>
          </div>

          <!-- Corpo do comparativo -->
          <div class="comparativo-body">
            <div class="comparativo-desc">
              <p v-if="comparativo.descricao">{{ truncateText(comparativo.descricao, 100) }}</p>
              <p v-else class="sem-descricao">Sem descrição</p>
            </div>
            
            <div class="comparativo-detalhes">
              <div class="detalhe">
                <strong>Tipo:</strong> {{ getTipoLabel(comparativo.tipo_comparativo) }}
              </div>
              <div class="detalhe" v-if="comparativo.prazo_resposta">
                <strong>Prazo:</strong> {{ formatDate(comparativo.prazo_resposta) }}
              </div>
              <div class="detalhe" v-if="comparativo.metodologia">
                <strong>Metodologia:</strong> {{ getMetodologiaLabel(comparativo.metodologia) }}
              </div>
            </div>
          </div>

          <!-- Ações do comparativo -->
          <div class="comparativo-actions">
            <button @click="visualizarComparativo(comparativo)" class="btn-small">👁️ Ver</button>
            <button @click="editarComparativo(comparativo)" class="btn-small">✏️ Editar</button>
            <button @click="gerenciarItens(comparativo)" class="btn-small">📋 Itens</button>
            <button 
              v-if="comparativo.status === 'em_andamento'" 
              @click="finalizarComparativo(comparativo)" 
              class="btn-small btn-success"
            >
              ✅ Finalizar
            </button>
            <button @click="duplicarComparativo(comparativo)" class="btn-small">📋 Duplicar</button>
            <button @click="removerComparativo(comparativo)" class="btn-small btn-danger">🗑️ Remover</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Novo/Editar Comparativo -->
    <div v-if="modalComparativo.show" class="modal-overlay" @click="fecharModalComparativo">
      <div class="modal-content large" @click.stop>
        <div class="modal-header">
          <h3>{{ modalComparativo.editando ? '✏️ Editar Comparativo' : '➕ Novo Comparativo' }}</h3>
          <button @click="fecharModalComparativo" class="btn-close">✕</button>
        </div>
        
        <div class="modal-body">
          <form @submit.prevent="salvarComparativo" class="form-comparativo">
            <!-- Dados Básicos -->
            <fieldset class="form-section">
              <legend>📋 Dados Básicos</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Título do Comparativo*</label>
                  <input 
                    v-model="comparativoForm.titulo" 
                    type="text" 
                    required 
                    class="input-field"
                    placeholder="Ex: Comparativo Notebooks Dell vs HP"
                  >
                </div>
                <div class="form-group">
                  <label>Categoria</label>
                  <input 
                    v-model="comparativoForm.categoria" 
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
                    v-model="comparativoForm.descricao" 
                    class="textarea-field"
                    rows="3"
                    placeholder="Descreva o objetivo e escopo do comparativo..."
                  ></textarea>
                </div>
              </div>
            </fieldset>

            <!-- Configurações -->
            <fieldset class="form-section">
              <legend>⚙️ Configurações</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Tipo de Comparativo*</label>
                  <select v-model="comparativoForm.tipo_comparativo" required class="select-field">
                    <option value="tecnico">Técnico</option>
                    <option value="preco">Preço</option>
                    <option value="completo">Completo</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Metodologia</label>
                  <select v-model="comparativoForm.metodologia" class="select-field">
                    <option value="matriz_decisao">Matriz de Decisão</option>
                    <option value="ranking">Ranking Ponderado</option>
                    <option value="pontuacao">Sistema de Pontuação</option>
                  </select>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>Data de Início</label>
                  <input 
                    v-model="comparativoForm.data_inicio" 
                    type="date" 
                    class="input-field"
                  >
                </div>
                <div class="form-group">
                  <label>Prazo para Respostas</label>
                  <input 
                    v-model="comparativoForm.prazo_resposta" 
                    type="date" 
                    class="input-field"
                  >
                </div>
              </div>
            </fieldset>
          </form>
        </div>
        
        <div class="modal-footer">
          <button @click="fecharModalComparativo" class="btn-secondary">Cancelar</button>
          <button @click="salvarComparativo" class="btn-primary" :disabled="salvandoComparativo">
            {{ salvandoComparativo ? 'Salvando...' : 'Salvar Comparativo' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Gerenciar Itens -->
    <div v-if="modalItens.show" class="modal-overlay" @click="fecharModalItens">
      <div class="modal-content extra-large" @click.stop>
        <div class="modal-header">
          <h3>📋 Gerenciar Itens - {{ modalItens.comparativo?.titulo }}</h3>
          <button @click="fecharModalItens" class="btn-close">✕</button>
        </div>
        
        <div class="modal-body">
          <div class="itens-actions">
            <button @click="adicionarItem" class="btn-primary">
              ➕ Adicionar Item
            </button>
            <button @click="importarDeCotacoes" class="btn-secondary">
              📥 Importar de Cotações
            </button>
          </div>
          
          <div class="itens-lista">
            <div v-if="itensComparativo.length === 0" class="empty-state-small">
              <p>Nenhum item adicionado ao comparativo</p>
            </div>
            
            <div v-else class="itens-grid">
              <div 
                v-for="item in itensComparativo" 
                :key="item.id"
                class="item-card"
              >
                <div class="item-header">
                  <h6>{{ item.produto_nome }}</h6>
                  <span class="fornecedor">{{ item.fornecedor_nome }}</span>
                </div>
                
                <div class="item-body">
                  <div class="item-preco" v-if="item.preco_unitario">
                    {{ formatCurrency(item.preco_unitario) }}
                  </div>
                  <div class="item-pontuacao" v-if="item.pontuacao_final">
                    <span class="pontuacao">{{ item.pontuacao_final }}pts</span>
                    <span class="ranking" v-if="item.posicao_ranking">#{{ item.posicao_ranking }}</span>
                  </div>
                </div>
                
                <div class="item-actions">
                  <button @click="editarItem(item)" class="btn-mini">✏️</button>
                  <button @click="removerItem(item)" class="btn-mini btn-danger">🗑️</button>
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
  name: 'GerenciadorComparativo',
  data() {
    return {
      comparativos: [],
      itensComparativo: [],
      loading: false,
      salvandoComparativo: false,
      
      // Filtros
      filtros: {
        busca: '',
        status: '',
        tipo: '',
        dataInicio: '',
        dataFim: ''
      },
      
      // Modal Novo/Editar Comparativo
      modalComparativo: {
        show: false,
        editando: false
      },
      
      // Modal Gerenciar Itens
      modalItens: {
        show: false,
        comparativo: null
      },
      
      // Formulário de comparativo
      comparativoForm: {
        id: null,
        titulo: '',
        descricao: '',
        categoria: '',
        tipo_comparativo: 'tecnico',
        metodologia: 'matriz_decisao',
        data_inicio: '',
        prazo_resposta: ''
      }
    }
  },
  
  computed: {
    comparativosFiltrados() {
      let resultado = [...this.comparativos]
      
      // Filtro de busca
      if (this.filtros.busca) {
        const busca = this.filtros.busca.toLowerCase()
        resultado = resultado.filter(comp => 
          comp.titulo.toLowerCase().includes(busca) ||
          (comp.categoria && comp.categoria.toLowerCase().includes(busca)) ||
          (comp.descricao && comp.descricao.toLowerCase().includes(busca))
        )
      }
      
      // Filtro de status
      if (this.filtros.status) {
        resultado = resultado.filter(comp => comp.status === this.filtros.status)
      }
      
      // Filtro de tipo
      if (this.filtros.tipo) {
        resultado = resultado.filter(comp => comp.tipo_comparativo === this.filtros.tipo)
      }
      
      // Filtro de data
      if (this.filtros.dataInicio) {
        resultado = resultado.filter(comp => comp.data_inicio >= this.filtros.dataInicio)
      }
      
      if (this.filtros.dataFim) {
        resultado = resultado.filter(comp => comp.data_inicio <= this.filtros.dataFim)
      }
      
      return resultado.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    },
    
    temFiltrosAplicados() {
      return this.filtros.busca || this.filtros.status || this.filtros.tipo || this.filtros.dataInicio || this.filtros.dataFim
    }
  },
  
  async mounted() {
    await this.carregarComparativos()
  },
  
  methods: {
    async carregarComparativos() {
      this.loading = true
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const { data, error } = await supabase
          .from('comparativos')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', { ascending: false })
        
        if (error) throw error
        
        this.comparativos = data || []
      } catch (error) {
        console.error('Erro ao carregar comparativos:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao carregar comparativos: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.loading = false
      }
    },
    
    // Modais
    abrirModalNovoComparativo() {
      this.modalComparativo.show = true
      this.modalComparativo.editando = false
      this.resetarFormulario()
    },
    
    fecharModalComparativo() {
      this.modalComparativo.show = false
      this.resetarFormulario()
    },
    
    fecharModalItens() {
      this.modalItens.show = false
      this.modalItens.comparativo = null
      this.itensComparativo = []
    },
    
    resetarFormulario() {
      this.comparativoForm = {
        id: null,
        titulo: '',
        descricao: '',
        categoria: '',
        tipo_comparativo: 'tecnico',
        metodologia: 'matriz_decisao',
        data_inicio: new Date().toISOString().split('T')[0],
        prazo_resposta: ''
      }
    },
    
    // CRUD
    async salvarComparativo() {
      this.salvandoComparativo = true
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const comparativoData = {
          ...this.comparativoForm,
          tenant_id: tenantId
        }
        
        if (this.modalComparativo.editando) {
          const { error } = await supabase
            .from('comparativos')
            .update(comparativoData)
            .eq('id', this.comparativoForm.id)
          
          if (error) throw error
        } else {
          delete comparativoData.id
          const { error } = await supabase
            .from('comparativos')
            .insert([comparativoData])
          
          if (error) throw error
        }
        
        this.$swal({
          title: 'Sucesso!',
          text: `Comparativo ${this.modalComparativo.editando ? 'atualizado' : 'criado'} com sucesso`,
          icon: 'success',
          timer: 2000
        })
        
        await this.carregarComparativos()
        this.fecharModalComparativo()
        
      } catch (error) {
        console.error('Erro ao salvar comparativo:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao salvar comparativo: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.salvandoComparativo = false
      }
    },
    
    editarComparativo(comparativo) {
      this.comparativoForm = { ...comparativo }
      this.modalComparativo.show = true
      this.modalComparativo.editando = true
    },
    
    async removerComparativo(comparativo) {
      const confirm = await this.$swal({
        title: 'Confirmar exclusão',
        text: `Deseja realmente remover o comparativo "${comparativo.titulo}"?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sim, remover',
        cancelButtonText: 'Cancelar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('comparativos')
            .delete()
            .eq('id', comparativo.id)
          
          if (error) throw error
          
          this.$swal({
            title: 'Removido!',
            text: 'Comparativo removido com sucesso',
            icon: 'success',
            timer: 2000
          })
          
          await this.carregarComparativos()
        } catch (error) {
          console.error('Erro ao remover comparativo:', error)
          this.$swal({
            title: 'Erro',
            text: 'Erro ao remover comparativo: ' + error.message,
            icon: 'error'
          })
        }
      }
    },
    
    // Ações específicas
    visualizarComparativo(comparativo) {
      this.$swal({
        title: `📊 ${comparativo.titulo}`,
        html: `
          <div style="text-align: left; margin: 20px 0;">
            <h4>📋 Informações Básicas</h4>
            <p><strong>Categoria:</strong> ${comparativo.categoria || 'Não informada'}</p>
            <p><strong>Tipo:</strong> ${this.getTipoLabel(comparativo.tipo_comparativo)}</p>
            <p><strong>Status:</strong> ${this.getStatusLabel(comparativo.status)}</p>
            <p><strong>Metodologia:</strong> ${this.getMetodologiaLabel(comparativo.metodologia)}</p>
            
            ${comparativo.descricao ? `<h4>📝 Descrição</h4><p>${comparativo.descricao}</p>` : ''}
            
            <h4>📅 Datas</h4>
            <p><strong>Início:</strong> ${this.formatDate(comparativo.data_inicio)}</p>
            ${comparativo.prazo_resposta ? `<p><strong>Prazo:</strong> ${this.formatDate(comparativo.prazo_resposta)}</p>` : ''}
            ${comparativo.data_conclusao ? `<p><strong>Conclusão:</strong> ${this.formatDate(comparativo.data_conclusao)}</p>` : ''}
          </div>
        `,
        width: '600px',
        confirmButtonText: 'Fechar'
      })
    },
    
    duplicarComparativo(comparativo) {
      this.comparativoForm = {
        ...comparativo,
        id: null,
        titulo: comparativo.titulo + ' (Cópia)',
        status: 'em_andamento'
      }
      this.modalComparativo.show = true
      this.modalComparativo.editando = false
    },
    
    async finalizarComparativo(comparativo) {
      const confirm = await this.$swal({
        title: 'Finalizar Comparativo',
        text: `Deseja finalizar o comparativo "${comparativo.titulo}"?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Sim, finalizar',
        cancelButtonText: 'Cancelar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('comparativos')
            .update({ 
              status: 'finalizado',
              data_conclusao: new Date().toISOString().split('T')[0]
            })
            .eq('id', comparativo.id)
          
          if (error) throw error
          
          this.$swal({
            title: 'Finalizado!',
            text: 'Comparativo finalizado com sucesso',
            icon: 'success',
            timer: 2000
          })
          
          await this.carregarComparativos()
        } catch (error) {
          console.error('Erro ao finalizar comparativo:', error)
          this.$swal({
            title: 'Erro',
            text: 'Erro ao finalizar comparativo: ' + error.message,
            icon: 'error'
          })
        }
      }
    },
    
    // Gerenciamento de Itens
    async gerenciarItens(comparativo) {
      this.modalItens.show = true
      this.modalItens.comparativo = comparativo
      await this.carregarItensComparativo(comparativo.id)
    },
    
    async carregarItensComparativo(comparativoId) {
      try {
        const { data, error } = await supabase
          .from('comparativos_itens')
          .select('*')
          .eq('comparativo_id', comparativoId)
          .order('posicao_ranking', { ascending: true })
        
        if (error) throw error
        
        this.itensComparativo = data || []
      } catch (error) {
        console.error('Erro ao carregar itens:', error)
      }
    },
    
    adicionarItem() {
      this.$swal({
        title: '➕ Adicionar Item',
        text: 'Funcionalidade em desenvolvimento - Adicionar item ao comparativo',
        icon: 'info'
      })
    },
    
    editarItem(item) {
      this.$swal({
        title: '✏️ Editar Item',
        text: 'Funcionalidade em desenvolvimento - Editar item do comparativo',
        icon: 'info'
      })
    },
    
    async removerItem(item) {
      const confirm = await this.$swal({
        title: 'Confirmar exclusão',
        text: `Deseja remover "${item.produto_nome}" do comparativo?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sim, remover',
        cancelButtonText: 'Cancelar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('comparativos_itens')
            .delete()
            .eq('id', item.id)
          
          if (error) throw error
          
          await this.carregarItensComparativo(this.modalItens.comparativo.id)
          
          this.$swal({
            title: 'Removido!',
            text: 'Item removido do comparativo',
            icon: 'success',
            timer: 2000
          })
        } catch (error) {
          console.error('Erro ao remover item:', error)
          this.$swal({
            title: 'Erro',
            text: 'Erro ao remover item: ' + error.message,
            icon: 'error'
          })
        }
      }
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
    
    importarDeCotacoes() {
      this.$swal({
        title: '📥 Importar de Cotações',
        text: 'Funcionalidade em desenvolvimento - Importar cotações para este comparativo',
        icon: 'info'
      })
    },
    
    async exportarComparativos() {
      try {
        if (this.comparativosFiltrados.length === 0) {
          this.$swal({
            title: 'Atenção',
            text: 'Não há comparativos para exportar com os filtros aplicados.',
            icon: 'warning'
          })
          return
        }

        // Perguntar formato de exportação
        const { value: formato } = await this.$swal({
          title: '📤 Exportar Comparativos',
          text: `Exportar ${this.comparativosFiltrados.length} comparativo(s). Escolha o formato:`,
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
        const { exportComparativos } = await import('@/services/exportService')
        
        // Exportar
        const tipoExport = formato ? 'excel' : 'csv'
        await exportComparativos(this.comparativosFiltrados, tipoExport)
        
        this.$swal({
          title: 'Sucesso!',
          text: `${this.comparativosFiltrados.length} comparativo(s) exportado(s) com sucesso!`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao exportar comparativos:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao exportar comparativos: ' + error.message,
          icon: 'error'
        })
      }
    },
    
    // Utilitários
    getItensCount(comparativoId) {
      // Implementar contagem real de itens
      return Math.floor(Math.random() * 5) + 1
    },
    
    isComparativoVencido(comparativo) {
      if (!comparativo.prazo_resposta) return false
      return new Date(comparativo.prazo_resposta) < new Date()
    },
    
    truncateText(text, maxLength) {
      if (!text) return ''
      return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
    },
    
    // Formatação
    formatDate(date) {
      if (!date) return ''
      return new Date(date).toLocaleDateString('pt-BR')
    },
    
    formatCurrency(value) {
      if (!value) return 'R$ 0,00'
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
      }).format(value)
    },
    
    getStatusLabel(status) {
      const labels = {
        'em_andamento': 'Em Andamento',
        'finalizado': 'Finalizado',
        'cancelado': 'Cancelado'
      }
      return labels[status] || status
    },
    
    getTipoLabel(tipo) {
      const labels = {
        'tecnico': 'Técnico',
        'preco': 'Preço',
        'completo': 'Completo'
      }
      return labels[tipo] || tipo
    },
    
    getMetodologiaLabel(metodologia) {
      const labels = {
        'matriz_decisao': 'Matriz de Decisão',
        'ranking': 'Ranking Ponderado',
        'pontuacao': 'Sistema de Pontuação'
      }
      return labels[metodologia] || metodologia
    }
  }
}
</script>

<style scoped>
@import './GerenciadorComparativo.css';
</style>