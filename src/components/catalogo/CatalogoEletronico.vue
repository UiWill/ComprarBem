<template>
  <div class="catalogo-container">
    <h2>Catálogo Eletrônico de Bens Padronizados</h2>
    
    <div class="search-filters">
      <div class="search-box">
        <input 
          type="text" 
          v-model="searchTerm" 
          placeholder="Buscar produto..." 
          @input="filtrarProdutos"
        >
      </div>
      
      <div class="filters">
        <div class="categoria-filter">
          <label><strong>Categoria:</strong></label>
          <div class="dropdown">
            <button class="dropdown-toggle" 
                    type="button" 
                    @click="toggleCategoriaDropdown">
              {{ categoriaAtual }}
            </button>
            <div class="dropdown-menu" :class="{'show': showCategoriaDropdown}">
              <div v-if="carregandoCategorias" class="dropdown-item loading">
                <div class="spinner-border spinner-border-sm" role="status"></div>
                <span>Carregando...</span>
              </div>
              <template v-else>
                <a class="dropdown-item" @click="selecionarCategoria(null)">Todas as categorias</a>
                <div v-if="categorias.length === 0" class="dropdown-item empty">
                  Nenhuma categoria disponível
                </div>
                <template v-else>
                  <a 
                    v-for="categoria in categorias" 
                    :key="categoria.id" 
                    class="dropdown-item" 
                    :class="{'active': categoria.id === filtroCategoria}"
                    @click="selecionarCategoria(categoria)">
                    {{ categoria.nome }}
                  </a>
                </template>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="produtos-grid" v-if="produtosFiltrados.length > 0">
      <div 
        class="produto-card" 
        v-for="produto in produtosFiltrados" 
        :key="produto.id"
        @click="verDetalhesProduto(produto.id)"
      >
        <div class="produto-info">
          <h3>{{ produto.nome }}</h3>
          <p><strong>Marca:</strong> {{ produto.marca }}</p>
          <p><strong>Modelo:</strong> {{ produto.modelo }}</p>
          <p><strong>Fabricante:</strong> {{ produto.fabricante }}</p>
        </div>
        <div class="produto-status" :class="getStatusClass(produto.status)">
          {{ produto.status }}
        </div>
      </div>
    </div>
    
    <div class="empty-state" v-else>
      <p>Nenhum produto encontrado.</p>
    </div>
    
    <div class="produto-modal" v-if="produtoSelecionado" @click.self="fecharModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ produtoSelecionado.nome }}</h3>
          <button class="btn-close" @click="fecharModal">×</button>
        </div>
        <div class="modal-body">
          <div class="produto-detalhes">
            <p><strong>Marca:</strong> {{ produtoSelecionado.marca }}</p>
            <p><strong>Modelo:</strong> {{ produtoSelecionado.modelo }}</p>
            <p><strong>Fabricante:</strong> {{ produtoSelecionado.fabricante }}</p>
            <p><strong>CNPJ:</strong> {{ produtoSelecionado.cnpj }}</p>
            <p v-if="produtoSelecionado.descricao"><strong>Descrição:</strong> {{ produtoSelecionado.descricao }}</p>
            <p><strong>Status:</strong> <span :class="getStatusClass(produtoSelecionado.status)">{{ produtoSelecionado.status }}</span></p>
            
            <!-- Seção de Avaliações RDM -->
            <div class="avaliacoes-section">
              <div class="avaliacoes-header" @click="toggleAvaliacoes" :class="{ 'active': showAvaliacoes }">
                <h4>Avaliações de Desempenho (RDM)</h4>
                <div class="avaliacao-summary">
                  <div class="stars-container" v-if="avaliacaoMedia > 0">
                    <div class="stars">
                      <span v-for="n in 5" :key="n" class="star" :class="{ filled: avaliacaoMedia >= n, half: avaliacaoMedia >= n-0.5 && avaliacaoMedia < n }">★</span>
                    </div>
                    <span class="rating-number">{{ avaliacaoMedia }}</span>
                    <span class="rating-count">({{ avaliacoes.length }} avaliações)</span>
                  </div>
                  <div v-else class="no-ratings">
                    Sem avaliações ainda
                  </div>
                  <span class="toggle-icon">{{ showAvaliacoes ? '▲' : '▼' }}</span>
                </div>
              </div>
              
              <div class="avaliacoes-content" v-if="showAvaliacoes">
                <div v-if="avaliacoes.length === 0" class="no-avaliacoes">
                  Este produto ainda não possui avaliações de desempenho.
                </div>
                <div v-else class="avaliacoes-list">
                  <div v-for="(avaliacao, index) in avaliacoes" :key="index" class="avaliacao-item">
                    <div class="avaliacao-stars">
                      <span v-for="n in 5" :key="n" class="star" :class="{ filled: avaliacao.avaliacao >= n }">★</span>
                    </div>
                    <div class="avaliacao-comentario">
                      {{ avaliacao.comentario }}
                    </div>
                    <div class="avaliacao-data">
                      {{ obterDataAvaliacao(avaliacao) }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div v-if="documentos.length > 0" class="documentos">
              <h4>Documentos</h4>
              <ul>
                <li v-for="doc in documentos" :key="doc.id">
                  <a :href="doc.arquivo_url" target="_blank">{{ doc.nome }}</a>
                </li>
              </ul>
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
  name: 'CatalogoEletronico',
  data() {
    return {
      produtos: [],
      produtosFiltrados: [],
      categorias: [],
      searchTerm: '',
      filtroCategoria: '',
      categoriaAtual: 'Todas as categorias',
      showCategoriaDropdown: false,
      showAvaliacoes: false,
      produtoSelecionado: null,
      documentos: [],
      avaliacoes: [],
      avaliacaoMedia: 0,
      carregandoCategorias: true,
      categoriaSelecionada: null,
      currentTenantId: null,
      loading: false
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarDados()
    })
    document.addEventListener('click', this.closeDropdownOnClickOutside)
  },
  mounted() {
    // Carregar categorias diretamente e garantir que o dropdown está fechado
    this.carregarCategoriasDireto()
    this.showCategoriaDropdown = false
  },
  beforeUnmount() {
    document.removeEventListener('click', this.closeDropdownOnClickOutside)
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
          console.log('Tenant ID obtido dos metadados:', this.currentTenantId)
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
          console.log('Tenant ID obtido da tabela usuarios:', this.currentTenantId)
        } else {
          console.error('Tenant ID não encontrado para o usuário')
        }
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
      }
    },
    async carregarDados() {
      console.log("Iniciando carregamento de dados")
      this.carregandoCategorias = true
      this.loading = true
      
      try {
        // Garantir que temos o tenant_id antes de continuar
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível. Tentando recarregar...')
          await this.obterTenantId()
          
          if (!this.currentTenantId) {
            console.error('Não foi possível obter o tenant_id, impossível carregar dados')
            this.$swal({
              icon: 'error',
              title: 'Erro ao carregar dados',
              text: 'Não foi possível identificar sua conta. Por favor, faça login novamente.'
            })
            return
          }
        }
        
        // Carregar categorias
        console.log("Buscando categorias do Supabase...")
        const { data: categorias, error: errorCategorias } = await supabase
          .from('categorias')
          .select('*')
        
        if (errorCategorias) {
          console.error('Erro ao carregar categorias:', errorCategorias.message)
          this.$swal({
            icon: 'error',
            title: 'Erro ao carregar categorias',
            text: 'Não foi possível carregar as categorias. Por favor, tente novamente.'
          })
        } else {
          console.log('Categorias carregadas:', categorias)
          this.categorias = categorias || []
          
          if (this.categorias.length === 0) {
            console.warn('Nenhuma categoria encontrada no banco de dados')
          }
        }
        
        this.carregandoCategorias = false
        
        // Carregar produtos APENAS do tenant atual
        console.log("Buscando produtos do Supabase para tenant_id:", this.currentTenantId)
        const { data: produtos, error: errorProdutos } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId) // Filtrar por tenant_id
        
        if (errorProdutos) {
          console.error('Erro ao carregar produtos:', errorProdutos.message)
          this.$swal({
            icon: 'error',
            title: 'Erro ao carregar produtos',
            text: 'Não foi possível carregar os produtos. Por favor, tente novamente.'
          })
        } else {
          console.log('Produtos carregados:', produtos)
          this.produtos = produtos || []
          console.log(`${this.produtos.length} produtos carregados para o tenant atual`)
          
          // Mapear IDs de categorias para nomes
          this.produtos = this.produtos.map(produto => {
            const categoria = this.categorias.find(c => c.id === produto.categoria_id)
            return {
              ...produto,
              categoria_nome: categoria ? categoria.nome : 'Categoria não encontrada'
            }
          })
          
          this.produtosFiltrados = [...this.produtos]
        }
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar dados',
          text: 'Ocorreu um erro inesperado. Por favor, tente novamente.'
        })
      } finally {
        this.loading = false
      }
    },
    async carregarCategoriasDireto() {
      try {
        console.log('Tentando carregar categorias diretamente...')
        const { data, error } = await supabase
          .from('categorias')
          .select('*')
        
        if (error) {
          console.error('Erro ao carregar categorias direto:', error)
          return
        }
        
        console.log('Resposta direta de categorias:', data)
        
        if (data && data.length > 0 && this.categorias.length === 0) {
          console.log('Atualizando categorias com dados diretos')
          this.categorias = data
        }
      } catch (e) {
        console.error('Exceção ao carregar categorias direto:', e)
      }
    },
    filtrarProdutos() {
      console.log('Filtrando produtos por:', this.filtroCategoria, 'e texto:', this.searchTerm)
      
      this.produtosFiltrados = this.produtos.filter(produto => {
        const matchCategoria = !this.filtroCategoria || produto.categoria_id === this.filtroCategoria
        const matchText = !this.searchTerm || 
                        produto.nome.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
                        (produto.descricao && produto.descricao.toLowerCase().includes(this.searchTerm.toLowerCase()))
        
        return matchCategoria && matchText
      })
      
      console.log('Produtos filtrados:', this.produtosFiltrados.length)
    },
    async verDetalhesProduto(id) {
      try {
        // Garantir que só podemos ver produtos do nosso tenant
        if (!this.currentTenantId) {
          console.error('Não foi possível identificar o tenant_id')
          return
        }
        
        // Buscar detalhes do produto (com filtro de tenant_id)
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', id)
          .eq('tenant_id', this.currentTenantId) // Garantir que só vemos produtos do nosso tenant
          .single()
        
        if (error) {
          console.error('Erro ao carregar produto:', error)
          throw error
        }
        
        if (!data) {
          console.error('Produto não encontrado ou não pertence ao tenant atual')
          this.$swal({
            icon: 'error',
            title: 'Produto não encontrado',
            text: 'O produto solicitado não existe ou você não tem permissão para visualizá-lo.'
          })
          return
        }
        
        this.produtoSelecionado = data
        
        // Buscar documentos do produto
        const { data: docs, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', id)
          .eq('tenant_id', this.currentTenantId) // Filtrar documentos por tenant_id
        
        if (docsError) throw docsError
        
        this.documentos = docs || []

        // Buscar avaliações RDM do produto
        const { data: avaliacoes, error: avaliacoesError } = await supabase
          .from('rdm_feedbacks')
          .select('*')
          .eq('produto_id', id)
          .eq('tenant_id', this.currentTenantId) // Filtrar avaliações por tenant_id
        
        if (avaliacoesError) {
          console.error('Erro ao carregar avaliações:', avaliacoesError)
          this.avaliacoes = []
          this.avaliacaoMedia = 0
        } else {
          this.avaliacoes = avaliacoes || []
          
          // Log para depuração - ver quais campos estão disponíveis
          if (this.avaliacoes.length > 0) {
            console.log('Campos disponíveis na avaliação:', Object.keys(this.avaliacoes[0]));
            console.log('Exemplo de avaliação:', this.avaliacoes[0]);
          }
          
          // Calcular média de avaliações se existirem
          if (this.avaliacoes.length > 0) {
            const somaAvaliacoes = this.avaliacoes.reduce((soma, item) => soma + item.avaliacao, 0)
            this.avaliacaoMedia = parseFloat((somaAvaliacoes / this.avaliacoes.length).toFixed(1))
          } else {
            this.avaliacaoMedia = 0
          }
        }
      } catch (error) {
        console.error('Erro ao carregar detalhes do produto:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar detalhes',
          text: 'Não foi possível carregar os detalhes do produto. Tente novamente.'
        })
      }
    },
    fecharModal() {
      this.produtoSelecionado = null;
      this.documentos = [];
      this.avaliacoes = [];
      this.avaliacaoMedia = 0;
      this.showAvaliacoes = false; // Reset ao fechar modal
    },
    getStatusClass(status) {
      switch (status) {
        case 'aprovado': return 'status-aprovado'
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        default: return ''
      }
    },
    closeDropdownOnClickOutside(event) {
      // Método melhorado para fechar dropdown quando clica fora
      const dropdownEl = this.$el.querySelector('.dropdown')
      if (dropdownEl && !dropdownEl.contains(event.target)) {
        this.showCategoriaDropdown = false
      }
    },
    selecionarCategoria(categoria) {
      console.log('Categoria selecionada:', categoria)
      this.categoriaSelecionada = categoria
      this.categoriaAtual = categoria ? categoria.nome : 'Todas as categorias'
      this.filtroCategoria = categoria ? categoria.id : ''
      this.showCategoriaDropdown = false
      this.filtrarProdutos()
    },
    toggleCategoriaDropdown() {
      this.showCategoriaDropdown = !this.showCategoriaDropdown
    },
    toggleAvaliacoes() {
      this.showAvaliacoes = !this.showAvaliacoes;
    },
    formatarData(dataString) {
      if (!dataString) {
        // Se não houver data, verificar se há outro campo de data disponível
        return 'Data não disponível';
      }
      try {
        const data = new Date(dataString);
        return data.toLocaleDateString('pt-BR', { 
          day: '2-digit', 
          month: '2-digit', 
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });
      } catch (e) {
        console.error('Erro ao formatar data:', e);
        return 'Data inválida';
      }
    },
    obterDataAvaliacao(avaliacao) {
      // Tentar obter a data de diferentes campos possíveis
      const dataField = avaliacao.created_at || avaliacao.criado_em || avaliacao.data || null;
      return this.formatarData(dataField);
    }
  }
}
</script>

