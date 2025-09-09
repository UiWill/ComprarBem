<template>
  <div class="rdm-container">
    <h2>Relatório de Desempenho de Material (RDM)</h2>
    
    <form @submit.prevent="enviarFeedback">
      <div class="form-group">
        <label for="produto">Produto*</label>
        
        <!-- Searchable Dropdown Unificado -->
        <div class="searchable-dropdown" :class="{ 'dropdown-open': dropdownAberto }">
          <div class="dropdown-input-container">
            <input 
              type="text" 
              v-model="textoDisplay" 
              @input="filtrarProdutos"
              @focus="abrirDropdown"
              @blur="fecharDropdown"
              placeholder="🔍 Digite o nome do produto ou clique para ver lista completa..."
              class="dropdown-input"
              autocomplete="off"
            />
            <div class="dropdown-arrow" @mousedown="toggleDropdown">
              {{ dropdownAberto ? '▲' : '▼' }}
            </div>
          </div>
          
          <div v-if="dropdownAberto" class="dropdown-list">
            <div v-if="produtosFiltrados.length === 0" class="dropdown-item no-results">
              Nenhum produto encontrado
            </div>
            <div 
              v-for="produto in produtosFiltrados" 
              :key="produto.id" 
              class="dropdown-item"
              @mousedown="selecionarProduto(produto)"
              :class="{ selected: feedback.rdm_id === produto.id }"
            >
              <div class="produto-nome">{{ produto.nome }}</div>
              <div class="produto-detalhes">
                <small>Código: {{ produto.codigo || 'Sem código' }}</small>
                <small v-if="produto.marca"> • Marca: {{ produto.marca }}</small>
              </div>
            </div>
          </div>
          
          <div class="search-info" v-if="textoDisplay && !dropdownAberto">
            {{ produtosFiltrados.length }} produto(s) encontrado(s)
          </div>
        </div>
        
        <!-- Produto selecionado -->
        <div v-if="produtoSelecionado" class="produto-selecionado">
          <div class="produto-info">
            <strong>✓ {{ produtoSelecionado.nome }}</strong>
            <br>
            <small>Código: {{ produtoSelecionado.codigo || 'Sem código' }}</small>
            <small v-if="produtoSelecionado.marca"> • Marca: {{ produtoSelecionado.marca }}</small>
          </div>
          <button type="button" class="btn-limpar" @click="limparSelecao">×</button>
        </div>
      </div>
      
      <div class="form-group">
        <label>Avaliação*</label>
        <div class="avaliacao">
          <div 
            v-for="n in 5" 
            :key="n" 
            class="estrela" 
            :class="{ ativa: feedback.rating >= n }"
            @click="feedback.rating = n"
          >
            ★
          </div>
        </div>
      </div>
      
      <div class="form-group">
        <label for="comentario">Justificativa da avaliação*</label>
        <textarea 
          id="comentario" 
          v-model="feedback.comentario" 
          rows="4" 
          placeholder="Ex: Equipamento apresentou falha após 3 meses de uso..."
          required
        ></textarea>
      </div>
      
      <div class="form-group">
        <label for="sugestoes">Sugestões</label>
        <textarea 
          id="sugestoes" 
          v-model="feedback.sugestoes" 
          rows="3" 
          placeholder="Ex: Melhorar a qualidade do material, incluir manual em português..."
        ></textarea>
      </div>
      
      <div class="form-actions">
        <button type="submit" class="btn-primary" :disabled="loading">
          {{ loading ? 'Salvando...' : 'Salvar' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { v4 as uuidv4 } from 'uuid'

export default {
  name: 'FormularioRDM',
  data() {
    return {
      feedback: {
        rdm_id: '',
        rating: 0,
        comentario: '',
        sugestoes: '',
        material_nome: '',
        material_codigo: '',
      },
      produtos: [],
      produtosFiltrados: [],
      textoDisplay: '',
      dropdownAberto: false,
      produtoSelecionado: null,
      loading: false,
      currentUser: null,
      currentTenantId: null,
      error: null
    }
  },
  created() {
    this.carregarProdutos()
    this.obterUsuarioAtual()
  },
  methods: {
    async obterUsuarioAtual() {
      try {
        const { data: { session }, error } = await supabase.auth.getSession()
        
        if (error) throw error
        
        if (session?.user) {
          this.currentUser = session.user
          
          // Buscar tenant_id dos metadados ou da tabela de usuários
          const { data: userData, error: userError } = await supabase
            .from('usuarios')
            .select('tenant_id')
            .eq('email', session.user.email)
            .single()
            
          if (userError && userError.code !== 'PGRST116') { // Ignora erro de não encontrado
            throw userError
          }
          
          this.currentTenantId = userData?.tenant_id || session.user.user_metadata?.tenant_id || uuidv4()
        } else {
          throw new Error('Usuário não está autenticado')
        }
      } catch (error) {
        console.error('Erro ao obter dados do usuário:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro de Autenticação',
          text: 'Por favor, faça login novamente para enviar um feedback.'
        })
      }
    },
    async carregarProdutos() {
      try {
        if (!this.currentTenantId) {
          await this.obterUsuarioAtual()
        }
        
        if (!this.currentTenantId) {
          throw new Error('Não foi possível identificar o tenant_id')
        }
        
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('status', 'aprovado')
          .eq('tenant_id', this.currentTenantId)
          .order('nome')
        
        if (error) throw error
        
        this.produtos = data || []
        this.produtosFiltrados = this.produtos // Inicializar produtos filtrados
      } catch (error) {
        console.error('Erro ao carregar produtos:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar produtos',
          text: 'Não foi possível carregar a lista de produtos. Por favor, recarregue a página.'
        })
      }
    },
    async enviarFeedback() {
      if (this.feedback.rating === 0) {
        this.$swal({
          icon: 'warning',
          title: 'Avaliação necessária',
          text: 'Por favor, selecione uma avaliação de 1 a 5 estrelas.'
        })
        return
      }
      
      if (!this.feedback.rdm_id) {
        this.$swal({
          icon: 'warning',
          title: 'Produto necessário',
          text: 'Por favor, selecione um produto para avaliar.'
        })
        return
      }
      
      if (!this.feedback.comentario || this.feedback.comentario.trim() === '') {
        this.$swal({
          icon: 'warning',
          title: 'Justificativa necessária',
          text: 'Por favor, preencha a justificativa da avaliação.'
        })
        return
      }

      try {
        this.loading = true
        this.error = null

        if (!this.currentUser?.email) {
          throw new Error('Usuário não está autenticado')
        }

        // Buscar ou criar usuário
        const { data: usuario, error: userError } = await supabase
          .from('usuarios')
          .select('id, tenant_id')
          .eq('email', this.currentUser.email)
          .single()

        if (userError && userError.code !== 'PGRST116') {
          throw userError
        }

        // Obter informações do produto selecionado
        const produtoSelecionado = this.produtos.find(p => p.id === this.feedback.rdm_id)
        if (!produtoSelecionado) {
          throw new Error('Produto não encontrado')
        }

        // Preparar dados do feedback
        const feedbackData = {
          id: uuidv4(),
          tenant_id: this.currentTenantId,
          rdm_id: this.feedback.rdm_id,
          usuario_rdm_id: usuario.id,
          rating: this.feedback.rating,
          comentario: this.feedback.comentario || null,
          sugestoes: this.feedback.sugestoes || null,
          material_nome: produtoSelecionado.nome,
          material_codigo: produtoSelecionado.codigo || 'N/A',
          criado_em: new Date().toISOString()
        }

        // Enviar feedback
        const { error: feedbackError } = await supabase
          .from('rdm_feedbacks')
          .insert(feedbackData)

        if (feedbackError) throw feedbackError

        this.$swal({
          icon: 'success',
          title: 'Feedback enviado!',
          text: 'Seu feedback foi enviado com sucesso.'
        })

        this.limparFormulario()
      } catch (error) {
        console.error('Erro ao enviar feedback:', error)
        
        let mensagemErro = 'Por favor, tente novamente.'
        if (error.message === 'Usuário não está autenticado') {
          mensagemErro = 'Por favor, faça login para enviar um feedback.'
        } else if (error.code === '23505') {
          mensagemErro = 'Você já enviou um feedback para este produto.'
        }

        this.$swal({
          icon: 'error',
          title: 'Erro ao enviar feedback',
          text: mensagemErro
        })

        this.error = error
      } finally {
        this.loading = false
      }
    },
    filtrarProdutos() {
      if (!this.textoDisplay || this.textoDisplay.trim() === '') {
        this.produtosFiltrados = this.produtos
        return
      }
      
      const termo = this.textoDisplay.toLowerCase().trim()
      this.produtosFiltrados = this.produtos.filter(produto => {
        return produto.nome.toLowerCase().includes(termo) ||
               (produto.codigo && produto.codigo.toLowerCase().includes(termo)) ||
               (produto.descricao && produto.descricao.toLowerCase().includes(termo)) ||
               (produto.marca && produto.marca.toLowerCase().includes(termo)) ||
               (produto.fabricante && produto.fabricante.toLowerCase().includes(termo))
      })
    },
    abrirDropdown() {
      this.dropdownAberto = true
      this.filtrarProdutos()
    },
    fecharDropdown() {
      setTimeout(() => {
        this.dropdownAberto = false
      }, 200) // Delay para permitir clique nos itens
    },
    toggleDropdown() {
      this.dropdownAberto = !this.dropdownAberto
      if (this.dropdownAberto) {
        this.filtrarProdutos()
      }
    },
    selecionarProduto(produto) {
      this.feedback.rdm_id = produto.id
      this.produtoSelecionado = produto
      this.textoDisplay = produto.nome
      this.dropdownAberto = false
    },
    limparSelecao() {
      this.feedback.rdm_id = ''
      this.produtoSelecionado = null
      this.textoDisplay = ''
      this.produtosFiltrados = this.produtos
    },
    limparFormulario() {
      this.feedback = {
        rdm_id: '',
        rating: 0,
        comentario: '',
        sugestoes: '',
        material_nome: '',
        material_codigo: ''
      }
      this.textoDisplay = ''
      this.dropdownAberto = false
      this.produtosFiltrados = this.produtos
      this.produtoSelecionado = null
      this.error = null
    }
  }
}
</script>

