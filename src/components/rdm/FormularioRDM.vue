<template>
  <div class="rdm-container">
    <h2>Relatório de Desempenho de Material (RDM)</h2>
    
    <form @submit.prevent="enviarFeedback">
      <div class="form-group">
        <label for="produto">Produto*</label>
        <select 
          id="produto" 
          v-model="feedback.rdm_id" 
          required
        >
          <option value="">Selecione o produto...</option>
          <option 
            v-for="produto in produtos" 
            :key="produto.id" 
            :value="produto.id"
          >
            {{ produto.nome }} - {{ produto.codigo || 'Sem código' }}
          </option>
        </select>
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
    limparFormulario() {
      this.feedback = {
        rdm_id: '',
        rating: 0,
        comentario: '',
        sugestoes: '',
        material_nome: '',
        material_codigo: ''
      }
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
</style> 