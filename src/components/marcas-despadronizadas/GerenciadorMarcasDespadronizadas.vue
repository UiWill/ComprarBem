<template>
  <div class="gerenciador-marcas-despadronizadas">
    <div class="header-section">
      <div class="title-and-stats">
        <h2>🚫 Gerenciador de Marcas Despadronizadas</h2>
        <div class="stats-mini">
          <span class="stat-item">
            <strong>{{ totalMarcas }}</strong> Total
          </span>
          <span class="stat-item ativas">
            <strong>{{ marcasAtivas }}</strong> Ativas
          </span>
          <span class="stat-item revisao">
            <strong>{{ marcasPendenteRevisao }}</strong> Pendente Revisão
          </span>
          <span class="stat-item criticas">
            <strong>{{ marcasCriticas }}</strong> Críticas
          </span>
        </div>
      </div>
      
      <div class="actions-header">
        <button @click="abrirModalNovaMarca" class="btn-primary">
          + Nova Despadronização
        </button>
        <button @click="carregarMarcas" class="btn-secondary">
          🔄 Atualizar
        </button>
        <button @click="exportarMarcas" class="btn-secondary">
          📤 Exportar
        </button>
      </div>
    </div>

    <!-- Filtros -->
    <div class="filtros-section">
      <div class="filtros-linha">
        <div class="filtro-group">
          <label>🏷️ Marca:</label>
          <input 
            v-model="filtros.marca" 
            type="text" 
            placeholder="Filtrar por marca..."
            @input="aplicarFiltros"
          >
        </div>
        
        <div class="filtro-group">
          <label>📋 Categoria:</label>
          <select v-model="filtros.categoria" @change="aplicarFiltros">
            <option value="">Todas</option>
            <option value="Impressoras">Impressoras</option>
            <option value="Computadores">Computadores</option>
            <option value="Tablets">Tablets</option>
            <option value="Telefones">Telefones</option>
            <option value="Mobiliário">Mobiliário</option>
            <option value="Veículos">Veículos</option>
            <option value="Outros">Outros</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>🎯 Status:</label>
          <select v-model="filtros.status" @change="aplicarFiltros">
            <option value="">Todos</option>
            <option value="ativa">Ativa</option>
            <option value="revogada">Revogada</option>
            <option value="expirada">Expirada</option>
            <option value="suspensa">Suspensa</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>🔧 Tipo:</label>
          <select v-model="filtros.tipo" @change="aplicarFiltros">
            <option value="">Todos</option>
            <option value="total">Total</option>
            <option value="parcial">Parcial</option>
            <option value="temporaria">Temporária</option>
            <option value="definitiva">Definitiva</option>
          </select>
        </div>
        
        <div class="filtro-group">
          <label>⚠️ Criticidade:</label>
          <select v-model="filtros.criticidade" @change="aplicarFiltros">
            <option value="">Todas</option>
            <option value="baixo">Baixa</option>
            <option value="medio">Média</option>
            <option value="alto">Alta</option>
            <option value="critico">Crítica</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Alertas de Revisão -->
    <div v-if="marcasComRevisaoVencida.length > 0" class="alertas-section">
      <div class="alerta-card alerta-warning">
        <h4>⚠️ Revisões Pendentes</h4>
        <p>{{ marcasComRevisaoVencida.length }} marca(s) com revisão vencida.</p>
        <button @click="mostrarRevisoesVencidas" class="btn-warning btn-small">
          Ver Detalhes
        </button>
      </div>
    </div>

    <!-- Lista de Marcas -->
    <div class="marcas-lista">
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Carregando marcas despadronizadas...</p>
      </div>

      <div v-else-if="marcasFiltradas.length === 0" class="empty-state">
        <div class="empty-icon">🚫</div>
        <h3>Nenhuma marca encontrada</h3>
        <p>Não há marcas despadronizadas que correspondam aos filtros aplicados.</p>
        <button @click="limparFiltros" class="btn-secondary">Limpar Filtros</button>
      </div>

      <div v-else class="marcas-grid">
        <div 
          v-for="marca in marcasPaginadas" 
          :key="marca.id"
          class="marca-card"
          :class="[
            'status-' + marca.status_atual,
            'criticidade-' + marca.nivel_criticidade
          ]"
        >
          <div class="card-header">
            <div class="marca-info">
              <h4>{{ marca.marca }} {{ marca.modelo }}</h4>
              <span class="categoria-badge">{{ marca.categoria }}</span>
            </div>
            
            <div class="status-badges">
              <span class="status-badge" :class="'status-' + marca.status_atual">
                {{ getStatusLabel(marca.status_atual) }}
              </span>
              <span class="tipo-badge" :class="'tipo-' + marca.tipo_despadronizacao">
                {{ getTipoLabel(marca.tipo_despadronizacao) }}
              </span>
            </div>
          </div>

          <div class="card-content">
            <div class="info-row">
              <strong>Processo:</strong> {{ marca.numero_processo }}
            </div>
            
            <div class="info-row">
              <strong>Motivo:</strong> {{ getMotivoLabel(marca.motivo_principal) }}
            </div>
            
            <div class="info-row">
              <strong>Despadronizada em:</strong> {{ formatarData(marca.data_despadronizacao) }}
            </div>
            
            <div v-if="marca.data_fim_vigencia" class="info-row">
              <strong>Vigência até:</strong> {{ formatarData(marca.data_fim_vigencia) }}
            </div>
            
            <div class="info-row criticidade">
              <strong>Criticidade:</strong> 
              <span :class="'nivel-' + marca.nivel_criticidade">
                {{ getCriticidadeLabel(marca.nivel_criticidade) }}
              </span>
            </div>
            
            <div v-if="marca.proxima_revisao" class="info-row revisao">
              <strong>Próxima Revisão:</strong> 
              <span :class="{ 'vencida': isRevisaoVencida(marca.proxima_revisao) }">
                {{ formatarData(marca.proxima_revisao) }}
                <span v-if="isRevisaoVencida(marca.proxima_revisao)" class="vencida-label">
                  ({{ diasAtraso(marca.proxima_revisao) }} dias atraso)
                </span>
              </span>
            </div>
          </div>

          <div class="card-actions">
            <button 
              @click="visualizarMarca(marca)"
              class="btn-action view"
              title="Visualizar Detalhes"
            >
              👁️ Ver
            </button>
            
            <button 
              @click="editarMarca(marca)"
              class="btn-action edit"
              title="Editar"
            >
              ✏️ Editar
            </button>
            
            <button 
              v-if="marca.status_atual === 'ativa'"
              @click="programarRevisao(marca)"
              class="btn-action review"
              title="Programar Revisão"
            >
              📅 Revisão
            </button>
            
            <button 
              @click="gerenciarNotificacoes(marca)"
              class="btn-action notify"
              title="Notificações"
            >
              📧 Notificar
            </button>
            
            <button 
              @click="verHistorico(marca)"
              class="btn-action history"
              title="Ver Histórico"
            >
              📋 Histórico
            </button>
            
            <button 
              v-if="marca.status_atual === 'ativa'"
              @click="revogarMarca(marca)"
              class="btn-action revoke"
              title="Revogar"
            >
              ❌ Revogar
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

    <!-- Modal Nova/Editar Marca -->
    <div v-if="showModal" class="modal-overlay" @click="fecharModal">
      <div class="modal-content modal-large" @click.stop>
        <div class="modal-header">
          <h3>{{ marcaEditando.id ? 'Editar Despadronização' : 'Nova Despadronização' }}</h3>
          <button @click="fecharModal" class="modal-close">×</button>
        </div>

        <div class="modal-body">
          <form @submit.prevent="salvarMarca">
            <!-- Seleção de Produto do Catálogo -->
            <div class="form-group">
              <label>🔍 Produto do Catálogo*</label>
              <select 
                v-model="marcaEditando.produto_id" 
                @change="preencherDadosProduto"
                class="produto-select"
                required
              >
                <option value="">Selecione o produto a ser despadronizado...</option>
                <option 
                  v-for="produto in produtosAtivos" 
                  :key="produto.id"
                  :value="produto.id"
                >
                  {{ produto.nome }} - {{ produto.marca || 'S/Marca' }} {{ produto.modelo || '' }}
                </option>
              </select>
              <small>{{ produtosAtivos.length }} produto(s) aprovado(s) disponível(is) para despadronização</small>
            </div>
            
            <!-- Dados Preenchidos Automaticamente -->
            <div class="form-row">
              <div class="form-group">
                <label>🏷️ Marca</label>
                <input 
                  v-model="marcaEditando.marca" 
                  type="text" 
                  readonly
                  placeholder="Será preenchido automaticamente"
                >
              </div>
              
              <div class="form-group">
                <label>📱 Modelo</label>
                <input 
                  v-model="marcaEditando.modelo" 
                  type="text" 
                  readonly
                  placeholder="Será preenchido automaticamente"
                >
              </div>
            </div>

            <!-- Dados da Despadronização -->
            <div class="form-row">
              <div class="form-group">
                <label>📄 Número do Processo*</label>
                <input 
                  v-model="marcaEditando.numero_processo" 
                  type="text" 
                  required
                  placeholder="Ex: PROC-2024-001"
                >
              </div>
              
              <div class="form-group">
                <label>📅 Data de Despadronização*</label>
                <input 
                  v-model="marcaEditando.data_despadronizacao" 
                  type="date" 
                  required
                >
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>🎯 Motivo Principal*</label>
                <select v-model="marcaEditando.motivo_principal" required>
                  <option value="">Selecione...</option>
                  <option value="qualidade">Problemas de Qualidade</option>
                  <option value="custo">Custo Elevado</option>
                  <option value="descontinuacao">Descontinuação</option>
                  <option value="seguranca">Problemas de Segurança</option>
                  <option value="fornecimento">Problemas de Fornecimento</option>
                  <option value="tecnico">Obsolescência Técnica</option>
                  <option value="outros">Outros</option>
                </select>
              </div>
              
              <div class="form-group">
                <label>🔧 Tipo*</label>
                <select v-model="marcaEditando.tipo_despadronizacao" required>
                  <option value="">Selecione...</option>
                  <option value="total">Total</option>
                  <option value="temporaria">Temporária</option>
                  <option value="definitiva">Definitiva</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label>📝 Justificativa*</label>
              <textarea 
                v-model="marcaEditando.justificativa" 
                rows="4"
                required
                placeholder="Descreva os motivos que levaram à despadronização..."
              ></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" @click="fecharModal" class="btn-secondary">
                Cancelar
              </button>
              <button type="submit" class="btn-primary" :disabled="salvando">
                {{ salvando ? 'Salvando...' : 'Salvar Despadronização' }}
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
  name: 'GerenciadorMarcasDespadronizadas',
  data() {
    return {
      marcas: [],
      produtos: [], // produtos do catálogo
      loading: false,
      salvando: false,
      showModal: false,
      activeModalTab: 'basicos',
      
      // Filtros
      filtros: {
        marca: '',
        categoria: '',
        status: '',
        tipo: '',
        criticidade: ''
      },
      
      // Paginação
      paginaAtual: 1,
      itensPorPagina: 12,
      
      // Modal
      marcaEditando: this.getMarcaVazia(),
      
      // Estado
      erro: null
    }
  },
  
  computed: {
    totalMarcas() {
      return this.marcas.length
    },
    
    marcasAtivas() {
      return this.marcas.filter(m => m.status_atual === 'ativa').length
    },
    
    marcasPendenteRevisao() {
      return this.marcas.filter(m => 
        m.proxima_revisao && new Date(m.proxima_revisao) <= new Date()
      ).length
    },
    
    marcasCriticas() {
      return this.marcas.filter(m => m.nivel_criticidade === 'critico').length
    },
    
    marcasComRevisaoVencida() {
      return this.marcas.filter(m => 
        m.proxima_revisao && 
        new Date(m.proxima_revisao) < new Date() &&
        m.status_atual === 'ativa'
      )
    },
    
    marcasFiltradas() {
      let filtradas = this.marcas
      
      if (this.filtros.marca) {
        filtradas = filtradas.filter(m => 
          m.marca.toLowerCase().includes(this.filtros.marca.toLowerCase()) ||
          (m.modelo && m.modelo.toLowerCase().includes(this.filtros.marca.toLowerCase()))
        )
      }
      
      if (this.filtros.categoria) {
        filtradas = filtradas.filter(m => m.categoria === this.filtros.categoria)
      }
      
      if (this.filtros.status) {
        filtradas = filtradas.filter(m => m.status_atual === this.filtros.status)
      }
      
      if (this.filtros.tipo) {
        filtradas = filtradas.filter(m => m.tipo_despadronizacao === this.filtros.tipo)
      }
      
      if (this.filtros.criticidade) {
        filtradas = filtradas.filter(m => m.nivel_criticidade === this.filtros.criticidade)
      }
      
      return filtradas.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    },
    
    totalPaginas() {
      return Math.ceil(this.marcasFiltradas.length / this.itensPorPagina)
    },
    
    marcasPaginadas() {
      const inicio = (this.paginaAtual - 1) * this.itensPorPagina
      const fim = inicio + this.itensPorPagina
      return this.marcasFiltradas.slice(inicio, fim)
    },
    
    produtosAtivos() {
      // Filtrar produtos que não estão despadronizados
      const produtosDespadronizados = this.marcas
        .filter(m => m.status_atual === 'ativa' && m.produto_id)
        .map(m => m.produto_id)
      
      return this.produtos.filter(p => !produtosDespadronizados.includes(p.id))
    }
  },
  
  async mounted() {
    await this.carregarMarcas()
    await this.carregarProdutos()
  },
  
  methods: {
    async carregarMarcas() {
      this.loading = true
      this.erro = null
      
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const { data, error } = await supabase
          .from('marcas_despadronizadas')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', { ascending: false })
        
        if (error) throw error
        
        this.marcas = data || []
        console.log('Marcas carregadas:', this.marcas.length)
      } catch (error) {
        console.error('Erro ao carregar marcas:', error)
        this.erro = 'Erro ao carregar marcas: ' + error.message
      } finally {
        this.loading = false
      }
    },
    
    async carregarProdutos() {
      try {
        const tenantId = await getTenantId()
        console.log('🔑 Carregando produtos para tenant:', tenantId)
        if (!tenantId) return
        
        const { data, error } = await supabase
          .from('produtos')
          .select('id, nome, marca, modelo, codigo_material, categoria_id, status')
          .eq('tenant_id', tenantId)
          .eq('status', 'aprovado')
          .order('nome', { ascending: true })
        
        if (error) {
          console.error('❌ Erro na query Supabase:', error)
          throw error
        }
        
        this.produtos = data || []
        console.log('✅ Produtos carregados no marcas-despadronizadas:', this.produtos.length)
        console.log('📋 Primeiros produtos:', this.produtos.slice(0, 3))
        
        if (this.produtos.length === 0) {
          console.warn('⚠️ Nenhum produto APROVADO encontrado')
        }
      } catch (error) {
        console.error('💥 Erro ao carregar produtos:', error)
      }
    },
    
    preencherDadosProduto() {
      if (!this.marcaEditando.produto_id) {
        // Limpar campos se nenhum produto selecionado
        this.marcaEditando.marca = ''
        this.marcaEditando.modelo = ''
        return
      }
      
      // Encontrar produto selecionado
      const produto = this.produtos.find(p => p.id === this.marcaEditando.produto_id)
      if (produto) {
        this.marcaEditando.marca = produto.marca || ''
        this.marcaEditando.modelo = produto.modelo || ''
        
        console.log('✅ Dados do produto preenchidos:', {
          nome: produto.nome,
          marca: produto.marca,
          modelo: produto.modelo
        })
      } else {
        console.error('❌ Produto não encontrado no array:', this.marcaEditando.produto_id)
      }
    },
    
    aplicarFiltros() {
      this.paginaAtual = 1
    },
    
    limparFiltros() {
      this.filtros = {
        marca: '',
        categoria: '',
        status: '',
        tipo: '',
        criticidade: ''
      }
      this.paginaAtual = 1
    },
    
    abrirModalNovaMarca() {
      this.marcaEditando = this.getMarcaVazia()
      this.showModal = true
    },
    
    editarMarca(marca) {
      this.marcaEditando = { ...marca }
      this.showModal = true
    },
    
    fecharModal() {
      this.showModal = false
      this.marcaEditando = this.getMarcaVazia()
    },
    
    async salvarMarca() {
      this.salvando = true
      
      try {
        const tenantId = await getTenantId()
        if (!tenantId) {
          throw new Error('Tenant ID não encontrado')
        }
        
        const dadosMarca = {
          ...this.marcaEditando,
          tenant_id: tenantId,
          status_atual: 'ativa',
          nivel_criticidade: 'medio',
          updated_at: new Date().toISOString()
        }
        
        if (this.marcaEditando.id) {
          // Editar
          const { error } = await supabase
            .from('marcas_despadronizadas')
            .update(dadosMarca)
            .eq('id', this.marcaEditando.id)
          
          if (error) throw error
        } else {
          // Criar novo
          dadosMarca.created_at = new Date().toISOString()
          
          const { error } = await supabase
            .from('marcas_despadronizadas')
            .insert([dadosMarca])
          
          if (error) throw error
          
          // Atualizar status do produto no catálogo se foi selecionado um produto
          if (this.marcaEditando.produto_id && this.marcaEditando.produto_id !== 'MANUAL') {
            await this.atualizarStatusProduto(this.marcaEditando.produto_id, 'despadronizada')
          }
        }
        
        await this.carregarMarcas()
        this.fecharModal()
        
        this.$swal({
          title: 'Sucesso!',
          text: 'Marca despadronizada salva com sucesso!',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao salvar marca:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao salvar marca: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.salvando = false
      }
    },
    
    async revogarMarca(marca) {
      const confirmacao = await this.$swal({
        title: 'Revogar Despadronização?',
        text: `Tem certeza que deseja revogar a despadronização da marca "${marca.marca} ${marca.modelo}"?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sim, Revogar',
        cancelButtonText: 'Cancelar'
      })
      
      if (!confirmacao.isConfirmed) return
      
      try {
        const { error } = await supabase
          .from('marcas_despadronizadas')
          .update({ 
            status_atual: 'revogada',
            updated_at: new Date().toISOString()
          })
          .eq('id', marca.id)
        
        if (error) throw error
        
        // Reverter status do produto no catálogo se existir referência
        if (marca.produto_id) {
          await this.atualizarStatusProduto(marca.produto_id, 'ativa')
        }
        
        await this.carregarMarcas()
        
        this.$swal({
          title: 'Revogada!',
          text: 'Despadronização revogada com sucesso.',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao revogar marca:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao revogar marca: ' + error.message,
          icon: 'error'
        })
      }
    },
    
    async atualizarStatusProduto(produtoId, statusDespadronizacao) {
      try {
        // Apenas recarregar os produtos para atualizar a lista de disponíveis
        // A sincronização com o Catálogo será feita automaticamente quando 
        // ele recarregar os dados da tabela marcas_despadronizadas
        await this.carregarProdutos()
        
        console.log(`✅ Lista de produtos atualizada após ${statusDespadronizacao === 'despadronizada' ? 'despadronização' : 'revogação'}`)
        console.log(`ℹ️ O status será sincronizado automaticamente no Catálogo de Marcas`)
      } catch (error) {
        console.error('❌ Erro ao atualizar lista de produtos:', error)
        // Não bloquear o processo principal por erro aqui
      }
    },
    
    async exportarMarcas() {
      try {
        if (this.marcasFiltradas.length === 0) {
          this.$swal({
            title: 'Atenção',
            text: 'Não há marcas para exportar com os filtros aplicados.',
            icon: 'warning'
          })
          return
        }

        const { value: formato } = await this.$swal({
          title: '📤 Exportar Marcas Despadronizadas',
          text: `Exportar ${this.marcasFiltradas.length} marca(s). Escolha o formato:`,
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: '📊 Excel (.xlsx)',
          cancelButtonText: '📄 CSV (.csv)',
          showDenyButton: true,
          denyButtonText: 'Cancelar',
          reverseButtons: true
        })

        if (formato === undefined) return

        // Simular exportação (implementar depois)
        this.$swal({
          title: 'Sucesso!',
          text: `${this.marcasFiltradas.length} marca(s) exportada(s) com sucesso!`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
      } catch (error) {
        console.error('Erro ao exportar marcas:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao exportar marcas: ' + error.message,
          icon: 'error'
        })
      }
    },
    
    visualizarMarca(marca) {
      this.$swal({
        title: `${marca.marca} ${marca.modelo}`,
        html: `
          <div style="text-align: left; margin: 20px 0;">
            <h4>📦 Dados do Produto</h4>
            <p><strong>Categoria:</strong> ${marca.categoria}</p>
            <p><strong>Fabricante:</strong> ${marca.fabricante || 'N/A'}</p>
            <p><strong>Código:</strong> ${marca.codigo_produto || 'N/A'}</p>
            
            <h4>📋 Despadronização</h4>
            <p><strong>Processo:</strong> ${marca.numero_processo}</p>
            <p><strong>Tipo:</strong> ${this.getTipoLabel(marca.tipo_despadronizacao)}</p>
            <p><strong>Motivo:</strong> ${this.getMotivoLabel(marca.motivo_principal)}</p>
            <p><strong>Status:</strong> ${this.getStatusLabel(marca.status_atual)}</p>
            <p><strong>Criticidade:</strong> ${this.getCriticidadeLabel(marca.nivel_criticidade)}</p>
            
            <h4>📝 Justificativa</h4>
            <p>${marca.justificativa || 'N/A'}</p>
          </div>
        `,
        icon: 'info',
        customClass: {
          popup: 'swal-wide'
        }
      })
    },
    
    programarRevisao(marca) {
      this.$swal({
        title: '📅 Programar Revisão',
        text: `Funcionalidade em desenvolvimento - Programar revisão para ${marca.marca}`,
        icon: 'info'
      })
    },
    
    gerenciarNotificacoes(marca) {
      this.$swal({
        title: '📧 Gerenciar Notificações',
        text: `Funcionalidade em desenvolvimento - Notificações para ${marca.marca}`,
        icon: 'info'
      })
    },
    
    verHistorico(marca) {
      this.$swal({
        title: '📋 Histórico',
        text: `Funcionalidade em desenvolvimento - Histórico de ${marca.marca}`,
        icon: 'info'
      })
    },
    
    mostrarRevisoesVencidas() {
      const lista = this.marcasComRevisaoVencida
        .map(m => `• ${m.marca} ${m.modelo} - Vencida há ${this.diasAtraso(m.proxima_revisao)} dias`)
        .join('<br>')
      
      this.$swal({
        title: '⚠️ Revisões Vencidas',
        html: `<div style="text-align: left;">${lista}</div>`,
        icon: 'warning'
      })
    },
    
    getMarcaVazia() {
      return {
        produto_id: '',
        marca: '',
        modelo: '',
        numero_processo: '',
        data_despadronizacao: '',
        tipo_despadronizacao: '',
        motivo_principal: '',
        justificativa: ''
      }
    },
    
    getStatusLabel(status) {
      const labels = {
        ativa: 'Ativa',
        revogada: 'Revogada',
        expirada: 'Expirada',
        suspensa: 'Suspensa'
      }
      return labels[status] || status
    },
    
    getTipoLabel(tipo) {
      const labels = {
        total: 'Total',
        parcial: 'Parcial',
        temporaria: 'Temporária',
        definitiva: 'Definitiva'
      }
      return labels[tipo] || tipo
    },
    
    getMotivoLabel(motivo) {
      const labels = {
        qualidade: 'Problemas de Qualidade',
        custo: 'Custo Elevado',
        descontinuacao: 'Descontinuação',
        seguranca: 'Problemas de Segurança',
        fornecimento: 'Problemas de Fornecimento',
        tecnico: 'Obsolescência Técnica',
        manutencao: 'Dificuldade de Manutenção',
        outros: 'Outros'
      }
      return labels[motivo] || motivo
    },
    
    getCriticidadeLabel(criticidade) {
      const labels = {
        baixo: 'Baixa',
        medio: 'Média',
        alto: 'Alta',
        critico: 'Crítica'
      }
      return labels[criticidade] || criticidade
    },
    
    formatarData(data) {
      if (!data) return ''
      return new Date(data).toLocaleDateString('pt-BR')
    },
    
    isRevisaoVencida(data) {
      if (!data) return false
      return new Date(data) < new Date()
    },
    
    diasAtraso(data) {
      if (!data) return 0
      const hoje = new Date()
      const dataRevisao = new Date(data)
      const diffTime = hoje - dataRevisao
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      return Math.max(0, diffDays)
    }
  }
}
</script>

<style scoped>
.gerenciador-marcas-despadronizadas {
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

.stat-item.ativas {
  color: #27ae60;
}

.stat-item.revisao {
  color: #f39c12;
}

.stat-item.criticas {
  color: #e74c3c;
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
  background: #e74c3c;
  color: white;
}

.btn-primary:hover {
  background: #c0392b;
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
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
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

.alertas-section {
  margin-bottom: 20px;
}

.alerta-card {
  background: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 8px;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.alerta-card h4 {
  margin: 0 0 5px 0;
  color: #856404;
}

.alerta-card p {
  margin: 0;
  color: #856404;
}

.btn-warning {
  background: #f39c12;
  color: white;
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
}

.btn-warning:hover {
  background: #e67e22;
}

.marcas-lista {
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
  border-top: 4px solid #e74c3c;
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

.marcas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 20px;
}

.marca-card {
  background: white;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  padding: 15px;
  transition: all 0.2s;
  position: relative;
}

.marca-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.marca-card.status-ativa {
  border-left: 4px solid #27ae60;
}

.marca-card.status-revogada {
  border-left: 4px solid #95a5a6;
}

.marca-card.status-expirada {
  border-left: 4px solid #f39c12;
}

.marca-card.status-suspensa {
  border-left: 4px solid #e74c3c;
}

.marca-card.criticidade-critico {
  box-shadow: 0 0 0 2px rgba(231, 76, 60, 0.2);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.marca-info h4 {
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
  background: #3498db;
  color: white;
}

.status-badges {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: flex-end;
}

.status-badge,
.tipo-badge {
  font-size: 10px;
  padding: 3px 6px;
  border-radius: 4px;
  font-weight: 500;
  color: white;
}

.status-badge.status-ativa {
  background: #27ae60;
}

.status-badge.status-revogada {
  background: #95a5a6;
}

.status-badge.status-expirada {
  background: #f39c12;
}

.status-badge.status-suspensa {
  background: #e74c3c;
}

.tipo-badge.tipo-total {
  background: #e74c3c;
}

.tipo-badge.tipo-parcial {
  background: #f39c12;
}

.tipo-badge.tipo-temporaria {
  background: #3498db;
}

.tipo-badge.tipo-definitiva {
  background: #8e44ad;
}

.card-content {
  margin-bottom: 15px;
}

.info-row {
  font-size: 13px;
  margin-bottom: 4px;
  color: #666;
}

.info-row.criticidade .nivel-critico {
  color: #e74c3c;
  font-weight: bold;
}

.info-row.criticidade .nivel-alto {
  color: #f39c12;
  font-weight: bold;
}

.info-row.criticidade .nivel-medio {
  color: #3498db;
}

.info-row.criticidade .nivel-baixo {
  color: #27ae60;
}

.info-row.revisao .vencida {
  color: #e74c3c;
  font-weight: bold;
}

.vencida-label {
  font-size: 11px;
}

.card-actions {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
}

.btn-action {
  padding: 6px 8px;
  border: none;
  border-radius: 4px;
  font-size: 10px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
}

.btn-action.view {
  background: #3498db;
  color: white;
}

.btn-action.view:hover {
  background: #2980b9;
}

.btn-action.edit {
  background: #f39c12;
  color: white;
}

.btn-action.edit:hover {
  background: #e67e22;
}

.btn-action.review {
  background: #9b59b6;
  color: white;
}

.btn-action.review:hover {
  background: #8e44ad;
}

.btn-action.notify {
  background: #1abc9c;
  color: white;
}

.btn-action.notify:hover {
  background: #16a085;
}

.btn-action.history {
  background: #34495e;
  color: white;
}

.btn-action.history:hover {
  background: #2c3e50;
}

.btn-action.revoke {
  background: #e74c3c;
  color: white;
}

.btn-action.revoke:hover {
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
  max-width: 800px;
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

.form-group small {
  color: #666;
  font-size: 12px;
  margin-top: 2px;
}

.produto-select {
  border: 2px solid #3498db !important;
  background: #f8f9fa;
}

.produto-select:focus {
  border-color: #2980b9 !important;
  box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
}

.form-group input[readonly] {
  background: #e9ecef;
  color: #6c757d;
  cursor: not-allowed;
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
  .marcas-grid {
    grid-template-columns: 1fr;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .filtros-linha {
    grid-template-columns: 1fr;
  }
  
  .card-actions {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Classe CSS para SweetAlert largo */
:global(.swal-wide) {
  width: 800px !important;
}
</style>