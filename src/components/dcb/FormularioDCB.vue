<template>
  <div class="dcb-container">
    <h2>Declaração de Conformidade de Bem (DCB)</h2>
    
    <div class="search-container">
      <div class="form-group">
        <label for="produto">Selecione o produto</label>
        <select 
          id="produto" 
          v-model="produtoSelecionado" 
          @change="carregarDetalhes"
        >
          <option value="">Selecione...</option>
          <option 
            v-for="produto in produtos" 
            :key="produto.id" 
            :value="produto.id"
          >
            {{ produto.nome }} - {{ produto.marca }} - {{ produto.modelo }}
          </option>
        </select>
      </div>
    </div>
    
    <div v-if="loading" class="loading">
      <p>Carregando informações...</p>
    </div>
    
    <div v-else-if="produtoDetalhes" class="produto-detalhes">
      <h3>{{ produtoDetalhes.nome }}</h3>
      
      <div class="info-grid">
        <div class="info-item">
          <strong>Marca:</strong> {{ produtoDetalhes.marca }}
        </div>
        <div class="info-item">
          <strong>Modelo:</strong> {{ produtoDetalhes.modelo }}
        </div>
        <div class="info-item">
          <strong>Fabricante:</strong> {{ produtoDetalhes.fabricante }}
        </div>
        <div class="info-item">
          <strong>CNPJ:</strong> {{ produtoDetalhes.cnpj }}
        </div>
        <div class="info-item">
          <strong>Origem:</strong> {{ produtoDetalhes.origem || 'Não informada' }}
        </div>
        <div class="info-item">
          <strong>Registro na Anvisa/MS:</strong> {{ produtoDetalhes.registro_anvisa || 'Não informado' }}
        </div>
        <div class="info-item">
          <strong>CBPF:</strong> {{ produtoDetalhes.cbpf || 'Não informado' }}
        </div>
        <div class="info-item">
          <strong>Código do Material:</strong> {{ produtoDetalhes.codigo_material || 'Não informado' }}
        </div>
        <div class="info-item full-width">
          <strong>Status:</strong> 
          <span class="status-badge" :class="getStatusClass(produtoDetalhes.status)">
            {{ formatarStatus(produtoDetalhes.status) }}
          </span>
        </div>
      </div>
      
      <div class="documentos" v-if="documentos.length > 0">
        <h3>Documentos</h3>
        <ul class="documentos-lista">
          <li v-for="doc in documentos" :key="doc.id" class="documento-item">
            <span class="doc-icon">📄</span>
            <span class="doc-nome">{{ doc.nome }}</span>
            <a :href="doc.arquivo_url" target="_blank" class="btn-download">Visualizar</a>
          </li>
        </ul>
      </div>
      
      <div class="dcb-actions">
        <button @click="gerarDCB" class="btn-primary" :disabled="!produtoAprovado">
          Baixar Declaração de Conformidade
        </button>
        <p v-if="!produtoAprovado" class="aviso">
          Somente produtos aprovados possuem Declaração de Conformidade disponível.
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'FormularioDCB',
  data() {
    return {
      produtoSelecionado: '',
      produtoDetalhes: null,
      documentos: [],
      produtos: [],
      loading: false,
      currentTenantId: null
    }
  },
  computed: {
    produtoAprovado() {
      return this.produtoDetalhes && this.produtoDetalhes.status === 'aprovado'
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarProdutos()
    })
  },
  methods: {
    async obterTenantId() {
      try {
        // Obter dados da sessão atual
        const { data: authData } = await supabase.auth.getSession()
        const user = authData?.session?.user
        
        if (user) {
          // Tentar obter tenant_id dos metadados
          if (user.user_metadata?.tenant_id) {
            this.currentTenantId = user.user_metadata.tenant_id
          } else {
            // Buscar na tabela usuários
            const { data: userData, error: userError } = await supabase
              .from('usuarios')
              .select('tenant_id')
              .eq('email', user.email)
              .single()
            
            if (!userError && userData?.tenant_id) {
              this.currentTenantId = userData.tenant_id
            }
          }
        }
      } catch (error) {
        console.error('Erro ao obter dados do usuário:', error)
      }
    },
    async carregarProdutos() {
      try {
        this.loading = true
        
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível')
          return
        }
        
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .order('nome')
        
        if (error) throw error
        
        this.produtos = data || []
      } catch (error) {
        console.error('Erro ao carregar produtos:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar a lista de produtos.'
        })
      } finally {
        this.loading = false
      }
    },
    async carregarDetalhes() {
      if (!this.produtoSelecionado) {
        this.produtoDetalhes = null
        this.documentos = []
        return
      }
      
      try {
        this.loading = true
        
        // Carregar detalhes do produto
        const { data: produto, error: produtoError } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', this.produtoSelecionado)
          .single()
        
        if (produtoError) throw produtoError
        
        this.produtoDetalhes = produto
        
        // Carregar documentos
        const { data: docs, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', this.produtoSelecionado)
        
        if (docsError) throw docsError
        
        this.documentos = docs || []
      } catch (error) {
        console.error('Erro ao carregar detalhes do produto:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar os detalhes do produto.'
        })
      } finally {
        this.loading = false
      }
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
    formatarStatus(status) {
      switch (status) {
        case 'pendente': return 'Em avaliação'
        case 'diligencia': return 'Diligência'
        default: return status.charAt(0).toUpperCase() + status.slice(1)
      }
    },
    gerarDCB() {
      if (!this.produtoDetalhes || !this.produtoAprovado) {
        this.$swal({
          icon: 'error',
          title: 'Não disponível',
          text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
        })
        return
      }
      
      // Exibir mensagem informativa sobre a funcionalidade
      this.$swal({
        icon: 'info',
        title: 'Funcionalidade em Desenvolvimento',
        text: 'A geração de PDF da Declaração de Conformidade estará disponível em breve. Esta funcionalidade requer a instalação de bibliotecas adicionais no projeto.'
      })
    }
  }
}
</script>

<style scoped>
.dcb-container {
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
}

.search-container {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.loading {
  text-align: center;
  padding: 20px;
}

.produto-detalhes {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
  margin-bottom: 20px;
}

.info-item {
  padding: 10px;
  background: #f9f9f9;
  border-radius: 4px;
}

.info-item.full-width {
  grid-column: span 2;
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

.status-diligencia {
  background-color: #9b59b6;
  color: white;
}

.documentos {
  margin-top: 20px;
}

.documentos h3 {
  margin-bottom: 15px;
}

.documentos-lista {
  list-style: none;
  padding: 0;
  margin: 0;
}

.documento-item {
  display: flex;
  align-items: center;
  padding: 10px;
  background: #f9f9f9;
  margin-bottom: 8px;
  border-radius: 4px;
}

.doc-icon {
  margin-right: 10px;
  font-size: 20px;
}

.doc-nome {
  flex: 1;
}

.btn-download {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  font-size: 12px;
}

.dcb-actions {
  margin-top: 30px;
  text-align: center;
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

.aviso {
  margin-top: 10px;
  color: #e74c3c;
  font-size: 14px;
}
</style> 