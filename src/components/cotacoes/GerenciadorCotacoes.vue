<template>
  <div class="gerenciador-cotacoes">
    <!-- Cabeçalho com ações principais -->
    <div class="cotacoes-header">
      <div class="header-info">
        <h4>💰 Gerenciamento de Cotações</h4>
        <p>Registre e gerencie cotações de fornecedores para análise de preços e tomada de decisão.</p>
      </div>
      
      <div class="header-actions">
        <button @click="abrirModalNovaCotacao" class="btn-primary">
          ➕ Nova Cotação
        </button>
        <button @click="exportarCotacoes" class="btn-secondary">
          📤 Exportar
        </button>
      </div>
    </div>

    <!-- Filtros e busca -->
    <div class="cotacoes-filtros">
      <div class="filtros-row">
        <div class="filtro-group">
          <label>Buscar:</label>
          <input 
            v-model="filtros.busca" 
            type="text" 
            placeholder="Produto, fornecedor ou CNPJ..."
            class="input-field"
          >
        </div>
        
        <div class="filtro-group">
          <label>Status:</label>
          <select v-model="filtros.status" class="select-field">
            <option value="">Todos</option>
            <option value="ativa">Ativa</option>
            <option value="vencida">Vencida</option>
            <option value="aceita">Aceita</option>
            <option value="cancelada">Cancelada</option>
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
      <p>Carregando cotações...</p>
    </div>

    <!-- Lista de cotações -->
    <div v-else class="cotacoes-container">
      <!-- Estado vazio -->
      <div v-if="cotacoesFiltradas.length === 0 && !temFiltrosAplicados" class="empty-state">
        <div class="empty-icon">💰</div>
        <h3>Nenhuma cotação registrada</h3>
        <p>Comece registrando cotações de fornecedores para análise de preços.</p>
        <button @click="abrirModalNovaCotacao" class="btn-primary">
          ➕ Registrar Primeira Cotação
        </button>
      </div>

      <!-- Nenhum resultado encontrado -->
      <div v-else-if="cotacoesFiltradas.length === 0 && temFiltrosAplicados" class="empty-state">
        <div class="empty-icon">🔍</div>
        <h3>Nenhuma cotação encontrada</h3>
        <p>Nenhuma cotação corresponde aos filtros aplicados.</p>
        <button @click="limparFiltros" class="btn-secondary">
          🗑️ Limpar Filtros
        </button>
      </div>

      <!-- Grid de cotações -->
      <div v-else class="cotacoes-grid">
        <div 
          v-for="cotacao in cotacoesFiltradas" 
          :key="cotacao.id"
          class="cotacao-card"
          :class="{ 'vencida': isCotacaoVencida(cotacao), 'aceita': cotacao.status === 'aceita' }"
        >
          <!-- Cabeçalho da cotação -->
          <div class="cotacao-header">
            <div class="cotacao-info">
              <h5>{{ cotacao.produto_nome }}</h5>
              <div class="cotacao-meta">
                <span class="data">{{ formatDate(cotacao.data_cotacao) }}</span>
                <span class="status" :class="cotacao.status">{{ getStatusLabel(cotacao.status) }}</span>
              </div>
            </div>
            <div class="cotacao-preco">
              <div class="preco-unitario">{{ formatCurrency(cotacao.preco_unitario) }}</div>
              <div class="preco-total" v-if="cotacao.preco_total">
                Total: {{ formatCurrency(cotacao.preco_total) }}
              </div>
            </div>
          </div>

          <!-- Detalhes da cotação -->
          <div class="cotacao-body">
            <div class="fornecedor-info">
              <p><strong>Fornecedor:</strong> {{ cotacao.fornecedor_nome }}</p>
              <p v-if="cotacao.fornecedor_cnpj"><strong>CNPJ:</strong> {{ formatCNPJ(cotacao.fornecedor_cnpj) }}</p>
              <p v-if="cotacao.quantidade"><strong>Quantidade:</strong> {{ cotacao.quantidade }} {{ cotacao.unidade_medida }}</p>
            </div>
            
            <div class="condicoes-info">
              <p v-if="cotacao.prazo_entrega"><strong>Prazo:</strong> {{ cotacao.prazo_entrega }} dias</p>
              <p v-if="cotacao.data_validade"><strong>Válida até:</strong> {{ formatDate(cotacao.data_validade) }}</p>
              <p v-if="cotacao.condicoes_pagamento"><strong>Pagamento:</strong> {{ cotacao.condicoes_pagamento }}</p>
            </div>
          </div>

          <!-- Ações da cotação -->
          <div class="cotacao-actions">
            <button @click="visualizarCotacao(cotacao)" class="btn-small">👁️ Ver</button>
            <button @click="editarCotacao(cotacao)" class="btn-small">✏️ Editar</button>
            <button @click="duplicarCotacao(cotacao)" class="btn-small">📋 Duplicar</button>
            <button 
              v-if="cotacao.status === 'ativa'" 
              @click="aceitarCotacao(cotacao)" 
              class="btn-small btn-success"
            >
              ✅ Aceitar
            </button>
            <button @click="removerCotacao(cotacao)" class="btn-small btn-danger">🗑️ Remover</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Nova/Editar Cotação -->
    <div v-if="modalCotacao.show" class="modal-overlay" @click="fecharModalCotacao">
      <div class="modal-content large" @click.stop>
        <div class="modal-header">
          <h3>{{ modalCotacao.editando ? '✏️ Editar Cotação' : '➕ Nova Cotação' }}</h3>
          <button @click="fecharModalCotacao" class="btn-close">✕</button>
        </div>
        
        <div class="modal-body">
          <form @submit.prevent="salvarCotacao" class="form-cotacao">
            <!-- Dados do Produto -->
            <fieldset class="form-section">
              <legend>📦 Dados do Produto</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Nome do Produto*</label>
                  <input 
                    v-model="cotacaoForm.produto_nome" 
                    type="text" 
                    required 
                    class="input-field"
                    placeholder="Ex: Notebook Dell Inspiron 15"
                  >
                </div>
                <div class="form-group">
                  <label>Unidade</label>
                  <select v-model="cotacaoForm.unidade_medida" class="select-field">
                    <option value="UN">Unidade</option>
                    <option value="CX">Caixa</option>
                    <option value="KG">Quilograma</option>
                    <option value="LT">Litro</option>
                    <option value="MT">Metro</option>
                    <option value="M2">Metro²</option>
                    <option value="M3">Metro³</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Quantidade</label>
                  <input 
                    v-model.number="cotacaoForm.quantidade" 
                    type="number" 
                    min="0" 
                    step="0.01"
                    class="input-field"
                  >
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group full-width">
                  <label>Descrição</label>
                  <textarea 
                    v-model="cotacaoForm.produto_descricao" 
                    class="textarea-field"
                    rows="2"
                    placeholder="Descrição detalhada do produto..."
                  ></textarea>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group full-width">
                  <label>Especificação Técnica</label>
                  <textarea 
                    v-model="cotacaoForm.produto_especificacao" 
                    class="textarea-field"
                    rows="3"
                    placeholder="Especificações técnicas detalhadas..."
                  ></textarea>
                </div>
              </div>
            </fieldset>

            <!-- Dados do Fornecedor -->
            <fieldset class="form-section">
              <legend>🏢 Dados do Fornecedor</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Nome do Fornecedor*</label>
                  <input 
                    v-model="cotacaoForm.fornecedor_nome" 
                    type="text" 
                    required 
                    class="input-field"
                    placeholder="Ex: Dell Computadores do Brasil Ltda"
                  >
                </div>
                <div class="form-group">
                  <label>CNPJ</label>
                  <input 
                    v-model="cotacaoForm.fornecedor_cnpj" 
                    type="text" 
                    class="input-field"
                    placeholder="00.000.000/0000-00"
                    @input="formatarCNPJ"
                  >
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>Contato</label>
                  <input 
                    v-model="cotacaoForm.fornecedor_contato" 
                    type="text" 
                    class="input-field"
                    placeholder="Nome do contato"
                  >
                </div>
                <div class="form-group">
                  <label>Telefone</label>
                  <input 
                    v-model="cotacaoForm.fornecedor_telefone" 
                    type="text" 
                    class="input-field"
                    placeholder="(00) 0000-0000"
                  >
                </div>
                <div class="form-group">
                  <label>E-mail</label>
                  <input 
                    v-model="cotacaoForm.fornecedor_email" 
                    type="email" 
                    class="input-field"
                    placeholder="contato@fornecedor.com"
                  >
                </div>
              </div>
            </fieldset>

            <!-- Dados Comerciais -->
            <fieldset class="form-section">
              <legend>💰 Dados Comerciais</legend>
              <div class="form-row">
                <div class="form-group">
                  <label>Preço Unitário*</label>
                  <input 
                    v-model.number="cotacaoForm.preco_unitario" 
                    type="number" 
                    min="0" 
                    step="0.01"
                    required 
                    class="input-field"
                    placeholder="0,00"
                  >
                </div>
                <div class="form-group">
                  <label>Prazo Entrega (dias)</label>
                  <input 
                    v-model.number="cotacaoForm.prazo_entrega" 
                    type="number" 
                    min="0"
                    class="input-field"
                    placeholder="Ex: 15"
                  >
                </div>
                <div class="form-group">
                  <label>Validade (dias)</label>
                  <input 
                    v-model.number="cotacaoForm.validade_cotacao" 
                    type="number" 
                    min="1"
                    class="input-field"
                    placeholder="30"
                  >
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group full-width">
                  <label>Condições de Pagamento</label>
                  <textarea 
                    v-model="cotacaoForm.condicoes_pagamento" 
                    class="textarea-field"
                    rows="2"
                    placeholder="Ex: 30 dias após entrega, PIX com 5% desconto..."
                  ></textarea>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group full-width">
                  <label>Observações</label>
                  <textarea 
                    v-model="cotacaoForm.observacoes" 
                    class="textarea-field"
                    rows="3"
                    placeholder="Observações adicionais, garantias, condições especiais..."
                  ></textarea>
                </div>
              </div>
            </fieldset>
          </form>
        </div>
        
        <div class="modal-footer">
          <button @click="fecharModalCotacao" class="btn-secondary">Cancelar</button>
          <button @click="salvarCotacao" class="btn-primary" :disabled="salvandoCotacao">
            {{ salvandoCotacao ? 'Salvando...' : 'Salvar Cotação' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { supabase, getTenantId } from '@/services/supabase'

export default {
  name: 'GerenciadorCotacoes',
  data() {
    return {
      cotacoes: [],
      loading: false,
      salvandoCotacao: false,
      
      // Filtros
      filtros: {
        busca: '',
        status: '',
        dataInicio: '',
        dataFim: ''
      },
      
      // Modal Nova/Editar Cotação
      modalCotacao: {
        show: false,
        editando: false
      },
      
      
      // Formulário de cotação
      cotacaoForm: {
        id: null,
        produto_nome: '',
        produto_descricao: '',
        produto_especificacao: '',
        unidade_medida: 'UN',
        quantidade: null,
        fornecedor_nome: '',
        fornecedor_cnpj: '',
        fornecedor_contato: '',
        fornecedor_telefone: '',
        fornecedor_email: '',
        preco_unitario: null,
        prazo_entrega: null,
        validade_cotacao: 30,
        condicoes_pagamento: '',
        observacoes: ''
      }
    }
  },
  
  computed: {
    cotacoesFiltradas() {
      let resultado = [...this.cotacoes]
      
      // Filtro de busca
      if (this.filtros.busca) {
        const busca = this.filtros.busca.toLowerCase()
        resultado = resultado.filter(cotacao => 
          cotacao.produto_nome.toLowerCase().includes(busca) ||
          cotacao.fornecedor_nome.toLowerCase().includes(busca) ||
          (cotacao.fornecedor_cnpj && cotacao.fornecedor_cnpj.includes(busca))
        )
      }
      
      // Filtro de status
      if (this.filtros.status) {
        resultado = resultado.filter(cotacao => cotacao.status === this.filtros.status)
      }
      
      // Filtro de data
      if (this.filtros.dataInicio) {
        resultado = resultado.filter(cotacao => cotacao.data_cotacao >= this.filtros.dataInicio)
      }
      
      if (this.filtros.dataFim) {
        resultado = resultado.filter(cotacao => cotacao.data_cotacao <= this.filtros.dataFim)
      }
      
      return resultado.sort((a, b) => new Date(b.data_cotacao) - new Date(a.data_cotacao))
    },
    
    temFiltrosAplicados() {
      return this.filtros.busca || this.filtros.status || this.filtros.dataInicio || this.filtros.dataFim
    }
  },
  
  async mounted() {
    await this.carregarCotacoes()
  },
  
  methods: {
    async carregarCotacoes() {
      this.loading = true
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const { data, error } = await supabase
          .from('cotacoes')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', { ascending: false })
        
        if (error) throw error
        
        this.cotacoes = data || []
      } catch (error) {
        console.error('Erro ao carregar cotações:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao carregar cotações: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.loading = false
      }
    },
    
    // Modais
    abrirModalNovaCotacao() {
      this.modalCotacao.show = true
      this.modalCotacao.editando = false
      this.resetarFormulario()
    },
    
    fecharModalCotacao() {
      this.modalCotacao.show = false
      this.resetarFormulario()
    },
    
    resetarFormulario() {
      this.cotacaoForm = {
        id: null,
        produto_nome: '',
        produto_descricao: '',
        produto_especificacao: '',
        unidade_medida: 'UN',
        quantidade: null,
        fornecedor_nome: '',
        fornecedor_cnpj: '',
        fornecedor_contato: '',
        fornecedor_telefone: '',
        fornecedor_email: '',
        preco_unitario: null,
        prazo_entrega: null,
        validade_cotacao: 30,
        condicoes_pagamento: '',
        observacoes: ''
      }
    },
    
    // CRUD
    async salvarCotacao() {
      this.salvandoCotacao = true
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const cotacaoData = {
          ...this.cotacaoForm,
          tenant_id: tenantId
        }
        
        if (this.modalCotacao.editando) {
          const { error } = await supabase
            .from('cotacoes')
            .update(cotacaoData)
            .eq('id', this.cotacaoForm.id)
          
          if (error) throw error
        } else {
          delete cotacaoData.id
          const { error } = await supabase
            .from('cotacoes')
            .insert([cotacaoData])
          
          if (error) throw error
        }
        
        this.$swal({
          title: 'Sucesso!',
          text: `Cotação ${this.modalCotacao.editando ? 'atualizada' : 'registrada'} com sucesso`,
          icon: 'success',
          timer: 2000
        })
        
        await this.carregarCotacoes()
        this.fecharModalCotacao()
        
      } catch (error) {
        console.error('Erro ao salvar cotação:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao salvar cotação: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.salvandoCotacao = false
      }
    },
    
    editarCotacao(cotacao) {
      this.cotacaoForm = { ...cotacao }
      this.modalCotacao.show = true
      this.modalCotacao.editando = true
    },
    
    async removerCotacao(cotacao) {
      const confirm = await this.$swal({
        title: 'Confirmar exclusão',
        text: `Deseja realmente remover a cotação de "${cotacao.produto_nome}"?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sim, remover',
        cancelButtonText: 'Cancelar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('cotacoes')
            .delete()
            .eq('id', cotacao.id)
          
          if (error) throw error
          
          this.$swal({
            title: 'Removida!',
            text: 'Cotação removida com sucesso',
            icon: 'success',
            timer: 2000
          })
          
          await this.carregarCotacoes()
        } catch (error) {
          console.error('Erro ao remover cotação:', error)
          this.$swal({
            title: 'Erro',
            text: 'Erro ao remover cotação: ' + error.message,
            icon: 'error'
          })
        }
      }
    },
    
    // Ações específicas
    visualizarCotacao(cotacao) {
      this.$swal({
        title: `Cotação: ${cotacao.produto_nome}`,
        html: `
          <div style="text-align: left; margin: 20px 0;">
            <h4>📦 Produto</h4>
            <p><strong>Nome:</strong> ${cotacao.produto_nome}</p>
            ${cotacao.produto_descricao ? `<p><strong>Descrição:</strong> ${cotacao.produto_descricao}</p>` : ''}
            ${cotacao.quantidade ? `<p><strong>Quantidade:</strong> ${cotacao.quantidade} ${cotacao.unidade_medida}</p>` : ''}
            
            <h4>🏢 Fornecedor</h4>
            <p><strong>Nome:</strong> ${cotacao.fornecedor_nome}</p>
            ${cotacao.fornecedor_cnpj ? `<p><strong>CNPJ:</strong> ${this.formatCNPJ(cotacao.fornecedor_cnpj)}</p>` : ''}
            ${cotacao.fornecedor_contato ? `<p><strong>Contato:</strong> ${cotacao.fornecedor_contato}</p>` : ''}
            
            <h4>💰 Comercial</h4>
            <p><strong>Preço Unitário:</strong> ${this.formatCurrency(cotacao.preco_unitario)}</p>
            ${cotacao.preco_total ? `<p><strong>Preço Total:</strong> ${this.formatCurrency(cotacao.preco_total)}</p>` : ''}
            ${cotacao.prazo_entrega ? `<p><strong>Prazo:</strong> ${cotacao.prazo_entrega} dias</p>` : ''}
            ${cotacao.data_validade ? `<p><strong>Válida até:</strong> ${this.formatDate(cotacao.data_validade)}</p>` : ''}
            ${cotacao.condicoes_pagamento ? `<p><strong>Pagamento:</strong> ${cotacao.condicoes_pagamento}</p>` : ''}
            ${cotacao.observacoes ? `<p><strong>Observações:</strong> ${cotacao.observacoes}</p>` : ''}
          </div>
        `,
        width: '600px',
        confirmButtonText: 'Fechar'
      })
    },
    
    duplicarCotacao(cotacao) {
      this.cotacaoForm = {
        ...cotacao,
        id: null,
        produto_nome: cotacao.produto_nome + ' (Cópia)'
      }
      this.modalCotacao.show = true
      this.modalCotacao.editando = false
    },
    
    async aceitarCotacao(cotacao) {
      const confirm = await this.$swal({
        title: 'Aceitar Cotação',
        text: `Deseja aceitar a cotação de "${cotacao.produto_nome}" de ${cotacao.fornecedor_nome}?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Sim, aceitar',
        cancelButtonText: 'Cancelar'
      })
      
      if (confirm.isConfirmed) {
        try {
          const { error } = await supabase
            .from('cotacoes')
            .update({ status: 'aceita' })
            .eq('id', cotacao.id)
          
          if (error) throw error
          
          this.$swal({
            title: 'Aceita!',
            text: 'Cotação aceita com sucesso',
            icon: 'success',
            timer: 2000
          })
          
          await this.carregarCotacoes()
        } catch (error) {
          console.error('Erro ao aceitar cotação:', error)
          this.$swal({
            title: 'Erro',
            text: 'Erro ao aceitar cotação: ' + error.message,
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
        dataInicio: '',
        dataFim: ''
      }
    },
    
    // Exportação/Importação
    async exportarCotacoes() {
      try {
        if (this.cotacoesFiltradas.length === 0) {
          this.$swal({
            title: 'Atenção',
            text: 'Não há cotações para exportar com os filtros aplicados.',
            icon: 'warning'
          })
          return
        }

        // Perguntar formato de exportação
        const { value: formato } = await this.$swal({
          title: '📤 Exportar Cotações',
          text: `Exportar ${this.cotacoesFiltradas.length} cotação(ões). Escolha o formato:`,
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
        const { exportCotacoes } = await import('@/services/exportService')
        
        // Exportar
        const tipoExport = formato ? 'excel' : 'csv'
        await exportCotacoes(this.cotacoesFiltradas, tipoExport)
        
        this.$swal({
          title: 'Sucesso!',
          text: `${this.cotacoesFiltradas.length} cotação(ões) exportada(s) com sucesso!`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao exportar cotações:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao exportar cotações: ' + error.message,
          icon: 'error'
        })
      }
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
    
    formatCNPJ(cnpj) {
      if (!cnpj) return ''
      return cnpj.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5')
    },
    
    formatarCNPJ(event) {
      let value = event.target.value.replace(/\D/g, '')
      value = value.replace(/^(\d{2})(\d)/, '$1.$2')
      value = value.replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
      value = value.replace(/\.(\d{3})(\d)/, '.$1/$2')
      value = value.replace(/(\d{4})(\d)/, '$1-$2')
      event.target.value = value
      this.cotacaoForm.fornecedor_cnpj = value
    },
    
    getStatusLabel(status) {
      const labels = {
        'ativa': 'Ativa',
        'vencida': 'Vencida',
        'aceita': 'Aceita',
        'cancelada': 'Cancelada'
      }
      return labels[status] || status
    },
    
    isCotacaoVencida(cotacao) {
      if (!cotacao.data_validade) return false
      return new Date(cotacao.data_validade) < new Date()
    }
  }
}
</script>

<style scoped>
@import './GerenciadorCotacoes.css';
</style>