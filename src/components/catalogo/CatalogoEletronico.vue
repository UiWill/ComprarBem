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
          <label><strong>Grupo:</strong></label>
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
                <a class="dropdown-item" @click="selecionarCategoria(null)">Todos os grupos</a>
                <div v-if="categorias.length === 0" class="dropdown-item empty">
                  Nenhum grupo disponível
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
      categoriaAtual: 'Todos os grupos',
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
          console.error('Erro ao carregar categorias:', errorCategorias)
        } else {
          this.categorias = categorias || []
          console.log(`${this.categorias.length} categorias carregadas`)
        }
        
        // Carregar produtos - apenas produtos pré-qualificados e padronizados
        console.log("Buscando produtos padronizados do Supabase...")
        let query = supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'aprovado') // Apenas produtos aprovados (pré-qualificados)
        
        const { data: produtos, error: errorProdutos } = await query
        
        if (errorProdutos) {
          console.error('Erro ao carregar produtos:', errorProdutos)
          this.produtos = []
        } else {
          this.produtos = produtos || []
          console.log(`${this.produtos.length} produtos padronizados carregados`)
        }
        
        this.filtrarProdutos()
        
      } catch (error) {
        console.error('Erro no carregamento de dados:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar dados',
          text: 'Ocorreu um erro ao carregar os dados. Tente novamente.'
        })
      } finally {
        this.carregandoCategorias = false
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
      this.categoriaAtual = categoria ? categoria.nome : 'Todos os grupos'
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
  border: 0.15em solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spinner-border 0.75s linear infinite;
}

@keyframes spinner-border {
  to { transform: rotate(360deg); }
}

.search-box input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.search-box input:focus {
  outline: none;
  border-color: #2c3e50;
}

.produtos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.produto-card {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.produto-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  border-color: #2c3e50;
}

.produto-info h3 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 18px;
  font-weight: 600;
}

.produto-info p {
  margin: 8px 0;
  color: #666;
  font-size: 14px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #666;
}

.produto-modal {
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
  max-width: 600px;
  width: 90%;
  max-height: 80vh;
  overflow-y: auto;
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

.produto-detalhes p {
  margin: 12px 0;
  color: #666;
}

.avaliacoes-section {
  margin-top: 20px;
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.avaliacoes-header {
  cursor: pointer;
  padding: 10px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.avaliacoes-header:hover {
  background-color: #f8f9fa;
}

.avaliacoes-header h4 {
  margin: 0;
  color: #2c3e50;
}

.avaliacao-summary {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 5px;
}

.stars-container {
  display: flex;
  align-items: center;
  gap: 5px;
}

.stars {
  display: flex;
}

.star {
  color: #ddd;
  font-size: 18px;
}

.star.filled {
  color: #ffc107;
}

.star.half {
  color: #ffc107;
}

.rating-number {
  font-weight: bold;
  color: #2c3e50;
}

.rating-count {
  color: #666;
  font-size: 12px;
}

.no-ratings {
  color: #666;
  font-style: italic;
}

.toggle-icon {
  color: #666;
  font-size: 12px;
  margin-left: auto;
}

.avaliacoes-content {
  padding: 15px 0;
}

.no-avaliacoes {
  color: #666;
  font-style: italic;
  text-align: center;
  padding: 20px;
}

.avaliacoes-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.avaliacao-item {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 4px;
  border-left: 3px solid #2c3e50;
}

.avaliacao-stars {
  margin-bottom: 8px;
}

.avaliacao-comentario {
  color: #666;
  margin-bottom: 8px;
}

.avaliacao-data {
  color: #999;
  font-size: 12px;
}

.documentos {
  margin-top: 20px;
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.documentos h4 {
  margin-bottom: 10px;
  color: #2c3e50;
}

.documentos ul {
  list-style: none;
  padding: 0;
}

.documentos li {
  margin-bottom: 8px;
}

.documentos a {
  color: #3498db;
  text-decoration: none;
  padding: 5px 10px;
  border: 1px solid #3498db;
  border-radius: 4px;
  display: inline-block;
  transition: all 0.3s;
}

.documentos a:hover {
  background-color: #3498db;
  color: white;
}
</style> 