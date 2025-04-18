<template>
  <div class="analise-container">
    <div v-if="loading" class="loading">
      <p>Carregando...</p>
    </div>
    
    <div v-else-if="produto" class="produto-analise">
      <h2>Análise de Produto</h2>
      
      <div class="produto-info">
        <h3>{{ produto.nome }}</h3>
        
        <div class="info-grid">
          <div class="info-item">
            <strong>Marca:</strong> {{ produto.marca }}
          </div>
          <div class="info-item">
            <strong>Modelo:</strong> {{ produto.modelo }}
          </div>
          <div class="info-item">
            <strong>Fabricante:</strong> {{ produto.fabricante }}
          </div>
          <div class="info-item">
            <strong>CNPJ:</strong> {{ produto.cnpj }}
          </div>
          <div class="info-item">
            <strong>Origem:</strong> {{ produto.origem || 'Não informada' }}
          </div>
          <div class="info-item">
            <strong>Registro na Anvisa/MS:</strong> {{ produto.registro_anvisa || 'Não informado' }}
          </div>
          <div class="info-item">
            <strong>CBPF:</strong> {{ produto.cbpf || 'Não informado' }}
          </div>
          <div class="info-item">
            <strong>Código do Material:</strong> {{ produto.codigo_material || 'Não informado' }}
          </div>
          <div class="info-item full-width">
            <strong>Descrição:</strong> {{ produto.descricao || 'Não informada' }}
          </div>
          <div class="info-item">
            <strong>Status Atual:</strong> 
            <span class="status-pill" :class="getStatusClass(produto.status)">
              {{ produto.status }}
            </span>
          </div>
          <div class="info-item">
            <strong>Data de Cadastro:</strong> {{ formatDate(produto.criado_em) }}
          </div>
        </div>
      </div>
      
      <div class="documentos-section" v-if="documentos.length > 0">
        <h3>Documentos</h3>
        <div class="documentos-list">
          <div 
            v-for="doc in documentos" 
            :key="doc.id" 
            class="documento-item"
          >
            <div class="doc-icon">📄</div>
            <div class="doc-info">
              <p class="doc-name">{{ doc.nome }}</p>
              <p class="doc-type">{{ doc.tipo }}</p>
            </div>
            <a :href="doc.arquivo_url" target="_blank" class="doc-action">Visualizar</a>
          </div>
        </div>
      </div>
      
      <div class="analise-form">
        <h3>Parecer Técnico</h3>
        
        <form @submit.prevent="salvarAnalise">
          <div class="form-group">
            <label for="parecer">Observações / Parecer</label>
            <textarea 
              id="parecer" 
              v-model="analise.parecer" 
              rows="4" 
              required
            ></textarea>
          </div>
          
          <div class="form-group">
            <label>Decisão</label>
            <div class="radio-group">
              <label class="radio-label">
                <input 
                  type="radio" 
                  v-model="analise.status" 
                  value="aprovado"
                  required
                >
                Aprovar
              </label>
              <label class="radio-label">
                <input 
                  type="radio" 
                  v-model="analise.status" 
                  value="reprovado"
                  required
                >
                Reprovar
              </label>
            </div>
          </div>
          
          <div class="form-group" v-if="analise.status === 'reprovado'">
            <label for="motivacao">Motivação da Reprovação</label>
            <textarea 
              id="motivacao" 
              v-model="analise.motivacao" 
              rows="6" 
              placeholder="Descreva detalhadamente os motivos que levaram à reprovação deste produto"
              required
            ></textarea>
            <small class="helper-text">Este campo será exibido ao fornecedor para justificar a reprovação do produto</small>
          </div>
          
          <div class="form-actions">
            <button type="submit" class="btn-primary" :disabled="submitting">
              {{ submitting ? 'Salvando...' : 'Salvar Análise' }}
            </button>
            <button type="button" class="btn-secondary" @click="voltar">
              Voltar
            </button>
          </div>
        </form>
      </div>
      
      <div class="analises-anteriores" v-if="analisesAnteriores.length > 0">
        <h3>Análises Anteriores</h3>
        <div class="analise-historico" v-for="item in analisesAnteriores" :key="item.id">
          <div class="analise-header">
            <span class="status-pill" :class="getStatusClass(item.status)">{{ item.status }}</span>
            <span class="analise-data">{{ formatDate(item.criado_em) }}</span>
          </div>
          <div class="analise-conteudo">
            <p>{{ item.parecer }}</p>
            <div v-if="item.status === 'reprovado' && item.motivacao" class="motivacao-reprovacao">
              <h4>Motivação da Reprovação:</h4>
              <p>{{ item.motivacao }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-else class="not-found">
      <p>Produto não encontrado ou você não tem permissão para visualizá-lo.</p>
      <button class="btn-secondary" @click="voltar">Voltar</button>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'AnaliseProduto',
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      produto: null,
      documentos: [],
      analisesAnteriores: [],
      analise: {
        parecer: '',
        status: '',
        motivacao: ''
      },
      loading: true,
      submitting: false
    }
  },
  created() {
    this.carregarDados()
  },
  methods: {
    async carregarDados() {
      try {
        this.loading = true
        
        // Carregar produto
        const { data: produto, error: produtoError } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', this.id)
          .single()
        
        if (produtoError) throw produtoError
        
        this.produto = produto
        
        // Carregar documentos
        const { data: documentos, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', this.id)
        
        if (docsError) throw docsError
        
        this.documentos = documentos || []
        
        // Carregar análises anteriores
        const { data: analises, error: analisesError } = await supabase
          .from('analises')
          .select('*')
          .eq('produto_id', this.id)
          .order('criado_em', { ascending: false })
        
        if (analisesError) throw analisesError
        
        this.analisesAnteriores = analises || []
        
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
        alert('Erro ao carregar dados do produto. Por favor, tente novamente.')
      } finally {
        this.loading = false
      }
    },
    async salvarAnalise() {
      try {
        this.submitting = true
        
        if (this.analise.status === 'reprovado' && !this.analise.motivacao) {
          this.$swal({
            icon: 'error',
            title: 'Campo obrigatório',
            text: 'É necessário preencher a motivação da reprovação'
          });
          this.submitting = false;
          return;
        }
        
        const { data: authData } = await supabase.auth.getSession()
        const authUser = authData?.session?.user
        
        let avaliadorId;
        
        if (authUser) {
          console.log('Usuário autenticado:', authUser.email)
          
          const { data: usuarioData, error: usuarioError } = await supabase
            .from('usuarios')
            .select('id')
            .eq('email', authUser.email)
            .maybeSingle()
          
          if (usuarioError) {
            console.error('Erro ao buscar ID do usuário:', usuarioError)
          }
          
          if (usuarioData?.id) {
            console.log('ID do usuário encontrado na tabela usuarios:', usuarioData.id)
            avaliadorId = usuarioData.id
          } else {
            console.warn('Usuário não encontrado na tabela, gerando UUID')
            avaliadorId = this.gerarUUID()
            
            const { error: insertError } = await supabase
              .from('usuarios')
              .insert({
                id: avaliadorId,
                email: authUser.email,
                nome: authUser.email.split('@')[0],
                tenant_id: this.produto.tenant_id,
                tipo: 'avaliador',
                ativo: true
              })
            
            if (insertError) {
              console.error('Erro ao criar usuário automaticamente:', insertError)
            }
          }
        } else {
          console.warn('Nenhum usuário autenticado, gerando UUID')
          avaliadorId = this.gerarUUID()
        }
        
        console.log('Salvando análise com avaliador_id:', avaliadorId)
        
        const dadosAnalise = {
          produto_id: this.id,
          tenant_id: this.produto.tenant_id,
          avaliador_id: avaliadorId,
          parecer: this.analise.parecer,
          status: this.analise.status
        };
        
        if (this.analise.status === 'reprovado') {
          dadosAnalise.motivacao = this.analise.motivacao;
        }
        
        const { error: analiseError } = await supabase
          .from('analises')
          .insert(dadosAnalise)
        
        if (analiseError) {
          console.error('Erro detalhado ao salvar análise:', analiseError)
          throw new Error(`Erro ao salvar análise: ${analiseError.message}`)
        }
        
        const { error: produtoError } = await supabase
          .from('produtos')
          .update({ status: this.analise.status })
          .eq('id', this.id)
        
        if (produtoError) throw produtoError
        
        this.$swal({
          icon: 'success',
          title: 'Análise salva com sucesso!',
          showConfirmButton: false,
          timer: 1500
        })
        
        await this.carregarDados()
        
        this.analise = {
          parecer: '',
          status: '',
          motivacao: ''
        }
        
      } catch (error) {
        console.error('Erro ao salvar análise:', error)
        
        let mensagemErro = 'Erro ao salvar análise.'
        
        if (error.message && error.message.includes('uuid')) {
          mensagemErro = 'Erro no formato de identificação. Este problema foi corrigido, tente novamente.'
        } else if (error.message) {
          mensagemErro = error.message
        }
        
        this.$swal({
          icon: 'error',
          title: 'Erro ao processar análise',
          text: mensagemErro
        })
      } finally {
        this.submitting = false
      }
    },
    formatDate(dateString) {
      if (!dateString) return ''
      const date = new Date(dateString)
      return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    getStatusClass(status) {
      switch (status) {
        case 'aprovado': return 'status-aprovado'
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        default: return ''
      }
    },
    voltar() {
      this.$router.push('/dashboard')
    },
    gerarUUID() {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0, 
              v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
      });
    }
  }
}
</script>

