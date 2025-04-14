<template>
  <div class="detalhe-produto" v-if="produto">
    <h2>Detalhes do Produto</h2>
    
    <div class="card-produto">
      <div class="info-grupo">
        <div class="info-item">
          <strong>Nome:</strong> {{ produto.nome }}
        </div>
        <div class="info-item">
          <strong>Categoria:</strong> {{ categoriaNome }}
        </div>
      </div>
      
      <div class="info-grupo">
        <div class="info-item">
          <strong>Marca:</strong> {{ produto.marca }}
        </div>
        <div class="info-item">
          <strong>Modelo:</strong> {{ produto.modelo }}
        </div>
      </div>
      
      <div class="info-grupo">
        <div class="info-item">
          <strong>Fabricante:</strong> {{ produto.fabricante }}
        </div>
        <div class="info-item">
          <strong>CNPJ:</strong> {{ produto.cnpj }}
        </div>
      </div>
      
      <div class="info-item full-width">
        <strong>Descrição:</strong>
        <p>{{ produto.descricao }}</p>
      </div>
      
      <div class="info-item full-width">
        <strong>Status:</strong>
        <span class="status-badge" :class="'status-' + produto.status">
          {{ statusFormatado }}
        </span>
      </div>
      
      <!-- Seção de documentos -->
      <div class="documentos-section">
        <h3>Documentos</h3>
        <div v-if="loading" class="loading-docs">
          Carregando documentos...
        </div>
        <div v-else-if="documentos.length === 0" class="no-docs">
          Nenhum documento associado a este produto.
        </div>
        <div v-else class="documentos-lista">
          <div v-for="doc in documentos" :key="doc.id" class="documento-item">
            <div class="doc-info">
              <i class="doc-icon" :class="getDocumentIcon(doc.tipo)"></i>
              <span class="doc-nome">{{ doc.nome }}</span>
            </div>
            <div class="doc-actions">
              <a :href="doc.arquivo_url" target="_blank" class="btn-download">
                Visualizar
              </a>
              <button @click="downloadDocument(doc)" class="btn-download">
                Download
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="actions">
      <button @click="voltar" class="btn-secondary">Voltar</button>
    </div>
  </div>
  
  <div v-else class="loading">
    Carregando detalhes do produto...
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { ref, onMounted } from 'vue'

export default {
  name: 'DetalheProduto',
  props: {
    produtoId: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      produto: null,
      documentos: [],
      categorias: [],
      loading: true
    }
  },
  computed: {
    categoriaNome() {
      if (!this.produto || !this.produto.categoria_id) return 'N/A'
      
      const categoria = this.categorias.find(c => c.id === this.produto.categoria_id)
      return categoria ? categoria.nome : 'N/A'
    },
    statusFormatado() {
      const statusMap = {
        'pendente': 'Pendente de Aprovação',
        'aprovado': 'Aprovado',
        'rejeitado': 'Rejeitado'
      }
      
      return statusMap[this.produto.status] || this.produto.status
    }
  },
  async created() {
    await this.carregarCategorias()
    await this.carregarProduto()
  },
  methods: {
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
    async carregarProduto() {
      try {
        // Carregar dados do produto
        const { data: produto, error: produtoError } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', this.produtoId)
          .single()
        
        if (produtoError) throw produtoError
        
        this.produto = produto
        
        // Carregar documentos do produto
        await this.carregarDocumentos()
      } catch (error) {
        console.error('Erro ao carregar produto:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar produto',
          text: 'Não foi possível carregar os detalhes do produto.'
        })
      } finally {
        this.loading = false
      }
    },
    async carregarDocumentos() {
      try {
        this.loading = true
        
        const { data, error } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', this.produtoId)
        
        if (error) throw error
        
        this.documentos = data || []
      } catch (error) {
        console.error('Erro ao carregar documentos:', error)
      } finally {
        this.loading = false
      }
    },
    getDocumentIcon(tipo) {
      // Retorna uma classe de ícone com base no tipo MIME do documento
      if (tipo.includes('pdf')) {
        return 'icon-pdf'
      } else if (tipo.includes('image')) {
        return 'icon-image'
      } else if (tipo.includes('word') || tipo.includes('document')) {
        return 'icon-doc'
      } else if (tipo.includes('excel') || tipo.includes('sheet')) {
        return 'icon-excel'
      } else {
        return 'icon-file'
      }
    },
    downloadDocument(doc) {
      // Cria um link temporário para download
      const link = document.createElement('a')
      link.href = doc.arquivo_url
      link.download = doc.nome
      link.target = '_blank'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    },
    voltar() {
      this.$router.back()
    }
  }
}
</script>

<style scoped>
.detalhe-produto {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
}

.card-produto {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  padding: 20px;
  margin-bottom: 20px;
}

.info-grupo {
  display: flex;
  gap: 20px;
  margin-bottom: 15px;
}

.info-item {
  flex: 1;
  margin-bottom: 10px;
}

.full-width {
  flex-basis: 100%;
}

.status-badge {
  display: inline-block;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 14px;
  font-weight: bold;
}

.status-pendente {
  background-color: #f39c12;
  color: white;
}

.status-aprovado {
  background-color: #27ae60;
  color: white;
}

.status-rejeitado {
  background-color: #e74c3c;
  color: white;
}

.documentos-section {
  margin-top: 20px;
  border-top: 1px solid #eee;
  padding-top: 15px;
}

.documentos-lista {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.documento-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #f9f9f9;
  padding: 10px 15px;
  border-radius: 4px;
}

.doc-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.doc-icon {
  font-size: 18px;
}

.doc-nome {
  font-size: 14px;
  word-break: break-word;
}

.doc-actions {
  display: flex;
  gap: 10px;
}

.btn-download {
  padding: 5px 10px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  text-decoration: none;
  display: inline-block;
}

.loading, .loading-docs {
  text-align: center;
  padding: 20px;
  color: #666;
}

.no-docs {
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 4px;
  color: #666;
  text-align: center;
}

.actions {
  display: flex;
  justify-content: flex-start;
  margin-top: 20px;
}

.btn-secondary {
  padding: 10px 20px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
</style> 