<style scoped>
.rdm-container {
  padding: 20px;
  max-width: 600px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

select, textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

textarea {
  resize: vertical;
}

.avaliacao {
  display: flex;
  font-size: 30px;
  cursor: pointer;
}

.estrela {
  color: #ddd;
  margin-right: 5px;
}

.estrela.ativa {
  color: #f1c40f;
}

.form-actions {
  margin-top: 20px;
}

.btn-primary {
  padding: 10px 20px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

.error-text {
  color: #dc3545;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

/* Searchable Dropdown Unificado */
.searchable-dropdown {
  position: relative;
  width: 100%;
}

.dropdown-input-container {
  position: relative;
  display: flex;
  align-items: center;
}

.dropdown-input {
  width: 100%;
  padding: 12px 40px 12px 12px;
  border: 2px solid #3498db;
  border-radius: 8px;
  font-size: 14px;
  background-color: #f8f9fa;
  transition: all 0.3s ease;
  cursor: text;
}

.dropdown-input:focus {
  outline: none;
  border-color: #2980b9;
  background-color: white;
  box-shadow: 0 0 10px rgba(52, 152, 219, 0.3);
}

.dropdown-arrow {
  position: absolute;
  right: 12px;
  font-size: 12px;
  color: #666;
  cursor: pointer;
  user-select: none;
  padding: 5px;
  transition: color 0.2s ease;
}

.dropdown-arrow:hover {
  color: #2980b9;
}

.dropdown-list {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 2px solid #3498db;
  border-top: none;
  border-radius: 0 0 8px 8px;
  max-height: 300px;
  overflow-y: auto;
  z-index: 1000;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.dropdown-item {
  padding: 12px;
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.2s ease;
}

.dropdown-item:hover {
  background-color: #f8f9fa;
}

.dropdown-item.selected {
  background-color: #e3f2fd;
  border-left: 4px solid #2196f3;
}

.dropdown-item.no-results {
  color: #666;
  font-style: italic;
  cursor: default;
  text-align: center;
}

.dropdown-item.no-results:hover {
  background-color: white;
}

.produto-nome {
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 4px;
}

.produto-detalhes {
  color: #7f8c8d;
  font-size: 12px;
}

.produto-detalhes small {
  margin-right: 8px;
}

.search-info {
  margin-top: 6px;
  font-size: 12px;
  color: #666;
  font-style: italic;
  text-align: right;
}

/* Produto Selecionado */
.produto-selecionado {
  margin-top: 12px;
  padding: 12px;
  background: linear-gradient(135deg, #e8f5e8, #f0f8f0);
  border: 2px solid #27ae60;
  border-radius: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  animation: fadeIn 0.3s ease;
}

.produto-info {
  flex: 1;
  font-size: 13px;
  color: #2c3e50;
}

.produto-info strong {
  color: #27ae60;
  font-size: 14px;
}

.produto-info small {
  color: #5d6d7e;
}

.btn-limpar {
  background: #e74c3c;
  color: white;
  border: none;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  font-size: 14px;
  font-weight: bold;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  margin-left: 10px;
}

.btn-limpar:hover {
  background: #c0392b;
  transform: scale(1.1);
}

.dropdown-open .dropdown-input {
  border-radius: 8px 8px 0 0;
  border-bottom-color: transparent;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Scrollbar personalizada para a lista */
.dropdown-list::-webkit-scrollbar {
  width: 6px;
}

.dropdown-list::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.dropdown-list::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.dropdown-list::-webkit-scrollbar-thumb:hover {
  background: #a1a1a1;
}
</style> 