<style scoped>
.analise-container {
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}

.loading, .not-found {
  text-align: center;
  padding: 40px;
}

.produto-analise {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 20px;
}

h2, h3 {
  margin-top: 0;
}

.produto-info {
  margin-bottom: 30px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.info-item {
  padding: 10px;
  background: #f9f9f9;
  border-radius: 4px;
}

.info-item.full-width {
  grid-column: span 2;
}

.status-pill {
  display: inline-block;
  padding: 5px 10px;
  border-radius: 20px;
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

.documentos-section {
  margin-bottom: 30px;
}

.documentos-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 15px;
}

.documento-item {
  display: flex;
  align-items: center;
  background: #f9f9f9;
  padding: 10px;
  border-radius: 4px;
}

.doc-icon {
  font-size: 24px;
  margin-right: 10px;
}

.doc-info {
  flex: 1;
}

.doc-name {
  margin: 0;
  font-weight: bold;
}

.doc-type {
  margin: 0;
  font-size: 12px;
  color: #7f8c8d;
}

.doc-action {
  color: #3498db;
  text-decoration: none;
}

.analise-form {
  margin-bottom: 30px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  resize: vertical;
}

.radio-group {
  display: flex;
  gap: 20px;
}

.radio-label {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.radio-label input {
  margin-right: 8px;
}

.form-actions {
  display: flex;
  gap: 10px;
}

.btn-primary, .btn-secondary {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary {
  background-color: #2c3e50;
  color: white;
}

.btn-primary:disabled {
  background-color: #95a5a6;
}

.btn-secondary {
  background-color: #ecf0f1;
  color: #2c3e50;
}

.analises-anteriores {
  margin-top: 30px;
}

.analise-historico {
  background: #f9f9f9;
  border-radius: 4px;
  padding: 15px;
  margin-bottom: 10px;
}

.analise-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.analise-data {
  color: #7f8c8d;
  font-size: 12px;
}

.analise-conteudo {
  font-style: italic;
}

.motivacao-reprovacao {
  margin-top: 15px;
  background-color: #ffecec;
  padding: 12px;
  border-radius: 4px;
  border-left: 4px solid #e74c3c;
}

.motivacao-reprovacao h4 {
  margin-top: 0;
  margin-bottom: 8px;
  color: #c0392b;
}

.helper-text {
  display: block;
  margin-top: 5px;
  color: #7f8c8d;
  font-size: 12px;
}
</style> 