<style scoped>
.catalogo-container {
  padding: 20px;
}

h2 {
  margin-bottom: 20px;
}

.search-filters {
  display: flex;
  margin-bottom: 20px;
  gap: 15px;
}

.search-box {
  flex: 2;
}

.filters {
  flex: 1;
  position: relative;
}

.categoria-filter {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.dropdown {
  position: relative;
  display: inline-block;
  width: 100%;
}

.dropdown-toggle {
  width: 100%;
  padding: 10px 12px;
  background-color: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  text-align: left;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  position: relative;
}

.dropdown-toggle::after {
  content: '';
  display: inline-block;
  margin-left: 0.255em;
  vertical-align: 0.255em;
  border-top: 0.3em solid;
  border-right: 0.3em solid transparent;
  border-bottom: 0;
  border-left: 0.3em solid transparent;
}

.dropdown-toggle:hover {
  border-color: #2c3e50;
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  z-index: 1000;
  display: none;
  width: 100%;
  padding: 0.5rem 0;
  margin: 0.125rem 0 0;
  font-size: 14px;
  color: #212529;
  text-align: left;
  list-style: none;
  background-color: #fff;
  background-clip: padding-box;
  border: 1px solid rgba(0, 0, 0, 0.15);
  border-radius: 0.25rem;
  box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.175);
}

.dropdown-menu.show {
  display: block;
}

.dropdown-item {
  display: block;
  width: 100%;
  padding: 0.5rem 1rem;
  clear: both;
  font-weight: 400;
  color: #212529;
  text-align: inherit;
  white-space: nowrap;
  background-color: transparent;
  border: 0;
  cursor: pointer;
}

.dropdown-item:hover, .dropdown-item:focus {
  color: #16181b;
  text-decoration: none;
  background-color: #f8f9fa;
}

.dropdown-item.active, .dropdown-item:active {
  color: #fff;
  text-decoration: none;
  background-color: #2c3e50;
}

.dropdown-item.loading {
  display: flex;
  align-items: center;
  gap: 8px;
}

.dropdown-item.empty {
  color: #6c757d;
  cursor: default;
}

.spinner-border {
  display: inline-block;
  width: 1rem;
  height: 1rem;
  vertical-align: text-bottom;
  border: 0.2em solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spinner-border .75s linear infinite;
}

@keyframes spinner-border {
  to { transform: rotate(360deg); }
}

input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.produtos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.produto-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 15px;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  position: relative;
}

.produto-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.produto-info h3 {
  margin-top: 0;
  margin-bottom: 10px;
}

.produto-status {
  position: absolute;
  top: 15px;
  right: 15px;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 12px;
  text-transform: uppercase;
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

.empty-state {
  text-align: center;
  padding: 40px;
  color: #7f8c8d;
}

.produto-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  padding: 15px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  margin: 0;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
}

.modal-body {
  padding: 15px;
}

.documentos {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.documentos h4 {
  margin-top: 0;
}

.documentos ul {
  padding-left: 20px;
}

.documentos a {
  color: #3498db;
  text-decoration: none;
}

.documentos a:hover {
  text-decoration: underline;
}

.avaliacoes-section {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.avaliacoes-header {
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 6px;
  transition: background-color 0.2s;
}

.avaliacoes-header:hover {
  background-color: #e9ecef;
}

.avaliacoes-header h4 {
  margin: 0;
  font-size: 16px;
  color: #2c3e50;
}

.avaliacao-summary {
  display: flex;
  align-items: center;
}

.stars-container {
  display: flex;
  align-items: center;
  margin-right: 10px;
}

.stars {
  display: flex;
}

.star {
  font-size: 18px;
  margin-right: 2px;
  color: #ddd;
}

.star.filled {
  color: #f1c40f;
}

.half {
  position: relative;
}

.half:after {
  content: '★';
  color: #f1c40f;
  position: absolute;
  left: 0;
  top: 0;
  width: 50%;
  overflow: hidden;
}

.rating-number {
  margin: 0 5px;
  font-weight: bold;
}

.rating-count {
  color: #7f8c8d;
  font-size: 14px;
}

.no-ratings {
  color: #7f8c8d;
  font-style: italic;
}

.toggle-icon {
  color: #7f8c8d;
  font-size: 12px;
  transition: transform 0.3s;
}

.avaliacoes-header.active .toggle-icon {
  transform: rotate(180deg);
}

.avaliacoes-content {
  margin-top: 15px;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 6px;
  max-height: 300px;
  overflow-y: auto;
}

.no-avaliacoes {
  color: #7f8c8d;
  font-style: italic;
  text-align: center;
  padding: 20px;
}

.avaliacoes-list {
  margin-top: 10px;
}

.avaliacao-item {
  margin-bottom: 15px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.avaliacao-item:last-child {
  margin-bottom: 0;
  padding-bottom: 0;
  border-bottom: none;
}

.avaliacao-stars {
  margin-bottom: 8px;
}

.avaliacao-comentario {
  margin-bottom: 8px;
  line-height: 1.5;
  white-space: pre-line;
}

.avaliacao-data {
  color: #7f8c8d;
  font-size: 12px;
}
</style> 